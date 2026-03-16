import { callSp, callSpOut, sql } from "../../db/query.js";

export interface AsientoDetalleInput {
  codCuenta: string;
  descripcion?: string;
  centroCosto?: string;
  auxiliarTipo?: string;
  auxiliarCodigo?: string;
  documento?: string;
  debe: number;
  haber: number;
}

export interface CrearAsientoInput {
  fecha: string;
  tipoAsiento: string;
  referencia?: string;
  concepto: string;
  moneda?: string;
  tasa?: number;
  origenModulo?: string;
  origenDocumento?: string;
  detalle: AsientoDetalleInput[];
}

export interface ListAsientosInput {
  fechaDesde?: string;
  fechaHasta?: string;
  tipoAsiento?: string;
  estado?: string;
  origenModulo?: string;
  origenDocumento?: string;
  page?: number;
  limit?: number;
}

async function getDefaultScope() {
  const rows = await callSp<{ CompanyId: number; BranchId: number }>(
    "dbo.usp_Acct_Scope_GetDefault"
  );

  const companyId = Number(rows[0]?.CompanyId ?? 0);
  const branchId = Number(rows[0]?.BranchId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");
  return { companyId, branchId };
}

function toPeriodCode(fecha: Date) {
  const yyyy = fecha.getUTCFullYear();
  const mm = String(fecha.getUTCMonth() + 1).padStart(2, "0");
  return `${yyyy}${mm}`;
}

function generateEntryNumber(tipoAsiento: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  const pref = String(tipoAsiento || "ASI").trim().toUpperCase().slice(0, 6) || "ASI";
  return `${pref}-${stamp}`;
}

function normalizeAsientoEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (["ACTIVO", "A", "POSTED", "APROBADO", "APPROVED"].includes(value)) return "APPROVED";
  if (["ANULADO", "VOID", "VOIDED"].includes(value)) return "VOIDED";
  if (["BORRADOR", "DRAFT"].includes(value)) return "DRAFT";
  return value;
}

function round2(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export async function listAsientos(input: ListAsientosInput) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const estado = normalizeAsientoEstado(input.estado);

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Entry_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: input.fechaDesde || null,
      FechaHasta: input.fechaHasta || null,
      TipoAsiento: input.tipoAsiento || null,
      Estado: estado,
      OrigenModulo: input.origenModulo || null,
      OrigenDocumento: input.origenDocumento || null,
      Page: page,
      Limit: limit
    },
    {
      TotalCount: sql.Int
    }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit
  };
}

export async function getAsiento(asientoId: number) {
  const scope = await getDefaultScope();

  const cabeceraRows = await callSp<any>(
    "dbo.usp_Acct_Entry_Get",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      AsientoId: asientoId
    }
  );

  const detalle = await callSp<any>(
    "dbo.usp_Acct_Entry_GetDetail",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      AsientoId: asientoId
    }
  );

  return {
    cabecera: cabeceraRows[0] || null,
    detalle: detalle || []
  };
}

