-- ============================================================
-- usp_sys_resource.sql — Gestión de recursos de tenants
-- Motor: PostgreSQL (plpgsql)
-- Paridad: web/api/sqlweb/includes/sp/usp_sys_resource.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_resource_audit()
-- Audita el tamaño de BD y actividad de cada tenant activo.
-- Recorre sys."TenantDatabase", mide pg_database_size y registra en
-- sys."TenantResourceLog". Llamado por el job nocturno.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_resource_audit()
RETURNS TABLE(
  "tenants_audited" INT,
  "total_size_mb"   NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
  v_row            RECORD;
  v_db_size_bytes  BIGINT;
  v_db_size_mb     NUMERIC(10,2);
  v_last_login     TIMESTAMP;
  v_user_count     INT;
  v_count          INT := 0;
  v_total_bytes    BIGINT := 0;
BEGIN
  -- Recorrer todos los tenants activos con BD registrada
  FOR v_row IN
    SELECT t."CompanyId", t."DbName"
    FROM sys."TenantDatabase" t
    WHERE t."IsActive" = TRUE
    ORDER BY t."CompanyId"
  LOOP
    -- Obtener tamaño de la BD (dinámico — la BD puede ser externa)
    BEGIN
      EXECUTE format('SELECT pg_database_size(%L)', v_row."DbName")
        INTO v_db_size_bytes;
    EXCEPTION WHEN OTHERS THEN
      v_db_size_bytes := NULL;
    END;

    v_db_size_mb := CASE
      WHEN v_db_size_bytes IS NOT NULL THEN
        ROUND(v_db_size_bytes / 1048576.0, 2)
      ELSE NULL
    END;

    -- Último login del tenant desde audit.AuditLog en master
    SELECT MAX(a."CreatedAt")
    INTO v_last_login
    FROM audit."AuditLog" a
    WHERE a."CompanyId" = v_row."CompanyId"
      AND a."ModuleName" = 'auth';

    -- Conteo de usuarios activos del tenant
    SELECT COUNT(*)
    INTO v_user_count
    FROM sec."User" u
    WHERE u."CompanyId" = v_row."CompanyId"
      AND u."IsActive" = TRUE
      AND u."IsDeleted" = FALSE;

    -- Insertar registro de auditoría
    INSERT INTO sys."TenantResourceLog" (
      "CompanyId", "DbName",
      "DbSizeBytes", "DbSizeMB",
      "TableCount", "LastLoginAt",
      "UserCount", "RecordedAt"
    ) VALUES (
      v_row."CompanyId", v_row."DbName",
      v_db_size_bytes, v_db_size_mb,
      NULL,            -- TableCount no aplica en postgres cross-db
      v_last_login,
      v_user_count,
      NOW()
    );

    v_count       := v_count + 1;
    v_total_bytes := v_total_bytes + COALESCE(v_db_size_bytes, 0);
  END LOOP;

  RETURN QUERY SELECT
    v_count,
    ROUND(v_total_bytes / 1048576.0, 2);
END; $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_cleanup_scan()
-- Detecta automáticamente tenants candidatos a limpieza según 3 reglas:
--   1. TRIAL_EXPIRED  : Plan=FREE + licencia expirada >30d + sin conversión
--   2. CANCELLED_90D  : Licencia CANCELLED hace >90 días
--   3. SUSPENDED_180D : TenantStatus=SUSPENDED hace >180 días
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_cleanup_scan()
RETURNS TABLE(
  "new_candidates" INT,
  "total_pending"  INT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_new INT := 0;
  v_total INT;
BEGIN

  -- ── Regla 1: TRIAL_EXPIRED ─────────────────────────────────────────────────
  -- Plan FREE + licencia tipo TRIAL expirada hace >30 días + no convertida
  INSERT INTO sys."CleanupQueue" (
    "CompanyId", "Reason", "FlaggedAt", "FlaggedBy",
    "Status", "DbName", "DbSizeBytes", "DeleteAfter"
  )
  SELECT DISTINCT
    c."CompanyId",
    'TRIAL_EXPIRED'::VARCHAR(50),
    NOW(),
    'auto'::VARCHAR(100),
    'PENDING'::VARCHAR(20),
    t."DbName",
    NULL::BIGINT,
    NOW() + INTERVAL '30 days'
  FROM cfg."Company" c
  JOIN sys."License" l
    ON l."CompanyId" = c."CompanyId"
   AND l."LicenseType" = 'TRIAL'
   AND l."Status" IN ('EXPIRED', 'CANCELLED')
   AND l."ExpiresAt" < NOW() - INTERVAL '30 days'
   AND COALESCE(l."ConvertedFromTrial", FALSE) = FALSE
  LEFT JOIN sys."TenantDatabase" t ON t."CompanyId" = c."CompanyId"
  WHERE c."Plan" = 'FREE'
    AND c."IsActive" = TRUE
    AND c."IsDeleted" = FALSE
    AND NOT EXISTS (
      SELECT 1 FROM sys."CleanupQueue" q WHERE q."CompanyId" = c."CompanyId"
    )
  ON CONFLICT ("CompanyId") DO NOTHING;

  GET DIAGNOSTICS v_new = ROW_COUNT;

  -- ── Regla 2: CANCELLED_90D ─────────────────────────────────────────────────
  -- Licencia CANCELLED hace >90 días
  INSERT INTO sys."CleanupQueue" (
    "CompanyId", "Reason", "FlaggedAt", "FlaggedBy",
    "Status", "DbName", "DbSizeBytes", "DeleteAfter"
  )
  SELECT DISTINCT
    c."CompanyId",
    'CANCELLED_90D'::VARCHAR(50),
    NOW(),
    'auto'::VARCHAR(100),
    'PENDING'::VARCHAR(20),
    t."DbName",
    NULL::BIGINT,
    NOW() + INTERVAL '30 days'
  FROM cfg."Company" c
  JOIN sys."License" l
    ON l."CompanyId" = c."CompanyId"
   AND l."Status" = 'CANCELLED'
   AND l."UpdatedAt" < NOW() - INTERVAL '90 days'
  LEFT JOIN sys."TenantDatabase" t ON t."CompanyId" = c."CompanyId"
  WHERE c."IsActive" = TRUE
    AND c."IsDeleted" = FALSE
    -- Excluir INTERNAL (Zentto mismo) y tenants que ya tienen licencia activa
    AND NOT EXISTS (
      SELECT 1 FROM sys."License" la
      WHERE la."CompanyId" = c."CompanyId"
        AND la."Status" = 'ACTIVE'
        AND la."LicenseType" = 'INTERNAL'
    )
    AND NOT EXISTS (
      SELECT 1 FROM sys."CleanupQueue" q WHERE q."CompanyId" = c."CompanyId"
    )
  ON CONFLICT ("CompanyId") DO NOTHING;

  v_new := v_new + (SELECT COUNT(*) FROM sys."CleanupQueue"
                    WHERE "Status" = 'PENDING'
                      AND "Reason" = 'CANCELLED_90D'
                      AND "FlaggedAt" >= NOW() - INTERVAL '1 minute');

  -- ── Regla 3: SUSPENDED_180D ────────────────────────────────────────────────
  -- TenantStatus=SUSPENDED + sin cambio hace >180 días
  INSERT INTO sys."CleanupQueue" (
    "CompanyId", "Reason", "FlaggedAt", "FlaggedBy",
    "Status", "DbName", "DbSizeBytes", "DeleteAfter"
  )
  SELECT DISTINCT
    c."CompanyId",
    'SUSPENDED_180D'::VARCHAR(50),
    NOW(),
    'auto'::VARCHAR(100),
    'PENDING'::VARCHAR(20),
    t."DbName",
    NULL::BIGINT,
    NOW() + INTERVAL '30 days'
  FROM cfg."Company" c
  LEFT JOIN sys."TenantDatabase" t ON t."CompanyId" = c."CompanyId"
  WHERE c."TenantStatus" = 'SUSPENDED'
    AND c."UpdatedAt" < NOW() - INTERVAL '180 days'
    AND c."IsDeleted" = FALSE
    AND NOT EXISTS (
      SELECT 1 FROM sys."CleanupQueue" q WHERE q."CompanyId" = c."CompanyId"
    )
  ON CONFLICT ("CompanyId") DO NOTHING;

  -- Total PENDING tras el scan
  SELECT COUNT(*) INTO v_total
  FROM sys."CleanupQueue"
  WHERE "Status" = 'PENDING';

  RETURN QUERY SELECT v_new, v_total;
END; $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_cleanup_list(p_status)
-- Lista la cola de limpieza con información del tenant.
-- p_status NULL = todos los estados
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_cleanup_list(
  p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE(
  "CompanyId"      BIGINT,
  "CompanyCode"    VARCHAR,
  "LegalName"      VARCHAR,
  "Plan"           VARCHAR,
  "Reason"         VARCHAR,
  "Status"         VARCHAR,
  "FlaggedAt"      TIMESTAMP,
  "DeleteAfter"    TIMESTAMP,
  "DbSizeMB"       NUMERIC,
  "LastLoginAt"    TIMESTAMP,
  "DaysUntilDelete" INT
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    c."CompanyId"::BIGINT,
    c."CompanyCode"::VARCHAR,
    c."LegalName"::VARCHAR,
    c."Plan"::VARCHAR,
    q."Reason"::VARCHAR,
    q."Status"::VARCHAR,
    q."FlaggedAt",
    q."DeleteAfter",
    COALESCE(rl."DbSizeMB", NULL::NUMERIC),
    rl."LastLoginAt",
    CASE
      WHEN q."DeleteAfter" IS NULL THEN NULL::INT
      ELSE EXTRACT(DAY FROM q."DeleteAfter" - NOW())::INT
    END
  FROM sys."CleanupQueue" q
  JOIN cfg."Company" c ON c."CompanyId" = q."CompanyId"
  LEFT JOIN LATERAL (
    -- Último registro de recursos del tenant
    SELECT r."DbSizeMB", r."LastLoginAt"
    FROM sys."TenantResourceLog" r
    WHERE r."CompanyId" = q."CompanyId"
    ORDER BY r."RecordedAt" DESC
    LIMIT 1
  ) rl ON TRUE
  WHERE (p_status IS NULL OR q."Status" = p_status)
  ORDER BY q."FlaggedAt" DESC;
END; $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- usp_sys_cleanup_process(p_queue_id, p_action)
-- Procesa una entrada de la cola de limpieza.
-- p_action: 'CANCEL' | 'NOTIFY' | 'ARCHIVE' | 'CONFIRM_DELETE'
-- CONFIRM_DELETE: solo marca como DELETED — el borrado real de la BD
-- lo ejecuta el job Node.js (nunca un SP).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_sys_cleanup_process(
  p_queue_id BIGINT,
  p_action   VARCHAR
)
RETURNS TABLE(
  "ok"      BOOLEAN,
  "mensaje" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
  v_current_status VARCHAR(20);
  v_company_id     BIGINT;
BEGIN
  -- Obtener registro actual
  SELECT q."Status", q."CompanyId"
  INTO v_current_status, v_company_id
  FROM sys."CleanupQueue" q
  WHERE q."QueueId" = p_queue_id;

  IF v_company_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'QUEUE_NOT_FOUND'::VARCHAR;
    RETURN;
  END IF;

  -- Validar transiciones de estado permitidas
  CASE p_action

    WHEN 'CANCEL' THEN
      IF v_current_status = 'DELETED' THEN
        RETURN QUERY SELECT FALSE, 'CANNOT_CANCEL_DELETED'::VARCHAR;
        RETURN;
      END IF;
      UPDATE sys."CleanupQueue"
      SET "Status" = 'CANCELLED', "ProcessedAt" = NOW()
      WHERE "QueueId" = p_queue_id;
      RETURN QUERY SELECT TRUE, 'CANCELLED'::VARCHAR;

    WHEN 'NOTIFY' THEN
      IF v_current_status NOT IN ('PENDING') THEN
        RETURN QUERY SELECT FALSE, ('INVALID_STATUS_FOR_NOTIFY:' || v_current_status)::VARCHAR;
        RETURN;
      END IF;
      UPDATE sys."CleanupQueue"
      SET "Status" = 'NOTIFIED', "NotifiedAt" = NOW()
      WHERE "QueueId" = p_queue_id;
      RETURN QUERY SELECT TRUE, 'NOTIFIED'::VARCHAR;

    WHEN 'ARCHIVE' THEN
      IF v_current_status NOT IN ('PENDING', 'NOTIFIED') THEN
        RETURN QUERY SELECT FALSE, ('INVALID_STATUS_FOR_ARCHIVE:' || v_current_status)::VARCHAR;
        RETURN;
      END IF;
      UPDATE sys."CleanupQueue"
      SET "Status" = 'ARCHIVED', "ProcessedAt" = NOW()
      WHERE "QueueId" = p_queue_id;
      RETURN QUERY SELECT TRUE, 'ARCHIVED'::VARCHAR;

    WHEN 'CONFIRM_DELETE' THEN
      IF v_current_status NOT IN ('PENDING', 'NOTIFIED', 'ARCHIVED') THEN
        RETURN QUERY SELECT FALSE, ('INVALID_STATUS_FOR_DELETE:' || v_current_status)::VARCHAR;
        RETURN;
      END IF;
      -- Solo marcar: el job Node.js hace el DROP DATABASE real
      UPDATE sys."CleanupQueue"
      SET "Status" = 'DELETED', "ProcessedAt" = NOW()
      WHERE "QueueId" = p_queue_id;

      -- Marcar empresa como inactiva y eliminada
      UPDATE cfg."Company"
      SET "IsActive"   = FALSE,
          "IsDeleted"  = TRUE,
          "DeletedAt"  = NOW(),
          "TenantStatus" = 'CANCELLED'
      WHERE "CompanyId" = v_company_id;

      RETURN QUERY SELECT TRUE, 'CONFIRM_DELETE_OK'::VARCHAR;

    ELSE
      RETURN QUERY SELECT FALSE, ('UNKNOWN_ACTION:' || COALESCE(p_action, 'NULL'))::VARCHAR;

  END CASE;
END; $$;
