import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";
import {
  emitBankMovementAccountingEntry,
  linkMovementToEntry,
  emitConciliacionClosingEntry,
} from "./bancos-contabilidad.service.js";

export interface ConciliacionRow {
  ID?: number;
  Nro_Cta?: string;
  Fecha_Desde?: string;
  Fecha_Hasta?: string;
  Saldo_Inicial_Sistema?: number;
  Saldo_Final_Sistema?: number;
  Saldo_Inicial_Banco?: number;
  Saldo_Final_Banco?: number;
  Diferencia?: number;
  Estado?: string;
  Observaciones?: string;
  Banco?: string;
  Pendientes?: number;
  Conciliados?: number;
}

export interface MovimientoBancarioPayload {
  Nro_Cta: string;
  Tipo: string;
  Nro_Ref: string;
  Beneficiario: string;
  Monto: number;
  Concepto: string;
  Categoria?: string;
  Documento_Relacionado?: string;
  Tipo_Doc_Rel?: string;
}

export interface ExtractoPayload {
  Nro_Cta?: string;
  Fecha: string;
  Descripcion?: string;
  Referencia?: string;
  Tipo: "DEBITO" | "CREDITO";
  Monto: number;
  Saldo?: number;
}

export interface AjustePayload {
  Conciliacion_ID: number;
  Tipo_Ajuste: string;
  Monto: number;
  Descripcion: string;
}

export interface ConciliacionResult {
  conciliacionId: number;
  saldoInicial: number;
  saldoFinal: number;
}

type Scope = {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
};

type BankAccountRow = {
  bankAccountId: number;
  nroCta: string;
  bankName: string;
  balance: number;
  availableBalance: number;
};

let scopeCache: Scope | null = null;

