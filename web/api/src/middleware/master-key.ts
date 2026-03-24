/**
 * master-key.ts — Middleware de autenticación por X-Master-Key
 *
 * Protege endpoints del backoffice y operaciones de licencias que no requieren JWT.
 * La clave se configura via MASTER_API_KEY en .env.
 */
import type { Request, Response, NextFunction } from "express";

export function requireMasterKey(req: Request, res: Response, next: NextFunction): void {
  const key = req.headers['x-master-key'];
  if (!key || key !== process.env.MASTER_API_KEY) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }
  next();
}
