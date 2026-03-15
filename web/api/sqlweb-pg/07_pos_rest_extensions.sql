-- ============================================================
-- DatqBoxWeb PostgreSQL - 07_pos_rest_extensions.sql
-- Tablas: pos."FiscalCorrelative", rest."DiningTable" + seeds
-- ============================================================

BEGIN;

-- ============================================================
-- pos.FiscalCorrelative
-- ============================================================
CREATE TABLE IF NOT EXISTS pos."FiscalCorrelative" (
  "FiscalCorrelativeId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"            INT         NOT NULL,
  "BranchId"             INT         NOT NULL,
  "CorrelativeType"      VARCHAR(20) NOT NULL DEFAULT 'FACTURA',
  "CashRegisterCode"     VARCHAR(10) NOT NULL DEFAULT 'GLOBAL',
  "SerialFiscal"         VARCHAR(40) NOT NULL,
  "CurrentNumber"        INT         NOT NULL DEFAULT 0,
  "Description"          VARCHAR(200) NULL,
  "IsActive"             BOOLEAN     NOT NULL DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP   NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT         NULL,
  "UpdatedByUserId"      INT         NULL,
  "RowVer"               INT         NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_pos_FiscalCorrelative" UNIQUE ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode"),
  CONSTRAINT "FK_pos_FiscalCorrelative_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_pos_FiscalCorrelative_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_pos_FiscalCorrelative_Search"
  ON pos."FiscalCorrelative" ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode", "IsActive");

-- ============================================================
-- rest.DiningTable
-- ============================================================
CREATE TABLE IF NOT EXISTS rest."DiningTable" (
  "DiningTableId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT          NOT NULL,
  "BranchId"         INT          NOT NULL,
  "TableNumber"      VARCHAR(20)  NOT NULL,
  "TableName"        VARCHAR(100) NULL,
  "Capacity"         INT          NOT NULL DEFAULT 4,
  "EnvironmentCode"  VARCHAR(20)  NULL,
  "EnvironmentName"  VARCHAR(80)  NULL,
  "PositionX"        INT          NULL,
  "PositionY"        INT          NULL,
  "IsActive"         BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"  INT          NULL,
  "UpdatedByUserId"  INT          NULL,
  "RowVer"           INT          NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_rest_DiningTable" UNIQUE ("CompanyId", "BranchId", "TableNumber"),
  CONSTRAINT "FK_rest_DiningTable_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_rest_DiningTable_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId"),
  CONSTRAINT "FK_rest_DiningTable_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_rest_DiningTable_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_rest_DiningTable_Search"
  ON rest."DiningTable" ("CompanyId", "BranchId", "IsActive", "EnvironmentCode", "TableNumber");

-- ============================================================
-- SEEDS
-- ============================================================
DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
  v_SystemUserId     INT;
  v_n                INT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch"
    WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;
  SELECT "UserId" INTO v_SystemUserId
    FROM sec."User" WHERE "UserCode" = 'SYSTEM' LIMIT 1;

  IF v_DefaultCompanyId IS NOT NULL AND v_DefaultBranchId IS NOT NULL THEN

    -- Seed: FiscalCorrelative
    INSERT INTO pos."FiscalCorrelative" (
      "CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode",
      "SerialFiscal", "CurrentNumber", "Description", "IsActive",
      "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
      v_DefaultCompanyId, v_DefaultBranchId, 'FACTURA', 'GLOBAL',
      'SERIAL-DEMO', 0, 'Correlativo fiscal global por defecto', TRUE,
      v_SystemUserId, v_SystemUserId
    )
    ON CONFLICT ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode") DO NOTHING;

    -- Seed: 20 mesas de restaurante (recursive CTE)
    IF NOT EXISTS (
      SELECT 1 FROM rest."DiningTable"
      WHERE "CompanyId" = v_DefaultCompanyId AND "BranchId" = v_DefaultBranchId
    ) THEN
      WITH RECURSIVE n_series AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1 FROM n_series WHERE n < 20
      )
      INSERT INTO rest."DiningTable" (
        "CompanyId", "BranchId", "TableNumber", "TableName",
        "Capacity", "EnvironmentCode", "EnvironmentName",
        "PositionX", "PositionY", "IsActive",
        "CreatedByUserId", "UpdatedByUserId"
      )
      SELECT
        v_DefaultCompanyId,
        v_DefaultBranchId,
        n::TEXT,
        'Mesa ' || n::TEXT,
        4,
        'SALON',
        'Salon Principal',
        ((n - 1) % 5) * 120,
        ((n - 1) / 5) * 120,
        TRUE,
        v_SystemUserId,
        v_SystemUserId
      FROM n_series;
    END IF;

  END IF;
END $$;

COMMIT;
