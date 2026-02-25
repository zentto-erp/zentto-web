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
    listPosReportCajas,
    listCorrelativosFiscales,
    upsertCorrelativoFiscal,
} from "./service.js";

export const posRouter = Router();

const DEFAULT_LOCAL_FISCAL_AGENT = "http://localhost:5059";

function normalizeAgentUrl(raw?: string) {
    const value = (raw || "").trim();
    if (!value) return DEFAULT_LOCAL_FISCAL_AGENT;
    return value.replace(/\/$/, "");
}

async function proxyFiscalGet(res: any, path: string, query: Record<string, string | undefined>) {
    try {
        const agentUrl = normalizeAgentUrl(query.agentUrl);
        const params = new URLSearchParams();
        Object.entries(query).forEach(([key, value]) => {
            if (key === "agentUrl") return;
            if (value !== undefined && value !== null && String(value).trim() !== "") {
                params.set(key, String(value));
            }
        });
        const qs = params.toString();
        const target = `${agentUrl}${path}${qs ? `?${qs}` : ""}`;
        const response = await fetch(target);
        const text = await response.text();
        let data: unknown = { raw: text };
        try {
            data = JSON.parse(text);
        } catch {
            // raw fallback
        }
        return res.status(response.status).json(data);
    } catch (error: any) {
        return res.status(502).json({
            success: false,
            message: error?.message || "No se pudo conectar con el Agente Fiscal local",
        });
    }
}

async function proxyFiscalPost(res: any, path: string, body: Record<string, unknown>) {
    try {
        const agentUrl = normalizeAgentUrl(typeof body.agentUrl === "string" ? body.agentUrl : undefined);
        const { agentUrl: _agentUrl, ...payload } = body;
        const response = await fetch(`${agentUrl}${path}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
        });
        const text = await response.text();
        let data: unknown = { raw: text };
        try {
            data = JSON.parse(text);
        } catch {
            // raw fallback
        }
        return res.status(response.status).json(data);
    } catch (error: any) {
        return res.status(502).json({
            success: false,
            message: error?.message || "No se pudo conectar con el Agente Fiscal local",
        });
    }
}

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
    cajaId: z.string().optional(),
});

const reporteConLimitSchema = reporteSchema.extend({
    limit: z.coerce.number().int().min(1).max(500).optional(),
});

const correlativoFiscalSchema = z.object({
    cajaId: z.string().optional(),
    serialFiscal: z.string().min(1),
    correlativoActual: z.coerce.number().int().min(0).optional(),
    descripcion: z.string().optional(),
});

posRouter.get("/correlativos-fiscales", async (req, res) => {
    const cajaId = (req.query.cajaId as string | undefined)?.trim();
    const data = await listCorrelativosFiscales({ cajaId });
    res.json(data);
});

posRouter.put("/correlativos-fiscales", async (req, res) => {
    const parsed = correlativoFiscalSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    const data = await upsertCorrelativoFiscal(parsed.data);
    res.json(data);
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

posRouter.get("/reportes/cajas", async (req, res) => {
    const parsed = reporteSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    const data = await listPosReportCajas(parsed.data);
    res.json(data);
});

// ═══ Proxy Fiscal (Agente Local) ═══
const fiscalActionSchema = z.object({
    marca: z.string().min(1),
    puerto: z.string().min(1),
    conexion: z.string().min(1),
    agentUrl: z.string().url().optional(),
});

const fiscalPrintSchema = fiscalActionSchema.extend({
    cliente: z.record(z.any()).optional(),
    items: z.array(z.record(z.any())).optional(),
});

const fiscalDocumentoNoFiscalSchema = fiscalActionSchema.extend({
    titulo: z.string().optional(),
    lineas: z.array(z.string()).optional(),
});

posRouter.get("/fiscal/metodos", async (req, res) => {
    return proxyFiscalGet(res, "/api/fiscal/metodos", {
        agentUrl: req.query.agentUrl as string | undefined,
    });
});

posRouter.get("/fiscal/status", async (req, res) => {
    return proxyFiscalGet(res, "/api/fiscal/status", {
        marca: req.query.marca as string | undefined,
        puerto: req.query.puerto as string | undefined,
        conexion: req.query.conexion as string | undefined,
        agentUrl: req.query.agentUrl as string | undefined,
    });
});

posRouter.post("/fiscal/reporte/x", async (req, res) => {
    const parsed = fiscalActionSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    return proxyFiscalPost(res, "/api/fiscal/reporte/x", parsed.data as Record<string, unknown>);
});

posRouter.post("/fiscal/reporte/z", async (req, res) => {
    const parsed = fiscalActionSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    return proxyFiscalPost(res, "/api/fiscal/reporte/z", parsed.data as Record<string, unknown>);
});

posRouter.get("/fiscal/reporte/mensual", async (req, res) => {
    return proxyFiscalGet(res, "/api/fiscal/reporte/mensual", {
        anio: req.query.anio as string | undefined,
        mes: req.query.mes as string | undefined,
        marca: req.query.marca as string | undefined,
        puerto: req.query.puerto as string | undefined,
        conexion: req.query.conexion as string | undefined,
        agentUrl: req.query.agentUrl as string | undefined,
    });
});

posRouter.get("/fiscal/memoria", async (req, res) => {
    return proxyFiscalGet(res, "/api/fiscal/memoria", {
        marca: req.query.marca as string | undefined,
        puerto: req.query.puerto as string | undefined,
        conexion: req.query.conexion as string | undefined,
        agentUrl: req.query.agentUrl as string | undefined,
    });
});

posRouter.post("/fiscal/documento-no-fiscal", async (req, res) => {
    const parsed = fiscalDocumentoNoFiscalSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    return proxyFiscalPost(res, "/api/fiscal/documento-no-fiscal", parsed.data as Record<string, unknown>);
});

posRouter.post("/fiscal/print", async (req, res) => {
    const parsed = fiscalPrintSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    return proxyFiscalPost(res, "/api/print", parsed.data as Record<string, unknown>);
});
