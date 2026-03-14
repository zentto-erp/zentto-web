import { query } from "../../db/query.js";
import { isBcryptHash, verifyPassword } from "../../auth/password.js";
import {
  hasActiveSupervisorBiometricCredential,
  touchSupervisorBiometricCredential,
} from "./supervisor-biometric.service.js";

type OverrideStatus = "APPROVED" | "CONSUMED" | "CANCELLED";

interface SupervisorRecord {
  codUsuario: string;
  nombre: string | null;
  tipo: string | null;
  isAdmin: boolean | null;
  canDelete: boolean | null;
  passwordHash: string | null;
}

function normalizeCode(value: unknown) {
  return String(value ?? "").trim().toUpperCase();
}

function normalizeText(value: unknown, max = 300) {
  const normalized = String(value ?? "").trim();
  if (!normalized) return "";
  return normalized.slice(0, max);
}

function isSupervisor(record: SupervisorRecord) {
  const tipo = normalizeCode(record.tipo);
  return (
    Boolean(record.isAdmin) ||
    tipo === "ADMIN" ||
    tipo === "SUP" ||
    tipo === "SUPERVISOR" ||
    Boolean(record.canDelete)
  );
}

export async function validateSupervisorCredentials(input: {
  supervisorUser: string;
  supervisorPassword: string;
  requestedByUser?: string | null;
  biometricBypass?: boolean;
  biometricCredentialId?: string | null;
}) {
  const supervisorUser = normalizeCode(input.supervisorUser);
  const requestedBy = normalizeCode(input.requestedByUser);
  const password = String(input.supervisorPassword ?? "");
  const biometricCredentialId = String(input.biometricCredentialId ?? "").trim();

  if (!supervisorUser) {
    return {
      ok: false as const,
      error: "supervisor_credentials_required",
      message: "Debe indicar usuario de supervisor.",
    };
  }

  if (requestedBy && requestedBy === supervisorUser) {
    return {
      ok: false as const,
      error: "self_approval_not_allowed",
      message: "La autorizacion supervisoria debe ser realizada por un usuario distinto al operador.",
    };
  }

  const rows = await query<SupervisorRecord>(
    `
    SELECT TOP 1
      Cod_Usuario AS codUsuario,
      Nombre AS nombre,
      Tipo AS tipo,
      IsAdmin AS isAdmin,
      Deletes AS canDelete,
      Password AS passwordHash
    FROM dbo.Usuarios
    WHERE UPPER(Cod_Usuario) = @supervisorUser
    `,
    { supervisorUser }
  );

  const supervisor = rows[0];
  if (!supervisor) {
    return {
      ok: false as const,
      error: "supervisor_not_found",
      message: "Supervisor no encontrado.",
    };
  }

  if (!isSupervisor(supervisor)) {
    return {
      ok: false as const,
      error: "supervisor_insufficient_permissions",
      message: "El usuario indicado no tiene permisos de supervision.",
    };
  }

  if (input.biometricBypass) {
    if (!biometricCredentialId) {
      return {
        ok: false as const,
        error: "biometric_credential_required",
        message: "Debe indicar la credencial biometrica del supervisor.",
      };
    }

    const biometric = await hasActiveSupervisorBiometricCredential({
      supervisorUser,
      credentialId: biometricCredentialId,
    });
    if (!biometric.ok) {
      return {
        ok: false as const,
        error: "biometric_credential_not_registered",
        message: "La credencial biometrica no esta registrada para este supervisor.",
      };
    }

    await touchSupervisorBiometricCredential({
      supervisorUser,
      credentialId: biometricCredentialId,
    });

    return {
      ok: true as const,
      supervisorUser,
      supervisorName: String(supervisor.nombre ?? supervisorUser),
      biometricCredentialId,
    };
  }

  if (!password) {
    return {
      ok: false as const,
      error: "supervisor_credentials_required",
      message: "Debe indicar clave de supervisor.",
    };
  }

  const hash = String(supervisor.passwordHash ?? "");
  if (!isBcryptHash(hash)) {
    return {
      ok: false as const,
      error: "supervisor_password_legacy_not_allowed",
      message: "El supervisor debe tener clave actualizada para autorizar esta accion.",
    };
  }

  const validPassword = await verifyPassword(password, hash);
  if (!validPassword) {
    return {
      ok: false as const,
      error: "supervisor_invalid_password",
      message: "Clave de supervisor invalida.",
    };
  }

  return {
    ok: true as const,
    supervisorUser,
    supervisorName: String(supervisor.nombre ?? supervisorUser),
    biometricCredentialId: null,
  };
}

