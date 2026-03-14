import { Router } from "express";
import { z } from "zod";
import { spawn } from "node:child_process";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
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
import { authorizePosLineVoid } from "./supervision.service.js";

export const posRouter = Router();

const DEFAULT_LOCAL_FISCAL_AGENT = "http://localhost:5059";
const DEFAULT_LOCAL_FISCAL_SERVICE_NAME = process.env.LOCAL_FISCAL_SERVICE_NAME?.trim() || "DatqBoxHardwareHub";

function normalizeAgentUrl(raw?: string) {
    const value = (raw || "").trim();
    if (!value) return DEFAULT_LOCAL_FISCAL_AGENT;
    return value.replace(/\/$/, "");
}

function normalizeServiceName(raw?: string) {
    const value = String(raw ?? "").trim();
    return value || DEFAULT_LOCAL_FISCAL_SERVICE_NAME;
}

function runPowerShell(command: string): Promise<{ ok: boolean; stdout: string; stderr: string; exitCode: number | null }> {
    return new Promise((resolve) => {
        const ps = spawn("powershell.exe", [
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            command,
        ], {
            windowsHide: true,
        });

        let stdout = "";
        let stderr = "";

        ps.stdout.on("data", (chunk) => {
            stdout += String(chunk);
        });
        ps.stderr.on("data", (chunk) => {
            stderr += String(chunk);
        });

        ps.on("error", (error) => {
            resolve({
                ok: false,
                stdout,
                stderr: `${stderr}\n${String(error?.message ?? error)}`.trim(),
                exitCode: null,
            });
        });

        ps.on("close", (code) => {
            resolve({
                ok: code === 0,
                stdout,
                stderr,
                exitCode: code,
            });
        });
    });
}

