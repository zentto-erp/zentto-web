type CaptchaAction =
  | "login"
  | "register"
  | "forgot_password"
  | "reset_password"
  | "verify_email"
  | "resend_verification"
  | "track_public";

type CaptchaValidation = {
  ok: boolean;
  skipped?: boolean;
  reason?: string;
};

function getCaptchaSecret() {
  return (
    process.env.CAPTCHA_SECRET ||
    process.env.TURNSTILE_SECRET ||
    process.env.RECAPTCHA_SECRET ||
    ""
  ).trim();
}

function getCaptchaProvider() {
  const raw = String(process.env.CAPTCHA_PROVIDER || "").trim().toLowerCase();
  if (raw === "recaptcha") return "recaptcha";
  return "turnstile";
}

function getCaptchaMinScore() {
  const parsed = Number(process.env.CAPTCHA_MIN_SCORE || "0.5");
  if (!Number.isFinite(parsed) || parsed < 0 || parsed > 1) return 0.5;
  return parsed;
}

async function verifyTurnstile(
  token: string,
  remoteIp: string | undefined,
  expectedAction: CaptchaAction
): Promise<CaptchaValidation> {
  const secret = getCaptchaSecret();
  const endpoint =
    process.env.CAPTCHA_VERIFY_URL ||
    "https://challenges.cloudflare.com/turnstile/v0/siteverify";

  const body = new URLSearchParams();
  body.set("secret", secret);
  body.set("response", token);
  if (remoteIp) body.set("remoteip", remoteIp);

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!response.ok) {
    return { ok: false, reason: "captcha_service_unavailable" };
  }

  const data = (await response.json()) as {
    success?: boolean;
    action?: string;
    "error-codes"?: string[];
  };

  if (!data.success) {
    return {
      ok: false,
      reason:
        data["error-codes"]?.[0] ||
        "captcha_invalid",
    };
  }

  if (data.action && data.action !== expectedAction) {
    return { ok: false, reason: "captcha_action_mismatch" };
  }

  return { ok: true };
}

async function verifyRecaptcha(
  token: string,
  remoteIp: string | undefined
): Promise<CaptchaValidation> {
  const secret = getCaptchaSecret();
  const endpoint =
    process.env.CAPTCHA_VERIFY_URL ||
    "https://www.google.com/recaptcha/api/siteverify";

  const body = new URLSearchParams();
  body.set("secret", secret);
  body.set("response", token);
  if (remoteIp) body.set("remoteip", remoteIp);

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!response.ok) {
    return { ok: false, reason: "captcha_service_unavailable" };
  }

  const data = (await response.json()) as {
    success?: boolean;
    score?: number;
    "error-codes"?: string[];
  };

  if (!data.success) {
    return {
      ok: false,
      reason:
        data["error-codes"]?.[0] ||
        "captcha_invalid",
    };
  }

  const score = Number(data.score ?? 1);
  if (score < getCaptchaMinScore()) {
    return { ok: false, reason: "captcha_low_score" };
  }

  return { ok: true };
}

export async function validateCaptchaToken(
  token: string | undefined,
  remoteIp: string | undefined,
  action: CaptchaAction
): Promise<CaptchaValidation> {
  const secret = getCaptchaSecret();
  if (!secret) {
    return { ok: true, skipped: true };
  }

  const normalizedToken = String(token ?? "").trim();
  if (!normalizedToken) {
    return { ok: false, reason: "captcha_required" };
  }

  try {
    const provider = getCaptchaProvider();
    if (provider === "recaptcha") {
      return await verifyRecaptcha(normalizedToken, remoteIp);
    }
    return await verifyTurnstile(normalizedToken, remoteIp, action);
  } catch {
    return { ok: false, reason: "captcha_validation_error" };
  }
}
