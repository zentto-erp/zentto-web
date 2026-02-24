import { Router } from "express";
import { z } from "zod";
import {
    listProductosPOS,
    getProductoByCodigo,
    searchClientesPOS,
    listCategoriasPOS,
    getPosReportResumen,
    listPosReportVentas,
    listPosReportProductosTop,
    listPosReportFormasPago,
} from "./service.js";

export const posRouter = Router();

// ═══ Productos POS ═══
const productosSchema = z.object({
    search: z.string().optional(),
    categoria: z.string().optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
});

posRouter.get("/productos", async (req, res) => {
    const parsed = productosSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await listProductosPOS({
        search: parsed.data.search,
        categoria: parsed.data.categoria,
        page: parsed.data.page ? Number(parsed.data.page) : undefined,
        limit: parsed.data.limit ? Number(parsed.data.limit) : undefined,
    });
    res.json(data);
});

posRouter.get("/productos/:codigo", async (req, res) => {
    const result = await getProductoByCodigo(req.params.codigo);
    if (!result.row) return res.status(404).json({ error: "not_found" });
    res.json(result.row);
});

// ═══ Clientes POS ═══
posRouter.get("/clientes", async (req, res) => {
    const search = req.query.search as string | undefined;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    const data = await searchClientesPOS(search, limit);
    res.json(data);
});

// ═══ Categorías POS ═══
posRouter.get("/categorias", async (_req, res) => {
    const data = await listCategoriasPOS();
    res.json(data);
});

// ═══ Reportes POS ═══
const reporteSchema = z.object({
    from: z.string().optional(),
    to: z.string().optional(),
});

const reporteConLimitSchema = reporteSchema.extend({
    limit: z.coerce.number().int().min(1).max(500).optional(),
});

posRouter.get("/reportes/resumen", async (req, res) => {
    const parsed = reporteSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await getPosReportResumen(parsed.data);
    res.json(data);
});

posRouter.get("/reportes/ventas", async (req, res) => {
    const parsed = reporteConLimitSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await listPosReportVentas(parsed.data);
    res.json(data);
});

posRouter.get("/reportes/productos-top", async (req, res) => {
    const parsed = reporteConLimitSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await listPosReportProductosTop(parsed.data);
    res.json(data);
});

posRouter.get("/reportes/formas-pago", async (req, res) => {
    const parsed = reporteSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await listPosReportFormasPago(parsed.data);
    res.json(data);
});
