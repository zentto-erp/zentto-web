import { Router } from "express";
import { listPayments, createPayment, updatePaymentStatus, listInvoices, createInvoice, createRefund, approveRefund } from "./service.js";

export const paymentsRouter = Router();

paymentsRouter.get("/", async (req, res) => { res.json(await listPayments(req.query as any)); });
paymentsRouter.post("/", async (req, res) => {
    try { res.status(201).json(await createPayment(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
paymentsRouter.patch("/:id/status", async (req, res) => {
    try { res.json(await updatePaymentStatus(Number(req.params.id), req.body.status)); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

// Invoices
paymentsRouter.get("/invoices", async (req, res) => { res.json(await listInvoices(req.query as any)); });
paymentsRouter.post("/invoices", async (req, res) => {
    try { res.status(201).json(await createInvoice(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});

// Refunds
paymentsRouter.post("/refunds", async (req, res) => {
    try { res.status(201).json(await createRefund(req.body ?? {})); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
paymentsRouter.patch("/refunds/:id/approve", async (req, res) => {
    try { res.json(await approveRefund(Number(req.params.id))); }
    catch (err) { res.status(400).json({ error: String(err) }); }
});
