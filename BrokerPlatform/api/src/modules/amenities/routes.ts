import { Router } from "express";
import { query, execute } from "../../db/query.js";

export const amenitiesRouter = Router();

amenitiesRouter.get("/", async (_req, res) => {
    const rows = await query<any>("SELECT * FROM Amenities ORDER BY category, name");
    res.json(rows);
});

amenitiesRouter.post("/", async (req, res) => {
    try {
        const { name, icon, category } = req.body;
        const result = await execute(
            "INSERT INTO Amenities (name, icon, category) OUTPUT INSERTED.id VALUES (@name, @icon, @category)",
            { name, icon: icon || null, category: category || 'general' }
        );
        res.status(201).json({ id: result.recordset[0]?.id });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});

amenitiesRouter.put("/:id", async (req, res) => {
    try {
        const { name, icon, category } = req.body;
        await execute("UPDATE Amenities SET name = @name, icon = @icon, category = @category WHERE id = @id",
            { id: Number(req.params.id), name, icon, category });
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});

amenitiesRouter.delete("/:id", async (req, res) => {
    try {
        await execute("DELETE FROM PropertyAmenities WHERE amenity_id = @id", { id: Number(req.params.id) });
        await execute("DELETE FROM Amenities WHERE id = @id", { id: Number(req.params.id) });
        res.json({ ok: true });
    } catch (err) { res.status(400).json({ error: String(err) }); }
});
