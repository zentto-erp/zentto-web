import { Router, Request, Response } from "express";

export const reportesRouter = Router();

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CONFIGURACIÃ“N DE MOTORES DE REPORTES
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const CRYSTAL_SERVER = process.env.REPORT_SERVER_URL || "http://localhost:5060";
const JSREPORT_SERVER = process.env.JSREPORT_SERVER_URL || "http://localhost:5070";
const SSRS_SERVER = process.env.SSRS_SERVER_URL || "http://localhost/ReportServer";
const SSRS_PORTAL = process.env.SSRS_PORTAL_URL || "http://localhost/Reports";

// â”€â”€â”€ Helper para fetch con timeout â”€â”€â”€
async function safeFetch(url: string, options?: RequestInit, timeoutMs = 5000) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const res = await fetch(url, { ...options, signal: controller.signal });
        return res;
    } finally {
        clearTimeout(timer);
    }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ENDPOINT UNIFICADO: Estado de todos los motores de reportes
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
reportesRouter.get("/engines", async (_req: Request, res: Response) => {
    const engines: any[] = [];

    // Crystal Reports Server
    try {
        const r = await safeFetch(`${CRYSTAL_SERVER}/api/health`);
        const d = await r.json();
        engines.push({ engine: "crystal", status: "online", ...d });
    } catch {
        engines.push({ engine: "crystal", status: "offline", url: CRYSTAL_SERVER });
    }

    // jsreport Server
    try {
        const r = await safeFetch(`${JSREPORT_SERVER}/api/version`);
        const version = await r.text();
        engines.push({ engine: "jsreport", status: "online", version, url: JSREPORT_SERVER, studio: JSREPORT_SERVER });
    } catch {
        engines.push({ engine: "jsreport", status: "offline", url: JSREPORT_SERVER });
    }

    // SSRS
    try {
        const r = await safeFetch(SSRS_SERVER);
        engines.push({
            engine: "ssrs",
            status: r.ok || r.status === 401 ? "online" : "offline",
            httpStatus: r.status,
            url: SSRS_SERVER,
            portal: SSRS_PORTAL,
            note: r.status === 401 ? "Requiere autenticaciÃ³n Windows" : undefined
        });
    } catch {
        engines.push({
            engine: "ssrs",
            status: "offline",
            url: SSRS_SERVER,
            hint: "SSRS necesita ser configurado con 'Reporting Services Configuration Manager'"
        });
    }

    res.json({ engines });
});

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CRYSTAL REPORTS (.NET Framework 4.8) â€” Puerto 5060
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

reportesRouter.get("/crystal/health", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/health`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({
            success: false, service: "Crystal Reports Server", status: "offline",
            message: error?.message || "No disponible",
            hint: "Ejecute DatqBox.ReportServer.exe (puerto 5060)"
        });
    }
});

reportesRouter.get("/crystal/catalogo", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/catalogo`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message || "Crystal Server no disponible" });
    }
});

reportesRouter.get("/crystal/parametros", async (req: Request, res: Response) => {
    try {
        const reporte = req.query.reporte as string;
        if (!reporte) return res.status(400).json({ error: "Falta 'reporte'" });
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/parametros?reporte=${encodeURIComponent(reporte)}`);
        const data = await response.json();
        res.status(response.status).json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});

reportesRouter.post("/crystal/render", async (req: Request, res: Response) => {
    try {
        const body = {
            server: process.env.DB_SERVER || "DELLXEONE31545",
            database: process.env.DB_DATABASE || "sanjose",
            user: process.env.DB_USER || "sa",
            password: process.env.DB_PASSWORD || "1234",
            ...req.body,
        };

        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/render`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
        }, 30000);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: "Error desconocido" }));
            return res.status(response.status).json(errorData);
        }

        const contentType = response.headers.get("content-type") || "application/pdf";
        const contentDisposition = response.headers.get("content-disposition");
        res.setHeader("Content-Type", contentType);
        if (contentDisposition) res.setHeader("Content-Disposition", contentDisposition);

        const buffer = await response.arrayBuffer();
        // nosemgrep: direct-response-write â€” binary report proxy, not user input
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message, hint: "Crystal Server no disponible" });
    }
});

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// JSREPORT (Open Source Node.js) â€” Puerto 5070
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

