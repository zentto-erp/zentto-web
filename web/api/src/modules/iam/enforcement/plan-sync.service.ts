/**
 * Plan-to-module synchronization service.
 *
 * Called from billing webhook (subscription.updated) to ensure
 * user module access is updated when a tenant changes plan.
 */
import { callSp } from "../../../db/query.js";
import { applyPlanModules } from "../../license/license.service.js";

/**
 * Resolves companyId from a Paddle subscription ID, then applies the
 * new plan's module set to all users of that tenant.
 */
export async function syncPlanModules(
  paddleSubscriptionId: string,
  planName: string
): Promise<{ synced: boolean; companyId?: number; modulesApplied?: number }> {
  // Resolve companyId from Paddle subscription
  const rows = await callSp<{ CompanyId: number }>(
    "usp_sys_Subscription_GetCompanyByPaddleId",
    { PaddleSubscriptionId: paddleSubscriptionId }
  );

  const companyId = rows[0]?.CompanyId;
  if (!companyId) {
    console.warn(`[iam:plan-sync] No company found for Paddle sub ${paddleSubscriptionId}`);
    return { synced: false };
  }

  const result = await applyPlanModules(companyId, planName);
  console.log(`[iam:plan-sync] Plan ${planName} applied to company ${companyId}: ${result.modulesApplied} modules`);

  return { synced: true, companyId, modulesApplied: result.modulesApplied };
}
