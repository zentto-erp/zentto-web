-- usp_governance_capturesnapshot
CREATE OR REPLACE FUNCTION public.usp_governance_capturesnapshot(p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" bigint, "SnapshotAt" timestamp without time zone, "TotalTables" integer, "TablesWithoutPK" integer, "TablesWithoutCreatedAt" integer, "TablesWithoutUpdatedAt" integer, "TablesWithoutCreatedBy" integer, "TablesWithoutDateColumns" integer, "DuplicateNameCandidatePairs" integer, "SimilarityCandidatePairs" integer, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total INT := 0;
    v_no_pk INT := 0;
    v_no_cat INT := 0;
    v_no_uat INT := 0;
    v_no_cby INT := 0;
    v_no_dt INT := 0;
    v_dup INT := 0;
    v_sim INT := 0;
BEGIN
    SELECT
        COUNT(1),
        SUM(CASE WHEN NOT has_pk THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_created_at THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_updated_at THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT has_created_by THEN 1 ELSE 0 END),
        SUM(CASE WHEN date_column_count = 0 THEN 1 ELSE 0 END)
    INTO v_total, v_no_pk, v_no_cat, v_no_uat, v_no_cby, v_no_dt
    FROM public."vw_Governance_AuditCoverage";

    SELECT COUNT(1) INTO v_dup FROM public."vw_Governance_DuplicateNameCandidates";
    SELECT COUNT(1) INTO v_sim FROM public."vw_Governance_TableSimilarityCandidates" WHERE similarity_ratio >= 0.7000;

    INSERT INTO public."SchemaGovernanceSnapshot" (
        "TotalTables", "TablesWithoutPK", "TablesWithoutCreatedAt", "TablesWithoutUpdatedAt",
        "TablesWithoutCreatedBy", "TablesWithoutDateColumns", "DuplicateNameCandidatePairs",
        "SimilarityCandidatePairs", "Notes"
    ) VALUES (v_total, v_no_pk, v_no_cat, v_no_uat, v_no_cby, v_no_dt, v_dup, v_sim, p_notes);

    RETURN QUERY
    SELECT s.* FROM public."SchemaGovernanceSnapshot" s ORDER BY s."Id" DESC LIMIT 1;
END;
$function$
;

-- usp_sys_genericdelete
CREATE OR REPLACE FUNCTION public.usp_sys_genericdelete(p_schema_name character varying, p_table_name character varying, p_key_json jsonb)
 RETURNS TABLE("rowsAffected" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table   TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_where        TEXT := '';
    v_key          TEXT;
    v_val          TEXT;
    v_rows         INT;
BEGIN
    FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_key_json)
    LOOP
        IF v_where = '' THEN v_where := ' WHERE '; ELSE v_where := v_where || ' AND '; END IF;
        v_where := v_where || quote_ident(v_key) || ' = ' || quote_literal(v_val);
    END LOOP;

    EXECUTE 'DELETE FROM ' || v_full_table || v_where;
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RETURN QUERY SELECT v_rows;
END;
$function$
;

-- usp_sys_genericgetbykey
CREATE OR REPLACE FUNCTION public.usp_sys_genericgetbykey(p_schema_name character varying, p_table_name character varying, p_key_json jsonb)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table   TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_where        TEXT := '';
    v_key          TEXT;
    v_val          TEXT;
BEGIN
    FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_key_json)
    LOOP
        IF v_where = '' THEN v_where := ' WHERE '; ELSE v_where := v_where || ' AND '; END IF;
        v_where := v_where || quote_ident(v_key) || ' = ' || quote_literal(v_val);
    END LOOP;

    RETURN QUERY EXECUTE 'SELECT to_jsonb(t.*) FROM ' || v_full_table || ' t' || v_where;
END;
$function$
;

