/**
 * Endpoints hr.PayrollConceptTemplate — catalogo global conceptos nomina por pais.
 */
import { Router } from "express";
import { z } from "zod";
import { query } from "../../db/query.js";

export const conceptTemplatesRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

// GET /v1/nomina/concept-templates?countryCode=ES&conceptType=ASIGNACION
conceptTemplatesRouter.get("/", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const conceptType = req.query.conceptType ? String(req.query.conceptType).toUpperCase() : null;
    const rows = await query<any>(
      `SELECT "TemplateId","CountryCode","ConceptCode","ConceptName","ConceptType","ConceptClass",
              "Formula","LegalReference","AppliesToRegimen","SortOrder","IsActive"
       FROM hr."PayrollConceptTemplate"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@ct IS NULL OR "ConceptType" = @ct)
         AND "IsActive" = TRUE
       ORDER BY "CountryCode", "SortOrder"`,
      { cc: cc ?? null, ct: conceptType }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
