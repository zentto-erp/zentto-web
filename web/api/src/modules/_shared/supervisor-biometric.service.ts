import { createHash } from "node:crypto";
import { callSp } from "../../db/query.js";

interface BiometricCredentialRow {
  biometricCredentialId: number;
  supervisorUserCode: string;
  credentialId: string;
  credentialLabel: string | null;
  deviceInfo: string | null;
  isActive: boolean;
  lastValidatedAtUtc: string | null;
}

function normalizeUserCode(value: unknown) {
  return String(value ?? "").trim().toUpperCase();
}

function normalizeCredentialId(value: unknown) {
  return String(value ?? "").trim();
}

function normalizeText(value: unknown, max: number) {
  const normalized = String(value ?? "").trim();
  if (!normalized) return null;
  return normalized.slice(0, max);
}

function credentialHash(credentialId: string) {
  return createHash("sha256").update(credentialId, "utf8").digest("hex");
}

export async function hasActiveSupervisorBiometricCredential(input: {
  supervisorUser: string;
  credentialId: string;
}) {
  const supervisorUser = normalizeUserCode(input.supervisorUser);
  const normalizedCredentialId = normalizeCredentialId(input.credentialId);
  if (!supervisorUser || !normalizedCredentialId) {
    return { ok: false as const };
  }

  const rows = await callSp<{ biometricCredentialId: number }>(
    'usp_Sec_Supervisor_Biometric_HasActive',
    {
      SupervisorUser: supervisorUser,
      CredentialHash: credentialHash(normalizedCredentialId),
    }
  );

  return rows[0]
    ? {
        ok: true as const,
        biometricCredentialId: Number(rows[0].biometricCredentialId),
      }
    : { ok: false as const };
}

export async function touchSupervisorBiometricCredential(input: {
  supervisorUser: string;
  credentialId: string;
}) {
  const supervisorUser = normalizeUserCode(input.supervisorUser);
  const normalizedCredentialId = normalizeCredentialId(input.credentialId);
  if (!supervisorUser || !normalizedCredentialId) return;

  await callSp('usp_Sec_Supervisor_Biometric_Touch', {
    SupervisorUser: supervisorUser,
    CredentialHash: credentialHash(normalizedCredentialId),
  });
}

export async function enrollSupervisorBiometricCredential(input: {
  supervisorUser: string;
  credentialId: string;
  credentialLabel?: string | null;
  deviceInfo?: string | null;
  actorUser?: string | null;
}) {
  const supervisorUser = normalizeUserCode(input.supervisorUser);
  const normalizedCredentialId = normalizeCredentialId(input.credentialId);
  const credentialLabel = normalizeText(input.credentialLabel, 120);
  const deviceInfo = normalizeText(input.deviceInfo, 300);
  const actorUser = normalizeUserCode(input.actorUser) || supervisorUser;

  if (!supervisorUser || !normalizedCredentialId) {
    throw new Error("biometric_credential_required");
  }

  const hash = credentialHash(normalizedCredentialId);

  const rows = await callSp<{ biometricCredentialId: number }>(
    'usp_Sec_Supervisor_Biometric_Enroll',
    {
      SupervisorUser: supervisorUser,
      CredentialHash: hash,
      CredentialId: normalizedCredentialId,
      CredentialLabel: credentialLabel,
      DeviceInfo: deviceInfo,
      ActorUser: actorUser,
    }
  );

  const biometricCredentialId = Number(rows[0]?.biometricCredentialId ?? 0);
  if (!Number.isFinite(biometricCredentialId) || biometricCredentialId <= 0) {
    throw new Error("biometric_credential_not_saved");
  }

  return { biometricCredentialId };
}

export async function listSupervisorBiometricCredentials(input: {
  supervisorUser?: string | null;
}) {
  const supervisorUser = normalizeUserCode(input.supervisorUser);

  const rows = await callSp<BiometricCredentialRow>(
    'usp_Sec_Supervisor_Biometric_List',
    { SupervisorUser: supervisorUser }
  );

  return rows.map((row) => ({
    biometricCredentialId: Number(row.biometricCredentialId),
    supervisorUserCode: normalizeUserCode(row.supervisorUserCode),
    credentialId: String(row.credentialId ?? ""),
    credentialLabel: row.credentialLabel ?? null,
    deviceInfo: row.deviceInfo ?? null,
    isActive: Boolean(row.isActive),
    lastValidatedAtUtc: row.lastValidatedAtUtc ?? null,
  }));
}

export async function deactivateSupervisorBiometricCredential(input: {
  supervisorUser: string;
  credentialId: string;
  actorUser?: string | null;
}) {
  const supervisorUser = normalizeUserCode(input.supervisorUser);
  const normalizedCredentialId = normalizeCredentialId(input.credentialId);
  const actorUser = normalizeUserCode(input.actorUser) || supervisorUser;
  if (!supervisorUser || !normalizedCredentialId) {
    return { ok: false as const, error: "biometric_credential_required" };
  }

  const rows = await callSp<{ biometricCredentialId: number }>(
    'usp_Sec_Supervisor_Biometric_Deactivate',
    {
      SupervisorUser: supervisorUser,
      CredentialHash: credentialHash(normalizedCredentialId),
      ActorUser: actorUser,
    }
  );

  return rows[0]
    ? { ok: true as const, biometricCredentialId: Number(rows[0].biometricCredentialId) }
    : { ok: false as const, error: "biometric_credential_not_found" };
}
