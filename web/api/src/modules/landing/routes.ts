import { Router, Request, Response } from "express";
import { registerLead, resolvePublicApiKey } from "./service.js";

export const landingRouter = Router();

landingRouter.post("/register", async (req: Request, res: Response) => {
  try {
    const { email, name, company, country, source, topic, message, phone } = req.body;

    if (!email || !name) {
      res.status(400).json({ ok: false, error: "Email y nombre son requeridos" });
      return;
    }

    // Resolución de tenant destino (en orden de preferencia):
    //  1. Header X-Tenant-Key (sitios externos con API key pública).
    //  2. Subdomain middleware (req._tenantCompanyId) → form embebido en
    //     {acme}.zentto.net.
    //  3. Default del SP (ZENTTO — nuestro tenant principal).
    const apiKey = (req.headers["x-tenant-key"] as string | undefined)?.trim();
    let targetCompanyId: number | null = null;
    if (apiKey) {
      targetCompanyId = await resolvePublicApiKey(apiKey);
      if (!targetCompanyId) {
        res.status(401).json({ ok: false, error: "X-Tenant-Key inválida o revocada" });
        return;
      }
    } else {
      const subdomainCompanyId = (req as any)._tenantCompanyId as number | undefined;
      if (subdomainCompanyId) targetCompanyId = subdomainCompanyId;
    }

    const result = await registerLead({
      email, name, company, country, source, topic, message, phone,
      targetCompanyId,
    });
    res.json({ ...result, targetCompanyId });
  } catch (err: any) {
    console.error("[landing/register]", err.message);
    res.status(500).json({ ok: false, error: "Error interno" });
  }
});
