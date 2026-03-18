import { Router } from "express";
import express from "express";
import { verifyPaddleSignature, handlePaddleEvent } from "./paddle.service.js";

export const paddleWebhookRouter = Router();

paddleWebhookRouter.post(
  "/paddle",
  express.raw({ type: "*/*" }),
  async (req, res) => {
    const signature = req.headers["paddle-signature"] as string | undefined;
    if (!signature) {
      res.status(400).json({ error: "missing_paddle_signature" });
      return;
    }

    const rawBody = req.body as Buffer;

    if (!verifyPaddleSignature(rawBody, signature)) {
      res.status(401).json({ error: "invalid_signature" });
      return;
    }

    let event: Record<string, unknown>;
    try {
      event = JSON.parse(rawBody.toString("utf8"));
    } catch {
      res.status(400).json({ error: "invalid_json" });
      return;
    }

    try {
      const result = await handlePaddleEvent(event);
      res.json({ ok: true, ...result });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "internal_error";
      res.status(500).json({ error: msg });
    }
  }
);
