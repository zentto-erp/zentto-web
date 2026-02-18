/**
 * Servicio de Nómina
 * Maneja cálculo de nómina, vacaciones y liquidación
 */
import { getPool, sql } from "../../db/mssql.js";

// Tipos
export interface ConceptoNomina {
  codigo: string;
  codigoNomina: string;
  nombre: string;
  formula?: string;
  sobre?: string;
  clase?: string;
  tipo?: "ASIGNACION" | "DEDUCCION" | "BONO";
  uso?: string;
  bonificable?: string;
  esAntiguedad?: string;
  cuentaContable?: string;
  aplica?: string;
  valorDefecto?: number;
}

export interface NominaCabecera {
  nomina: string;
  cedula: string;
  nombreEmpleado?: string;
  cargo?: string;
  fechaProceso?: Date;
  fechaInicio?: Date;
  fechaHasta?: Date;
  totalAsignaciones?: number;
  totalDeducciones?: number;
  totalNeto?: number;
  cerrada?: boolean;
  tipoNomina?: string;
}

export interface NominaDetalle {
  coConcepto?: string;
  nombreConcepto?: string;
  tipoConcepto?: string;
  cantidad?: number;
  monto?: number;
  total?: number;
  descripcion?: string;
  cuentaContable?: string;
}

export interface Vacacion {
  vacacion: string;
  cedula: string;
  nombreEmpleado?: string;
  inicio?: Date;
  hasta?: Date;
  reintegro?: Date;
  fechaCalculo?: Date;
  total?: number;
  totalCalculado?: number;
}

