import { Router } from "express";
import { z } from "zod";
import { registerUser, loginUser, getMe } from "./service.js";
import { requireJwt } from "../../middleware/auth.js";

export const authRouter = Router();

const registerSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    first_name: z.string().min(1),
    last_name: z.string().min(1),
    phone: z.string().optional(),
    role: z.enum(["admin", "provider", "customer"]).optional(),
});

const loginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(1),
});

authRouter.post("/register", async (req, res) => {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "validation_error", details: parsed.error.flatten() });
    try {
        const result = await registerUser(parsed.data);
        res.status(201).json({ ok: true, ...result });
    } catch (err: any) {
        const status = err.message === "email_already_exists" ? 409 : 400;
        res.status(status).json({ error: err.message });
    }
});

authRouter.post("/login", async (req, res) => {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: "validation_error", details: parsed.error.flatten() });
    try {
        const result = await loginUser(parsed.data.email, parsed.data.password);
        res.json(result);
    } catch (err: any) {
        res.status(401).json({ error: err.message });
    }
});

authRouter.get("/me", requireJwt, async (req, res) => {
    const user = await getMe(req.user!.userId);
    if (!user) return res.status(404).json({ error: "user_not_found" });
    res.json(user);
});
