-- +goose Up
-- F5: Onboarding self-service — tabla para flujo de signup público

CREATE TABLE IF NOT EXISTS cfg."OnboardingFlow" (
    "Id"                SERIAL          PRIMARY KEY,
    "Email"             VARCHAR(255)    NOT NULL,
    "CompanyName"       VARCHAR(200)    NOT NULL,
    "Plan"              VARCHAR(30)     NOT NULL DEFAULT 'free_trial'
                        CHECK ("Plan" IN ('free_trial','basic','professional')),
    "Status"            VARCHAR(30)     NOT NULL DEFAULT 'pending_verification'
                        CHECK ("Status" IN ('pending_verification','verified','provisioning','active','failed')),
    "VerificationToken" VARCHAR(128)    NOT NULL,
    "VerifiedAt"        TIMESTAMPTZ,
    "ProvisionedAt"     TIMESTAMPTZ,
    "TenantSlug"        VARCHAR(60),
    "CompanyId"         INT,
    "ErrorMessage"      VARCHAR(500),
    "CreatedAt"         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAt"         TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_onboarding_token
    ON cfg."OnboardingFlow" ("VerificationToken");

CREATE INDEX IF NOT EXISTS idx_onboarding_email
    ON cfg."OnboardingFlow" ("Email");

-- SP: Crear registro de onboarding
CREATE OR REPLACE FUNCTION cfg.usp_Cfg_Onboarding_Create(
    p_email             VARCHAR,
    p_company_name      VARCHAR,
    p_plan              VARCHAR,
    p_verification_token VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "Id" INT)
LANGUAGE plpgsql AS $$
BEGIN
    -- Verificar si ya hay un onboarding activo para este email
    IF EXISTS (
        SELECT 1 FROM cfg."OnboardingFlow"
        WHERE "Email" = p_email
          AND "Status" NOT IN ('failed','active')
    ) THEN
        RETURN QUERY SELECT false, 'Ya existe un proceso de onboarding activo para este email'::VARCHAR, 0;
        RETURN;
    END IF;

    INSERT INTO cfg."OnboardingFlow" ("Email", "CompanyName", "Plan", "VerificationToken")
    VALUES (p_email, p_company_name, p_plan, p_verification_token)
    RETURNING true, 'OK'::VARCHAR, "OnboardingFlow"."Id"
    INTO ok, mensaje, "Id";

    RETURN NEXT;
END;
$$;

-- SP: Verificar token
CREATE OR REPLACE FUNCTION cfg.usp_Cfg_Onboarding_Verify(
    p_token VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "Id" INT, "Email" VARCHAR, "CompanyName" VARCHAR, "Plan" VARCHAR, "Status" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_row cfg."OnboardingFlow"%ROWTYPE;
BEGIN
    SELECT * INTO v_row
    FROM cfg."OnboardingFlow"
    WHERE "VerificationToken" = p_token;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Token no válido'::VARCHAR, 0, ''::VARCHAR, ''::VARCHAR, ''::VARCHAR, ''::VARCHAR;
        RETURN;
    END IF;

    IF v_row."Status" != 'pending_verification' THEN
        RETURN QUERY SELECT false, 'Token ya fue usado'::VARCHAR, v_row."Id",
            v_row."Email", v_row."CompanyName", v_row."Plan", v_row."Status";
        RETURN;
    END IF;

    UPDATE cfg."OnboardingFlow"
    SET "Status" = 'verified', "VerifiedAt" = NOW(), "UpdatedAt" = NOW()
    WHERE "Id" = v_row."Id";

    RETURN QUERY SELECT true, 'OK'::VARCHAR, v_row."Id",
        v_row."Email", v_row."CompanyName", v_row."Plan", 'verified'::VARCHAR;
END;
$$;

-- SP: Actualizar status de onboarding
CREATE OR REPLACE FUNCTION cfg.usp_Cfg_Onboarding_UpdateStatus(
    p_id            INT,
    p_status        VARCHAR,
    p_company_id    INT DEFAULT NULL,
    p_tenant_slug   VARCHAR DEFAULT NULL,
    p_error_message VARCHAR DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE cfg."OnboardingFlow"
    SET "Status"       = p_status,
        "CompanyId"    = COALESCE(p_company_id, "CompanyId"),
        "TenantSlug"   = COALESCE(p_tenant_slug, "TenantSlug"),
        "ErrorMessage" = p_error_message,
        "ProvisionedAt"= CASE WHEN p_status = 'active' THEN NOW() ELSE "ProvisionedAt" END,
        "UpdatedAt"    = NOW()
    WHERE "Id" = p_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Registro no encontrado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT true, 'OK'::VARCHAR;
END;
$$;

-- SP: Consultar status por email
CREATE OR REPLACE FUNCTION cfg.usp_Cfg_Onboarding_StatusByEmail(
    p_email VARCHAR
)
RETURNS TABLE("Id" INT, "Email" VARCHAR, "CompanyName" VARCHAR, "Plan" VARCHAR,
              "Status" VARCHAR, "TenantSlug" VARCHAR, "CompanyId" INT,
              "CreatedAt" TIMESTAMPTZ, "VerifiedAt" TIMESTAMPTZ, "ProvisionedAt" TIMESTAMPTZ,
              "ErrorMessage" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT o."Id", o."Email", o."CompanyName", o."Plan",
           o."Status", o."TenantSlug", o."CompanyId",
           o."CreatedAt", o."VerifiedAt", o."ProvisionedAt",
           o."ErrorMessage"
    FROM cfg."OnboardingFlow" o
    WHERE o."Email" = p_email
    ORDER BY o."CreatedAt" DESC
    LIMIT 1;
END;
$$;

-- +goose Down
DROP FUNCTION IF EXISTS cfg.usp_Cfg_Onboarding_StatusByEmail(VARCHAR);
DROP FUNCTION IF EXISTS cfg.usp_Cfg_Onboarding_UpdateStatus(INT, VARCHAR, INT, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS cfg.usp_Cfg_Onboarding_Verify(VARCHAR);
DROP FUNCTION IF EXISTS cfg.usp_Cfg_Onboarding_Create(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP TABLE IF EXISTS cfg."OnboardingFlow";
