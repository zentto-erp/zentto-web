-- +goose Up
-- CRM-108: Tabla crm."SavedView" + funciones para gestionar vistas guardadas
-- (filtros, columnas y orden) por usuario y entidad. Soporta vistas compartidas
-- a nivel de tenant (CompanyId) y una vista por defecto por (User, Entity).

-- ── Tabla ────────────────────────────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS crm."SavedView" (
    "ViewId"       BIGINT       PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "CompanyId"    INTEGER      NOT NULL,
    "UserId"       INTEGER      NOT NULL,
    "Entity"       VARCHAR(50)  NOT NULL,
    "Name"         VARCHAR(200) NOT NULL,
    "FilterJson"   JSONB        NOT NULL DEFAULT '{}'::JSONB,
    "ColumnsJson"  JSONB,
    "SortJson"     JSONB,
    "IsShared"     BOOLEAN      NOT NULL DEFAULT FALSE,
    "IsDefault"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "CreatedAt"    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "UpdatedAt"    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT "CK_crm_SavedView_Entity"
        CHECK ("Entity" IN ('LEAD','CONTACT','COMPANY','DEAL','ACTIVITY')),
    CONSTRAINT "UQ_crm_SavedView_Name"
        UNIQUE ("CompanyId","UserId","Entity","Name"),
    CONSTRAINT "FK_crm_SavedView_Company"
        FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
    CONSTRAINT "FK_crm_SavedView_User"
        FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId")
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_SavedView_UserEntity"
    ON crm."SavedView" ("CompanyId","UserId","Entity");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_crm_SavedView_Shared"
    ON crm."SavedView" ("CompanyId","Entity","IsShared")
    WHERE "IsShared" = TRUE;
-- +goose StatementEnd


-- ── usp_crm_saved_view_list ──────────────────────────────────────────────────
-- Lista vistas del usuario + vistas compartidas por otros del mismo tenant.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_list(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_entity     VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMPTZ,
    "UpdatedAt"   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        sv."ViewId",
        sv."CompanyId",
        sv."UserId",
        sv."Entity"::VARCHAR,
        sv."Name"::VARCHAR,
        sv."FilterJson",
        sv."ColumnsJson",
        sv."SortJson",
        sv."IsShared",
        sv."IsDefault",
        (sv."UserId" = p_user_id) AS "IsOwner",
        sv."CreatedAt",
        sv."UpdatedAt"
    FROM   crm."SavedView" sv
    WHERE  sv."CompanyId" = p_company_id
      AND  (p_entity IS NULL OR sv."Entity" = p_entity)
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE)
    ORDER BY sv."Entity", sv."IsDefault" DESC, sv."Name";
END;
$$;
-- +goose StatementEnd


-- ── usp_crm_saved_view_detail ────────────────────────────────────────────────
-- Detalle por ViewId con tenant guard + visibilidad (owner o compartida).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_detail(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_view_id    BIGINT
)
RETURNS TABLE(
    "ViewId"      BIGINT,
    "CompanyId"   INTEGER,
    "UserId"      INTEGER,
    "Entity"      VARCHAR,
    "Name"        VARCHAR,
    "FilterJson"  JSONB,
    "ColumnsJson" JSONB,
    "SortJson"    JSONB,
    "IsShared"    BOOLEAN,
    "IsDefault"   BOOLEAN,
    "IsOwner"     BOOLEAN,
    "CreatedAt"   TIMESTAMPTZ,
    "UpdatedAt"   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        sv."ViewId",
        sv."CompanyId",
        sv."UserId",
        sv."Entity"::VARCHAR,
        sv."Name"::VARCHAR,
        sv."FilterJson",
        sv."ColumnsJson",
        sv."SortJson",
        sv."IsShared",
        sv."IsDefault",
        (sv."UserId" = p_user_id) AS "IsOwner",
        sv."CreatedAt",
        sv."UpdatedAt"
    FROM   crm."SavedView" sv
    WHERE  sv."ViewId"    = p_view_id
      AND  sv."CompanyId" = p_company_id
      AND  (sv."UserId" = p_user_id OR sv."IsShared" = TRUE);
END;
$$;
-- +goose StatementEnd


-- ── usp_crm_saved_view_upsert ────────────────────────────────────────────────
-- Insert/Update. Solo el owner puede actualizar. ViewId NULL o <=0 = create.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_upsert(
    p_company_id   INTEGER,
    p_user_id      INTEGER,
    p_view_id      BIGINT        DEFAULT NULL,
    p_entity       VARCHAR       DEFAULT NULL,
    p_name         VARCHAR       DEFAULT NULL,
    p_filter_json  JSONB         DEFAULT '{}'::JSONB,
    p_columns_json JSONB         DEFAULT NULL,
    p_sort_json    JSONB         DEFAULT NULL,
    p_is_shared    BOOLEAN       DEFAULT FALSE,
    p_is_default   BOOLEAN       DEFAULT FALSE
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR, "ViewId" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_view_id  BIGINT;
    v_owner_id INTEGER;
BEGIN
    IF p_view_id IS NULL OR p_view_id <= 0 THEN
        -- Crear
        IF p_entity IS NULL OR p_name IS NULL THEN
            RETURN QUERY SELECT FALSE, 'Entity y Name son requeridos'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;

        IF p_entity NOT IN ('LEAD','CONTACT','COMPANY','DEAL','ACTIVITY') THEN
            RETURN QUERY SELECT FALSE, 'Entity invalida'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;

        -- Si se marca default, limpiar el flag de las demas del mismo user/entity
        IF COALESCE(p_is_default, FALSE) = TRUE THEN
            UPDATE crm."SavedView"
               SET "IsDefault" = FALSE,
                   "UpdatedAt" = NOW()
             WHERE "CompanyId" = p_company_id
               AND "UserId"    = p_user_id
               AND "Entity"    = p_entity
               AND "IsDefault" = TRUE;
        END IF;

        INSERT INTO crm."SavedView" (
            "CompanyId","UserId","Entity","Name","FilterJson",
            "ColumnsJson","SortJson","IsShared","IsDefault"
        ) VALUES (
            p_company_id, p_user_id, p_entity, p_name,
            COALESCE(p_filter_json, '{}'::JSONB),
            p_columns_json, p_sort_json,
            COALESCE(p_is_shared, FALSE),
            COALESCE(p_is_default, FALSE)
        )
        RETURNING crm."SavedView"."ViewId" INTO v_view_id;

        RETURN QUERY SELECT TRUE, 'Vista creada'::VARCHAR, v_view_id;
        RETURN;
    ELSE
        -- Actualizar — solo owner del mismo tenant
        SELECT sv."UserId" INTO v_owner_id
        FROM   crm."SavedView" sv
        WHERE  sv."ViewId"    = p_view_id
          AND  sv."CompanyId" = p_company_id;

        IF v_owner_id IS NULL THEN
            RETURN QUERY SELECT FALSE, 'Vista no encontrada'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;

        IF v_owner_id <> p_user_id THEN
            RETURN QUERY SELECT FALSE, 'Solo el propietario puede modificar la vista'::VARCHAR, NULL::BIGINT;
            RETURN;
        END IF;

        -- Si se marca default, limpiar los demas del mismo user/entity
        IF COALESCE(p_is_default, FALSE) = TRUE THEN
            UPDATE crm."SavedView"
               SET "IsDefault" = FALSE,
                   "UpdatedAt" = NOW()
             WHERE "CompanyId" = p_company_id
               AND "UserId"    = p_user_id
               AND "Entity"    = COALESCE(p_entity, (SELECT "Entity" FROM crm."SavedView" WHERE "ViewId" = p_view_id))
               AND "ViewId"   <> p_view_id
               AND "IsDefault" = TRUE;
        END IF;

        UPDATE crm."SavedView"
           SET "Name"        = COALESCE(p_name,         "Name"),
               "FilterJson"  = COALESCE(p_filter_json,  "FilterJson"),
               "ColumnsJson" = COALESCE(p_columns_json, "ColumnsJson"),
               "SortJson"    = COALESCE(p_sort_json,    "SortJson"),
               "IsShared"    = COALESCE(p_is_shared,    "IsShared"),
               "IsDefault"   = COALESCE(p_is_default,   "IsDefault"),
               "UpdatedAt"   = NOW()
         WHERE "ViewId" = p_view_id;

        RETURN QUERY SELECT TRUE, 'Vista actualizada'::VARCHAR, p_view_id;
        RETURN;
    END IF;

EXCEPTION
    WHEN unique_violation THEN
        RETURN QUERY SELECT FALSE, 'Ya existe una vista con ese nombre para la entidad'::VARCHAR, NULL::BIGINT;
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, SQLERRM::VARCHAR, NULL::BIGINT;
END;
$$;
-- +goose StatementEnd


-- ── usp_crm_saved_view_delete ────────────────────────────────────────────────
-- Hard delete con tenant + owner guard (no hay FK entrantes).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_delete(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_view_id    BIGINT
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_owner_id INTEGER;
BEGIN
    SELECT sv."UserId" INTO v_owner_id
    FROM   crm."SavedView" sv
    WHERE  sv."ViewId"    = p_view_id
      AND  sv."CompanyId" = p_company_id;

    IF v_owner_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Vista no encontrada'::VARCHAR;
        RETURN;
    END IF;

    IF v_owner_id <> p_user_id THEN
        RETURN QUERY SELECT FALSE, 'Solo el propietario puede eliminar la vista'::VARCHAR;
        RETURN;
    END IF;

    DELETE FROM crm."SavedView"
     WHERE "ViewId"    = p_view_id
       AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT TRUE, 'Vista eliminada'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- ── usp_crm_saved_view_set_default ───────────────────────────────────────────
-- Marca una vista como default y limpia el flag de las otras del mismo
-- user/entity atomicamente. Solo owner.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_crm_saved_view_set_default(
    p_company_id INTEGER,
    p_user_id    INTEGER,
    p_view_id    BIGINT
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_owner_id INTEGER;
    v_entity   VARCHAR(50);
BEGIN
    SELECT sv."UserId", sv."Entity" INTO v_owner_id, v_entity
    FROM   crm."SavedView" sv
    WHERE  sv."ViewId"    = p_view_id
      AND  sv."CompanyId" = p_company_id;

    IF v_owner_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Vista no encontrada'::VARCHAR;
        RETURN;
    END IF;

    IF v_owner_id <> p_user_id THEN
        RETURN QUERY SELECT FALSE, 'Solo el propietario puede marcar default'::VARCHAR;
        RETURN;
    END IF;

    -- Atomic: la funcion PG ya corre en una tx implicita.
    UPDATE crm."SavedView"
       SET "IsDefault" = FALSE,
           "UpdatedAt" = NOW()
     WHERE "CompanyId" = p_company_id
       AND "UserId"    = p_user_id
       AND "Entity"    = v_entity
       AND "IsDefault" = TRUE
       AND "ViewId"   <> p_view_id;

    UPDATE crm."SavedView"
       SET "IsDefault" = TRUE,
           "UpdatedAt" = NOW()
     WHERE "ViewId"    = p_view_id
       AND "CompanyId" = p_company_id;

    RETURN QUERY SELECT TRUE, 'Default actualizado'::VARCHAR;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, SQLERRM::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_saved_view_set_default(INTEGER, INTEGER, BIGINT);
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_saved_view_delete(INTEGER, INTEGER, BIGINT);
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_saved_view_upsert(INTEGER, INTEGER, BIGINT, VARCHAR, VARCHAR, JSONB, JSONB, JSONB, BOOLEAN, BOOLEAN);
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_saved_view_detail(INTEGER, INTEGER, BIGINT);
-- +goose StatementEnd

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_crm_saved_view_list(INTEGER, INTEGER, VARCHAR);
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS crm."SavedView";
-- +goose StatementEnd