async function getWindowsServiceStatus(serviceNameRaw?: string) {
    const serviceName = normalizeServiceName(serviceNameRaw);
    const escapedServiceName = serviceName.replace(/'/g, "''");
    const script = [
        `$name = '${escapedServiceName}'`,
        "try {",
        "  $svc = Get-Service -Name $name -ErrorAction Stop",
        "  [PSCustomObject]@{",
        "    success = $true",
        "    serviceName = $svc.Name",
        "    displayName = $svc.DisplayName",
        "    status = [string]$svc.Status",
        "    running = ([string]$svc.Status -eq 'Running')",
        "    message = ''",
        "  } | ConvertTo-Json -Compress",
        "} catch {",
        "  [PSCustomObject]@{",
        "    success = $false",
        "    serviceName = $name",
        "    displayName = $name",
        "    status = 'NotFound'",
        "    running = $false",
        "    message = $_.Exception.Message",
        "  } | ConvertTo-Json -Compress",
        "}",
    ].join("\n");

    const result = await runPowerShell(script);
    const statusJson = result.stdout
        .split("\n")
        .map((l) => l.trim())
        .filter((l) => l.startsWith("{") && l.endsWith("}"))
        .pop() ?? "";
    if (!statusJson) {
        return {
            ok: false,
            statusCode: 500,
            data: {
                success: false,
                serviceName,
                displayName: serviceName,
                status: "Unknown",
                running: false,
                message: result.stderr?.trim() || "No se pudo consultar el servicio local",
            },
        };
    }

    try {
        const parsed = JSON.parse(statusJson);
        return {
            ok: true,
            statusCode: 200,
            data: parsed,
        };
    } catch {
        return {
            ok: false,
            statusCode: 500,
            data: {
                success: false,
                serviceName,
                displayName: serviceName,
                status: "Unknown",
                running: false,
                message: "Respuesta inválida al consultar el servicio",
            },
        };
    }
}

async function executeWindowsServiceAction(params: { action: "start" | "stop" | "restart"; serviceNameRaw?: string }) {
    const serviceName = normalizeServiceName(params.serviceNameRaw);
    const escapedServiceName = serviceName.replace(/'/g, "''");
    const successMessage = params.action === "start" ? "Agente Fiscal iniciado" : params.action === "stop" ? "Agente Fiscal detenido" : "Agente Fiscal reiniciado";

    // Uses direct Start-Service / Stop-Service.
    // Requires service permissions for interactive users – run REGISTRAR_TAREAS_CONTROL.ps1 as Admin once.
    const psLines = [
        `$svcName    = '${escapedServiceName}'`,
        `$successMsg = '${successMessage}'`,
        "function Out-Svc($svc, $ok, $msg) {",
        "  [PSCustomObject]@{",
        "    success     = $ok",
        "    serviceName = $svc.Name",
        "    displayName = $svc.DisplayName",
        "    status      = [string]$svc.Status",
        "    running     = ([string]$svc.Status -eq 'Running')",
        "    message     = $msg",
        "  } | ConvertTo-Json -Compress",
        "}",
        "function Out-Err($name, $msg) {",
        "  [PSCustomObject]@{",
        "    success     = $false",
        "    serviceName = $name",
        "    displayName = $name",
        "    status      = 'Unknown'",
        "    running     = $false",
        "    message     = $msg",
        "  } | ConvertTo-Json -Compress",
        "}",
        "try {",
    ];

    if (params.action === "restart") {
        psLines.push(
            "  $svc = Get-Service -Name $svcName -ErrorAction Stop",
            "  if ([string]$svc.Status -eq 'Running') {",
            "    Stop-Service -Name $svcName -Force -ErrorAction Stop",
            "    $elapsed = 0",
            "    do { Start-Sleep -Milliseconds 500; $elapsed += 500; $svc = Get-Service -Name $svcName } while ([string]$svc.Status -ne 'Stopped' -and $elapsed -lt 6000)",
            "  }",
            "  Start-Service -Name $svcName -ErrorAction Stop",
            "  $elapsed = 0",
            "  do { Start-Sleep -Milliseconds 500; $elapsed += 500; $svc = Get-Service -Name $svcName } while ([string]$svc.Status -ne 'Running' -and $elapsed -lt 6000)",
            "  Out-Svc $svc $true $successMsg",
        );
    } else if (params.action === "stop") {
        psLines.push(
            "  Stop-Service -Name $svcName -Force -ErrorAction Stop",
            "  $elapsed = 0; $svc = $null",
            "  do { Start-Sleep -Milliseconds 500; $elapsed += 500; $svc = Get-Service -Name $svcName } while ([string]$svc.Status -ne 'Stopped' -and $elapsed -lt 8000)",
            "  Out-Svc $svc $true $successMsg",
        );
    } else {
        psLines.push(
            "  Start-Service -Name $svcName -ErrorAction Stop",
            "  $elapsed = 0; $svc = $null",
            "  do { Start-Sleep -Milliseconds 500; $elapsed += 500; $svc = Get-Service -Name $svcName } while ([string]$svc.Status -ne 'Running' -and $elapsed -lt 8000)",
            "  Out-Svc $svc $true $successMsg",
        );
    }

    psLines.push(
        "} catch {",
        "  $errMsg = $_.Exception.Message",
        "  $isPermission = $errMsg -match 'abrir' -or $errMsg -match 'access' -or $errMsg -match 'denegad' -or $errMsg -match 'denied' -or $errMsg -match 'privilege'",
        "  if ($isPermission) {",
        "    Out-Err $svcName 'Sin permisos para controlar el servicio. Ejecute REGISTRAR_TAREAS_CONTROL.ps1 como Administrador.'",
        "  } else {",
        "    Out-Err $svcName $errMsg",
        "  }",
        "}",
    );

    const script = psLines.join("\n");

    const result = await runPowerShell(script);
    // Extract the last valid JSON line from stdout (guards against PS warnings leaking)
    const lastJsonLine = result.stdout
        .split("\n")
        .map((l) => l.trim())
        .filter((l) => l.startsWith("{") && l.endsWith("}"))
        .pop();
    const rawJson = lastJsonLine ?? "";
    if (!rawJson) {
        return {
            ok: false,
            statusCode: 500,
            data: {
                success: false,
                serviceName,
                displayName: serviceName,
                status: "Unknown",
                running: false,
                message: result.stderr?.trim() || result.stdout?.trim() || "Sin respuesta al ejecutar la acción sobre el servicio",
            },
        };
    }

    try {
        const parsed = JSON.parse(rawJson);
        const failed = !parsed?.success;
        const msg = String(parsed?.message ?? "").toLowerCase();
        const notInstalled = msg.includes("cannot find any service")
            || msg.includes("no se encontr")
            || msg.includes("no existe");
        const needsSetup = msg.includes("registrar_tareas_control") || msg.includes("sin permisos");
        return {
            ok: !failed,
            statusCode: failed ? (notInstalled ? 404 : needsSetup ? 503 : 500) : 200,
            data: parsed,
        };
    } catch {
        return {
            ok: false,
            statusCode: 500,
            data: {
                success: false,
                serviceName,
                displayName: serviceName,
                status: "Unknown",
                running: false,
                message: "Respuesta inválida al ejecutar la acción del servicio",
            },
        };
    }
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

const authorizeVoidSchema = z.object({
    supervisorUser: z.string().trim().min(1),
    supervisorPassword: z.string().optional(),
    biometricBypass: z.boolean().optional(),
    biometricCredentialId: z.string().trim().max(512).optional(),
    reason: z.string().trim().min(3).max(300),
    item: z.object({
        productoId: z.string().trim().min(1),
        codigo: z.string().trim().optional(),
        nombre: z.string().trim().min(1),
        cantidad: z.number().positive(),
        precioUnitario: z.number().min(0),
        iva: z.number().min(0).max(100).optional(),
        subtotal: z.number(),
    }),
});

posRouter.post("/supervision/authorize-void", async (req, res) => {
    const parsed = authorizeVoidSchema.safeParse(req.body);
    if (!parsed.success) {
        return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    }

    const user = (req as AuthenticatedRequest).user;
    const scope = (req as AuthenticatedRequest).scope;

    const result = await authorizePosLineVoid({
        supervisorUser: parsed.data.supervisorUser,
        supervisorPassword: parsed.data.supervisorPassword ?? "",
        biometricBypass: Boolean(parsed.data.biometricBypass),
        biometricCredentialId: parsed.data.biometricCredentialId ?? null,
        reason: parsed.data.reason,
        requestedByUser: user?.sub,
        companyId: scope?.companyId,
        branchId: scope?.branchId,
        payload: {
            item: parsed.data.item,
        },
    });

    if (!result.ok) {
        return res.status(403).json(result);
    }

    return res.json(result);
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

const fiscalServiceActionSchema = z.object({
    serviceName: z.string().trim().min(1).max(180).optional(),
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

posRouter.get("/fiscal/agent/service-status", async (req, res) => {
    const result = await getWindowsServiceStatus(req.query.serviceName as string | undefined);
    return res.status(result.statusCode).json(result.data);
});

posRouter.post("/fiscal/agent/start", async (req, res) => {
    const parsed = fiscalServiceActionSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    const result = await executeWindowsServiceAction({
        action: "start",
        serviceNameRaw: parsed.data.serviceName,
    });
    return res.status(result.statusCode).json(result.data);
});

posRouter.post("/fiscal/agent/stop", async (req, res) => {
    const parsed = fiscalServiceActionSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    const result = await executeWindowsServiceAction({
        action: "stop",
        serviceNameRaw: parsed.data.serviceName,
    });
    return res.status(result.statusCode).json(result.data);
});

posRouter.post("/fiscal/agent/restart", async (req, res) => {
    const parsed = fiscalServiceActionSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_body", issues: parsed.error.flatten() });
    const result = await executeWindowsServiceAction({
        action: "restart",
        serviceNameRaw: parsed.data.serviceName,
    });
    return res.status(result.statusCode).json(result.data);
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