async function getScope(): Promise<Scope> {
  const activeScope = getActiveScope();
  if (scopeCache && activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (scopeCache) return scopeCache;

  const rows = await callSp<{ companyId: number; branchId: number; systemUserId: number | null }>(
    "usp_Bank_ResolveScope"
  );

  const row = rows[0];
  scopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };
  if (activeScope) {
    return {
      ...scopeCache,
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  return scopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  if (!code) return (await getScope()).systemUserId;

  const rows = await callSp<{ userId: number }>(
    "usp_Bank_ResolveUserId",
    { Code: code }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getScope()).systemUserId;
}

async function getBankAccount(nroCta: string): Promise<BankAccountRow | null> {
  const scope = await getScope();

  const rows = await callSp<BankAccountRow>(
    "usp_Bank_Account_GetByNumber",
    {
      CompanyId: scope.companyId,
      NroCta: String(nroCta ?? "").trim(),
    }
  );

  return rows[0] ?? null;
}

function toMovementSign(tipo: string) {
  const normalized = String(tipo ?? "").trim().toUpperCase();
  if (["DEP", "NCR", "IDB", "NOTA_CREDITO", "CREDITO"].includes(normalized)) return 1;
  return -1;
}

function toSqlDate(value?: string) {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export async function generarMovimientoBancario(
  payload: MovimientoBancarioPayload,
  codUsuario?: string
): Promise<{ ok: boolean; movimientoId?: number; saldoNuevo?: number }> {
  const account = await getBankAccount(payload.Nro_Cta);
  if (!account) return { ok: false };

  const amount = Math.abs(Number(payload.Monto ?? 0));
  if (!(amount > 0)) return { ok: false };

  const movementSign = toMovementSign(payload.Tipo);
  const netAmount = Number((movementSign * amount).toFixed(2));
  const userId = await resolveUserId(codUsuario);

  try {
    const { rows, output } = await callSpOut<{ movementId: number; newBalance: number }>(
      "usp_Bank_Movement_Create",
      {
        BankAccountId: account.bankAccountId,
        MovementType: String(payload.Tipo ?? "").trim().toUpperCase() || "MOV",
        MovementSign: movementSign,
        Amount: amount,
        NetAmount: netAmount,
        ReferenceNo: String(payload.Nro_Ref ?? "").trim() || null,
        Beneficiary: String(payload.Beneficiario ?? "").trim() || null,
        Concept: String(payload.Concepto ?? "").trim() || null,
        CategoryCode: String(payload.Categoria ?? "").trim() || null,
        RelatedDocumentNo: String(payload.Documento_Relacionado ?? "").trim() || null,
        RelatedDocumentType: String(payload.Tipo_Doc_Rel ?? "").trim() || null,
        CreatedByUserId: userId ?? null,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );

    const movementId = Number(output.Resultado ?? rows[0]?.movementId ?? 0);
    const newBalance = Number(output.Mensaje ?? rows[0]?.newBalance ?? 0);

    return {
      ok: true,
      movimientoId: movementId || undefined,
      saldoNuevo: newBalance,
    };
  } catch {
    return { ok: false };
  }
}

export async function crearConciliacion(
  Nro_Cta: string,
  Fecha_Desde: string,
  Fecha_Hasta: string,
  codUsuario?: string
): Promise<ConciliacionResult> {
  const scope = await getScope();
  const account = await getBankAccount(Nro_Cta);
  if (!account) throw new Error("Cuenta bancaria no encontrada");

  const from = toSqlDate(Fecha_Desde);
  const to = toSqlDate(Fecha_Hasta);
  if (!from || !to) throw new Error("Fechas invalidas");

  const netRows = await callSp<{ netTotal: number }>(
    "usp_Bank_Reconciliation_GetNetTotal",
    {
      BankAccountId: account.bankAccountId,
      FromDate: from,
      ToDate: to,
    }
  );

  const opening = Number(account.balance ?? 0);
  const closing = Number((opening + Number(netRows[0]?.netTotal ?? 0)).toFixed(2));
  const userId = await resolveUserId(codUsuario);

  const { output } = await callSpOut(
    "usp_Bank_Reconciliation_Create",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      BankAccountId: account.bankAccountId,
      FromDate: from,
      ToDate: to,
      Opening: opening,
      Closing: closing,
      CreatedByUserId: userId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    conciliacionId: Number(output.Resultado ?? 0),
    saldoInicial: opening,
    saldoFinal: closing,
  };
}

export async function listConciliaciones(params: {
  Nro_Cta?: string;
  Estado?: string;
  page?: number;
  limit?: number;
}): Promise<{ rows: ConciliacionRow[]; total: number; page: number; limit: number }> {
  const scope = await getScope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);
  const offset = (page - 1) * limit;

  const nroCta = params.Nro_Cta?.trim() || null;
  const estado = params.Estado?.trim() ? params.Estado.trim().toUpperCase() : null;

  const { rows, output } = await callSpOut<ConciliacionRow>(
    "usp_Bank_Reconciliation_List",
    {
      CompanyId: scope.companyId,
      NroCta: nroCta,
      Estado: estado,
      Offset: offset,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

export async function getConciliacion(
  Conciliacion_ID: number
): Promise<{
  cabecera: ConciliacionRow | null;
  movimientosSistema: any[];
  extractoPendiente: any[];
}> {
  const scope = await getScope();

  const cabeceraRows = await callSp<ConciliacionRow>(
    "usp_Bank_Reconciliation_GetById",
    {
      CompanyId: scope.companyId,
      Id: Conciliacion_ID,
    }
  );

  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) {
    return { cabecera: null, movimientosSistema: [], extractoPendiente: [] };
  }

  const movimientosSistema = await callSp<any>(
    "usp_Bank_Reconciliation_GetSystemMovements",
    { Id: Conciliacion_ID }
  );

  const extractoPendiente = await callSp<any>(
    "usp_Bank_Reconciliation_GetPendingStatements",
    { Id: Conciliacion_ID }
  );

  return {
    cabecera,
    movimientosSistema,
    extractoPendiente,
  };
}

export async function importarExtracto(
  Nro_Cta: string,
  extractoRows: ExtractoPayload[],
  codUsuario?: string
): Promise<{ ok: boolean; registrosImportados?: number }> {
  const scope = await getScope();
  const account = await getBankAccount(Nro_Cta);
  if (!account) return { ok: false };

  const userId = await resolveUserId(codUsuario);
  const validRows = extractoRows.filter((row) => Number(row.Monto ?? 0) > 0);
  if (validRows.length === 0) return { ok: true, registrosImportados: 0 };

  const openRec = await callSp<{ id: number }>(
    "usp_Bank_Reconciliation_GetOpenForAccount",
    {
      CompanyId: scope.companyId,
      BankAccountId: account.bankAccountId,
    }
  );

  let reconciliationId = Number(openRec[0]?.id ?? 0);
  if (!reconciliationId) {
    const dates = validRows
      .map((row) => toSqlDate(row.Fecha))
      .filter((value): value is Date => value instanceof Date)
      .sort((a, b) => a.getTime() - b.getTime());

    const fromDate = dates[0] ?? new Date();
    const toDate = dates[dates.length - 1] ?? new Date();

    const { output } = await callSpOut(
      "usp_Bank_Reconciliation_Create",
      {
        CompanyId: scope.companyId,
        BranchId: scope.branchId,
        BankAccountId: account.bankAccountId,
        FromDate: fromDate,
        ToDate: toDate,
        Opening: account.balance,
        Closing: account.balance,
        CreatedByUserId: userId,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );

    reconciliationId = Number(output.Resultado ?? 0);
  }

  try {
    for (const row of validRows) {
      await callSpOut(
        "usp_Bank_StatementLine_Insert",
        {
          ReconciliationId: reconciliationId,
          StatementDate: toSqlDate(row.Fecha) ?? new Date(),
          DescriptionText: String(row.Descripcion ?? "").trim() || null,
          ReferenceNo: String(row.Referencia ?? "").trim() || null,
          EntryType: row.Tipo === "CREDITO" ? "CREDITO" : "DEBITO",
          Amount: Math.abs(Number(row.Monto ?? 0)),
          Balance: row.Saldo == null ? null : Number(row.Saldo),
          CreatedByUserId: userId ?? null,
        },
        { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
      );
    }

    return { ok: true, registrosImportados: validRows.length };
  } catch {
    return { ok: false };
  }
}

export async function conciliarMovimientos(
  Conciliacion_ID: number,
  MovimientoSistema_ID: number,
  Extracto_ID?: number,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const userId = await resolveUserId(codUsuario);

  try {
    const { output } = await callSpOut(
      "usp_Bank_Reconciliation_MatchMovement",
      {
        ReconciliationId: Conciliacion_ID,
        MovementId: MovimientoSistema_ID,
        StatementId: Number(Extracto_ID ?? 0) > 0 ? Number(Extracto_ID) : null,
        MatchedByUserId: userId ?? null,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );

    const resultado = Number(output.Resultado ?? 0);
    const mensaje = String(output.Mensaje ?? "");

    if (resultado === 0) {
      return { ok: false, mensaje: mensaje || "No se pudo conciliar" };
    }

    return { ok: true, mensaje: mensaje || "Movimiento conciliado" };
  } catch {
    return { ok: false, mensaje: "No se pudo conciliar" };
  }
}

export async function generarAjusteBancario(
  payload: AjustePayload,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const rows = await callSp<{ accountNo: string }>(
    "usp_Bank_Reconciliation_GetAccountNoById",
    { Id: payload.Conciliacion_ID }
  );

  const accountNo = String(rows[0]?.accountNo ?? "").trim();
  if (!accountNo) return { ok: false, mensaje: "Conciliacion no encontrada" };

  const tipo = String(payload.Tipo_Ajuste ?? "").trim().toUpperCase() === "NOTA_CREDITO" ? "NCR" : "NDB";
  const result = await generarMovimientoBancario(
    {
      Nro_Cta: accountNo,
      Tipo: tipo,
      Nro_Ref: `AJ-${payload.Conciliacion_ID}-${Date.now()}`,
      Beneficiario: "AJUSTE",
      Monto: Math.abs(Number(payload.Monto ?? 0)),
      Concepto: payload.Descripcion,
      Categoria: "AJUSTE_CONCILIACION",
      Documento_Relacionado: String(payload.Conciliacion_ID),
      Tipo_Doc_Rel: "CONCILIACION",
    },
    codUsuario
  );

  if (!result.ok || !result.movimientoId) {
    return { ok: false, mensaje: "No se pudo generar el ajuste" };
  }

  await conciliarMovimientos(payload.Conciliacion_ID, result.movimientoId, undefined, codUsuario);

  // Best-effort: generar asiento contable y vincular
  try {
    const acctResult = await emitBankMovementAccountingEntry({
      movimientoId: result.movimientoId,
      nroCta: accountNo,
      tipo,
      monto: Math.abs(Number(payload.Monto ?? 0)),
      beneficiario: "AJUSTE CONCILIACION",
      concepto: payload.Descripcion ?? "Ajuste bancario",
      nroRef: `AJ-${payload.Conciliacion_ID}-${Date.now()}`,
    }, codUsuario);
    if (acctResult.ok && acctResult.asientoId) {
      await linkMovementToEntry(result.movimientoId, acctResult.asientoId);
    }
  } catch { /* best-effort: never block bank operation */ }

  return { ok: true, mensaje: "Ajuste generado" };
}

export async function cerrarConciliacion(
  Conciliacion_ID: number,
  Saldo_Final_Banco: number,
  Observaciones?: string,
  codUsuario?: string
): Promise<{ ok: boolean; diferencia?: number; estado?: string }> {
  const userId = await resolveUserId(codUsuario);

  try {
    const { rows, output } = await callSpOut<{ diferencia: number; estado: string }>(
      "usp_Bank_Reconciliation_Close",
      {
        Id: Conciliacion_ID,
        BankClosing: Number(Saldo_Final_Banco ?? 0),
        Notes: String(Observaciones ?? "").trim() || null,
        ClosedByUserId: userId,
      },
      { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
    );

    const resultado = Number(output.Resultado ?? 0);
    if (resultado === 0) return { ok: false };

    const row = rows[0];
    const diferencia = Number(row?.diferencia ?? 0);
    const estado = String(row?.estado ?? "CLOSED");

    // Best-effort: generar asiento de cierre si hay diferencia
    try {
      const saldoSistema = Number(row?.diferencia ?? 0) + Number(Saldo_Final_Banco ?? 0);
      // Obtener nroCta para el asiento
      const acctRows = await callSp<{ accountNo: string }>(
        "usp_Bank_Reconciliation_GetAccountNoById",
        { Id: Conciliacion_ID }
      );
      const nroCta = String(acctRows[0]?.accountNo ?? "").trim();
      if (nroCta) {
        await emitConciliacionClosingEntry(
          Conciliacion_ID, saldoSistema, Number(Saldo_Final_Banco ?? 0), nroCta, codUsuario
        );
      }
    } catch { /* best-effort */ }

    return { ok: true, diferencia, estado };
  } catch {
    return { ok: false };
  }
}

export async function getCuentasBancarias(): Promise<any[]> {
  const scope = await getScope();

  const rows = await callSp<any>(
    "usp_Bank_Account_List",
    { CompanyId: scope.companyId }
  );

  return rows;
}

export async function getMovimientosCuenta(
  Nro_Cta: string,
  desde?: string,
  hasta?: string,
  page: number = 1,
  limit: number = 50
): Promise<{ rows: any[]; total: number }> {
  const scope = await getScope();
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(Math.max(1, Number(limit) || 50), 500);
  const offset = (safePage - 1) * safeLimit;

  const fromDate = desde ? toSqlDate(desde) : null;
  const toDate = hasta ? toSqlDate(hasta) : null;

  const { rows, output } = await callSpOut<any>(
    "usp_Bank_Movement_ListByAccount",
    {
      CompanyId: scope.companyId,
      NroCta: String(Nro_Cta ?? "").trim(),
      FromDate: fromDate,
      ToDate: toDate,
      Offset: offset,
      Limit: safeLimit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
  };
}

export async function getMovimientoById(movimientoId: number): Promise<any | null> {
  const rows = await callSp<any>(
    "sp_GetMovimientoBancarioById",
    { MovimientoId: movimientoId }
  );
  return rows[0] ?? null;
}
