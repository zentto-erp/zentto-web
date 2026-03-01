import { Router } from "express";
import { z } from "zod";
import { listBookings, getBooking, createBooking, updateBooking, updateBookingStatus, deleteBooking } from "./service.js";

export const bookingsRouter = Router();

const qSchema = z.object({ search: z.string().optional(), status: z.string().optional(), provider_id: z.string().optional(), customer_id: z.string().optional(), from: z.string().optional(), to: z.string().optional(), page: z.string().optional(), limit: z.string().optional() });

bookingsRouter.get("/", async (req, res) => {
    const parsed = qSchema.safeParse(req.query);
    if (!parsed.success) return res.status(400).json({ error: "invalid_query" });
    res.json(await listBookings(parsed.data));
});

bookingsRouter.get("/:id", async (req, res) => {
    const data = await getBooking(Number(req.params.id));
    if (!data) return res.status(404).json({ error: "not_found" });
    res.json(data);
});

bookingsRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createBooking(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

bookingsRouter.put("/:id", async (req, res) => {
    try { res.json(await updateBooking(Number(req.params.id), req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

bookingsRouter.patch("/:id/status", async (req, res) => {
    try {
        const { status, notes } = req.body;
        res.json(await updateBookingStatus(Number(req.params.id), status, req.user?.userId, notes));
    } catch (err: any) {
        res.status(400).json({ error: err.message });
    }
});

bookingsRouter.delete("/:id", async (req, res) => {
    try { res.json(await deleteBooking(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
