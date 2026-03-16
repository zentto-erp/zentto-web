import { Router, Request, Response } from "express";

export const reportesRouter = Router();

// ═══════════════════════════════════════════════════════════════
// CONFIGURACIÓN DE MOTORES DE REPORTES
// ═══════════════════════════════════════════════════════════════

const CRYSTAL_SERVER = process.env.REPORT_SERVER_URL || "http://localhost:5060";
const JSREPORT_SERVER = process.env.JSREPORT_SERVER_URL || "http://localhost:5070";
const SSRS_SERVER = process.env.SSRS_SERVER_URL || "http://localhost/ReportServer";
const SSRS_PORTAL = process.env.SSRS_PORTAL_URL || "http://localhost/Reports";

// ─── Helper para fetch con timeout ───
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

// ═══════════════════════════════════════════════════════════════
// ENDPOINT UNIFICADO: Estado de todos los motores de reportes
// ═══════════════════════════════════════════════════════════════
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
            note: r.status === 401 ? "Requiere autenticación Windows" : undefined
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

// ═══════════════════════════════════════════════════════════════
// CRYSTAL REPORTS (.NET Framework 4.8) — Puerto 5060
// ═══════════════════════════════════════════════════════════════

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
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message, hint: "Crystal Server no disponible" });
    }
});

// ═══════════════════════════════════════════════════════════════
// JSREPORT (Open Source Node.js) — Puerto 5070
// ═══════════════════════════════════════════════════════════════

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
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message, hint: "jsreport no disponible" });
    }
});

// ═══════════════════════════════════════════════════════════════
// RUTAS LEGACY (compatibilidad con las rutas originales)
// ═══════════════════════════════════════════════════════════════

// /health → Crystal por defecto
reportesRouter.get("/health", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/health`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, status: "offline", message: error?.message });
    }
});

// /catalogo → Crystal por defecto
reportesRouter.get("/catalogo", async (_req: Request, res: Response) => {
    try {
        const response = await safeFetch(`${CRYSTAL_SERVER}/api/reportes/catalogo`);
        const data = await response.json();
        res.json(data);
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});

// /render → Crystal por defecto (backward compatible)
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
        res.send(Buffer.from(buffer));
    } catch (error: any) {
        res.status(502).json({ success: false, message: error?.message });
    }
});
