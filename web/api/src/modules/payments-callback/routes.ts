/**
 * Callback handler — recibe del microservicio zentto-payments.
 * Routing por metadata.source:
 *   - "ecommerce"  → marcar orden tienda como pagada (usp_Store_Order_MarkPaid)
 *   - "tickets"    → callback handler propio de tickets (no llega aquí)
 *   - default      → billing SaaS (subscription.* / transaction.*)
 */
import { Router, type Request, type Response } from "express";
import { handleWebhookEvent } from "../billing/billing.service.js";
import { callSpOut, sql } from "../../db/query.js";
import { sendAuthMail } from "../usuarios/auth-mailer.service.js";
import { orderPaidTemplate } from "../usuarios/email-templates/base.js";
import { emitBusinessNotification } from "../_shared/notify.js";

export const paymentsCallbackRouter = Router();

paymentsCallbackRouter.post("/callback", async (req: Request, res: Response) => {
  try {
    const { eventType, status, providerSubId, providerTxnId, customData, rawPayload, metadata } = req.body ?? {};
    if (!eventType || !status) return res.status(400).json({ error: "missing_fields" });

    const source = (metadata?.source as string | undefined) ?? (customData?.source as string | undefined);

    // ── ECOMMERCE: marcar orden de tienda como pagada ──
    if (source === "ecommerce") {
      const orderToken = (metadata?.orderToken ?? customData?.orderToken) as string | undefined;
      if (!orderToken) return res.json({ received: true, ignored: true, reason: "no_order_token" });

      if (status === "paid") {
        try {
          const { output } = await callSpOut(
            "usp_Store_Order_MarkPaid",
            {
              CompanyId: Number(metadata?.companyId ?? customData?.companyId ?? 1),
              OrderToken: orderToken,
              PaymentRef: providerTxnId ?? req.body?.transactionId ?? "",
              PaymentMethod: req.body?.provider ?? "online",
            },
            { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
          );

          // Email + notify (best-effort, no bloquea la respuesta al microservicio)
          try {
            const customerEmail = (metadata?.customerEmail ?? customData?.customerEmail) as string | undefined;
            const customerName  = (metadata?.customerName  ?? customData?.customerName  ?? "Cliente") as string;
            const orderNumber   = (metadata?.orderNumber   ?? customData?.orderNumber   ?? orderToken) as string;
            const totalAmount   = String(metadata?.totalAmount ?? customData?.totalAmount ?? "");
            const currencyCode  = String(metadata?.currencyCode ?? customData?.currencyCode ?? "USD");
            const paymentRef    = providerTxnId ?? req.body?.transactionId ?? "";
            const trackingUrl   = `${process.env.PUBLIC_FRONTEND_URL || "https://app.zentto.net"}/confirmacion/${orderToken}`;

            if (customerEmail && Number(output.Resultado) === 1) {
              const tpl = orderPaidTemplate({
                customerName,
                orderNumber,
                total: totalAmount,
                currency: currencyCode,
                paymentRef: String(paymentRef),
                trackingUrl,
              });
              sendAuthMail({ to: customerEmail, subject: tpl.subject, text: tpl.text, html: tpl.html }).catch(() => {});
              emitBusinessNotification({
                event: "ORDER_PAID",
                to: customerEmail,
                subject: tpl.subject,
                data: {
                  Orden: orderNumber,
                  Total: totalAmount,
                  Moneda: currencyCode,
                  Referencia: String(paymentRef),
                  Tracking: trackingUrl,
                },
              }).catch(() => {});
            }
          } catch (notifyErr) {
            console.error("[payments/callback] notify error:", notifyErr);
          }

          return res.json({ received: true, processed: true, source, result: output.Resultado, message: output.Mensaje });
        } catch (err: unknown) {
          console.error("[payments/callback] usp_Store_Order_MarkPaid error:", err);
          return res.status(500).json({ error: "ecommerce_mark_paid_failed", message: err instanceof Error ? err.message : String(err) });
        }
      }

      if (["failed", "cancelled", "expired"].includes(status)) {
        console.log(`[payments/callback] ecommerce order ${orderToken} → ${status}`);
        return res.json({ received: true, status });
      }
      return res.json({ received: true, status });
    }

    // ── BILLING SAAS: subscription.* / transaction.* ──
    if (eventType.startsWith("subscription.") || eventType.startsWith("transaction.")) {
      const payload = (rawPayload ?? {}) as { event_type?: string; data?: Record<string, unknown> };
      if (!payload.event_type) {
        payload.event_type = eventType;
        payload.data = {
          id: providerSubId ?? providerTxnId,
          status: status === "paid" ? "active" : status,
          custom_data: { ...(customData ?? metadata ?? {}) },
        };
      }
      const result = await handleWebhookEvent(payload as never);
      return res.json({ received: true, ...result });
    }

    return res.json({ received: true, ignored: true, reason: "event_not_handled" });
  } catch (err: unknown) {
    console.error("[payments-callback] error:", err);
    return res.status(500).json({ error: "callback_processing_error" });
  }
});
