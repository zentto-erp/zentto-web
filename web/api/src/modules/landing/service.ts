import { callSpOut } from "../../db/query.js";
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
  }, {
    Resultado: { type: sql.Int, value: 0 },
    Mensaje: { type: sql.NVarChar(500), value: "" },
  });

  return {
    ok: output.Resultado === 1,
    mensaje: output.Mensaje,
  };
}
