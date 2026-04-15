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
// La función scalar devuelve una fila con una única columna cuyo nombre el
// normalizador de query.ts convierte a PascalCase → la leemos por Object.values
// para no acoplarnos a la transformación exacta.
export async function resolvePublicApiKey(keyPlain: string | undefined): Promise<number | null> {
  if (!keyPlain || !keyPlain.trim()) return null;
  const rows = await callSp<Record<string, unknown>>(
    "cfg.usp_cfg_publicapikey_verify",
    { KeyPlain: keyPlain.trim() },
  );
  const first = rows?.[0];
  if (!first) return null;
  const raw = Object.values(first)[0];
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
