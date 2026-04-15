import { callSpOut, callSp } from "../../db/query.js";
import sql from "mssql";

interface RegisterLead {
  email: string;
  name: string;
  company?: string;
  country?: string;
  source?: string;
  topic?: string;
  message?: string;
  phone?: string;
  targetCompanyId?: number | null;
}

// Resuelve una `X-Tenant-Key` (header) a CompanyId o null si inválida.
export async function resolvePublicApiKey(keyPlain: string | undefined): Promise<number | null> {
  if (!keyPlain || !keyPlain.trim()) return null;
  const rows = await callSp<{ usp_cfg_publicapikey_verify: number | null }>(
    "cfg.usp_cfg_publicapikey_verify",
    { KeyPlain: keyPlain.trim() },
  );
  const raw = rows?.[0]?.usp_cfg_publicapikey_verify;
  return typeof raw === "number" && raw > 0 ? raw : null;
}

export async function registerLead(data: RegisterLead) {
  const { output } = await callSpOut("usp_sys_Lead_Upsert", {
    Email: data.email,
    FullName: data.name,
    Company: data.company || null,
    Country: data.country || null,
    Source: data.source || "zentto-landing",
    Topic: data.topic || null,
    Message: data.message || null,
    Phone: data.phone || null,
    TargetCompanyId: data.targetCompanyId ?? null,
  }, {
    Resultado: { type: sql.Int, value: 0 },
    Mensaje: { type: sql.NVarChar(500), value: "" },
  });

  return {
    ok: output.Resultado === 1,
    mensaje: output.Mensaje,
  };
}
