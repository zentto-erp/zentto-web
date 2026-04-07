-- +goose Up
-- usp_Master_Generic_List — SP genérico para listar maestros con paginación y búsqueda
-- DROP CASCADE elimina todos los overloads previos (había una versión vieja sin p_company_id)
DROP FUNCTION IF EXISTS usp_master_generic_list CASCADE;

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_master_generic_list(
  p_company_id  integer      DEFAULT NULL,
  p_schema_name varchar(100) DEFAULT 'cfg',
  p_table_name  varchar(100) DEFAULT NULL,
  p_search      varchar(500) DEFAULT NULL,
  p_sort_column varchar(100) DEFAULT NULL,
  p_offset      integer      DEFAULT 0,
  p_limit       integer      DEFAULT 50
)
RETURNS TABLE("JsonRow" jsonb, "TotalCount" bigint)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_schema      text;
  v_table       text;
  v_qualified   text;
  v_where       text := 'TRUE';
  v_sort        text;
  v_search_cond text := '';
  v_company_cond text := '';
  v_count       bigint;
  v_has_company boolean;
BEGIN
  IF p_table_name IS NULL OR p_table_name = '' THEN
    RAISE EXCEPTION 'p_table_name is required';
  END IF;

  -- Sanitizar nombres con quote_ident para prevenir inyección SQL
  v_schema    := quote_ident(lower(COALESCE(p_schema_name, 'cfg')));
  v_table     := quote_ident(p_table_name);
  v_qualified := v_schema || '.' || v_table;

  -- Verificar existencia de la tabla
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = lower(COALESCE(p_schema_name, 'cfg'))
      AND table_name = p_table_name
  ) THEN
    RAISE EXCEPTION 'table_not_found: %.%', p_schema_name, p_table_name;
  END IF;

  -- ¿La tabla tiene columna CompanyId? → filtrar por ella
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = lower(COALESCE(p_schema_name, 'cfg'))
      AND table_name   = p_table_name
      AND column_name  = 'CompanyId'
  ) INTO v_has_company;

  IF v_has_company AND p_company_id IS NOT NULL THEN
    v_company_cond := ' AND "CompanyId" = ' || p_company_id::text;
  END IF;

  -- Búsqueda en columnas de texto
  IF p_search IS NOT NULL AND p_search <> '' THEN
    SELECT string_agg(
      quote_ident(column_name) || ' ILIKE ' || quote_literal('%' || p_search || '%'),
      ' OR '
    )
    INTO v_search_cond
    FROM information_schema.columns
    WHERE table_schema = lower(COALESCE(p_schema_name, 'cfg'))
      AND table_name   = p_table_name
      AND data_type IN ('character varying', 'text', 'character', 'name');

    IF v_search_cond IS NOT NULL AND v_search_cond <> '' THEN
      v_search_cond := ' AND (' || v_search_cond || ')';
    ELSE
      v_search_cond := '';
    END IF;
  END IF;

  -- Validar columna de ordenamiento (previene inyección)
  IF p_sort_column IS NOT NULL AND p_sort_column <> '' AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = lower(COALESCE(p_schema_name, 'cfg'))
      AND table_name  = p_table_name
      AND column_name = p_sort_column
  ) THEN
    v_sort := quote_ident(p_sort_column);
  ELSE
    -- Fallback: primera columna de la tabla
    SELECT quote_ident(column_name)
    INTO v_sort
    FROM information_schema.columns
    WHERE table_schema = lower(COALESCE(p_schema_name, 'cfg'))
      AND table_name   = p_table_name
    ORDER BY ordinal_position
    LIMIT 1;
  END IF;

  -- COUNT total
  EXECUTE 'SELECT COUNT(*) FROM ' || v_qualified ||
          ' WHERE ' || v_where || v_company_cond || v_search_cond
  INTO v_count;

  -- Retornar filas como JSONB + TotalCount en cada fila
  RETURN QUERY EXECUTE
    'SELECT to_jsonb(t.*), ' || v_count || '::bigint' ||
    ' FROM '   || v_qualified || ' t' ||
    ' WHERE '  || v_where || v_company_cond || v_search_cond ||
    ' ORDER BY t.' || v_sort ||
    ' OFFSET ' || COALESCE(p_offset, 0)::text ||
    ' LIMIT '  || LEAST(COALESCE(p_limit, 50), 500)::text;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_master_generic_list CASCADE;
-- +goose StatementEnd
