import { Router } from "express";
import { z } from "zod";
import { createInventario, deleteInventario, getInventario, updateInventario } from "./service.js";
import { search, getByCode, getFilterOptions, invalidateAndReload, warmUp, getCacheStats } from "./inventario-cache.js";

export const inventarioRouter = Router();

// Esquema de validación para query params de listado de artículos
const qSchema = z.object({
  search: z.string().optional(),
  categoria: z.string().optional(),
  marca: z.string().optional(),
  linea: z.string().optional(),
  tipo: z.string().optional(),
  clase: z.string().optional(),
  unidad: z.string().optional(),
  ubicacion: z.string().optional(),
  estado: z.enum(["activo", "inactivo", "todos"]).optional(),
  precioMin: z.string().optional(),
  precioMax: z.string().optional(),
  stockMin: z.string().optional(),
  stockMax: z.string().optional(),
  servicio: z.enum(["true", "false"]).optional(),
  wildcard: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
  sortBy: z.string().optional(),
  sortOrder: z.enum(["asc", "desc"]).optional(),
});

/** Construye el objeto de filtro desde los query params parseados */
function buildFilter(q: z.infer<typeof qSchema>) {
  return {
    search: q.search,
    categoria: q.categoria,
    marca: q.marca,
    linea: q.linea,
    tipo: q.tipo,
    clase: q.clase,
    unidad: q.unidad,
    ubicacion: q.ubicacion,
    estado: q.estado,
    precioMin: q.precioMin ? Number(q.precioMin) : undefined,
    precioMax: q.precioMax ? Number(q.precioMax) : undefined,
    stockMin: q.stockMin ? Number(q.stockMin) : undefined,
    stockMax: q.stockMax ? Number(q.stockMax) : undefined,
    servicio: q.servicio !== undefined ? q.servicio === "true" : undefined,
    wildcard: q.wildcard,
    page: q.page ? Number(q.page) : undefined,
    limit: q.limit ? Number(q.limit) : undefined,
    sortBy: q.sortBy,
    sortOrder: q.sortOrder,
  };
}

// ========== GET: Listado con caché ==========
inventarioRouter.get("/", async (req, res) => {
  const parsed = qSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await search(buildFilter(parsed.data)));
});

// Alias /articulos para compatibilidad
inventarioRouter.get("/articulos", async (req, res) => {
  const parsed = qSchema.safeParse(req.query);
  if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
  res.json(await search(buildFilter(parsed.data)));
});

// ========== GET: Opciones de filtros (lineas, categorias, etc.) ==========
inventarioRouter.get("/filters", async (_req, res) => {
  const options = await getFilterOptions();
  res.json(options);
});

// ========== GET: Diagnóstico del caché ==========
inventarioRouter.get("/cache/stats", async (_req, res) => {
  res.json(getCacheStats());
});

// ========== POST: Forzar recarga del caché ==========
inventarioRouter.post("/cache/reload", async (_req, res) => {
  const count = await warmUp();
  res.json({ ok: true, count, message: `Cache recargado con ${count} artículos` });
});

// ========== GET: Artículo por código (caché) ==========
inventarioRouter.get("/:codigo", async (req, res) => {
  const item = await getByCode(req.params.codigo);
  if (!item) return res.status(404).json({ error: "not_found" });
  res.json(item);
});

// ========== POST: Crear artículo + invalidar caché ==========
inventarioRouter.post("/", async (req, res) => {
  try {
    const data = await createInventario(req.body ?? {});
    // Invalidar caché tras mutación
    invalidateAndReload().catch(() => {});
    res.status(201).json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== PUT: Actualizar artículo + invalidar caché ==========
inventarioRouter.put("/:codigo", async (req, res) => {
  try {
    const data = await updateInventario(req.params.codigo, req.body ?? {});
    // Invalidar caché tras mutación
    invalidateAndReload().catch(() => {});
    res.json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== DELETE: Eliminar artículo + invalidar caché ==========
inventarioRouter.delete("/:codigo", async (req, res) => {
  try {
    const data = await deleteInventario(req.params.codigo);
    // Invalidar caché tras mutación
    invalidateAndReload().catch(() => {});
    res.json({ ok: true, data });
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
