import { query } from "../../db/query.js";
import { getPool, sql } from "../../db/mssql.js";
import { createRow, deleteRow, encodeKeyObject, updateRow } from "../crud/crud.service.js";
import { runHeaderDetailTx } from "../shared/tx.js";

function escapeXml(value: unknown): string {
  const s = value === null || value === undefined ? "" : String(value);
  return s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&apos;");
}
function recordToXmlAttrs(row: Record<string, unknown>): string {
  return Object.entries(row)
    .filter(([, v]) => v !== undefined && v !== null)
    .map(([k, v]) => `${k}="${escapeXml(v)}"`)
    .join(" ");
}
export type EmitirPresupuestoPayload = {
  presupuesto?: Record<string, unknown>;
  factura?: Record<string, unknown>;
  detalle: Record<string, unknown>[];
  formasPago?: Record<string, unknown>[];
  options?: {
    actualizarInventario?: boolean;
    generarCxC?: boolean;
    cxcTable?: "P_Cobrar" | "P_CobrarC";
    formaPagoTable?: string;
    actualizarSaldosCliente?: boolean;
  };
};
function presupuestoPayloadToXml(payload: EmitirPresupuestoPayload) {
  const header = payload.presupuesto ?? payload.factura ?? {};
  const presupuestoAttrs = recordToXmlAttrs(header);
  const detalleRows = (payload.detalle ?? []).map((r) => `<row ${recordToXmlAttrs(r)} />`).join("");
  const formasRows = (payload.formasPago ?? []).map((r) => `<row ${recordToXmlAttrs(r)} />`).join("");
  return {
    presupuestoXml: `<presupuesto ${presupuestoAttrs} />`,
    detalleXml: `<detalles>${detalleRows}</detalles>`,
    formasPagoXml: `<formasPago>${formasRows}</formasPago>`
  };
}

export async function listPresupuestos(params: { search?: string; codigo?: string; page?: string; limit?: string }) {
  const page = Math.max(Number(params.page || 1), 1);
  const limit = Math.min(Math.max(Number(params.limit || 50), 1), 500);
  const offset = (page - 1) * limit;
  const where: string[] = [];
  const sqlParams: Record<string, unknown> = {};
  if (params.search) { where.push("(NUM_FACT LIKE @search OR NOMBRE LIKE @search OR RIF LIKE @search)"); sqlParams.search = `%${params.search}%`; }
  if (params.codigo) { where.push("CODIGO = @codigo"); sqlParams.codigo = params.codigo; }
  const clause = where.length ? `WHERE ${where.join(" AND ")}` : "";
  const rows = await query<any>(`SELECT * FROM Presupuestos ${clause} ORDER BY FECHA DESC OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`, sqlParams);
  const total = await query<{ total: number }>(`SELECT COUNT(1) AS total FROM Presupuestos ${clause}`, sqlParams);
  return { page, limit, total: Number(total[0]?.total ?? 0), rows };
}
export async function getPresupuesto(numFact: string) { const rows = await query<any>("SELECT TOP 1 * FROM Presupuestos WHERE NUM_FACT = @numFact", { numFact }); return rows[0] ?? null; }
export async function getPresupuestoDetalle(numFact: string) { return query<any>("SELECT * FROM Detalle_Presupuestos WHERE NUM_FACT = @numFact ORDER BY ID", { numFact }); }
export async function createPresupuesto(body: Record<string, unknown>) { return createRow("dbo", "Presupuestos", body); }
export async function updatePresupuesto(numFact: string, body: Record<string, unknown>) { return updateRow("dbo", "Presupuestos", encodeKeyObject({ NUM_FACT: numFact }), body); }
export async function deletePresupuesto(numFact: string) { return deleteRow("dbo", "Presupuestos", encodeKeyObject({ NUM_FACT: numFact })); }
export async function createPresupuestoTx(payload: { presupuesto: Record<string, unknown>; detalle: Record<string, unknown>[] }) {
  return runHeaderDetailTx({ headerTable: "[dbo].[Presupuestos]", detailTable: "[dbo].[Detalle_Presupuestos]", header: payload.presupuesto ?? {}, details: payload.detalle ?? [], linkFields: ["NUM_FACT", "SERIALTIPO"] });
}