reportesRouter.get("/jsreport/health", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${JSREPORT_SERVER}/api/version`);
        const version = await response.text();
        res.json({ service: "jsreport", status: "online", version, studio: JSREPORT_SERVER });
    } catch (error: any) {
        res.status(502).json({
            success: false, service: "jsreport", status: "offline",
            message: error?.message, hint: "Ejecute: cd DatqBox.JsReport && node server.js"
        });
    }
});

reportesRouter.get("/jsreport/templates", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${JSREPORT_SERVER}/odata/templates`);
        const data = await response.json();
        res.json({ templates: data.value || [], total: data.value?.length || 0 });
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});

reportesRouter.post("/jsreport/render", async (req: Request, res: Response) => {
    try {
        const { template, data, options } = req.body;

        const jsreportBody: any = {
            template: {
                name: template || req.body.reporte,
                ...(req.body.recipe && { recipe: req.body.recipe }),
                ...(req.body.engine && { engine: req.body.engine }),
            },
            data: data || req.body.parametros || {},
            options: options || {},
        };

        const response = await safeFetch(`${JSREPORT_SERVER}/api/report`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(jsreportBody),
        }, 30000);

        if (!response.ok) {
            const errText = await response.text().catch(() => "Error desconocido");
            return res.status(response.status).json({ error: errText });
        }

        const contentType = response.headers.get("content-type") || "application/pdf";
        const contentDisposition = response.headers.get("content-disposition");
        res.setHeader("Content-Type", contentType);
        if (contentDisposition) res.setHeader("Content-Disposition", contentDisposition);

        const buffer = await response.arrayBuffer();
        // nosemgrep: direct-response-write â€” binary report proxy, not user input
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message, hint: "jsreport no disponible" });
    }
});

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// RUTAS LEGACY (compatibilidad con las rutas originales)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// /health â†’ Crystal por defecto
reportesRouter.get("/health", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/health`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, status: "offline", message: error?.message });
    }
});

// /catalogo â†’ Crystal por defecto
reportesRouter.get("/catalogo", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/catalogo`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});

