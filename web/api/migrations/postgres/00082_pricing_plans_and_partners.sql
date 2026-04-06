-- +goose Up
-- F7: Pricing Engine por vertical + F8: Partner Portal

-- ══════════════════════════════════════════════════════════════════════════════
-- F7: Pricing Plans
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS cfg."PricingPlan" (
    "PricingPlanId"          SERIAL        PRIMARY KEY,
    "Name"                   VARCHAR(120)  NOT NULL,
    "Slug"                   VARCHAR(80)   NOT NULL,
    "VerticalType"           VARCHAR(30)   NOT NULL DEFAULT 'erp'::VARCHAR,
    "MonthlyPrice"           NUMERIC(12,2) NOT NULL DEFAULT 0,
    "AnnualPrice"            NUMERIC(12,2) NOT NULL DEFAULT 0,
    "TransactionFeePercent"  NUMERIC(5,2)  NOT NULL DEFAULT 0,
    "MaxUsers"               INTEGER       NOT NULL DEFAULT 0,
    "MaxTransactions"        INTEGER       NOT NULL DEFAULT 0,
    "Features"               JSONB         NOT NULL DEFAULT '[]'::JSONB,
    "IsActive"               BOOLEAN       NOT NULL DEFAULT TRUE,
    "CompanyId"              INTEGER       NOT NULL DEFAULT 0,
    "CreatedAt"              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_pricing_vertical CHECK ("VerticalType" IN ('erp','medical','tickets','hotel','education'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_pricing_plan_slug ON cfg."PricingPlan" ("Slug");
CREATE INDEX IF NOT EXISTS idx_pricing_plan_vertical ON cfg."PricingPlan" ("VerticalType", "IsActive");

-- ── SP: usp_cfg_pricing_plan_list ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_pricing_plan_list(
    p_vertical_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "PricingPlanId"          INTEGER,
    "Name"                   VARCHAR,
    "Slug"                   VARCHAR,
    "VerticalType"           VARCHAR,
    "MonthlyPrice"           NUMERIC,
    "AnnualPrice"            NUMERIC,
    "TransactionFeePercent"  NUMERIC,
    "MaxUsers"               INTEGER,
    "MaxTransactions"        INTEGER,
    "Features"               JSONB,
    "IsActive"               BOOLEAN,
    "CompanyId"              INTEGER,
    "CreatedAt"              TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pp."PricingPlanId",
        pp."Name"::VARCHAR,
        pp."Slug"::VARCHAR,
        pp."VerticalType"::VARCHAR,
        pp."MonthlyPrice",
        pp."AnnualPrice",
        pp."TransactionFeePercent",
        pp."MaxUsers",
        pp."MaxTransactions",
        pp."Features",
        pp."IsActive",
        pp."CompanyId",
        pp."CreatedAt"
    FROM cfg."PricingPlan" pp
    WHERE pp."IsActive" = TRUE
      AND (p_vertical_type IS NULL OR pp."VerticalType" = p_vertical_type)
    ORDER BY pp."MonthlyPrice" ASC;
END;
$$;

-- ── SP: usp_cfg_pricing_plan_get ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_pricing_plan_get(
    p_slug VARCHAR
)
RETURNS TABLE(
    "PricingPlanId"          INTEGER,
    "Name"                   VARCHAR,
    "Slug"                   VARCHAR,
    "VerticalType"           VARCHAR,
    "MonthlyPrice"           NUMERIC,
    "AnnualPrice"            NUMERIC,
    "TransactionFeePercent"  NUMERIC,
    "MaxUsers"               INTEGER,
    "MaxTransactions"        INTEGER,
    "Features"               JSONB,
    "IsActive"               BOOLEAN,
    "CompanyId"              INTEGER,
    "CreatedAt"              TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pp."PricingPlanId",
        pp."Name"::VARCHAR,
        pp."Slug"::VARCHAR,
        pp."VerticalType"::VARCHAR,
        pp."MonthlyPrice",
        pp."AnnualPrice",
        pp."TransactionFeePercent",
        pp."MaxUsers",
        pp."MaxTransactions",
        pp."Features",
        pp."IsActive",
        pp."CompanyId",
        pp."CreatedAt"
    FROM cfg."PricingPlan" pp
    WHERE pp."Slug" = p_slug
      AND pp."IsActive" = TRUE;
END;
$$;

-- ── Seed: planes default ──────────────────────────────────────────────────────
INSERT INTO cfg."PricingPlan" ("Name", "Slug", "VerticalType", "MonthlyPrice", "AnnualPrice", "TransactionFeePercent", "MaxUsers", "MaxTransactions", "Features")
VALUES
  ('Starter',     'erp-starter',     'erp',       29.00,  290.00, 0.50,  5,   1000, '["Facturacion","Inventario","Clientes","Reportes basicos"]'::JSONB),
  ('Professional','erp-professional','erp',       79.00,  790.00, 0.30, 15,   5000, '["Todo en Starter","Contabilidad","Nomina","CRM","Multi-sucursal"]'::JSONB),
  ('Enterprise',  'erp-enterprise',  'erp',      199.00, 1990.00, 0.10, 50,  50000, '["Todo en Professional","API ilimitada","Soporte prioritario","White-label","Multi-tenant"]'::JSONB),
  ('Clinica',     'medical-clinic',  'medical',   49.00,  490.00, 0.00, 10,   2000, '["Citas","Pacientes","Recetas","Historia clinica","Chat medico"]'::JSONB),
  ('Hospital',    'medical-hospital','medical',  149.00, 1490.00, 0.00, 50,  20000, '["Todo en Clinica","Multi-sede","Laboratorio","Facturacion medica","Reportes avanzados"]'::JSONB),
  ('Basico',      'tickets-basic',   'tickets',   19.00,  190.00, 1.00,  3,    500, '["Venta de tickets","QR","Dashboard basico"]'::JSONB),
  ('Pro',         'tickets-pro',     'tickets',   59.00,  590.00, 0.50, 10,   5000, '["Todo en Basico","Multi-evento","Reportes","API"]'::JSONB),
  ('Hotel Pyme',  'hotel-pyme',      'hotel',     39.00,  390.00, 0.00,  5,   1000, '["Reservas","Huespedes","Housekeeping","Check-in/out"]'::JSONB),
  ('Hotel Chain', 'hotel-chain',     'hotel',    129.00, 1290.00, 0.00, 30,  10000, '["Todo en Pyme","Multi-propiedad","Revenue management","Channel manager"]'::JSONB),
  ('Academia',    'edu-academy',     'education',  29.00, 290.00, 0.00,  5,   1000, '["Estudiantes","Cursos","Asistencia","Notas","Comunicados"]'::JSONB),
  ('Universidad', 'edu-university',  'education', 99.00,  990.00, 0.00, 30,  10000, '["Todo en Academia","Multi-sede","Inscripciones online","Reportes regulatorios"]'::JSONB)
ON CONFLICT DO NOTHING;

-- ══════════════════════════════════════════════════════════════════════════════
-- F8: Partner Portal
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS cfg."Partner" (
    "PartnerId"          SERIAL        PRIMARY KEY,
    "CompanyName"        VARCHAR(200)  NOT NULL,
    "ContactName"        VARCHAR(200)  NOT NULL,
    "Email"              VARCHAR(200)  NOT NULL,
    "Phone"              VARCHAR(50)   DEFAULT ''::VARCHAR,
    "Status"             VARCHAR(20)   NOT NULL DEFAULT 'pending'::VARCHAR,
    "CommissionPercent"  NUMERIC(5,2)  NOT NULL DEFAULT 10.00,
    "TotalReferrals"     INTEGER       NOT NULL DEFAULT 0,
    "TotalRevenue"       NUMERIC(14,2) NOT NULL DEFAULT 0,
    "ApiKey"             VARCHAR(120)  DEFAULT ''::VARCHAR,
    "CompanyId"          INTEGER       NOT NULL DEFAULT 0,
    "CreatedAt"          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_partner_status CHECK ("Status" IN ('pending','approved','active','suspended'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_partner_email ON cfg."Partner" ("Email");
CREATE INDEX IF NOT EXISTS idx_partner_status ON cfg."Partner" ("Status");

CREATE TABLE IF NOT EXISTS cfg."PartnerReferral" (
    "PartnerReferralId"  SERIAL        PRIMARY KEY,
    "PartnerId"          INTEGER       NOT NULL REFERENCES cfg."Partner"("PartnerId"),
    "ReferredCompanyId"  INTEGER       NOT NULL DEFAULT 0,
    "Status"             VARCHAR(20)   NOT NULL DEFAULT 'pending'::VARCHAR,
    "CommissionAmount"   NUMERIC(12,2) NOT NULL DEFAULT 0,
    "PaidAt"             TIMESTAMPTZ,
    "CreatedAt"          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_referral_status CHECK ("Status" IN ('pending','converted','cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_referral_partner ON cfg."PartnerReferral" ("PartnerId");

-- ── SP: usp_cfg_partner_apply ─────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_partner_apply(
    p_company_name VARCHAR,
    p_contact_name VARCHAR,
    p_email        VARCHAR,
    p_phone        VARCHAR DEFAULT ''
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM cfg."Partner" WHERE "Email" = p_email;
    IF v_exists > 0 THEN
        RETURN QUERY SELECT FALSE, 'Ya existe una solicitud con ese email'::VARCHAR;
        RETURN;
    END IF;

    INSERT INTO cfg."Partner" ("CompanyName", "ContactName", "Email", "Phone", "ApiKey")
    VALUES (p_company_name, p_contact_name, p_email, COALESCE(p_phone, ''),
            encode(gen_random_bytes(32), 'hex'));

    RETURN QUERY SELECT TRUE, 'Solicitud enviada correctamente'::VARCHAR;
END;
$$;

-- ── SP: usp_cfg_partner_get_by_email ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_partner_get_by_email(
    p_email VARCHAR
)
RETURNS TABLE(
    "PartnerId"          INTEGER,
    "CompanyName"        VARCHAR,
    "ContactName"        VARCHAR,
    "Email"              VARCHAR,
    "Phone"              VARCHAR,
    "Status"             VARCHAR,
    "CommissionPercent"  NUMERIC,
    "TotalReferrals"     INTEGER,
    "TotalRevenue"       NUMERIC,
    "ApiKey"             VARCHAR,
    "CompanyId"          INTEGER,
    "CreatedAt"          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."PartnerId",
        p."CompanyName"::VARCHAR,
        p."ContactName"::VARCHAR,
        p."Email"::VARCHAR,
        p."Phone"::VARCHAR,
        p."Status"::VARCHAR,
        p."CommissionPercent",
        p."TotalReferrals",
        p."TotalRevenue",
        p."ApiKey"::VARCHAR,
        p."CompanyId",
        p."CreatedAt"
    FROM cfg."Partner" p
    WHERE p."Email" = p_email;
END;
$$;

-- ── SP: usp_cfg_partner_referrals_list ────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_partner_referrals_list(
    p_partner_id INTEGER
)
RETURNS TABLE(
    "PartnerReferralId"  INTEGER,
    "PartnerId"          INTEGER,
    "ReferredCompanyId"  INTEGER,
    "Status"             VARCHAR,
    "CommissionAmount"   NUMERIC,
    "PaidAt"             TIMESTAMPTZ,
    "CreatedAt"          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."PartnerReferralId",
        r."PartnerId",
        r."ReferredCompanyId",
        r."Status"::VARCHAR,
        r."CommissionAmount",
        r."PaidAt",
        r."CreatedAt"
    FROM cfg."PartnerReferral" r
    WHERE r."PartnerId" = p_partner_id
    ORDER BY r."CreatedAt" DESC;
END;
$$;

-- ── SP: usp_cfg_partner_dashboard ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_cfg_partner_dashboard(
    p_partner_id INTEGER
)
RETURNS TABLE(
    "TotalReferrals"     BIGINT,
    "ConvertedReferrals" BIGINT,
    "PendingReferrals"   BIGINT,
    "TotalCommission"    NUMERIC,
    "PaidCommission"     NUMERIC,
    "PendingCommission"  NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT                                                          AS "TotalReferrals",
        COUNT(*) FILTER (WHERE r."Status" = 'converted')::BIGINT                 AS "ConvertedReferrals",
        COUNT(*) FILTER (WHERE r."Status" = 'pending')::BIGINT                   AS "PendingReferrals",
        COALESCE(SUM(r."CommissionAmount"), 0)::NUMERIC                           AS "TotalCommission",
        COALESCE(SUM(r."CommissionAmount") FILTER (WHERE r."PaidAt" IS NOT NULL), 0)::NUMERIC AS "PaidCommission",
        COALESCE(SUM(r."CommissionAmount") FILTER (WHERE r."PaidAt" IS NULL AND r."Status" = 'converted'), 0)::NUMERIC AS "PendingCommission"
    FROM cfg."PartnerReferral" r
    WHERE r."PartnerId" = p_partner_id;
END;
$$;

-- +goose Down
DROP FUNCTION IF EXISTS usp_cfg_partner_dashboard(INTEGER);
DROP FUNCTION IF EXISTS usp_cfg_partner_referrals_list(INTEGER);
DROP FUNCTION IF EXISTS usp_cfg_partner_get_by_email(VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_partner_apply(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP TABLE IF EXISTS cfg."PartnerReferral";
DROP TABLE IF EXISTS cfg."Partner";
DROP FUNCTION IF EXISTS usp_cfg_pricing_plan_get(VARCHAR);
DROP FUNCTION IF EXISTS usp_cfg_pricing_plan_list(VARCHAR);
DROP TABLE IF EXISTS cfg."PricingPlan";
