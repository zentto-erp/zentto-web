/**
 * Endpoints cfg.ActivityCode — Codigos de actividad economica por pais.
 * ES usa CNAE-2009 (Real Decreto 475/2007).
 */
import { Router } from "express";
import { z } from "zod";
import { query } from "../../db/query.js";

export const activityCodesRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

// GET /v1/config/activity-codes?countryCode=ES&level=SECTION
activityCodesRouter.get("/", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const level = req.query.level ? String(req.query.level).toUpperCase() : null;
    const parentCode = req.query.parentCode ? String(req.query.parentCode).toUpperCase() : null;
    const rows = await query<any>(
      `SELECT "ActivityCodeId","CountryCode","Code","Level","ParentCode","Description",
              "Classification","SortOrder","IsActive"
       FROM cfg."ActivityCode"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@level IS NULL OR "Level" = @level)
         AND (@parent IS NULL OR "ParentCode" = @parent)
         AND "IsActive" = TRUE
       ORDER BY "CountryCode", "SortOrder", "Code"`,
      { cc: cc ?? null, level, parent: parentCode }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
