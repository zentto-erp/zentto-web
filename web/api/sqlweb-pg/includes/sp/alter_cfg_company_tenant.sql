-- ============================================================
-- Multi-tenant: agregar columnas de suscripción a cfg.Company
-- Idempotente: usa ADD COLUMN IF NOT EXISTS
-- ============================================================
ALTER TABLE cfg."Company"
  ADD COLUMN IF NOT EXISTS "Plan"                   VARCHAR(30)  NOT NULL DEFAULT 'FREE',
  ADD COLUMN IF NOT EXISTS "TenantStatus"           VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS "OwnerEmail"             VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "ProvisionedAt"          TIMESTAMP    NULL,
  ADD COLUMN IF NOT EXISTS "PaddleSubscriptionId"   VARCHAR(100) NULL,
  ADD COLUMN IF NOT EXISTS "TenantSubdomain"       VARCHAR(63)  NULL;

CREATE INDEX IF NOT EXISTS "IX_cfg_Company_OwnerEmail"
  ON cfg."Company"("OwnerEmail") WHERE "OwnerEmail" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "IX_cfg_Company_TenantStatus"
  ON cfg."Company"("TenantStatus");
