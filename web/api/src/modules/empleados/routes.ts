import { Router } from "express";
import { z } from "zod";
import {
  listEmpleadosSP,
  getEmpleadoByCedulaSP,
  insertEmpleadoSP,
  updateEmpleadoSP,
  deleteEmpleadoSP,
} from "./empleados-sp.service.js";

export const empleadosRouter = Router();

const listSchema = z.object({
  search: z.string().optional(),
  grupo: z.string().optional(),
  status: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const insertSchema = z.object({
  CEDULA: z.string().min(1),
  NOMBRE: z.string().min(1),
  GRUPO: z.string().optional(),
  DIRECCION: z.string().optional(),
  TELEFONO: z.string().optional(),
  CARGO: z.string().optional(),
  NOMINA: z.string().optional(),
  SUELDO: z.number().optional(),
  STATUS: z.string().optional().default("ACTIVO"),
  SEXO: z.string().optional(),
  NACIONALIDAD: z.string().optional(),
  Autoriza: z.boolean().optional(),
});

const updateSchema = z.object({
  NOMBRE: z.string().min(1).optional(),
  GRUPO: z.string().optional(),
  DIRECCION: z.string().optional(),
  TELEFONO: z.string().optional(),
  CARGO: z.string().optional(),
  NOMINA: z.string().optional(),
  SUELDO: z.number().optional(),
  STATUS: z.string().optional(),
  SEXO: z.string().optional(),
  NACIONALIDAD: z.string().optional(),
  Autoriza: z.boolean().optional(),
});

// GET /v1/empleados - Listar empleados
empleadosRouter.get("/", async (req, res) => {
  try {
    const parsed = listSchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_query", issues: parsed.error.flatten() });
    }

    const data = await listEmpleadosSP({
      search: parsed.data.search,
      grupo: parsed.data.grupo,
      status: parsed.data.status,
      page: parsed.data.page ? parseInt(parsed.data.page) : 1,
      limit: parsed.data.limit ? parseInt(parsed.data.limit) : 50,
    });

    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// GET /v1/empleados/:cedula - Obtener empleado por cédula
empleadosRouter.get("/:cedula", async (req, res) => {
  try {
    const data = await getEmpleadoByCedulaSP(req.params.cedula);
    if (!data) return res.status(404).json({ error: "not_found" });
    return res.json(data);
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// POST /v1/empleados - Crear empleado
empleadosRouter.post("/", async (req, res) => {
  try {
    const parsed = insertSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await insertEmpleadoSP(parsed.data);
    if (result.success) {
      return res.status(201).json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// PUT /v1/empleados/:cedula - Actualizar empleado
empleadosRouter.put("/:cedula", async (req, res) => {
  try {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await updateEmpleadoSP(req.params.cedula, parsed.data);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

// DELETE /v1/empleados/:cedula - Eliminar empleado
empleadosRouter.delete("/:cedula", async (req, res) => {
  try {
    const result = await deleteEmpleadoSP(req.params.cedula);
    if (result.success) {
      return res.json({ success: true, message: result.message });
    } else {
      return res.status(400).json({ success: false, message: result.message });
    }
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
