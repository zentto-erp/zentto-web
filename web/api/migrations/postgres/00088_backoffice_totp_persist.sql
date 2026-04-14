-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Persistencia del secret TOTP del backoffice en BD (sobrevive deploys).
--
-- Bug recurrente: el secret se guardaba solo en env var BACKOFFICE_TOTP_SECRET.
-- Al regenerar (flow 'Perdí mi autenticador'), el código intentaba escribir a
-- /opt/zentto/.env.api desde DENTRO del container — path no montado → falla
-- silenciosa. Cada deploy reiniciaba el container con el secret viejo.
--
-- Fix: tabla cfg."BackofficeAuth" con KV simple. Cada ambiente (zentto_prod,
-- zentto_dev) mantiene su propio secret. La env var queda como fallback de
-- bootstrap inicial.
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS cfg."BackofficeAuth" (
    "Key"        VARCHAR(50)  PRIMARY KEY,
    "Value"      TEXT         NOT NULL,
    "UpdatedAt"  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── SP: usp_cfg_backoffice_auth_get ──────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_backoffice_auth_get(
    p_key VARCHAR
)
RETURNS TABLE("Value" TEXT, "UpdatedAt" TIMESTAMPTZ)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT b."Value", b."UpdatedAt"
      FROM cfg."BackofficeAuth" b
     WHERE b."Key" = p_key
     LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ── SP: usp_cfg_backoffice_auth_set ──────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_backoffice_auth_set(
    p_key   VARCHAR,
    p_value TEXT
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO cfg."BackofficeAuth" ("Key", "Value", "UpdatedAt")
    VALUES (p_key, p_value, NOW())
    ON CONFLICT ("Key") DO UPDATE SET
        "Value" = EXCLUDED."Value",
        "UpdatedAt" = NOW();
    RETURN QUERY SELECT TRUE, 'guardado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_cfg_backoffice_auth_set(VARCHAR, TEXT);
DROP FUNCTION IF EXISTS usp_cfg_backoffice_auth_get(VARCHAR);
DROP TABLE IF EXISTS cfg."BackofficeAuth";
