import { createSupervisorOverride, validateSupervisorCredentials } from "../_shared/supervisor-override.service.js";

export async function authorizePosLineVoid(input: {
  supervisorUser: string;
  supervisorPassword: string;
  reason: string;
  requestedByUser?: string | null;
  biometricBypass?: boolean;
  biometricCredentialId?: string | null;
  companyId?: number;
  branchId?: number;
  payload?: unknown;
}) {
  const validation = await validateSupervisorCredentials({
    supervisorUser: input.supervisorUser,
    supervisorPassword: input.supervisorPassword,
    requestedByUser: input.requestedByUser,
    biometricBypass: input.biometricBypass,
    biometricCredentialId: input.biometricCredentialId,
  });

  if (!validation.ok) {
    return {
      ok: false as const,
      error: validation.error,
      message: validation.message,
    };
  }

  const override = await createSupervisorOverride({
    moduleCode: "POS",
    actionCode: "CART_LINE_VOID",
    reason: input.reason,
    supervisorUser: validation.supervisorUser,
    requestedByUser: input.requestedByUser,
    companyId: input.companyId,
    branchId: input.branchId,
    payload: input.payload,
  });

  return {
    ok: true as const,
    approvalId: override.overrideId,
    supervisorUser: validation.supervisorUser,
    supervisorName: validation.supervisorName,
  };
}
