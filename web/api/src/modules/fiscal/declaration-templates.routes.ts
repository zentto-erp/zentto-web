/**
 * Endpoints fiscal.DeclarationTemplate — Modelos AEAT/SENIAT/DIAN/etc.
 */
import { Router } from "express";
import { z } from "zod";
import { query } from "../../db/query.js";

export const declarationTemplatesRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

declarationTemplatesRouter.get("/", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const rows = await query<any>(
      `SELECT "TemplateId","CountryCode","DeclarationType","TemplateName",
              "FileFormat","FormatVersion","AuthorityName","AuthorityUrl","IsActive"
       FROM fiscal."DeclarationTemplate"
       WHERE (@cc IS NULL OR "CountryCode" = @cc) AND "IsActive" = TRUE
       ORDER BY "CountryCode", "DeclarationType"`,
      { cc: cc ?? null }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

declarationTemplatesRouter.get("/:countryCode/:type", async (req, res) => {
  try {
    const cc = countryCodeSchema.parse(req.params.countryCode);
    const type = String(req.params.type).toUpperCase();
    const rows = await query<any>(
      `SELECT * FROM fiscal."DeclarationTemplate"
       WHERE "CountryCode" = @cc AND "DeclarationType" = @type LIMIT 1`,
      { cc, type }
    );
    if (rows.length === 0) return res.status(404).json({ ok: false, error: "not_found" });
    return res.json({ ok: true, data: rows[0] });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
