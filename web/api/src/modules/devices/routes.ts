import { Router, Request, Response } from 'express';
import { requireJwt } from '../../middleware/auth.js';
import { callSp, callSpOut } from '../../db/query.js';

const router = Router();

/**
 * POST /v1/devices/register
 * Registra un push token de dispositivo móvil (Expo Push).
 * Requiere JWT (empleado) o customerToken (store).
 */
router.post('/register', requireJwt, async (req: Request, res: Response) => {
  try {
    const { pushToken, platform, deviceName } = req.body;
    if (!pushToken || !platform) {
      return res.status(400).json({ error: 'pushToken and platform are required' });
    }

    const scope = (req as any).scope;
    const userId = (req as any).user?.sub;

    const { output } = await callSpOut('usp_Sys_Device_Register', {
      CompanyId: scope?.companyId || 1,
      UserId: userId ? Number(userId) : null,
      PushToken: pushToken,
      Platform: platform, // 'ios' | 'android'
      DeviceName: deviceName || null,
    });

    return res.json({ ok: true, deviceId: (output as any)?.Resultado });
  } catch (err: any) {
    console.error('[devices/register]', err.message);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * POST /v1/devices/unregister
 * Elimina un push token (al hacer logout).
 */
router.post('/unregister', requireJwt, async (req: Request, res: Response) => {
  try {
    const { pushToken } = req.body;
    if (!pushToken) {
      return res.status(400).json({ error: 'pushToken is required' });
    }

    await callSpOut('usp_Sys_Device_Unregister', {
      PushToken: pushToken,
    });

    return res.json({ ok: true });
  } catch (err: any) {
    console.error('[devices/unregister]', err.message);
    return res.status(500).json({ error: err.message });
  }
});

/**
 * GET /v1/devices/my
 * Lista dispositivos registrados del usuario actual.
 */
router.get('/my', requireJwt, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.sub;
    const scope = (req as any).scope;

    const rows = await callSp('usp_Sys_Device_ListByUser', {
      CompanyId: scope?.companyId || 1,
      UserId: userId ? Number(userId) : 0,
    });

    return res.json(rows);
  } catch (err: any) {
    console.error('[devices/my]', err.message);
    return res.status(500).json({ error: err.message });
  }
});

export default router;
