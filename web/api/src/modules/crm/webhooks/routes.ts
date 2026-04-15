/**
 * Admin CRUD de tenant webhooks. Protegido por JWT: cada tenant ve/gestiona
 * solo sus propios webhooks (scoped por CompanyId del token).
 *
 * Flujo:
 *   POST /api/v1/crm/webhooks            → crea, devuelve el SECRET plain UNA vez
 *   GET  /api/v1/crm/webhooks            → lista (sin secret)
 *   GET  /api/v1/crm/webhooks/:id/deliveries  → audit de entregas recientes
 *   DELETE /api/v1/crm/webhooks/:id      → revoca
 */
import { Router, Request, Response } from "express";
import sql from "mssql";
import { callSp, callSpOut } from "../../../db/query.js";

export const webhooksRouter = Router();

function getCompanyId(req: Request): number | null {
  const user = (req as any).user;
  const id = user?.companyId ?? user?.CompanyId;
  return typeof id === "number" && id > 0 ? id : null;
}

webhooksRouter.get("/", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) { res.status(401).json({ ok: false, error: "Sin contexto de tenant" }); return; }
    const rows = await callSp<Record<string, unknown>>(
      "cfg.usp_cfg_tenantwebhook_list",
      { CompanyId: companyId },
    );
    res.json({ ok: true, webhooks: rows });
  } catch (err: any) {
    console.error("[crm/webhooks/list]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});

webhooksRouter.post("/", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) { res.status(401).json({ ok: false, error: "Sin contexto de tenant" }); return; }
    const user = (req as any).user;
    const userId = user?.userId ?? user?.UserId ?? null;
    const { url, label, eventFilter } = req.body || {};
    if (!url || typeof url !== "string") { res.status(400).json({ ok: false, error: "url requerida" }); return; }

    const { output } = await callSpOut("cfg.usp_cfg_tenantwebhook_create", {
      CompanyId: companyId,
      Url: url,
      Label: label || "default",
      EventFilter: eventFilter || "*",
      UserId: userId,
    }, {
      WebhookId: { type: sql.BigInt,        value: 0 },
      Secret:    { type: sql.NVarChar(200), value: "" },
      Resultado: { type: sql.Int,           value: 0 },
      Mensaje:   { type: sql.NVarChar(500), value: "" },
    });

    if (output.Resultado !== 1) {
      res.status(400).json({ ok: false, error: output.Mensaje });
      return;
    }

    // IMPORTANTE: el secret se expone UNA SOLA VEZ. Guardalo ahora.
    res.json({
      ok: true,
      webhookId: output.WebhookId,
      secret: output.Secret,
      warning: "Guardá este secret ahora — no se puede recuperar después. Usalo para verificar X-Zentto-Signature en los payloads.",
    });
  } catch (err: any) {
    console.error("[crm/webhooks/create]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});

webhooksRouter.delete("/:webhookId", async (req: Request, res: Response) => {
  try {
    const companyId = getCompanyId(req);
    if (!companyId) { res.status(401).json({ ok: false, error: "Sin contexto de tenant" }); return; }
    const webhookId = Number(req.params.webhookId);
    if (!Number.isFinite(webhookId) || webhookId <= 0) {
      res.status(400).json({ ok: false, error: "webhookId inválido" }); return;
    }
    const { output } = await callSpOut("cfg.usp_cfg_tenantwebhook_revoke", {
      WebhookId: webhookId,
      CompanyId: companyId,
    }, {
      Resultado: { type: sql.Int,           value: 0 },
      Mensaje:   { type: sql.NVarChar(500), value: "" },
    });
    if (output.Resultado !== 1) { res.status(404).json({ ok: false, error: output.Mensaje }); return; }
    res.json({ ok: true, mensaje: output.Mensaje });
  } catch (err: any) {
    console.error("[crm/webhooks/revoke]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});
