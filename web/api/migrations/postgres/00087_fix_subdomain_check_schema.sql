-- +goose Up
-- Fix: usp_cfg_subdomain_check usaba 'mstr.Company' (nombre SQL Server) que
-- no existe en PostgreSQL. El equivalente PG es cfg.Company.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cfg_subdomain_check(
    p_slug VARCHAR
)
RETURNS TABLE("available" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_count     INTEGER;
    v_reserved  TEXT[] := ARRAY[
        'www','app','api','auth','admin','backoffice','docs','docs2','dev',
        'appdev','apidev','authdev','notify','vault','mail','elastic','kibana',
        'broker','store','staging','test','demo','static','cdn','assets','img',
        'blog','support','help','status','stress','report','pay','payments'
    ];
BEGIN
    IF p_slug IS NULL OR LENGTH(p_slug) < 3 OR LENGTH(p_slug) > 63
       OR p_slug !~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' THEN
        RETURN QUERY SELECT FALSE, 'Formato inválido (3-63 caracteres, minúsculas/números/guiones)'::VARCHAR;
        RETURN;
    END IF;

    IF p_slug = ANY(v_reserved) THEN
        RETURN QUERY SELECT FALSE, 'Subdominio reservado'::VARCHAR;
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM cfg."Company"
     WHERE LOWER("TenantSubdomain") = p_slug;

    IF v_count > 0 THEN
        RETURN QUERY SELECT FALSE, 'Subdominio ocupado'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, 'Disponible'::VARCHAR;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- No revertir: la versión previa también estaba rota (mstr no existe en PG).
SELECT 1;
