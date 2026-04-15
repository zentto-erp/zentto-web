-- +goose Up

-- Extiende cfg.PublicApiKey para que una key pueda autorizar más que solo
-- crear leads. Hoy todos los scopes viven como VARCHAR(500) CSV, así que
-- lo único que cambia es (a) convención de scope names, (b) un helper que
-- verifica scope + CompanyId, y (c) docs.
--
-- Scopes soportados (convención "resource:action"):
--   landing:lead:create       (antes default)
--   notify:email:send         (email via notify desde el sitio del tenant)
--   notify:contacts:upsert    (CRM notify scope del tenant)
--   notify:otp:send           (OTP pass-through)
--   cache:read                (lectura de cache.zentto.net)
--   cache:write               (escritura de cache.zentto.net)
--
-- Scope '*' = permite todo (solo asignable via admin — no expuesto en UI
-- pública).

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION cfg.usp_cfg_publicapikey_verify_scope(
  p_key_plain TEXT,
  p_scope     TEXT
) RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
  v_hash     TEXT;
  v_row      RECORD;
  v_scopes   TEXT[];
BEGIN
  IF p_key_plain IS NULL OR TRIM(p_key_plain) = '' THEN RETURN NULL; END IF;
  IF p_scope IS NULL OR TRIM(p_scope) = '' THEN RETURN NULL; END IF;

  v_hash := ENCODE(DIGEST(TRIM(p_key_plain), 'sha256'), 'hex');

  SELECT "CompanyId", "Scopes" INTO v_row
  FROM cfg."PublicApiKey"
  WHERE "KeyHash" = v_hash
    AND "IsActive" = TRUE
    AND "IsDeleted" = FALSE
    AND ("ExpiresAt" IS NULL OR "ExpiresAt" > (now() AT TIME ZONE 'UTC'))
  LIMIT 1;

  IF v_row IS NULL THEN RETURN NULL; END IF;

  -- Scopes CSV → array
  v_scopes := string_to_array(REPLACE(v_row."Scopes", ' ', ''), ',');

  -- Match: wildcard '*' OR scope exacto
  IF '*' = ANY(v_scopes) OR p_scope = ANY(v_scopes) THEN
    UPDATE cfg."PublicApiKey"
    SET "LastUsedAt" = (now() AT TIME ZONE 'UTC')
    WHERE "KeyHash" = v_hash;
    RETURN v_row."CompanyId";
  END IF;

  RETURN NULL;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
-- Mejora usp_cfg_publicapikey_create para validar scopes conocidos.
-- Comentado: mantiene backward compat — el SP no rechaza scopes
-- desconocidos (permite extensiones futuras sin migración).
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS cfg.usp_cfg_publicapikey_verify_scope(TEXT, TEXT);
-- +goose StatementEnd
