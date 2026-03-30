import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Router } from "express";
import multer from "multer";
import { z } from "zod";
import { env } from "../../config/env.js";
import { callSp } from "../../db/query.js";
import type { AuthenticatedRequest } from "../../middleware/auth.js";
import {
  entityIdSchema,
  entityTypeSchema,
  linkImageBodySchema,
  listEntityImagesSchema,
  setPrimarySchema,
  uploadBodySchema,
} from "./types.js";
import {
  buildPublicUrl,
  createMediaAsset,
  getEntityTypeFromPathEntity,
  getFileExtension,
  getMediaAssetById,
  getMediaScope,
  linkMediaToEntity,
  listEntityImages,
  parseStorageKeyFromUrl,
  resolveUserIdByCode,
  setPrimaryEntityImage,
  toPublicStorageKey,
  unlinkEntityImage,
} from "./service.js";

const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/svg+xml",
]);

const MAX_FILE_SIZE_BYTES = Math.max(1, Number(env.media.maxFileSizeMb || 5)) * 1024 * 1024;

function buildStorageFolder(companyId: number, branchId: number) {
  const now = new Date();
  const yyyy = String(now.getUTCFullYear());
  const mm = String(now.getUTCMonth() + 1).padStart(2, "0");
  return path.join(env.media.storagePath, `c${companyId}`, `b${branchId}`, yyyy, mm);
}

const storage = multer.diskStorage({
  destination(req, _file, cb) {
    getMediaScope()
      .then((scope) => {
        const folder = buildStorageFolder(scope.companyId, scope.branchId);
        fs.mkdirSync(folder, { recursive: true });
        cb(null, folder);
      })
      .catch((err) => cb(err as Error, env.media.storagePath));
  },
  filename(_req, file, cb) {
    const ext = getFileExtension(file.originalname) || ".bin";
    const id = crypto.randomUUID().replace(/-/g, "");
    cb(null, `${id}${ext}`);
  },
});

const uploader = multer({
  storage,
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
    files: 1,
  },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_MIME_TYPES.has(String(file.mimetype || "").toLowerCase())) {
      return cb(new Error("tipo_de_archivo_no_permitido"));
    }
    return cb(null, true);
  },
});

export const mediaRouter = Router();

mediaRouter.get("/entities/:entityType/:entityId/images", async (req, res) => {
  try {
    const parsed = listEntityImagesSchema.safeParse({
      entityType: req.params.entityType,
      entityId: req.params.entityId,
    });
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_params", issues: parsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const entityType = getEntityTypeFromPathEntity(parsed.data.entityType);
    const data = await listEntityImages(scope, entityType, parsed.data.entityId);
    return res.json({
      entityType,
      entityId: parsed.data.entityId,
      ...data,
    });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

mediaRouter.post("/upload", uploader.single("file"), async (req, res) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: "missing_file", message: "Debes enviar el archivo en el campo 'file'" });
    }

    const bodyParsed = uploadBodySchema.safeParse(req.body ?? {});
    if (!bodyParsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: bodyParsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const actorUserId = await resolveUserIdByCode((req as AuthenticatedRequest).user?.sub);
    const storageKeyRaw = path.relative(env.media.storagePath, file.path);
    const storageKey = toPublicStorageKey(storageKeyRaw);
    const publicUrl = buildPublicUrl(storageKey, env.media.publicBaseUrl);
    const fileContent = await fs.promises.readFile(file.path);
    const checksum = crypto.createHash("sha256").update(fileContent).digest("hex");
    const extension = getFileExtension(file.originalname);

    const mediaAssetId = await createMediaAsset({
      companyId: scope.companyId,
      branchId: scope.branchId,
      storageKey,
      publicUrl,
      mimeType: file.mimetype || "application/octet-stream",
      originalFileName: file.originalname,
      fileExtension: extension,
      fileSizeBytes: file.size,
      checksumSha256: checksum,
      altText: bodyParsed.data.altText ?? null,
      actorUserId,
    });

    let linked: any = null;
    if (bodyParsed.data.entityType && bodyParsed.data.entityId) {
      const entityType = getEntityTypeFromPathEntity(bodyParsed.data.entityType);
      linked = await linkMediaToEntity({
        companyId: scope.companyId,
        branchId: scope.branchId,
        entityType,
        entityId: bodyParsed.data.entityId,
        mediaAssetId,
        roleCode: bodyParsed.data.roleCode ?? null,
        sortOrder: bodyParsed.data.sortOrder ?? 0,
        isPrimary: bodyParsed.data.isPrimary ?? true,
        actorUserId,
      });
    }

    return res.status(201).json({
      ok: true,
      mediaAssetId,
      storageKey,
      publicUrl,
      mimeType: file.mimetype,
      fileSizeBytes: file.size,
      linked,
    });
  } catch (error: any) {
    return res.status(400).json({
      error: "upload_failed",
      message: String(error?.message ?? error),
    });
  }
});

