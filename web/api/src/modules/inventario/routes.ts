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
  getKardexDetalladoSP,
} from "./movimientos-sp.service.js";
import { search, getByCode, getFilterOptions, invalidateAndReload, warmUp, getCacheStats } from "./inventario-cache.js";
import { reserveStockSP, releaseStockSP, commitStockSP, getStockAvailableSP } from "./reservas-sp.service.js";
import {
  crearHojaConteoSP, upsertLineaConteoSP, cerrarHojaConteoSP, listHojasConteoSP,
  crearAlbaranSP, addLineaAlbaranSP, emitirAlbaranSP, firmarAlbaranSP, listAlbaranesSP,
  crearTrasladoMultiPasoSP, avanzarTrasladoSP,
} from "./conteo-sp.service.js";
import { emitInventarioMovementEntry } from "./inventario-contabilidad.service.js";
import { emitBusinessNotification } from "../_shared/notify.js";
import { obs } from "../integrations/observability.js";

export const inventarioRouter = Router();

/** Extrae CompanyId del JWT. Lanza 401 si no está presente (evita fallback a empresa 1). */
function requireCompanyId(req: any): number {
  const id = Number(req.user?.companyId);
  if (!Number.isFinite(id) || id <= 0) throw Object.assign(new Error("missing_company_scope"), { status: 401 });
  return id;
}

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
inventarioRouter.get("/dashboard", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const data = await getInventarioDashboardSP(companyId);
    res.json(data);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== GET: Listado de movimientos ==========
inventarioRouter.get("/movimientos", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const q = req.query;
    const result = await listMovimientosSP({
      companyId,
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
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== POST: Registrar movimiento ==========
inventarioRouter.post("/movimientos", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    const result = await insertMovimientoSP({
      companyId,
      productCode: b.productCode || b.codigoArticulo,
      movementType: b.movementType || (Number(b.cantidad) < 0 ? "SALIDA" : "ENTRADA"),
      quantity: Math.abs(Number(b.quantity || b.cantidad || 0)),
      unitCost: b.unitCost ? Number(b.unitCost) : undefined,
      documentRef: b.documentRef || b.motivo,
      warehouseFrom: b.warehouseFrom,
      warehouseTo: b.warehouseTo,
      notes: b.notes || b.observaciones,
      userId: (req as any).user?.userId,
      sourceDocumentType: b.sourceDocumentType,
      sourceDocumentId: b.sourceDocumentId ? Number(b.sourceDocumentId) : undefined,
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
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    const result = await insertMovimientoSP({
      companyId,
      productCode: b.productCode,
      movementType: "TRASLADO",
      quantity: Math.abs(Number(b.quantity || 0)),
      unitCost: b.unitCost ? Number(b.unitCost) : undefined,
      documentRef: b.documentRef,
      warehouseFrom: b.warehouseFrom,
      warehouseTo: b.warehouseTo,
      notes: b.notes,
      userId: (req as any).user?.userId,
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
    const companyId = requireCompanyId(req);
    const q = req.query;
    if (!q.fechaDesde || !q.fechaHasta) {
      return res.status(400).json({ error: "fechaDesde y fechaHasta son requeridos" });
    }
    const rows = await getLibroInventarioSP({
      companyId,
      fechaDesde: q.fechaDesde as string,
      fechaHasta: q.fechaHasta as string,
      productCode: q.productCode as string,
    });
    res.json({ rows });
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== GET: Kardex detallado (trazabilidad completa con saldo acumulado) ==========
inventarioRouter.get("/kardex/:codigo", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const q = req.query;
    const result = await getKardexDetalladoSP({
      companyId,
      productCode: req.params.codigo,
      fechaDesde: q.fechaDesde as string,
      fechaHasta: q.fechaHasta as string,
      page: q.page ? Number(q.page) : undefined,
      limit: q.limit ? Number(q.limit) : undefined,
    });
    res.json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== GET: Stock disponible (considera reservas activas) ==========
inventarioRouter.get("/reservas/disponible/:codigo", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const result = await getStockAvailableSP(companyId, req.params.codigo);
    res.json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== POST: Reservar stock (atómico, TTL configurable) ==========
inventarioRouter.post("/reservas", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.productCode || !b.quantity || !b.referenceType || !b.referenceId) {
      return res.status(400).json({ error: "productCode, quantity, referenceType y referenceId son requeridos" });
    }
    const result = await reserveStockSP({
      companyId,
      productCode:   b.productCode,
      quantity:      Number(b.quantity),
      referenceType: b.referenceType,
      referenceId:   String(b.referenceId),
      ttlMinutes:    b.ttlMinutes ? Number(b.ttlMinutes) : 30,
      userId:        (req as any).user?.userId,
    });
    if (result.ok) {
      res.status(201).json(result);
    } else {
      res.status(409).json(result);
    }
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== DELETE: Liberar reserva ==========
inventarioRouter.delete("/reservas/:id", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "id inválido" });
    const result = await releaseStockSP(id, companyId);
    res.status(result.ok ? 200 : 404).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ========== POST: Confirmar reserva (convierte en movimiento real) ==========
inventarioRouter.post("/reservas/:id/commit", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: "id inválido" });
    const b = req.body ?? {};
    const result = await commitStockSP(id, companyId, b.unitCost ? Number(b.unitCost) : 0, (req as any).user?.userId);
    if (result.ok) {
      invalidateAndReload().catch(() => {});
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ──────────────────────────��� CONTEO FÍSICO ───────────────────────────────────

inventarioRouter.get("/conteo", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const q = req.query;
    res.json(await listHojasConteoSP({
      companyId,
      estado:        q.estado        as string,
      warehouseCode: q.warehouseCode as string,
      page:          q.page  ? Number(q.page)  : undefined,
      limit:         q.limit ? Number(q.limit) : undefined,
    }));
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/conteo", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.warehouseCode) return res.status(400).json({ error: "warehouseCode requerido" });
    const result = await crearHojaConteoSP(companyId, b.warehouseCode, (req as any).user?.userId, b.notas);
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.put("/conteo/:id/lineas", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.productCode || b.stockFisico === undefined)
      return res.status(400).json({ error: "productCode y stockFisico requeridos" });
    const result = await upsertLineaConteoSP({
      hojaConteoId: Number(req.params.id),
      productCode:  b.productCode,
      stockFisico:  Number(b.stockFisico),
      unitCost:     b.unitCost ? Number(b.unitCost) : undefined,
      justificacion: b.justificacion,
      userId:       (req as any).user?.userId,
    });
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/conteo/:id/cerrar", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const result = await cerrarHojaConteoSP(Number(req.params.id), companyId, (req as any).user?.userId);
    if (result.ok) invalidateAndReload().catch(() => {});
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ─────────────────────────── ALBARANES ───────────────────────────────────────

inventarioRouter.get("/albaranes", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const q = req.query;
    res.json(await listAlbaranesSP({
      companyId,
      tipo:        q.tipo        as string,
      estado:      q.estado      as string,
      fechaDesde:  q.fechaDesde  as string,
      fechaHasta:  q.fechaHasta  as string,
      page:        q.page  ? Number(q.page)  : undefined,
      limit:       q.limit ? Number(q.limit) : undefined,
    }));
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/albaranes", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.tipo) return res.status(400).json({ error: "tipo requerido: DESPACHO | RECEPCION | TRASLADO" });
    const result = await crearAlbaranSP({
      companyId, tipo: b.tipo,
      warehouseFrom: b.warehouseFrom, warehouseTo: b.warehouseTo,
      destinatarioNombre: b.destinatarioNombre, destinatarioRif: b.destinatarioRif,
      sourceType: b.sourceType, sourceId: b.sourceId ? Number(b.sourceId) : undefined,
      observaciones: b.observaciones, userId: (req as any).user?.userId,
    });
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/albaranes/:id/lineas", async (req, res) => {
  try {
    requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.productCode || b.cantidad === undefined)
      return res.status(400).json({ error: "productCode y cantidad requeridos" });
    const result = await addLineaAlbaranSP({
      albaranId: Number(req.params.id), productCode: b.productCode,
      cantidad: Number(b.cantidad), unidad: b.unidad,
      costo: b.costo ? Number(b.costo) : undefined,
      lote: b.lote, vencimiento: b.vencimiento, observaciones: b.observaciones,
    });
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/albaranes/:id/emitir", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const result = await emitirAlbaranSP(Number(req.params.id), companyId, (req as any).user?.userId);
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/albaranes/:id/firmar", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    const result = await firmarAlbaranSP(Number(req.params.id), companyId, (req as any).user?.userId, b.firmante);
    if (result.ok) invalidateAndReload().catch(() => {});
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

// ─────────────────────────── TRASLADOS MULTI-PASO ────────────────────────────

inventarioRouter.post("/traslados-mp", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.warehouseFrom || !b.warehouseTo)
      return res.status(400).json({ error: "warehouseFrom y warehouseTo requeridos" });
    const result = await crearTrasladoMultiPasoSP({
      companyId, warehouseFrom: b.warehouseFrom, warehouseTo: b.warehouseTo,
      userId: (req as any).user?.userId, notas: b.notas,
    });
    res.status(result.ok ? 201 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
  }
});

inventarioRouter.post("/traslados-mp/:id/avanzar", async (req, res) => {
  try {
    const companyId = requireCompanyId(req);
    const b = req.body ?? {};
    if (!b.action) return res.status(400).json({ error: "action requerido: APROBAR | DESPACHAR | RECIBIR | CANCELAR" });
    const result = await avanzarTrasladoSP({
      trasladoId: Number(req.params.id), companyId,
      userId: (req as any).user?.userId, action: b.action,
    });
    if (result.ok && b.action === "RECIBIR") invalidateAndReload().catch(() => {});
    res.status(result.ok ? 200 : 400).json(result);
  } catch (err: any) {
    res.status(err?.status ?? 500).json({ error: String(err.message ?? err) });
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
