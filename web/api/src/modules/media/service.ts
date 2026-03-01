import path from "node:path";
import { query, execute } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";

type MediaScope = {
  companyId: number;
  branchId: number;
};

let scopeCache: MediaScope | null = null;

const PUBLIC_MEDIA_PREFIX = "/media-files/";

export function normalizeEntityType(value: string) {
  return String(value ?? "")
    .trim()
    .toUpperCase()
    .replace(/\s+/g, "_");
}

export function toPublicStorageKey(storageKey: string) {
  return storageKey.replace(/\\/g, "/").replace(/^\/+/, "");
}

export function buildPublicUrl(storageKey: string, publicBaseUrl?: string | null) {
  const normalizedKey = toPublicStorageKey(storageKey);
  const relative = `${PUBLIC_MEDIA_PREFIX}${normalizedKey}`;
  const base = String(publicBaseUrl ?? "").trim().replace(/\/+$/, "");
  if (!base) return relative;
  return `${base}${relative}`;
}

export function parseStorageKeyFromUrl(url: string) {
  const value = String(url ?? "").trim();
  const idx = value.indexOf(PUBLIC_MEDIA_PREFIX);
  if (idx < 0) return null;
  return toPublicStorageKey(value.slice(idx + PUBLIC_MEDIA_PREFIX.length));
}

export async function getMediaScope(): Promise<MediaScope> {
  const activeScope = getActiveScope();
  if (scopeCache && activeScope) {
    return {
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  if (scopeCache) return scopeCache;

  const rows = await query<{ companyId: number; branchId: number }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
      ON b.CompanyId = c.CompanyId
     AND b.BranchCode = N'MAIN'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId
    `
  );

  const row = rows[0];
  scopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
  };

  if (activeScope) {
    return {
      companyId: activeScope.companyId,
      branchId: activeScope.branchId,
    };
  }
  return scopeCache;
}

export async function resolveUserIdByCode(userCode?: string | null) {
  const code = String(userCode ?? "").trim();
  if (!code) return null;

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@code)
      AND IsDeleted = 0
      AND IsActive = 1
    ORDER BY UserId
    `,
    { code }
  );

  const value = Number(rows[0]?.userId ?? 0);
  return Number.isFinite(value) && value > 0 ? value : null;
}

export async function createMediaAsset(params: {
  companyId: number;
  branchId: number;
  storageKey: string;
  publicUrl: string;
  mimeType: string;
  originalFileName?: string | null;
  fileExtension?: string | null;
  fileSizeBytes: number;
  checksumSha256?: string | null;
  altText?: string | null;
  actorUserId?: number | null;
}) {
  const inserted = await query<{ mediaAssetId: number }>(
    `
    INSERT INTO cfg.MediaAsset (
      CompanyId,
      BranchId,
      StorageProvider,
      StorageKey,
      PublicUrl,
      OriginalFileName,
      MimeType,
      FileExtension,
      FileSizeBytes,
      ChecksumSha256,
      AltText,
      CreatedByUserId,
      UpdatedByUserId
    )
    OUTPUT INSERTED.MediaAssetId AS mediaAssetId
    VALUES (
      @companyId,
      @branchId,
      N'LOCAL',
      @storageKey,
      @publicUrl,
      @originalFileName,
      @mimeType,
      @fileExtension,
      @fileSizeBytes,
      @checksumSha256,
      @altText,
      @actorUserId,
      @actorUserId
    )
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      storageKey: toPublicStorageKey(params.storageKey),
      publicUrl: params.publicUrl,
      originalFileName: params.originalFileName ?? null,
      mimeType: params.mimeType,
      fileExtension: params.fileExtension ?? null,
      fileSizeBytes: Number(params.fileSizeBytes ?? 0),
      checksumSha256: params.checksumSha256 ?? null,
      altText: params.altText ?? null,
      actorUserId: params.actorUserId ?? null,
    }
  );

  return Number(inserted[0]?.mediaAssetId ?? 0);
}

export async function getMediaAssetById(scope: MediaScope, mediaAssetId: number) {
  const rows = await query<any>(
    `
    SELECT TOP 1
      MediaAssetId AS mediaAssetId,
      StorageKey AS storageKey,
      PublicUrl AS publicUrl,
      MimeType AS mimeType,
      OriginalFileName AS originalFileName,
      FileSizeBytes AS fileSizeBytes,
      IsActive AS isActive,
      IsDeleted AS isDeleted
    FROM cfg.MediaAsset
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND MediaAssetId = @mediaAssetId
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      mediaAssetId,
    }
  );

  return rows[0] ?? null;
}

