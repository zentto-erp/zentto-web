import { Router } from "express";
import { getTasasBCV, triggerSyncTasas } from "./service.js";
import { callSp, callSpOut, sql } from "../../db/query.js";

export const configRouter = Router();

// /api/config/tasas
configRouter.get("/tasas", async (_req, res) => {
    try {
        const tasas = await getTasasBCV();
        res.json({ success: true, ...tasas });
    } catch (err: any) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// /api/config/tasas/sync (Trigger manual for immediate sync)
configRouter.post("/tasas/sync", async (_req, res) => {
    try {
        const result = await triggerSyncTasas();
        res.json({ success: true, result });
    } catch (err: any) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// /v1/config/countries
configRouter.get("/countries", async (_req, res) => {
    try {
        const rows = await callSp("usp_CFG_Country_List", { ActiveOnly: 1 });
        res.json(rows);
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

// /v1/config/countries/all (incluye inactivos)
configRouter.get("/countries/all", async (_req, res) => {
    try {
        const rows = await callSp("usp_CFG_Country_List", { ActiveOnly: 0 });
        res.json(rows);
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

// /v1/config/countries/:code
configRouter.get("/countries/:code", async (req, res) => {
    try {
        const rows = await callSp("usp_CFG_Country_Get", { CountryCode: req.params.code.toUpperCase() });
        res.json(rows[0] ?? null);
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});

// POST /v1/config/countries
configRouter.post("/countries", async (req, res) => {
    try {
        const b = req.body;
        const { output } = await callSpOut("usp_CFG_Country_Save", {
            CountryCode: b.countryCode,
            CountryName: b.countryName,
            CurrencyCode: b.currencyCode,
            CurrencySymbol: b.currencySymbol ?? "$",
            ReferenceCurrency: b.referenceCurrency ?? "USD",
            ReferenceCurrencySymbol: b.referenceCurrencySymbol ?? "$",
            DefaultExchangeRate: b.defaultExchangeRate ?? 1.0,
            PricesIncludeTax: b.pricesIncludeTax ?? false,
            SpecialTaxRate: b.specialTaxRate ?? 0,
            SpecialTaxEnabled: b.specialTaxEnabled ?? false,
            TaxAuthorityCode: b.taxAuthorityCode ?? null,
            FiscalIdName: b.fiscalIdName ?? null,
            TimeZoneIana: b.timeZoneIana ?? null,
            PhonePrefix: b.phonePrefix ?? null,
            SortOrder: b.sortOrder ?? 100,
            IsActive: b.isActive ?? true,
        }, { Resultado: sql.Int, Mensaje: sql.NVarChar(500) });
        res.json({ success: Number(output.Resultado ?? 0) >= 0, message: output.Mensaje });
    } catch (err: any) {
        res.status(500).json({ error: err.message });
    }
});
