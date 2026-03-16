import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

export interface JwtPayload {
    userId: number;
    email: string;
    roles: string[];
}

declare global {
    namespace Express {
        interface Request {
            user?: JwtPayload;
        }
    }
}

export function requireJwt(req: Request, res: Response, next: NextFunction) {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
        return res.status(401).json({ error: "missing_token" });
    }

    const token = header.slice(7);
    try {
        const decoded = jwt.verify(token, env.jwt.secret) as JwtPayload;
        req.user = decoded;
        next();
    } catch {
        return res.status(401).json({ error: "invalid_token" });
    }
}

export function requireRole(...roles: string[]) {
    return (req: Request, res: Response, next: NextFunction) => {
        if (!req.user) return res.status(401).json({ error: "not_authenticated" });
        const hasRole = req.user.roles.some((r) => roles.includes(r));
        if (!hasRole) return res.status(403).json({ error: "forbidden" });
        next();
    };
}
