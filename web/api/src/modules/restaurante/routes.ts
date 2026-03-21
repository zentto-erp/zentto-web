import { Router } from "express";
import { z } from "zod";
import { listMesas, abrirPedido, agregarItemPedido, enviarComanda, cerrarPedido, getPedidoByMesa, contabilizarPedidoExistente, cancelarItemPedido } from "./service.js";
import type { AuthenticatedRequest } from "../../middleware/auth.js";

export const restauranteRouter = Router();

// Mesas
restauranteRouter.get("/mesas", async (req, res) => {
    try {
        const ambienteId = req.query.ambienteId as string | undefined;
        const data = await listMesas(ambienteId);
        res.json(data);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// Pedido activo por mesa
restauranteRouter.get("/mesas/:mesaId/pedido", async (req, res) => {
    try {
        const mesaId = Number(req.params.mesaId);
        if (isNaN(mesaId)) return res.status(400).json({ error: "mesaId invalido" });
        const data = await getPedidoByMesa(mesaId);
        res.json(data);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// Abrir pedido en mesa
const abrirSchema = z.object({
    mesaId: z.number(),
    clienteNombre: z.string().optional(),
    clienteRif: z.string().optional(),
    codUsuario: z.string().optional(),
});

restauranteRouter.post("/pedidos/abrir", async (req, res) => {
    const parsed = abrirSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    const result = await abrirPedido(parsed.data.mesaId, parsed.data.clienteNombre, parsed.data.clienteRif, parsed.data.codUsuario);
    res.status(result.ok ? 201 : 400).json(result);
});

// Agregar item a pedido
const itemSchema = z.object({
    pedidoId: z.coerce.number().int().positive(),
    productoId: z.string().trim().min(1),
    nombre: z.string().trim().min(1),
    cantidad: z.coerce.number().positive(),
    precioUnitario: z.coerce.number().nonnegative(),
    iva: z.coerce.number().min(0).max(100).optional(),
    esCompuesto: z.boolean().optional(),
    componentes: z.string().optional(),
    comentarios: z.string().optional(),
});

restauranteRouter.post("/pedidos/item", async (req, res) => {
    const parsed = itemSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    const result = await agregarItemPedido(parsed.data);
    res.status(result.ok ? 201 : 400).json(result);
});

const cancelarItemSchema = z.object({
    motivo: z.string().trim().max(200).optional(),
    supervisorUser: z.string().trim().min(1),
    supervisorPassword: z.string().optional(),
    biometricBypass: z.boolean().optional(),
    biometricCredentialId: z.string().trim().max(512).optional(),
});

restauranteRouter.post("/pedidos/:pedidoId/items/:itemId/cancelar", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    const itemId = Number(req.params.itemId);
    if (!Number.isFinite(pedidoId) || pedidoId <= 0) return res.status(400).json({ error: "pedidoId invalido" });
    if (!Number.isFinite(itemId) || itemId <= 0) return res.status(400).json({ error: "itemId invalido" });

    const parsed = cancelarItemSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });

    const result = await cancelarItemPedido({
        pedidoId,
        itemId,
        motivo: parsed.data.motivo,
        supervisorUser: parsed.data.supervisorUser,
        supervisorPassword: parsed.data.supervisorPassword ?? "",
        biometricBypass: Boolean(parsed.data.biometricBypass),
        biometricCredentialId: parsed.data.biometricCredentialId ?? null,
        requestedByUser: (req as AuthenticatedRequest).user?.sub,
    });

    if (!result.ok && (result.error === "pedido_not_found" || result.error === "item_not_found")) {
        return res.status(404).json(result);
    }
    return res.status(result.ok ? 200 : 400).json(result);
});

// Enviar comanda a cocina
restauranteRouter.post("/pedidos/:pedidoId/comanda", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    if (isNaN(pedidoId)) return res.status(400).json({ error: "pedidoId invalido" });
    const result = await enviarComanda(pedidoId);
    res.json(result);
});

// Cerrar pedido
const cerrarSchema = z.object({
    empresaId: z.number().int().positive().optional(),
    sucursalId: z.number().int().nonnegative().optional(),
    countryCode: z.string().length(2).toUpperCase().optional(),
    codUsuario: z.string().optional(),
    invoiceNumber: z.string().optional(),
    invoiceDate: z.string().optional(),
    invoiceTypeHint: z.string().optional(),
    fiscalPrinterSerial: z.string().optional(),
    fiscalControlNumber: z.string().optional(),
    zReportNumber: z.number().int().optional(),
});

restauranteRouter.post("/pedidos/:pedidoId/cerrar", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    if (isNaN(pedidoId)) return res.status(400).json({ error: "pedidoId invalido" });

    const parsed = cerrarSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });

    const result = await cerrarPedido({
        pedidoId,
        ...parsed.data,
    });
    res.json(result);
});

const contabilizarPedidoSchema = z.object({
    codUsuario: z.string().optional(),
    countryCode: z.string().length(2).toUpperCase().optional(),
    currency: z.string().optional(),
    exchangeRate: z.number().positive().optional(),
    invoiceNumber: z.string().optional(),
});

restauranteRouter.post("/pedidos/:pedidoId/contabilizar", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    if (!Number.isFinite(pedidoId) || pedidoId <= 0) return res.status(400).json({ error: "pedidoId invalido" });

    const parsed = contabilizarPedidoSchema.safeParse(req.body ?? {});
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });

    const result = await contabilizarPedidoExistente({
        pedidoId,
        codUsuario: parsed.data.codUsuario,
        countryCode: parsed.data.countryCode,
        currency: parsed.data.currency,
        exchangeRate: parsed.data.exchangeRate,
        invoiceNumber: parsed.data.invoiceNumber,
    });

    if (!result.ok && !result.skipped) return res.status(400).json(result);
    if (result.skipped && result.reason === "pedido_not_found") return res.status(404).json(result);
    return res.json(result);
});
