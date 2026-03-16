import { getRequestScope } from "../../context/request-context.js";

export type ActiveScope = {
  companyId: number;
  branchId: number;
  countryCode?: string;
  timeZone?: string;
  companyCode?: string;
  companyName?: string;
  branchCode?: string;
  branchName?: string;
};

export function getActiveScope(): ActiveScope | null {
  const scope = getRequestScope();
  if (!scope) return null;

  const companyId = Number(scope.companyId);
  const branchId = Number(scope.branchId);
  if (!Number.isFinite(companyId) || companyId <= 0) return null;
  if (!Number.isFinite(branchId) || branchId <= 0) return null;

  return {
    companyId,
    branchId,
    countryCode: scope.countryCode,
    companyCode: scope.companyCode,
    companyName: scope.companyName,
    branchCode: scope.branchCode,
    branchName: scope.branchName,
    timeZone: scope.timeZone,
  };
}
