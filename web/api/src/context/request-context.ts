import { AsyncLocalStorage } from "node:async_hooks";
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
};

type RequestContext = {
  user?: JwtPayload;
  scope?: RequestScope;
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
