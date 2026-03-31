import { callSp } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

interface LimitCheckResult {
  allowed: boolean;
  current: number;
  max: number | null;
  plan: string;
}

export async function checkUserLimit(companyId?: number): Promise<LimitCheckResult> {
  const cid = companyId ?? getActiveScope()?.companyId ?? 1;
  const rows = await callSp<any>("usp_Sys_License_CheckUserLimit", { CompanyId: cid });
  const r = rows[0];
  return {
    allowed: r?.allowed ?? true,
    current: r?.currentUsers ?? 0,
    max: r?.maxUsers ?? null,
    plan: r?.plan ?? 'FREE',
  };
}

export async function checkCompanyLimit(companyId?: number): Promise<LimitCheckResult & { multiCompanyEnabled: boolean }> {
  const cid = companyId ?? getActiveScope()?.companyId ?? 1;
  const rows = await callSp<any>("usp_Sys_License_CheckCompanyLimit", { CompanyId: cid });
  const r = rows[0];
  return {
    allowed: r?.allowed ?? true,
    current: r?.currentCompanies ?? 0,
    max: r?.maxCompanies ?? null,
    multiCompanyEnabled: r?.multiCompanyEnabled ?? true,
    plan: r?.plan ?? 'FREE',
  };
}