export async function linkMediaToEntity(params: {
  companyId: number;
  branchId: number;
  entityType: string;
  entityId: number;
  mediaAssetId: number;
  roleCode?: string | null;
  sortOrder?: number;
  isPrimary?: boolean;
  actorUserId?: number | null;
}) {
  const entityType = normalizeEntityType(params.entityType);
  const sortOrder = Number(params.sortOrder ?? 0);
  const actorUserId = params.actorUserId ?? null;
  const isPrimary = Boolean(params.isPrimary ?? false);

  if (isPrimary) {
    await query(
      `
      UPDATE cfg.EntityImage
      SET
        IsPrimary = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @actorUserId
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND EntityType = @entityType
        AND EntityId = @entityId
        AND IsDeleted = 0
        AND IsActive = 1
      `,
      {
        companyId: params.companyId,
        branchId: params.branchId,
        entityType,
        entityId: params.entityId,
        actorUserId,
      }
    );
  }

  await query(
    `
    IF EXISTS (
      SELECT 1
      FROM cfg.EntityImage
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND EntityType = @entityType
        AND EntityId = @entityId
        AND MediaAssetId = @mediaAssetId
    )
    BEGIN
      UPDATE cfg.EntityImage
      SET
        RoleCode = @roleCode,
        SortOrder = @sortOrder,
        IsPrimary = CASE WHEN @isPrimary = 1 THEN 1 ELSE IsPrimary END,
        IsActive = 1,
        IsDeleted = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @actorUserId
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND EntityType = @entityType
        AND EntityId = @entityId
        AND MediaAssetId = @mediaAssetId;
    END
    ELSE
    BEGIN
      INSERT INTO cfg.EntityImage (
        CompanyId,
        BranchId,
        EntityType,
        EntityId,
        MediaAssetId,
        RoleCode,
        SortOrder,
        IsPrimary,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @companyId,
        @branchId,
        @entityType,
        @entityId,
        @mediaAssetId,
        @roleCode,
        @sortOrder,
        @isPrimary,
        @actorUserId,
        @actorUserId
      );
    END
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
      mediaAssetId: params.mediaAssetId,
      roleCode: params.roleCode ?? null,
      sortOrder,
      isPrimary: isPrimary ? 1 : 0,
      actorUserId,
    }
  );

  const rows = await query<any>(
    `
    SELECT TOP 1
      ei.EntityImageId AS entityImageId,
      ei.EntityType AS entityType,
      ei.EntityId AS entityId,
      ei.MediaAssetId AS mediaAssetId,
      ei.RoleCode AS roleCode,
      ei.SortOrder AS sortOrder,
      ei.IsPrimary AS isPrimary,
      ma.PublicUrl AS publicUrl,
      ma.MimeType AS mimeType
    FROM cfg.EntityImage ei
    INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
    WHERE ei.CompanyId = @companyId
      AND ei.BranchId = @branchId
      AND ei.EntityType = @entityType
      AND ei.EntityId = @entityId
      AND ei.MediaAssetId = @mediaAssetId
      AND ei.IsDeleted = 0
      AND ei.IsActive = 1
      AND ma.IsDeleted = 0
      AND ma.IsActive = 1
    ORDER BY ei.EntityImageId DESC
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
      mediaAssetId: params.mediaAssetId,
    }
  );

  return rows[0] ?? null;
}

