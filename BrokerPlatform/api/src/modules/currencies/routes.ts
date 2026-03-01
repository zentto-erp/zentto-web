import { Router } from "express";
import { query, execute } from "../../db/query.js";

export const currenciesRouter = Router();

currenciesRouter.get("/", async (_req, res) => {
    const rows = await query<any>("SELECT * FROM Currencies ORDER BY code");
    res.json(rows);
});

currenciesRouter.post("/", async (req, res) => {
    try {
        const { code, name, symbol, exchange_rate } = req.body;
        await execute("INSERT INTO Currencies (code, name, symbol, exchange_rate) VALUES (@code, @name, @symbol, @rate)",
            { code, name, symbol, rate: exchange_rate || 1 });
        res.status(201).json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});

currenciesRouter.put("/:code", async (req, res) => {
    try {
        const { name, symbol, exchange_rate } = req.body;
        await execute("UPDATE Currencies SET name = @name, symbol = @symbol, exchange_rate = @rate WHERE code = @code",
            { code: req.params.code, name, symbol, rate: exchange_rate });
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});

currenciesRouter.delete("/:code", async (req, res) => {
    try {
        await execute("DELETE FROM Currencies WHERE code = @code", { code: req.params.code });
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});
