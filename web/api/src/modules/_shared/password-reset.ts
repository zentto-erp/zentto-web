/**
 * password-reset.ts — Magic-link tokens para set-password.
 *
 * Sustituye el envío de password plaintext en welcome emails. El owner del
 * tenant recibe un link de uso único que expira en 24h, con el cual fija su
 * propia contraseña.
 */
import crypto from "node:crypto";
import { callSp } from "../../db/query.js";

export interface PasswordResetTokenInput {
  companyId: number;
  userCode: string;
  email: string;
  ttlHours?: number;
  fromIp?: string;
}

export interface PasswordResetTokenResult {
  token: string;
  expiresAt: string;
}

export async function createPasswordResetToken(
  input: PasswordResetTokenInput
): Promise<PasswordResetTokenResult> {
  const token = crypto.randomBytes(32).toString("hex");
  const rows = await callSp<{ ok: boolean; TokenId: number; ExpiresAt: string }>(
    "usp_sec_password_reset_token_create",
    {
      Token: token,
      CompanyId: input.companyId,
      UserCode: input.userCode,
      Email: input.email,
      Purpose: "set_password",
      TtlHours: input.ttlHours ?? 24,
      FromIp: input.fromIp ?? "",
    }
  );
  if (!rows[0]?.ok) throw new Error("password_reset_token_create_failed");
  return { token, expiresAt: rows[0].ExpiresAt };
}

export async function consumePasswordResetToken(token: string): Promise<{
  ok: boolean;
  mensaje: string;
  companyId?: number;
  userCode?: string;
  email?: string;
}> {
  const rows = await callSp<{
    ok: boolean; mensaje: string;
    CompanyId: number | null; UserCode: string | null; Email: string | null;
  }>("usp_sec_password_reset_token_consume", { Token: token });
  const r = rows[0];
  if (!r) return { ok: false, mensaje: "token_invalid" };
  return {
    ok: r.ok,
    mensaje: r.mensaje,
    companyId: r.CompanyId ?? undefined,
    userCode: r.UserCode ?? undefined,
    email: r.Email ?? undefined,
  };
}

/** URL pública del set-password (frontend page). */
export function buildSetPasswordUrl(opts: {
  subdomain?: string;
  token: string;
}): string {
  const host = opts.subdomain ? `${opts.subdomain}.zentto.net` : "app.zentto.net";
  return `https://${host}/auth/set-password?token=${opts.token}`;
}
