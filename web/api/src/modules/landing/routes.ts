import { Router, Request, Response } from "express";
import { registerLead } from "./service.js";

export const landingRouter = Router();

landingRouter.post("/register", async (req: Request, res: Response) => {
  try {
    const { email, name, company, country, source } = req.body;

    if (!email || !name) {
      res.status(400).json({ ok: false, error: "Email y nombre son requeridos" });
      return;
    }

    const result = await registerLead({ email, name, company, country, source });
    res.json(result);
  } catch (err: any) {
    console.error("[landing/register]", err.message, err.stack);
    res.status(500).json({
      ok: false,
      error: "Error interno",
      // DEBUG temporal — quitar tras diagnóstico
      _debug: { message: err.message, code: err.code, hint: err.hint, where: err.where },
    });
  }
});
