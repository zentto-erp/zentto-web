import { Router, Request, Response, NextFunction } from 'express';
import { notifyEmail } from '../_shared/notify.js';
import { obs } from './observability.js';

const router = Router();

const GITHUB_TOKEN = process.env.GITHUB_PAT || '';
const REPO = 'zentto-erp/zentto-support';
const SUPPORT_EMAIL = process.env.SUPPORT_TEAM_EMAIL || 'soporte@zentto.net';

const MODULE_LABELS: Record<string, string> = {
  ventas: 'modulo:ventas',
  compras: 'modulo:compras',
  inventario: 'modulo:inventario',
  contabilidad: 'modulo:contabilidad',
  bancos: 'modulo:bancos',
  nomina: 'modulo:nomina',
  pos: 'modulo:pos',
  restaurante: 'modulo:restaurante',
  ecommerce: 'modulo:ecommerce',
  crm: 'modulo:crm',
  logistica: 'modulo:logistica',
  auditoria: 'modulo:auditoria',
  fiscal: 'modulo:fiscal',
  mobile: 'modulo:mobile',
};

// POST /v1/support/ticket — Create support ticket as GitHub Issue
router.post('/ticket', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = (req as any).user;
    const {
      type = 'bug',        // bug | feature | question
      module,              // ventas, inventario, etc.
      title,
      description,
      severity,            // critico | alto | medio | bajo
      steps,               // pasos para reproducir (solo bugs)
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ ok: false, message: 'Título y descripción son requeridos' });
    }

    // Build labels
    const labels: string[] = [type];
    if (module && MODULE_LABELS[module]) labels.push(MODULE_LABELS[module]);
    if (severity === 'critico') labels.push('urgent');
    if (type === 'bug') labels.push('ai-fix');

    // Build issue body
    const meta = [
      `**Empresa:** ${user?.companyName || 'N/A'}`,
      `**Usuario:** ${user?.userName || 'N/A'}`,
      `**Email:** ${user?.email || 'N/A'}`,
      `**Módulo:** ${module || 'General'}`,
      `**Tipo:** ${type}`,
      severity ? `**Severidad:** ${severity}` : '',
      `**Fecha:** ${new Date().toISOString()}`,
    ].filter(Boolean).join('\n');

    let body = `## Información\n\n${meta}\n\n## Descripción\n\n${description}`;
    if (steps) body += `\n\n## Pasos para reproducir\n\n${steps}`;
    if (type === 'bug') {
      body += `\n\n---\n\n@claude Analiza este reporte de bug. Lee CLAUDE.md, identifica la causa raíz en el código y crea un PR con la corrección en zentto-web. Si no puedes resolverlo, comenta explicando tus hallazgos.`;
    }
    body += `\n\n---\n*Ticket creado automáticamente desde Zentto ERP*`;

    // Create GitHub Issue
    const ghRes = await fetch(`https://api.github.com/repos/${REPO}/issues`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
        Accept: 'application/vnd.github+json',
      },
      body: JSON.stringify({ title, body, labels }),
    });

    const issue = await ghRes.json();

    if (!ghRes.ok) {
      return res.status(500).json({ ok: false, message: 'Error al crear ticket', details: issue.message });
    }

    res.json({
      ok: true,
      ticketNumber: issue.number,
      ticketUrl: issue.html_url,
      message: `Ticket #${issue.number} creado exitosamente`,
    });

    // Observability: Kafka event + audit
    obs.event('support.ticket.created', {
      ticketNumber: issue.number,
      type,
      module: module || 'general',
      severity: severity || 'normal',
      companyId: user?.companyId,
      companyName: user?.companyName,
      userId: user?.userId,
    });
    obs.audit('support.ticket.create', {
      module: 'support',
      entity: 'ticket',
      entityId: issue.number,
      userId: user?.userId,
      userName: user?.userName,
      companyId: user?.companyId,
    });

    // Fire-and-forget: email confirmación al usuario
    const userEmail = user?.email;
    if (userEmail) {
      notifyEmail(
        userEmail,
        `Ticket #${issue.number} creado — ${title}`,
        buildTicketEmailHtml(issue.number, title, description, 'creado'),
      ).catch(() => {});
    }

    // Fire-and-forget: email alerta al equipo de soporte
    notifyEmail(
      SUPPORT_EMAIL,
      `[Soporte] Nuevo ticket #${issue.number} — ${severity || 'normal'} — ${module || 'general'}`,
      buildTicketEmailHtml(issue.number, title, description, 'nuevo', {
        empresa: user?.companyName,
        usuario: user?.userName,
        email: userEmail,
        modulo: module,
        severidad: severity,
      }),
    ).catch(() => {});
  } catch (err) {
    next(err);
  }
});

