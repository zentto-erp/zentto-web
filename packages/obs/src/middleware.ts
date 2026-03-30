/**
 * Express middlewares for HTTP logging, business events, and audit trail.
 * These are optional — only used if the consumer has Express as a dependency.
 */
import type { Request, Response, NextFunction } from 'express';
import type { ObsInstance } from './types.js';

// ─── Default business event mapping ────────────────────────────────────
const DEFAULT_BUSINESS_EVENTS: Record<string, string> = {
  '/v1/auth/login': 'user.login',
  '/v1/facturas': 'invoice.created',
  '/v1/compras': 'purchase.created',
  '/v1/clientes': 'customer.created',
  '/v1/proveedores': 'vendor.created',
  '/v1/pagos': 'payment.created',
  '/v1/nomina/procesar': 'payroll.processed',
  '/v1/pos': 'pos.sale',
  '/v1/restaurante': 'restaurant.order',
  '/v1/crm/leads': 'crm.lead.created',
  '/v1/inventario': 'inventory.movement',
  '/v1/contabilidad/asientos': 'accounting.entry.created',
  '/v1/support/ticket': 'support.ticket.created',
};

// ─── Default audit skip patterns ───────────────────────────────────────
const DEFAULT_AUDIT_SKIP: RegExp[] = [
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

/**
 * Extract user info from req.user (JWT payload).
 */
function extractUser(req: Request): { userId?: number | string; companyId?: number; userName?: string } {
  const user = (req as any).user;
  if (!user) return {};
  return {
    userId: user.sub ? (Number(user.sub) || user.sub) : user.userId,
    companyId: user.companyId,
    userName: user.username ?? user.code,
  };
}

/**
 * Extract client IP from request.
 */
function extractIp(req: Request): string | undefined {
  return (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim()
    || req.ip
    || req.socket?.remoteAddress
    || undefined;
}

// ═══════════════════════════════════════════════════════════════════════
//  HTTP Logging Middleware
// ═══════════════════════════════════════════════════════════════════════

export interface HttpMiddlewareOptions {
  /** Additional business event mappings (merged with defaults) */
  businessEvents?: Record<string, string>;
}

/**
 * Express middleware that logs every HTTP request/response to Kafka.
 * Also auto-detects business events from POST routes.
 */
export function httpMiddleware(obs: ObsInstance, options?: HttpMiddlewareOptions) {
  const eventMap = { ...DEFAULT_BUSINESS_EVENTS, ...options?.businessEvents };

  return (req: Request, res: Response, next: NextFunction): void => {
    const start = Date.now();

    res.on('finish', () => {
      const durationMs = Date.now() - start;
      const user = extractUser(req);

      obs.httpRequest({
        method: req.method,
        path: req.originalUrl || req.path,
        statusCode: res.statusCode,
        durationMs,
        userId: user.userId,
        companyId: user.companyId,
        ip: extractIp(req),
        userAgent: req.headers['user-agent'],
      });

      // Auto-detect business events on successful POSTs
      if (req.method === 'POST' && res.statusCode < 400) {
        const path = req.path;
        for (const [route, event] of Object.entries(eventMap)) {
          if (path.startsWith(route)) {
            obs.event(event, {
              companyId: user.companyId,
              userId: user.userId,
              path,
            });
            break;
          }
        }
      }
    });

    next();
  };
}

// ═══════════════════════════════════════════════════════════════════════
//  Audit Trail Middleware
// ═══════════════════════════════════════════════════════════════════════

export interface AuditMiddlewareOptions {
  /** Additional skip patterns (merged with defaults) */
  skipPatterns?: RegExp[];
  /** Module resolver override */
  moduleMap?: Record<string, string>;
  /** Callback to persist audit log to database (fire-and-forget) */
  persistFn?: (entry: AuditLogEntry) => Promise<void>;
}

export interface AuditLogEntry {
  userId: number | string | null;
  userName: string;
  moduleName: string;
  entityName: string;
  entityId: string | null;
  actionType: string;
  summary: string;
  oldValues: string | null;
  newValues: string | null;
  ipAddress: string | null;
}

const DEFAULT_MODULE_MAP: Record<string, string> = {
  'documentos-venta': 'ventas',
  'documentos-compra': 'compras',
  facturas: 'ventas',
  clientes: 'ventas',
  proveedores: 'compras',
  cxc: 'cuentas-por-cobrar',
  cxp: 'cuentas-por-pagar',
  bancos: 'bancos',
  contabilidad: 'contabilidad',
  nomina: 'nomina',
  rrhh: 'rrhh',
  empleados: 'rrhh',
  pos: 'pos',
  restaurante: 'restaurante',
  inventario: 'inventario',
  articulos: 'inventario',
  usuarios: 'seguridad',
  empresa: 'configuracion',
  fiscal: 'fiscal',
  payments: 'pagos',
  billing: 'facturacion',
};

function resolveModule(path: string, moduleMap: Record<string, string>): string {
  const segment = path.replace(/^\/(?:api\/)?v1\//, '').split('/')[0] || 'sistema';
  return moduleMap[segment] || segment;
}

function resolveAction(method: string, path: string): string {
  if (path.includes('anular') || path.includes('void')) return 'VOID';
  switch (method) {
    case 'POST': return 'CREATE';
    case 'PUT': return 'UPDATE';
    case 'PATCH': return 'UPDATE';
    case 'DELETE': return 'DELETE';
    default: return 'OTHER';
  }
}

function resolveEntity(path: string): string {
  const parts = path.replace(/^\/(?:api\/)?v1\//, '').split('/');
  return parts.filter(p => p && !/^\d+$/.test(p) && !p.startsWith(':')).slice(0, 2).join('/') || 'unknown';
}

function resolveEntityId(path: string, body: any): string | null {
  if (body?.numRecibo) return body.numRecibo;
  if (body?.numPago) return body.numPago;
  if (body?.numFact) return body.numFact;
  if (body?.ventaId) return String(body.ventaId);
  if (body?.batchId) return String(body.batchId);
  if (body?.asientoId) return String(body.asientoId);
  if (body?.id) return String(body.id);
  const parts = path.split('/');
  for (let i = parts.length - 1; i >= 0; i--) {
    if (/^\d+$/.test(parts[i])) return parts[i];
  }
  return null;
}

/**
 * Express middleware that logs audit trail for write operations (POST/PUT/PATCH/DELETE).
 * Sends to Kafka audit topic + optionally persists to database via persistFn.
 */
export function auditMiddleware(obs: ObsInstance, options?: AuditMiddlewareOptions) {
  const skipPatterns = [...DEFAULT_AUDIT_SKIP, ...(options?.skipPatterns ?? [])];
  const moduleMap = { ...DEFAULT_MODULE_MAP, ...(options?.moduleMap ?? {}) };
  const persistFn = options?.persistFn;

  return (req: Request, res: Response, next: NextFunction): void => {
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
      next();
      return;
    }

    const fullPath = req.originalUrl || req.path;
    if (skipPatterns.some(p => p.test(fullPath))) {
      next();
      return;
    }

    const requestBody = req.body ? JSON.stringify(req.body).slice(0, 2000) : null;

    const originalJson = res.json.bind(res);
    res.json = function (body: any) {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        const user = extractUser(req);
        const ip = extractIp(req) ?? null;

        const entry: AuditLogEntry = {
          userId: user.userId ?? null,
          userName: user.userName ?? 'unknown',
          moduleName: resolveModule(fullPath, moduleMap),
          entityName: resolveEntity(fullPath),
          entityId: resolveEntityId(fullPath, body),
          actionType: resolveAction(req.method, fullPath),
          summary: `${resolveAction(req.method, fullPath)} ${resolveEntity(fullPath)} → ${res.statusCode}`,
          oldValues: null,
          newValues: requestBody,
          ipAddress: ip,
        };

        // Send to Kafka audit topic
        obs.audit(entry.actionType, {
          userId: entry.userId,
          userName: entry.userName,
          companyId: user.companyId,
          module: entry.moduleName,
          entity: entry.entityName,
          entityId: entry.entityId,
          ip: ip ?? undefined,
        });

        // Persist to database if callback provided
        if (persistFn) {
          setImmediate(() => { persistFn(entry).catch(() => {}); });
        }
      }

      return originalJson(body);
    };

    next();
  };
}

// ═══════════════════════════════════════════════════════════════════════
//  Error Handler Middleware
// ═══════════════════════════════════════════════════════════════════════

/**
 * Express error handler that logs unhandled errors to obs.
 * Place AFTER all routes: `app.use(obs.errorHandler())`
 */
export function errorHandlerMiddleware(obs: ObsInstance) {
  return (err: any, req: Request, res: Response, next: NextFunction): void => {
    obs.error(err instanceof Error ? err : new Error(String(err?.message ?? err)), {
      method: req.method,
      path: req.originalUrl || req.path,
      userId: extractUser(req).userId,
      companyId: extractUser(req).companyId,
      ip: extractIp(req),
    });

    if (!res.headersSent) {
      const status = err?.status || err?.statusCode || 500;
      res.status(status).json({
        error: 'internal_server_error',
        message: err?.message,
        ...(process.env.NODE_ENV !== 'production' && { stack: err?.stack }),
      });
    } else {
      next(err);
    }
  };
}
