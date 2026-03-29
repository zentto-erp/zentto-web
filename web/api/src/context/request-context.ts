import { AsyncLocalStorage } from "node:async_hooks";
import type { Pool } from "pg";
import type { JwtPayload } from "../auth/jwt.js";

export type RequestScope = {
  companyId: number;
  branchId: number;
  companyCode?: string;
  companyName?: string;
  branchCode?: string;
  branchName?: string;
  countryCode?: string;
  timeZone?: string;
  dbName?: string;
  isDemo?: boolean;
};

type RequestContext = {
  user?: JwtPayload;
  scope?: RequestScope;
  tenantPool?: Pool;
};

const requestContextStorage = new AsyncLocalStorage<RequestContext>();

export function runWithRequestContext<T>(context: RequestContext, callback: () => T): T {
  return requestContextStorage.run(context, callback);
}

export function getRequestContext() {
  return requestContextStorage.getStore() ?? null;
}

export function getRequestScope() {
  return requestContextStorage.getStore()?.scope ?? null;
}

/** Obtiene el pool del tenant del request actual (o null si no hay context) */
export function getTenantPoolFromContext(): Pool | null {
  return requestContextStorage.getStore()?.tenantPool ?? null;
}
