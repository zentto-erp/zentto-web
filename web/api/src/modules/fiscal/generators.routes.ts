/**
 * Endpoints para generar formatos fiscales (TXT BOE, XML FacturaE, XML Verifactu).
 * POST body contiene los datos; respuesta es texto (TXT o XML) con Content-Type apropiado.
 */
import { Router } from "express";
import { z } from "zod";
import {
  buildModelo303FromTaxBook,
  generateModelo303,
  generateModelo390,
  generateModelo111,
  generateModelo190,
  generateModelo347,
  generateFacturaE,
  generateVerifactuXML,
} from "./generators/index.js";

export const fiscalGeneratorsRouter = Router();

// ─── Modelo 303 ───────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/modelo-303", async (req, res) => {
  try {
    const txt = generateModelo303(req.body);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-303-${req.body.ejercicio}-${req.body.periodo}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// Build Modelo 303 desde taxBook entries (conveniencia)
const buildFromTaxBookSchema = z.object({
  declarante: z.object({ nif: z.string(), razonSocial: z.string() }),
  ejercicio: z.number().int(),
  periodo: z.number().int().min(1).max(4),
  entries: z.array(z.object({
    bookType: z.string(),
    taxableBase: z.number(),
    taxRate: z.number(),
    taxAmount: z.number(),
    isInvestment: z.boolean().optional(),
  })),
});
fiscalGeneratorsRouter.post("/modelo-303/from-taxbook", async (req, res) => {
  try {
    const body = buildFromTaxBookSchema.parse(req.body);
    const input = buildModelo303FromTaxBook(body.declarante, body.ejercicio, body.periodo, body.entries);
    const txt = generateModelo303(input);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-303-${body.ejercicio}-${body.periodo}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── Modelo 390 ───────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/modelo-390", async (req, res) => {
  try {
    const txt = generateModelo390(req.body);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-390-${req.body.ejercicio}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── Modelo 111 ───────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/modelo-111", async (req, res) => {
  try {
    const txt = generateModelo111(req.body);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-111-${req.body.ejercicio}-${req.body.periodo}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── Modelo 190 ───────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/modelo-190", async (req, res) => {
  try {
    const txt = generateModelo190(req.body);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-190-${req.body.ejercicio}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── Modelo 347 ───────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/modelo-347", async (req, res) => {
  try {
    const txt = generateModelo347(req.body);
    res.setHeader("Content-Type", "text/plain; charset=iso-8859-1");
    res.setHeader("Content-Disposition", `attachment; filename="modelo-347-${req.body.ejercicio}.txt"`);
    return res.send(txt);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── FacturaE 3.2.2 XML ───────────────────────────────────────────────
fiscalGeneratorsRouter.post("/facturae", async (req, res) => {
  try {
    const xml = generateFacturaE(req.body);
    res.setHeader("Content-Type", "application/xml; charset=utf-8");
    res.setHeader("Content-Disposition", `attachment; filename="facturae-${req.body.invoiceNumber}.xsig"`);
    return res.send(xml);
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

// ─── Verifactu XML ────────────────────────────────────────────────────
fiscalGeneratorsRouter.post("/verifactu", async (req, res) => {
  try {
    const { environment, ...record } = req.body;
    const result = generateVerifactuXML(record, environment ?? "PRODUCTION");
    // Retorna XML + hash + QR como JSON para que frontend los use
    return res.json({ ok: true, ...result });
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});
