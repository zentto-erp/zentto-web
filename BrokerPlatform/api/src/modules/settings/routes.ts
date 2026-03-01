import { Router } from "express";
import { query, execute } from "../../db/query.js";

export const settingsRouter = Router();

settingsRouter.get("/", async (req, res) => {
    const category = req.query.category as string | undefined;
    const rows = category
        ? await query<any>("SELECT * FROM Settings WHERE category = @cat ORDER BY [key]", { cat: category })
        : await query<any>("SELECT * FROM Settings ORDER BY category, [key]");
    res.json(rows);
});

settingsRouter.get("/:key", async (req, res) => {
    const rows = await query<any>("SELECT * FROM Settings WHERE [key] = @key", { key: req.params.key });
    if (!rows[0]) return res.status(404).json({ error: "not_found" });
    res.json(rows[0]);
});

settingsRouter.put("/:key", async (req, res) => {
    try {
        const { value } = req.body;
        const existing = await query<any>("SELECT id FROM Settings WHERE [key] = @key", { key: req.params.key });
        if (existing.length) {
            await execute("UPDATE Settings SET value = @value WHERE [key] = @key", { key: req.params.key, value });
        } else {
            await execute("INSERT INTO Settings ([key], value, category, description) VALUES (@key, @value, @cat, @desc)",
                { key: req.params.key, value, cat: req.body.category || 'general', desc: req.body.description || null });
        }
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});

// Countries endpoint
settingsRouter.get("/data/countries", async (_req, res) => {
    const rows = await query<any>("SELECT * FROM Countries ORDER BY name");
    res.json(rows);
});

// Commission rules
settingsRouter.get("/data/commission-rules", async (_req, res) => {
    const rows = await query<any>("SELECT * FROM CommissionRules ORDER BY provider_type");
    res.json(rows);
});

settingsRouter.put("/data/commission-rules/:id", async (req, res) => {
    try {
        const { min_pct, max_pct, default_pct } = req.body;
        await execute("UPDATE CommissionRules SET min_pct = @min, max_pct = @max, default_pct = @def WHERE id = @id",
            { id: Number(req.params.id), min: min_pct, max: max_pct, def: default_pct });
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});
