import path from "node:path";
import { callSp, callSpOut, sql } from "../../db/query.js";
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

  const rows = await callSp<{ companyId: number; branchId: number }>(
    "usp_Cfg_Scope_GetDefault"
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

  const rows = await callSp<{ userId: number }>(
    "usp_Sec_User_ResolveByCodeActive",
    { Code: code }
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
  const inserted = await callSp<{ mediaAssetId: number }>(
    "usp_Cfg_MediaAsset_Insert",
    {
      CompanyId: params.companyId,
      BranchId: params.branchId,
      StorageKey: toPublicStorageKey(params.storageKey),
      PublicUrl: params.publicUrl,
      OriginalFileName: params.originalFileName ?? null,
      MimeType: params.mimeType,
      FileExtension: params.fileExtension ?? null,
      FileSizeBytes: Number(params.fileSizeBytes ?? 0),
      ChecksumSha256: params.checksumSha256 ?? null,
      AltText: params.altText ?? null,
      ActorUserId: params.actorUserId ?? null,
    }
  );

  return Number(inserted[0]?.mediaAssetId ?? 0);
}

export async function getMediaAssetById(scope: MediaScope, mediaAssetId: number) {
  const rows = await callSp<any>(
    "usp_Cfg_MediaAsset_GetById",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      MediaAssetId: mediaAssetId,
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

  const rows = await callSp<any>(
    "usp_Cfg_EntityImage_Link",
    {
      CompanyId: params.companyId,
      BranchId: params.branchId,
      EntityType: entityType,
      EntityId: params.entityId,
      MediaAssetId: params.mediaAssetId,
      RoleCode: params.roleCode ?? null,
      SortOrder: Number(params.sortOrder ?? 0),
      IsPrimary: Boolean(params.isPrimary ?? false) ? 1 : 0,
      ActorUserId: params.actorUserId ?? null,
    }
  );

  return rows[0] ?? null;
}

export async function listEntityImages(scope: MediaScope, entityType: string, entityId: number) {
  const normalizedType = normalizeEntityType(entityType);
  const rows = await callSp<any>(
    "usp_Cfg_EntityImage_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      EntityType: normalizedType,
      EntityId: entityId,
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

  const rows = await callSp<{ affected: number }>(
    "usp_Cfg_EntityImage_SetPrimary",
    {
      CompanyId: params.companyId,
      BranchId: params.branchId,
      EntityType: entityType,
      EntityId: params.entityId,
      EntityImageId: params.entityImageId,
      ActorUserId: params.actorUserId ?? null,
    }
  );

  const affected = Number(rows[0]?.affected ?? 0);
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

  await callSp(
    "usp_Cfg_EntityImage_Unlink",
    {
      CompanyId: params.companyId,
      BranchId: params.branchId,
      EntityType: entityType,
      EntityId: params.entityId,
      EntityImageId: params.entityImageId,
      ActorUserId: params.actorUserId ?? null,
    }
  );

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
