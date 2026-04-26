import { Router } from 'express';
import express from 'express';
import crypto from 'crypto';
import { notifyEmail } from '../_shared/notify.js';

export const githubSupportWebhookRouter = Router();

/** Escapa caracteres HTML para prevenir XSS en emails de notificación */
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || '';

function verifySignature(rawBody: Buffer, signature: string | undefined): boolean {
  if (!WEBHOOK_SECRET || !signature) return false;
  const expected = 'sha256=' + crypto.createHmac('sha256', WEBHOOK_SECRET).update(rawBody).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}

function extractEmailFromBody(body: string): string | null {
  const match = body?.match(/\*\*Email:\*\*\s*(.+)/);
  return match?.[1]?.trim() || null;
}

function buildNotificationHtml(title: string, message: string, ticketNumber: number): string {
  return `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">
      <div style="background:#1a1a2e;color:#fff;padding:20px;text-align:center;border-radius:8px 8px 0 0">
        <h2 style="margin:0">${title}</h2>
      </div>
      <div style="padding:20px;background:#fff;border:1px solid #eee">
        <p style="color:#333">${message}</p>
      </div>
      <div style="padding:12px;text-align:center;color:#999;font-size:12px">
        <a href="https://app.zentto.net/soporte/${ticketNumber}" style="color:#1a73e8">Ver ticket en Zentto</a> · Enviado por Zentto ERP
      </div>
    </div>
  `;
}

githubSupportWebhookRouter.post(
  '/github-support',
  express.raw({ type: '*/*' }),
  async (req, res) => {
    const signature = req.headers['x-hub-signature-256'] as string | undefined;

    if (!verifySignature(req.body as Buffer, signature)) {
      res.status(401).json({ error: 'invalid_signature' });
      return;
    }

    let payload: Record<string, any>;
    try {
      payload = JSON.parse((req.body as Buffer).toString('utf8'));
    } catch {
      res.status(400).json({ error: 'invalid_json' });
      return;
    }

    const event = req.headers['x-github-event'] as string;

    try {
      // Issue closed
      if (event === 'issues' && payload.action === 'closed') {
        const email = extractEmailFromBody(payload.issue?.body);
        if (email) {
          await notifyEmail(
            email,
            `Ticket #${payload.issue.number} resuelto`,
            buildNotificationHtml(
              `Ticket #${payload.issue.number} resuelto`,
              // nosemgrep: raw-html-format — inputs ya pasaron por escapeHtml(), HTML estatico controlado.
              `Tu ticket "<strong>${escapeHtml(String(payload.issue.title))}</strong>" ha sido cerrado. Si el problema persiste, puedes reabrir el ticket desde la plataforma.`,
              payload.issue.number,
            ),
          );
        }
      }

      // Issue labeled with ai-pr (AI created a PR)
      if (event === 'issues' && payload.action === 'labeled' && payload.label?.name === 'ai-pr') {
        const email = extractEmailFromBody(payload.issue?.body);
        if (email) {
          await notifyEmail(
            email,
            `IA creó una corrección para Ticket #${payload.issue.number}`,
            buildNotificationHtml(
              `Corrección automática en progreso`,
              // nosemgrep: raw-html-format — inputs ya pasaron por escapeHtml(), HTML estatico controlado.
              `Nuestro agente de IA ha analizado tu reporte "<strong>${escapeHtml(String(payload.issue.title))}</strong>" y ha creado una propuesta de corrección. El equipo de desarrollo la revisará próximamente.`,
              payload.issue.number,
            ),
          );
        }
      }

      // New comment on issue (only from non-bot users)
      if (event === 'issue_comment' && payload.action === 'created') {
        const isBot = payload.comment?.user?.type === 'Bot';
        if (!isBot) {
          const email = extractEmailFromBody(payload.issue?.body);
          if (email) {
            const commentPreview = escapeHtml((payload.comment.body || '').slice(0, 300));
            await notifyEmail(
              email,
              `Nuevo comentario en Ticket #${payload.issue.number}`,
              buildNotificationHtml(
                `Nuevo comentario en Ticket #${payload.issue.number}`,
                // nosemgrep: raw-html-format — login y commentPreview ya pasaron por escapeHtml(), HTML estatico controlado.
                `<strong>${escapeHtml(String(payload.comment.user.login))}</strong> comentó:<br><br><blockquote style="border-left:3px solid #ddd;padding-left:12px;color:#555">${commentPreview}</blockquote>`,
                payload.issue.number,
              ),
            );
          }
        }
      }

      res.json({ ok: true });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'internal_error';
      res.status(500).json({ error: msg });
    }
  },
);
