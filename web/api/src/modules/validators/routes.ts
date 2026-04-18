import { Router } from "express";
import { z } from "zod";
import { validateCIF, validateIBAN, validateNIE, validateNIF } from "./service.js";

const bodySchema = z.object({ value: z.string().min(1).max(64) });

export const validatorsRouter = Router();

async function handle(fn: (v: string) => Promise<boolean>, value: string, res: any) {
  try {
    const valid = await fn(value);
    return res.json({ ok: true, valid, value });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "validation_error" });
  }
}

validatorsRouter.post("/nif", async (req, res) => {
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ ok: false, error: "invalid_body" });
  return handle(validateNIF, parsed.data.value, res);
});

validatorsRouter.post("/nie", async (req, res) => {
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ ok: false, error: "invalid_body" });
  return handle(validateNIE, parsed.data.value, res);
});

validatorsRouter.post("/cif", async (req, res) => {
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ ok: false, error: "invalid_body" });
  return handle(validateCIF, parsed.data.value, res);
});

validatorsRouter.post("/iban", async (req, res) => {
  const parsed = bodySchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ ok: false, error: "invalid_body" });
  return handle(validateIBAN, parsed.data.value, res);
});

validatorsRouter.get("/check", async (req, res) => {
  const type = String(req.query.type ?? "").toLowerCase();
  const value = String(req.query.value ?? "");
  if (!value) return res.status(400).json({ ok: false, error: "value_required" });
  const fnMap: Record<string, (v: string) => Promise<boolean>> = {
    nif: validateNIF, nie: validateNIE, cif: validateCIF, iban: validateIBAN,
  };
  const fn = fnMap[type];
  if (!fn) return res.status(400).json({ ok: false, error: "invalid_type", allowed: Object.keys(fnMap) });
  return handle(fn, value, res);
});
