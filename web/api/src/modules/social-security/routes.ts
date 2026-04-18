/**
 * Endpoints Seguridad Social — hr.SocialSecurityGroup/Rate/Base por pais.
 */
import { Router } from "express";
import { z } from "zod";
import { query } from "../../db/query.js";

export const socialSecurityRouter = Router();
const countryCodeSchema = z.string().length(2).transform((s) => s.toUpperCase());

// GET /v1/social-security/groups?countryCode=ES
socialSecurityRouter.get("/groups", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const rows = await query<any>(
      `SELECT "GroupId","CountryCode","GroupCode","GroupName","Description","SortOrder","IsActive"
       FROM hr."SocialSecurityGroup"
       WHERE (@cc IS NULL OR "CountryCode" = @cc) AND "IsActive" = TRUE
       ORDER BY "CountryCode", "SortOrder"`,
      { cc: cc ?? null }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

// GET /v1/social-security/rates?countryCode=ES&taxYear=2026
socialSecurityRouter.get("/rates", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const taxYear = req.query.taxYear ? Number(req.query.taxYear) : null;
    const rows = await query<any>(
      `SELECT "RateId","CountryCode","TaxYear","ContingencyCode","ContingencyName",
              "EmployerRate","EmployeeRate","TotalRate","AppliesTo","Notes","IsActive"
       FROM hr."SocialSecurityRate"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@taxYear IS NULL OR "TaxYear" = @taxYear)
         AND "IsActive" = TRUE
       ORDER BY "CountryCode", "TaxYear" DESC, "ContingencyCode"`,
      { cc: cc ?? null, taxYear }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});

// GET /v1/social-security/bases?countryCode=ES&taxYear=2026
socialSecurityRouter.get("/bases", async (req, res) => {
  try {
    const cc = countryCodeSchema.optional().parse(req.query.countryCode ?? undefined);
    const taxYear = req.query.taxYear ? Number(req.query.taxYear) : null;
    const rows = await query<any>(
      `SELECT "BaseId","CountryCode","TaxYear","GroupCode","MinBase","MaxBase",
              "EffectiveDate","IsActive"
       FROM hr."SocialSecurityBase"
       WHERE (@cc IS NULL OR "CountryCode" = @cc)
         AND (@taxYear IS NULL OR "TaxYear" = @taxYear)
         AND "IsActive" = TRUE
       ORDER BY "CountryCode", "TaxYear" DESC, "GroupCode"`,
      { cc: cc ?? null, taxYear }
    );
    return res.json({ ok: true, data: rows, count: rows.length });
  } catch (err: any) {
    return res.status(500).json({ ok: false, error: err?.message ?? "internal_error" });
  }
});