// GET /v1/support/tickets — List tickets (filtered by user email, or all for admins)
router.get('/tickets', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = (req as any).user;
    const userEmail = user?.email || '';
    const isAdmin = user?.role === 'admin' || user?.role === 'superadmin';
    const scope = req.query.scope as string; // scope=all → backoffice (admin only)
    const state = (req.query.state as string) || 'open';

    const ghRes = await fetch(
      `https://api.github.com/repos/${REPO}/issues?state=${state}&per_page=100&sort=created&direction=desc`,
      {
        headers: {
          Authorization: `Bearer ${GITHUB_TOKEN}`,
          Accept: 'application/vnd.github+json',
        },
      }
    );

    const issues = await ghRes.json();
    if (!Array.isArray(issues)) {
      return res.json({ ok: true, tickets: [], total: 0 });
    }

    // Admin + scope=all → all tickets; otherwise filter by user email
    const filtered = (scope === 'all' && isAdmin)
      ? issues
      : issues.filter((i: any) => userEmail && i.body?.includes(`**Email:** ${userEmail}`));

    const tickets = filtered.map((i: any) => ({
      number: i.number,
      title: i.title,
      state: i.state,
      labels: i.labels?.map((l: any) => l.name) || [],
      createdAt: i.created_at,
      updatedAt: i.updated_at,
      url: i.html_url,
      comments: i.comments,
      // Extra fields for backoffice
      ...(scope === 'all' && isAdmin ? {
        company: i.body?.match(/\*\*Empresa:\*\*\s*(.+)/)?.[1]?.trim() || '',
        email: i.body?.match(/\*\*Email:\*\*\s*(.+)/)?.[1]?.trim() || '',
        module: i.body?.match(/\*\*Módulo:\*\*\s*(.+)/)?.[1]?.trim() || '',
        severity: i.body?.match(/\*\*Severidad:\*\*\s*(.+)/)?.[1]?.trim() || '',
      } : {}),
    }));

    // Stats for backoffice
    const stats = (scope === 'all' && isAdmin) ? {
      total: tickets.length,
      bugs: tickets.filter((t: any) => t.labels.includes('bug')).length,
      features: tickets.filter((t: any) => t.labels.includes('feature')).length,
      questions: tickets.filter((t: any) => t.labels.includes('question')).length,
      urgent: tickets.filter((t: any) => t.labels.includes('urgent')).length,
      aiFixed: tickets.filter((t: any) => t.labels.includes('ai-pr')).length,
      aiPending: tickets.filter((t: any) => t.labels.includes('ai-fix') && !t.labels.includes('ai-pr')).length,
    } : undefined;

    res.json({ ok: true, tickets, total: tickets.length, stats });
  } catch (err) {
    next(err);
  }
});

// GET /v1/support/tickets/:number — Get ticket detail with comments
router.get('/tickets/:number', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { number } = req.params;

    const [issueRes, commentsRes] = await Promise.all([
      fetch(`https://api.github.com/repos/${REPO}/issues/${number}`, {
        headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: 'application/vnd.github+json' },
      }),
      fetch(`https://api.github.com/repos/${REPO}/issues/${number}/comments`, {
        headers: { Authorization: `Bearer ${GITHUB_TOKEN}`, Accept: 'application/vnd.github+json' },
      }),
    ]);

    const issue = await issueRes.json();
    const comments = await commentsRes.json();

    res.json({
      ok: true,
      ticket: {
        number: issue.number,
        title: issue.title,
        body: issue.body,
        state: issue.state,
        labels: issue.labels?.map((l: any) => l.name) || [],
        createdAt: issue.created_at,
        updatedAt: issue.updated_at,
        closedAt: issue.closed_at,
        url: issue.html_url,
      },
      comments: Array.isArray(comments)
        ? comments.map((c: any) => ({
            author: c.user?.login,
            body: c.body,
            createdAt: c.created_at,
          }))
        : [],
    });
  } catch (err) {
    next(err);
  }
});

// POST /v1/support/tickets/:number/comment — Add comment to ticket
router.post('/tickets/:number/comment', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { number } = req.params;
    const { message } = req.body;
    const user = (req as any).user;

    if (!message) {
      return res.status(400).json({ ok: false, message: 'Mensaje requerido' });
    }

    const body = `**${user?.userName || 'Cliente'}** (${user?.companyName || ''}):\n\n${message}`;

    const ghRes = await fetch(`https://api.github.com/repos/${REPO}/issues/${number}/comments`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
        Accept: 'application/vnd.github+json',
      },
      body: JSON.stringify({ body }),
    });

    const comment = await ghRes.json();

    res.json({ ok: true, commentId: comment.id });
  } catch (err) {
    next(err);
  }
});

// PATCH /v1/support/tickets/:number/close — Close a ticket
router.patch('/tickets/:number/close', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { number } = req.params;

    const ghRes = await fetch(`https://api.github.com/repos/${REPO}/issues/${number}`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
        Accept: 'application/vnd.github+json',
      },
      body: JSON.stringify({ state: 'closed' }),
    });

    if (!ghRes.ok) {
      const err = await ghRes.json();
      return res.status(500).json({ ok: false, message: err.message });
    }

    res.json({ ok: true, message: `Ticket #${number} cerrado` });
  } catch (err) {
    next(err);
  }
});

// ─── Email HTML helper ──────────────────────────────────────────

function buildTicketEmailHtml(
  number: number,
  title: string,
  description: string,
  action: string,
  meta?: Record<string, string | undefined>,
): string {
  const metaRows = meta
    ? Object.entries(meta)
        .filter(([, v]) => v)
        .map(([k, v]) => `<tr><td style="padding:4px 12px;font-weight:600;color:#555;text-transform:capitalize">${k}</td><td style="padding:4px 12px">${v}</td></tr>`)
        .join('')
    : '';

  return `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">
      <div style="background:#1a1a2e;color:#fff;padding:20px;text-align:center;border-radius:8px 8px 0 0">
        <h2 style="margin:0">Ticket #${number} ${action}</h2>
      </div>
      <div style="padding:20px;background:#fff;border:1px solid #eee">
        <h3 style="margin-top:0">${title}</h3>
        <p style="color:#555">${description.slice(0, 500)}${description.length > 500 ? '...' : ''}</p>
        ${metaRows ? `<table style="width:100%;border-collapse:collapse;margin-top:12px">${metaRows}</table>` : ''}
      </div>
      <div style="padding:12px;text-align:center;color:#999;font-size:12px">
        <a href="https://app.zentto.net/soporte/${number}" style="color:#1a73e8">Ver ticket en Zentto</a> · Enviado por Zentto ERP
      </div>
    </div>
  `;
}

export { router as supportRouter };
