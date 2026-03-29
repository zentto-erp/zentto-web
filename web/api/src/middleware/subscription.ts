/**
 * Middleware de verificación de suscripción.
 *
 * Verifica que la empresa del usuario tiene una suscripción activa.
 * Empresas exentas: CompanyId <= 1 (DEFAULT/demo), Plan='FREE'.
 *
 * Se ejecuta DESPUÉS del middleware de auth (req.user ya tiene companyId).
 * Cachea el resultado por 5 minutos para no consultar la BD en cada request.
 */

import type { Request, Response, NextFunction } from "express";
import { callSp } from "../db/query.js";

interface SubscriptionCheck {
  ok: boolean;
  reason: string;
  plan: string;
  status: string;
  expiresAt: string | null;
  daysRemaining: number;
}

// Cache simple en memoria: companyId → { result, timestamp }
const cache = new Map<number, { result: SubscriptionCheck; ts: number }>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutos

export async function requireSubscription(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const user = (req as any).user;
  const companyId = user?.companyId;

  // Sin companyId (endpoint público o sin auth) → pasar
  if (!companyId) {
    next();
    return;
  }

  // Empresa DEFAULT (demo) → siempre permitir
  if (companyId <= 1) {
    next();
    return;
  }

  // Verificar cache
  const cached = cache.get(companyId);
  if (cached && Date.now() - cached.ts < CACHE_TTL_MS) {
    if (cached.result.ok) {
      // Agregar info de suscripción al request para uso downstream
      (req as any).subscription = cached.result;
      next();
      return;
    }
    res.status(403).json({
      error: "subscription_required",
      reason: cached.result.reason,
      plan: cached.result.plan,
      status: cached.result.status,
      expiresAt: cached.result.expiresAt,
    });
    return;
  }

  // Consultar BD
  try {
    const rows = await callSp<SubscriptionCheck>(
      "usp_sys_Subscription_CheckAccess",
      { CompanyId: companyId }
    );

    const result = rows[0] ?? { ok: false, reason: "CHECK_FAILED", plan: "", status: "", expiresAt: null, daysRemaining: 0 };

    // Cachear resultado
    cache.set(companyId, { result, ts: Date.now() });

    if (result.ok) {
      (req as any).subscription = result;
      next();
      return;
    }

    res.status(403).json({
      error: "subscription_required",
      reason: result.reason,
      plan: result.plan,
      status: result.status,
      expiresAt: result.expiresAt,
    });
  } catch (err) {
    // Si falla la verificación, permitir acceso (fail-open para no bloquear)
    console.error("[subscription] Check failed, allowing access:", err);
    next();
  }
}

/** Invalida el cache de una empresa (llamar cuando cambia la suscripción) */
export function invalidateSubscriptionCache(companyId: number) {
  cache.delete(companyId);
}

/** Invalida todo el cache */
export function clearSubscriptionCache() {
  cache.clear();
}