/** Emite presupuesto con lógica de negocio (formas de pago, CxC, inventario). SP primero, fallback a createPresupuestoTx. */
export async function emitirPresupuestoTx(payload: EmitirPresupuestoPayload) {
  const header = payload.presupuesto ?? payload.factura ?? {};
  const detalle = payload.detalle ?? [];
  const formasPago = payload.formasPago ?? [];
  const options = payload.options ?? {};
  const numFact = String(header.NUM_FACT ?? "").trim();
  if (!numFact) throw new Error("missing_num_fact");
  if (!detalle.length) throw new Error("missing_detalle");

  const actualizarInventario = options.actualizarInventario !== false;
  const generarCxC = options.generarCxC !== false;
  const cxcTable: "P_Cobrar" | "P_CobrarC" = options.cxcTable === "P_CobrarC" ? "P_CobrarC" : "P_Cobrar";
  const formaPagoTable = (options.formaPagoTable?.trim() || "Detalle_FormaPagoCotizacion") as string;
  const actualizarSaldos = options.actualizarSaldosCliente !== false;

  try {
    const pool = await getPool();
    const { presupuestoXml, detalleXml, formasPagoXml } = presupuestoPayloadToXml(payload);
    const req = pool.request();
    req.input("PresupuestoXml", sql.NVarChar(sql.MAX), presupuestoXml);
    req.input("DetalleXml", sql.NVarChar(sql.MAX), detalleXml);
    req.input("FormasPagoXml", sql.NVarChar(sql.MAX), formasPagoXml || null);
    req.input("ActualizarInventario", sql.Bit, actualizarInventario ? 1 : 0);
    req.input("GenerarCxC", sql.Bit, generarCxC ? 1 : 0);
    req.input("CxcTable", sql.NVarChar(20), cxcTable);
    req.input("FormaPagoTable", sql.NVarChar(128), formaPagoTable);
    req.input("ActualizarSaldosCliente", sql.Bit, actualizarSaldos ? 1 : 0);

    const spResult = await req.execute("dbo.sp_emitir_presupuesto_tx");
    const row = (spResult.recordset as any[])?.[0];
    if (row?.ok) {
      return {
        ok: true,
        numFact: row.numFact ?? numFact,
        detalleRows: row.detalleRows ?? detalle.length,
        formaPagoRows: formasPago.length,
        montoEfectivo: row.montoEfectivo ?? 0,
        montoCheque: row.montoCheque ?? 0,
        montoTarjeta: row.montoTarjeta ?? 0,
        saldoPendiente: row.saldoPendiente ?? 0,
        abono: row.abono ?? 0,
        executionMode: "sp"
      };
    }
  } catch {
    // Fallback: solo header + detalle (sin CxC/inventario/formas pago)
  }
  await createPresupuestoTx({ presupuesto: header, detalle });
  return { ok: true, numFact, detalleRows: detalle.length, executionMode: "ts_fallback" as const };
}

/** Anula presupuesto (revierte inventario y CxC tipo PRESUP). */
export async function anularPresupuestoTx(params: { numFact: string; codUsuario?: string; motivo?: string }) {
  const { numFact, codUsuario = "API", motivo = "" } = params;
  const pool = await getPool();
  const req = pool.request();
  req.input("NumFact", sql.NVarChar(60), numFact);
  req.input("CodUsuario", sql.NVarChar(60), codUsuario);
  req.input("Motivo", sql.NVarChar(500), motivo);
  const result = await req.execute("dbo.sp_anular_presupuesto_tx");
  const row = (result.recordset as any[])?.[0];
  if (!row?.ok) throw new Error("anulacion_fallo");
  return { ok: true, numFact: row.numFact, codCliente: row.codCliente, mensaje: row.mensaje };
}