// /render â†’ Crystal por defecto (backward compatible)
reportesRouter.post("/render", async (req: Request, res: Response) => {
    try {
        const body = {
            server: process.env.DB_SERVER || "DELLXEONE31545",
            database: process.env.DB_DATABASE || "sanjose",
            user: process.env.DB_USER || "sa",
            password: process.env.DB_PASSWORD || "1234",
            ...req.body,
        };

        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/render`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
        }, 30000);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: "Error desconocido" }));
            return res.status(response.status).json(errorData);
        }

        const contentType = response.headers.get("content-type") || "application/pdf";
        const contentDisposition = response.headers.get("content-disposition");
        res.setHeader("Content-Type", contentType);
        if (contentDisposition) res.setHeader("Content-Disposition", contentDisposition);

        const buffer = await response.arrayBuffer();
        // nosemgrep: direct-response-write â€” binary report proxy, not user input
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ZENTTO REPORT ENGINE â€” Saved Report Layouts
// Proxy to zentto-cache for report persistence
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// ZENTTO PDF ENGINE â€” Proxy to pdf-engine service
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

const PDF_ENGINE_URL = process.env.PDF_ENGINE_URL || "http://localhost:5050";

// POST /v1/reportes/pdf â€” generate PDF from layout + data
// Query params: ?format=base64 returns JSON { pdf: "base64string", filename: "..." }
//               ?format=binary (default) returns raw PDF bytes
reportesRouter.post("/pdf", async (req: Request, res: Response) => {
    try {
        const resp = await safeFetch(
            `${PDF_ENGINE_URL}/render/pdf`,
            { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(req.body) },
            30000,
        );
        if (!resp.ok) {
            const err = await resp.text().catch(() => "PDF generation failed");
            return res.status(resp.status).json({ error: err });
        }
        const buffer = await resp.arrayBuffer();
        const renderTime = resp.headers.get("x-render-time-ms");
        const filename = `${req.body?.layout?.name || 'report'}.pdf`;

        // Base64 format for external API consumers
        if (req.query.format === 'base64') {
            const base64 = Buffer.from(buffer).toString('base64');
            return res.json({
                pdf: base64,
                filename,
                mimeType: 'application/pdf',
                sizeBytes: buffer.byteLength,
                renderTimeMs: renderTime ? parseInt(renderTime) : undefined,
            });
        }

        // Binary format (default) for browser download
        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `inline; filename="${filename}"`);
        if (renderTime) res.setHeader("X-Render-Time-Ms", renderTime);
        res.send(Buffer.from(buffer));
    } catch (err: any) {
        res.status(502).json({ error: err?.message || "PDF engine unavailable" });
    }
});

const CACHE_URL = process.env.ZENTTO_CACHE_URL || "http://localhost:4100";
const CACHE_KEY = process.env.ZENTTO_CACHE_KEY || "";

function cacheHeaders(req: Request): Record<string, string> {
    const headers: Record<string, string> = { "Content-Type": "application/json" };
    if (CACHE_KEY) headers["x-app-key"] = CACHE_KEY;
    return headers;
}

function cacheQuery(req: Request): string {
    const companyId = (req as any).companyId || (req as any).jwt?.companyId || "1";
    const userId = (req as any).jwt?.sub || "anonymous";
    return `companyId=${companyId}&userId=${userId}`;
}

// GET /v1/reportes/saved â€” list saved reports
reportesRouter.get("/saved", async (req: Request, res: Response) => {
    try {
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates?${cacheQuery(req)}`,
            { headers: cacheHeaders(req) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "cache_error" });
        const body = await resp.json();
        const ids: string[] = Array.isArray(body) ? body : (body.templateIds ?? body.data ?? []);
        const reports = await Promise.all(ids.map(async (id) => {
            try {
                const r = await safeFetch(
                    `${CACHE_URL}/v1/report-templates/${id}?${cacheQuery(req)}`,
                    { headers: cacheHeaders(req) },
                    5000,
                );
                if (!r.ok) return null;
                const d = await r.json();
                return { id, name: d.template?.layout?.name || id, updatedAt: d.updatedAt };
            } catch { return null; }
        }));
        res.json({ data: reports.filter(Boolean) });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// GET /v1/reportes/saved/:id
reportesRouter.get("/saved/:id", async (req: Request, res: Response) => {
    try {
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/${req.params.id}?${cacheQuery(req)}`,
            { headers: cacheHeaders(req) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "not_found" });
        const d = await resp.json();
        res.json({ layout: d.template?.layout, sampleData: d.template?.sampleData });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// PUT /v1/reportes/saved/:id
reportesRouter.put("/saved/:id", async (req: Request, res: Response) => {
    try {
        const body = {
            companyId: String((req as any).companyId || (req as any).jwt?.companyId || "1"),
            userId: String((req as any).jwt?.sub || "anonymous"),
            template: req.body,
        };
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/${req.params.id}`,
            { method: "PUT", headers: cacheHeaders(req), body: JSON.stringify(body) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "save_failed" });
        res.json({ ok: true, id: req.params.id });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// GET /v1/reportes/public â€” list public/company-wide reports
reportesRouter.get("/public", async (req: Request, res: Response) => {
    try {
        const companyId = (req as any).companyId || (req as any).jwt?.companyId || "1";
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/public?companyId=${companyId}`,
            { headers: cacheHeaders(req) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "cache_error" });
        const data = await resp.json();
        res.json({ data: data || [] });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// GET /v1/reportes/public/:id â€” get a single public report with full layout
reportesRouter.get("/public/:id", async (req: Request, res: Response) => {
    try {
        const companyId = (req as any).companyId || (req as any).jwt?.companyId || "1";
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/public/${req.params.id}?companyId=${companyId}`,
            { headers: cacheHeaders(req) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "not_found" });
        const d = await resp.json();
        res.json({ layout: d.template?.layout, sampleData: d.template?.sampleData, name: d.name });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// PUT /v1/reportes/public/:id â€” save a public/company-wide report
reportesRouter.put("/public/:id", async (req: Request, res: Response) => {
    try {
        const companyId = String((req as any).companyId || (req as any).jwt?.companyId || "1");
        const userId = String((req as any).jwt?.sub || "anonymous");
        const body = { companyId, userId, template: req.body };
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/public/${req.params.id}`,
            { method: "PUT", headers: cacheHeaders(req), body: JSON.stringify(body) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "save_failed" });
        res.json({ ok: true, id: req.params.id });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});

// DELETE /v1/reportes/saved/:id
reportesRouter.delete("/saved/:id", async (req: Request, res: Response) => {
    try {
        const resp = await safeFetch(
            `${CACHE_URL}/v1/report-templates/${req.params.id}?${cacheQuery(req)}`,
            { method: "DELETE", headers: cacheHeaders(req) },
            10000,
        );
        if (!resp.ok) return res.status(resp.status).json({ error: "delete_failed" });
        res.json({ ok: true });
    } catch (err: any) {
        res.status(500).json({ error: err?.message });
    }
});
