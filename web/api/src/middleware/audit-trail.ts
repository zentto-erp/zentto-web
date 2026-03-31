/**
 * Middleware de auditoría global — powered by @zentto/obs SDK.
 * Intercepta POST/PUT/PATCH/DELETE exitosos y registra en:
 *   1. Kafka audit topic (via obs SDK)
 *   2. audit.AuditLog table (via SP)
 * Best-effort: nunca bloquea la respuesta al cliente.
 */
import type { RequestHandler } from 'express';
import { auditMiddleware } from '@zentto/obs';
import { obs } from '../modules/integrations/observability.js';
import { insertAuditLog } from '../modules/auditoria/service.js';

export const auditTrailMiddleware = auditMiddleware(obs, {
  persistFn: (entry) => insertAuditLog({
    userId: typeof entry.userId === 'string' ? Number(entry.userId) || null : entry.userId ?? null,
    userName: entry.userName,
    moduleName: entry.moduleName,
    entityName: entry.entityName,
    entityId: entry.entityId,
    actionType: entry.actionType,
    summary: entry.summary,
    oldValues: entry.oldValues,
    newValues: entry.newValues,
    ipAddress: entry.ipAddress,
  }),
}) as unknown as RequestHandler;
