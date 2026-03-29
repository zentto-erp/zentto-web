/**
 * Middleware de auditoría global.
 * Intercepta POST/PUT/PATCH/DELETE exitosos y registra en audit.AuditLog.
 * Best-effort: nunca bloquea la respuesta al cliente.
 */
import { Request, Response, NextFunction } from "express";
import { insertAuditLog } from "../modules/auditoria/service.js";

// Rutas que NO deben auditarse (health checks, lecturas, polling)
const SKIP_PATTERNS = [
  /\/health/,
  /\/sistema\/notificaciones/,
  /\/sistema\/tareas/,
  /\/sistema\/mensajes/,
  /\/auditoria\//,
  /\/config/,
  /\/settings/,
  /\/meta/,
  /\/auth\/refresh/,
];

// Mapeo de ruta a módulo legible
function resolveModuleName(path: string): string {
  const segment = path.replace(/^\/(?:api\/)?v1\//, "").split("/")[0] || "sistema";
  const map: Record<string, string> = {
    "documentos-venta": "ventas",
    "documentos-compra": "compras",
    facturas: "ventas",
    clientes: "ventas",
    proveedores: "compras",
    cxc: "cuentas-por-cobrar",
    cxp: "cuentas-por-pagar",
    "cuentas-por-pagar": "cuentas-por-pagar",
    bancos: "bancos",
    contabilidad: "contabilidad",
    nomina: "nomina",
    rrhh: "rrhh",
    empleados: "rrhh",
    pos: "pos",
    restaurante: "restaurante",
    inventario: "inventario",
    articulos: "inventario",
    usuarios: "seguridad",
    empresa: "configuracion",
    fiscal: "fiscal",
    payments: "pagos",
    billing: "facturacion",
  };
  return map[segment] || segment;
}

// Mapeo de método HTTP a ActionType
function resolveActionType(method: string, path: string): string {
  if (path.includes("anular") || path.includes("void")) return "VOID";
  switch (method) {
    case "POST": return "CREATE";
    case "PUT": return "UPDATE";
    case "PATCH": return "UPDATE";
    case "DELETE": return "DELETE";
    default: return "OTHER";
  }
}

// Extraer entity name del path
function resolveEntityName(path: string): string {
  const parts = path.replace(/^\/(?:api\/)?v1\//, "").split("/");
  // Remover IDs numéricos y parámetros
  const meaningful = parts.filter(p => p && !/^\d+$/.test(p) && !p.startsWith(":"));
  return meaningful.slice(0, 2).join("/") || "unknown";
}

// Extraer entity ID del body o path
function resolveEntityId(path: string, body: any): string | null {
  // Buscar ID en respuesta común
  if (body?.numRecibo) return body.numRecibo;
  if (body?.numPago) return body.numPago;
  if (body?.numFact) return body.numFact;
  if (body?.ventaId) return String(body.ventaId);
  if (body?.batchId) return String(body.batchId);
  if (body?.asientoId) return String(body.asientoId);
  if (body?.id) return String(body.id);

  // Buscar en path
  const parts = path.split("/");
  for (let i = parts.length - 1; i >= 0; i--) {
    if (/^\d+$/.test(parts[i])) return parts[i];
  }
  return null;
}

// Generar resumen legible
function buildSummary(method: string, path: string, statusCode: number, body: any): string {
  const action = resolveActionType(method, path);
  const entity = resolveEntityName(path);
  const id = resolveEntityId(path, body);
  const idStr = id ? ` #${id}` : "";
  return `${action} ${entity}${idStr} → ${statusCode}`;
}

export function auditTrailMiddleware(req: Request, res: Response, next: NextFunction) {
  // Solo auditar métodos que modifican datos
  if (!["POST", "PUT", "PATCH", "DELETE"].includes(req.method)) {
    return next();
  }

  // Saltar rutas excluidas
  const fullPath = req.originalUrl || req.path;
  if (SKIP_PATTERNS.some(p => p.test(fullPath))) {
    return next();
  }

  // Capturar el body original del request (para OldValues potencial)
  const requestBody = req.body ? JSON.stringify(req.body).slice(0, 2000) : null;

  // Interceptar res.json para capturar la respuesta
  const originalJson = res.json.bind(res);
  res.json = function (body: any) {
    // Solo auditar respuestas exitosas (2xx)
    if (res.statusCode >= 200 && res.statusCode < 300) {
      const user = (req as any).user;

      // Fire-and-forget: nunca bloquea
      setImmediate(async () => {
        try {
          await insertAuditLog({
            userId: user?.userId ?? null,
            userName: user?.username ?? user?.code ?? "unknown",
            moduleName: resolveModuleName(fullPath),
            entityName: resolveEntityName(fullPath),
            entityId: resolveEntityId(fullPath, body),
            actionType: resolveActionType(req.method, fullPath),
            summary: buildSummary(req.method, fullPath, res.statusCode, body),
            oldValues: null,
            newValues: requestBody,
            ipAddress: (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim()
              || req.socket.remoteAddress
              || null,
          });
        } catch {
          // Silencioso — nunca falla la operación principal
        }
      });
    }

    return originalJson(body);
  };

  next();
}
