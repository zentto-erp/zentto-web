import { Router, Request, Response } from "express";
import { callSp, callSpOut } from "../../../db/query.js";
import sql from "mssql";

// Gestión de API keys públicas para que un tenant reciba leads desde sitios
// externos (acme.com → POST /api/landing/register con X-Tenant-Key).
// Solo el propio tenant (vía JWT) puede listar/crear/revocar sus keys.

export const publicApiKeysRouter = Router();

function getCompanyId(req: Request): number | null {
  const user = (req as any).user;
  const id = user?.companyId ?? user?.CompanyId;
  return typeof id === "number" && id > 0 ? id : null;
}

publicApiKeysRouter.get("/", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "Sin contexto de tenant" });
      return;
    }
    const rows = await callSp<Record<string, unknown>>(
      "cfg.usp_cfg_publicapikey_list",
      { CompanyId: companyId },
    );
    res.json({ ok: true, keys: rows });
  } catch (err: any) {
    console.error("[crm/public-keys/list]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});

publicApiKeysRouter.post("/", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "Sin contexto de tenant" });
      return;
    }
    const user = (req as any).user;
    const userId = user?.userId ?? user?.UserId ?? null;
    const { label, scopes, expiresAt } = req.body || {};

    const { output } = await callSpOut("cfg.usp_cfg_publicapikey_create", {
      CompanyId: companyId,
      Label: label || "Default",
      UserId: userId,
      Scopes: scopes || "landing:lead:create",
      ExpiresAt: expiresAt || null,
    }, {
      KeyId:     { type: sql.BigInt, value: 0 },
      KeyPlain:  { type: sql.NVarChar(200), value: "" },
      KeyPrefix: { type: sql.NVarChar(20),  value: "" },
      Resultado: { type: sql.Int,           value: 0 },
      Mensaje:   { type: sql.NVarChar(500), value: "" },
    });

    if (output.Resultado !== 1) {
      res.status(400).json({ ok: false, error: output.Mensaje });
      return;
    }

    // IMPORTANTE: el `key` plain se muestra UNA SOLA VEZ al caller.
    res.json({
      ok: true,
      keyId: output.KeyId,
      keyPrefix: output.KeyPrefix,
      key: output.KeyPlain,
      warning: "Guardá esta key ahora — no se puede recuperar después.",
    });
  } catch (err: any) {
    console.error("[crm/public-keys/create]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});

publicApiKeysRouter.delete("/:keyId", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) {
      res.status(401).json({ ok: false, error: "Sin contexto de tenant" });
      return;
    }
    const keyId = Number(req.params.keyId);
    if (!Number.isFinite(keyId) || keyId <= 0) {
      res.status(400).json({ ok: false, error: "keyId inválido" });
      return;
    }

    const { output } = await callSpOut("cfg.usp_cfg_publicapikey_revoke", {
      KeyId: keyId,
      CompanyId: companyId,
    }, {
      Resultado: { type: sql.Int,           value: 0 },
      Mensaje:   { type: sql.NVarChar(500), value: "" },
    });

    if (output.Resultado !== 1) {
      res.status(404).json({ ok: false, error: output.Mensaje });
      return;
    }
    res.json({ ok: true, mensaje: output.Mensaje });
  } catch (err: any) {
    console.error("[crm/public-keys/revoke]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});
