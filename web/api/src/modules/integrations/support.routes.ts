import { Router, Request, Response, NextFunction } from 'express';

const router = Router();

const GITHUB_TOKEN = process.env.GITHUB_PAT || '';
const REPO = 'zentto-erp/zentto-support';

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
  } catch (err) {
    next(err);
  }
});

// GET /v1/support/tickets — List tickets for the current company
router.get('/tickets', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = (req as any).user;
    const companyName = user?.companyName || '';
    const state = (req.query.state as string) || 'open';

    const ghRes = await fetch(
      `https://api.github.com/repos/${REPO}/issues?state=${state}&per_page=50&sort=created&direction=desc`,
      {
        headers: {
          Authorization: `Bearer ${GITHUB_TOKEN}`,
          Accept: 'application/vnd.github+json',
        },
      }
    );

    const issues = await ghRes.json();

    // Filter by company name in body
    const filtered = Array.isArray(issues)
      ? issues.filter((i: any) => !companyName || i.body?.includes(companyName))
      : [];

    const tickets = filtered.map((i: any) => ({
      number: i.number,
      title: i.title,
      state: i.state,
      labels: i.labels?.map((l: any) => l.name) || [],
      createdAt: i.created_at,
      updatedAt: i.updated_at,
      url: i.html_url,
      comments: i.comments,
    }));

    res.json({ ok: true, tickets, total: tickets.length });
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

export { router as supportRouter };
