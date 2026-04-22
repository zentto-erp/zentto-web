import { Router } from 'express';
import type { AuthenticatedRequest } from '../../middleware/auth.js';
import * as service from './sistema.service.js';

const router = Router();

// /v1/sistema/notificaciones?appCode=crm
// Scope:
//   - usuarioId: del JWT
//   - companyId: del header x-company-id (inyectado por el cliente)
//   - appCode:   del query param (frontend lo pasa segun la app actual)
router.get('/notificaciones', async (req, res) => {
    try {
        const usuarioId = (req as AuthenticatedRequest).user?.sub;
        const rawCompanyId = req.header('x-company-id');
        const companyId = rawCompanyId ? Number(rawCompanyId) : null;
        const appCode = typeof req.query.appCode === 'string' && req.query.appCode.trim()
            ? req.query.appCode.trim().toLowerCase()
            : null;
        const data = await service.getNotificaciones(
            usuarioId,
            Number.isFinite(companyId) && companyId! > 0 ? companyId : null,
            appCode,
        );
        res.json({ ok: true, data });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

router.post('/notificaciones/leido', async (req, res) => {
    try {
        const { ids } = req.body;
        if (!Array.isArray(ids)) {
            return res.status(400).json({ error: 'ids debe ser un arreglo de números' });
        }
        await service.markNotificacionesAsRead(ids);
        res.json({ ok: true });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

// /v1/sistema/tareas
router.get('/tareas', async (req, res) => {
    try {
        const asignadoA = (req as AuthenticatedRequest).user?.sub;
        const data = await service.getTareas(asignadoA);
        res.json({ ok: true, data });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

router.patch('/tareas/:id/progreso', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const { progress } = req.body;
        if (!id || typeof progress !== 'number') {
            return res.status(400).json({ error: 'id y progress son requeridos' });
        }
        const isCompleted = progress >= 100;
        await service.toggleTarea(id, isCompleted, progress);
        res.json({ ok: true });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

// /v1/sistema/mensajes
router.get('/mensajes', async (req, res) => {
    try {
        const destinatarioId = (req as AuthenticatedRequest).user?.sub;
        if (!destinatarioId) return res.status(401).json({ ok: false, error: 'missing_user' });
        const data = await service.getMensajes(destinatarioId);
        res.json({ ok: true, data });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

router.patch('/mensajes/:id/leido', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        if (!id) return res.status(400).json({ error: 'id invalido' });
        await service.markMensajeAsRead(id);
        res.json({ ok: true });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

// /v1/sistema/alertas/procesar — dispara verificación manual de alertas
router.post('/alertas/procesar', async (_req, res) => {
    try {
        const { processSystemAlerts } = await import('./alertas-automaticas.service.js');
        const result = await processSystemAlerts();
        res.json({ ok: true, ...result });
    } catch (e: any) {
        res.status(500).json({ ok: false, error: e.message });
    }
});

export const sistemaRouter = router;