export async function crearAsiento(input: CrearAsientoInput, _codUsuario?: string) {
  const scope = await getDefaultScope();

  const fecha = input.fecha ? new Date(input.fecha) : new Date();
  const entryNumber = generateEntryNumber(input.tipoAsiento);
  const periodCode = toPeriodCode(fecha);

  const detalle = Array.isArray(input.detalle) ? input.detalle : [];
  if (detalle.length === 0) {
    return { ok: false, resultado: 0, mensaje: "Detalle de asiento requerido", asientoId: null, numeroAsiento: null };
  }

  const totalDebe = round2(detalle.reduce((acc, item) => acc + Number(item.debe || 0), 0));
  const totalHaber = round2(detalle.reduce((acc, item) => acc + Number(item.haber || 0), 0));
  if (totalDebe <= 0 || totalHaber <= 0 || round2(totalDebe - totalHaber) !== 0) {
    return { ok: false, resultado: 0, mensaje: "Asiento desbalanceado", asientoId: null, numeroAsiento: null };
  }

  const detalleXml = "<rows>" + detalle.map((item) => {
    const esc = (v: unknown) => String(v ?? "").replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");
    return `<row codCuenta="${esc(String(item.codCuenta || "").trim())}" descripcion="${esc(item.descripcion || "")}" centroCosto="${esc(item.centroCosto || "")}" auxiliarTipo="${esc(item.auxiliarTipo || "")}" auxiliarCodigo="${esc(item.auxiliarCodigo || "")}" documento="${esc(item.documento || input.origenDocumento || "")}" debe="${Number(item.debe || 0)}" haber="${Number(item.haber || 0)}"/>`;
  }).join("") + "</rows>";

  const { output } = await callSpOut(
    "dbo.usp_Acct_Entry_Insert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EntryNumber: entryNumber,
      EntryDate: fecha.toISOString().slice(0, 10),
      PeriodCode: periodCode,
      EntryType: input.tipoAsiento || "DIA",
      ReferenceNumber: input.referencia || null,
      Concept: input.concepto || "Asiento",
      CurrencyCode: (input.moneda || "VES").toUpperCase().slice(0, 3),
      ExchangeRate: Number(input.tasa ?? 1),
      TotalDebit: totalDebe,
      TotalCredit: totalHaber,
      SourceModule: input.origenModulo || null,
      SourceDocumentNo: input.origenDocumento || null,
      DetalleXml: detalleXml
    },
    {
      AsientoId: sql.BigInt,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const asientoId = Number(output.AsientoId ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  if (resultado !== 1) {
    return {
      ok: false,
      resultado: 0,
      mensaje: mensaje || "No se pudo crear asiento",
      asientoId: null,
      numeroAsiento: null
    };
  }

  return {
    ok: true,
    resultado: 1,
    mensaje: mensaje || "Asiento creado en modelo canonico",
    asientoId: asientoId > 0 ? asientoId : null,
    numeroAsiento: entryNumber
  };
}

export async function anularAsiento(asientoId: number, motivo: string, _codUsuario?: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Entry_Void",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      AsientoId: asientoId,
      Motivo: motivo || "sin_motivo"
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    ok: resultado > 0,
    resultado: resultado > 0 ? 1 : 0,
    mensaje: mensaje || (resultado > 0 ? "Asiento anulado" : "Asiento no encontrado")
  };
}

export async function crearAjuste(
  input: {
    fecha: string;
    tipoAjuste: string;
    referencia?: string;
    motivo: string;
    detalle: AsientoDetalleInput[];
  },
  codUsuario?: string
) {
  return crearAsiento(
    {
      fecha: input.fecha,
      tipoAsiento: input.tipoAjuste || "AJUSTE",
      referencia: input.referencia,
      concepto: input.motivo,
      moneda: "VES",
      tasa: 1,
      origenModulo: "CONTABILIDAD",
      origenDocumento: input.referencia || undefined,
      detalle: input.detalle,
    },
    codUsuario
  );
}

export async function generarDepreciacion(periodo: string, centroCosto?: string, codUsuario?: string) {
  const { calculateDepreciation } = await import("./activos-fijos.service.js");
  return calculateDepreciation(periodo, false, centroCosto, codUsuario);
}

export async function libroMayor(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_Report_LibroMayor",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );
}

export async function mayorAnalitico(codCuenta: string, fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_Report_MayorAnalitico",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CodCuenta: codCuenta,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );
}

export async function balanceComprobacion(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_BalanceComprobacion",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );
  // SP retorna 'cuenta' pero el frontend espera 'descripcion'
  return (rows || []).map((r: any) => ({
    ...r,
    descripcion: r.cuenta ?? r.descripcion ?? "",
  }));
}

export async function estadoResultados(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  const detalle = await callSp<any>(
    "dbo.usp_Acct_Report_EstadoResultados",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );

  const ingresos = round2(detalle.filter((r: any) => r.tipo === "I").reduce((acc: number, r: any) => acc + Number(r.monto ?? 0), 0));
  const gastos = round2(detalle.filter((r: any) => r.tipo === "G").reduce((acc: number, r: any) => acc + Number(r.monto ?? 0), 0));
  const resultado = round2(ingresos - gastos);

  return {
    detalle,
    resumen: {
      ingresos,
      gastos,
      resultado
    }
  };
}

export async function balanceGeneral(fechaCorte: string) {
  const scope = await getDefaultScope();
  const detalle = await callSp<any>(
    "dbo.usp_Acct_Report_BalanceGeneral",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaCorte: fechaCorte
    }
  );

  const totalActivo = round2(detalle.filter((r: any) => r.tipo === "A").reduce((acc: number, r: any) => acc + Number(r.saldo ?? 0), 0));
  const totalPasivo = round2(detalle.filter((r: any) => r.tipo === "P").reduce((acc: number, r: any) => acc + Number(r.saldo ?? 0), 0));
  const totalPatrimonio = round2(detalle.filter((r: any) => r.tipo === "C").reduce((acc: number, r: any) => acc + Number(r.saldo ?? 0), 0));

  return {
    detalle,
    resumen: {
      totalActivo,
      totalPasivo,
      totalPatrimonio,
      totalPasivoPatrimonio: round2(totalPasivo + totalPatrimonio)
    }
  };
}

