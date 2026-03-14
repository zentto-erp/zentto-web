import { createHash } from "node:crypto";
import { query } from "../../db/query.js";

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

  const rows = await query<{ biometricCredentialId: number }>(
    `
    SELECT TOP 1 BiometricCredentialId AS biometricCredentialId
    FROM sec.SupervisorBiometricCredential
    WHERE SupervisorUserCode = @supervisorUser
      AND CredentialHash = @credentialHash
      AND IsActive = 1
    `,
    {
      supervisorUser,
      credentialHash: credentialHash(normalizedCredentialId),
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

  await query(
    `
    UPDATE sec.SupervisorBiometricCredential
    SET
      LastValidatedAtUtc = SYSUTCDATETIME(),
      UpdatedAtUtc = SYSUTCDATETIME()
    WHERE SupervisorUserCode = @supervisorUser
      AND CredentialHash = @credentialHash
      AND IsActive = 1
    `,
    {
      supervisorUser,
      credentialHash: credentialHash(normalizedCredentialId),
    }
  );
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

  const rows = await query<{ biometricCredentialId: number }>(
    `
    MERGE sec.SupervisorBiometricCredential AS target
    USING (
      SELECT
        @supervisorUser AS SupervisorUserCode,
        @credentialHash AS CredentialHash
    ) AS source
      ON target.SupervisorUserCode = source.SupervisorUserCode
      AND target.CredentialHash = source.CredentialHash
    WHEN MATCHED THEN
      UPDATE SET
        CredentialId = @credentialId,
        CredentialLabel = @credentialLabel,
        DeviceInfo = @deviceInfo,
        IsActive = 1,
        UpdatedAtUtc = SYSUTCDATETIME(),
        UpdatedByUserCode = @actorUser
    WHEN NOT MATCHED THEN
      INSERT (
        SupervisorUserCode,
        CredentialHash,
        CredentialId,
        CredentialLabel,
        DeviceInfo,
        IsActive,
        LastValidatedAtUtc,
        CreatedAtUtc,
        UpdatedAtUtc,
        CreatedByUserCode,
        UpdatedByUserCode
      )
      VALUES (
        @supervisorUser,
        @credentialHash,
        @credentialId,
        @credentialLabel,
        @deviceInfo,
        1,
        NULL,
        SYSUTCDATETIME(),
        SYSUTCDATETIME(),
        @actorUser,
        @actorUser
      )
    OUTPUT inserted.BiometricCredentialId AS biometricCredentialId;
    `,
    {
      supervisorUser,
      credentialHash: hash,
      credentialId: normalizedCredentialId,
      credentialLabel,
      deviceInfo,
      actorUser,
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

  const rows = await query<BiometricCredentialRow>(
    `
    SELECT
      BiometricCredentialId AS biometricCredentialId,
      SupervisorUserCode AS supervisorUserCode,
      CredentialId AS credentialId,
      CredentialLabel AS credentialLabel,
      DeviceInfo AS deviceInfo,
      IsActive AS isActive,
      CONVERT(varchar(33), LastValidatedAtUtc, 127) AS lastValidatedAtUtc
    FROM sec.SupervisorBiometricCredential
    WHERE IsActive = 1
      AND (@supervisorUser = '' OR SupervisorUserCode = @supervisorUser)
    ORDER BY BiometricCredentialId DESC
    `,
    { supervisorUser }
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

  const rows = await query<{ biometricCredentialId: number }>(
    `
    UPDATE sec.SupervisorBiometricCredential
    SET
      IsActive = 0,
      UpdatedAtUtc = SYSUTCDATETIME(),
      UpdatedByUserCode = @actorUser
    OUTPUT inserted.BiometricCredentialId AS biometricCredentialId
    WHERE SupervisorUserCode = @supervisorUser
      AND CredentialHash = @credentialHash
      AND IsActive = 1
    `,
    {
      supervisorUser,
      credentialHash: credentialHash(normalizedCredentialId),
      actorUser,
    }
  );

  return rows[0]
    ? { ok: true as const, biometricCredentialId: Number(rows[0].biometricCredentialId) }
    : { ok: false as const, error: "biometric_credential_not_found" };
}
