import { Router } from "express";
import { z } from "zod";
import {
    listAmbientes, upsertAmbiente,
    listCategoriasMenu, upsertCategoriaMenu,
    listProductosMenu, getProductoMenu, upsertProductoMenu, deleteProductoMenu,
    upsertComponente, upsertOpcion,
    upsertRecetaItem, deleteRecetaItem,
    listCompras, getCompraDetalle, crearCompra, updateCompra, upsertCompraDetalle, deleteCompraDetalle,
    searchProveedores,
    searchInsumosRestaurante,
} from "./admin.service.js";

export const restauranteAdminRouter = Router();

// ═══ AMBIENTES ═══
restauranteAdminRouter.get("/ambientes", async (_req, res) => {
    try {
        res.json(await listAmbientes());
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.post("/ambientes", async (req, res) => {
    try {
        const s = z.object({ id: z.number().optional(), nombre: z.string(), color: z.string().optional(), orden: z.number().optional() });
        const parsed = s.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        const result = await upsertAmbiente(parsed.data);
        res.status(201).json(result);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ CATEGORÍAS DEL MENÚ ═══
restauranteAdminRouter.get("/categorias", async (_req, res) => {
    try {
        res.json(await listCategoriasMenu());
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.post("/categorias", async (req, res) => {
    try {
        const s = z.object({ id: z.number().optional(), nombre: z.string(), descripcion: z.string().optional(), color: z.string().optional(), orden: z.number().optional() });
        const parsed = s.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertCategoriaMenu(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ PRODUCTOS DEL MENÚ ═══
restauranteAdminRouter.get("/productos", async (req, res) => {
    try {
        const categoriaId = req.query.categoriaId ? Number(req.query.categoriaId) : undefined;
        const search = req.query.search as string | undefined;
        const soloDisponibles = req.query.soloDisponibles !== "false";
        res.json(await listProductosMenu({ categoriaId, search, soloDisponibles }));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.get("/productos/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        const data = await getProductoMenu(id);
        if (!data.producto) return res.status(404).json({ error: "not_found" });
        res.json(data);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

const productoSchema = z.object({
    id: z.number().optional(),
    codigo: z.string().min(1),
    nombre: z.string().min(1),
    descripcion: z.string().optional(),
    categoriaId: z.number().optional(),
    precio: z.number().optional(),
    costoEstimado: z.number().optional(),
    iva: z.number().optional(),
    esCompuesto: z.boolean().optional(),
    tiempoPreparacion: z.number().optional(),
    imagen: z.string().optional(),
    esSugerenciaDelDia: z.boolean().optional(),
    disponible: z.boolean().optional(),
    articuloInventarioId: z.string().optional(),
});

restauranteAdminRouter.post("/productos", async (req, res) => {
    try {
        const parsed = productoSchema.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertProductoMenu(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.put("/productos/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        const parsed = productoSchema.safeParse({ ...req.body, id });
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.json(await upsertProductoMenu(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.delete("/productos/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        res.json(await deleteProductoMenu(id));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ COMPONENTES / OPCIONES ═══
restauranteAdminRouter.post("/componentes", async (req, res) => {
    try {
        const s = z.object({ id: z.number().optional(), productoId: z.number(), nombre: z.string(), obligatorio: z.boolean().optional(), orden: z.number().optional() });
        const parsed = s.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertComponente(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.post("/opciones", async (req, res) => {
    try {
        const s = z.object({ id: z.number().optional(), componenteId: z.number(), nombre: z.string(), precioExtra: z.number().optional(), orden: z.number().optional() });
        const parsed = s.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertOpcion(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ RECETAS ═══
restauranteAdminRouter.post("/recetas", async (req, res) => {
    try {
        const s = z.object({ id: z.number().optional(), productoId: z.number(), inventarioId: z.string(), cantidad: z.number(), unidad: z.string().optional(), comentario: z.string().optional() });
        const parsed = s.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertRecetaItem(parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.delete("/recetas/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        res.json(await deleteRecetaItem(id));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ COMPRAS RESTAURANTE ═══
restauranteAdminRouter.get("/compras", async (req, res) => {
    try {
        const estado = req.query.estado as string | undefined;
        const from = req.query.from as string | undefined;
        const to = req.query.to as string | undefined;
        res.json(await listCompras({ estado, from, to }));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.get("/compras/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        const data = await getCompraDetalle(id);
        if (!data.compra) return res.status(404).json({ error: "not_found" });
        res.json(data);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

const compraSchema = z.object({
    proveedorId: z.string().optional(),
    observaciones: z.string().optional(),
    codUsuario: z.string().optional(),
    detalle: z.array(z.object({
        descripcion: z.string().min(1),
        cantidad: z.number().min(0.001),
        precioUnit: z.number().min(0),
        iva: z.number().optional(),
        inventarioId: z.string().optional(),
    })).min(1),
});

restauranteAdminRouter.post("/compras", async (req, res) => {
    try {
        const parsed = compraSchema.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        const result = await crearCompra(parsed.data);
        res.status(201).json(result);
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

const compraUpdateSchema = z.object({
    proveedorId: z.string().optional(),
    estado: z.string().optional(),
    observaciones: z.string().optional(),
});

restauranteAdminRouter.put("/compras/:id", async (req, res) => {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
        const parsed = compraUpdateSchema.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.json(await updateCompra(id, parsed.data));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

const compraDetalleSchema = z.object({
    id: z.number().optional(),
    inventarioId: z.string().optional(),
    descripcion: z.string().min(1),
    cantidad: z.number().min(0.001),
    precioUnit: z.number().min(0),
    iva: z.number().optional(),
});

restauranteAdminRouter.post("/compras/:id/detalle", async (req, res) => {
    try {
        const compraId = Number(req.params.id);
        if (isNaN(compraId)) return res.status(400).json({ error: "id inválido" });
        const parsed = compraDetalleSchema.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
        res.status(201).json(await upsertCompraDetalle({ ...parsed.data, compraId }));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

restauranteAdminRouter.delete("/compras/:id/detalle/:detalleId", async (req, res) => {
    try {
        const compraId = Number(req.params.id);
        const detalleId = Number(req.params.detalleId);
        if (isNaN(compraId) || isNaN(detalleId)) return res.status(400).json({ error: "id inválido" });
        res.json(await deleteCompraDetalle(compraId, detalleId));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ PROVEEDORES (lectura — de tabla compartida) ═══
restauranteAdminRouter.get("/proveedores", async (req, res) => {
    try {
        const search = req.query.search as string | undefined;
        const limit = req.query.limit ? Number(req.query.limit) : 20;
        res.json(await searchProveedores(search, limit));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});

// ═══ INSUMOS RESTAURANTE (para recetas) ═══
restauranteAdminRouter.get("/insumos", async (req, res) => {
    try {
        const search = req.query.search as string | undefined;
        const limit = req.query.limit ? Number(req.query.limit) : 30;
        res.json(await searchInsumosRestaurante(search, limit));
    } catch (err: any) {
        res.status(500).json({ error: err?.message || "internal_error" });
    }
});
