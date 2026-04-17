/**
 * Endpoints para fiscal.TaxRate — IVA/IGV/ITBMS/etc por pais.
 */
import { Router } from "express";
import { z } from "zod";
import { query, execute } from "../../db/query.js";

export const taxRatesRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

taxRatesRouter.get("/", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const activeOnly = req.query.activeOnly !== "false";
    const rows = await query<any>(
      `SELECT "TaxRateId","CountryCode","TaxCode","TaxName","Rate","SurchargeRate",
              "AppliesToPOS","AppliesToRestaurant","IsDefault","IsActive","SortOrder",
              "CreatedAt","UpdatedAt"
       FROM fiscal."TaxRate"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@activeOnly = 'false' OR "IsActive" = TRUE)
       ORDER BY "CountryCode", "SortOrder", "TaxCode"`,
      { cc: cc ?? null, activeOnly: String(activeOnly) }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

taxRatesRouter.get("/:countryCode/:taxCode", async (req, res) => {
  try {
    const cc = countryCodeSchema.parse(req.params.countryCode);
    const taxCode = String(req.params.taxCode).toUpperCase();
    const rows = await query<any>(
      `SELECT * FROM fiscal."TaxRate" WHERE "CountryCode" = @cc AND "TaxCode" = @taxCode LIMIT 1`,
      { cc, taxCode }
    );
    if (rows.length === 0) return res.status(404).json({ ok: false, error: "not_found" });
    return res.json({ ok: true, data: rows[0] });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

const upsertSchema = z.object({
  countryCode: countryCodeSchema,
  taxCode: z.string().min(1).max(30),
  taxName: z.string().min(1).max(120),
  rate: z.number().min(0).max(1),
  surchargeRate: z.number().min(0).max(1).optional(),
  appliesToPOS: z.boolean().default(true),
  appliesToRestaurant: z.boolean().default(true),
  isDefault: z.boolean().default(false),
  isActive: z.boolean().default(true),
  sortOrder: z.number().int().default(0),
});

taxRatesRouter.post("/", async (req, res) => {
  try {
    const body = upsertSchema.parse(req.body);
    await execute(
      `INSERT INTO fiscal."TaxRate"
         ("CountryCode","TaxCode","TaxName","Rate","SurchargeRate",
          "AppliesToPOS","AppliesToRestaurant","IsDefault","IsActive","SortOrder")
       VALUES (@cc,@code,@name,@rate,@surcharge,@pos,@rest,@def,@active,@sort)
       ON CONFLICT ("CountryCode","TaxCode") DO UPDATE SET
         "TaxName" = EXCLUDED."TaxName", "Rate" = EXCLUDED."Rate",
         "SurchargeRate" = EXCLUDED."SurchargeRate",
         "AppliesToPOS" = EXCLUDED."AppliesToPOS",
         "AppliesToRestaurant" = EXCLUDED."AppliesToRestaurant",
         "IsDefault" = EXCLUDED."IsDefault",
         "IsActive" = EXCLUDED."IsActive",
         "SortOrder" = EXCLUDED."SortOrder"`,
      {
        cc: body.countryCode, code: body.taxCode, name: body.taxName,
        rate: body.rate, surcharge: body.surchargeRate ?? null,
        pos: body.appliesToPOS, rest: body.appliesToRestaurant,
        def: body.isDefault, active: body.isActive, sort: body.sortOrder,
      }
    );
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(400).json({ ok: false, error: err?.message ?? "bad_request" });
  }
});

taxRatesRouter.delete("/:countryCode/:taxCode", async (req, res) => {
  try {
    const cc = countryCodeSchema.parse(req.params.countryCode);
    const taxCode = String(req.params.taxCode).toUpperCase();
    const result = await execute(
      `UPDATE fiscal."TaxRate" SET "IsActive" = FALSE WHERE "CountryCode" = @cc AND "TaxCode" = @taxCode`,
      { cc, taxCode }
    );
    return res.json({ ok: true, affected: result.rowsAffected[0] ?? 0 });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
