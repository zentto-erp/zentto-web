import { Request, Response, NextFunction } from "express";

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
    console.error("[ERROR]", err.message, err.stack);
    res.status(500).json({ error: "internal_error", message: err.message });
}
