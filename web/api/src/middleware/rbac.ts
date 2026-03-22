/**
 * Middleware RBAC — Verifica permisos granulares por endpoint.
 * Usa sec.Permission + sec.RolePermission + sec.UserPermissionOverride.
 * Best-effort: si la tabla no existe o falla, permite acceso (graceful degradation).
 */
import { Request, Response, NextFunction } from "express";
import { callSp } from "../db/query.js";

// Cache de permisos en memoria (TTL 5 min)
const permissionCache = new Map<string, { granted: boolean; expiry: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutos

// Mapeo de método HTTP a ActionCode
function methodToAction(method: string, path: string): string {
  if (path.includes("anular") || path.includes("void")) return "VOID";
  if (path.includes("aprobar") || path.includes("approve")) return "APPROVE";
  if (path.includes("exportar") || path.includes("export")) return "EXPORT";
  switch (method) {
    case "GET": return "VIEW";
    case "POST": return "CREATE";
    case "PUT": case "PATCH": return "EDIT";
    case "DELETE": return "DELETE";
    default: return "VIEW";
  }
}

// Mapeo de ruta a módulo
function pathToModule(path: string): string {
  const segment = path.replace(/^\/(?:api\/)?v1\//, "").split("/")[0] || "";
  const map: Record<string, string> = {
    "documentos-venta": "ventas", facturas: "ventas", clientes: "ventas",
    cxc: "ventas", abonos: "ventas",
    "documentos-compra": "compras", compras: "compras", proveedores: "compras",
    cxp: "compras", "cuentas-por-pagar": "compras",
    inventario: "inventario", articulos: "inventario",
    "inventario-avanzado": "inventario",
    logistica: "logistica",
    bancos: "bancos",
    contabilidad: "contabilidad", "centro-costo": "contabilidad",
    nomina: "nomina",
    rrhh: "rrhh", empleados: "rrhh",
    pos: "pos",
    restaurante: "restaurante",
    auditoria: "auditoria",
    crm: "crm",
    manufactura: "manufactura",
    flota: "flota",
    permisos: "permisos",
  };
  return map[segment] || segment;
}

async function checkPermission(userId: number, permissionCode: string): Promise<boolean> {
  const cacheKey = `${userId}:${permissionCode}`;
  const cached = permissionCache.get(cacheKey);
  if (cached && cached.expiry > Date.now()) return cached.granted;

  try {
    const rows = await callSp<{ hasPermission: number }>(
      "usp_Sec_UserPermission_Check",
      { UserId: userId, PermissionCode: permissionCode }
    );
    const granted = Number(rows[0]?.hasPermission ?? 1) === 1;
    permissionCache.set(cacheKey, { granted, expiry: Date.now() + CACHE_TTL });
    return granted;
  } catch {
    // Si la tabla/SP no existe, permitir acceso (graceful degradation)
    return true;
  }
}

/**
 * Middleware factory: verifica que el usuario tenga el permiso requerido.
 * Si no hay userId en req.user o es admin, permite acceso.
 * Si el SP no existe, permite acceso (backward compatible).
 */
export function requirePermission(moduleCode: string, actionCode: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const user = (req as any).user;

    // Admin siempre pasa
    if (user?.isAdmin) return next();

    // Sin userId = sin RBAC activo, dejar pasar
    const userId = user?.userId;
    if (!userId) return next();

    const permissionCode = `${moduleCode}.${actionCode}`;
    const granted = await checkPermission(userId, permissionCode);

    if (!granted) {
      return res.status(403).json({
        error: "permission_denied",
        permission: permissionCode,
        message: `No tiene permiso: ${permissionCode}`,
      });
    }

    next();
  };
}

/**
 * Middleware auto-RBAC: resuelve módulo y acción del path+método automáticamente.
 * Útil para aplicar globalmente sin configurar cada ruta.
 */
export function autoRbac(req: Request, res: Response, next: NextFunction) {
  const user = (req as any).user;

  // Admin o sin userId → pasar
  if (user?.isAdmin || !user?.userId) return next();

  // Solo verificar en métodos que modifican datos
  if (req.method === "GET") return next();

  const moduleCode = pathToModule(req.originalUrl || req.path);
  const actionCode = methodToAction(req.method, req.originalUrl || req.path);

  // Skip módulos internos
  if (["auth", "config", "settings", "sistema", "health", "meta"].includes(moduleCode)) {
    return next();
  }

  const permissionCode = `${moduleCode}.${actionCode}`;

  checkPermission(user.userId, permissionCode).then((granted) => {
    if (!granted) {
      return res.status(403).json({
        error: "permission_denied",
        permission: permissionCode,
        message: `No tiene permiso: ${permissionCode}`,
      });
    }
    next();
  }).catch(() => next()); // En error, permitir (graceful)
}
