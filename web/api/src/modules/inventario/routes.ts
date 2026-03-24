import { Router } from "express";
import { z } from "zod";
import {
  insertInventarioSP,
  updateInventarioSP,
  deleteInventarioSP,
  getInventarioByCodigoSP,
} from "./inventario-sp.service.js";
import {
  insertMovimientoSP,
  listMovimientosSP,
  getInventarioDashboardSP,
  getLibroInventarioSP,
} from "./movimientos-sp.service.js";
import { search, getByCode, getFilterOptions, invalidateAndReload, warmUp, getCacheStats } from "./inventario-cache.js";
import { emitInventarioMovementEntry } from "./inventario-contabilidad.service.js";
import { emitBusinessNotification } from "../_shared/notify.js";
import { obs } from "../../integrations/observability.js";

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

// ========== GET: Dashboard de inventario ==========
inventarioRouter.get("/dashboard", async (_req, res) => {
  try {
    const data = await getInventarioDashboardSP();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ========== GET: Listado de movimientos ==========
inventarioRouter.get("/movimientos", async (req, res) => {
  try {
    const q = req.query;
    const result = await listMovimientosSP({
      search: q.search as string,
      productCode: q.productCode as string,
      movementType: q.movementType as string,
      warehouseCode: q.warehouseCode as string,
      fechaDesde: q.fechaDesde as string,
      fechaHasta: q.fechaHasta as string,
      page: q.page ? Number(q.page) : undefined,
      limit: q.limit ? Number(q.limit) : undefined,
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
});

// ========== POST: Registrar movimiento ==========
inventarioRouter.post("/movimientos", async (req, res) => {
  try {
    const b = req.body ?? {};
    const result = await insertMovimientoSP({
      productCode: b.productCode || b.codigoArticulo,
      movementType: b.movementType || (Number(b.cantidad) < 0 ? "SALIDA" : "ENTRADA"),
      quantity: Math.abs(Number(b.quantity || b.cantidad || 0)),
      unitCost: b.unitCost ? Number(b.unitCost) : undefined,
      documentRef: b.documentRef || b.motivo,
      warehouseFrom: b.warehouseFrom,
      warehouseTo: b.warehouseTo,
      notes: b.notes || b.observaciones,
    });
    invalidateAndReload().catch(() => {});
    if (result.success) {
      // Best-effort: generate accounting entry
      let contabilidad: { ok: boolean; asientoId?: number | null } = { ok: false };
      try {
        const qty = Math.abs(Number(b.quantity || b.cantidad || 0));
        const cost = Number(b.unitCost || 0);
        if (qty > 0 && cost > 0) {
          contabilidad = await emitInventarioMovementEntry({
            productCode: b.productCode || b.codigoArticulo || "",
            movementType: b.movementType || (Number(b.cantidad) < 0 ? "SALIDA" : "ENTRADA"),
            quantity: qty,
            unitCost: cost,
            totalCost: qty * cost,
            documentRef: b.documentRef || b.motivo,
            notes: b.notes || b.observaciones,
          });
        }
      } catch { /* never block inventory operation */ }
      // Notify: movimiento de inventario (best-effort)
      emitBusinessNotification({
        event: "LOW_STOCK_ALERT",
        to: "almacen@empresa.com",
        subject: `Movimiento inventario: ${b.movementType || "ENTRADA"} - ${b.productCode || b.codigoArticulo || ""}`,
        data: { Producto: String(b.productCode || b.codigoArticulo || ""), Tipo: String(b.movementType || "ENTRADA"), Cantidad: String(b.quantity || b.cantidad || 0) },
      }).catch(() => {});
      res.status(201).json({ ok: true, message: result.message, contabilidad });
      const movType = String(b.movementType || (Number(b.cantidad) < 0 ? "SALIDA" : "ENTRADA"));
      try { obs.event('inventario.movimiento.created', {
          productCode: b.productCode || b.codigoArticulo,
          movementType: movType,
          quantity: Math.abs(Number(b.quantity || b.cantidad || 0)),
          userId: (req as any).user?.userId,
          userName: (req as any).user?.userName,
          companyId: (req as any).user?.companyId,
          module: 'inventario',
      }); } catch { /* never blocks */ }
      if (movType === "AJUSTE") {
          try { obs.audit('inventario.ajuste.aplicado', {
              userId: (req as any).user?.userId,
              userName: (req as any).user?.userName,
              companyId: (req as any).user?.companyId,
              module: 'inventario',
              entity: 'MovimientoInventario',
              entityId: b.productCode || b.codigoArticulo,
          }); } catch { /* never blocks */ }
      }
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== POST: Traslado entre almacenes ==========
inventarioRouter.post("/traslados", async (req, res) => {
  try {
    const b = req.body ?? {};
    const result = await insertMovimientoSP({
      productCode: b.productCode,
      movementType: "TRASLADO",
      quantity: Math.abs(Number(b.quantity || 0)),
      unitCost: b.unitCost ? Number(b.unitCost) : undefined,
      documentRef: b.documentRef,
      warehouseFrom: b.warehouseFrom,
      warehouseTo: b.warehouseTo,
      notes: b.notes,
    });
    invalidateAndReload().catch(() => {});
    if (result.success) {
      res.status(201).json({ ok: true, message: result.message });
      try { obs.event('inventario.movimiento.created', {
          productCode: b.productCode,
          movementType: 'TRASLADO',
          quantity: Math.abs(Number(b.quantity || 0)),
          warehouseFrom: b.warehouseFrom,
          warehouseTo: b.warehouseTo,
          userId: (req as any).user?.userId,
          userName: (req as any).user?.userName,
          companyId: (req as any).user?.companyId,
          module: 'inventario',
      }); } catch { /* never blocks */ }
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== GET: Libro de inventario (reporte) ==========
inventarioRouter.get("/reportes/libro", async (req, res) => {
  try {
    const q = req.query;
    if (!q.fechaDesde || !q.fechaHasta) {
      return res.status(400).json({ error: "fechaDesde y fechaHasta son requeridos" });
    }
    const rows = await getLibroInventarioSP({
      fechaDesde: q.fechaDesde as string,
      fechaHasta: q.fechaHasta as string,
      productCode: q.productCode as string,
    });
    res.json({ rows });
  } catch (err) {
    res.status(500).json({ error: String(err) });
  }
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
    const result = await insertInventarioSP(req.body ?? {});
    invalidateAndReload().catch(() => {});
    if (result.success) {
      res.status(201).json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== PUT: Actualizar artículo + invalidar caché ==========
inventarioRouter.put("/:codigo", async (req, res) => {
  try {
    const result = await updateInventarioSP(req.params.codigo, req.body ?? {});
    invalidateAndReload().catch(() => {});
    if (result.success) {
      res.json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});

// ========== DELETE: Eliminar artículo + invalidar caché ==========
inventarioRouter.delete("/:codigo", async (req, res) => {
  try {
    const result = await deleteInventarioSP(req.params.codigo);
    invalidateAndReload().catch(() => {});
    if (result.success) {
      res.json({ ok: true, message: result.message });
    } else {
      res.status(400).json({ ok: false, message: result.message });
    }
  } catch (err) {
    res.status(400).json({ error: String(err) });
  }
});
