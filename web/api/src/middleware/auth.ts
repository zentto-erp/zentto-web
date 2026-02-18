import type { Request, Response, NextFunction } from "express";
import { verifyJwt, type JwtPayload } from "../auth/jwt.js";

const PUBLIC_PATHS = new Set(["/auth/login"]);

export interface AuthenticatedRequest extends Request {
  user?: JwtPayload;
}

export function requireJwt(req: Request, res: Response, next: NextFunction) {
  // Skip preflight CORS requests
  if (req.method === "OPTIONS") {
    return next();
  }

  if (PUBLIC_PATHS.has(req.path)) {
    return next();
  }

  const auth = req.headers.authorization ?? "";
  const [scheme, token] = auth.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "missing_token" });
  }

  try {
    const payload = verifyJwt(token);
    (req as AuthenticatedRequest).user = payload;
    return next();
  } catch {
    return res.status(401).json({ error: "invalid_token" });
  }
}

/** Middleware: require admin role */
export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user?.isAdmin) {
    return res.status(403).json({ error: "forbidden", message: "Requiere permisos de administrador" });
  }
  return next();
}

/** Middleware: require specific module access */
export function requireModule(modulo: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as AuthenticatedRequest).user;
    if (!user) {
      return res.status(401).json({ error: "not_authenticated" });
    }
    // Admin has access to all modules
    if (user.isAdmin) return next();
    // Check module list (from JWT)
    if (user.modulos && user.modulos.includes(modulo)) {
      return next();
    }
    return res.status(403).json({
      error: "forbidden",
      message: `No tienes acceso al módulo: ${modulo}`,
    });
  };
}

/** Middleware: require create permission */
export function requireCreate(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canCreate) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para crear registros" });
}

/** Middleware: require update permission */
export function requireUpdate(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canUpdate) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para actualizar registros" });
}

/** Middleware: require delete permission */
export function requireDelete(req: Request, res: Response, next: NextFunction) {
  const user = (req as AuthenticatedRequest).user;
  if (!user) return res.status(401).json({ error: "not_authenticated" });
  if (user.isAdmin || user.permisos?.canDelete) return next();
  return res.status(403).json({ error: "forbidden", message: "No tienes permisos para eliminar registros" });
}