mediaRouter.post("/entities/:entityType/:entityId/images", async (req, res) => {
  try {
    const paramsParsed = z
      .object({
        entityType: entityTypeSchema,
        entityId: entityIdSchema,
      })
      .safeParse(req.params);
    if (!paramsParsed.success) {
      return res.status(400).json({ error: "invalid_params", issues: paramsParsed.error.flatten() });
    }

    const bodyParsed = linkImageBodySchema.safeParse(req.body ?? {});
    if (!bodyParsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: bodyParsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const actorUserId = await resolveUserIdByCode((req as AuthenticatedRequest).user?.sub);
    const entityType = getEntityTypeFromPathEntity(paramsParsed.data.entityType);

    const media = await getMediaAssetById(scope, bodyParsed.data.mediaAssetId);
    if (!media || media.isDeleted || !media.isActive) {
      return res.status(404).json({ error: "media_not_found" });
    }

    const linked = await linkMediaToEntity({
      companyId: scope.companyId,
      branchId: scope.branchId,
      entityType,
      entityId: paramsParsed.data.entityId,
      mediaAssetId: bodyParsed.data.mediaAssetId,
      roleCode: bodyParsed.data.roleCode ?? null,
      sortOrder: bodyParsed.data.sortOrder ?? 0,
      isPrimary: bodyParsed.data.isPrimary ?? true,
      actorUserId,
    });

    return res.status(201).json({ ok: true, linked });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

mediaRouter.put("/entities/:entityType/:entityId/images/:entityImageId/primary", async (req, res) => {
  try {
    const parsed = setPrimarySchema.safeParse({
      entityType: req.params.entityType,
      entityId: req.params.entityId,
      entityImageId: req.params.entityImageId,
    });
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_params", issues: parsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const actorUserId = await resolveUserIdByCode((req as AuthenticatedRequest).user?.sub);
    const entityType = getEntityTypeFromPathEntity(parsed.data.entityType);
    const ok = await setPrimaryEntityImage({
      companyId: scope.companyId,
      branchId: scope.branchId,
      entityType,
      entityId: parsed.data.entityId,
      entityImageId: parsed.data.entityImageId,
      actorUserId,
    });

    if (!ok) return res.status(404).json({ error: "entity_image_not_found" });
    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

mediaRouter.delete("/entities/:entityType/:entityId/images/:entityImageId", async (req, res) => {
  try {
    const parsed = setPrimarySchema.safeParse({
      entityType: req.params.entityType,
      entityId: req.params.entityId,
      entityImageId: req.params.entityImageId,
    });
    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_params", issues: parsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const actorUserId = await resolveUserIdByCode((req as AuthenticatedRequest).user?.sub);
    const entityType = getEntityTypeFromPathEntity(parsed.data.entityType);

    await unlinkEntityImage({
      companyId: scope.companyId,
      branchId: scope.branchId,
      entityType,
      entityId: parsed.data.entityId,
      entityImageId: parsed.data.entityImageId,
      actorUserId,
    });

    return res.json({ ok: true });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});

mediaRouter.post("/link-by-url", async (req, res) => {
  try {
    const parsed = z
      .object({
        entityType: entityTypeSchema,
        entityId: entityIdSchema,
        imageUrl: z.string().trim().min(1),
        roleCode: z.string().trim().max(30).optional(),
        sortOrder: z.coerce.number().int().min(0).max(9999).optional(),
        isPrimary: z.boolean().optional(),
      })
      .safeParse(req.body ?? {});

    if (!parsed.success) {
      return res.status(400).json({ error: "invalid_payload", issues: parsed.error.flatten() });
    }

    const scope = await getMediaScope();
    const actorUserId = await resolveUserIdByCode((req as AuthenticatedRequest).user?.sub);
    const storageKey = parseStorageKeyFromUrl(parsed.data.imageUrl);
    if (!storageKey) {
      return res.status(400).json({ error: "invalid_image_url", message: "La URL no pertenece al storage local de media" });
    }

    const mediaRows = await callSp<{ mediaAssetId: number }>(
      "usp_Cfg_MediaAsset_GetByStorageKey",
      {
        CompanyId: scope.companyId,
        BranchId: scope.branchId,
        StorageKey: storageKey,
      }
    );

    const mediaAssetId = Number(mediaRows[0]?.mediaAssetId ?? 0);
    if (!Number.isFinite(mediaAssetId) || mediaAssetId <= 0) {
      return res.status(404).json({ error: "media_not_found" });
    }

    const linked = await linkMediaToEntity({
      companyId: scope.companyId,
      branchId: scope.branchId,
      entityType: getEntityTypeFromPathEntity(parsed.data.entityType),
      entityId: parsed.data.entityId,
      mediaAssetId,
      roleCode: parsed.data.roleCode ?? null,
      sortOrder: parsed.data.sortOrder ?? 0,
      isPrimary: parsed.data.isPrimary ?? true,
      actorUserId,
    });

    return res.status(201).json({ ok: true, linked });
  } catch (err: any) {
    return res.status(500).json({ error: String(err.message ?? err) });
  }
});