-- usp_sys_genericinsert
CREATE OR REPLACE FUNCTION public.usp_sys_genericinsert(p_schema_name character varying, p_table_name character varying, p_data_json jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_cols       TEXT := '';
    v_vals       TEXT := '';
    v_key        TEXT;
    v_val        TEXT;
    v_type       TEXT;
BEGIN
    FOR v_key IN SELECT k FROM jsonb_object_keys(p_data_json) AS k
    LOOP
        IF v_cols <> '' THEN v_cols := v_cols || ', '; v_vals := v_vals || ', '; END IF;
        v_cols := v_cols || quote_ident(v_key);
        v_type := jsonb_typeof(p_data_json->v_key);
        IF v_type = 'null' THEN
            v_vals := v_vals || 'NULL';
        ELSE
            v_vals := v_vals || quote_literal(p_data_json->>v_key);
        END IF;
    END LOOP;

    IF v_cols = '' THEN
        RAISE EXCEPTION 'no_writable_fields';
    END IF;

    EXECUTE 'INSERT INTO ' || v_full_table || ' (' || v_cols || ') VALUES (' || v_vals || ')';
END;
$function$
;

-- usp_sys_genericlist
CREATE OR REPLACE FUNCTION public.usp_sys_genericlist(p_schema_name character varying, p_table_name character varying, p_sort_column character varying DEFAULT 'id'::character varying, p_sort_dir character varying DEFAULT 'ASC'::character varying, p_offset integer DEFAULT 0, p_page_size integer DEFAULT 50, p_filters_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("TotalCount" bigint, "JsonRow" jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_safe_sort  TEXT := quote_ident(p_sort_column);
    v_direction  TEXT := CASE WHEN UPPER(p_sort_dir)::character varying = 'DESC' THEN 'DESC' ELSE 'ASC' END;
    v_where      TEXT := '';
    v_key        TEXT;
    v_val        TEXT;
    v_total      BIGINT;
BEGIN
    -- Build WHERE from JSONB filters (key=value equality)
    IF p_filters_json IS NOT NULL AND jsonb_typeof(p_filters_json) = 'object' THEN
        FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_filters_json)
        LOOP
            IF v_where = '' THEN v_where := ' WHERE '; ELSE v_where := v_where || ' AND '; END IF;
            v_where := v_where || quote_ident(v_key) || ' = ' || quote_literal(v_val);
        END LOOP;
    END IF;

    -- Count
    EXECUTE 'SELECT COUNT(1) FROM ' || v_full_table || v_where INTO v_total;

    -- Data
    RETURN QUERY EXECUTE
        'SELECT ' || v_total || '::BIGINT, to_jsonb(t.*) FROM ' || v_full_table || ' t' || v_where
        || ' ORDER BY ' || v_safe_sort || ' ' || v_direction
        || ' LIMIT ' || p_page_size || ' OFFSET ' || p_offset;
END;
$function$
;

-- usp_sys_genericupdate
CREATE OR REPLACE FUNCTION public.usp_sys_genericupdate(p_schema_name character varying, p_table_name character varying, p_key_json jsonb, p_data_json jsonb)
 RETURNS TABLE("rowsAffected" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_full_table   TEXT := quote_ident(p_schema_name) || '.' || quote_ident(p_table_name);
    v_set_clause   TEXT := '';
    v_where        TEXT := '';
    v_key          TEXT;
    v_val          TEXT;
    v_type         TEXT;
    v_rows         INT;
BEGIN
    -- Build SET clause
    FOR v_key IN SELECT k FROM jsonb_object_keys(p_data_json) AS k
    LOOP
        IF v_set_clause <> '' THEN v_set_clause := v_set_clause || ', '; END IF;
        v_type := jsonb_typeof(p_data_json->v_key);
        IF v_type = 'null' THEN
            v_set_clause := v_set_clause || quote_ident(v_key) || ' = NULL';
        ELSE
            v_set_clause := v_set_clause || quote_ident(v_key) || ' = ' || quote_literal(p_data_json->>v_key);
        END IF;
    END LOOP;

    IF v_set_clause = '' THEN
        RAISE EXCEPTION 'no_writable_fields';
    END IF;

    -- Build WHERE from key
    FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_key_json)
    LOOP
        IF v_where = '' THEN v_where := ' WHERE '; ELSE v_where := v_where || ' AND '; END IF;
        v_where := v_where || quote_ident(v_key) || ' = ' || quote_literal(v_val);
    END LOOP;

    EXECUTE 'UPDATE ' || v_full_table || ' SET ' || v_set_clause || v_where;
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    RETURN QUERY SELECT v_rows;
END;
$function$
;

-- usp_sys_gettablecolumns
CREATE OR REPLACE FUNCTION public.usp_sys_gettablecolumns(p_schema_name character varying, p_table_name character varying)
 RETURNS TABLE("COLUMN_NAME" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.column_name::VARCHAR
    FROM   information_schema.columns c
    WHERE  c.table_schema = p_schema_name
      AND  c.table_name   = p_table_name
    ORDER BY c.ordinal_position;
END;
$function$
;

-- usp_sys_headerdetailtx
CREATE OR REPLACE FUNCTION public.usp_sys_headerdetailtx(p_header_table character varying, p_detail_table character varying, p_header_json jsonb, p_details_json jsonb, p_link_fields_csv character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok integer, "detailRows" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_cols       TEXT;
    v_vals       TEXT;
    v_sql        TEXT;
    v_detail_count INT;
    v_row        JSONB;
    v_key        TEXT;
    v_val        TEXT;
    v_d_cols     TEXT;
    v_d_vals     TEXT;
    v_link_fields TEXT[];
    v_lf         TEXT;
BEGIN
    -- Build header INSERT dynamically from JSONB keys
    v_cols := '';
    v_vals := '';

    FOR v_key, v_val IN SELECT * FROM jsonb_each_text(p_header_json)
    LOOP
        IF v_cols <> '' THEN v_cols := v_cols || ', '; v_vals := v_vals || ', '; END IF;
        v_cols := v_cols || quote_ident(v_key);
        v_vals := v_vals || quote_literal(v_val);
    END LOOP;

    v_sql := 'INSERT INTO ' || p_header_table || ' (' || v_cols || ') VALUES (' || v_vals || ')';
    EXECUTE v_sql;

    -- Parse link fields
    IF p_link_fields_csv IS NOT NULL AND LENGTH(p_link_fields_csv) > 0 THEN
        v_link_fields := string_to_array(p_link_fields_csv, ',');
        FOR i IN 1..array_length(v_link_fields, 1) LOOP
            v_link_fields[i] := TRIM(v_link_fields[i]);
        END LOOP;
    ELSE
        v_link_fields := ARRAY[]::TEXT[];
    END IF;

    -- Process each detail row
    v_detail_count := jsonb_array_length(p_details_json);

    FOR i IN 0..v_detail_count-1
    LOOP
        v_row := p_details_json->i;

        -- Add header link fields if missing from detail row
        IF array_length(v_link_fields, 1) > 0 THEN
            FOREACH v_lf IN ARRAY v_link_fields
            LOOP
                IF v_row->>v_lf IS NULL AND p_header_json->>v_lf IS NOT NULL THEN
                    v_row := v_row || jsonb_build_object(v_lf, p_header_json->>v_lf);
                END IF;
            END LOOP;
        END IF;

        -- Build INSERT from row keys
        v_d_cols := '';
        v_d_vals := '';

        FOR v_key, v_val IN SELECT * FROM jsonb_each_text(v_row)
        LOOP
            IF v_d_cols <> '' THEN v_d_cols := v_d_cols || ', '; v_d_vals := v_d_vals || ', '; END IF;
            v_d_cols := v_d_cols || quote_ident(v_key);
            v_d_vals := v_d_vals || quote_literal(v_val);
        END LOOP;

        IF LENGTH(v_d_cols) > 0 THEN
            v_sql := 'INSERT INTO ' || p_detail_table || ' (' || v_d_cols || ') VALUES (' || v_d_vals || ')';
            EXECUTE v_sql;
        END IF;
    END LOOP;

    RETURN QUERY SELECT 1, v_detail_count;
END;
$function$
;

-- usp_sys_healthcheck
CREATE OR REPLACE FUNCTION public.usp_sys_healthcheck()
 RETURNS TABLE(ok integer, "serverTime" timestamp without time zone, "dbName" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 1, NOW() AT TIME ZONE 'UTC', current_database()::TEXT;
END;
$function$
;

-- usp_sys_mensaje_list
CREATE OR REPLACE FUNCTION public.usp_sys_mensaje_list(p_destinatario_id character varying)
 RETURNS TABLE("Id" integer, "RemitenteId" character varying, "RemitenteNombre" character varying, "Asunto" character varying, "Cuerpo" character varying, "Leido" boolean, "FechaEnvio" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."Id", m."RemitenteId", m."RemitenteNombre",
           m."Asunto", m."Cuerpo", m."Leido", m."FechaEnvio"
    FROM "Sys_Mensajes" m
    WHERE m."DestinatarioId" = p_destinatario_id
    ORDER BY m."FechaEnvio" DESC
    LIMIT 50;
END;
$function$
;

-- usp_sys_mensaje_markread
CREATE OR REPLACE FUNCTION public.usp_sys_mensaje_markread(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "Sys_Mensajes" SET "Leido" = TRUE WHERE "Id" = p_id;
END;
$function$
;

-- usp_sys_meta_relations
CREATE OR REPLACE FUNCTION public.usp_sys_meta_relations()
 RETURNS TABLE("fkName" character varying, "parentSchema" character varying, "parentTable" character varying, "parentColumn" character varying, "refSchema" character varying, "refTable" character varying, "refColumn" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        tc.constraint_name::TEXT                   AS "fkName",
        kcu.table_schema::TEXT                     AS "parentSchema",
        kcu.table_name::TEXT                       AS "parentTable",
        kcu.column_name::TEXT                      AS "parentColumn",
        ccu.table_schema::TEXT                     AS "refSchema",
        ccu.table_name::TEXT                       AS "refTable",
        ccu.column_name::TEXT                      AS "refColumn"
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON kcu.constraint_name = tc.constraint_name
     AND kcu.constraint_schema = tc.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
    ORDER BY kcu.table_schema, kcu.table_name;
END;
$function$
;

-- usp_sys_meta_tablesandcolumns_columns
CREATE OR REPLACE FUNCTION public.usp_sys_meta_tablesandcolumns_columns()
 RETURNS TABLE(schema character varying, "table" character varying, "column" character varying, type character varying, nullable character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        table_schema::TEXT,
        table_name::TEXT,
        column_name::TEXT,
        data_type::TEXT,
        is_nullable::TEXT
    FROM information_schema.columns
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY table_schema, table_name, ordinal_position;
END;
$function$
;

-- usp_sys_meta_tablesandcolumns_tables
CREATE OR REPLACE FUNCTION public.usp_sys_meta_tablesandcolumns_tables()
 RETURNS TABLE(schema character varying, "table" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT table_schema::TEXT, table_name::TEXT
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
      AND table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY table_schema, table_name;
END;
$function$
;

-- usp_sys_metadata_columns
CREATE OR REPLACE FUNCTION public.usp_sys_metadata_columns()
 RETURNS TABLE("TABLE_SCHEMA" character varying, "TABLE_NAME" character varying, "COLUMN_NAME" character varying, "DATA_TYPE" character varying, "IS_NULLABLE" character varying, is_identity integer, is_computed integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c.table_schema::VARCHAR, c.table_name::VARCHAR, c.column_name::VARCHAR,
        c.data_type::VARCHAR, c.is_nullable::VARCHAR,
        CASE WHEN c.column_default LIKE 'nextval%' THEN 1 ELSE 0 END,
        CASE WHEN c.is_generated = 'ALWAYS' THEN 1 ELSE 0 END
    FROM information_schema.columns c
    WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY c.table_schema, c.table_name, c.ordinal_position;
END;
$function$
;

-- usp_sys_metadata_primarykeys
CREATE OR REPLACE FUNCTION public.usp_sys_metadata_primarykeys()
 RETURNS TABLE("TABLE_SCHEMA" character varying, "TABLE_NAME" character varying, "COLUMN_NAME" character varying, "ORDINAL_POSITION" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        ku.table_schema::VARCHAR, ku.table_name::VARCHAR,
        ku.column_name::VARCHAR, ku.ordinal_position::INT
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage ku
      ON tc.constraint_name = ku.constraint_name
      AND tc.table_schema = ku.table_schema
      AND tc.table_name = ku.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
    ORDER BY ku.table_schema, ku.table_name, ku.ordinal_position;
END;
$function$
;

-- usp_sys_metadata_tables
CREATE OR REPLACE FUNCTION public.usp_sys_metadata_tables()
 RETURNS TABLE("TABLE_SCHEMA" character varying, "TABLE_NAME" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t.table_schema::VARCHAR, t.table_name::VARCHAR
    FROM information_schema.tables t
    WHERE t.table_type = 'BASE TABLE'
      AND t.table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY t.table_schema, t.table_name;
END;
$function$
;

-- usp_sys_notificacion_list
CREATE OR REPLACE FUNCTION public.usp_sys_notificacion_list(p_usuario_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" integer, "Tipo" character varying, "Titulo" character varying, "Mensaje" character varying, "Leido" boolean, "FechaCreacion" timestamp without time zone, "RutaNavegacion" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT n."Id", n."Tipo", n."Titulo", n."Mensaje",
           n."Leido", n."FechaCreacion", n."RutaNavegacion"
    FROM "Sys_Notificaciones" n
    WHERE n."UsuarioId" IS NULL OR n."UsuarioId" = p_usuario_id
    ORDER BY n."FechaCreacion" DESC
    LIMIT 50;
END;
$function$
;

-- usp_sys_notificacion_markread
CREATE OR REPLACE FUNCTION public.usp_sys_notificacion_markread(p_ids_csv text)
 RETURNS TABLE("AffectedCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_affected INT;
BEGIN
    UPDATE "Sys_Notificaciones" n
    SET "Leido" = TRUE
    FROM unnest(string_to_array(p_ids_csv, ',')) AS s(val)
    WHERE n."Id" = s.val::INT;

    GET DIAGNOSTICS v_affected = ROW_COUNT;
    RETURN QUERY SELECT v_affected;
END;
$function$
;

-- usp_sys_tarea_list
CREATE OR REPLACE FUNCTION public.usp_sys_tarea_list(p_asignado_a character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" integer, "Titulo" character varying, "Descripcion" character varying, "Progreso" integer, "Color" character varying, "AsignadoA" character varying, "FechaVencimiento" date, "Completado" boolean, "FechaCreacion" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT t."Id", t."Titulo", t."Descripcion", t."Progreso",
           t."Color", t."AsignadoA", t."FechaVencimiento",
           t."Completado", t."FechaCreacion"
    FROM "Sys_Tareas" t
    WHERE (t."AsignadoA" IS NULL OR t."AsignadoA" = p_asignado_a)
      AND t."Completado" = FALSE
    ORDER BY t."FechaCreacion" DESC
    LIMIT 50;
END;
$function$
;

-- usp_sys_tarea_toggle
CREATE OR REPLACE FUNCTION public.usp_sys_tarea_toggle(p_id integer, p_completado boolean, p_progress integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "Sys_Tareas"
    SET "Completado" = p_completado,
        "Progreso"   = p_progress
    WHERE "Id" = p_id;
END;
$function$
;

