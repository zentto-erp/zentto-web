import { Router, Request, Response, NextFunction } from 'express';
import * as zohoService from './zoho.service.js';

const router = Router();

// GET /v1/integrations/zoho/connect?services=mail,sign,desk
// Redirects to Zoho OAuth authorization
router.get('/connect', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId || 1;
    const services = req.query.services ? String(req.query.services).split(',') : [];
    const url = await zohoService.getAuthorizationUrl(companyId, services);
    res.json({ ok: true, url });
  } catch (err) {
    next(err);
  }
});

// GET /v1/integrations/zoho/callback?code=...&state=companyId
// OAuth callback — exchanges code for tokens
router.get('/callback', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const code = req.query.code as string;
    const companyId = Number(req.query.state) || 1;

    if (!code) {
      return res.status(400).json({ ok: false, message: 'No authorization code' });
    }

    const tokens = await zohoService.exchangeCode(code);

    if (!tokens.access_token) {
      return res.status(400).json({ ok: false, message: 'Token exchange failed', details: tokens });
    }

    zohoService.cacheTokens(companyId, tokens);

    // Redirect back to app with success
    res.redirect('https://app.zentto.net/configuracion?zoho=connected');
  } catch (err) {
    next(err);
  }
});

// GET /v1/integrations/zoho/status
// Check if Zoho is connected for the current company
router.get('/status', async (req: Request, res: Response) => {
  const companyId = (req as any).user?.companyId || 1;
  const token = await zohoService.getValidToken(companyId);
  res.json({ ok: true, connected: !!token });
});

// POST /v1/integrations/zoho/mail/send
// Send email via Zoho Mail
router.post('/mail/send', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId || 1;
    const { accountId, to, subject, html, from } = req.body;
    const result = await zohoService.sendMailViaZoho(companyId, accountId, to, subject, html, from);
    res.json({ ok: true, data: result });
  } catch (err) {
    next(err);
  }
});

// POST /v1/integrations/zoho/sign/send
// Send document for signature
router.post('/sign/send', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId || 1;
    const { documentName, recipientEmail, recipientName, fileBase64 } = req.body;
    const result = await zohoService.sendForSignature(companyId, documentName, recipientEmail, recipientName, fileBase64);
    res.json({ ok: true, data: result });
  } catch (err) {
    next(err);
  }
});

// POST /v1/integrations/zoho/desk/ticket
// Create support ticket
router.post('/desk/ticket', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId || 1;
    const { subject, description, contactEmail, priority } = req.body;
    const result = await zohoService.createSupportTicket(companyId, subject, description, contactEmail, priority);
    res.json({ ok: true, data: result });
  } catch (err) {
    next(err);
  }
});

// POST /v1/integrations/zoho/cliq/message
// Send message to Cliq channel
router.post('/cliq/message', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const companyId = (req as any).user?.companyId || 1;
    const { channel, message } = req.body;
    const result = await zohoService.sendCliqMessage(companyId, channel, message);
    res.json({ ok: true, data: result });
  } catch (err) {
    next(err);
  }
});

export default router;
