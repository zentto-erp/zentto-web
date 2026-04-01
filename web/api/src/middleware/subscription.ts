/**
 * Verificación de suscripción a nivel de USUARIO.
 *
 * La suscripción pertenece al usuario (dueño del tenant), no a cada empresa.
 * Se valida en el LOGIN, no en cada request.
 * El SP busca el mejor plan entre todas las empresas del usuario.
 */

import { getMasterPool } from "../db/pg-pool-manager.js";
import { env } from "../config/env.js";
import { callSp } from "../db/query.js";

export interface SubscriptionCheck {
  ok: boolean;
  reason: string;
  plan: string;
  status: string;
  expiresAt: string | null;
  daysRemaining: number;
}

/**
 * Verifica la suscripción del usuario. Llamar en el login.
 * Consulta siempre la BD master (fuente de verdad).
 */
export async function checkUserSubscription(userCode: string): Promise<SubscriptionCheck> {
  try {
    let rows: SubscriptionCheck[];
    if ((env.dbType ?? "postgres") === "postgres") {
      const masterPool = getMasterPool();
      const res = await masterPool.query(
        `SELECT * FROM usp_sys_subscription_checkaccess($1)`,
        [userCode],
      );
      rows = res.rows as SubscriptionCheck[];
    } else {
      rows = await callSp<SubscriptionCheck>(
        "usp_sys_Subscription_CheckAccess",
        { UserCode: userCode },
      );
    }

    return rows[0] ?? { ok: true, reason: "CHECK_FAILED", plan: "FREE", status: "active", expiresAt: null, daysRemaining: 999 };
  } catch (err) {
    // Fail-open: si falla la verificación, permitir acceso
    console.error("[subscription] Check failed, allowing access:", err);
    return { ok: true, reason: "CHECK_ERROR", plan: "FREE", status: "active", expiresAt: null, daysRemaining: 999 };
  }
}

/** Invalidar cache de billing (para uso desde paddle webhook) */
export function clearSubscriptionCache() {
  // Ya no hay cache por request — la validación es solo en login.
  // Esta función se mantiene por compatibilidad con billing.service.ts
}
