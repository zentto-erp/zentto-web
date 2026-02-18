import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

export type JwtPayload = {
  sub: string;
  name?: string | null;
  tipo?: string | null;
  isAdmin?: boolean;
  permisos?: {
    canUpdate: boolean;
    canCreate: boolean;
    canDelete: boolean;
    canChangePrice: boolean;
    canGiveCredit: boolean;
    canChangePwd: boolean;
    isCreator: boolean;
  };
  modulos?: string[];
};

export function signJwt(payload: JwtPayload) {
  return jwt.sign(payload, env.jwt.secret, {
    expiresIn: env.jwt.expires as jwt.SignOptions["expiresIn"]
  });
}

export function verifyJwt(token: string) {
  return jwt.verify(token, env.jwt.secret) as JwtPayload & jwt.JwtPayload;
}