// Listar conceptos de nómina
export async function listConceptos(params: {
  coNomina?: string;
  tipo?: string;
  search?: string;
  page?: number;
  limit?: number;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CoNomina", sql.NVarChar(15), params.coNomina || null);
  request.input("Tipo", sql.NVarChar(15), params.tipo || null);
  request.input("Search", sql.NVarChar(100), params.search || null);
  request.input("Page", sql.Int, params.page || 1);
  request.input("Limit", sql.Int, Math.min(params.limit || 50, 500));
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Nomina_Conceptos_List");

  return {
    rows: (result.recordset || []) as ConceptoNomina[],
    total: (request.parameters.TotalCount?.value as number) ?? 0,
  };
}

// Guardar concepto
export async function saveConcepto(data: Partial<ConceptoNomina>) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("CoConcept", sql.NVarChar(10), data.codigo);
  request.input("CoNomina", sql.NVarChar(15), data.codigoNomina);
  request.input("NbConcepto", sql.NVarChar(100), data.nombre);
  request.input("Formula", sql.NVarChar(255), data.formula || null);
  request.input("Sobre", sql.NVarChar(255), data.sobre || null);
  request.input("Clase", sql.NVarChar(15), data.clase || null);
  request.input("Tipo", sql.NVarChar(15), data.tipo || null);
  request.input("Uso", sql.NVarChar(15), data.uso || null);
  request.input("Bonificable", sql.NVarChar(1), data.bonificable || null);
  request.input("Antiguedad", sql.NVarChar(1), data.esAntiguedad || null);
  request.input("Contable", sql.NVarChar(50), data.cuentaContable || null);
  request.input("Aplica", sql.NVarChar(1), data.aplica || "S");
  request.input("Defecto", sql.Float, data.valorDefecto || null);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_Concepto_Save");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Procesar nómina de un empleado
export async function procesarNominaEmpleado(payload: {
  nomina: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.nomina);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaInicio", sql.Date, payload.fechaInicio);
  request.input("FechaHasta", sql.Date, payload.fechaHasta);
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarEmpleado");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Procesar nómina completa
export async function procesarNominaCompleta(payload: {
  nomina: string;
  fechaInicio: string;
  fechaHasta: string;
  soloActivos?: boolean;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.nomina);
  request.input("FechaInicio", sql.Date, payload.fechaInicio);
  request.input("FechaHasta", sql.Date, payload.fechaHasta);
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.input("SoloActivos", sql.Bit, payload.soloActivos ?? true);
  request.output("Procesados", sql.Int);
  request.output("Errores", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarNomina");

  return {
    procesados: (request.parameters.Procesados?.value as number) ?? 0,
    errores: (request.parameters.Errores?.value as number) ?? 0,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Listar nóminas
export async function listNominas(params: {
  nomina?: string;
  cedula?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  soloAbiertas?: boolean;
  page?: number;
  limit?: number;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), params.nomina || null);
  request.input("Cedula", sql.NVarChar(12), params.cedula || null);
  request.input("FechaDesde", sql.Date, params.fechaDesde || null);
  request.input("FechaHasta", sql.Date, params.fechaHasta || null);
  request.input("SoloAbiertas", sql.Bit, params.soloAbiertas || false);
  request.input("Page", sql.Int, params.page || 1);
  request.input("Limit", sql.Int, Math.min(params.limit || 50, 500));
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Nomina_List");

  return {
    rows: (result.recordset || []) as NominaCabecera[],
    total: (request.parameters.TotalCount?.value as number) ?? 0,
  };
}

// Obtener detalle de nómina
export async function getNomina(nomina: string, cedula: string) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), nomina);
  request.input("Cedula", sql.NVarChar(12), cedula);

  const result = await request.execute("sp_Nomina_Get");
  const recordsets = result.recordsets as unknown as Array<Array<Record<string, unknown>>>;

  return {
    cabecera: (recordsets[0]?.[0] as unknown as NominaCabecera) || null,
    detalle: (recordsets[1] || []) as unknown as NominaDetalle[],
  };
}

// Cerrar nómina
export async function cerrarNomina(payload: {
  nomina: string;
  cedula?: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.nomina);
  request.input("Cedula", sql.NVarChar(12), payload.cedula || null);
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_Cerrar");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Procesar vacaciones
export async function procesarVacaciones(payload: {
  vacacionId: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  fechaReintegro?: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("VacacionID", sql.NVarChar(50), payload.vacacionId);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaInicio", sql.Date, payload.fechaInicio);
  request.input("FechaHasta", sql.Date, payload.fechaHasta);
  request.input("FechaReintegro", sql.Date, payload.fechaReintegro || null);
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarVacaciones");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Listar vacaciones
export async function listVacaciones(params: {
  cedula?: string;
  page?: number;
  limit?: number;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Cedula", sql.NVarChar(12), params.cedula || null);
  request.input("Page", sql.Int, params.page || 1);
  request.input("Limit", sql.Int, Math.min(params.limit || 50, 500));
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Nomina_Vacaciones_List");

  return {
    rows: (result.recordset || []) as Vacacion[],
    total: (request.parameters.TotalCount?.value as number) ?? 0,
  };
}

// Obtener detalle de vacaciones
export async function getVacaciones(vacacionId: string) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("VacacionID", sql.NVarChar(50), vacacionId);

  const result = await request.execute("sp_Nomina_Vacaciones_Get");
  const recordsets = result.recordsets as unknown as Array<Array<Record<string, unknown>>>;

  return {
    cabecera: recordsets[0]?.[0] || null,
    detalle: recordsets[1] || [],
  };
}

// Calcular liquidación
export async function calcularLiquidacion(payload: {
  liquidacionId: string;
  cedula: string;
  fechaRetiro: string;
  causaRetiro?: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("LiquidacionID", sql.NVarChar(50), payload.liquidacionId);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaRetiro", sql.Date, payload.fechaRetiro);
  request.input("CausaRetiro", sql.NVarChar(50), payload.causaRetiro || "RENUNCIA");
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_CalcularLiquidacion");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Listar liquidaciones
export async function listLiquidaciones(params: {
  cedula?: string;
  page?: number;
  limit?: number;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Cedula", sql.NVarChar(12), params.cedula || null);
  request.input("Page", sql.Int, params.page || 1);
  request.input("Limit", sql.Int, Math.min(params.limit || 50, 500));
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Nomina_Liquidaciones_List");

  return {
    rows: result.recordset || [],
    total: (request.parameters.TotalCount?.value as number) ?? 0,
  };
}

// Obtener detalle de liquidación
export async function getLiquidacion(liquidacionId: string) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("LiquidacionID", sql.NVarChar(50), liquidacionId);

  const result = await request.execute("sp_Nomina_GetLiquidacion");
  const recordsets = result.recordsets as unknown as Array<Array<Record<string, unknown>>>;

  return {
    detalle: recordsets[0] || [],
    totales: recordsets[1]?.[0] || null,
  };
}

// Listar constantes
export async function listConstantes(params: { page?: number; limit?: number }) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Page", sql.Int, params.page || 1);
  request.input("Limit", sql.Int, Math.min(params.limit || 50, 500));
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Nomina_Constantes_List");

  return {
    rows: result.recordset || [],
    total: (request.parameters.TotalCount?.value as number) ?? 0,
  };
}

// Guardar constante
export async function saveConstante(data: {
  codigo: string;
  nombre?: string;
  valor?: number;
  origen?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Codigo", sql.NVarChar(50), data.codigo);
  request.input("Nombre", sql.NVarChar(100), data.nombre || null);
  request.input("Valor", sql.Float, data.valor || null);
  request.input("Origen", sql.NVarChar(50), data.origen || null);
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_Constante_Save");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}
