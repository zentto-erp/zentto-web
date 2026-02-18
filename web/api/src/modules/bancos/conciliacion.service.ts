/**
 * Conciliacion Bancaria Service
 * Maneja conciliaciones bancarias, extractos y ajustes
 */
import { getPool, sql } from "../../db/mssql.js";

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
  Tipo: string;           // PCH, DEP, NCR, NDB
  Nro_Ref: string;
  Beneficiario: string;
  Monto: number;
  Concepto: string;
  Categoria?: string;
  Documento_Relacionado?: string;
  Tipo_Doc_Rel?: string;
}

export interface ExtractoPayload {
  Nro_Cta?: string;       // Opcional, se obtiene de la conciliación
  Fecha: string;
  Descripcion?: string;
  Referencia?: string;
  Tipo: "DEBITO" | "CREDITO";
  Monto: number;
  Saldo?: number;
}

export interface AjustePayload {
  Conciliacion_ID: number;
  Tipo_Ajuste: string;    // NOTA_CREDITO, NOTA_DEBITO
  Monto: number;
  Descripcion: string;
}

export interface ConciliacionResult {
  conciliacionId: number;
  saldoInicial: number;
  saldoFinal: number;
}

// Generar movimiento bancario desde pago/cobro
export async function generarMovimientoBancario(
  payload: MovimientoBancarioPayload,
  codUsuario?: string
): Promise<{ ok: boolean; movimientoId?: number; saldoNuevo?: number }> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Nro_Cta", sql.NVarChar(20), payload.Nro_Cta);
  request.input("Tipo", sql.NVarChar(10), payload.Tipo);
  request.input("Nro_Ref", sql.NVarChar(30), payload.Nro_Ref);
  request.input("Beneficiario", sql.NVarChar(255), payload.Beneficiario);
  request.input("Monto", sql.Decimal(18, 2), payload.Monto);
  request.input("Concepto", sql.NVarChar(100), payload.Concepto);
  request.input("Categoria", sql.NVarChar(50), payload.Categoria || null);
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");
  request.input("Documento_Relacionado", sql.NVarChar(60), payload.Documento_Relacionado || null);
  request.input("Tipo_Doc_Rel", sql.NVarChar(20), payload.Tipo_Doc_Rel || null);

  const result = await request.execute("sp_GenerarMovimientoBancario");
  return result.recordset[0];
}

// Crear nueva conciliacion
export async function crearConciliacion(
  Nro_Cta: string,
  Fecha_Desde: string,
  Fecha_Hasta: string,
  codUsuario?: string
): Promise<ConciliacionResult> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Nro_Cta", sql.NVarChar(20), Nro_Cta);
  request.input("Fecha_Desde", sql.DateTime, new Date(Fecha_Desde));
  request.input("Fecha_Hasta", sql.DateTime, new Date(Fecha_Hasta));
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");

  const result = await request.execute("sp_CrearConciliacion");
  return result.recordset[0];
}

// Listar conciliaciones
export async function listConciliaciones(params: {
  Nro_Cta?: string;
  Estado?: string;
  page?: number;
  limit?: number;
}): Promise<{ rows: ConciliacionRow[]; total: number; page: number; limit: number }> {
  const pool = await getPool();
  const request = pool.request();

  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);

  request.input("Nro_Cta", sql.NVarChar(20), params.Nro_Cta || null);
  request.input("Estado", sql.NVarChar(20), params.Estado || null);
  request.input("Page", sql.Int, page);
  request.input("Limit", sql.Int, limit);
  request.output("TotalCount", sql.Int);

  const result = await request.execute("sp_Conciliacion_List");

  return {
    rows: result.recordset || [],
    total: result.output.TotalCount || 0,
    page,
    limit,
  };
}

// Obtener detalle de conciliacion
export async function getConciliacion(
  Conciliacion_ID: number
): Promise<{
  cabecera: ConciliacionRow | null;
  movimientosSistema: any[];
  extractoPendiente: any[];
}> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Conciliacion_ID", sql.Int, Conciliacion_ID);

  const result = await request.execute("sp_Conciliacion_Get");
  const recordsets = result.recordsets as unknown as Array<Array<Record<string, unknown>>>;

  return {
    cabecera: recordsets[0]?.[0] || null,
    movimientosSistema: recordsets[1] || [],
    extractoPendiente: recordsets[2] || [],
  };
}

