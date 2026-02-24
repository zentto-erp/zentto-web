import { Router } from "express";
import { z } from "zod";
import {
    listAmbientes, upsertAmbiente,
    listCategoriasMenu, upsertCategoriaMenu,
    listProductosMenu, getProductoMenu, upsertProductoMenu, deleteProductoMenu,
    upsertComponente, upsertOpcion,
    upsertRecetaItem, deleteRecetaItem,
    listCompras, getCompraDetalle, crearCompra,
    searchProveedores,
} from "./admin.service.js";

export const restauranteAdminRouter = Router();

// ═══ AMBIENTES ═══
restauranteAdminRouter.get("/ambientes", async (_req, res) => {
    res.json(await listAmbientes());
});

restauranteAdminRouter.post("/ambientes", async (req, res) => {
    const s = z.object({ id: z.number().optional(), nombre: z.string(), color: z.string().optional(), orden: z.number().optional() });
    const parsed = s.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    const result = await upsertAmbiente(parsed.data);
    res.status(201).json(result);
});

// ═══ CATEGORÍAS DEL MENÚ ═══
restauranteAdminRouter.get("/categorias", async (_req, res) => {
    res.json(await listCategoriasMenu());
});

restauranteAdminRouter.post("/categorias", async (req, res) => {
    const s = z.object({ id: z.number().optional(), nombre: z.string(), descripcion: z.string().optional(), color: z.string().optional(), orden: z.number().optional() });
    const parsed = s.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.status(201).json(await upsertCategoriaMenu(parsed.data));
});

// ═══ PRODUCTOS DEL MENÚ ═══
restauranteAdminRouter.get("/productos", async (req, res) => {
    const categoriaId = req.query.categoriaId ? Number(req.query.categoriaId) : undefined;
    const search = req.query.search as string | undefined;
    const soloDisponibles = req.query.soloDisponibles !== "false";
    res.json(await listProductosMenu({ categoriaId, search, soloDisponibles }));
});

restauranteAdminRouter.get("/productos/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    const data = await getProductoMenu(id);
    if (!data.producto) return res.status(404).json({ error: "not_found" });
    res.json(data);
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
    const parsed = productoSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.status(201).json(await upsertProductoMenu(parsed.data));
});

restauranteAdminRouter.put("/productos/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    const parsed = productoSchema.safeParse({ ...req.body, id });
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.json(await upsertProductoMenu(parsed.data));
});

restauranteAdminRouter.delete("/productos/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    res.json(await deleteProductoMenu(id));
});

// ═══ COMPONENTES / OPCIONES ═══
restauranteAdminRouter.post("/componentes", async (req, res) => {
    const s = z.object({ id: z.number().optional(), productoId: z.number(), nombre: z.string(), obligatorio: z.boolean().optional(), orden: z.number().optional() });
    const parsed = s.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.status(201).json(await upsertComponente(parsed.data));
});

restauranteAdminRouter.post("/opciones", async (req, res) => {
    const s = z.object({ id: z.number().optional(), componenteId: z.number(), nombre: z.string(), precioExtra: z.number().optional(), orden: z.number().optional() });
    const parsed = s.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.status(201).json(await upsertOpcion(parsed.data));
});

// ═══ RECETAS ═══
restauranteAdminRouter.post("/recetas", async (req, res) => {
    const s = z.object({ id: z.number().optional(), productoId: z.number(), inventarioId: z.string(), cantidad: z.number(), unidad: z.string().optional(), comentario: z.string().optional() });
    const parsed = s.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    res.status(201).json(await upsertRecetaItem(parsed.data));
});

restauranteAdminRouter.delete("/recetas/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    res.json(await deleteRecetaItem(id));
});

// ═══ COMPRAS RESTAURANTE ═══
restauranteAdminRouter.get("/compras", async (req, res) => {
    const estado = req.query.estado as string | undefined;
    const from = req.query.from as string | undefined;
    const to = req.query.to as string | undefined;
    res.json(await listCompras({ estado, from, to }));
});

restauranteAdminRouter.get("/compras/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    const data = await getCompraDetalle(id);
    if (!data.compra) return res.status(404).json({ error: "not_found" });
    res.json(data);
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
    const parsed = compraSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    try {
        const result = await crearCompra(parsed.data);
        res.status(201).json(result);
    } catch (err) {
        res.status(400).json({ error: String(err) });
    }
});

// ═══ PROVEEDORES (lectura — de tabla compartida) ═══
restauranteAdminRouter.get("/proveedores", async (req, res) => {
    const search = req.query.search as string | undefined;
    const limit = req.query.limit ? Number(req.query.limit) : 20;
    res.json(await searchProveedores(search, limit));
});
