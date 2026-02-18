import { Router } from "express";
import { z } from "zod";
import {
  getEmpresaSP,
  updateEmpresaSP,
} from "./empresa-sp.service.js";

export const empresaRouter = Router();

const updateSchema = z.object({
  Empresa: z.string().optional(),
  RIF: z.string().optional(),
  Nit: z.string().optional(),
  Telefono: z.string().optional(),
  Direccion: z.string().optional(),
});

// GET /v1/empresa - Obtener datos de la empresa
empresaRouter.get("/", async (_req, res) => {
  const data = await getEmpresaSP();
  if (!data) return res.status(404).json({ error: "not_found" });
  return res.json(data);
});

// PUT /v1/empresa - Actualizar datos de la empresa
empresaRouter.put("/", async (req, res) => {
  const parsed = updateSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
  }

  const result = await updateEmpresaSP(parsed.data);
  if (result.success) {
    return res.json({ success: true, message: result.message });
  } else {
    return res.status(400).json({ success: false, message: result.message });
  }
});
