import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

// ─── Mesas ───

export async function listMesas(ambienteId?: string) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("AmbienteId", sql.NVarChar(10), ambienteId ?? null);
        const result = await req.execute("usp_REST_Mesas_List");
        return { rows: result.recordset ?? [], executionMode: "sp" as const };
    } catch { }

    const where = ambienteId ? "WHERE Activa = 1 AND AmbienteId = @ambienteId" : "WHERE Activa = 1";
    const rows = await query<any>(
        `SELECT Id AS id, Numero AS numero, Nombre AS nombre, Capacidad AS capacidad, AmbienteId AS ambienteId, Ambiente AS ambiente, PosicionX AS posicionX, PosicionY AS posicionY, Estado AS estado FROM RestauranteMesas ${where} ORDER BY AmbienteId, Numero`,
        ambienteId ? { ambienteId } : {}
    );
    return { rows, executionMode: "ts_fallback" as const };
}

// ─── Pedidos ───

export async function abrirPedido(mesaId: number, clienteNombre?: string, clienteRif?: string, codUsuario?: string) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("MesaId", sql.Int, mesaId);
        req.input("ClienteNombre", sql.NVarChar(100), clienteNombre ?? null);
        req.input("ClienteRif", sql.NVarChar(20), clienteRif ?? null);
        req.input("CodUsuario", sql.NVarChar(10), codUsuario ?? null);
        req.output("PedidoId", sql.Int);
        await req.execute("usp_REST_Pedido_Abrir");
        const pedidoId = req.parameters.PedidoId?.value as number;
        return { ok: true, pedidoId, executionMode: "sp" as const };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

export async function agregarItemPedido(params: {
    pedidoId: number;
    productoId: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    esCompuesto?: boolean;
    componentes?: string;
    comentarios?: string;
}) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("PedidoId", sql.Int, params.pedidoId);
        req.input("ProductoId", sql.NVarChar(50), params.productoId);
        req.input("Nombre", sql.NVarChar(200), params.nombre);
        req.input("Cantidad", sql.Decimal(10, 3), params.cantidad);
        req.input("PrecioUnitario", sql.Decimal(18, 2), params.precioUnitario);
        req.input("EsCompuesto", sql.Bit, params.esCompuesto ?? false);
        req.input("Componentes", sql.NVarChar(sql.MAX), params.componentes ?? null);
        req.input("Comentarios", sql.NVarChar(500), params.comentarios ?? null);
        req.output("ItemId", sql.Int);
        await req.execute("usp_REST_PedidoItem_Agregar");
        const itemId = req.parameters.ItemId?.value as number;
        return { ok: true, itemId, executionMode: "sp" as const };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

export async function enviarComanda(pedidoId: number) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("PedidoId", sql.Int, pedidoId);
        await req.execute("usp_REST_Comanda_Enviar");
        return { ok: true, executionMode: "sp" as const };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

export async function cerrarPedido(pedidoId: number) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("PedidoId", sql.Int, pedidoId);
        await req.execute("usp_REST_Pedido_Cerrar");
        return { ok: true, executionMode: "sp" as const };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

export async function getPedidoByMesa(mesaId: number) {
    try {
        const pool = await getPool();
        const req = pool.request();
        req.input("MesaId", sql.Int, mesaId);
        const result = await req.execute("usp_REST_Pedido_GetByMesa");
        const sets = result.recordsets as any[][];
        const pedido = sets?.[0]?.[0] ?? null;
        const items = sets?.[1] ?? [];
        return { pedido, items, executionMode: "sp" as const };
    } catch { }

    const pedidos = await query<any>(
        "SELECT TOP 1 Id AS id, MesaId AS mesaId, ClienteNombre AS clienteNombre, ClienteRif AS clienteRif, Estado AS estado, Total AS total FROM RestaurantePedidos WHERE MesaId = @mesaId AND Estado NOT IN ('cerrado') ORDER BY FechaApertura DESC",
        { mesaId }
    );
    const pedido = pedidos[0] ?? null;
    let items: any[] = [];
    if (pedido) {
        items = await query<any>(
            "SELECT Id AS id, ProductoId AS productoId, Nombre AS nombre, Cantidad AS cantidad, PrecioUnitario AS precioUnitario, Subtotal AS subtotal, Estado AS estado, EnviadoACocina AS enviadoACocina FROM RestaurantePedidoItems WHERE PedidoId = @pedidoId ORDER BY Id",
            { pedidoId: pedido.id }
        );
    }
    return { pedido, items, executionMode: "ts_fallback" as const };
}
