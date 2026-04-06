import { Router } from "express";
import { z } from "zod";
import crypto from "node:crypto";
import { callSp } from "../../db/query.js";
import { provisionTenant } from "../tenants/tenant.service.js";

export const onboardingRouter = Router();

const API_BASE = process.env.FRONTEND_URL || "https://zentto.net";

// ── Schemas ──────────────────────────────────────────────────────────────────

const signupSchema = z.object({
  email: z.string().email(),
  companyName: z.string().min(2).max(200),
  plan: z.enum(["free_trial", "basic", "professional"]).default("free_trial"),
});

// ── Helpers ──────────────────────────────────────────────────────────────────

function generateToken(): string {
  return crypto.randomBytes(48).toString("hex");
}

/**
 * Enviar email de verificacion via zentto-notify (o log en dev)
 */
async function sendVerificationEmail(email: string, token: string, companyName: string): Promise<void> {
  const verifyUrl = `${API_BASE}/signup/verify?token=${token}`;
  const notifyUrl = process.env.NOTIFY_URL || "https://notify.zentto.net";

  try {
    const res = await fetch(`${notifyUrl}/api/email/send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": process.env.NOTIFY_API_KEY || "",
      },
      body: JSON.stringify({
        to: email,
        subject: `Verifica tu cuenta en Zentto - ${companyName}`,
        template: "onboarding-verify",
        variables: { companyName, verifyUrl, email },
      }),
    });

    if (!res.ok) {
      console.warn(`[onboarding] notify responded ${res.status} for ${email}`);
    }
  } catch (err) {
    console.warn("[onboarding] could not send verification email:", err);
  }

  // Siempre logueamos el link para debug
  console.log(`[onboarding] verify link for ${email}: ${verifyUrl}`);
}

// ── POST /v1/onboarding/signup ───────────────────────────────────────────────

onboardingRouter.post("/signup", async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "validation_error", issues: parsed.error.flatten() });
    return;
  }

  const { email, companyName, plan } = parsed.data;
  const token = generateToken();

  try {
    const rows = await callSp<{ ok: boolean; mensaje: string; Id: number }>(
      "usp_Cfg_Onboarding_Create",
      {
        Email: email,
        CompanyName: companyName,
        Plan: plan,
        VerificationToken: token,
      },
    );

    const result = rows[0];
    if (!result?.ok) {
      res.status(409).json({ error: result?.mensaje || "duplicate_onboarding" });
      return;
    }

    // Enviar email (no bloquea respuesta)
    sendVerificationEmail(email, token, companyName).catch(() => {});

    res.status(201).json({
      ok: true,
      mensaje: "Revisa tu correo para verificar tu cuenta",
      id: result.Id,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    console.error("[onboarding] signup error:", msg);
    res.status(500).json({ error: msg });
  }
});

// ── POST /v1/onboarding/verify/:token ────────────────────────────────────────

onboardingRouter.post("/verify/:token", async (req, res) => {
  const { token } = req.params;
  if (!token || token.length < 10) {
    res.status(400).json({ error: "invalid_token" });
    return;
  }

  try {
    // 1. Verificar token
    const rows = await callSp<{
      ok: boolean;
      mensaje: string;
      Id: number;
      Email: string;
      CompanyName: string;
      Plan: string;
      Status: string;
    }>("usp_Cfg_Onboarding_Verify", { Token: token });

    const result = rows[0];
    if (!result?.ok) {
      res.status(400).json({ error: result?.mensaje || "invalid_token" });
      return;
    }

    // 2. Si ya fue verificado previamente, retornar estado actual
    if (result.Status !== "verified") {
      res.json({
        ok: true,
        status: result.Status,
        mensaje: "Token ya procesado",
      });
      return;
    }

    // 3. Provisionar tenant automaticamente
    await callSp("usp_Cfg_Onboarding_UpdateStatus", {
      Id: result.Id,
      Status: "provisioning",
    });

    const slug = result.CompanyName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 50);

    const companyCode = slug.toUpperCase().replace(/-/g, "_").slice(0, 20);
    const tempPassword = crypto.randomBytes(6).toString("base64url");

    try {
      const provision = await provisionTenant({
        companyCode,
        legalName: result.CompanyName,
        ownerEmail: result.Email,
        countryCode: "US",
        baseCurrency: "USD",
        adminUserCode: result.Email.split("@")[0].toUpperCase().slice(0, 40),
        adminPassword: tempPassword,
        plan: "STARTER",
      });

      if (!provision.ok) {
        await callSp("usp_Cfg_Onboarding_UpdateStatus", {
          Id: result.Id,
          Status: "failed",
          ErrorMessage: provision.mensaje,
        });
        res.status(500).json({ error: provision.mensaje });
        return;
      }

      await callSp("usp_Cfg_Onboarding_UpdateStatus", {
        Id: result.Id,
        Status: "active",
        CompanyId: provision.companyId,
        TenantSlug: slug,
      });

      res.json({
        ok: true,
        status: "active",
        companyId: provision.companyId,
        tenantSlug: slug,
        mensaje: "Cuenta creada exitosamente",
      });
    } catch (provisionErr: unknown) {
      const errMsg = provisionErr instanceof Error ? provisionErr.message : "provision_error";
      await callSp("usp_Cfg_Onboarding_UpdateStatus", {
        Id: result.Id,
        Status: "failed",
        ErrorMessage: errMsg,
      }).catch(() => {});

      res.status(500).json({ error: errMsg });
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    console.error("[onboarding] verify error:", msg);
    res.status(500).json({ error: msg });
  }
});

// ── GET /v1/onboarding/status/:email ─────────────────────────────────────────

onboardingRouter.get("/status/:email", async (req, res) => {
  const email = decodeURIComponent(req.params.email || "").toLowerCase().trim();
  if (!email || !email.includes("@")) {
    res.status(400).json({ error: "invalid_email" });
    return;
  }

  try {
    const rows = await callSp<{
      Id: number;
      Email: string;
      CompanyName: string;
      Plan: string;
      Status: string;
      TenantSlug: string | null;
      CompanyId: number | null;
      CreatedAt: string;
      VerifiedAt: string | null;
      ProvisionedAt: string | null;
      ErrorMessage: string | null;
    }>("usp_Cfg_Onboarding_StatusByEmail", { Email: email });

    if (!rows.length) {
      res.status(404).json({ error: "not_found" });
      return;
    }

    const row = rows[0];
    res.json({
      ok: true,
      id: row.Id,
      email: row.Email,
      companyName: row.CompanyName,
      plan: row.Plan,
      status: row.Status,
      tenantSlug: row.TenantSlug,
      companyId: row.CompanyId,
      createdAt: row.CreatedAt,
      verifiedAt: row.VerifiedAt,
      provisionedAt: row.ProvisionedAt,
      errorMessage: row.ErrorMessage,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "internal_error";
    res.status(500).json({ error: msg });
  }
});