export async function seedPlanCuentas(codUsuario?: string) {
  const scopeRows = await callSp<{ CompanyId: number; BranchId: number; SystemUserId: number | null }>(
    "dbo.usp_Acct_Scope_GetDefaultForSeed"
  );

  const companyId = Number(scopeRows[0]?.CompanyId ?? 0);
  const systemUserId = Number(scopeRows[0]?.SystemUserId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) {
    return { success: false, message: "No existe cfg.Company DEFAULT para sembrar plan de cuentas" };
  }

  const { output } = await callSpOut(
    "dbo.usp_Acct_SeedPlanCuentas",
    {
      CompanyId: companyId,
      SystemUserId: Number.isFinite(systemUserId) && systemUserId > 0 ? systemUserId : null
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");
  const userLabel = codUsuario || "API";

  if (resultado !== 1) {
    return { success: false, message: mensaje || "Error sembrando plan de cuentas" };
  }

  return { success: true, message: `${mensaje} (${userLabel})` };
}

// --- Funciones de servicio para CRUD de cuentas (usadas por routes.ts) ---

export async function getDefaultCompanyId(): Promise<number> {
  const { getActiveScope: getScope } = await import("../_shared/scope.js");
  const activeScope = getScope();
  if (activeScope?.companyId) return activeScope.companyId;

  const rows = await callSp<{ CompanyId: number }>(
    "dbo.usp_Acct_Scope_GetDefault"
  );
  return Number(rows[0]?.CompanyId ?? 1);
}

export function normalizeTipoCuenta(value: string | undefined): string | null {
  const tipo = String(value ?? "").trim().toUpperCase();
  if (!tipo) return null;
  const normalized = tipo.charAt(0);
  if (!["A", "P", "C", "I", "G"].includes(normalized)) return null;
  return normalized;
}

export interface CuentaRow {
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
  activo: boolean;
}

export async function listCuentas(params: {
  companyId: number;
  search?: string;
  tipo?: string;
  nivel?: number;
  activo?: boolean;
  page?: number;
  limit?: number;
}): Promise<{ data: CuentaRow[]; total: number; page: number; limit: number }> {
  const page = Math.max(1, Number(params.page ?? 1));
  const limit = Math.min(200, Math.max(1, Number(params.limit ?? 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Account_List",
    {
      CompanyId: params.companyId,
      Search: params.search?.trim() || null,
      Tipo: params.tipo || null,
      Grupo: null,
      Page: page,
      Limit: limit
    },
    {
      TotalCount: sql.Int
    }
  );

  const data: CuentaRow[] = (rows || []).map((row: any) => ({
    codCuenta: row.AccountCode,
    descripcion: row.AccountName,
    tipo: row.AccountType,
    nivel: row.AccountLevel,
    activo: row.IsActive,
  }));

  return { data, total: Number(output.TotalCount ?? 0), page, limit };
}

export async function getCuenta(companyId: number, codCuenta: string): Promise<CuentaRow | null> {
  const rows = await callSp<any>(
    "dbo.usp_Acct_Account_Get",
    {
      CompanyId: companyId,
      AccountCode: codCuenta
    }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    codCuenta: row.AccountCode,
    descripcion: row.AccountName,
    tipo: row.AccountType,
    nivel: row.AccountLevel,
    activo: row.IsActive,
  };
}

export async function insertCuenta(params: {
  companyId: number;
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
}): Promise<{ ok: boolean; mensaje: string }> {
  const { output } = await callSpOut(
    "dbo.usp_Acct_Account_Insert",
    {
      CompanyId: params.companyId,
      AccountCode: params.codCuenta,
      AccountName: params.descripcion,
      AccountType: params.tipo,
      AccountLevel: params.nivel
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    ok: resultado === 1,
    mensaje
  };
}

export async function updateCuenta(params: {
  companyId: number;
  codCuenta: string;
  descripcion?: string;
  tipo?: string;
  nivel?: number;
}): Promise<{ ok: boolean; mensaje: string }> {
  const { output } = await callSpOut(
    "dbo.usp_Acct_Account_Update",
    {
      CompanyId: params.companyId,
      AccountCode: params.codCuenta,
      AccountName: params.descripcion || null,
      AccountType: params.tipo || null,
      AccountLevel: params.nivel ?? null
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    ok: resultado === 1,
    mensaje
  };
}

export async function deleteCuenta(params: {
  companyId: number;
  codCuenta: string;
}): Promise<{ ok: boolean; mensaje: string }> {
  const { output } = await callSpOut(
    "dbo.usp_Acct_Account_Delete",
    {
      CompanyId: params.companyId,
      AccountCode: params.codCuenta
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    ok: resultado === 1,
    mensaje
  };
}

export async function libroDiario(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_Report_LibroDiario",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );
}

export async function dashboardResumen(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_Dashboard_Resumen",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaDesde: fechaDesde,
      FechaHasta: fechaHasta
    }
  );
  return rows[0] || {
    totalIngresos: 0,
    totalGastos: 0,
    margenPorcentaje: 0,
    cuentasPorPagar: 0,
    totalAsientos: 0,
    totalCuentas: 0,
    totalAnulados: 0
  };
}