export async function listEntityImages(scope: MediaScope, entityType: string, entityId: number) {
  const normalizedType = normalizeEntityType(entityType);
  const rows = await query<any>(
    `
    SELECT
      ei.EntityImageId AS entityImageId,
      ei.EntityType AS entityType,
      ei.EntityId AS entityId,
      ei.MediaAssetId AS mediaAssetId,
      ei.RoleCode AS roleCode,
      ei.SortOrder AS sortOrder,
      ei.IsPrimary AS isPrimary,
      ma.PublicUrl AS publicUrl,
      ma.OriginalFileName AS originalFileName,
      ma.MimeType AS mimeType,
      ma.FileSizeBytes AS fileSizeBytes,
      ma.AltText AS altText,
      ma.CreatedAt AS createdAt
    FROM cfg.EntityImage ei
    INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
    WHERE ei.CompanyId = @companyId
      AND ei.BranchId = @branchId
      AND ei.EntityType = @entityType
      AND ei.EntityId = @entityId
      AND ei.IsDeleted = 0
      AND ei.IsActive = 1
      AND ma.IsDeleted = 0
      AND ma.IsActive = 1
    ORDER BY
      CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END,
      ei.SortOrder,
      ei.EntityImageId
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      entityType: normalizedType,
      entityId,
    }
  );

  return { rows };
}

export async function setPrimaryEntityImage(params: {
  companyId: number;
  branchId: number;
  entityType: string;
  entityId: number;
  entityImageId: number;
  actorUserId?: number | null;
}) {
  const entityType = normalizeEntityType(params.entityType);
  const actorUserId = params.actorUserId ?? null;

  await query(
    `
    UPDATE cfg.EntityImage
    SET
      IsPrimary = 0,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @actorUserId
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND EntityType = @entityType
      AND EntityId = @entityId
      AND IsDeleted = 0
      AND IsActive = 1
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
      actorUserId,
    }
  );

  const updated = await execute(
    `
    UPDATE cfg.EntityImage
    SET
      IsPrimary = 1,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @actorUserId
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND EntityType = @entityType
      AND EntityId = @entityId
      AND EntityImageId = @entityImageId
      AND IsDeleted = 0
      AND IsActive = 1
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
      entityImageId: params.entityImageId,
      actorUserId,
    }
  );

  const affected = Number(updated.rowsAffected?.[0] ?? 0);
  return affected > 0;
}

export async function unlinkEntityImage(params: {
  companyId: number;
  branchId: number;
  entityType: string;
  entityId: number;
  entityImageId: number;
  actorUserId?: number | null;
}) {
  const entityType = normalizeEntityType(params.entityType);
  const actorUserId = params.actorUserId ?? null;

  await execute(
    `
    UPDATE cfg.EntityImage
    SET
      IsActive = 0,
      IsDeleted = 1,
      IsPrimary = 0,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @actorUserId
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND EntityType = @entityType
      AND EntityId = @entityId
      AND EntityImageId = @entityImageId
      AND IsDeleted = 0
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
      entityImageId: params.entityImageId,
      actorUserId,
    }
  );

  const hasPrimary = await query<{ hasPrimary: number }>(
    `
    SELECT TOP 1 1 AS hasPrimary
    FROM cfg.EntityImage
    WHERE CompanyId = @companyId
      AND BranchId = @branchId
      AND EntityType = @entityType
      AND EntityId = @entityId
      AND IsDeleted = 0
      AND IsActive = 1
      AND IsPrimary = 1
    `,
    {
      companyId: params.companyId,
      branchId: params.branchId,
      entityType,
      entityId: params.entityId,
    }
  );

  if (!hasPrimary[0]) {
    await query(
      `
      ;WITH FirstImage AS (
        SELECT TOP 1 EntityImageId
        FROM cfg.EntityImage
        WHERE CompanyId = @companyId
          AND BranchId = @branchId
          AND EntityType = @entityType
          AND EntityId = @entityId
          AND IsDeleted = 0
          AND IsActive = 1
        ORDER BY SortOrder, EntityImageId
      )
      UPDATE ei
      SET
        IsPrimary = 1,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @actorUserId
      FROM cfg.EntityImage ei
      INNER JOIN FirstImage f ON f.EntityImageId = ei.EntityImageId
      `,
      {
        companyId: params.companyId,
        branchId: params.branchId,
        entityType,
        entityId: params.entityId,
        actorUserId,
      }
    );
  }

  return { ok: true };
}

export function getEntityTypeFromPathEntity(entity: string) {
  const normalized = normalizeEntityType(entity);
  if (normalized === "MASTER_PRODUCT" || normalized === "PRODUCT" || normalized === "INVENTARIO") {
    return "MASTER_PRODUCT";
  }
  if (normalized === "REST_MENU_PRODUCT" || normalized === "MENU_PRODUCT" || normalized === "PLATO") {
    return "REST_MENU_PRODUCT";
  }
  if (normalized === "REST_MENU_RECIPE" || normalized === "RECIPE" || normalized === "RECETA") {
    return "REST_MENU_RECIPE";
  }
  return normalized;
}

export function getFileExtension(filename: string) {
  const ext = path.extname(filename || "").trim().toLowerCase();
  return ext.slice(0, 20);
}

