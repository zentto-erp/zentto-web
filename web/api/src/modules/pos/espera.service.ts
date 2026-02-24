import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

function escXml(v: unknown): string {
    if (v === null || v === undefined) return "";
    return String(v).replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

interface CartItem {
    productoId: string;
    codigo?: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    descuento?: number;
    iva?: number;
    subtotal: number;
}

// ═════════════════════════════════════════════════════
// VENTAS EN ESPERA
// ═════════════════════════════════════════════════════

export async function crearEspera(data: {
    cajaId: string;
    estacionNombre?: string;
    codUsuario?: string;
    clienteId?: string;
    clienteNombre?: string;
    clienteRif?: string;
    tipoPrecio?: string;
    motivo?: string;
    items: CartItem[];
}) {
    const xmlItems = data.items.map((d, idx) =>
        `<item prodId="${escXml(d.productoId)}" cod="${escXml(d.codigo)}" nom="${escXml(d.nombre)}" cant="${d.cantidad}" precio="${d.precioUnitario}" desc="${d.descuento ?? 0}" iva="${d.iva ?? 16}" sub="${d.subtotal}" ord="${idx}" />`
    ).join("");
    const xmlStr = `<items>${xmlItems}</items>`;

    const pool = await getPool();
    const req = pool.request();
    req.input("CajaId", sql.NVarChar(10), data.cajaId);
    req.input("EstacionNombre", sql.NVarChar(50), data.estacionNombre ?? null);
    req.input("CodUsuario", sql.NVarChar(10), data.codUsuario ?? null);
    req.input("ClienteId", sql.NVarChar(12), data.clienteId ?? null);
    req.input("ClienteNombre", sql.NVarChar(100), data.clienteNombre ?? null);
    req.input("ClienteRif", sql.NVarChar(20), data.clienteRif ?? null);
    req.input("TipoPrecio", sql.NVarChar(20), data.tipoPrecio ?? "Detal");
    req.input("Motivo", sql.NVarChar(200), data.motivo ?? null);
    req.input("DetalleXml", sql.Xml, xmlStr);
    req.output("EsperaId", sql.Int);
    await req.execute("usp_POS_Espera_Crear");
    return { ok: true, esperaId: req.parameters.EsperaId?.value as number };
}

export async function listEspera() {
    try {
        const pool = await getPool();
        const result = await pool.request().execute("usp_POS_Espera_List");
        return { rows: result.recordset ?? [] };
    } catch { }
    const rows = await query<any>(
        "SELECT Id AS id, CajaId AS cajaId, EstacionNombre AS estacionNombre, ClienteNombre AS clienteNombre, Motivo AS motivo, Total AS total, FechaCreacion AS fechaCreacion FROM PosVentasEnEspera WHERE Estado='espera' ORDER BY FechaCreacion"
    );
    return { rows };
}

export async function recuperarEspera(id: number, recuperadoPor?: string, recuperadoEn?: string) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("Id", sql.Int, id);
        req.input("RecuperadoPor", sql.NVarChar(10), recuperadoPor ?? null);
        req.input("RecuperadoEn", sql.NVarChar(10), recuperadoEn ?? null);
        const result = await req.execute("usp_POS_Espera_Recuperar");
        const sets = result.recordsets as any[][];
        const header = sets?.[0]?.[0] ?? null;
        const items = sets?.[1] ?? [];
        if (!header) return { ok: false, error: "not_found" };
        return { ok: true, header, items };
    } catch (e: any) {
        return { ok: false, error: e.message };
    }
}

export async function anularEspera(id: number) {
    const pool = await getPool();
    const req = pool.request();
    req.input("Id", sql.Int, id);
    await req.execute("usp_POS_Espera_Anular");
    return { ok: true };
}

// ═════════════════════════════════════════════════════
// VENTAS COMPLETADAS
// ═════════════════════════════════════════════════════

export async function registrarVenta(data: {
    numFactura: string;
    cajaId: string;
    codUsuario?: string;
    clienteId?: string;
    clienteNombre?: string;
    clienteRif?: string;
    tipoPrecio?: string;
    metodoPago?: string;
    tramaFiscal?: string;
    esperaOrigenId?: number;
    items: CartItem[];
}) {
    const xmlItems = data.items.map(d =>
        `<item prodId="${escXml(d.productoId)}" cod="${escXml(d.codigo)}" nom="${escXml(d.nombre)}" cant="${d.cantidad}" precio="${d.precioUnitario}" desc="${d.descuento ?? 0}" iva="${d.iva ?? 16}" sub="${d.subtotal}" />`
    ).join("");
    const xmlStr = `<items>${xmlItems}</items>`;

    const pool = await getPool();
    const req = pool.request();
    req.input("NumFactura", sql.NVarChar(20), data.numFactura);
    req.input("CajaId", sql.NVarChar(10), data.cajaId);
    req.input("CodUsuario", sql.NVarChar(10), data.codUsuario ?? null);
    req.input("ClienteId", sql.NVarChar(12), data.clienteId ?? null);
    req.input("ClienteNombre", sql.NVarChar(100), data.clienteNombre ?? null);
    req.input("ClienteRif", sql.NVarChar(20), data.clienteRif ?? null);
    req.input("TipoPrecio", sql.NVarChar(20), data.tipoPrecio ?? "Detal");
    req.input("MetodoPago", sql.NVarChar(50), data.metodoPago ?? null);
    req.input("TramaFiscal", sql.NVarChar(sql.MAX), data.tramaFiscal ?? null);
    req.input("EsperaOrigenId", sql.Int, data.esperaOrigenId ?? null);
    req.input("DetalleXml", sql.Xml, xmlStr);
    req.output("VentaId", sql.Int);
    await req.execute("usp_POS_Venta_Crear");
    return { ok: true, ventaId: req.parameters.VentaId?.value as number };
}