export async function createSupervisorOverride(input: {
  moduleCode: string;
  actionCode: string;
  reason: string;
  supervisorUser: string;
  requestedByUser?: string | null;
  companyId?: number | null;
  branchId?: number | null;
  payload?: unknown;
}) {
  const moduleCode = normalizeCode(input.moduleCode);
  const actionCode = normalizeCode(input.actionCode);
  const reason = normalizeText(input.reason, 300) || "Sin motivo";
  const requestedByUser = normalizeCode(input.requestedByUser) || null;
  const supervisorUser = normalizeCode(input.supervisorUser);
  const payloadJson = input.payload === undefined ? null : JSON.stringify(input.payload);

  const rows = await query<{ overrideId: number }>(
    `
    INSERT INTO sec.SupervisorOverride (
      ModuleCode,
      ActionCode,
      Status,
      CompanyId,
      BranchId,
      RequestedByUserCode,
      SupervisorUserCode,
      Reason,
      PayloadJson,
      ApprovedAtUtc
    )
    OUTPUT INSERTED.OverrideId AS overrideId
    VALUES (
      @moduleCode,
      @actionCode,
      @status,
      @companyId,
      @branchId,
      @requestedByUserCode,
      @supervisorUserCode,
      @reason,
      @payloadJson,
      SYSUTCDATETIME()
    )
    `,
    {
      moduleCode,
      actionCode,
      status: "APPROVED" as OverrideStatus,
      companyId: input.companyId ?? null,
      branchId: input.branchId ?? null,
      requestedByUserCode: requestedByUser,
      supervisorUserCode: supervisorUser,
      reason,
      payloadJson,
    }
  );

  const overrideId = Number(rows[0]?.overrideId ?? 0);
  if (!Number.isFinite(overrideId) || overrideId <= 0) {
    throw new Error("override_not_created");
  }

  return { overrideId };
}

export async function consumeSupervisorOverride(input: {
  overrideId: number;
  moduleCode: string;
  actionCode: string;
  consumedByUser?: string | null;
  sourceDocumentId?: number | null;
  sourceLineId?: number | null;
  reversalLineId?: number | null;
}) {
  const overrideId = Number(input.overrideId);
  const moduleCode = normalizeCode(input.moduleCode);
  const actionCode = normalizeCode(input.actionCode);
  const consumedByUser = normalizeCode(input.consumedByUser) || null;

  if (!Number.isFinite(overrideId) || overrideId <= 0) {
    return { ok: false as const, error: "override_id_invalid" };
  }

  const rows = await query<{ overrideId: number }>(
    `
    UPDATE sec.SupervisorOverride
    SET
      Status = N'CONSUMED',
      ConsumedAtUtc = SYSUTCDATETIME(),
      ConsumedByUserCode = @consumedByUserCode,
      SourceDocumentId = @sourceDocumentId,
      SourceLineId = @sourceLineId,
      ReversalLineId = @reversalLineId
    OUTPUT INSERTED.OverrideId AS overrideId
    WHERE OverrideId = @overrideId
      AND Status = N'APPROVED'
      AND UPPER(ModuleCode) = @moduleCode
      AND UPPER(ActionCode) = @actionCode
    `,
    {
      overrideId,
      moduleCode,
      actionCode,
      consumedByUserCode: consumedByUser,
      sourceDocumentId: input.sourceDocumentId ?? null,
      sourceLineId: input.sourceLineId ?? null,
      reversalLineId: input.reversalLineId ?? null,
    }
  );

  return rows[0]
    ? { ok: true as const, overrideId: Number(rows[0].overrideId) }
    : { ok: false as const, error: "override_not_available" };
}

