import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";
import { emitFiscalRecordFromTransaction } from "../fiscal/service.js";
import { getCountryTaxRates, getFiscalConfig } from "../fiscal/service.js";
import { CountryCode } from "../fiscal/types.js";
import { emitSaleAccountingEntry, reprocessRestauranteAccounting } from "../contabilidad/integracion.service.js";

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
        let pedidoId = req.parameters.PedidoId?.value as number | undefined;
        if (!Number.isFinite(Number(pedidoId)) || Number(pedidoId) <= 0) {
            const rows = await query<{ id: number }>(
                `
                SELECT TOP 1 Id AS id
                FROM RestaurantePedidos
                WHERE MesaId = @mesaId
                  AND Estado <> 'cerrado'
                ORDER BY Id DESC
                `,
                { mesaId }
            );
            pedidoId = rows[0]?.id;
        }
        return { ok: true, pedidoId, executionMode: "sp" as const };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

let hasRestPedidoItemAgregarIvaParamCache: boolean | null = null;
let hasRestaurantePedidoItemIvaColumnCache: boolean | null = null;

async function hasRestPedidoItemAgregarIvaParam() {
    if (hasRestPedidoItemAgregarIvaParamCache !== null) {
        return hasRestPedidoItemAgregarIvaParamCache;
    }
    const rows = await query<{ ok: number }>(
        `
        SELECT CASE WHEN EXISTS(
            SELECT 1
            FROM sys.parameters p
            INNER JOIN sys.objects o ON p.object_id = o.object_id
            WHERE o.name = 'usp_REST_PedidoItem_Agregar'
              AND p.name = '@Iva'
        ) THEN 1 ELSE 0 END AS ok
        `
    );
    hasRestPedidoItemAgregarIvaParamCache = Number(rows?.[0]?.ok ?? 0) === 1;
    return hasRestPedidoItemAgregarIvaParamCache;
}

async function hasRestaurantePedidoItemIvaColumn() {
    if (hasRestaurantePedidoItemIvaColumnCache !== null) {
        return hasRestaurantePedidoItemIvaColumnCache;
    }
    const rows = await query<{ ok: number }>(
        `
        SELECT CASE WHEN EXISTS(
            SELECT 1
            FROM sys.columns c
            INNER JOIN sys.tables t ON c.object_id = t.object_id
            WHERE t.name = 'RestaurantePedidoItems'
              AND c.name = 'IvaPct'
        ) THEN 1 ELSE 0 END AS ok
        `
    );
    hasRestaurantePedidoItemIvaColumnCache = Number(rows?.[0]?.ok ?? 0) === 1;
    return hasRestaurantePedidoItemIvaColumnCache;
}

