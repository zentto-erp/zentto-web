import { z } from "zod";

export const entityTypeSchema = z
  .string()
  .trim()
  .min(2)
  .max(80)
  .regex(/^[A-Z0-9_]+$/i, "entityType invalido");

export const entityIdSchema = z.coerce.number().int().positive();

export const uploadBodySchema = z.object({
  entityType: entityTypeSchema.optional(),
  entityId: entityIdSchema.optional(),
  roleCode: z.string().trim().max(30).optional(),
  sortOrder: z.coerce.number().int().min(0).max(9999).optional(),
  isPrimary: z
    .union([z.boolean(), z.string().trim().toLowerCase()])
    .optional()
    .transform((value) => {
      if (typeof value === "boolean") return value;
      if (typeof value === "string") return value === "1" || value === "true" || value === "yes";
      return undefined;
    }),
  altText: z.string().trim().max(200).optional(),
});

export const listEntityImagesSchema = z.object({
  entityType: entityTypeSchema,
  entityId: entityIdSchema,
});

export const linkImageBodySchema = z.object({
  mediaAssetId: z.coerce.number().int().positive(),
  roleCode: z.string().trim().max(30).optional(),
  sortOrder: z.coerce.number().int().min(0).max(9999).optional(),
  isPrimary: z.boolean().optional(),
});

export const setPrimarySchema = z.object({
  entityType: entityTypeSchema,
  entityId: entityIdSchema,
  entityImageId: z.coerce.number().int().positive(),
});

