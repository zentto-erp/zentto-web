/**
 * Endpoints fiscal.ISLRTariff — Tramos ISLR/IRPF por pais y año.
 */
import { Router } from "express";
import { z } from "zod";
import { query } from "../../db/query.js";

export const islrTariffRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

islrTariffRouter.get("/", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const taxYear = req.query.taxYear ? Number(req.query.taxYear) : null;
    const rows = await query<any>(
      `SELECT "TariffId","CountryCode","TaxYear","BracketFrom","BracketTo",
              "Rate","Subtrahend","IsActive"
       FROM fiscal."ISLRTariff"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@taxYear IS NULL OR "TaxYear" = @taxYear)
         AND "IsActive" = TRUE
       ORDER BY "CountryCode", "TaxYear" DESC, "BracketFrom"`,
      { cc: cc ?? null, taxYear }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
