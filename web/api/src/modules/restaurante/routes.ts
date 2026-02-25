import { Router } from "express";
import { z } from "zod";
import { listMesas, abrirPedido, agregarItemPedido, enviarComanda, cerrarPedido, getPedidoByMesa } from "./service.js";

export const restauranteRouter = Router();

// ═══ Mesas ═══
restauranteRouter.get("/mesas", async (req, res) => {
    const ambienteId = req.query.ambienteId as string | undefined;
    const data = await listMesas(ambienteId);
    res.json(data);
});

// ═══ Pedido activo por mesa ═══
restauranteRouter.get("/mesas/:mesaId/pedido", async (req, res) => {
    const mesaId = Number(req.params.mesaId);
    if (isNaN(mesaId)) return res.status(400).json({ error: "mesaId inválido" });
    const data = await getPedidoByMesa(mesaId);
    res.json(data);
});

// ═══ Abrir pedido en mesa ═══
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

// ═══ Agregar item a pedido ═══
const itemSchema = z.object({
    pedidoId: z.coerce.number().int().positive(),
    productoId: z.string().trim().min(1),
    nombre: z.string().trim().min(1),
    cantidad: z.coerce.number().positive(),
    precioUnitario: z.coerce.number().nonnegative(),
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

// ═══ Enviar comanda a cocina ═══
restauranteRouter.post("/pedidos/:pedidoId/comanda", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    if (isNaN(pedidoId)) return res.status(400).json({ error: "pedidoId inválido" });
    const result = await enviarComanda(pedidoId);
    res.json(result);
});

// ═══ Cerrar pedido ═══
restauranteRouter.post("/pedidos/:pedidoId/cerrar", async (req, res) => {
    const pedidoId = Number(req.params.pedidoId);
    if (isNaN(pedidoId)) return res.status(400).json({ error: "pedidoId inválido" });
    const result = await cerrarPedido(pedidoId);
    res.json(result);
});