// Importar extracto bancario
export async function importarExtracto(
  Nro_Cta: string,
  extractoRows: ExtractoPayload[],
  codUsuario?: string
): Promise<{ ok: boolean; registrosImportados?: number }> {
  const pool = await getPool();

  // Convertir a XML
  let xml = "<extracto>";
  for (const row of extractoRows) {
    xml += `<row Fecha="${row.Fecha}" Descripcion="${row.Descripcion || ""}" Referencia="${row.Referencia || ""}" Tipo="${row.Tipo}" Monto="${row.Monto}" Saldo="${row.Saldo || ""}"/>`;
  }
  xml += "</extracto>";

  const request = pool.request();
  request.input("ExtractoXml", sql.NVarChar(sql.MAX), xml);
  request.input("Nro_Cta", sql.NVarChar(20), Nro_Cta);
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");

  const result = await request.execute("sp_ImportarExtracto");
  return result.recordset[0];
}

// Conciliar movimientos
export async function conciliarMovimientos(
  Conciliacion_ID: number,
  MovimientoSistema_ID: number,
  Extracto_ID?: number,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Conciliacion_ID", sql.Int, Conciliacion_ID);
  request.input("MovimientoSistema_ID", sql.Int, MovimientoSistema_ID);
  request.input("Extracto_ID", sql.Int, Extracto_ID || null);
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");

  const result = await request.execute("sp_ConciliarMovimientos");
  return result.recordset[0];
}

// Generar ajuste bancario (Nota Credito/Debito)
export async function generarAjusteBancario(
  payload: AjustePayload,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Conciliacion_ID", sql.Int, payload.Conciliacion_ID);
  request.input("Tipo_Ajuste", sql.NVarChar(20), payload.Tipo_Ajuste);
  request.input("Monto", sql.Decimal(18, 2), payload.Monto);
  request.input("Descripcion", sql.NVarChar(255), payload.Descripcion);
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");

  const result = await request.execute("sp_GenerarAjusteBancario");
  return result.recordset[0];
}

// Cerrar conciliacion
export async function cerrarConciliacion(
  Conciliacion_ID: number,
  Saldo_Final_Banco: number,
  Observaciones?: string,
  codUsuario?: string
): Promise<{ ok: boolean; diferencia?: number; estado?: string }> {
  const pool = await getPool();
  const request = pool.request();

  request.input("Conciliacion_ID", sql.Int, Conciliacion_ID);
  request.input("Saldo_Final_Banco", sql.Decimal(18, 2), Saldo_Final_Banco);
  request.input("Observaciones", sql.NVarChar(500), Observaciones || null);
  request.input("Co_Usuario", sql.NVarChar(60), codUsuario || "API");

  const result = await request.execute("sp_CerrarConciliacion");
  return result.recordset[0];
}

// Obtener cuentas bancarias
export async function getCuentasBancarias(): Promise<any[]> {
  const pool = await getPool();
  const result = await pool.request().query(`
    SELECT cb.Nro_Cta, cb.Banco, cb.Descripcion, cb.Moneda, 
           cb.Saldo, cb.Saldo_Disponible, b.Nombre as BancoNombre
    FROM CuentasBank cb
    LEFT JOIN Bancos b ON b.Nombre = cb.Banco
    ORDER BY cb.Banco, cb.Nro_Cta
  `);
  return result.recordset || [];
}

// Obtener movimientos de cuenta
export async function getMovimientosCuenta(
  Nro_Cta: string,
  desde?: string,
  hasta?: string,
  page: number = 1,
  limit: number = 50
): Promise<{ rows: any[]; total: number }> {
  const pool = await getPool();
  const offset = (page - 1) * limit;

  let whereClause = "WHERE Nro_Cta = @Nro_Cta";
  if (desde) whereClause += " AND Fecha >= @Desde";
  if (hasta) whereClause += " AND Fecha <= @Hasta";

  const countResult = await pool.request()
    .input("Nro_Cta", sql.NVarChar(20), Nro_Cta)
    .input("Desde", sql.DateTime, desde ? new Date(desde) : null)
    .input("Hasta", sql.DateTime, hasta ? new Date(hasta) : null)
    .query(`SELECT COUNT(1) as total FROM MovCuentas ${whereClause}`);

  const result = await pool.request()
    .input("Nro_Cta", sql.NVarChar(20), Nro_Cta)
    .input("Desde", sql.DateTime, desde ? new Date(desde) : null)
    .input("Hasta", sql.DateTime, hasta ? new Date(hasta) : null)
    .input("Offset", sql.Int, offset)
    .input("Limit", sql.Int, limit)
    .query(`
      SELECT * FROM MovCuentas 
      ${whereClause}
      ORDER BY Fecha DESC, id DESC
      OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
    `);

  return {
    rows: result.recordset || [],
    total: countResult.recordset[0]?.total || 0,
  };
}
