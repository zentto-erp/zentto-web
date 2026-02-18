import sql from "mssql";
import { getPool } from "../../db/mssql.js";
import { query } from "../../db/query.js";

// Tipos
export interface DocumentoAplicar {
  tipoDoc: string;
  numDoc: string;
  montoAplicar: number;
}

export interface FormaPago {
  formaPago: string;
  monto: number;
  banco?: string;
  numCheque?: string;
  fechaVencimiento?: string;
}

export interface AplicarPagoInput {
  requestId: string;
  codProveedor: string;
  fecha: string;
  montoTotal: number;
  codUsuario: string;
  observaciones?: string;
  documentos: DocumentoAplicar[];
  formasPago: FormaPago[];
}

export interface AplicarPagoResult {
  success: boolean;
  numPago?: string;
  message: string;
}

/**
 * Convierte array de documentos a XML para SQL Server 2012
 */
function documentosToXml(documentos: DocumentoAplicar[]): string {
  const esc = (v: unknown) =>
    String(v ?? "")
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/'/g, "&apos;");

  const rows = documentos
    .map(
      (d) =>
        `  <row tipoDoc="${esc(d.tipoDoc)}" numDoc="${esc(d.numDoc)}" montoAplicar="${esc(d.montoAplicar)}"/>`
    )
    .join("\n");
  return `<documentos>\n${rows}\n</documentos>`;
}

/**
 * Convierte array de formas de pago a XML para SQL Server 2012
 */
function formasPagoToXml(formasPago: FormaPago[]): string {
  const esc = (v: unknown) =>
    String(v ?? "")
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/'/g, "&apos;");

  const rows = formasPago
    .map(
      (fp) =>
        `  <row formaPago="${esc(fp.formaPago)}" monto="${esc(fp.monto)}"` +
        `${fp.banco ? ` banco="${esc(fp.banco)}"` : ""}` +
        `${fp.numCheque ? ` numCheque="${esc(fp.numCheque)}"` : ""}` +
        `${fp.fechaVencimiento ? ` fechaVencimiento="${esc(fp.fechaVencimiento)}"` : ""}/>`
    )
    .join("\n");
  return `<formasPago>\n${rows}\n</formasPago>`;
}

/**
 * Aplica un pago a documentos de proveedores usando Stored Procedure
 * Optimizado para SQL Server 2012 - usa XML para pasar arrays
 */
export async function aplicarPago(
  input: AplicarPagoInput
): Promise<AplicarPagoResult> {
  const pool = await getPool();
  const request = new sql.Request(pool);

  // Configurar parámetros de entrada
  request.input("RequestId", sql.VarChar(100), input.requestId);
  request.input("CodProveedor", sql.VarChar(20), input.codProveedor);
  request.input("Fecha", sql.VarChar(10), input.fecha);
  request.input("MontoTotal", sql.Decimal(18, 2), input.montoTotal);
  request.input("CodUsuario", sql.VarChar(20), input.codUsuario);
  request.input(
    "Observaciones",
    sql.VarChar(500),
    input.observaciones || ""
  );

  // Convertir arrays a XML (compatible con SQL 2012)
  request.input(
    "DocumentosXml",
    sql.NVarChar(sql.MAX),
    documentosToXml(input.documentos)
  );
  request.input(
    "FormasPagoXml",
    sql.NVarChar(sql.MAX),
    formasPagoToXml(input.formasPago)
  );

  // Parámetros de salida
  request.output("NumPago", sql.VarChar(50));
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.VarChar(500));

  // Ejecutar SP
  const result = await request.execute("usp_CxP_AplicarPago");

  const resultado = result.output.Resultado as number;
  const mensaje = result.output.Mensaje as string;
  const numPago = result.output.NumPago as string;

  return {
    success: resultado === 1,
    numPago: numPago || undefined,
    message: mensaje,
  };
}

// Alias para compatibilidad
export const aplicarPagoTx = aplicarPago;

/**
 * Obtiene los documentos pendientes de un proveedor
 */
export async function getDocumentosPendientes(codProveedor: string) {
  const rows = await query<any>(`
    SELECT 
      TIPO AS tipoDoc,
      DOCUMENTO AS numDoc,
      FECHA AS fecha,
      ISNULL(PEND, ISNULL(SALDO, 0)) AS pendiente,
      ISNULL(HABER, 0) AS total
    FROM P_Pagar
    WHERE CODIGO = @codProveedor
      AND ISNULL(PEND, ISNULL(SALDO, 0)) > 0
      AND PAID = 0
    ORDER BY FECHA ASC
  `, { codProveedor });

  return rows;
}

/**
 * Obtiene el saldo total de un proveedor
 */
export async function getSaldoProveedor(codProveedor: string) {
  const rows = await query<any>(`
    SELECT 
      ISNULL(SALDO_TOT, 0) AS saldoTotal,
      ISNULL(SALDO_30, 0) AS saldo30,
      ISNULL(SALDO_60, 0) AS saldo60,
      ISNULL(SALDO_90, 0) AS saldo90,
      ISNULL(SALDO_91, 0) AS saldo91
    FROM Proveedores
    WHERE CODIGO = @codProveedor
  `, { codProveedor });

  return rows[0] || null;
}
