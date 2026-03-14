import { Router } from "express";
import { z } from "zod";
import { crearEspera, listEspera, recuperarEspera, anularEspera, registrarVenta, contabilizarVentaExistente } from "./espera.service.js";
import type { AuthenticatedRequest } from "../../middleware/auth.js";

export const posEsperaRouter = Router();

// ═══ VENTAS EN ESPERA ═══

// Listar todas las ventas en espera (multi-estación)
posEsperaRouter.get("/espera", async (_req, res) => {
    res.json(await listEspera());
});

// Poner venta en espera
const esperaSchema = z.object({
    cajaId: z.string().min(1),
    estacionNombre: z.string().optional(),
    codUsuario: z.string().optional(),
    clienteId: z.string().optional(),
    clienteNombre: z.string().optional(),
    clienteRif: z.string().optional(),
    tipoPrecio: z.string().optional(),
    motivo: z.string().optional(),
    items: z.array(z.object({
        productoId: z.string().min(1),
        codigo: z.string().optional(),
        nombre: z.string().min(1),
        cantidad: z.number().refine((value) => value !== 0, { message: "cantidad_no_puede_ser_cero" }),
        precioUnitario: z.number().min(0),
        descuento: z.number().optional(),
        iva: z.number().optional(),
        subtotal: z.number(),
        esAnulacion: z.boolean().optional(),
        anulaItemId: z.string().optional(),
        motivoAnulacion: z.string().optional(),
        supervisorUser: z.string().optional(),
        supervisorApprovalId: z.number().int().positive().optional(),
    })).min(1),
});

posEsperaRouter.post("/espera", async (req, res) => {
    const parsed = esperaSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    try {
        const user = (req as AuthenticatedRequest).user;
        const result = await crearEspera({
            ...parsed.data,
            codUsuario: parsed.data.codUsuario ?? user?.sub,
        });
        res.status(201).json(result);
    } catch (err) {
        res.status(400).json({ error: String(err) });
    }
});

// Recuperar venta en espera (carga items + marca como recuperado)
posEsperaRouter.post("/espera/:id/recuperar", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    const recuperadoPor = req.body.codUsuario as string | undefined;
    const recuperadoEn = req.body.cajaId as string | undefined;
    const result = await recuperarEspera(id, recuperadoPor, recuperadoEn);
    if (!result.ok) return res.status(404).json(result);
    res.json(result);
});

// Anular venta en espera
posEsperaRouter.delete("/espera/:id", async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) return res.status(400).json({ error: "id inválido" });
    res.json(await anularEspera(id));
});

// ═══ REGISTRAR VENTA COMPLETADA ═══

const ventaSchema = z.object({
    numFactura: z.string().min(1),
    cajaId: z.string().min(1),
    codUsuario: z.string().optional(),
    clienteId: z.string().optional(),
    clienteNombre: z.string().optional(),
    clienteRif: z.string().optional(),
    tipoPrecio: z.string().optional(),
    metodoPago: z.string().optional(),
    tramaFiscal: z.string().optional(),
    esperaOrigenId: z.number().optional(),
    empresaId: z.number().int().positive().optional(),
    sucursalId: z.number().int().nonnegative().optional(),
    countryCode: z.enum(["VE", "ES"]).optional(),
    invoiceTypeHint: z.string().optional(),
    fiscalPrinterSerial: z.string().optional(),
    fiscalControlNumber: z.string().optional(),
    zReportNumber: z.number().int().optional(),
    items: z.array(z.object({
        productoId: z.string().min(1),
        codigo: z.string().optional(),
        nombre: z.string().min(1),
        cantidad: z.number().refine((value) => value !== 0, { message: "cantidad_no_puede_ser_cero" }),
        precioUnitario: z.number().min(0),
        descuento: z.number().optional(),
        iva: z.number().optional(),
        subtotal: z.number(),
        esAnulacion: z.boolean().optional(),
        anulaItemId: z.string().optional(),
        motivoAnulacion: z.string().optional(),
        supervisorUser: z.string().optional(),
        supervisorApprovalId: z.number().int().positive().optional(),
    })).min(1),
});

posEsperaRouter.post("/ventas", async (req, res) => {
    const parsed = ventaSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    try {
        const user = (req as AuthenticatedRequest).user;
        const result = await registrarVenta({
            ...parsed.data,
            codUsuario: parsed.data.codUsuario ?? user?.sub,
        });
        res.status(201).json(result);
    } catch (err) {
        res.status(400).json({ error: String(err) });
    }
});

const contabilizarVentaSchema = z.object({
    codUsuario: z.string().optional(),
    countryCode: z.enum(["VE", "ES"]).optional(),
    currency: z.string().optional(),
    exchangeRate: z.number().positive().optional(),
});

posEsperaRouter.post("/ventas/:ventaId/contabilizar", async (req, res) => {
    const ventaId = Number(req.params.ventaId);
    if (!Number.isFinite(ventaId) || ventaId <= 0) {
        return res.status(400).json({ error: "ventaId invalido" });
    }

    const parsed = contabilizarVentaSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
        return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const result = await contabilizarVentaExistente({
        ventaId,
        codUsuario: parsed.data.codUsuario,
        countryCode: parsed.data.countryCode,
        currency: parsed.data.currency,
        exchangeRate: parsed.data.exchangeRate,
    });

    if (!result.ok && !result.skipped) return res.status(400).json(result);
    if (result.skipped && result.reason === "venta_not_found") return res.status(404).json(result);
    return res.json(result);
});