export async function agregarItemPedido(params: {
    pedidoId: number;
    productoId: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    iva?: number;
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
        if (await hasRestPedidoItemAgregarIvaParam()) {
            req.input("Iva", sql.Decimal(9, 4), params.iva ?? null);
        }
        req.input("EsCompuesto", sql.Bit, params.esCompuesto ?? false);
        req.input("Componentes", sql.NVarChar(sql.MAX), params.componentes ?? null);
        req.input("Comentarios", sql.NVarChar(500), params.comentarios ?? null);
        req.output("ItemId", sql.Int);
        await req.execute("usp_REST_PedidoItem_Agregar");
        let itemId = req.parameters.ItemId?.value as number | undefined;
        if (!Number.isFinite(Number(itemId)) || Number(itemId) <= 0) {
            const rows = await query<{ id: number }>(
                `
                SELECT TOP 1 Id AS id
                FROM RestaurantePedidoItems
                WHERE PedidoId = @pedidoId
                ORDER BY Id DESC
                `,
                { pedidoId: params.pedidoId }
            );
            itemId = rows[0]?.id;
        }
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

async function getPedidoHeaderForClose(pedidoId: number) {
    const rows = await query<any>(
        `
        SELECT TOP 1
          Id AS id,
          MesaId AS mesaId,
          ClienteNombre AS clienteNombre,
          ClienteRif AS clienteRif,
          Estado AS estado,
          Total AS total,
          CodUsuario AS codUsuario
        FROM RestaurantePedidos
        WHERE Id = @pedidoId
        `,
        { pedidoId }
    );
    return rows[0] ?? null;
}

interface RestaurantePedidoItemFiscal {
    id: number;
    productoId: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    subtotal: number;
    itemIvaPct?: number | null;
    productIvaPct?: number | null;
}

interface RestaurantFiscalBreakdown {
    lines: Array<{
        itemId: number;
        productoId: string;
        nombre: string;
        quantity: number;
        unitPrice: number;
        baseAmount: number;
        taxCode: string;
        taxRate: number;
        taxAmount: number;
        totalAmount: number;
    }>;
    taxSummary: Array<{
        taxCode: string;
        taxRate: number;
        baseAmount: number;
        taxAmount: number;
        totalAmount: number;
    }>;
    baseAmount: number;
    taxAmount: number;
    totalAmount: number;
    taxCode: string;
    taxRate: number;
    sourceTotal: number;
}

function round2(value: number) {
    return Math.round((value + Number.EPSILON) * 100) / 100;
}

function round4(value: number) {
    return Math.round((value + Number.EPSILON) * 10000) / 10000;
}

function normalizeTaxRate(raw: unknown): number | null {
    const value = Number(raw);
    if (!Number.isFinite(value) || value < 0) return null;
    if (value > 1) return round4(value / 100);
    return round4(value);
}

async function getPedidoItemsForFiscal(pedidoId: number): Promise<RestaurantePedidoItemFiscal[]> {
    const hasIvaColumn = await hasRestaurantePedidoItemIvaColumn();
    const rows = await query<any>(
        hasIvaColumn
            ? `
              SELECT
                i.Id AS id,
                i.ProductoId AS productoId,
                i.Nombre AS nombre,
                i.Cantidad AS cantidad,
                i.PrecioUnitario AS precioUnitario,
                i.Subtotal AS subtotal,
                i.IvaPct AS itemIvaPct,
                inv.PORCENTAJE AS productIvaPct
              FROM RestaurantePedidoItems i
              LEFT JOIN Inventario inv ON LTRIM(RTRIM(inv.CODIGO)) = LTRIM(RTRIM(i.ProductoId))
              WHERE i.PedidoId = @pedidoId
              ORDER BY i.Id
            `
            : `
              SELECT
                i.Id AS id,
                i.ProductoId AS productoId,
                i.Nombre AS nombre,
                i.Cantidad AS cantidad,
                i.PrecioUnitario AS precioUnitario,
                i.Subtotal AS subtotal,
                CAST(NULL AS DECIMAL(9,4)) AS itemIvaPct,
                inv.PORCENTAJE AS productIvaPct
              FROM RestaurantePedidoItems i
              LEFT JOIN Inventario inv ON LTRIM(RTRIM(inv.CODIGO)) = LTRIM(RTRIM(i.ProductoId))
              WHERE i.PedidoId = @pedidoId
              ORDER BY i.Id
            `,
        { pedidoId }
    );

    return rows.map((row) => ({
        id: Number(row.id ?? 0),
        productoId: String(row.productoId ?? ""),
        nombre: String(row.nombre ?? ""),
        cantidad: Number(row.cantidad ?? 0),
        precioUnitario: Number(row.precioUnitario ?? 0),
        subtotal: Number(row.subtotal ?? 0),
        itemIvaPct: row.itemIvaPct !== null && row.itemIvaPct !== undefined ? Number(row.itemIvaPct) : null,
        productIvaPct: row.productIvaPct !== null && row.productIvaPct !== undefined ? Number(row.productIvaPct) : null,
    }));
}

async function inferCountryCodeFromFiscalConfig(empresaId: number, sucursalId: number): Promise<CountryCode> {
    const hasConfigTable = await query<{ hasTable: number }>(
        `
        SELECT CASE WHEN EXISTS(
            SELECT 1
            FROM sys.tables
            WHERE name = 'FiscalCountryConfig'
        ) THEN 1 ELSE 0 END AS hasTable
        `
    );
    if (Number(hasConfigTable?.[0]?.hasTable ?? 0) !== 1) return "VE";

    const rows = await query<{ CountryCode: string }>(
        `
        SELECT TOP 1 CountryCode
        FROM FiscalCountryConfig
        WHERE EmpresaId = @empresaId
          AND SucursalId = @sucursalId
          AND IsActive = 1
        ORDER BY UpdatedAt DESC, Id DESC
        `,
        { empresaId, sucursalId }
    );
    return String(rows[0]?.CountryCode ?? "VE").toUpperCase() === "ES" ? "ES" : "VE";
}

async function resolveRestaurantTaxContext(params: {
    empresaId: number;
    sucursalId: number;
    countryCode: CountryCode;
}) {
    const config = await getFiscalConfig({
        empresaId: params.empresaId,
        sucursalId: params.sucursalId,
        countryCode: params.countryCode,
    });
    const taxes = getCountryTaxRates(params.countryCode);
    const ivaCandidates = taxes.filter((tax) => !String(tax.code).startsWith("RE_"));

    const byConfigCode = ivaCandidates.find((tax) => tax.code === config.defaultTaxCode);
    if (byConfigCode) {
        return {
            defaultTaxCode: byConfigCode.code,
            defaultTaxRate: Number(byConfigCode.rate),
            ivaCandidates,
        };
    }

    const restaurantTax = ivaCandidates.find((tax) => tax.appliesToRestaurant && tax.rate > 0);
    if (restaurantTax) {
        return {
            defaultTaxCode: restaurantTax.code,
            defaultTaxRate: Number(restaurantTax.rate),
            ivaCandidates,
        };
    }

    const firstTax = ivaCandidates[0];
    return {
        defaultTaxCode: config.defaultTaxCode || firstTax?.code || "IVA_GENERAL",
        defaultTaxRate: Number(config.defaultTaxRate ?? firstTax?.rate ?? 0),
        ivaCandidates,
    };
}

function resolveTaxProfileForRate(params: {
    rate: number | null;
    defaultTaxCode: string;
    defaultTaxRate: number;
    ivaCandidates: Array<{ code: string; rate: number }>;
}) {
    const { rate, defaultTaxCode, defaultTaxRate, ivaCandidates } = params;
    if (rate === null) {
        return { taxCode: defaultTaxCode, taxRate: defaultTaxRate };
    }

    const exact = ivaCandidates.find((tax) => Math.abs(Number(tax.rate) - rate) < 0.0005);
    if (exact) {
        return { taxCode: exact.code, taxRate: Number(exact.rate) };
    }

    return { taxCode: defaultTaxCode, taxRate: defaultTaxRate };
}

async function buildRestaurantFiscalBreakdown(params: {
    pedidoId: number;
    empresaId: number;
    sucursalId: number;
    countryCode: CountryCode;
    sourceTotal: number;
}): Promise<RestaurantFiscalBreakdown> {
    const items = await getPedidoItemsForFiscal(params.pedidoId);
    const taxContext = await resolveRestaurantTaxContext({
        empresaId: params.empresaId,
        sucursalId: params.sucursalId,
        countryCode: params.countryCode,
    });

    const lines = items.map((item) => {
        const resolvedRate = normalizeTaxRate(item.itemIvaPct ?? item.productIvaPct ?? null);
        const taxProfile = resolveTaxProfileForRate({
            rate: resolvedRate,
            defaultTaxCode: taxContext.defaultTaxCode,
            defaultTaxRate: taxContext.defaultTaxRate,
            ivaCandidates: taxContext.ivaCandidates.map((tax) => ({ code: tax.code, rate: tax.rate })),
        });
        const baseAmount = round2(Number(item.subtotal ?? 0));
        const taxAmount = round2(baseAmount * taxProfile.taxRate);
        const totalAmount = round2(baseAmount + taxAmount);
        return {
            itemId: item.id,
            productoId: item.productoId,
            nombre: item.nombre,
            quantity: round2(Number(item.cantidad ?? 0)),
            unitPrice: round2(Number(item.precioUnitario ?? 0)),
            baseAmount,
            taxCode: taxProfile.taxCode,
            taxRate: taxProfile.taxRate,
            taxAmount,
            totalAmount,
        };
    });

    const baseAmount = round2(lines.reduce((acc, line) => acc + line.baseAmount, 0));
    const taxAmount = round2(lines.reduce((acc, line) => acc + line.taxAmount, 0));
    const totalAmount = round2(baseAmount + taxAmount);
    const taxSummaryMap = new Map<string, {
        taxCode: string;
        taxRate: number;
        baseAmount: number;
        taxAmount: number;
        totalAmount: number;
    }>();
    for (const line of lines) {
        const key = `${line.taxCode}|${round4(line.taxRate)}`;
        const current = taxSummaryMap.get(key) ?? {
            taxCode: line.taxCode,
            taxRate: line.taxRate,
            baseAmount: 0,
            taxAmount: 0,
            totalAmount: 0,
        };
        current.baseAmount = round2(current.baseAmount + line.baseAmount);
        current.taxAmount = round2(current.taxAmount + line.taxAmount);
        current.totalAmount = round2(current.totalAmount + line.totalAmount);
        taxSummaryMap.set(key, current);
    }
    const taxSummary = Array.from(taxSummaryMap.values()).sort((a, b) => {
        if (a.taxRate === b.taxRate) return a.taxCode.localeCompare(b.taxCode);
        return a.taxRate - b.taxRate;
    });
    const mainTax = taxSummary.length === 1 ? taxSummary[0] : null;

    return {
        lines,
        taxSummary,
        baseAmount,
        taxAmount,
        totalAmount,
        taxCode: mainTax?.taxCode ?? "MULTI_IVA",
        taxRate: mainTax?.taxRate ?? 0,
        sourceTotal: round2(params.sourceTotal),
    };
}

export async function cerrarPedido(params: {
    pedidoId: number;
    empresaId?: number;
    sucursalId?: number;
    countryCode?: CountryCode;
    codUsuario?: string;
    invoiceNumber?: string;
    invoiceDate?: string;
    invoiceTypeHint?: string;
    fiscalPrinterSerial?: string;
    fiscalControlNumber?: string;
    zReportNumber?: number;
}) {
    try {
        const pedidoActual = await getPedidoHeaderForClose(params.pedidoId);
        if (!pedidoActual) {
            return { ok: false, error: "pedido_not_found", executionMode: "ts_fallback" as const };
        }

        const pool = await getPool();
        const req = pool.request();
        req.input("PedidoId", sql.Int, params.pedidoId);
        await req.execute("usp_REST_Pedido_Cerrar");

        const alreadyClosed = String(pedidoActual.estado ?? "").toLowerCase() === "cerrado";

        const invoiceNumber = String(params.invoiceNumber ?? "").trim() || `REST-${params.pedidoId}`;
        const empresaId = Number(params.empresaId ?? 1);
        const sucursalId = Number(params.sucursalId ?? 0);
        const countryCode = params.countryCode ?? (await inferCountryCodeFromFiscalConfig(empresaId, sucursalId));
        const sourceTotal = Number(pedidoActual.total ?? 0);

        let fiscalBreakdown: RestaurantFiscalBreakdown | null = null;
        try {
            fiscalBreakdown = await buildRestaurantFiscalBreakdown({
                pedidoId: params.pedidoId,
                empresaId,
                sucursalId,
                countryCode,
                sourceTotal,
            });
        } catch {
            fiscalBreakdown = null;
        }

        const totalAmount = Number(
            fiscalBreakdown?.totalAmount && fiscalBreakdown.totalAmount > 0
                ? fiscalBreakdown.totalAmount
                : sourceTotal
        );

        let fiscal: Awaited<ReturnType<typeof emitFiscalRecordFromTransaction>> | { ok: false; reason: string };
        if (alreadyClosed) {
            fiscal = {
                ok: true,
                skipped: true,
                reason: "pedido_already_closed"
            };
        } else {
            try {
                fiscal = await emitFiscalRecordFromTransaction({
                    empresaId,
                    sucursalId,
                    countryCode,
                    sourceModule: "RESTAURANTE",
                    invoiceId: Number(params.pedidoId),
                    invoiceNumber,
                    invoiceDate: params.invoiceDate ? new Date(params.invoiceDate) : new Date(),
                    invoiceTypeHint: params.invoiceTypeHint,
                    recipientId: pedidoActual.clienteRif ? String(pedidoActual.clienteRif) : undefined,
                    totalAmount,
                    payload: {
                        mesaId: pedidoActual.mesaId,
                        clienteNombre: pedidoActual.clienteNombre,
                        fiscalBreakdown,
                    },
                    metadata: {
                        fiscalPrinterSerial: params.fiscalPrinterSerial,
                        fiscalControlNumber: params.fiscalControlNumber,
                        zReportNumber: params.zReportNumber,
                        sourceTotal,
                        calculatedTotal: totalAmount,
                        breakdownSource: fiscalBreakdown ? "items" : "header_total",
                    }
                });
            } catch (fiscalError: any) {
                fiscal = {
                    ok: false,
                    reason: `fiscal_emit_exception:${String(fiscalError?.message ?? fiscalError)}`
                };
            }
        }

        const baseAmount = Number(fiscalBreakdown?.baseAmount ?? sourceTotal);
        const taxAmount = Number(fiscalBreakdown?.taxAmount ?? Math.max(0, totalAmount - sourceTotal));

        let contabilidad: Awaited<ReturnType<typeof emitSaleAccountingEntry>>;
        try {
            contabilidad = await emitSaleAccountingEntry({
                module: "RESTAURANTE",
                sourceId: Number(params.pedidoId),
                documentNumber: invoiceNumber,
                issueDate: params.invoiceDate ? new Date(params.invoiceDate) : new Date(),
                paymentMethod: "CAJA",
                codUsuario: params.codUsuario ?? (pedidoActual.codUsuario ? String(pedidoActual.codUsuario) : undefined),
                currency: countryCode === "ES" ? "EUR" : "VES",
                exchangeRate: 1,
                baseAmount,
                taxAmount,
                totalAmount,
                taxSummary: fiscalBreakdown?.taxSummary
            });
        } catch (accountingError: any) {
            contabilidad = {
                ok: false,
                reason: `accounting_emit_exception:${String(accountingError?.message ?? accountingError)}`
            };
        }

        return { ok: true, executionMode: "sp" as const, alreadyClosed, fiscal, contabilidad };
    } catch (e: any) {
        return { ok: false, error: e.message, executionMode: "sp" as const };
    }
}

export async function contabilizarPedidoExistente(params: {
    pedidoId: number;
    codUsuario?: string;
    countryCode?: CountryCode;
    currency?: string;
    exchangeRate?: number;
    invoiceNumber?: string;
}) {
    return reprocessRestauranteAccounting({
        pedidoId: params.pedidoId,
        codUsuario: params.codUsuario,
        countryCode: params.countryCode,
        currency: params.currency,
        exchangeRate: params.exchangeRate,
        invoiceNumber: params.invoiceNumber,
    });
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
        const hasIvaColumn = await hasRestaurantePedidoItemIvaColumn();
        items = await query<any>(
            hasIvaColumn
                ? "SELECT i.Id AS id, i.ProductoId AS productoId, i.Nombre AS nombre, i.Cantidad AS cantidad, i.PrecioUnitario AS precioUnitario, i.Subtotal AS subtotal, i.IvaPct AS iva, i.Estado AS estado, i.EnviadoACocina AS enviadoACocina FROM RestaurantePedidoItems i WHERE i.PedidoId = @pedidoId ORDER BY i.Id"
                : "SELECT i.Id AS id, i.ProductoId AS productoId, i.Nombre AS nombre, i.Cantidad AS cantidad, i.PrecioUnitario AS precioUnitario, i.Subtotal AS subtotal, inv.PORCENTAJE AS iva, i.Estado AS estado, i.EnviadoACocina AS enviadoACocina FROM RestaurantePedidoItems i LEFT JOIN Inventario inv ON LTRIM(RTRIM(inv.CODIGO)) = LTRIM(RTRIM(i.ProductoId)) WHERE i.PedidoId = @pedidoId ORDER BY i.Id",
            { pedidoId: pedido.id }
        );
    }
    return { pedido, items, executionMode: "ts_fallback" as const };
}
