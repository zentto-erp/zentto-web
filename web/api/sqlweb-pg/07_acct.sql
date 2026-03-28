-- usp_Contabilidad_Ajuste_Crear
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Ajuste_Crear"(date, character varying, character varying, character varying, character varying, jsonb, bigint, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Ajuste_Crear"(p_fecha date, p_tipoajuste character varying, p_referencia character varying DEFAULT NULL::character varying, p_motivo character varying DEFAULT ''::character varying, p_codusuario character varying DEFAULT NULL::character varying, p_detallejson jsonb DEFAULT '[]'::jsonb, OUT p_asientoid bigint, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_NumeroAsiento VARCHAR;
BEGIN
  SELECT * INTO p_AsientoId, v_NumeroAsiento, p_Resultado, p_Mensaje
  FROM public."usp_Contabilidad_Asiento_Crear"(
    p_Fecha,
    p_TipoAjuste,
    p_Referencia,
    p_Motivo,
    'VES',
    1,
    'AJUSTE',
    p_Referencia,
    p_CodUsuario,
    p_DetalleJson
  );
END;
$function$
;

-- usp_Contabilidad_Asiento_Anular
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Anular"(bigint, character varying, character varying, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Anular"(p_asientoid bigint, p_motivo character varying, p_codusuario character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public."Asientos" WHERE "Id" = p_AsientoId) THEN
    p_Resultado := 0;
    p_Mensaje := 'Asiento no encontrado.';
    RETURN;
  END IF;

  UPDATE public."Asientos"
  SET "Estado" = 'ANULADO',
      "Concepto" = LEFT("Concepto" || ' | ANULADO: ' || COALESCE(p_Motivo, ''), 400),
      "FechaActualizacion" = (NOW() AT TIME ZONE 'UTC')
  WHERE "Id" = p_AsientoId;

  p_Resultado := 1;
  p_Mensaje := 'Asiento anulado.';
END;
$function$
;

-- usp_Contabilidad_Asiento_Crear
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Crear"(date, character varying, character varying, character varying, character varying, numeric, character varying, character varying, character varying, jsonb, bigint, character varying, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Crear"(p_fecha date, p_tipoasiento character varying, p_referencia character varying DEFAULT NULL::character varying, p_concepto character varying DEFAULT ''::character varying, p_moneda character varying DEFAULT 'VES'::character varying, p_tasa numeric DEFAULT 1, p_origenmodulo character varying DEFAULT NULL::character varying, p_origendocumento character varying DEFAULT NULL::character varying, p_codusuario character varying DEFAULT NULL::character varying, p_detallejson jsonb DEFAULT '[]'::jsonb, OUT p_asientoid bigint, OUT p_numeroasiento character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_TotalDebe  NUMERIC(18,2);
  v_TotalHaber NUMERIC(18,2);
BEGIN
  -- Validar detalle
  IF jsonb_array_length(p_DetalleJson) = 0 THEN
    p_Resultado := 0;
    p_Mensaje := 'Detalle contable vacio.';
    RETURN;
  END IF;

  SELECT
    COALESCE(SUM((r->>'debe')::NUMERIC), 0),
    COALESCE(SUM((r->>'haber')::NUMERIC), 0)
  INTO v_TotalDebe, v_TotalHaber
  FROM jsonb_array_elements(p_DetalleJson) r;

  IF v_TotalDebe <> v_TotalHaber THEN
    p_Resultado := 0;
    p_Mensaje := 'Asiento no balanceado.';
    RETURN;
  END IF;

  INSERT INTO public."Asientos" (
    "Fecha", "Tipo_Asiento", "Concepto", "Referencia", "Estado",
    "Total_Debe", "Total_Haber", "Origen_Modulo", "Cod_Usuario"
  )
  VALUES (
    p_Fecha, p_TipoAsiento, p_Concepto,
    COALESCE(p_OrigenDocumento, p_Referencia),
    'APROBADO', v_TotalDebe, v_TotalHaber,
    p_OrigenModulo, COALESCE(p_CodUsuario, 'API')
  )
  RETURNING "Id" INTO p_AsientoId;

  INSERT INTO public."Asientos_Detalle" (
    "Id_Asiento", "Cod_Cuenta", "Descripcion", "CentroCosto",
    "AuxiliarTipo", "AuxiliarCodigo", "Documento", "Debe", "Haber"
  )
  SELECT
    p_AsientoId,
    r->>'codCuenta',
    NULLIF(r->>'descripcion', ''::character varying),
    NULLIF(r->>'centroCosto', ''::character varying),
    NULLIF(r->>'auxiliarTipo', ''::character varying),
    NULLIF(r->>'auxiliarCodigo', ''::character varying),
    NULLIF(r->>'documento', ''::character varying),
    COALESCE((r->>'debe')::NUMERIC, 0),
    COALESCE((r->>'haber')::NUMERIC, 0)
  FROM jsonb_array_elements(p_DetalleJson) r;

  p_NumeroAsiento := 'LEG-' || LPAD(p_AsientoId::TEXT, 10, '0');
  p_Resultado := 1;
  p_Mensaje := 'Asiento creado correctamente.';
END;
$function$
;

-- usp_Contabilidad_Asiento_Get
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Get"(bigint) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Get"(p_asientoid bigint)
 RETURNS TABLE("AsientoId" bigint, "NumeroAsiento" character varying, "Fecha" date, "TipoAsiento" character varying, "Referencia" character varying, "Concepto" character varying, "Moneda" character varying, "Tasa" numeric, "TotalDebe" numeric, "TotalHaber" numeric, "Estado" character varying, "OrigenModulo" character varying, "CodUsuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    a."Id"::BIGINT,
    ('LEG-' || LPAD(a."Id"::TEXT, 10, '0'))::VARCHAR,
    a."Fecha",
    a."Tipo_Asiento"::VARCHAR,
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    'VES'::VARCHAR,
    1::NUMERIC(18,6),
    a."Total_Debe",
    a."Total_Haber",
    a."Estado"::VARCHAR,
    a."Origen_Modulo"::VARCHAR,
    a."Cod_Usuario"::VARCHAR
  FROM public."Asientos" a
  WHERE a."Id" = p_AsientoId
  LIMIT 1;
END;
$function$
;

-- usp_Contabilidad_Asientos_List
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asientos_List"(date, date, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asientos_List"(p_fechadesde date DEFAULT NULL::date, p_fechahasta date DEFAULT NULL::date, p_tipoasiento character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_origenmodulo character varying DEFAULT NULL::character varying, p_origendocumento character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("AsientoId" bigint, "NumeroAsiento" character varying, "Fecha" date, "TipoAsiento" character varying, "Referencia" character varying, "Concepto" character varying, "Moneda" character varying, "Tasa" numeric, "TotalDebe" numeric, "TotalHaber" numeric, "Estado" character varying, "OrigenModulo" character varying, "CodUsuario" character varying, "TotalCount" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
  v_TotalCount INT;
BEGIN
  SELECT COUNT(1) INTO v_TotalCount
  FROM public."Asientos" a
  WHERE (p_FechaDesde IS NULL OR a."Fecha" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR a."Fecha" <= p_FechaHasta)
    AND (p_TipoAsiento IS NULL OR a."Tipo_Asiento" = p_TipoAsiento)
    AND (p_Estado IS NULL OR a."Estado" = p_Estado)
    AND (p_OrigenModulo IS NULL OR a."Origen_Modulo" = p_OrigenModulo)
    AND (p_OrigenDocumento IS NULL OR a."Referencia" = p_OrigenDocumento);

  RETURN QUERY
  SELECT
    a."Id"::BIGINT                                                                  AS "AsientoId",
    ('LEG-' || LPAD(a."Id"::TEXT, 10, '0'))::VARCHAR                                AS "NumeroAsiento",
    a."Fecha",
    a."Tipo_Asiento"::VARCHAR                                                       AS "TipoAsiento",
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    'VES'::VARCHAR                                                                  AS "Moneda",
    1::NUMERIC(18,6)                                                                AS "Tasa",
    a."Total_Debe"                                                                  AS "TotalDebe",
    a."Total_Haber"                                                                 AS "TotalHaber",
    a."Estado"::VARCHAR,
    a."Origen_Modulo"::VARCHAR                                                      AS "OrigenModulo",
    a."Cod_Usuario"::VARCHAR                                                        AS "CodUsuario",
    v_TotalCount
  FROM public."Asientos" a
  WHERE (p_FechaDesde IS NULL OR a."Fecha" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR a."Fecha" <= p_FechaHasta)
    AND (p_TipoAsiento IS NULL OR a."Tipo_Asiento" = p_TipoAsiento)
    AND (p_Estado IS NULL OR a."Estado" = p_Estado)
    AND (p_OrigenModulo IS NULL OR a."Origen_Modulo" = p_OrigenModulo)
    AND (p_OrigenDocumento IS NULL OR a."Referencia" = p_OrigenDocumento)
  ORDER BY a."Fecha" DESC, a."Id" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$function$
;

-- usp_Contabilidad_Balance_Comprobacion
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_Comprobacion"(date, date) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_Comprobacion"(p_fechadesde date, p_fechahasta date)
 RETURNS TABLE("CodCuenta" character varying, "Descripcion" character varying, "Debe" numeric, "Haber" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Debe" - d."Haber")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  LEFT JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  GROUP BY d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$function$
;

-- usp_Contabilidad_Balance_General
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_General"(date) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_General"(p_fechacorte date)
 RETURNS TABLE("Tipo" character, "CodCuenta" character varying, "Descripcion" character varying, "Debe" numeric, "Haber" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    c."Tipo",
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    CASE WHEN c."Tipo" = 'A' THEN SUM(d."Debe" - d."Haber")
         ELSE -SUM(d."Debe" - d."Haber") END
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  INNER JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" <= p_FechaCorte
    AND a."Estado" <> 'ANULADO'
    AND c."Tipo" IN ('A','P','C')
  GROUP BY c."Tipo", d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$function$
;

-- usp_Contabilidad_Depreciacion_Generar
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Depreciacion_Generar"(character varying, character varying, character varying, integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Depreciacion_Generar"(p_periodo character varying, p_codusuario character varying DEFAULT NULL::character varying, p_centrocosto character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje character varying)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
  p_Resultado := 1;
  p_Mensaje := 'Proceso de depreciacion preparado (sin reglas cargadas).';
END;
$function$
;

-- usp_Contabilidad_Estado_Resultados
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Estado_Resultados"(date, date) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Estado_Resultados"(p_fechadesde date, p_fechahasta date)
 RETURNS TABLE("Tipo" character, "CodCuenta" character varying, "Descripcion" character varying, "Debe" numeric, "Haber" numeric, "SaldoResultado" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    c."Tipo",
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Haber" - d."Debe")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  INNER JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
    AND c."Tipo" IN ('I','G')
  GROUP BY c."Tipo", d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$function$
;

-- usp_Contabilidad_Libro_Mayor
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Libro_Mayor"(date, date) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Libro_Mayor"(p_fechadesde date, p_fechahasta date)
 RETURNS TABLE("CodCuenta" character varying, "Descripcion" character varying, "Debe" numeric, "Haber" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    d."Cod_Cuenta"::VARCHAR,
    c."Desc_Cta"::VARCHAR,
    SUM(d."Debe"),
    SUM(d."Haber"),
    SUM(d."Debe" - d."Haber")
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  LEFT JOIN public."Cuentas" c ON c."Cod_Cuenta" = d."Cod_Cuenta"
  WHERE a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  GROUP BY d."Cod_Cuenta", c."Desc_Cta"
  ORDER BY d."Cod_Cuenta";
END;
$function$
;

-- usp_Contabilidad_Mayor_Analitico
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Mayor_Analitico"(character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Mayor_Analitico"(p_codcuenta character varying, p_fechadesde date, p_fechahasta date)
 RETURNS TABLE("AsientoId" integer, "Fecha" date, "Referencia" character varying, "Concepto" character varying, "Descripcion" character varying, "Debe" numeric, "Haber" numeric, "SaldoAcumulado" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    a."Id",
    a."Fecha",
    a."Referencia"::VARCHAR,
    a."Concepto"::VARCHAR,
    d."Descripcion"::VARCHAR,
    d."Debe",
    d."Haber",
    SUM(d."Debe" - d."Haber") OVER (ORDER BY a."Fecha", a."Id", d."Id" ROWS UNBOUNDED PRECEDING)
  FROM public."Asientos_Detalle" d
  INNER JOIN public."Asientos" a ON a."Id" = d."Id_Asiento"
  WHERE d."Cod_Cuenta" = p_CodCuenta
    AND a."Fecha" BETWEEN p_FechaDesde AND p_FechaHasta
    AND a."Estado" <> 'ANULADO'
  ORDER BY a."Fecha", a."Id", d."Id";
END;
$function$
;

-- usp_acct_account_delete
DROP FUNCTION IF EXISTS public.usp_acct_account_delete(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_delete(p_company_id integer, p_account_code character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_account_id INT;
BEGIN
    SELECT "AccountId" INTO v_account_id
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id
      AND "AccountCode" = p_account_code
      AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT 0, 'No se encontro la cuenta con codigo ' || p_account_code || ' o ya fue eliminada.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "ParentAccountId" = v_account_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'No se puede eliminar: la cuenta tiene cuentas hijas activas.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "AccountId" = v_account_id
          AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' eliminada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al eliminar cuenta: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_account_exists
DROP FUNCTION IF EXISTS public.usp_acct_account_exists(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_exists(p_company_id integer, p_account_code character varying)
 RETURNS TABLE(ok integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND TRIM("AccountCode") = TRIM(p_account_code)
          AND "IsDeleted" = FALSE
    ) THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_acct_account_get
DROP FUNCTION IF EXISTS public.usp_acct_account_get(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_get(p_company_id integer, p_account_code character varying)
 RETURNS SETOF acct."Account"
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM   acct."Account"
    WHERE  "CompanyId"   = p_company_id
      AND  "AccountCode" = p_account_code
      AND  "IsDeleted"   = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_acct_account_insert
DROP FUNCTION IF EXISTS public.usp_acct_account_insert(integer, character varying, character varying, character varying, integer, integer, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_insert(p_company_id integer, p_account_code character varying, p_account_name character varying, p_account_type character varying DEFAULT 'A'::character varying, p_account_level integer DEFAULT NULL::integer, p_parent_account_id integer DEFAULT NULL::integer, p_allows_posting boolean DEFAULT true)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_level    INT := p_account_level;
    v_parent   INT := p_parent_account_id;
    v_parent_code VARCHAR(20);
BEGIN
    -- Validar que no exista duplicado
    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Ya existe una cuenta con el codigo ' || p_account_code || ' para esta empresa.';
        RETURN;
    END IF;

    -- Auto-resolver nivel desde AccountCode si no se proporciono
    IF v_level IS NULL OR v_level < 1 THEN
        v_level := LENGTH(p_account_code) - LENGTH(REPLACE(p_account_code, '.', '')) + 1;
        IF v_level < 1 THEN v_level := 1; END IF;
    END IF;

    -- Auto-resolver cuenta padre desde AccountCode si no se proporciono
    IF v_parent IS NULL AND POSITION('.' IN p_account_code) > 0 THEN
        v_parent_code := LEFT(p_account_code,
            LENGTH(p_account_code) - POSITION('.' IN REVERSE(p_account_code)));

        SELECT "AccountId" INTO v_parent
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = v_parent_code
          AND "IsDeleted" = FALSE
        LIMIT 1;

        IF v_parent IS NULL THEN
            RETURN QUERY SELECT 0, 'Cuenta padre ' || v_parent_code || ' no encontrada.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."Account" (
            "CompanyId", "AccountCode", "AccountName", "AccountType",
            "AccountLevel", "ParentAccountId", "AllowsPosting",
            "RequiresAuxiliary", "IsActive",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        VALUES (
            p_company_id, p_account_code, p_account_name, p_account_type,
            v_level, v_parent, p_allows_posting,
            FALSE, TRUE,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        );

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' creada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al insertar cuenta: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_account_list
DROP FUNCTION IF EXISTS public.usp_acct_account_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_list(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_grupo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("AccountId" integer, "AccountCode" character varying, "AccountName" character varying, "AccountType" character varying, "AccountLevel" integer, "AllowsPosting" boolean, "IsActive" boolean, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   acct."Account"
    WHERE  "CompanyId" = p_company_id
      AND  "IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR "AccountCode" LIKE '%' || p_search || '%'
            OR "AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR "AccountType" = p_tipo)
      AND  (p_grupo IS NULL OR "AccountCode" LIKE p_grupo || '%');

    RETURN QUERY
    SELECT a."AccountId",
           a."AccountCode",
           a."AccountName",
           a."AccountType",
           a."AccountLevel",
           a."AllowsPosting",
           a."IsActive",
           v_total
    FROM   acct."Account" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR a."AccountCode" LIKE '%' || p_search || '%'
            OR a."AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR a."AccountType" = p_tipo)
      AND  (p_grupo IS NULL OR a."AccountCode" LIKE p_grupo || '%')
    ORDER BY a."AccountCode"
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$function$
;

-- usp_acct_account_update
DROP FUNCTION IF EXISTS public.usp_acct_account_update(integer, character varying, character varying, character varying, integer, boolean) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_account_update(p_company_id integer, p_account_code character varying, p_account_name character varying DEFAULT NULL::character varying, p_account_type character varying DEFAULT NULL::character varying, p_account_level integer DEFAULT NULL::integer, p_allows_posting boolean DEFAULT NULL::boolean)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'No se encontro la cuenta con codigo ' || p_account_code || '.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "AccountName"   = COALESCE(p_account_name,   "AccountName"),
            "AccountType"   = COALESCE(p_account_type,   "AccountType"),
            "AccountLevel"  = COALESCE(p_account_level,  "AccountLevel"),
            "AllowsPosting" = COALESCE(p_allows_posting, "AllowsPosting"),
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"   = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted"   = FALSE;

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' actualizada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al actualizar cuenta: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_accountmonetaryclass_autoclassify
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_autoclassify(integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_autoclassify(p_company_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_processed INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    INSERT INTO acct."AccountMonetaryClass" (
        "CompanyId", "AccountId", "Classification", "SubClassification"
    )
    SELECT a."CompanyId",
           a."AccountId",
           CASE
               WHEN a."AccountType" = 'A' AND (
                   a."AccountCode" LIKE '1.1.01%' OR
                   a."AccountCode" LIKE '1.1.02%' OR
                   a."AccountCode" LIKE '1.1.03%' OR
                   a."AccountCode" LIKE '1.1.04%' OR
                   a."AccountCode" LIKE '1.1.05%' OR
                   a."AccountCode" LIKE '1.1.06%' OR
                   a."AccountName" ILIKE '%caja%' OR
                   a."AccountName" ILIKE '%banco%' OR
                   a."AccountName" ILIKE '%cobrar%'
               ) THEN 'MONETARY'
               WHEN a."AccountType" = 'A' AND (
                   a."AccountCode" LIKE '1.1.07%' OR
                   a."AccountCode" LIKE '1.2%' OR
                   a."AccountName" ILIKE '%inventar%' OR
                   a."AccountName" ILIKE '%equipo%' OR
                   a."AccountName" ILIKE '%terreno%' OR
                   a."AccountName" ILIKE '%edificio%' OR
                   a."AccountName" ILIKE '%vehiculo%' OR
                   a."AccountName" ILIKE '%mobiliario%' OR
                   a."AccountName" ILIKE '%intangible%'
               ) THEN 'NON_MONETARY'
               WHEN a."AccountType" = 'P' THEN 'MONETARY'
               WHEN a."AccountType" = 'C' THEN 'NON_MONETARY'
               WHEN a."AccountType" IN ('I', 'G') THEN 'MONETARY'
               ELSE 'MONETARY'
           END,
           CASE
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.01%' OR a."AccountCode" LIKE '1.1.02%' OR a."AccountName" ILIKE '%caja%' OR a."AccountName" ILIKE '%banco%') THEN 'CASH'
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.04%' OR a."AccountName" ILIKE '%cobrar%') THEN 'RECEIVABLE'
               WHEN a."AccountType" = 'A' AND (a."AccountCode" LIKE '1.1.07%' OR a."AccountName" ILIKE '%inventar%') THEN 'INVENTORY'
               WHEN a."AccountType" = 'A' AND a."AccountCode" LIKE '1.2%' THEN 'FIXED_ASSET'
               WHEN a."AccountType" = 'P' AND (a."AccountName" ILIKE '%pagar%' OR a."AccountName" ILIKE '%proveedor%') THEN 'PAYABLE'
               WHEN a."AccountType" = 'C' THEN 'EQUITY'
               ELSE NULL
           END
    FROM acct."Account" a
    WHERE a."CompanyId"     = p_company_id
      AND a."AllowsPosting" = TRUE
      AND a."IsActive"      = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND NOT EXISTS (
              SELECT 1 FROM acct."AccountMonetaryClass" mc
              WHERE mc."CompanyId" = p_company_id AND mc."AccountId" = a."AccountId"
          );

    GET DIAGNOSTICS v_processed = ROW_COUNT;

    p_resultado := 1;
    p_mensaje   := 'Auto-clasificacion completada: ' || v_processed::TEXT || ' cuentas clasificadas.';
END;
$function$
;

-- usp_acct_accountmonetaryclass_list
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_list(integer, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_list(p_company_id integer, p_classification character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying)
 RETURNS TABLE(p_total_count bigint, "AccountMonetaryClassId" integer, "AccountId" bigint, "AccountCode" character varying, "AccountName" character varying, "AccountType" character, "AccountLevel" smallint, "AllowsPosting" boolean, "Classification" character varying, "SubClassification" character varying, "ReexpressionAccountId" bigint, "IsActive" boolean, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()          AS p_total_count,
           mc."AccountMonetaryClassId",
           a."AccountId",
           a."AccountCode",
           a."AccountName",
           a."AccountType",
           a."AccountLevel",
           a."AllowsPosting",
           mc."Classification",
           mc."SubClassification",
           mc."ReexpressionAccountId",
           mc."IsActive",
           mc."UpdatedAt"
    FROM acct."AccountMonetaryClass" mc
    JOIN acct."Account" a ON a."AccountId" = mc."AccountId" AND a."CompanyId" = mc."CompanyId"
    WHERE mc."CompanyId" = p_company_id
      AND mc."IsActive"  = TRUE
      AND (p_classification IS NULL OR mc."Classification" = p_classification)
      AND (p_search IS NULL
           OR a."AccountCode" LIKE '%' || p_search || '%'
           OR a."AccountName" LIKE '%' || p_search || '%')
    ORDER BY a."AccountCode";
END;
$function$
;

-- usp_acct_accountmonetaryclass_upsert
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_upsert(integer, bigint, character varying, character varying, bigint, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_accountmonetaryclass_upsert(p_company_id integer, p_account_id bigint, p_classification character varying, p_sub_classification character varying DEFAULT NULL::character varying, p_reexpression_account_id bigint DEFAULT NULL::bigint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_classification NOT IN ('MONETARY', 'NON_MONETARY') THEN
        p_mensaje := 'Clasificacion invalida. Usar MONETARY o NON_MONETARY.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "AccountId" = p_account_id AND "CompanyId" = p_company_id
    ) THEN
        p_mensaje := 'Cuenta contable no encontrada.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."AccountMonetaryClass"
        WHERE "CompanyId" = p_company_id AND "AccountId" = p_account_id
    ) THEN
        UPDATE acct."AccountMonetaryClass"
        SET "Classification"       = p_classification,
            "SubClassification"    = p_sub_classification,
            "ReexpressionAccountId" = p_reexpression_account_id,
            "UpdatedAt"            = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId" = p_company_id AND "AccountId" = p_account_id;
    ELSE
        INSERT INTO acct."AccountMonetaryClass" (
            "CompanyId", "AccountId", "Classification", "SubClassification", "ReexpressionAccountId"
        )
        VALUES (p_company_id, p_account_id, p_classification, p_sub_classification, p_reexpression_account_id);
    END IF;

    p_resultado := 1;
    p_mensaje   := 'Clasificacion guardada correctamente.';
END;
$function$
;

-- usp_acct_budget_delete
DROP FUNCTION IF EXISTS public.usp_acct_budget_delete(integer, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_delete(p_company_id integer, p_budget_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."Budget"
        WHERE "CompanyId" = p_company_id AND "BudgetId" = p_budget_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Presupuesto no encontrado.';
        RETURN;
    END IF;

    UPDATE acct."Budget"
    SET "IsDeleted" = TRUE,
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "BudgetId" = p_budget_id;

    p_resultado := 1;
    p_mensaje   := 'Presupuesto eliminado exitosamente.';
END;
$function$
;

-- usp_acct_budget_get
DROP FUNCTION IF EXISTS public.usp_acct_budget_get(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_get(p_company_id integer, p_budget_id integer)
 RETURNS TABLE("BudgetId" integer, "BudgetName" character varying, "FiscalYear" smallint, "CostCenterCode" character varying, "Status" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "BudgetId",
           "BudgetName",
           "FiscalYear",
           "CostCenterCode",
           "Status",
           "Notes",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."Budget"
    WHERE "CompanyId" = p_company_id
      AND "BudgetId"  = p_budget_id
      AND "IsDeleted" = FALSE;
END;
$function$
;

-- usp_acct_budget_getlines
DROP FUNCTION IF EXISTS public.usp_acct_budget_getlines(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_getlines(p_budget_id integer)
 RETURNS TABLE("BudgetLineId" bigint, "AccountCode" character varying, "AccountName" character varying, "Month01" numeric, "Month02" numeric, "Month03" numeric, "Month04" numeric, "Month05" numeric, "Month06" numeric, "Month07" numeric, "Month08" numeric, "Month09" numeric, "Month10" numeric, "Month11" numeric, "Month12" numeric, "AnnualTotal" numeric, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT bl."BudgetLineId",
           bl."AccountCode",
           a."AccountName",
           bl."Month01", bl."Month02", bl."Month03", bl."Month04",
           bl."Month05", bl."Month06", bl."Month07", bl."Month08",
           bl."Month09", bl."Month10", bl."Month11", bl."Month12",
           bl."AnnualTotal",
           bl."Notes"
    FROM acct."BudgetLine" bl
    LEFT JOIN acct."Account" a ON a."AccountCode" = bl."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE bl."BudgetId" = p_budget_id
    ORDER BY bl."AccountCode";
END;
$function$
;

-- usp_acct_budget_insert
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(integer, character varying, smallint, character varying, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_insert(p_company_id integer, p_name character varying, p_fiscal_year smallint, p_cost_center_code character varying DEFAULT NULL::character varying, p_lines_json text DEFAULT NULL::text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_budget_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        p_mensaje := 'El nombre del presupuesto es obligatorio.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."Budget" ("CompanyId", "BudgetName", "FiscalYear", "CostCenterCode")
        VALUES (p_company_id, p_name, p_fiscal_year, p_cost_center_code)
        RETURNING "BudgetId" INTO v_budget_id;

        INSERT INTO acct."BudgetLine" (
            "BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes"
        )
        SELECT v_budget_id,
               (r->>'accountCode')::VARCHAR(20),
               COALESCE((r->>'month01')::NUMERIC(18,2), 0),
               COALESCE((r->>'month02')::NUMERIC(18,2), 0),
               COALESCE((r->>'month03')::NUMERIC(18,2), 0),
               COALESCE((r->>'month04')::NUMERIC(18,2), 0),
               COALESCE((r->>'month05')::NUMERIC(18,2), 0),
               COALESCE((r->>'month06')::NUMERIC(18,2), 0),
               COALESCE((r->>'month07')::NUMERIC(18,2), 0),
               COALESCE((r->>'month08')::NUMERIC(18,2), 0),
               COALESCE((r->>'month09')::NUMERIC(18,2), 0),
               COALESCE((r->>'month10')::NUMERIC(18,2), 0),
               COALESCE((r->>'month11')::NUMERIC(18,2), 0),
               COALESCE((r->>'month12')::NUMERIC(18,2), 0),
               (r->>'notes')::VARCHAR(200)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Presupuesto creado con ID ' || v_budget_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear presupuesto: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_budget_list
DROP FUNCTION IF EXISTS public.usp_acct_budget_list(integer, smallint, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_list(p_company_id integer, p_fiscal_year smallint DEFAULT NULL::smallint, p_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "BudgetId" integer, "BudgetName" character varying, "FiscalYear" smallint, "CostCenterCode" character varying, "Status" character varying, "Notes" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."Budget"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_fiscal_year IS NULL OR "FiscalYear" = p_fiscal_year)
      AND (p_status      IS NULL OR "Status"     = p_status);

    RETURN QUERY
    SELECT v_total_count,
           "BudgetId",
           "BudgetName",
           "FiscalYear",
           "CostCenterCode",
           "Status",
           "Notes",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."Budget"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_fiscal_year IS NULL OR "FiscalYear" = p_fiscal_year)
      AND (p_status      IS NULL OR "Status"     = p_status)
    ORDER BY "FiscalYear" DESC, "BudgetName"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_budget_update
DROP FUNCTION IF EXISTS public.usp_acct_budget_update(integer, integer, character varying, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_update(p_company_id integer, p_budget_id integer, p_name character varying, p_lines_json text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."Budget"
        WHERE "CompanyId" = p_company_id AND "BudgetId" = p_budget_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Presupuesto no encontrado.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Budget"
        SET "BudgetName" = p_name,
            "UpdatedAt"  = (NOW() AT TIME ZONE 'UTC')
        WHERE "BudgetId" = p_budget_id;

        DELETE FROM acct."BudgetLine" WHERE "BudgetId" = p_budget_id;

        INSERT INTO acct."BudgetLine" (
            "BudgetId", "AccountCode",
            "Month01", "Month02", "Month03", "Month04", "Month05", "Month06",
            "Month07", "Month08", "Month09", "Month10", "Month11", "Month12", "Notes"
        )
        SELECT p_budget_id,
               (r->>'accountCode')::VARCHAR(20),
               COALESCE((r->>'month01')::NUMERIC(18,2), 0),
               COALESCE((r->>'month02')::NUMERIC(18,2), 0),
               COALESCE((r->>'month03')::NUMERIC(18,2), 0),
               COALESCE((r->>'month04')::NUMERIC(18,2), 0),
               COALESCE((r->>'month05')::NUMERIC(18,2), 0),
               COALESCE((r->>'month06')::NUMERIC(18,2), 0),
               COALESCE((r->>'month07')::NUMERIC(18,2), 0),
               COALESCE((r->>'month08')::NUMERIC(18,2), 0),
               COALESCE((r->>'month09')::NUMERIC(18,2), 0),
               COALESCE((r->>'month10')::NUMERIC(18,2), 0),
               COALESCE((r->>'month11')::NUMERIC(18,2), 0),
               COALESCE((r->>'month12')::NUMERIC(18,2), 0),
               (r->>'notes')::VARCHAR(200)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Presupuesto actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar presupuesto: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_budget_variance
DROP FUNCTION IF EXISTS public.usp_acct_budget_variance(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_budget_variance(p_company_id integer, p_budget_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "BudgetAmount" numeric, "ActualAmount" numeric, "Variance" numeric, "VariancePct" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT bl."AccountCode",
           a."AccountName",
           bl."AnnualTotal" AS "BudgetAmount",
           COALESCE(act."ActualAmount", 0) AS "ActualAmount",
           bl."AnnualTotal" - COALESCE(act."ActualAmount", 0) AS "Variance",
           CASE
               WHEN bl."AnnualTotal" = 0 THEN 0
               ELSE ROUND((bl."AnnualTotal" - COALESCE(act."ActualAmount", 0)) / bl."AnnualTotal" * 100, 2)
           END AS "VariancePct"
    FROM acct."BudgetLine" bl
    LEFT JOIN acct."Account" a ON a."AccountCode" = bl."AccountCode"
                               AND a."CompanyId"  = p_company_id
                               AND COALESCE(a."IsDeleted", FALSE) = FALSE
    LEFT JOIN (
        SELECT jel."AccountCodeSnapshot" AS "AccountCode",
               SUM(jel."DebitAmount" - jel."CreditAmount") AS "ActualAmount"
        FROM acct."JournalEntryLine" jel
        JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
        WHERE je."CompanyId"  = p_company_id
          AND je."EntryDate"  >= p_fecha_desde
          AND je."EntryDate"  <= p_fecha_hasta
          AND je."Status"     = 'APPROVED'
          AND je."IsDeleted"  = FALSE
        GROUP BY jel."AccountCodeSnapshot"
    ) act ON act."AccountCode" = bl."AccountCode"
    WHERE bl."BudgetId" = p_budget_id
    ORDER BY bl."AccountCode";
END;
$function$
;

-- usp_acct_costcenter_delete
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_delete(integer, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_delete(p_company_id integer, p_code character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_cc_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "CostCenterId"
    INTO v_cc_id
    FROM acct."CostCenter"
    WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE;

    IF v_cc_id IS NULL THEN
        p_mensaje := 'Centro de costo ' || p_code || ' no encontrado.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "ParentCostCenterId" = v_cc_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'No se puede eliminar: el centro de costo tiene hijos activos.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "CostCenterId" = v_cc_id;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' eliminado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al eliminar centro de costo: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_costcenter_get
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_get(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_get(p_company_id integer, p_cost_center_code character varying)
 RETURNS TABLE("CostCenterId" integer, "CostCenterCode" character varying, "CostCenterName" character varying, "ParentCostCenterId" integer, "ParentCode" character varying, "ParentName" character varying, "Level" smallint, "IsActive" boolean, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."CostCenterId",
           cc."CostCenterCode",
           cc."CostCenterName",
           cc."ParentCostCenterId",
           p."CostCenterCode"  AS "ParentCode",
           p."CostCenterName"  AS "ParentName",
           cc."Level",
           cc."IsActive",
           cc."CreatedAt",
           cc."UpdatedAt"
    FROM acct."CostCenter" cc
    LEFT JOIN acct."CostCenter" p ON p."CostCenterId" = cc."ParentCostCenterId"
    WHERE cc."CompanyId"      = p_company_id
      AND cc."CostCenterCode" = p_cost_center_code
      AND cc."IsDeleted"      = FALSE;
END;
$function$
;

-- usp_acct_costcenter_insert
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_insert(integer, character varying, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_insert(p_company_id integer, p_code character varying, p_name character varying, p_parent_code character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Ya existe un centro de costo con el codigo ' || p_code || '.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level")
        VALUES (p_company_id, p_code, p_name, v_parent_id, v_lvl);

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear centro de costo: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_costcenter_list
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_list(integer, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_list(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "CostCenterId" integer, "CostCenterCode" character varying, "CostCenterName" character varying, "ParentCostCenterId" integer, "Level" smallint, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."CostCenter"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL
           OR "CostCenterCode" ILIKE '%' || p_search || '%'
           OR "CostCenterName" ILIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           "CostCenterId",
           "CostCenterCode",
           "CostCenterName",
           "ParentCostCenterId",
           "Level",
           "IsActive"
    FROM acct."CostCenter"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_search IS NULL
           OR "CostCenterCode" ILIKE '%' || p_search || '%'
           OR "CostCenterName" ILIKE '%' || p_search || '%')
    ORDER BY "CostCenterCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_costcenter_update
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_update(integer, character varying, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_update(p_company_id integer, p_code character varying, p_name character varying, p_parent_code character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Centro de costo ' || p_code || ' no encontrado.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "CostCenterName"     = p_name,
            "ParentCostCenterId" = v_parent_id,
            "Level"              = v_lvl,
            "UpdatedAt"          = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"      = p_company_id
          AND "CostCenterCode" = p_code
          AND "IsDeleted"      = FALSE;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_code || ' actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar centro de costo: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_dashboard_resumen
DROP FUNCTION IF EXISTS public.usp_acct_dashboard_resumen(bigint, bigint, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_dashboard_resumen(p_company_id bigint, p_branch_id bigint, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("totalIngresos" numeric, "totalGastos" numeric, "margenPorcentaje" numeric, "cuentasPorPagar" numeric, "totalAsientos" integer, "totalCuentas" integer, "totalAnulados" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_ingresos   NUMERIC(18,2) := 0;
    v_total_gastos     NUMERIC(18,2) := 0;
    v_cuentas_por_pagar NUMERIC(18,2) := 0;
    v_total_asientos   INT := 0;
    v_total_cuentas    INT := 0;
    v_total_anulados   INT := 0;
BEGIN
    -- Total Ingresos (account type I)
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0) INTO v_total_ingresos
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'I';

    -- Total Gastos (account type G)
    SELECT COALESCE(SUM(jel."DebitAmount" - jel."CreditAmount"), 0) INTO v_total_gastos
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'G';

    -- Cuentas por pagar (account type P, code starts with '2.1')
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0) INTO v_cuentas_por_pagar
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'P' AND a."AccountCode" LIKE '2.1%';

    -- Counts
    SELECT COUNT(*) INTO v_total_asientos
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "EntryDate" >= p_fecha_desde AND "EntryDate" <= p_fecha_hasta
      AND "IsDeleted" = FALSE AND "Status" <> 'VOIDED';

    SELECT COUNT(*) INTO v_total_anulados
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "EntryDate" >= p_fecha_desde AND "EntryDate" <= p_fecha_hasta
      AND "IsDeleted" = FALSE AND "Status" = 'VOIDED';

    SELECT COUNT(*) INTO v_total_cuentas
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    RETURN QUERY
    SELECT
        v_total_ingresos,
        v_total_gastos,
        CASE WHEN v_total_ingresos > 0
             THEN ROUND((v_total_ingresos - v_total_gastos) / v_total_ingresos * 100, 2)
             ELSE 0
        END,
        v_cuentas_por_pagar,
        v_total_asientos,
        v_total_cuentas,
        v_total_anulados;
END;
$function$
;

-- usp_acct_documentlink_upsert
DROP FUNCTION IF EXISTS public.usp_acct_documentlink_upsert(integer, integer, character varying, character varying, character varying, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_documentlink_upsert(p_company_id integer, p_branch_id integer, p_module character varying, p_document_type character varying, p_origin_document character varying, p_journal_entry_id bigint)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF EXISTS (
        SELECT 1 FROM acct."DocumentLink"
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "ModuleCode" = p_module
          AND "DocumentType" = p_document_type
          AND "DocumentNumber" = p_origin_document
    ) THEN
        RETURN QUERY SELECT 0, 'El enlace de documento ya existe.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."DocumentLink" (
            "CompanyId", "BranchId", "ModuleCode", "DocumentType",
            "DocumentNumber", "NativeDocumentId", "JournalEntryId"
        )
        VALUES (
            p_company_id, p_branch_id, p_module, p_document_type,
            p_origin_document, NULL, p_journal_entry_id
        );

        RETURN QUERY SELECT 1, 'Enlace de documento creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al insertar enlace: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_entry_findbyorigin
DROP FUNCTION IF EXISTS public.usp_acct_entry_findbyorigin(integer, integer, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_findbyorigin(p_company_id integer, p_branch_id integer, p_module character varying, p_origin_document character varying)
 RETURNS TABLE("asientoId" bigint, "numeroAsiento" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT je."JournalEntryId" AS "asientoId",
           je."EntryNumber"::VARCHAR    AS "numeroAsiento"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."SourceModule" = p_module
      AND je."SourceDocumentNo" = p_origin_document
      AND je."IsDeleted" = FALSE
    ORDER BY je."JournalEntryId" DESC
    LIMIT 1;
END;
$function$
;

-- usp_acct_entry_get
DROP FUNCTION IF EXISTS public.usp_acct_entry_get(integer, integer, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_get(p_company_id integer, p_branch_id integer, p_asiento_id bigint)
 RETURNS TABLE("asientoId" bigint, "numeroAsiento" character varying, fecha date, "tipoAsiento" character varying, referencia character varying, concepto character varying, moneda character varying, tasa numeric, "totalDebe" numeric, "totalHaber" numeric, estado character varying, "origenModulo" character varying, "origenDocumento" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        je."JournalEntryId"::BIGINT    AS "asientoId",
        je."EntryNumber"::VARCHAR      AS "numeroAsiento",
        je."EntryDate"                 AS "fecha",
        je."EntryType"::VARCHAR        AS "tipoAsiento",
        je."ReferenceNumber"::VARCHAR  AS "referencia",
        je."Concept"::VARCHAR          AS "concepto",
        je."CurrencyCode"::VARCHAR     AS "moneda",
        je."ExchangeRate"              AS "tasa",
        je."TotalDebit"               AS "totalDebe",
        je."TotalCredit"              AS "totalHaber",
        je."Status"::VARCHAR           AS "estado",
        je."SourceModule"::VARCHAR     AS "origenModulo",
        je."SourceDocumentNo"::VARCHAR AS "origenDocumento",
        je."CreatedAt"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."JournalEntryId" = p_asiento_id
      AND je."IsDeleted" = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_acct_entry_getdetail
DROP FUNCTION IF EXISTS public.usp_acct_entry_getdetail(integer, integer, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_getdetail(p_company_id integer, p_branch_id integer, p_asiento_id bigint)
 RETURNS TABLE("detalleId" bigint, renglon integer, "codCuenta" character varying, "nombreCuenta" character varying, descripcion character varying, "centroCosto" character varying, "auxiliarTipo" character varying, "auxiliarCodigo" character varying, documento character varying, debe numeric, haber numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        l."JournalEntryLineId"::BIGINT   AS "detalleId",
        l."LineNumber"                    AS "renglon",
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        a."AccountName"::VARCHAR          AS "nombreCuenta",
        l."Description"::VARCHAR          AS "descripcion",
        l."CostCenterCode"::VARCHAR       AS "centroCosto",
        l."AuxiliaryType"::VARCHAR        AS "auxiliarTipo",
        l."AuxiliaryCode"::VARCHAR        AS "auxiliarCodigo",
        l."SourceDocumentNo"::VARCHAR     AS "documento",
        l."DebitAmount"                   AS "debe",
        l."CreditAmount"                  AS "haber"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."JournalEntryId" = p_asiento_id
    ORDER BY l."LineNumber", l."JournalEntryLineId";
END;
$function$
;

-- usp_acct_entry_insert
DROP FUNCTION IF EXISTS public.usp_acct_entry_insert(integer, integer, character varying, date, character varying, character varying, character varying, character varying, character, numeric, numeric, numeric, character varying, character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_insert(p_company_id integer, p_branch_id integer, p_entry_number character varying, p_entry_date date, p_period_code character varying, p_entry_type character varying, p_reference_number character varying DEFAULT NULL::character varying, p_concept character varying DEFAULT ''::character varying, p_currency_code character DEFAULT 'VES'::bpchar, p_exchange_rate numeric DEFAULT 1.0, p_total_debit numeric DEFAULT 0, p_total_credit numeric DEFAULT 0, p_source_module character varying DEFAULT NULL::character varying, p_source_document_no character varying DEFAULT NULL::character varying, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("AsientoId" bigint, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_asiento_id BIGINT := 0;
    v_missing    TEXT;
    v_elem       JSONB;
    v_idx        INT := 0;
    v_account_id INT;
BEGIN
    -- Validar balance
    IF ABS(p_total_debit - p_total_credit) > 0.005 THEN
        RETURN QUERY SELECT 0::BIGINT, 0,
            'Asiento desbalanceado: debe=' || p_total_debit::TEXT || ' haber=' || p_total_credit::TEXT;
        RETURN;
    END IF;

    -- Validar que el detalle no este vacio
    IF jsonb_array_length(p_detalle_json) = 0 THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Detalle de asiento requerido';
        RETURN;
    END IF;

    -- Verificar que todas las cuentas existen
    SELECT string_agg(elem->>'codCuenta', ', ') INTO v_missing
    FROM jsonb_array_elements(p_detalle_json) elem
    LEFT JOIN acct."Account" a
        ON a."CompanyId" = p_company_id
       AND a."AccountCode" = elem->>'codCuenta'
       AND a."IsDeleted" = FALSE
    WHERE a."AccountId" IS NULL;

    IF v_missing IS NOT NULL AND LENGTH(v_missing) > 0 THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Cuentas no encontradas: ' || v_missing;
        RETURN;
    END IF;

    BEGIN
        -- Insertar cabecera
        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType",
            "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status",
            "SourceModule", "SourceDocumentType", "SourceDocumentNo",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        VALUES (
            p_company_id, p_branch_id, p_entry_number, p_entry_date, p_period_code, p_entry_type,
            p_reference_number, p_concept, p_currency_code, p_exchange_rate,
            p_total_debit, p_total_credit, 'APPROVED',
            p_source_module, p_source_module, p_source_document_no,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        )
        RETURNING "JournalEntryId" INTO v_asiento_id;

        -- Insertar lineas
        v_idx := 0;
        FOR v_elem IN SELECT * FROM jsonb_array_elements(p_detalle_json)
        LOOP
            v_idx := v_idx + 1;

            SELECT a."AccountId" INTO v_account_id
            FROM acct."Account" a
            WHERE a."CompanyId" = p_company_id
              AND a."AccountCode" = v_elem->>'codCuenta'
              AND a."IsDeleted" = FALSE
            LIMIT 1;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount",
                "AuxiliaryType", "AuxiliaryCode", "CostCenterCode", "SourceDocumentNo",
                "CreatedAt", "UpdatedAt"
            )
            VALUES (
                v_asiento_id,
                v_idx,
                v_account_id,
                v_elem->>'codCuenta',
                v_elem->>'descripcion',
                COALESCE((v_elem->>'debe')::NUMERIC(18,2), 0),
                COALESCE((v_elem->>'haber')::NUMERIC(18,2), 0),
                v_elem->>'auxiliarTipo',
                v_elem->>'auxiliarCodigo',
                v_elem->>'centroCosto',
                COALESCE(v_elem->>'documento', p_source_document_no),
                NOW() AT TIME ZONE 'UTC',
                NOW() AT TIME ZONE 'UTC'
            );
        END LOOP;

        RETURN QUERY SELECT v_asiento_id, 1, 'Asiento creado en modelo canonico';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Error creando asiento canonico: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_entry_list
DROP FUNCTION IF EXISTS public.usp_acct_entry_list(integer, integer, date, date, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_list(p_company_id integer, p_branch_id integer, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_tipo_asiento character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_origen_modulo character varying DEFAULT NULL::character varying, p_origen_documento character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("asientoId" bigint, "numeroAsiento" character varying, fecha date, "tipoAsiento" character varying, referencia character varying, concepto character varying, moneda character varying, tasa numeric, "totalDebe" numeric, "totalHaber" numeric, estado character varying, "origenModulo" character varying, "origenDocumento" character varying, "CreatedAt" timestamp without time zone, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND (p_fecha_desde IS NULL OR je."EntryDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR je."EntryDate" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR je."EntryType" = p_tipo_asiento)
      AND (p_estado IS NULL OR je."Status" = p_estado)
      AND (p_origen_modulo IS NULL OR je."SourceModule" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR je."SourceDocumentNo" = p_origen_documento);

    RETURN QUERY
    SELECT
        je."JournalEntryId"::BIGINT    AS "asientoId",
        je."EntryNumber"::VARCHAR      AS "numeroAsiento",
        je."EntryDate"                 AS "fecha",
        je."EntryType"::VARCHAR        AS "tipoAsiento",
        je."ReferenceNumber"::VARCHAR  AS "referencia",
        je."Concept"::VARCHAR          AS "concepto",
        je."CurrencyCode"::VARCHAR     AS "moneda",
        je."ExchangeRate"              AS "tasa",
        je."TotalDebit"               AS "totalDebe",
        je."TotalCredit"              AS "totalHaber",
        je."Status"::VARCHAR           AS "estado",
        je."SourceModule"::VARCHAR     AS "origenModulo",
        je."SourceDocumentNo"::VARCHAR AS "origenDocumento",
        je."CreatedAt",
        v_total                        AS "TotalCount"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND (p_fecha_desde IS NULL OR je."EntryDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR je."EntryDate" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR je."EntryType" = p_tipo_asiento)
      AND (p_estado IS NULL OR je."Status" = p_estado)
      AND (p_origen_modulo IS NULL OR je."SourceModule" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR je."SourceDocumentNo" = p_origen_documento)
    ORDER BY je."EntryDate" DESC, je."JournalEntryId" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$function$
;

-- usp_acct_entry_resolveidbysource
DROP FUNCTION IF EXISTS public.usp_acct_entry_resolveidbysource(integer, integer, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_resolveidbysource(p_company_id integer, p_branch_id integer, p_module character varying, p_origin_document character varying)
 RETURNS TABLE("journalEntryId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT je."JournalEntryId" AS "journalEntryId"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."SourceModule" = p_module
      AND je."SourceDocumentNo" = p_origin_document
      AND je."IsDeleted" = FALSE
    ORDER BY je."JournalEntryId" DESC
    LIMIT 1;
END;
$function$
;

-- usp_acct_entry_reverse
DROP FUNCTION IF EXISTS public.usp_acct_entry_reverse(integer, integer, date, integer, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_reverse(p_company_id integer, p_entry_id integer, p_fecha date, p_user_id integer, p_motivo character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_orig_number   VARCHAR(40);
    v_orig_type     VARCHAR(20);
    v_orig_concept  VARCHAR(400);
    v_orig_currency CHAR(3);
    v_orig_rate     NUMERIC(18,6);
    v_branch_id     INTEGER;
    v_period_fmt    VARCHAR(7);
    v_rev_number    VARCHAR(40);
    v_new_entry_id  BIGINT;
    v_td            NUMERIC(18,2);
    v_tc            NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "EntryNumber", "EntryType", "Concept", "CurrencyCode",
           "ExchangeRate", "BranchId"
    INTO v_orig_number, v_orig_type, v_orig_concept, v_orig_currency,
         v_orig_rate, v_branch_id
    FROM acct."JournalEntry"
    WHERE "CompanyId"      = p_company_id
      AND "JournalEntryId" = p_entry_id
      AND "Status"         = 'APPROVED'
      AND "IsDeleted"      = FALSE;

    IF v_orig_number IS NULL THEN
        p_mensaje := 'Asiento original no encontrado o no esta aprobado.';
        RETURN;
    END IF;

    BEGIN
        v_period_fmt := TO_CHAR(p_fecha, 'YYYY') || '-' || TO_CHAR(p_fecha, 'MM');
        v_rev_number := 'REV-' || v_orig_number;

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_rev_number, p_fecha, v_period_fmt,
            'REV', v_orig_number,
            'REVERSION de ' || v_orig_number || ': ' || COALESCE(p_motivo, ''),
            v_orig_currency, v_orig_rate, 0, 0, 'APPROVED', 'CONTABILIDAD', p_user_id
        )
        RETURNING "JournalEntryId" INTO v_new_entry_id;

        -- Insertar lineas con Debe/Haber invertidos
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount", "CostCenterCode"
        )
        SELECT v_new_entry_id,
               "LineNumber",
               "AccountId",
               "AccountCodeSnapshot",
               'REV: ' || COALESCE("Description", ''),
               "CreditAmount",   -- invertido
               "DebitAmount",    -- invertido
               "CostCenterCode"
        FROM acct."JournalEntryLine"
        WHERE "JournalEntryId" = p_entry_id;

        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_new_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = COALESCE(v_td, 0), "TotalCredit" = COALESCE(v_tc, 0)
        WHERE "JournalEntryId" = v_new_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento de reversion ' || v_rev_number || ' creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al revertir asiento: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_entry_void
DROP FUNCTION IF EXISTS public.usp_acct_entry_void(integer, integer, bigint, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_entry_void(p_company_id integer, p_branch_id integer, p_asiento_id bigint, p_motivo character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_rows INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "JournalEntryId" = p_asiento_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Asiento no encontrado';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."JournalEntry"
        SET "Status"    = 'VOIDED',
            "Concept"   = CONCAT(
                COALESCE("Concept", ''),
                CASE WHEN COALESCE("Concept", '') = '' THEN '' ELSE ' | ' END,
                'ANULADO: ',
                p_motivo
            ),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "JournalEntryId" = p_asiento_id
          AND "IsDeleted" = FALSE;

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows > 0 THEN
            RETURN QUERY SELECT 1, 'Asiento anulado';
        ELSE
            RETURN QUERY SELECT 0, 'Asiento no encontrado';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al anular asiento: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_equitymovement_delete
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_delete(integer, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_delete(integer, bigint, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_delete(p_company_id integer, p_equity_movement_id bigint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."EquityMovement"
        WHERE "EquityMovementId" = p_equity_movement_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Movimiento no encontrado.';
        RETURN;
    END IF;

    DELETE FROM acct."EquityMovement"
    WHERE "EquityMovementId" = p_equity_movement_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento eliminado.';
END;
$function$
;

-- usp_acct_equitymovement_insert
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_insert(integer, integer, smallint, character varying, character varying, date, numeric, bigint, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_insert(p_company_id integer, p_branch_id integer, p_fiscal_year smallint, p_account_code character varying, p_movement_type character varying, p_movement_date date, p_amount numeric, p_journal_entry_id bigint DEFAULT NULL::bigint, p_description character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_account_id   BIGINT;
    v_account_name VARCHAR(200);
    v_new_id       BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Buscar la cuenta patrimonial
    SELECT "AccountId", "AccountName"
    INTO v_account_id, v_account_name
    FROM acct."Account"
    WHERE "CompanyId"   = p_company_id
      AND "AccountCode" = p_account_code
      AND "AccountType" = 'C'
      AND "IsActive"    = TRUE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        p_mensaje := 'Cuenta patrimonial no encontrada: ' || p_account_code;
        RETURN;
    END IF;

    INSERT INTO acct."EquityMovement" (
        "CompanyId", "BranchId", "FiscalYear", "AccountId", "AccountCode", "AccountName",
        "MovementType", "MovementDate", "Amount", "JournalEntryId", "Description"
    )
    VALUES (
        p_company_id, p_branch_id, p_fiscal_year, v_account_id, p_account_code, v_account_name,
        p_movement_type, p_movement_date, p_amount, p_journal_entry_id, p_description
    )
    RETURNING "EquityMovementId" INTO v_new_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento patrimonial registrado. ID: ' || v_new_id::TEXT;
END;
$function$
;

-- usp_acct_equitymovement_list
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_list(integer, integer, smallint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_list(integer, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_list(p_company_id integer, p_branch_id integer, p_fiscal_year smallint)
 RETURNS TABLE(p_total_count bigint, "EquityMovementId" bigint, "AccountId" bigint, "AccountCode" character varying, "AccountName" character varying, "MovementType" character varying, "MovementDate" date, "Amount" numeric, "JournalEntryId" bigint, "Description" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."EquityMovement"
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "FiscalYear" = p_fiscal_year;

    RETURN QUERY
    SELECT v_total_count,
           "EquityMovementId",
           "AccountId",
           "AccountCode",
           "AccountName",
           "MovementType",
           "MovementDate",
           "Amount",
           "JournalEntryId",
           "Description",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."EquityMovement"
    WHERE "CompanyId"  = p_company_id
      AND "BranchId"   = p_branch_id
      AND "FiscalYear" = p_fiscal_year
    ORDER BY "MovementDate", "AccountCode";
END;
$function$
;

-- usp_acct_equitymovement_update
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_update(integer, integer, character varying, date, numeric, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_update(integer, bigint, character varying, date, numeric, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_equitymovement_update(p_company_id integer, p_equity_movement_id bigint, p_movement_type character varying DEFAULT NULL::character varying, p_movement_date date DEFAULT NULL::date, p_amount numeric DEFAULT NULL::numeric, p_description character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."EquityMovement"
        WHERE "EquityMovementId" = p_equity_movement_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Movimiento no encontrado.';
        RETURN;
    END IF;

    UPDATE acct."EquityMovement"
    SET "MovementType" = COALESCE(p_movement_type, "MovementType"),
        "MovementDate" = COALESCE(p_movement_date, "MovementDate"),
        "Amount"       = COALESCE(p_amount, "Amount"),
        "Description"  = COALESCE(p_description, "Description"),
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC')
    WHERE "EquityMovementId" = p_equity_movement_id;

    p_resultado := 1;
    p_mensaje   := 'Movimiento actualizado.';
END;
$function$
;

-- usp_acct_fixedasset_addimprovement
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_addimprovement(integer, bigint, date, character varying, numeric, integer, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_addimprovement(p_company_id integer, p_asset_id bigint, p_improvement_date date, p_description character varying, p_amount numeric, p_additional_life_months integer DEFAULT 0, p_cod_usuario character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "Status"    = 'ACTIVE'
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END IF;

    INSERT INTO acct."FixedAssetImprovement" (
        "AssetId", "ImprovementDate", "Description", "Amount",
        "AdditionalLifeMonths", "CreatedAt", "CreatedBy"
    )
    VALUES (
        p_asset_id, p_improvement_date, p_description, p_amount,
        p_additional_life_months, (NOW() AT TIME ZONE 'UTC'), p_cod_usuario
    );

    UPDATE acct."FixedAsset"
    SET "AcquisitionCost"  = "AcquisitionCost" + p_amount,
        "UsefulLifeMonths" = "UsefulLifeMonths" + p_additional_life_months,
        "UpdatedAt"        = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"        = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Mejora registrada';
END;
$function$
;

-- usp_acct_fixedasset_calculatedepreciation
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_calculatedepreciation(integer, integer, character varying, character varying, boolean, character varying, integer, text, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_calculatedepreciation(p_company_id integer, p_branch_id integer, p_period_code character varying, p_cost_center_code character varying DEFAULT NULL::character varying, p_preview boolean DEFAULT false, p_cod_usuario character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text, OUT p_entries_generated integer)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_start  DATE;
    v_period_end    DATE;
BEGIN
    p_resultado        := 0;
    p_mensaje          := '';
    p_entries_generated := 0;

    v_period_start := CAST(p_period_code || '-01' AS DATE);
    v_period_end   := (DATE_TRUNC('month', v_period_start) + INTERVAL '1 month - 1 day')::DATE;

    -- Tabla temporal para calculo de depreciacion
    CREATE TEMP TABLE _depreciation_calc (
        asset_id              BIGINT,
        asset_code            VARCHAR(40),
        description           VARCHAR(250),
        acquisition_cost      NUMERIC(18,2),
        residual_value        NUMERIC(18,2),
        useful_life_months    INTEGER,
        depreciation_method   VARCHAR(20),
        expense_account_code  VARCHAR(20),
        deprec_account_code   VARCHAR(20),
        previous_accum        NUMERIC(18,2),
        months_depreciated    INTEGER,
        calc_amount           NUMERIC(18,2),
        new_accum             NUMERIC(18,2),
        new_book_value        NUMERIC(18,2)
    ) ON COMMIT DROP;

    -- Insertar activos elegibles
    INSERT INTO _depreciation_calc (
        asset_id, asset_code, description, acquisition_cost, residual_value,
        useful_life_months, depreciation_method, expense_account_code, deprec_account_code,
        previous_accum, months_depreciated, calc_amount, new_accum, new_book_value
    )
    SELECT
        a."AssetId",
        a."AssetCode",
        a."Description",
        a."AcquisitionCost",
        a."ResidualValue",
        a."UsefulLifeMonths",
        a."DepreciationMethod",
        a."ExpenseAccountCode",
        a."DeprecAccountCode",
        COALESCE((SELECT SUM(d."Amount") FROM acct."FixedAssetDepreciation" d WHERE d."AssetId" = a."AssetId"), 0),
        COALESCE((SELECT COUNT(*) FROM acct."FixedAssetDepreciation" d WHERE d."AssetId" = a."AssetId"), 0),
        0, 0, 0
    FROM acct."FixedAsset" a
    WHERE a."CompanyId"          = p_company_id
      AND a."BranchId"           = p_branch_id
      AND a."Status"             = 'ACTIVE'
      AND a."IsDeleted"          = FALSE
      AND a."DepreciationMethod" <> 'NONE'
      AND a."AcquisitionDate"    <= v_period_end
      AND NOT EXISTS (
          SELECT 1 FROM acct."FixedAssetDepreciation" d
          WHERE d."AssetId"   = a."AssetId"
            AND d."PeriodCode" = p_period_code
      )
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code);

    -- STRAIGHT_LINE
    UPDATE _depreciation_calc
    SET calc_amount = ROUND((acquisition_cost - residual_value) / useful_life_months, 2)
    WHERE depreciation_method = 'STRAIGHT_LINE'
      AND useful_life_months > 0;

    -- DOUBLE_DECLINING
    UPDATE _depreciation_calc
    SET calc_amount = ROUND((2.0 / useful_life_months) * (acquisition_cost - previous_accum), 2)
    WHERE depreciation_method = 'DOUBLE_DECLINING'
      AND useful_life_months > 0;

    -- Aplicar tope: no depreciar por debajo del valor residual
    UPDATE _depreciation_calc
    SET calc_amount = acquisition_cost - residual_value - previous_accum
    WHERE previous_accum + calc_amount > acquisition_cost - residual_value;

    -- Eliminar filas donde no hay monto a depreciar
    DELETE FROM _depreciation_calc WHERE calc_amount <= 0;

    -- Calcular nuevos acumulados
    UPDATE _depreciation_calc
    SET new_accum      = previous_accum + calc_amount,
        new_book_value = acquisition_cost - (previous_accum + calc_amount);

    GET DIAGNOSTICS p_entries_generated = ROW_COUNT;

    -- Si es preview, solo retornar sin insertar
    IF p_preview THEN
        -- El caller debe hacer SELECT * FROM _depreciation_calc ORDER BY asset_code
        p_resultado := 1;
        p_mensaje   := 'Preview de depreciacion: ' || p_entries_generated::TEXT || ' asientos';
        RETURN;
    END IF;

    -- Insertar registros de depreciacion
    INSERT INTO acct."FixedAssetDepreciation" (
        "AssetId", "PeriodCode", "DepreciationDate", "Amount",
        "AccumulatedDepreciation", "BookValue", "Status", "CreatedAt"
    )
    SELECT asset_id, p_period_code, v_period_end,
           calc_amount, new_accum, new_book_value,
           'POSTED', (NOW() AT TIME ZONE 'UTC')
    FROM _depreciation_calc;

    GET DIAGNOSTICS p_entries_generated = ROW_COUNT;

    p_resultado := 1;
    p_mensaje   := 'Depreciacion generada: ' || p_entries_generated::TEXT || ' asientos';
END;
$function$
;

-- usp_acct_fixedasset_depreciationhistory
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_depreciationhistory(integer, bigint, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_depreciationhistory(p_company_id integer, p_asset_id bigint, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "DepreciationId" bigint, "AssetId" bigint, "PeriodCode" character varying, "DepreciationDate" date, "Amount" numeric, "AccumulatedDepreciation" numeric, "BookValue" numeric, "JournalEntryId" bigint, "Status" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAssetDepreciation" d
    INNER JOIN acct."FixedAsset" a ON d."AssetId" = a."AssetId"
    WHERE a."CompanyId" = p_company_id
      AND d."AssetId"   = p_asset_id;

    RETURN QUERY
    SELECT v_total_count,
           d."DepreciationId", d."AssetId", d."PeriodCode",
           d."DepreciationDate", d."Amount",
           d."AccumulatedDepreciation", d."BookValue",
           d."JournalEntryId", d."Status", d."CreatedAt"
    FROM acct."FixedAssetDepreciation" d
    INNER JOIN acct."FixedAsset" a ON d."AssetId" = a."AssetId"
    WHERE a."CompanyId" = p_company_id
      AND d."AssetId"   = p_asset_id
    ORDER BY d."PeriodCode" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_fixedasset_dispose
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_dispose(integer, bigint, date, numeric, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_dispose(p_company_id integer, p_asset_id bigint, p_disposal_date date, p_disposal_amount numeric DEFAULT 0, p_disposal_reason character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "Status"    = 'ACTIVE'
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END IF;

    UPDATE acct."FixedAsset"
    SET "Status"         = 'DISPOSED',
        "DisposalDate"   = p_disposal_date,
        "DisposalAmount" = p_disposal_amount,
        "DisposalReason" = p_disposal_reason,
        "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"      = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Activo desincorporado';
END;
$function$
;

-- usp_acct_fixedasset_get
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_get(integer, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_get(p_company_id integer, p_asset_id bigint)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a.*,
           c."CategoryCode",
           c."CategoryName",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId" = a."AssetId"
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost"
               - COALESCE((SELECT SUM(d2."Amount") FROM acct."FixedAssetDepreciation" d2 WHERE d2."AssetId" = a."AssetId"), 0)
               + COALESCE((SELECT SUM(im."Amount") FROM acct."FixedAssetImprovement" im WHERE im."AssetId" = a."AssetId"), 0)
               AS "BookValue"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId" = p_company_id
      AND a."AssetId"   = p_asset_id
      AND a."IsDeleted" = FALSE;
END;
$function$
;

-- usp_acct_fixedasset_insert
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_insert(integer, integer, character varying, character varying, integer, date, numeric, numeric, integer, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, bigint, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_insert(p_company_id integer, p_branch_id integer, p_asset_code character varying, p_description character varying, p_category_id integer, p_acquisition_date date, p_acquisition_cost numeric, p_residual_value numeric DEFAULT 0, p_useful_life_months integer DEFAULT NULL::integer, p_depreciation_method character varying DEFAULT 'STRAIGHT_LINE'::character varying, p_asset_account_code character varying DEFAULT NULL::character varying, p_deprec_account_code character varying DEFAULT NULL::character varying, p_expense_account_code character varying DEFAULT NULL::character varying, p_cost_center_code character varying DEFAULT NULL::character varying, p_location character varying DEFAULT NULL::character varying, p_serial_number character varying DEFAULT NULL::character varying, p_units_capacity integer DEFAULT NULL::integer, p_currency_code character varying DEFAULT 'VES'::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, OUT p_asset_id bigint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_asset_id  := 0;
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetCode" = p_asset_code
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'El codigo de activo ya existe en esta empresa';
        RETURN;
    END IF;

    INSERT INTO acct."FixedAsset" (
        "CompanyId", "BranchId", "AssetCode", "Description", "CategoryId",
        "AcquisitionDate", "AcquisitionCost", "ResidualValue", "UsefulLifeMonths",
        "DepreciationMethod", "AssetAccountCode", "DeprecAccountCode", "ExpenseAccountCode",
        "CostCenterCode", "Location", "SerialNumber", "UnitsCapacity",
        "CurrencyCode", "Status", "IsDeleted", "CreatedAt", "CreatedBy"
    )
    VALUES (
        p_company_id, p_branch_id, p_asset_code, p_description, p_category_id,
        p_acquisition_date, p_acquisition_cost, p_residual_value, p_useful_life_months,
        p_depreciation_method, p_asset_account_code, p_deprec_account_code, p_expense_account_code,
        p_cost_center_code, p_location, p_serial_number, p_units_capacity,
        p_currency_code, 'ACTIVE', FALSE, (NOW() AT TIME ZONE 'UTC'), p_cod_usuario
    )
    RETURNING "AssetId" INTO p_asset_id;

    p_resultado := 1;
    p_mensaje   := 'Activo fijo registrado';
END;
$function$
;

-- usp_acct_fixedasset_list
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_list(integer, integer, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_list(p_company_id integer, p_branch_id integer DEFAULT NULL::integer, p_category_code character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_cost_center_code character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "AssetId" bigint, "AssetCode" character varying, "Description" character varying, "BranchId" integer, "CategoryId" integer, "CategoryCode" character varying, "CategoryName" character varying, "AcquisitionDate" date, "AcquisitionCost" numeric, "ResidualValue" numeric, "UsefulLifeMonths" integer, "DepreciationMethod" character varying, "Status" character varying, "CostCenterCode" character varying, "Location" character varying, "SerialNumber" character varying, "CurrencyCode" character varying, "AccumulatedDepreciation" numeric, "BookValue" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsDeleted"  = FALSE
      AND (p_branch_id        IS NULL OR a."BranchId"       = p_branch_id)
      AND (p_category_code    IS NULL OR c."CategoryCode"   = p_category_code)
      AND (p_status           IS NULL OR a."Status"         = p_status)
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code)
      AND (p_search IS NULL
           OR a."AssetCode"   LIKE '%' || p_search || '%'
           OR a."Description" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           a."AssetId", a."AssetCode", a."Description",
           a."BranchId",
           c."CategoryId", c."CategoryCode", c."CategoryName",
           a."AcquisitionDate", a."AcquisitionCost", a."ResidualValue",
           a."UsefulLifeMonths", a."DepreciationMethod",
           a."Status", a."CostCenterCode", a."Location",
           a."SerialNumber", a."CurrencyCode",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId" = a."AssetId"
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost"
               - COALESCE((SELECT SUM(d2."Amount") FROM acct."FixedAssetDepreciation" d2 WHERE d2."AssetId" = a."AssetId"), 0)
               + COALESCE((SELECT SUM(im."Amount") FROM acct."FixedAssetImprovement" im WHERE im."AssetId" = a."AssetId"), 0)
               AS "BookValue"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsDeleted"  = FALSE
      AND (p_branch_id        IS NULL OR a."BranchId"       = p_branch_id)
      AND (p_category_code    IS NULL OR c."CategoryCode"   = p_category_code)
      AND (p_status           IS NULL OR a."Status"         = p_status)
      AND (p_cost_center_code IS NULL OR a."CostCenterCode" = p_cost_center_code)
      AND (p_search IS NULL
           OR a."AssetCode"   LIKE '%' || p_search || '%'
           OR a."Description" LIKE '%' || p_search || '%')
    ORDER BY a."AssetCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_fixedasset_report_book
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_book(integer, integer, date, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_book(p_company_id integer, p_branch_id integer, p_fecha_corte date, p_category_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("AssetCode" character varying, "Description" character varying, "CategoryName" character varying, "AcquisitionDate" date, "AcquisitionCost" numeric, "AccumulatedDepreciation" numeric, "BookValue" numeric, "Status" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."AssetCode",
           a."Description",
           c."CategoryName",
           a."AcquisitionDate",
           a."AcquisitionCost",
           COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId"          = a."AssetId"
                 AND d."DepreciationDate" <= p_fecha_corte
           ), 0) AS "AccumulatedDepreciation",
           a."AcquisitionCost" - COALESCE((
               SELECT SUM(d."Amount")
               FROM acct."FixedAssetDepreciation" d
               WHERE d."AssetId"          = a."AssetId"
                 AND d."DepreciationDate" <= p_fecha_corte
           ), 0) AS "BookValue",
           a."Status"
    FROM acct."FixedAsset" a
    INNER JOIN acct."FixedAssetCategory" c ON a."CategoryId" = c."CategoryId"
    WHERE a."CompanyId"       = p_company_id
      AND a."BranchId"        = p_branch_id
      AND a."IsDeleted"       = FALSE
      AND a."AcquisitionDate" <= p_fecha_corte
      AND a."Status"          IN ('ACTIVE', 'FULLY_DEPRECIATED')
      AND (p_category_code IS NULL OR c."CategoryCode" = p_category_code)
    ORDER BY c."CategoryName", a."AssetCode";
END;
$function$
;

-- usp_acct_fixedasset_report_bycategory
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_bycategory(integer, integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_bycategory(p_company_id integer, p_branch_id integer, p_fecha_corte date)
 RETURNS TABLE("CategoryCode" character varying, "CategoryName" character varying, "AssetCount" bigint, "TotalAcquisitionCost" numeric, "TotalAccumulatedDepreciation" numeric, "TotalBookValue" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH asset_deprec AS (
        SELECT a."AssetId",
               a."CategoryId",
               a."AcquisitionCost",
               COALESCE((
                   SELECT SUM(d."Amount")
                   FROM acct."FixedAssetDepreciation" d
                   WHERE d."AssetId"          = a."AssetId"
                     AND d."DepreciationDate" <= p_fecha_corte
               ), 0) AS accum_depreciation
        FROM acct."FixedAsset" a
        WHERE a."CompanyId"       = p_company_id
          AND a."BranchId"        = p_branch_id
          AND a."IsDeleted"       = FALSE
          AND a."AcquisitionDate" <= p_fecha_corte
    )
    SELECT c."CategoryCode",
           c."CategoryName",
           COUNT(ad."AssetId")                              AS "AssetCount",
           SUM(ad."AcquisitionCost")                       AS "TotalAcquisitionCost",
           SUM(ad.accum_depreciation)                      AS "TotalAccumulatedDepreciation",
           SUM(ad."AcquisitionCost" - ad.accum_depreciation) AS "TotalBookValue"
    FROM asset_deprec ad
    INNER JOIN acct."FixedAssetCategory" c ON ad."CategoryId" = c."CategoryId"
    GROUP BY c."CategoryCode", c."CategoryName"
    ORDER BY c."CategoryCode";
END;
$function$
;

-- usp_acct_fixedasset_report_depreciationschedule
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_depreciationschedule(integer, bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_report_depreciationschedule(p_company_id integer, p_asset_id bigint)
 RETURNS TABLE("AssetCode" character varying, "Description" character varying, "MonthNumber" integer, "PeriodCode" character varying, "DepreciationDate" date, "MonthlyAmount" numeric, "AccumulatedDepreciation" numeric, "BookValue" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_acquisition_date    DATE;
    v_acquisition_cost    NUMERIC(18,2);
    v_residual_value      NUMERIC(18,2);
    v_useful_life_months  INTEGER;
    v_depreciation_method VARCHAR(20);
    v_asset_code          VARCHAR(40);
    v_description         VARCHAR(250);
    v_monthly_amount      NUMERIC(18,2);
    v_depreciable_base    NUMERIC(18,2);
BEGIN
    SELECT "AcquisitionDate", "AcquisitionCost", "ResidualValue",
           "UsefulLifeMonths", "DepreciationMethod", "AssetCode", "Description"
    INTO v_acquisition_date, v_acquisition_cost, v_residual_value,
         v_useful_life_months, v_depreciation_method, v_asset_code, v_description
    FROM acct."FixedAsset"
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    IF v_acquisition_date IS NULL THEN
        RETURN;
    END IF;

    v_depreciable_base := v_acquisition_cost - v_residual_value;

    -- For STRAIGHT_LINE: constant monthly amount
    IF v_depreciation_method = 'STRAIGHT_LINE' AND v_useful_life_months > 0 THEN
        v_monthly_amount := ROUND(v_depreciable_base / v_useful_life_months, 2);
    ELSE
        v_monthly_amount := 0;
    END IF;

    RETURN QUERY
    WITH months AS (
        SELECT generate_series(1, v_useful_life_months) AS n
    )
    SELECT v_asset_code,
           v_description,
           m.n AS "MonthNumber",
           TO_CHAR(v_acquisition_date + (m.n || ' month')::INTERVAL, 'YYYY-MM') AS "PeriodCode",
           (v_acquisition_date + (m.n || ' month')::INTERVAL)::DATE AS "DepreciationDate",
           CASE
               WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                   GREATEST(0, LEAST(v_monthly_amount,
                       v_depreciable_base - (v_monthly_amount * (m.n - 1))
                   ))
               ELSE 0
           END AS "MonthlyAmount",
           LEAST(v_depreciable_base,
               CASE
                   WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                       v_monthly_amount * m.n
                   ELSE 0
               END
           ) AS "AccumulatedDepreciation",
           GREATEST(v_residual_value,
               v_acquisition_cost - LEAST(v_depreciable_base,
                   CASE
                       WHEN v_depreciation_method = 'STRAIGHT_LINE' THEN
                           v_monthly_amount * m.n
                       ELSE 0
                   END
               )
           ) AS "BookValue"
    FROM months m
    ORDER BY m.n;
END;
$function$
;

-- usp_acct_fixedasset_revalue
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_revalue(integer, bigint, date, numeric, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_revalue(p_company_id integer, p_asset_id bigint, p_revaluation_date date, p_index_factor numeric, p_country_code character varying, p_cod_usuario character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_old_cost        NUMERIC(18,2);
    v_old_accum       NUMERIC(18,2);
    v_new_cost        NUMERIC(18,2);
    v_new_accum       NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "AcquisitionCost" INTO v_old_cost
    FROM acct."FixedAsset"
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    IF v_old_cost IS NULL THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado';
        RETURN;
    END IF;

    SELECT COALESCE(SUM("Amount"), 0) INTO v_old_accum
    FROM acct."FixedAssetDepreciation"
    WHERE "AssetId" = p_asset_id;

    v_new_cost  := ROUND(v_old_cost * p_index_factor, 2);
    v_new_accum := ROUND(v_old_accum * p_index_factor, 2);

    INSERT INTO acct."FixedAssetRevaluation" (
        "AssetId", "RevaluationDate",
        "PreviousCost", "NewCost", "PreviousAccumDeprec", "NewAccumDeprec",
        "IndexFactor", "CountryCode", "CreatedBy", "CreatedAt"
    )
    VALUES (
        p_asset_id, p_revaluation_date,
        v_old_cost, v_new_cost, v_old_accum, v_new_accum,
        p_index_factor, p_country_code, p_cod_usuario, (NOW() AT TIME ZONE 'UTC')
    );

    UPDATE acct."FixedAsset"
    SET "AcquisitionCost" = v_new_cost,
        "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"       = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Revaluacion aplicada';
END;
$function$
;

-- usp_acct_fixedasset_update
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_update(integer, bigint, character varying, character varying, character varying, character varying, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedasset_update(p_company_id integer, p_asset_id bigint, p_description character varying DEFAULT NULL::character varying, p_location character varying DEFAULT NULL::character varying, p_serial_number character varying DEFAULT NULL::character varying, p_cost_center_code character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FixedAsset"
        WHERE "CompanyId" = p_company_id
          AND "AssetId"   = p_asset_id
          AND "IsDeleted" = FALSE
    ) THEN
        p_resultado := 0;
        p_mensaje   := 'Activo fijo no encontrado';
        RETURN;
    END IF;

    UPDATE acct."FixedAsset"
    SET "Description"   = COALESCE(p_description,      "Description"),
        "Location"      = COALESCE(p_location,         "Location"),
        "SerialNumber"  = COALESCE(p_serial_number,    "SerialNumber"),
        "CostCenterCode" = COALESCE(p_cost_center_code, "CostCenterCode"),
        "CurrencyCode"  = COALESCE(p_currency_code,    "CurrencyCode"),
        "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC'),
        "UpdatedBy"     = p_cod_usuario
    WHERE "CompanyId" = p_company_id
      AND "AssetId"   = p_asset_id
      AND "IsDeleted" = FALSE;

    p_resultado := 1;
    p_mensaje   := 'Activo fijo actualizado';
END;
$function$
;

-- usp_acct_fixedassetcategory_get
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_get(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_get(p_company_id integer, p_category_code character varying)
 RETURNS SETOF acct."FixedAssetCategory"
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"    = p_company_id
      AND "CategoryCode" = p_category_code
      AND "IsDeleted"    = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_acct_fixedassetcategory_list
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_list(integer, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_list(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "CategoryId" integer, "CategoryCode" character varying, "CategoryName" character varying, "DefaultUsefulLifeMonths" integer, "DefaultDepreciationMethod" character varying, "DefaultResidualPercent" numeric, "DefaultAssetAccountCode" character varying, "DefaultDeprecAccountCode" character varying, "DefaultExpenseAccountCode" character varying, "CountryCode" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"  = p_company_id
      AND "IsDeleted"  = FALSE
      AND (p_search IS NULL
           OR "CategoryCode" LIKE '%' || p_search || '%'
           OR "CategoryName" LIKE '%' || p_search || '%');

    RETURN QUERY
    SELECT v_total_count,
           "CategoryId", "CategoryCode", "CategoryName",
           "DefaultUsefulLifeMonths", "DefaultDepreciationMethod",
           "DefaultResidualPercent",
           "DefaultAssetAccountCode", "DefaultDeprecAccountCode",
           "DefaultExpenseAccountCode", "CountryCode"
    FROM acct."FixedAssetCategory"
    WHERE "CompanyId"  = p_company_id
      AND "IsDeleted"  = FALSE
      AND (p_search IS NULL
           OR "CategoryCode" LIKE '%' || p_search || '%'
           OR "CategoryName" LIKE '%' || p_search || '%')
    ORDER BY "CategoryCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_fixedassetcategory_upsert
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_upsert(integer, character varying, character varying, integer, character varying, numeric, character varying, character varying, character varying, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_fixedassetcategory_upsert(p_company_id integer, p_category_code character varying, p_category_name character varying, p_default_useful_life_months integer, p_default_depreciation_method character varying DEFAULT 'STRAIGHT_LINE'::character varying, p_default_residual_percent numeric DEFAULT 0, p_default_asset_account_code character varying DEFAULT NULL::character varying, p_default_deprec_account_code character varying DEFAULT NULL::character varying, p_default_expense_account_code character varying DEFAULT NULL::character varying, p_country_code character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."FixedAssetCategory"
        WHERE "CompanyId"    = p_company_id
          AND "CategoryCode" = p_category_code
          AND "IsDeleted"    = FALSE
    ) THEN
        UPDATE acct."FixedAssetCategory"
        SET "CategoryName"              = p_category_name,
            "DefaultUsefulLifeMonths"   = p_default_useful_life_months,
            "DefaultDepreciationMethod" = p_default_depreciation_method,
            "DefaultResidualPercent"    = p_default_residual_percent,
            "DefaultAssetAccountCode"   = p_default_asset_account_code,
            "DefaultDeprecAccountCode"  = p_default_deprec_account_code,
            "DefaultExpenseAccountCode" = p_default_expense_account_code,
            "CountryCode"               = p_country_code
        WHERE "CompanyId"    = p_company_id
          AND "CategoryCode" = p_category_code
          AND "IsDeleted"    = FALSE;
    ELSE
        INSERT INTO acct."FixedAssetCategory" (
            "CompanyId", "CategoryCode", "CategoryName",
            "DefaultUsefulLifeMonths", "DefaultDepreciationMethod", "DefaultResidualPercent",
            "DefaultAssetAccountCode", "DefaultDeprecAccountCode", "DefaultExpenseAccountCode",
            "CountryCode", "IsDeleted", "CreatedAt"
        )
        VALUES (
            p_company_id, p_category_code, p_category_name,
            p_default_useful_life_months, p_default_depreciation_method, p_default_residual_percent,
            p_default_asset_account_code, p_default_deprec_account_code, p_default_expense_account_code,
            p_country_code, FALSE, (NOW() AT TIME ZONE 'UTC')
        );
    END IF;

    p_resultado := 1;
    p_mensaje   := 'Categoria guardada';
END;
$function$
;

-- usp_acct_inflation_calculate
DROP FUNCTION IF EXISTS public.usp_acct_inflation_calculate(integer, integer, character, smallint, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflation_calculate(p_company_id integer, p_branch_id integer, p_period_code character, p_fiscal_year smallint, p_user_id integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_base_period    CHAR(6);
    v_base_index     NUMERIC(18,6);
    v_end_index      NUMERIC(18,6);
    v_factor         NUMERIC(18,8);
    v_accum_infl     NUMERIC(18,6);
    v_fecha_corte    DATE;
    v_adj_id         INTEGER;
    v_total_adj      NUMERIC(18,2);
    v_reme           NUMERIC(18,2);
    v_line_count     INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."InflationAdjustment"
        WHERE "CompanyId"  = p_company_id
          AND "BranchId"   = p_branch_id
          AND "PeriodCode" = p_period_code
          AND "Status"     <> 'VOIDED'
    ) THEN
        p_mensaje := 'Ya existe un ajuste para este periodo. Anulelo primero.';
        RETURN;
    END IF;

    v_base_period := CAST(p_fiscal_year AS CHAR(4)) || '01';

    SELECT "IndexValue" INTO v_base_index
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = 'VE'
      AND "IndexName"   = 'INPC'
      AND "PeriodCode"  = v_base_period;

    SELECT "IndexValue" INTO v_end_index
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = 'VE'
      AND "IndexName"   = 'INPC'
      AND "PeriodCode"  = p_period_code;

    IF v_base_index IS NULL THEN
        p_mensaje := 'No se encontro el indice INPC para el periodo base ' || v_base_period;
        RETURN;
    END IF;
    IF v_end_index IS NULL THEN
        p_mensaje := 'No se encontro el indice INPC para el periodo ' || p_period_code;
        RETURN;
    END IF;
    IF v_base_index = 0 THEN
        p_mensaje := 'El indice INPC base no puede ser cero.';
        RETURN;
    END IF;

    v_factor      := v_end_index / v_base_index;
    v_accum_infl  := (v_factor - 1.0) * 100.0;
    v_fecha_corte := (DATE_TRUNC('month',
        MAKE_DATE(p_fiscal_year, CAST(RIGHT(p_period_code, 2) AS INTEGER), 1))
        + INTERVAL '1 month - 1 day')::DATE;

    BEGIN
        -- Insertar cabecera
        INSERT INTO acct."InflationAdjustment" (
            "CompanyId", "BranchId", "CountryCode", "PeriodCode", "FiscalYear",
            "AdjustmentDate", "BaseIndexValue", "EndIndexValue",
            "AccumulatedInflation", "ReexpressionFactor", "Status", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, 'VE', p_period_code, p_fiscal_year,
            v_fecha_corte, v_base_index, v_end_index,
            v_accum_infl, v_factor, 'DRAFT', p_user_id
        )
        RETURNING "InflationAdjustmentId" INTO v_adj_id;

        -- Calcular saldos historicos y ajustar cuentas no monetarias
        INSERT INTO acct."InflationAdjustmentLine" (
            "InflationAdjustmentId", "AccountId", "AccountCode", "AccountName",
            "Classification", "HistoricalBalance", "ReexpressionFactor",
            "AdjustedBalance", "AdjustmentAmount"
        )
        SELECT v_adj_id,
               a."AccountId",
               a."AccountCode",
               a."AccountName",
               mc."Classification",
               COALESCE(SUM(
                   CASE WHEN a."AccountType" IN ('A','G')
                        THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                        ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                   END
               ), 0),
               CASE WHEN mc."Classification" = 'NON_MONETARY' THEN v_factor ELSE 1.0 END,
               CASE WHEN mc."Classification" = 'NON_MONETARY'
                    THEN ROUND(COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0) * v_factor, 2)
                    ELSE COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0)
               END,
               CASE WHEN mc."Classification" = 'NON_MONETARY'
                    THEN ROUND(COALESCE(SUM(
                         CASE WHEN a."AccountType" IN ('A','G')
                              THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                              ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                         END
                    ), 0) * (v_factor - 1.0), 2)
                    ELSE 0
               END
        FROM acct."Account" a
        JOIN acct."AccountMonetaryClass" mc ON mc."AccountId" = a."AccountId" AND mc."CompanyId" = a."CompanyId"
        LEFT JOIN acct."JournalEntryLine" jl ON jl."AccountId" = a."AccountId"
        LEFT JOIN acct."JournalEntry" je ON je."JournalEntryId" = jl."JournalEntryId"
                                       AND je."CompanyId"       = p_company_id
                                       AND je."Status"          = 'APPROVED'
                                       AND je."EntryDate"       <= v_fecha_corte
        WHERE a."CompanyId"     = p_company_id
          AND a."AllowsPosting" = TRUE
          AND a."IsActive"      = TRUE
          AND mc."IsActive"     = TRUE
        GROUP BY a."AccountId", a."AccountCode", a."AccountName", a."AccountType", mc."Classification"
        HAVING COALESCE(SUM(
            CASE WHEN a."AccountType" IN ('A','G')
                 THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                 ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
            END
        ), 0) <> 0;

        SELECT COALESCE(SUM("AdjustmentAmount"), 0)
        INTO v_total_adj
        FROM acct."InflationAdjustmentLine"
        WHERE "InflationAdjustmentId" = v_adj_id
          AND "Classification"        = 'NON_MONETARY';

        SELECT COUNT(*) INTO v_line_count
        FROM acct."InflationAdjustmentLine"
        WHERE "InflationAdjustmentId" = v_adj_id;

        v_reme := -v_total_adj;

        UPDATE acct."InflationAdjustment"
        SET "TotalAdjustmentAmount" = v_total_adj,
            "TotalMonetaryGainLoss" = v_reme,
            "UpdatedAt"             = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = v_adj_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste calculado. Factor: ' || ROUND(v_factor, 8)::TEXT
                     || ', REME: ' || ROUND(v_reme, 2)::TEXT
                     || ', Lineas: ' || v_line_count::TEXT;
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$function$
;

-- usp_acct_inflation_post
DROP FUNCTION IF EXISTS public.usp_acct_inflation_post(integer, integer, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflation_post(p_company_id integer, p_adjustment_id integer, p_user_id integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status         VARCHAR(20);
    v_period_code    CHAR(6);
    v_adj_date       DATE;
    v_reme           NUMERIC(18,2);
    v_entry_number   VARCHAR(30);
    v_journal_id     BIGINT;
    v_total_debit    NUMERIC(18,2) := 0;
    v_total_credit   NUMERIC(18,2) := 0;
    v_reme_acct_id   BIGINT;
    v_reme_acc_code  VARCHAR(30);
    v_diff           NUMERIC(18,2);
    v_reme_debit     NUMERIC(18,2) := 0;
    v_reme_credit    NUMERIC(18,2) := 0;
    v_branch_id      INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "PeriodCode", "AdjustmentDate", "TotalMonetaryGainLoss", "BranchId"
    INTO v_status, v_period_code, v_adj_date, v_reme, v_branch_id
    FROM acct."InflationAdjustment"
    WHERE "InflationAdjustmentId" = p_adjustment_id
      AND "CompanyId"             = p_company_id;

    IF v_status IS NULL THEN
        p_mensaje := 'Ajuste no encontrado.';
        RETURN;
    END IF;
    IF v_status <> 'DRAFT' THEN
        p_mensaje := 'Solo se pueden publicar ajustes en estado DRAFT. Estado actual: ' || v_status;
        RETURN;
    END IF;

    BEGIN
        v_entry_number := 'AJI-' || TO_CHAR((NOW() AT TIME ZONE 'UTC'), 'YYYYMMDDHHMMSS');

        -- Insertar cabecera de asiento
        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType",
            "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status", "SourceModule",
            "SourceDocumentType", "SourceDocumentNo"
        )
        SELECT "CompanyId", "BranchId", v_entry_number, v_adj_date,
               LEFT(v_period_code, 4) || '-' || RIGHT(v_period_code, 2),
               'AJUSTE_INFLACION', NULL,
               'Ajuste por inflacion periodo ' || v_period_code || ' - BA VEN-NIF 2 / NIC 29',
               'VES', 1.0, 0, 0, 'APPROVED', 'INFLACION', NULL, p_adjustment_id::TEXT
        FROM acct."InflationAdjustment"
        WHERE "InflationAdjustmentId" = p_adjustment_id
        RETURNING "JournalEntryId" INTO v_journal_id;

        -- Insertar lineas de detalle
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount"
        )
        SELECT v_journal_id,
               ROW_NUMBER() OVER (ORDER BY l."AccountCode"),
               l."AccountId",
               l."AccountCode",
               'Ajuste inflacion - ' || l."AccountName",
               CASE WHEN l."AdjustmentAmount" > 0 THEN l."AdjustmentAmount" ELSE 0 END,
               CASE WHEN l."AdjustmentAmount" < 0 THEN ABS(l."AdjustmentAmount") ELSE 0 END
        FROM acct."InflationAdjustmentLine" l
        WHERE l."InflationAdjustmentId" = p_adjustment_id
          AND l."Classification"        = 'NON_MONETARY'
          AND l."AdjustmentAmount"      <> 0;

        SELECT COALESCE(SUM("DebitAmount"), 0), COALESCE(SUM("CreditAmount"), 0)
        INTO v_total_debit, v_total_credit
        FROM acct."JournalEntryLine"
        WHERE "JournalEntryId" = v_journal_id;

        -- Buscar cuenta REME
        SELECT "AccountId", "AccountCode" INTO v_reme_acct_id, v_reme_acc_code
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND ("AccountName" ILIKE '%resultado monetario%'
               OR "AccountName" ILIKE '%REME%'
               OR "AccountCode" LIKE '5.4%')
          AND "AllowsPosting" = TRUE
        LIMIT 1;

        IF v_reme_acct_id IS NOT NULL THEN
            v_diff := v_total_debit - v_total_credit;
            IF v_diff > 0 THEN v_reme_credit := v_diff; END IF;
            IF v_diff < 0 THEN v_reme_debit  := ABS(v_diff); END IF;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount"
            )
            VALUES (
                v_journal_id,
                (SELECT COALESCE(MAX("LineNumber"), 0) + 1 FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_journal_id),
                v_reme_acct_id, v_reme_acc_code,
                'Resultado Monetario del Ejercicio (REME) - NIC 29',
                v_reme_debit, v_reme_credit
            );

            v_total_debit  := v_total_debit  + v_reme_debit;
            v_total_credit := v_total_credit + v_reme_credit;
        END IF;

        UPDATE acct."JournalEntry"
        SET "TotalDebit"  = v_total_debit,
            "TotalCredit" = v_total_credit
        WHERE "JournalEntryId" = v_journal_id;

        UPDATE acct."InflationAdjustment"
        SET "Status"         = 'POSTED',
            "JournalEntryId" = v_journal_id,
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = p_adjustment_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste publicado. Asiento: ' || v_entry_number
                     || ', Debe: ' || ROUND(v_total_debit, 2)::TEXT
                     || ', Haber: ' || ROUND(v_total_credit, 2)::TEXT;
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$function$
;

-- usp_acct_inflation_void
DROP FUNCTION IF EXISTS public.usp_acct_inflation_void(integer, integer, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflation_void(p_company_id integer, p_adjustment_id integer, p_motivo character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status         VARCHAR(20);
    v_journal_id     BIGINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status", "JournalEntryId"
    INTO v_status, v_journal_id
    FROM acct."InflationAdjustment"
    WHERE "InflationAdjustmentId" = p_adjustment_id
      AND "CompanyId"             = p_company_id;

    IF v_status IS NULL THEN
        p_mensaje := 'Ajuste no encontrado.';
        RETURN;
    END IF;

    BEGIN
        IF v_journal_id IS NOT NULL THEN
            UPDATE acct."JournalEntry"
            SET "Status"    = 'VOIDED',
                "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
            WHERE "JournalEntryId" = v_journal_id;
        END IF;

        UPDATE acct."InflationAdjustment"
        SET "Status"    = 'VOIDED',
            "Notes"     = COALESCE("Notes" || ' | ', '') || 'ANULADO: ' || COALESCE(p_motivo, 'Sin motivo'),
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "InflationAdjustmentId" = p_adjustment_id;

        p_resultado := 1;
        p_mensaje   := 'Ajuste anulado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$function$
;

-- usp_acct_inflationindex_bulkload
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_bulkload(integer, character, character varying, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_bulkload(p_company_id integer, p_country_code character, p_index_name character varying, p_json_data text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_processed INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    BEGIN
        INSERT INTO acct."InflationIndex" (
            "CompanyId", "CountryCode", "IndexName", "PeriodCode", "IndexValue", "SourceReference"
        )
        SELECT p_company_id, p_country_code, p_index_name,
               r."periodCode", r."indexValue", r."source"
        FROM json_to_recordset(p_json_data::json) AS r(
            "periodCode" CHAR(6),
            "indexValue" NUMERIC(18,6),
            "source"     VARCHAR(200)
        )
        ON CONFLICT ("CompanyId", "CountryCode", "IndexName", "PeriodCode")
        DO UPDATE SET
            "IndexValue"      = EXCLUDED."IndexValue",
            "SourceReference" = COALESCE(EXCLUDED."SourceReference", acct."InflationIndex"."SourceReference"),
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC');

        GET DIAGNOSTICS v_processed = ROW_COUNT;

        p_resultado := 1;
        p_mensaje   := 'Carga masiva completada: ' || v_processed::TEXT || ' registros procesados.';
    EXCEPTION WHEN OTHERS THEN
        p_mensaje := SQLERRM;
    END;
END;
$function$
;

-- usp_acct_inflationindex_list
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_list(integer, character, character varying, smallint, smallint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_list(p_company_id integer, p_country_code character DEFAULT 'VE'::bpchar, p_index_name character varying DEFAULT 'INPC'::character varying, p_year_from smallint DEFAULT NULL::smallint, p_year_to smallint DEFAULT NULL::smallint)
 RETURNS TABLE(p_total_count bigint, "InflationIndexId" integer, "CountryCode" character, "IndexName" character varying, "PeriodCode" character, "IndexValue" numeric, "SourceReference" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()          AS p_total_count,
           "InflationIndexId",
           "CountryCode",
           "IndexName",
           "PeriodCode",
           "IndexValue",
           "SourceReference",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."InflationIndex"
    WHERE "CompanyId"   = p_company_id
      AND "CountryCode" = p_country_code
      AND "IndexName"   = p_index_name
      AND (p_year_from IS NULL OR CAST(LEFT("PeriodCode", 4) AS SMALLINT) >= p_year_from)
      AND (p_year_to   IS NULL OR CAST(LEFT("PeriodCode", 4) AS SMALLINT) <= p_year_to)
    ORDER BY "PeriodCode";
END;
$function$
;

-- usp_acct_inflationindex_upsert
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_upsert(integer, character, character varying, character, numeric, character varying, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_inflationindex_upsert(p_company_id integer, p_country_code character, p_index_name character varying, p_period_code character, p_index_value numeric, p_source_reference character varying DEFAULT NULL::character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_index_value <= 0 THEN
        p_mensaje := 'El valor del indice debe ser mayor a cero.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."InflationIndex"
        WHERE "CompanyId"   = p_company_id
          AND "CountryCode" = p_country_code
          AND "IndexName"   = p_index_name
          AND "PeriodCode"  = p_period_code
    ) THEN
        UPDATE acct."InflationIndex"
        SET "IndexValue"      = p_index_value,
            "SourceReference" = COALESCE(p_source_reference, "SourceReference"),
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"   = p_company_id
          AND "CountryCode" = p_country_code
          AND "IndexName"   = p_index_name
          AND "PeriodCode"  = p_period_code;

        p_resultado := 1;
        p_mensaje   := 'Indice actualizado correctamente.';
    ELSE
        INSERT INTO acct."InflationIndex" (
            "CompanyId", "CountryCode", "IndexName", "PeriodCode", "IndexValue", "SourceReference"
        )
        VALUES (p_company_id, p_country_code, p_index_name, p_period_code, p_index_value, p_source_reference);

        p_resultado := 1;
        p_mensaje   := 'Indice creado correctamente.';
    END IF;
END;
$function$
;

-- usp_acct_infra_check
DROP FUNCTION IF EXISTS public.usp_acct_infra_check() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_infra_check()
 RETURNS TABLE(ok integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'Account')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'JournalEntry')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'JournalEntryLine')
    THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_acct_period_checklist
DROP FUNCTION IF EXISTS public.usp_acct_period_checklist(integer, character) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_checklist(p_company_id integer, p_period_code character)
 RETURNS TABLE("ItemName" character varying, "ItemCount" integer, "Status" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_fmt  VARCHAR(7);
    v_drafts      INTEGER;
    v_unbalanced  INTEGER;
    v_approved    INTEGER;
    v_bal_diff    NUMERIC(18,2);
BEGIN
    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    -- 1. Asientos en borrador
    SELECT COUNT(*) INTO v_drafts
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'DRAFT' AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Asientos en borrador'::VARCHAR(100),
        v_drafts,
        CASE WHEN v_drafts = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 2. Asientos desbalanceados
    SELECT COUNT(*) INTO v_unbalanced
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'APPROVED' AND "IsDeleted" = FALSE
      AND ABS("TotalDebit" - "TotalCredit") > 0.01;

    RETURN QUERY SELECT
        'Asientos desbalanceados'::VARCHAR(100),
        v_unbalanced,
        CASE WHEN v_unbalanced = 0 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;

    -- 3. Total asientos aprobados
    SELECT COUNT(*) INTO v_approved
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_period_fmt
      AND "Status" = 'APPROVED' AND "IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Asientos aprobados en periodo'::VARCHAR(100),
        v_approved,
        CASE WHEN v_approved > 0 THEN 'OK'::VARCHAR(10) ELSE 'WARNING'::VARCHAR(10) END;

    -- 4. Balance total cuadra
    SELECT ABS(COALESCE(SUM(jel."DebitAmount"), 0) - COALESCE(SUM(jel."CreditAmount"), 0))
    INTO v_bal_diff
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE je."CompanyId" = p_company_id AND je."PeriodCode" = v_period_fmt
      AND je."Status" = 'APPROVED' AND je."IsDeleted" = FALSE;

    RETURN QUERY SELECT
        'Diferencia total debe/haber'::VARCHAR(100),
        COALESCE(v_bal_diff, 0)::INTEGER,
        CASE WHEN COALESCE(v_bal_diff, 0) < 0.01 THEN 'OK'::VARCHAR(10) ELSE 'ERROR'::VARCHAR(10) END;
END;
$function$
;

-- usp_acct_period_close
DROP FUNCTION IF EXISTS public.usp_acct_period_close(integer, character, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_close(p_company_id integer, p_period_code character, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_fmt VARCHAR(7);
    v_draft_count INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."FiscalPeriod"
        WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code AND "Status" = 'OPEN'
    ) THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado o no esta abierto.';
        RETURN;
    END IF;

    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    SELECT COUNT(*) INTO v_draft_count
    FROM acct."JournalEntry"
    WHERE "CompanyId"  = p_company_id
      AND "PeriodCode" = v_period_fmt
      AND "Status"     = 'DRAFT'
      AND "IsDeleted"  = FALSE;

    IF v_draft_count > 0 THEN
        p_mensaje := 'Existen ' || v_draft_count::TEXT
                   || ' asientos en borrador. Apruebelos o eliminelos antes de cerrar.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."FiscalPeriod"
        SET "Status"         = 'CLOSED',
            "ClosedAt"       = (NOW() AT TIME ZONE 'UTC'),
            "ClosedByUserId" = p_user_id,
            "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"  = p_company_id
          AND "PeriodCode" = p_period_code
          AND "Status"     = 'OPEN';

        p_resultado := 1;
        p_mensaje   := 'Periodo ' || p_period_code || ' cerrado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al cerrar periodo: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_period_ensureyear
DROP FUNCTION IF EXISTS public.usp_acct_period_ensureyear(integer, smallint, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_ensureyear(p_company_id integer, p_year smallint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_existing INTEGER;
    m_val      INTEGER;
    v_code     CHAR(6);
    v_start    DATE;
    v_end      DATE;
    v_name     VARCHAR(50);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_year < 2000 OR p_year > 2099 THEN
        p_mensaje := 'Anio fuera de rango valido (2000-2099).';
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_existing
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "YearCode" = p_year;

    IF v_existing = 12 THEN
        p_resultado := 1;
        p_mensaje   := 'Los 12 periodos del anio ' || p_year::TEXT || ' ya existen.';
        RETURN;
    END IF;

    BEGIN
        FOR m_val IN 1..12 LOOP
            v_code  := LPAD(p_year::TEXT, 4, '0') || LPAD(m_val::TEXT, 2, '0');
            v_start := MAKE_DATE(p_year::INTEGER, m_val, 1);
            v_end   := (DATE_TRUNC('month', v_start) + INTERVAL '1 month - 1 day')::DATE;
            v_name  := TO_CHAR(v_start, 'Month') || ' ' || p_year::TEXT;

            IF NOT EXISTS (
                SELECT 1 FROM acct."FiscalPeriod"
                WHERE "CompanyId" = p_company_id AND "PeriodCode" = v_code
            ) THEN
                INSERT INTO acct."FiscalPeriod"
                    ("CompanyId", "PeriodCode", "PeriodName", "YearCode", "MonthCode", "StartDate", "EndDate")
                VALUES
                    (p_company_id, v_code, v_name, p_year, m_val, v_start, v_end);
            END IF;
        END LOOP;

        p_resultado := 1;
        p_mensaje   := 'Periodos del anio ' || p_year::TEXT || ' creados exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear periodos: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_period_generateclosingentries
DROP FUNCTION IF EXISTS public.usp_acct_period_generateclosingentries(integer, character, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_generateclosingentries(p_company_id integer, p_period_code character, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_start_date      DATE;
    v_end_date        DATE;
    v_period_fmt      VARCHAR(7);
    v_seq_num         INTEGER;
    v_entry_number    VARCHAR(40);
    v_branch_id       INTEGER;
    v_entry_id        BIGINT;
    v_line_count      INTEGER;
    v_retained_acct   BIGINT;
    v_net_result      NUMERIC(18,2);
    v_td              NUMERIC(18,2);
    v_tc              NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "StartDate", "EndDate"
    INTO v_start_date, v_end_date
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code;

    IF v_start_date IS NULL THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado.';
        RETURN;
    END IF;

    v_period_fmt := LEFT(p_period_code, 4) || '-' || RIGHT(p_period_code, 2);

    -- Saldos de cuentas I y G en el periodo
    CREATE TEMP TABLE _closing_saldos (
        "AccountId"   BIGINT,
        "AccountCode" VARCHAR(40),
        "AccountType" CHAR(1),
        "Saldo"       NUMERIC(18,2)
    ) ON COMMIT DROP;

    INSERT INTO _closing_saldos ("AccountId", "AccountCode", "AccountType", "Saldo")
    SELECT a."AccountId",
           a."AccountCode",
           a."AccountType",
           SUM(jel."DebitAmount" - jel."CreditAmount")
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."PeriodCode" = v_period_fmt
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountId", a."AccountCode", a."AccountType"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0;

    IF NOT EXISTS (SELECT 1 FROM _closing_saldos) THEN
        p_resultado := 1;
        p_mensaje   := 'No hay saldos de I/G para cerrar en el periodo ' || p_period_code || '.';
        RETURN;
    END IF;

    BEGIN
        SELECT COALESCE(MAX(
            CAST(RIGHT("EntryNumber", 4) AS INTEGER)
        ), 0) + 1
        INTO v_seq_num
        FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id AND "EntryType" = 'CIE' AND "PeriodCode" = v_period_fmt;

        v_entry_number := 'CIE-' || p_period_code || '-' || LPAD(v_seq_num::TEXT, 4, '0');

        SELECT "BranchId" INTO v_branch_id
        FROM cfg."Branch"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
        ORDER BY "BranchId"
        LIMIT 1;

        IF v_branch_id IS NULL THEN v_branch_id := 1; END IF;

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "Concept", "CurrencyCode", "TotalDebit", "TotalCredit",
            "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_entry_number, v_end_date, v_period_fmt,
            'CIE', 'Asiento de cierre - Periodo ' || p_period_code,
            'VES', 0, 0, 'APPROVED', 'CONTABILIDAD', p_user_id
        )
        RETURNING "JournalEntryId" INTO v_entry_id;

        -- Lineas que revierten cada cuenta I/G
        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount"
        )
        SELECT v_entry_id,
               ROW_NUMBER() OVER (ORDER BY "AccountCode"),
               "AccountId",
               "AccountCode",
               'Cierre ' || "AccountCode",
               CASE WHEN "Saldo" < 0 THEN ABS("Saldo") ELSE 0 END,
               CASE WHEN "Saldo" > 0 THEN "Saldo"      ELSE 0 END
        FROM _closing_saldos;

        SELECT COUNT(*) INTO v_line_count FROM _closing_saldos;

        -- Linea contra 3.3.01 utilidades retenidas
        SELECT "AccountId" INTO v_retained_acct
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id AND "AccountCode" = '3.3.01' AND COALESCE("IsDeleted", FALSE) = FALSE
        LIMIT 1;

        IF v_retained_acct IS NULL THEN
            SELECT "AccountId" INTO v_retained_acct
            FROM acct."Account"
            WHERE "CompanyId" = p_company_id AND "AccountCode" LIKE '3.3%'
              AND "AllowsPosting" = TRUE AND COALESCE("IsDeleted", FALSE) = FALSE
            ORDER BY "AccountCode"
            LIMIT 1;
        END IF;

        IF v_retained_acct IS NOT NULL THEN
            SELECT SUM("Saldo") INTO v_net_result FROM _closing_saldos;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount"
            )
            VALUES (
                v_entry_id, v_line_count + 1, v_retained_acct, '3.3.01',
                'Resultado del periodo a utilidades retenidas',
                CASE WHEN v_net_result > 0 THEN v_net_result        ELSE 0 END,
                CASE WHEN v_net_result < 0 THEN ABS(v_net_result)   ELSE 0 END
            );
        END IF;

        -- Actualizar totales del asiento
        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = v_td, "TotalCredit" = v_tc
        WHERE "JournalEntryId" = v_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento de cierre ' || v_entry_number || ' generado con '
                     || (v_line_count + 1)::TEXT || ' lineas.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al generar cierre: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_period_list
DROP FUNCTION IF EXISTS public.usp_acct_period_list(integer, smallint, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_list(p_company_id integer, p_year smallint DEFAULT NULL::smallint, p_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "FiscalPeriodId" integer, "PeriodCode" character, "PeriodName" character varying, "YearCode" smallint, "MonthCode" smallint, "StartDate" date, "EndDate" date, "Status" character varying, "ClosedAt" timestamp without time zone, "ClosedByUserId" integer, "Notes" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id
      AND (p_year   IS NULL OR "YearCode" = p_year)
      AND (p_status IS NULL OR "Status"   = p_status);

    RETURN QUERY
    SELECT v_total_count,
           "FiscalPeriodId",
           "PeriodCode",
           "PeriodName",
           "YearCode",
           "MonthCode",
           "StartDate",
           "EndDate",
           "Status",
           "ClosedAt",
           "ClosedByUserId",
           "Notes"
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id
      AND (p_year   IS NULL OR "YearCode" = p_year)
      AND (p_status IS NULL OR "Status"   = p_status)
    ORDER BY "PeriodCode"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_period_reopen
DROP FUNCTION IF EXISTS public.usp_acct_period_reopen(integer, character, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_period_reopen(p_company_id integer, p_period_code character, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_status VARCHAR(10);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "Status"
    INTO v_current_status
    FROM acct."FiscalPeriod"
    WHERE "CompanyId" = p_company_id AND "PeriodCode" = p_period_code;

    IF v_current_status IS NULL THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no encontrado.';
        RETURN;
    END IF;

    IF v_current_status = 'LOCKED' THEN
        p_mensaje := 'Periodo ' || p_period_code || ' esta bloqueado y no puede reabrirse.';
        RETURN;
    END IF;

    IF v_current_status <> 'CLOSED' THEN
        p_mensaje := 'Periodo ' || p_period_code || ' no esta cerrado (estado actual: ' || v_current_status || ').';
        RETURN;
    END IF;

    UPDATE acct."FiscalPeriod"
    SET "Status"         = 'OPEN',
        "ClosedAt"       = NULL,
        "ClosedByUserId" = NULL,
        "UpdatedAt"      = (NOW() AT TIME ZONE 'UTC')
    WHERE "CompanyId"  = p_company_id
      AND "PeriodCode" = p_period_code
      AND "Status"     = 'CLOSED';

    p_resultado := 1;
    p_mensaje   := 'Periodo ' || p_period_code || ' reabierto exitosamente.';
END;
$function$
;

-- usp_acct_policy_load
DROP FUNCTION IF EXISTS public.usp_acct_policy_load(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_policy_load(p_company_id integer, p_module character varying)
 RETURNS TABLE("Proceso" character varying, "Naturaleza" character varying, "CuentaContable" character varying, "CentroCostoDefault" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."ProcessCode"::VARCHAR                                           AS "Proceso",
        (CASE WHEN p."Nature" = 'DEBIT' THEN 'DEBE' ELSE 'HABER' END)::VARCHAR AS "Naturaleza",
        a."AccountCode"::VARCHAR                                           AS "CuentaContable",
        NULL::VARCHAR(20)                                                   AS "CentroCostoDefault"
    FROM acct."AccountingPolicy" p
    INNER JOIN acct."Account" a ON a."AccountId" = p."AccountId"
    WHERE p."CompanyId" = p_company_id
      AND p."ModuleCode" = p_module
      AND p."IsActive" = TRUE
      AND p."ProcessCode" IN ('VENTA_TOTAL', 'VENTA_TOTAL_CAJA', 'VENTA_TOTAL_BANCO', 'VENTA_BASE', 'VENTA_IVA')
    ORDER BY p."PriorityOrder", p."AccountingPolicyId";
END;
$function$
;

-- usp_acct_pos_getheader
DROP FUNCTION IF EXISTS public.usp_acct_pos_getheader(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_pos_getheader(p_sale_ticket_id integer)
 RETURNS TABLE(id integer, "numFactura" character varying, "fechaVenta" timestamp without time zone, "metodoPago" character varying, "codUsuario" character varying, subtotal numeric, impuestos numeric, total numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId"   AS "id",
        v."InvoiceNumber"::VARCHAR  AS "numFactura",
        v."SoldAt"         AS "fechaVenta",
        v."PaymentMethod"::VARCHAR  AS "metodoPago",
        u."UserCode"::VARCHAR       AS "codUsuario",
        v."NetAmount"      AS "subtotal",
        v."TaxAmount"      AS "impuestos",
        v."TotalAmount"    AS "total"
    FROM pos."SaleTicket" v
    LEFT JOIN sec."User" u ON u."UserId" = v."SoldByUserId"
    WHERE v."SaleTicketId" = p_sale_ticket_id
    LIMIT 1;
END;
$function$
;

-- usp_acct_pos_gettaxsummary
DROP FUNCTION IF EXISTS public.usp_acct_pos_gettaxsummary(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_pos_gettaxsummary(p_sale_ticket_id integer)
 RETURNS TABLE("taxRate" numeric, "baseAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        stl."TaxRate"          AS "taxRate",
        SUM(stl."NetAmount")   AS "baseAmount",
        SUM(stl."TaxAmount")   AS "taxAmount",
        SUM(stl."TotalAmount") AS "totalAmount"
    FROM pos."SaleTicketLine" stl
    WHERE stl."SaleTicketId" = p_sale_ticket_id
    GROUP BY stl."TaxRate";
END;
$function$
;

-- usp_acct_recurringentry_delete
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_delete(integer, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_delete(p_company_id integer, p_recurring_entry_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."RecurringEntry"
        WHERE "CompanyId" = p_company_id AND "RecurringEntryId" = p_recurring_entry_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Plantilla recurrente no encontrada.';
        RETURN;
    END IF;

    UPDATE acct."RecurringEntry"
    SET "IsDeleted" = TRUE,
        "IsActive"  = FALSE
    WHERE "RecurringEntryId" = p_recurring_entry_id;

    p_resultado := 1;
    p_mensaje   := 'Plantilla recurrente eliminada exitosamente.';
END;
$function$
;

-- usp_acct_recurringentry_execute
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_execute(integer, integer, date, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_execute(p_company_id integer, p_recurring_entry_id integer, p_execution_date date, p_user_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_template_name VARCHAR(200);
    v_frequency     VARCHAR(10);
    v_tipo_asiento  VARCHAR(20);
    v_concepto      VARCHAR(300);
    v_max_exec      INTEGER;
    v_times_exec    INTEGER;
    v_is_active     BOOLEAN;
    v_period_fmt    VARCHAR(7);
    v_branch_id     INTEGER;
    v_seq_num       INTEGER;
    v_entry_number  VARCHAR(40);
    v_entry_id      BIGINT;
    v_td            NUMERIC(18,2);
    v_tc            NUMERIC(18,2);
    v_next_date     DATE;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "TemplateName", "Frequency", "TipoAsiento", "Concepto",
           "MaxExecutions", "TimesExecuted", "IsActive"
    INTO v_template_name, v_frequency, v_tipo_asiento, v_concepto,
         v_max_exec, v_times_exec, v_is_active
    FROM acct."RecurringEntry"
    WHERE "CompanyId" = p_company_id AND "RecurringEntryId" = p_recurring_entry_id AND "IsDeleted" = FALSE;

    IF v_template_name IS NULL THEN
        p_mensaje := 'Plantilla recurrente no encontrada.';
        RETURN;
    END IF;

    IF NOT v_is_active THEN
        p_mensaje := 'La plantilla esta inactiva.';
        RETURN;
    END IF;

    IF v_max_exec IS NOT NULL AND v_times_exec >= v_max_exec THEN
        p_mensaje := 'La plantilla alcanzo el maximo de ejecuciones (' || v_max_exec::TEXT || ').';
        RETURN;
    END IF;

    BEGIN
        v_period_fmt := TO_CHAR(p_execution_date, 'YYYY') || '-' || TO_CHAR(p_execution_date, 'MM');

        SELECT "BranchId" INTO v_branch_id
        FROM cfg."Branch"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
        ORDER BY "BranchId"
        LIMIT 1;
        IF v_branch_id IS NULL THEN v_branch_id := 1; END IF;

        SELECT COALESCE(MAX(
            CAST(RIGHT("EntryNumber", 6) AS INTEGER)
        ), 0) + 1
        INTO v_seq_num
        FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id AND "EntryType" = v_tipo_asiento AND "PeriodCode" = v_period_fmt;

        v_entry_number := v_tipo_asiento || '-'
            || REPLACE(v_period_fmt, '-', '') || '-'
            || LPAD(v_seq_num::TEXT, 6, '0');

        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode",
            "EntryType", "Concept", "CurrencyCode", "TotalDebit", "TotalCredit",
            "Status", "SourceModule", "CreatedByUserId"
        )
        VALUES (
            p_company_id, v_branch_id, v_entry_number, p_execution_date, v_period_fmt,
            v_tipo_asiento, v_concepto || ' [Recurrente: ' || v_template_name || ']',
            'VES', 0, 0, 'APPROVED', 'RECURRENTE', p_user_id
        )
        RETURNING "JournalEntryId" INTO v_entry_id;

        INSERT INTO acct."JournalEntryLine" (
            "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
            "Description", "DebitAmount", "CreditAmount", "CostCenterCode"
        )
        SELECT v_entry_id,
               ROW_NUMBER() OVER (ORDER BY rel."LineId"),
               a."AccountId",
               rel."AccountCode",
               rel."Description",
               rel."Debit",
               rel."Credit",
               rel."CostCenterCode"
        FROM acct."RecurringEntryLine" rel
        JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode"
                              AND a."CompanyId"  = p_company_id
                              AND COALESCE(a."IsDeleted", FALSE) = FALSE
        WHERE rel."RecurringEntryId" = p_recurring_entry_id;

        SELECT SUM("DebitAmount"), SUM("CreditAmount")
        INTO v_td, v_tc
        FROM acct."JournalEntryLine" WHERE "JournalEntryId" = v_entry_id;

        UPDATE acct."JournalEntry"
        SET "TotalDebit" = COALESCE(v_td, 0), "TotalCredit" = COALESCE(v_tc, 0)
        WHERE "JournalEntryId" = v_entry_id;

        -- Calcular siguiente fecha de ejecucion
        v_next_date := CASE v_frequency
            WHEN 'DAILY'     THEN p_execution_date + INTERVAL '1 day'
            WHEN 'WEEKLY'    THEN p_execution_date + INTERVAL '1 week'
            WHEN 'MONTHLY'   THEN p_execution_date + INTERVAL '1 month'
            WHEN 'QUARTERLY' THEN p_execution_date + INTERVAL '3 months'
            WHEN 'YEARLY'    THEN p_execution_date + INTERVAL '1 year'
            ELSE p_execution_date + INTERVAL '1 month'
        END;

        UPDATE acct."RecurringEntry"
        SET "NextExecutionDate" = v_next_date,
            "LastExecutedDate"  = p_execution_date,
            "TimesExecuted"     = "TimesExecuted" + 1,
            "IsActive"          = CASE
                WHEN "MaxExecutions" IS NOT NULL AND "TimesExecuted" + 1 >= "MaxExecutions" THEN FALSE
                ELSE TRUE
            END
        WHERE "RecurringEntryId" = p_recurring_entry_id;

        p_resultado := 1;
        p_mensaje   := 'Asiento ' || v_entry_number || ' generado desde plantilla recurrente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al ejecutar recurrente: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_recurringentry_get
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_get(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_get(p_company_id integer, p_recurring_entry_id integer)
 RETURNS TABLE("RecurringEntryId" integer, "TemplateName" character varying, "Frequency" character varying, "NextExecutionDate" date, "LastExecutedDate" date, "TimesExecuted" integer, "MaxExecutions" integer, "TipoAsiento" character varying, "Concepto" character varying, "IsActive" boolean, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "RecurringEntryId",
           "TemplateName",
           "Frequency",
           "NextExecutionDate",
           "LastExecutedDate",
           "TimesExecuted",
           "MaxExecutions",
           "TipoAsiento",
           "Concepto",
           "IsActive",
           "CreatedAt"
    FROM acct."RecurringEntry"
    WHERE "CompanyId"        = p_company_id
      AND "RecurringEntryId" = p_recurring_entry_id
      AND "IsDeleted"        = FALSE;
END;
$function$
;

-- usp_acct_recurringentry_getdue
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getdue(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getdue(p_company_id integer)
 RETURNS TABLE("RecurringEntryId" integer, "TemplateName" character varying, "Frequency" character varying, "NextExecutionDate" date, "LastExecutedDate" date, "TimesExecuted" integer, "MaxExecutions" integer, "TipoAsiento" character varying, "Concepto" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "RecurringEntryId",
           "TemplateName",
           "Frequency",
           "NextExecutionDate",
           "LastExecutedDate",
           "TimesExecuted",
           "MaxExecutions",
           "TipoAsiento",
           "Concepto"
    FROM acct."RecurringEntry"
    WHERE "CompanyId"          = p_company_id
      AND "IsActive"           = TRUE
      AND "IsDeleted"          = FALSE
      AND "NextExecutionDate" <= (NOW() AT TIME ZONE 'UTC')::DATE
      AND ("MaxExecutions" IS NULL OR "TimesExecuted" < "MaxExecutions")
    ORDER BY "NextExecutionDate";
END;
$function$
;

-- usp_acct_recurringentry_getlines
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getlines(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_getlines(p_recurring_entry_id integer)
 RETURNS TABLE("LineId" integer, "AccountCode" character varying, "AccountName" character varying, "Description" character varying, "CostCenterCode" character varying, "Debit" numeric, "Credit" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT rel."LineId",
           rel."AccountCode",
           a."AccountName",
           rel."Description",
           rel."CostCenterCode",
           rel."Debit",
           rel."Credit"
    FROM acct."RecurringEntryLine" rel
    LEFT JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE rel."RecurringEntryId" = p_recurring_entry_id
    ORDER BY rel."LineId";
END;
$function$
;

-- usp_acct_recurringentry_insert
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_insert(integer, character varying, character varying, date, character varying, character varying, integer, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_insert(p_company_id integer, p_template_name character varying, p_frequency character varying, p_next_execution_date date, p_tipo_asiento character varying, p_concepto character varying, p_max_executions integer DEFAULT NULL::integer, p_lines_json text DEFAULT NULL::text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_re_id     INTEGER;
    v_sum_debit NUMERIC(18,2);
    v_sum_credit NUMERIC(18,2);
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_template_name IS NULL OR LENGTH(TRIM(p_template_name)) = 0 THEN
        p_mensaje := 'El nombre de la plantilla es obligatorio.';
        RETURN;
    END IF;

    -- Validar que debito = credito en las lineas
    SELECT COALESCE(SUM((r->>'debit')::NUMERIC(18,2)), 0),
           COALESCE(SUM((r->>'credit')::NUMERIC(18,2)), 0)
    INTO v_sum_debit, v_sum_credit
    FROM json_array_elements(p_lines_json::json) AS r;

    IF ABS(COALESCE(v_sum_debit, 0) - COALESCE(v_sum_credit, 0)) > 0.01 THEN
        p_mensaje := 'Las lineas no estan balanceadas (Debe=' || v_sum_debit::TEXT
                   || ', Haber=' || v_sum_credit::TEXT || ').';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."RecurringEntry" (
            "CompanyId", "TemplateName", "Frequency", "NextExecutionDate",
            "MaxExecutions", "TipoAsiento", "Concepto"
        )
        VALUES (
            p_company_id, p_template_name, p_frequency, p_next_execution_date,
            p_max_executions, p_tipo_asiento, p_concepto
        )
        RETURNING "RecurringEntryId" INTO v_re_id;

        INSERT INTO acct."RecurringEntryLine" (
            "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
        )
        SELECT v_re_id,
               (r->>'accountCode')::VARCHAR(20),
               (r->>'description')::VARCHAR(200),
               (r->>'costCenterCode')::VARCHAR(20),
               COALESCE((r->>'debit')::NUMERIC(18,2), 0),
               COALESCE((r->>'credit')::NUMERIC(18,2), 0)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente creada con ID ' || v_re_id::TEXT || '.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear plantilla recurrente: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_recurringentry_list
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_list(integer, boolean, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_list(p_company_id integer, p_is_active boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "RecurringEntryId" integer, "TemplateName" character varying, "Frequency" character varying, "NextExecutionDate" date, "LastExecutedDate" date, "TimesExecuted" integer, "MaxExecutions" integer, "TipoAsiento" character varying, "Concepto" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_count BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."RecurringEntry"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_is_active IS NULL OR "IsActive" = p_is_active);

    RETURN QUERY
    SELECT v_total_count,
           "RecurringEntryId",
           "TemplateName",
           "Frequency",
           "NextExecutionDate",
           "LastExecutedDate",
           "TimesExecuted",
           "MaxExecutions",
           "TipoAsiento",
           "Concepto",
           "IsActive"
    FROM acct."RecurringEntry"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE
      AND (p_is_active IS NULL OR "IsActive" = p_is_active)
    ORDER BY "NextExecutionDate"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_recurringentry_update
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_update(integer, integer, character varying, character varying, date, character varying, integer, text, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_recurringentry_update(p_company_id integer, p_recurring_entry_id integer, p_template_name character varying, p_frequency character varying, p_next_execution_date date, p_concepto character varying, p_max_executions integer DEFAULT NULL::integer, p_lines_json text DEFAULT NULL::text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."RecurringEntry"
        WHERE "CompanyId" = p_company_id AND "RecurringEntryId" = p_recurring_entry_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Plantilla recurrente no encontrada.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."RecurringEntry"
        SET "TemplateName"      = p_template_name,
            "Frequency"         = p_frequency,
            "NextExecutionDate" = p_next_execution_date,
            "Concepto"          = p_concepto,
            "MaxExecutions"     = p_max_executions
        WHERE "RecurringEntryId" = p_recurring_entry_id;

        DELETE FROM acct."RecurringEntryLine" WHERE "RecurringEntryId" = p_recurring_entry_id;

        INSERT INTO acct."RecurringEntryLine" (
            "RecurringEntryId", "AccountCode", "Description", "CostCenterCode", "Debit", "Credit"
        )
        SELECT p_recurring_entry_id,
               (r->>'accountCode')::VARCHAR(20),
               (r->>'description')::VARCHAR(200),
               (r->>'costCenterCode')::VARCHAR(20),
               COALESCE((r->>'debit')::NUMERIC(18,2), 0),
               COALESCE((r->>'credit')::NUMERIC(18,2), 0)
        FROM json_array_elements(p_lines_json::json) AS r;

        p_resultado := 1;
        p_mensaje   := 'Plantilla recurrente actualizada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar plantilla: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_acct_report_agingcxc
DROP FUNCTION IF EXISTS public.usp_acct_report_agingcxc(integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_agingcxc(p_company_id integer, p_fecha_corte date)
 RETURNS TABLE("EntityCode" character varying, "EntityType" character varying, "Current_0_30" numeric, "Days_31_60" numeric, "Days_61_90" numeric, "Days_90_Plus" numeric, "Total" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT jel."AuxiliaryCode" AS "EntityCode",
           jel."AuxiliaryType" AS "EntityType",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 0  AND 30  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Current_0_30",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 31 AND 60  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_31_60",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 61 AND 90  THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_61_90",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") > 90               THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END) AS "Days_90_Plus",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Total"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND (a."AccountCode" LIKE '1.2%' OR (a."AccountType" = 'A' AND a."AccountCode" LIKE '1.1.2%'))
    GROUP BY jel."AuxiliaryCode", jel."AuxiliaryType"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0
    ORDER BY SUM(jel."DebitAmount" - jel."CreditAmount") DESC;
END;
$function$
;

-- usp_acct_report_agingcxp
DROP FUNCTION IF EXISTS public.usp_acct_report_agingcxp(integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_agingcxp(p_company_id integer, p_fecha_corte date)
 RETURNS TABLE("EntityCode" character varying, "EntityType" character varying, "Current_0_30" numeric, "Days_31_60" numeric, "Days_61_90" numeric, "Days_90_Plus" numeric, "Total" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT jel."AuxiliaryCode" AS "EntityCode",
           jel."AuxiliaryType" AS "EntityType",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 0  AND 30  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Current_0_30",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 31 AND 60  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_31_60",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") BETWEEN 61 AND 90  THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_61_90",
           SUM(CASE WHEN (p_fecha_corte - je."EntryDate") > 90               THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END) AS "Days_90_Plus",
           SUM(jel."CreditAmount" - jel."DebitAmount") AS "Total"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountCode" LIKE '2.1%'
    GROUP BY jel."AuxiliaryCode", jel."AuxiliaryType"
    HAVING SUM(jel."CreditAmount" - jel."DebitAmount") <> 0
    ORDER BY SUM(jel."CreditAmount" - jel."DebitAmount") DESC;
END;
$function$
;

-- usp_acct_report_balancecompmultiperiod
DROP FUNCTION IF EXISTS public.usp_acct_report_balancecompmultiperiod(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_balancecompmultiperiod(p_company_id integer, p_periodos character varying)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "AccountType" character, "PeriodCode" character varying, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_list VARCHAR(7)[];
    v_period_fmt  VARCHAR(7);
    p             TEXT;
BEGIN
    -- Parsear periodos: convertir '202601' a '2026-01'
    v_period_list := ARRAY[]::VARCHAR(7)[];

    FOR p IN
        SELECT TRIM(e) FROM unnest(string_to_array(p_periodos, ',')) AS e
        WHERE LENGTH(TRIM(e)) = 6
    LOOP
        v_period_fmt := LEFT(p, 4) || '-' || RIGHT(p, 2);
        v_period_list := v_period_list || v_period_fmt::VARCHAR(7);
    END LOOP;

    IF array_length(v_period_list, 1) IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           je."PeriodCode",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."PeriodCode" = ANY(v_period_list)
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", je."PeriodCode"
    ORDER BY a."AccountCode", je."PeriodCode";
END;
$function$
;

-- usp_acct_report_balancecomprobacion
DROP FUNCTION IF EXISTS public.usp_acct_report_balancecomprobacion(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_balancecomprobacion(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("codCuenta" character varying, cuenta character varying, "totalDebe" numeric, "totalHaber" numeric, saldo numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        SUM(l."DebitAmount" - l."CreditAmount") AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$function$
;

-- usp_acct_report_balancegeneral
DROP FUNCTION IF EXISTS public.usp_acct_report_balancegeneral(integer, integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_balancegeneral(p_company_id integer, p_branch_id integer, p_fecha_corte date)
 RETURNS TABLE("codCuenta" character varying, cuenta character varying, tipo character varying, "totalDebe" numeric, "totalHaber" numeric, saldo numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        MAX(a."AccountType")::VARCHAR     AS "tipo",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        CASE
            WHEN MAX(a."AccountType") = 'A' THEN SUM(l."DebitAmount" - l."CreditAmount")
            WHEN MAX(a."AccountType") IN ('P','C') THEN SUM(l."CreditAmount" - l."DebitAmount")
            ELSE 0
        END AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND a."AccountType" IN ('A', 'P', 'C')
      AND je."EntryDate" <= p_fecha_corte
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$function$
;

-- usp_acct_report_balancereexpresado
DROP FUNCTION IF EXISTS public.usp_acct_report_balancereexpresado(integer, integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_balancereexpresado(p_company_id integer, p_branch_id integer, p_fecha_corte date)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "AccountType" character, "AccountLevel" smallint, "historicalBalance" numeric, classification character varying, "adjustedBalance" numeric, "adjustmentAmount" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_code CHAR(6);
    v_factor      NUMERIC(18,8) := 1.0;
BEGIN
    v_period_code := TO_CHAR(p_fecha_corte, 'YYYYMM');

    SELECT "ReexpressionFactor" INTO v_factor
    FROM acct."InflationAdjustment"
    WHERE "CompanyId"  = p_company_id
      AND "BranchId"   = p_branch_id
      AND "PeriodCode" <= v_period_code
      AND "Status"     = 'POSTED'
    ORDER BY "PeriodCode" DESC
    LIMIT 1;

    IF v_factor IS NULL THEN v_factor := 1.0; END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           a."AccountLevel",
           COALESCE(SUM(
               CASE WHEN a."AccountType" IN ('A','G')
                    THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                    ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
               END
           ), 0) AS "historicalBalance",
           COALESCE(mc."Classification", 'MONETARY') AS "classification",
           CASE WHEN COALESCE(mc."Classification", 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0) * v_factor, 2)
                ELSE COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0)
           END AS "adjustedBalance",
           CASE WHEN COALESCE(mc."Classification", 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(COALESCE(SUM(
                     CASE WHEN a."AccountType" IN ('A','G')
                          THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
                          ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
                     END
                ), 0) * (v_factor - 1.0), 2)
                ELSE 0
           END AS "adjustmentAmount"
    FROM acct."Account" a
    LEFT JOIN acct."JournalEntryLine" jl ON jl."AccountId" = a."AccountId"
    LEFT JOIN acct."JournalEntry" je ON je."JournalEntryId" = jl."JournalEntryId"
                                   AND je."CompanyId"       = p_company_id
                                   AND je."Status"          = 'APPROVED'
                                   AND je."EntryDate"       <= p_fecha_corte
    LEFT JOIN acct."AccountMonetaryClass" mc ON mc."AccountId" = a."AccountId"
                                            AND mc."CompanyId" = a."CompanyId"
    WHERE a."CompanyId"  = p_company_id
      AND a."IsActive"   = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountType" IN ('A','P','C')
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", a."AccountLevel", mc."Classification"
    HAVING COALESCE(SUM(
        CASE WHEN a."AccountType" IN ('A','G')
             THEN COALESCE(jl."DebitAmount", 0) - COALESCE(jl."CreditAmount", 0)
             ELSE COALESCE(jl."CreditAmount", 0) - COALESCE(jl."DebitAmount", 0)
        END
    ), 0) <> 0
    ORDER BY a."AccountCode";
END;
$function$
;

-- usp_acct_report_cashflow
DROP FUNCTION IF EXISTS public.usp_acct_report_cashflow(integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_cashflow(p_company_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("Category" character varying, "AccountCode" character varying, "AccountName" character varying, "Amount" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE
               WHEN a."AccountType" IN ('I', 'G') THEN 'OPERACION'
               WHEN a."AccountType" = 'A' AND a."AccountLevel" >= 3
                    AND a."AccountCode" LIKE '1.2%' THEN 'INVERSION'
               WHEN a."AccountType" = 'P' AND a."AccountCode" LIKE '2.2%' THEN 'FINANCIAMIENTO'
               WHEN a."AccountType" = 'C' THEN 'FINANCIAMIENTO'
               ELSE 'OPERACION'
           END::VARCHAR(20) AS "Category",
           a."AccountCode",
           a."AccountName",
           SUM(jel."DebitAmount" - jel."CreditAmount") AS "Amount"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY CASE
                 WHEN a."AccountType" IN ('I', 'G') THEN 'OPERACION'
                 WHEN a."AccountType" = 'A' AND a."AccountLevel" >= 3
                      AND a."AccountCode" LIKE '1.2%' THEN 'INVERSION'
                 WHEN a."AccountType" = 'P' AND a."AccountCode" LIKE '2.2%' THEN 'FINANCIAMIENTO'
                 WHEN a."AccountType" = 'C' THEN 'FINANCIAMIENTO'
                 ELSE 'OPERACION'
             END,
             a."AccountCode", a."AccountName"
    HAVING SUM(jel."DebitAmount" - jel."CreditAmount") <> 0
    ORDER BY 1, a."AccountCode";
END;
$function$
;

-- usp_acct_report_drilldown
DROP FUNCTION IF EXISTS public.usp_acct_report_drilldown(integer, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_drilldown(p_company_id integer, p_account_code character varying, p_fecha_desde date, p_fecha_hasta date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "EntryId" bigint, "EntryDate" date, "EntryNumber" character varying, "EntryType" character varying, "Concept" character varying, "Status" character varying, "LineDescription" character varying, "Debit" numeric, "Credit" numeric, "CostCenterCode" character varying, "RunningBalance" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_account_id     BIGINT;
    v_saldo_anterior NUMERIC(18,2);
    v_total_count    BIGINT;
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    SELECT "AccountId" INTO v_account_id
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id AND "AccountCode" = p_account_code AND COALESCE("IsDeleted", FALSE) = FALSE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        v_total_count := 0;
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_total_count
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE;

    -- Saldo anterior al rango
    SELECT COALESCE(SUM(jel."DebitAmount" - jel."CreditAmount"), 0)
    INTO v_saldo_anterior
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  < p_fecha_desde
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE;

    RETURN QUERY
    SELECT v_total_count,
           je."JournalEntryId" AS "EntryId",
           je."EntryDate",
           je."EntryNumber",
           je."EntryType",
           je."Concept",
           je."Status",
           jel."Description" AS "LineDescription",
           jel."DebitAmount"  AS "Debit",
           jel."CreditAmount" AS "Credit",
           jel."CostCenterCode",
           v_saldo_anterior + SUM(jel."DebitAmount" - jel."CreditAmount")
               OVER (ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber"
                     ROWS UNBOUNDED PRECEDING) AS "RunningBalance"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    WHERE jel."AccountId" = v_account_id
      AND je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
    ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber"
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$
;

-- usp_acct_report_equitychanges
DROP FUNCTION IF EXISTS public.usp_acct_report_equitychanges(integer, integer, smallint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_equitychanges(p_company_id integer, p_branch_id integer, p_fiscal_year smallint)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "saldoInicial" numeric, capital numeric, reservas numeric, resultados numeric, dividendos numeric, "ajusteInflacion" numeric, "otrosIntegrales" numeric, "saldoFinal" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           -- Saldo inicial
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" = 'OPENING_BALANCE'
           ), 0) AS "saldoInicial",
           -- Capital
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('CAPITAL_INCREASE','CAPITAL_DECREASE')
           ), 0) AS "capital",
           -- Reservas
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY')
           ), 0) AS "reservas",
           -- Resultados
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT')
           ), 0) AS "resultados",
           -- Dividendos
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('DIVIDEND_CASH','DIVIDEND_STOCK')
           ), 0) AS "dividendos",
           -- Ajuste inflacion
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" IN ('INFLATION_ADJUST','REVALUATION_SURPLUS')
           ), 0) AS "ajusteInflacion",
           -- Otros integrales
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"    = p_company_id
                 AND em."BranchId"     = p_branch_id
                 AND em."AccountCode"  = a."AccountCode"
                 AND em."FiscalYear"   = p_fiscal_year
                 AND em."MovementType" = 'OTHER_COMPREHENSIVE'
           ), 0) AS "otrosIntegrales",
           -- Saldo final
           COALESCE((
               SELECT SUM(em."Amount")
               FROM acct."EquityMovement" em
               WHERE em."CompanyId"   = p_company_id
                 AND em."BranchId"    = p_branch_id
                 AND em."AccountCode" = a."AccountCode"
                 AND em."FiscalYear"  = p_fiscal_year
           ), 0) AS "saldoFinal"
    FROM acct."Account" a
    WHERE a."CompanyId"   = p_company_id
      AND a."AccountType" = 'C'
      AND a."IsActive"    = TRUE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND EXISTS (
              SELECT 1 FROM acct."EquityMovement" em
              WHERE em."CompanyId"   = p_company_id
                AND em."AccountCode" = a."AccountCode"
                AND em."FiscalYear"  = p_fiscal_year
          )
    ORDER BY a."AccountCode";
END;
$function$
;

-- usp_acct_report_equitychanges_totals
DROP FUNCTION IF EXISTS public.usp_acct_report_equitychanges_totals(integer, integer, smallint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_equitychanges_totals(p_company_id integer, p_branch_id integer, p_fiscal_year smallint)
 RETURNS TABLE("totalSaldoInicial" numeric, "totalCapital" numeric, "totalReservas" numeric, "totalResultados" numeric, "totalDividendos" numeric, "totalAjusteInflacion" numeric, "totalOtrosIntegrales" numeric, "totalSaldoFinal" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(CASE WHEN em."MovementType" = 'OPENING_BALANCE' THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('CAPITAL_INCREASE','CAPITAL_DECREASE') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('RESERVE_LEGAL','RESERVE_STATUTORY','RESERVE_VOLUNTARY') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('NET_INCOME','NET_LOSS','RETAINED_EARNINGS','ACCUMULATED_DEFICIT') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('DIVIDEND_CASH','DIVIDEND_STOCK') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" IN ('INFLATION_ADJUST','REVALUATION_SURPLUS') THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN em."MovementType" = 'OTHER_COMPREHENSIVE' THEN em."Amount" ELSE 0 END), 0),
        COALESCE(SUM(em."Amount"), 0)
    FROM acct."EquityMovement" em
    WHERE em."CompanyId" = p_company_id
      AND em."BranchId"  = p_branch_id
      AND em."FiscalYear" = p_fiscal_year;
END;
$function$
;

-- usp_acct_report_estadoresultados
DROP FUNCTION IF EXISTS public.usp_acct_report_estadoresultados(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_estadoresultados(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("codCuenta" character varying, cuenta character varying, tipo character varying, "totalDebe" numeric, "totalHaber" numeric, monto numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        MAX(a."AccountType")::VARCHAR     AS "tipo",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        CASE
            WHEN MAX(a."AccountType") = 'I' THEN SUM(l."CreditAmount" - l."DebitAmount")
            WHEN MAX(a."AccountType") = 'G' THEN SUM(l."DebitAmount" - l."CreditAmount")
            ELSE 0
        END AS "monto"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND a."AccountType" IN ('I', 'G')
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$function$
;

-- usp_acct_report_financialratios
DROP FUNCTION IF EXISTS public.usp_acct_report_financialratios(integer, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_financialratios(p_company_id integer, p_fecha_corte date)
 RETURNS TABLE("RatioName" character varying, "RatioValue" numeric, "Category" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_activo_corriente    NUMERIC(18,2) := 0;
    v_activo_nocorriente  NUMERIC(18,2) := 0;
    v_pasivo_corriente    NUMERIC(18,2) := 0;
    v_pasivo_nocorriente  NUMERIC(18,2) := 0;
    v_patrimonio          NUMERIC(18,2) := 0;
    v_ingresos            NUMERIC(18,2) := 0;
    v_costo_ventas        NUMERIC(18,2) := 0;
    v_gastos              NUMERIC(18,2) := 0;
    v_inventario          NUMERIC(18,2) := 0;
    v_total_pasivo        NUMERIC(18,2);
    v_utilidad_bruta      NUMERIC(18,2);
    v_utilidad_neta       NUMERIC(18,2);
BEGIN
    SELECT
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.1%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.2%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '2.1%'   THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '2.2%'   THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'C'         THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'I'         THEN jel."CreditAmount" - jel."DebitAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '5.1%'   THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountType" = 'G'         THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN a."AccountCode" LIKE '1.1.3%' THEN jel."DebitAmount" - jel."CreditAmount" ELSE 0 END), 0)
    INTO v_activo_corriente, v_activo_nocorriente,
         v_pasivo_corriente, v_pasivo_nocorriente,
         v_patrimonio, v_ingresos, v_costo_ventas, v_gastos, v_inventario
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  <= p_fecha_corte
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE;

    v_total_pasivo   := COALESCE(v_pasivo_corriente, 0) + COALESCE(v_pasivo_nocorriente, 0);
    v_utilidad_bruta := COALESCE(v_ingresos, 0) - COALESCE(v_costo_ventas, 0);
    v_utilidad_neta  := COALESCE(v_ingresos, 0) - COALESCE(v_gastos, 0);

    RETURN QUERY
    SELECT 'CurrentRatio'::VARCHAR(50),
           CASE WHEN COALESCE(v_pasivo_corriente, 0) = 0 THEN 0
                ELSE ROUND(COALESCE(v_activo_corriente, 0) / v_pasivo_corriente, 4)
           END,
           'LIQUIDEZ'::VARCHAR(20)
    UNION ALL
    SELECT 'QuickRatio',
           CASE WHEN COALESCE(v_pasivo_corriente, 0) = 0 THEN 0
                ELSE ROUND((COALESCE(v_activo_corriente, 0) - COALESCE(v_inventario, 0)) / v_pasivo_corriente, 4)
           END,
           'LIQUIDEZ'
    UNION ALL
    SELECT 'DebtToEquity',
           CASE WHEN COALESCE(v_patrimonio, 0) = 0 THEN 0
                ELSE ROUND(v_total_pasivo / v_patrimonio, 4)
           END,
           'APALANCAMIENTO'
    UNION ALL
    SELECT 'GrossMargin',
           CASE WHEN COALESCE(v_ingresos, 0) = 0 THEN 0
                ELSE ROUND(v_utilidad_bruta / v_ingresos * 100, 2)
           END,
           'RENTABILIDAD'
    UNION ALL
    SELECT 'NetMargin',
           CASE WHEN COALESCE(v_ingresos, 0) = 0 THEN 0
                ELSE ROUND(v_utilidad_neta / v_ingresos * 100, 2)
           END,
           'RENTABILIDAD'
    UNION ALL
    SELECT 'WorkingCapital',
           (COALESCE(v_activo_corriente, 0) - COALESCE(v_pasivo_corriente, 0))::NUMERIC(18,4),
           'LIQUIDEZ';
END;
$function$
;

-- usp_acct_report_librodiario
DROP FUNCTION IF EXISTS public.usp_acct_report_librodiario(bigint, bigint, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_librodiario(p_company_id bigint, p_branch_id bigint, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE(fecha character varying, "asientoId" bigint, "numeroAsiento" character varying, "tipoAsiento" character varying, concepto character varying, estado character varying, renglon integer, "codCuenta" character varying, "descripcionCuenta" character varying, "descripcionLinea" character varying, debe numeric, haber numeric, "centroCosto" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        to_char(je."EntryDate", 'YYYY-MM-DD')::VARCHAR AS "fecha",
        je."JournalEntryId"                             AS "asientoId",
        je."EntryNumber"::VARCHAR                       AS "numeroAsiento",
        je."EntryType"::VARCHAR                         AS "tipoAsiento",
        je."Concept"::VARCHAR                           AS "concepto",
        je."Status"::VARCHAR                            AS "estado",
        jel."LineNumber"                                AS "renglon",
        jel."AccountCodeSnapshot"::VARCHAR              AS "codCuenta",
        COALESCE(a."AccountName", jel."Description")::VARCHAR AS "descripcionCuenta",
        jel."Description"::VARCHAR                      AS "descripcionLinea",
        jel."DebitAmount"                               AS "debe",
        jel."CreditAmount"                              AS "haber",
        jel."CostCenterCode"::VARCHAR                   AS "centroCosto"
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId"  = p_branch_id
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted"  = FALSE
      AND je."Status"    <> 'VOIDED'
    ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber";
END;
$function$
;

-- usp_acct_report_libromayor
DROP FUNCTION IF EXISTS public.usp_acct_report_libromayor(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_libromayor(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE(fecha date, "numeroAsiento" character varying, "codCuenta" character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldo numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        je."EntryDate"                    AS "fecha",
        je."EntryNumber"::VARCHAR         AS "numeroAsiento",
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        a."AccountName"::VARCHAR          AS "cuenta",
        l."Description"::VARCHAR          AS "descripcion",
        l."DebitAmount"                   AS "debe",
        l."CreditAmount"                  AS "haber",
        SUM(l."DebitAmount" - l."CreditAmount") OVER (
            PARTITION BY l."AccountCodeSnapshot"
            ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber";
END;
$function$
;

-- usp_acct_report_mayoranalitico
DROP FUNCTION IF EXISTS public.usp_acct_report_mayoranalitico(integer, integer, character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_mayoranalitico(p_company_id integer, p_branch_id integer, p_cod_cuenta character varying, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE(fecha date, "numeroAsiento" character varying, renglon integer, descripcion character varying, debe numeric, haber numeric, saldo numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        je."EntryDate"               AS "fecha",
        je."EntryNumber"::VARCHAR    AS "numeroAsiento",
        l."LineNumber"               AS "renglon",
        l."Description"::VARCHAR     AS "descripcion",
        l."DebitAmount"              AS "debe",
        l."CreditAmount"             AS "haber",
        SUM(l."DebitAmount" - l."CreditAmount") OVER (
            ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND l."AccountCodeSnapshot" = p_cod_cuenta
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber";
END;
$function$
;

-- usp_acct_report_pnlbycostcenter
DROP FUNCTION IF EXISTS public.usp_acct_report_pnlbycostcenter(integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_pnlbycostcenter(p_company_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("CostCenterCode" character varying, "CostCenterName" character varying, "AccountCode" character varying, "AccountName" character varying, "AccountType" character, "TotalDebit" numeric, "TotalCredit" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COALESCE(jel."CostCenterCode", 'SIN-CC')::VARCHAR(20) AS "CostCenterCode",
           COALESCE(cc."CostCenterName", 'Sin centro de costo')::VARCHAR(200) AS "CostCenterName",
           a."AccountCode",
           a."AccountName",
           a."AccountType",
           SUM(jel."DebitAmount")  AS "TotalDebit",
           SUM(jel."CreditAmount") AS "TotalCredit",
           CASE
               WHEN a."AccountType" = 'I' THEN SUM(jel."CreditAmount") - SUM(jel."DebitAmount")
               WHEN a."AccountType" = 'G' THEN SUM(jel."DebitAmount")  - SUM(jel."CreditAmount")
               ELSE SUM(jel."DebitAmount") - SUM(jel."CreditAmount")
           END AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    LEFT JOIN acct."CostCenter" cc ON cc."CostCenterCode" = jel."CostCenterCode"
                                   AND cc."CompanyId"     = p_company_id
                                   AND cc."IsDeleted"     = FALSE
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY jel."CostCenterCode", cc."CostCenterName",
             a."AccountCode", a."AccountName", a."AccountType"
    ORDER BY jel."CostCenterCode", a."AccountCode";
END;
$function$
;

-- usp_acct_report_pnlmultiperiod
DROP FUNCTION IF EXISTS public.usp_acct_report_pnlmultiperiod(integer, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_pnlmultiperiod(p_company_id integer, p_periodos character varying)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "AccountType" character, "PeriodCode" character varying, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_period_list VARCHAR(7)[];
    v_period_fmt  VARCHAR(7);
    p             TEXT;
BEGIN
    v_period_list := ARRAY[]::VARCHAR(7)[];

    FOR p IN
        SELECT TRIM(e) FROM unnest(string_to_array(p_periodos, ',')) AS e
        WHERE LENGTH(TRIM(e)) = 6
    LOOP
        v_period_fmt := LEFT(p, 4) || '-' || RIGHT(p, 2);
        v_period_list := v_period_list || v_period_fmt::VARCHAR(7);
    END LOOP;

    IF array_length(v_period_list, 1) IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT a."AccountCode",
           a."AccountName",
           a."AccountType",
           je."PeriodCode",
           CASE
               WHEN a."AccountType" = 'I' THEN SUM(jel."CreditAmount" - jel."DebitAmount")
               ELSE SUM(jel."DebitAmount" - jel."CreditAmount")
           END AS "Saldo"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."PeriodCode" = ANY(v_period_list)
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND a."AccountType" IN ('I', 'G')
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
    GROUP BY a."AccountCode", a."AccountName", a."AccountType", je."PeriodCode"
    ORDER BY a."AccountCode", je."PeriodCode";
END;
$function$
;

-- usp_acct_report_reme
DROP FUNCTION IF EXISTS public.usp_acct_report_reme(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_reme(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("InflationAdjustmentId" integer, "PeriodCode" character, "AdjustmentDate" date, "inpcInicio" numeric, "inpcFin" numeric, "factorReexpresion" numeric, "inflacionAcumulada" numeric, reme numeric, "totalAjustes" numeric, "Status" character varying, "JournalEntryId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ia."InflationAdjustmentId",
           ia."PeriodCode",
           ia."AdjustmentDate",
           ia."BaseIndexValue"       AS "inpcInicio",
           ia."EndIndexValue"        AS "inpcFin",
           ia."ReexpressionFactor"   AS "factorReexpresion",
           ia."AccumulatedInflation" AS "inflacionAcumulada",
           ia."TotalMonetaryGainLoss" AS "reme",
           ia."TotalAdjustmentAmount" AS "totalAjustes",
           ia."Status",
           ia."JournalEntryId"
    FROM acct."InflationAdjustment" ia
    WHERE ia."CompanyId"      = p_company_id
      AND ia."BranchId"       = p_branch_id
      AND ia."AdjustmentDate" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND ia."Status"         <> 'VOIDED'
    ORDER BY ia."PeriodCode";
END;
$function$
;

-- usp_acct_report_reme_detail
DROP FUNCTION IF EXISTS public.usp_acct_report_reme_detail(integer, integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_reme_detail(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("AccountCode" character varying, "AccountName" character varying, "Classification" character varying, "HistoricalBalance" numeric, "ReexpressionFactor" numeric, "AdjustedBalance" numeric, "AdjustmentAmount" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_last_adj_id INTEGER;
BEGIN
    SELECT "InflationAdjustmentId" INTO v_last_adj_id
    FROM acct."InflationAdjustment"
    WHERE "CompanyId"      = p_company_id
      AND "BranchId"       = p_branch_id
      AND "AdjustmentDate" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND "Status"         <> 'VOIDED'
    ORDER BY "PeriodCode" DESC
    LIMIT 1;

    IF v_last_adj_id IS NOT NULL THEN
        RETURN QUERY
        SELECT l."AccountCode",
               l."AccountName",
               l."Classification",
               l."HistoricalBalance",
               l."ReexpressionFactor",
               l."AdjustedBalance",
               l."AdjustmentAmount"
        FROM acct."InflationAdjustmentLine" l
        WHERE l."InflationAdjustmentId" = v_last_adj_id
        ORDER BY l."AccountCode";
    END IF;
END;
$function$
;

-- usp_acct_report_taxsummary
DROP FUNCTION IF EXISTS public.usp_acct_report_taxsummary(integer, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_report_taxsummary(p_company_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("TaxAccountCode" character varying, "TaxType" character varying, "DebitTotal" numeric, "CreditTotal" numeric, "TaxAmount" numeric, "BaseAmount" numeric, "TotalAmount" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."AccountCode" AS "TaxAccountCode",
           a."AccountName" AS "TaxType",
           SUM(jel."DebitAmount")  AS "DebitTotal",
           SUM(jel."CreditAmount") AS "CreditTotal",
           SUM(jel."CreditAmount" - jel."DebitAmount") AS "TaxAmount",
           (SELECT SUM(jel2."DebitAmount" - jel2."CreditAmount")
            FROM acct."JournalEntryLine" jel2
            JOIN acct."Account" a2 ON a2."AccountId" = jel2."AccountId"
            WHERE jel2."JournalEntryId" IN (
                SELECT DISTINCT jel3."JournalEntryId"
                FROM acct."JournalEntryLine" jel3
                WHERE jel3."AccountId" = a."AccountId"
                  AND jel3."JournalEntryId" = jel."JournalEntryId"
            )
              AND a2."AccountCode" NOT LIKE '2.4%'
              AND a2."AccountType" IN ('G', 'A')
           ) AS "BaseAmount",
           SUM(jel."CreditAmount" - jel."DebitAmount")
           + COALESCE((SELECT SUM(jel2."DebitAmount" - jel2."CreditAmount")
                       FROM acct."JournalEntryLine" jel2
                       JOIN acct."Account" a2 ON a2."AccountId" = jel2."AccountId"
                       WHERE jel2."JournalEntryId" IN (
                           SELECT DISTINCT jel3."JournalEntryId"
                           FROM acct."JournalEntryLine" jel3
                           WHERE jel3."AccountId" = a."AccountId"
                       )
                         AND a2."AccountCode" NOT LIKE '2.4%'
                         AND a2."AccountType" IN ('G', 'A')
           ), 0) AS "TotalAmount"
    FROM acct."JournalEntryLine" jel
    JOIN acct."JournalEntry" je ON je."JournalEntryId" = jel."JournalEntryId"
    JOIN acct."Account" a       ON a."AccountId"       = jel."AccountId"
    WHERE je."CompanyId"  = p_company_id
      AND je."EntryDate"  >= p_fecha_desde
      AND je."EntryDate"  <= p_fecha_hasta
      AND je."Status"     = 'APPROVED'
      AND je."IsDeleted"  = FALSE
      AND COALESCE(a."IsDeleted", FALSE) = FALSE
      AND a."AccountCode" LIKE '2.4%'
    GROUP BY a."AccountId", a."AccountCode", a."AccountName", jel."JournalEntryId"
    ORDER BY a."AccountCode";
END;
$function$
;

-- usp_acct_reporttemplate_delete
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_delete(integer, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_delete(p_company_id integer, p_report_template_id integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."ReportTemplate"
        WHERE "ReportTemplateId" = p_report_template_id
          AND "CompanyId"        = p_company_id
    ) THEN
        p_mensaje := 'Plantilla no encontrada.';
        RETURN;
    END IF;

    UPDATE acct."ReportTemplate"
    SET "IsActive"  = FALSE,
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "ReportTemplateId" = p_report_template_id;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.';
END;
$function$
;

-- usp_acct_reporttemplate_get
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_get(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_get(p_company_id integer, p_report_template_id integer)
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Recordset 1: cabecera
    RETURN QUERY
    SELECT "ReportTemplateId", "CountryCode", "ReportCode", "ReportName",
           "LegalFramework", "LegalReference", "TemplateContent",
           "HeaderJson", "FooterJson", "IsDefault", "Version",
           "CreatedAt", "UpdatedAt"
    FROM acct."ReportTemplate"
    WHERE "ReportTemplateId" = p_report_template_id
      AND "CompanyId"        = p_company_id;
END;
$function$
;

-- usp_acct_reporttemplate_get_variables
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_get_variables(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_get_variables(p_report_template_id integer)
 RETURNS TABLE("VariableId" integer, "VariableName" character varying, "VariableType" character varying, "DataSource" character varying, "DefaultValue" character varying, "Description" character varying, "SortOrder" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "VariableId", "VariableName", "VariableType", "DataSource",
           "DefaultValue", "Description", "SortOrder"
    FROM acct."ReportTemplateVariable"
    WHERE "ReportTemplateId" = p_report_template_id
    ORDER BY "SortOrder";
END;
$function$
;

-- usp_acct_reporttemplate_list
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_list(integer, character, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_list(p_company_id integer, p_country_code character DEFAULT NULL::bpchar, p_report_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(p_total_count bigint, "ReportTemplateId" integer, "CountryCode" character, "ReportCode" character varying, "ReportName" character varying, "LegalFramework" character varying, "LegalReference" character varying, "IsDefault" boolean, "Version" integer, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COUNT(*) OVER()    AS p_total_count,
           "ReportTemplateId",
           "CountryCode",
           "ReportCode",
           "ReportName",
           "LegalFramework",
           "LegalReference",
           "IsDefault",
           "Version",
           "CreatedAt",
           "UpdatedAt"
    FROM acct."ReportTemplate"
    WHERE "CompanyId" = p_company_id
      AND "IsActive"  = TRUE
      AND (p_country_code IS NULL OR "CountryCode" = p_country_code)
      AND (p_report_code  IS NULL OR "ReportCode"  = p_report_code)
    ORDER BY "CountryCode", "ReportCode";
END;
$function$
;

-- usp_acct_reporttemplate_render
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_render(integer, integer, date, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_render(p_company_id integer, p_report_template_id integer, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_fecha_corte date DEFAULT NULL::date)
 RETURNS TABLE("ReportTemplateId" integer, "CountryCode" character, "ReportCode" character varying, "ReportName" character varying, "LegalFramework" character varying, "LegalReference" character varying, "TemplateContent" character varying, "HeaderJson" character varying, "FooterJson" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Recordset 1: plantilla
    RETURN QUERY
    SELECT "ReportTemplateId", "CountryCode", "ReportCode", "ReportName",
           "LegalFramework", "LegalReference", "TemplateContent",
           "HeaderJson", "FooterJson"
    FROM acct."ReportTemplate"
    WHERE "ReportTemplateId" = p_report_template_id
      AND "CompanyId"        = p_company_id;
END;
$function$
;

-- usp_acct_reporttemplate_render_company
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_render_company(integer, date, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_render_company(p_company_id integer, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_fecha_corte date DEFAULT NULL::date)
 RETURNS TABLE("CompanyId" integer, "CompanyCode" character varying, "companyName" character varying, "companyRIF" character varying, "companyNIF" character varying, "companyAddress" character varying, "companyCountry" character, "reportDate" date, "fechaDesde" date, "fechaHasta" date, currency character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId",
           c."CompanyCode",
           c."LegalName"    AS "companyName",
           c."FiscalId"     AS "companyRIF",
           c."FiscalId"     AS "companyNIF",
           b."AddressLine"  AS "companyAddress",
           c."FiscalCountryCode" AS "companyCountry",
           COALESCE(p_fecha_corte, p_fecha_hasta) AS "reportDate",
           p_fecha_desde    AS "fechaDesde",
           p_fecha_hasta    AS "fechaHasta",
           c."BaseCurrency" AS "currency"
    FROM cfg."Company" c
    LEFT JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId" AND b."IsActive" = TRUE
    WHERE c."CompanyId" = p_company_id;
END;
$function$
;

-- usp_acct_reporttemplate_upsert
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_upsert(integer, integer, character, character varying, character varying, character varying, character varying, text, text, text, integer, integer, text) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_upsert(p_company_id integer, p_report_template_id integer DEFAULT NULL::integer, p_country_code character DEFAULT NULL::bpchar, p_report_code character varying DEFAULT NULL::character varying, p_report_name character varying DEFAULT NULL::character varying, p_legal_framework character varying DEFAULT NULL::character varying, p_legal_reference character varying DEFAULT NULL::character varying, p_template_content text DEFAULT NULL::text, p_header_json text DEFAULT NULL::text, p_footer_json text DEFAULT NULL::text, p_user_id integer DEFAULT NULL::integer, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_new_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF p_report_template_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM acct."ReportTemplate"
        WHERE "ReportTemplateId" = p_report_template_id
          AND "CompanyId"        = p_company_id
    ) THEN
        UPDATE acct."ReportTemplate"
        SET "ReportName"      = COALESCE(p_report_name,      "ReportName"),
            "LegalFramework"  = COALESCE(p_legal_framework,  "LegalFramework"),
            "LegalReference"  = COALESCE(p_legal_reference,  "LegalReference"),
            "TemplateContent" = COALESCE(p_template_content, "TemplateContent"),
            "HeaderJson"      = COALESCE(p_header_json,      "HeaderJson"),
            "FooterJson"      = COALESCE(p_footer_json,      "FooterJson"),
            "Version"         = "Version" + 1,
            "UpdatedAt"       = (NOW() AT TIME ZONE 'UTC')
        WHERE "ReportTemplateId" = p_report_template_id;

        p_resultado := 1;
        p_mensaje   := 'Plantilla actualizada correctamente.';
    ELSE
        IF p_country_code IS NULL OR p_report_code IS NULL OR p_report_name IS NULL OR p_template_content IS NULL THEN
            p_mensaje := 'CountryCode, ReportCode, ReportName y TemplateContent son obligatorios para crear.';
            RETURN;
        END IF;

        INSERT INTO acct."ReportTemplate" (
            "CompanyId", "CountryCode", "ReportCode", "ReportName",
            "LegalFramework", "LegalReference", "TemplateContent",
            "HeaderJson", "FooterJson", "CreatedByUserId"
        )
        VALUES (
            p_company_id, p_country_code, p_report_code, p_report_name,
            COALESCE(p_legal_framework, 'VEN-NIF'), p_legal_reference, p_template_content,
            p_header_json, p_footer_json, p_user_id
        )
        RETURNING "ReportTemplateId" INTO v_new_id;

        p_resultado := 1;
        p_mensaje   := 'Plantilla creada. ID: ' || v_new_id::TEXT;
    END IF;
END;
$function$
;

-- usp_acct_rest_getheader
DROP FUNCTION IF EXISTS public.usp_acct_rest_getheader(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_rest_getheader(p_order_ticket_id integer)
 RETURNS TABLE(id integer, total numeric, "fechaCierre" timestamp without time zone, "codUsuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        o."OrderTicketId"  AS "id",
        o."TotalAmount"    AS "total",
        o."ClosedAt"       AS "fechaCierre",
        COALESCE(uclose."UserCode", uopen."UserCode")::VARCHAR AS "codUsuario"
    FROM rest."OrderTicket" o
    LEFT JOIN sec."User" uopen  ON uopen."UserId"  = o."OpenedByUserId"
    LEFT JOIN sec."User" uclose ON uclose."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_order_ticket_id
    LIMIT 1;
END;
$function$
;

-- usp_acct_rest_gettaxsummary
DROP FUNCTION IF EXISTS public.usp_acct_rest_gettaxsummary(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_rest_gettaxsummary(p_order_ticket_id integer)
 RETURNS TABLE("taxRate" numeric, "baseAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        otl."TaxRate"          AS "taxRate",
        SUM(otl."NetAmount")   AS "baseAmount",
        SUM(otl."TaxAmount")   AS "taxAmount",
        SUM(otl."TotalAmount") AS "totalAmount"
    FROM rest."OrderTicketLine" otl
    WHERE otl."OrderTicketId" = p_order_ticket_id
    GROUP BY otl."TaxRate";
END;
$function$
;

-- usp_acct_scope_getdefault
DROP FUNCTION IF EXISTS public.usp_acct_scope_getdefault() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_scope_getdefault()
 RETURNS TABLE("CompanyId" integer, "BranchId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", b."BranchId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
    WHERE c."IsDeleted" = FALSE
      AND b."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId",
        CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
    LIMIT 1;
END;
$function$
;

-- usp_acct_scope_getdefaultforseed
DROP FUNCTION IF EXISTS public.usp_acct_scope_getdefaultforseed() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_scope_getdefaultforseed()
 RETURNS TABLE("CompanyId" integer, "BranchId" integer, "SystemUserId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", b."BranchId", u."UserId" AS "SystemUserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId" AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" u ON u."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    LIMIT 1;
END;
$function$
;

-- usp_acct_seedplancuentas
DROP FUNCTION IF EXISTS public.usp_acct_seedplancuentas(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_acct_seedplancuentas(p_company_id integer, p_system_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_inserted INT := 1;
BEGIN
    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT 0, 'No existe cfg.Company DEFAULT para sembrar plan de cuentas';
        RETURN;
    END IF;

    -- Crear tabla temporal con plan de cuentas
    CREATE TEMP TABLE _plan (
        "AccountCode"   VARCHAR(40)  NOT NULL,
        "AccountName"   VARCHAR(200) NOT NULL,
        "AccountType"   CHAR(1)      NOT NULL,
        "AccountLevel"  INT          NOT NULL,
        "ParentCode"    VARCHAR(40),
        "AllowsPosting" BOOLEAN      NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO _plan VALUES
        ('1',       'ACTIVO',                    'A', 1, NULL,   FALSE),
        ('1.1',     'ACTIVO CORRIENTE',           'A', 2, '1',   FALSE),
        ('1.2',     'ACTIVO NO CORRIENTE',        'A', 2, '1',   FALSE),
        ('1.1.01',  'CAJA',                       'A', 3, '1.1', TRUE),
        ('1.1.02',  'BANCOS',                     'A', 3, '1.1', TRUE),
        ('1.1.03',  'INVERSIONES TEMPORALES',     'A', 3, '1.1', TRUE),
        ('1.1.04',  'CLIENTES',                   'A', 3, '1.1', TRUE),
        ('1.1.05',  'DOCUMENTOS POR COBRAR',      'A', 3, '1.1', TRUE),
        ('1.1.06',  'INVENTARIOS',                'A', 3, '1.1', TRUE),
        ('1.2.01',  'PROPIEDAD PLANTA Y EQUIPO',  'A', 3, '1.2', TRUE),
        ('1.2.02',  'DEPRECIACION ACUMULADA',     'A', 3, '1.2', TRUE),
        ('2',       'PASIVO',                     'P', 1, NULL,   FALSE),
        ('2.1',     'PASIVO CORRIENTE',           'P', 2, '2',   FALSE),
        ('2.2',     'PASIVO NO CORRIENTE',        'P', 2, '2',   FALSE),
        ('2.1.01',  'PROVEEDORES',                'P', 3, '2.1', TRUE),
        ('2.1.02',  'DOCUMENTOS POR PAGAR',       'P', 3, '2.1', TRUE),
        ('2.1.03',  'IMPUESTOS POR PAGAR',        'P', 3, '2.1', TRUE),
        ('2.1.04',  'SUELDOS POR PAGAR',          'P', 3, '2.1', TRUE),
        ('3',       'PATRIMONIO',                 'C', 1, NULL,   FALSE),
        ('3.1',     'CAPITAL SOCIAL',             'C', 2, '3',   FALSE),
        ('3.1.01',  'CAPITAL SUSCRITO',           'C', 3, '3.1', TRUE),
        ('4',       'INGRESOS',                   'I', 1, NULL,   FALSE),
        ('4.1',     'INGRESOS OPERACIONALES',     'I', 2, '4',   FALSE),
        ('4.1.01',  'VENTAS',                     'I', 3, '4.1', TRUE),
        ('4.1.02',  'DESCUENTOS EN VENTAS',       'I', 3, '4.1', TRUE),
        ('5',       'COSTOS Y GASTOS',            'G', 1, NULL,   FALSE),
        ('5.1',     'COSTO DE VENTAS',            'G', 2, '5',   FALSE),
        ('5.2',     'GASTOS OPERACIONALES',       'G', 2, '5',   FALSE),
        ('5.1.01',  'COSTO DE MERCADERIA',        'G', 3, '5.1', TRUE),
        ('5.2.01',  'SUELDOS Y SALARIOS',         'G', 3, '5.2', TRUE),
        ('5.2.02',  'ALQUILERES',                 'G', 3, '5.2', TRUE),
        ('5.2.03',  'DEPRECIACION',               'G', 3, '5.2', TRUE);

    BEGIN
        WHILE v_inserted > 0
        LOOP
            INSERT INTO acct."Account" (
                "CompanyId", "AccountCode", "AccountName", "AccountType", "AccountLevel",
                "ParentAccountId", "AllowsPosting", "RequiresAuxiliary",
                "IsActive", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId", "IsDeleted"
            )
            SELECT
                p_company_id,
                p."AccountCode",
                p."AccountName",
                p."AccountType",
                p."AccountLevel",
                parent."AccountId",
                p."AllowsPosting",
                FALSE,
                TRUE,
                NOW() AT TIME ZONE 'UTC',
                NOW() AT TIME ZONE 'UTC',
                p_system_user_id,
                p_system_user_id,
                FALSE
            FROM _plan p
            LEFT JOIN acct."Account" existing
                ON existing."CompanyId" = p_company_id
               AND existing."AccountCode" = p."AccountCode"
            LEFT JOIN acct."Account" parent
                ON parent."CompanyId" = p_company_id
               AND parent."AccountCode" = p."ParentCode"
            WHERE existing."AccountId" IS NULL
              AND (p."ParentCode" IS NULL OR parent."AccountId" IS NOT NULL);

            GET DIAGNOSTICS v_inserted = ROW_COUNT;
        END LOOP;

        RETURN QUERY SELECT 1, 'Plan de cuentas canonico listo';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error sembrando plan de cuentas: ' || SQLERRM;
    END;
END;
$function$
;

-- usp_contabilidad_ajuste_crear
DROP FUNCTION IF EXISTS public.usp_contabilidad_ajuste_crear(date, character varying, character varying, character varying, character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_ajuste_crear(p_fecha date, p_tipo_ajuste character varying, p_referencia character varying DEFAULT NULL::character varying, p_motivo character varying DEFAULT ''::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("AsientoId" bigint, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_asiento_id     BIGINT;
    v_numero_asiento VARCHAR(40);
    v_resultado      INT;
    v_mensaje        TEXT;
    rec              RECORD;
BEGIN
    SELECT * INTO rec
    FROM usp_contabilidad_asiento_crear(
        p_fecha,
        'AJU',
        p_referencia,
        p_motivo,
        'VES',
        1,
        'CONTABILIDAD',
        p_referencia,
        p_cod_usuario,
        p_detalle_json
    );

    v_asiento_id := rec."AsientoId";
    v_resultado  := rec."Resultado";
    v_mensaje    := rec."Mensaje";

    IF v_resultado = 1 THEN
        INSERT INTO "AjusteContable" ("AsientoId", "TipoAjuste", "Motivo", "Fecha", "Estado", "CodUsuario")
        VALUES (v_asiento_id, p_tipo_ajuste, p_motivo, p_fecha, 'APROBADO', p_cod_usuario);
    END IF;

    RETURN QUERY SELECT v_asiento_id, v_resultado, v_mensaje;
END;
$function$
;

-- usp_contabilidad_asiento_anular
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_anular(bigint, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_anular(p_asiento_id bigint, p_motivo character varying, p_cod_usuario character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "AsientoContable" WHERE "Id" = p_asiento_id) THEN
        RETURN QUERY SELECT -1, 'Asiento no encontrado'::TEXT;
        RETURN;
    END IF;

    UPDATE "AsientoContable"
    SET "Estado" = 'ANULADO',
        "FechaAnulacion" = NOW() AT TIME ZONE 'UTC',
        "UsuarioAnulacion" = p_cod_usuario,
        "MotivoAnulacion" = p_motivo
    WHERE "Id" = p_asiento_id;

    RETURN QUERY SELECT 1, 'OK'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::TEXT;
END;
$function$
;

-- usp_contabilidad_asiento_crear
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_crear(date, character varying, character varying, character varying, character varying, numeric, character varying, character varying, character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_crear(p_fecha date, p_tipo_asiento character varying, p_referencia character varying DEFAULT NULL::character varying, p_concepto character varying DEFAULT ''::character varying, p_moneda character varying DEFAULT 'VES'::character varying, p_tasa numeric DEFAULT 1, p_origen_modulo character varying DEFAULT NULL::character varying, p_origen_documento character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("AsientoId" bigint, "NumeroAsiento" character varying, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_asiento_id      BIGINT;
    v_numero_asiento  VARCHAR(40);
    v_periodo         VARCHAR(7);
    v_debe            NUMERIC(18,2);
    v_haber           NUMERIC(18,2);
    v_next            INT;
BEGIN
    v_periodo := TO_CHAR(p_fecha, 'YYYY-MM');

    -- Crear tabla temporal con el detalle parseado del JSONB
    CREATE TEMP TABLE _det_asiento (
        "Renglon"        SERIAL,
        "CodCuenta"      VARCHAR(40),
        "Descripcion"    VARCHAR(400),
        "CentroCosto"    VARCHAR(20),
        "AuxiliarTipo"   VARCHAR(30),
        "AuxiliarCodigo" VARCHAR(120),
        "Documento"      VARCHAR(120),
        "Debe"           NUMERIC(18,2),
        "Haber"          NUMERIC(18,2)
    ) ON COMMIT DROP;

    INSERT INTO _det_asiento ("CodCuenta", "Descripcion", "CentroCosto",
                               "AuxiliarTipo", "AuxiliarCodigo", "Documento", "Debe", "Haber")
    SELECT
        NULLIF(item->>'codCuenta', ''::character varying),
        NULLIF(item->>'descripcion', ''::character varying),
        NULLIF(item->>'centroCosto', ''::character varying),
        NULLIF(item->>'auxiliarTipo', ''::character varying),
        NULLIF(item->>'auxiliarCodigo', ''::character varying),
        NULLIF(item->>'documento', ''::character varying),
        COALESCE(NULLIF(item->>'debe', ''::character varying)::NUMERIC(18,2), 0)::character varying,
        COALESCE(NULLIF(item->>'haber', ''::character varying)::NUMERIC(18,2), 0)::character varying
    FROM jsonb_array_elements(p_detalle_json) AS item;

    IF NOT EXISTS (SELECT 1 FROM _det_asiento) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, -1, 'Detalle requerido'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM _det_asiento WHERE "CodCuenta" IS NULL) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, -2, 'Existe detalle sin cuenta contable'::TEXT;
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM _det_asiento d
        LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
        WHERE c."COD_CUENTA" IS NULL
    ) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, -3, 'Existe detalle con cuenta no registrada en Cuentas'::TEXT;
        RETURN;
    END IF;

    SELECT COALESCE(SUM("Debe"), 0), COALESCE(SUM("Haber"), 0)
    INTO v_debe, v_haber
    FROM _det_asiento;

    IF ABS(v_debe - v_haber) > 0.009 THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, -4, 'Asiento descuadrado: Debe y Haber no coinciden'::TEXT;
        RETURN;
    END IF;

    -- Generar numero secuencial
    SELECT COALESCE(MAX(
        CASE WHEN RIGHT("NumeroAsiento", 8) ~ '^\d+$'
             THEN RIGHT("NumeroAsiento", 8)::INT
             ELSE 0 END
    ), 0) + 1
    INTO v_next
    FROM "AsientoContable";

    v_numero_asiento := 'AST-' || LPAD(v_next::TEXT, 8, '0');

    INSERT INTO "AsientoContable" (
        "NumeroAsiento", "Fecha", "Periodo", "TipoAsiento", "Referencia", "Concepto", "Moneda", "Tasa",
        "TotalDebe", "TotalHaber", "Estado", "OrigenModulo", "OrigenDocumento", "CodUsuario", "FechaCreacion"
    )
    VALUES (
        v_numero_asiento, p_fecha, v_periodo, p_tipo_asiento, p_referencia, p_concepto, p_moneda, p_tasa,
        v_debe, v_haber, 'APROBADO', p_origen_modulo, p_origen_documento, p_cod_usuario, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "Id" INTO v_asiento_id;

    INSERT INTO "AsientoContableDetalle" (
        "AsientoId", "Renglon", "CodCuenta", "Descripcion", "CentroCosto",
        "AuxiliarTipo", "AuxiliarCodigo", "Documento", "Debe", "Haber"
    )
    SELECT
        v_asiento_id, "Renglon", "CodCuenta", "Descripcion", "CentroCosto",
        "AuxiliarTipo", "AuxiliarCodigo", "Documento", "Debe", "Haber"
    FROM _det_asiento
    ORDER BY "Renglon";

    IF p_origen_modulo IS NOT NULL AND p_origen_documento IS NOT NULL THEN
        INSERT INTO "AsientoOrigenAuxiliar" (
            "OrigenModulo", "TipoDocumento", "NumeroDocumento", "TablaOrigen", "LlaveOrigen", "AsientoId", "Estado"
        )
        VALUES (
            p_origen_modulo,
            p_tipo_asiento,
            p_origen_documento,
            NULL,
            p_origen_documento,
            v_asiento_id,
            'APLICADO'
        );
    END IF;

    RETURN QUERY SELECT v_asiento_id, v_numero_asiento, 1, 'OK'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, -99, SQLERRM::TEXT;
END;
$function$
;

-- usp_contabilidad_asiento_get_detalle
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_get_detalle(bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_get_detalle(p_asiento_id bigint)
 RETURNS TABLE("Id" bigint, "AsientoId" bigint, "Renglon" integer, "CodCuenta" character varying, "Descripcion" character varying, "CentroCosto" character varying, "AuxiliarTipo" character varying, "AuxiliarCodigo" character varying, "Documento" character varying, "Debe" numeric, "Haber" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT d."Id", d."AsientoId", d."Renglon", d."CodCuenta", d."Descripcion",
           d."CentroCosto", d."AuxiliarTipo", d."AuxiliarCodigo", d."Documento",
           d."Debe", d."Haber"
    FROM "AsientoContableDetalle" d
    WHERE d."AsientoId" = p_asiento_id
    ORDER BY d."Renglon", d."Id";
END;
$function$
;

-- usp_contabilidad_asiento_get_header
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_get_header(bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_asiento_get_header(p_asiento_id bigint)
 RETURNS TABLE("Id" bigint, "NumeroAsiento" character varying, "Fecha" date, "Periodo" character varying, "TipoAsiento" character varying, "Referencia" character varying, "Concepto" character varying, "Moneda" character varying, "Tasa" numeric, "TotalDebe" numeric, "TotalHaber" numeric, "Estado" character varying, "OrigenModulo" character varying, "OrigenDocumento" character varying, "CodUsuario" character varying, "FechaCreacion" timestamp without time zone, "FechaAnulacion" timestamp without time zone, "UsuarioAnulacion" character varying, "MotivoAnulacion" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."Id", a."NumeroAsiento", a."Fecha", a."Periodo", a."TipoAsiento",
           a."Referencia", a."Concepto", a."Moneda", a."Tasa",
           a."TotalDebe", a."TotalHaber", a."Estado",
           a."OrigenModulo", a."OrigenDocumento", a."CodUsuario",
           a."FechaCreacion", a."FechaAnulacion", a."UsuarioAnulacion", a."MotivoAnulacion"
    FROM "AsientoContable" a
    WHERE a."Id" = p_asiento_id;
END;
$function$
;

-- usp_contabilidad_asientos_list
DROP FUNCTION IF EXISTS public.usp_contabilidad_asientos_list(date, date, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_asientos_list(p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_tipo_asiento character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_origen_modulo character varying DEFAULT NULL::character varying, p_origen_documento character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "Id" bigint, "NumeroAsiento" character varying, "Fecha" date, "Periodo" character varying, "TipoAsiento" character varying, "Referencia" character varying, "Concepto" character varying, "Moneda" character varying, "Tasa" numeric, "TotalDebe" numeric, "TotalHaber" numeric, "Estado" character varying, "OrigenModulo" character varying, "OrigenDocumento" character varying, "CodUsuario" character varying, "FechaCreacion" timestamp without time zone, "FechaAnulacion" timestamp without time zone, "UsuarioAnulacion" character varying, "MotivoAnulacion" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT;
    v_limit  INT;
    v_total  BIGINT;
BEGIN
    v_limit := CASE WHEN p_limit IS NULL OR p_limit < 1 THEN 50 ELSE p_limit END;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (CASE WHEN p_page IS NULL OR p_page < 1 THEN 1 ELSE p_page END - 1) * v_limit;

    SELECT COUNT(1) INTO v_total
    FROM "AsientoContable" a
    WHERE (p_fecha_desde IS NULL OR a."Fecha" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR a."Fecha" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR a."TipoAsiento" = p_tipo_asiento)
      AND (p_estado IS NULL OR a."Estado" = p_estado)
      AND (p_origen_modulo IS NULL OR a."OrigenModulo" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR a."OrigenDocumento" = p_origen_documento);

    RETURN QUERY
    SELECT
        v_total,
        a."Id",
        a."NumeroAsiento",
        a."Fecha",
        a."Periodo",
        a."TipoAsiento",
        a."Referencia",
        a."Concepto",
        a."Moneda",
        a."Tasa",
        a."TotalDebe",
        a."TotalHaber",
        a."Estado",
        a."OrigenModulo",
        a."OrigenDocumento",
        a."CodUsuario",
        a."FechaCreacion",
        a."FechaAnulacion",
        a."UsuarioAnulacion",
        a."MotivoAnulacion"
    FROM "AsientoContable" a
    WHERE (p_fecha_desde IS NULL OR a."Fecha" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR a."Fecha" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR a."TipoAsiento" = p_tipo_asiento)
      AND (p_estado IS NULL OR a."Estado" = p_estado)
      AND (p_origen_modulo IS NULL OR a."OrigenModulo" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR a."OrigenDocumento" = p_origen_documento)
    ORDER BY a."Id" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_contabilidad_balance_comprobacion
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_comprobacion(date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_comprobacion(p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("CodCuenta" character varying, "CuentaDescripcion" character varying, "TotalDebe" numeric, "TotalHaber" numeric, "SaldoDeudor" numeric, "SaldoAcreedor" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."CodCuenta",
        c."DESCRIPCION",
        SUM(d."Debe"),
        SUM(d."Haber"),
        CASE
            WHEN SUM(d."Debe" - d."Haber") > 0 THEN SUM(d."Debe" - d."Haber")
            ELSE 0::NUMERIC
        END,
        CASE
            WHEN SUM(d."Debe" - d."Haber") < 0 THEN ABS(SUM(d."Debe" - d."Haber"))
            ELSE 0::NUMERIC
        END
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
    WHERE a."Estado" <> 'ANULADO'
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY d."CodCuenta", c."DESCRIPCION"
    ORDER BY d."CodCuenta";
END;
$function$
;

-- usp_contabilidad_balance_general
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_general(date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_general(p_fecha_corte date)
 RETURNS TABLE("Grupo" character varying, "CodCuenta" character varying, "CuentaDescripcion" character varying, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH base AS (
        SELECT
            d."CodCuenta",
            c."DESCRIPCION" AS "CuentaDescripcion",
            SUM(d."Debe" - d."Haber") AS "Saldo"
        FROM "AsientoContableDetalle" d
        INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
        LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
        WHERE a."Estado" <> 'ANULADO'
          AND a."Fecha" <= p_fecha_corte
          AND (d."CodCuenta" LIKE '1%' OR d."CodCuenta" LIKE '2%' OR d."CodCuenta" LIKE '3%')
        GROUP BY d."CodCuenta", c."DESCRIPCION"
    )
    SELECT
        CASE
            WHEN b."CodCuenta" LIKE '1%' THEN 'ACTIVOS'::VARCHAR
            WHEN b."CodCuenta" LIKE '2%' THEN 'PASIVOS'::VARCHAR
            WHEN b."CodCuenta" LIKE '3%' THEN 'PATRIMONIO'::VARCHAR
            ELSE 'OTROS'::VARCHAR
        END,
        b."CodCuenta",
        b."CuentaDescripcion",
        b."Saldo"
    FROM base b
    ORDER BY b."CodCuenta";
END;
$function$
;

-- usp_contabilidad_balance_general_resumen
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_general_resumen(date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_balance_general_resumen(p_fecha_corte date)
 RETURNS TABLE("TotalActivos" numeric, "TotalPasivos" numeric, "TotalPatrimonio" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        SUM(CASE WHEN d."CodCuenta" LIKE '1%' THEN (d."Debe" - d."Haber") ELSE 0 END),
        SUM(CASE WHEN d."CodCuenta" LIKE '2%' THEN (d."Haber" - d."Debe") ELSE 0 END),
        SUM(CASE WHEN d."CodCuenta" LIKE '3%' THEN (d."Haber" - d."Debe") ELSE 0 END)
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    WHERE a."Estado" <> 'ANULADO'
      AND a."Fecha" <= p_fecha_corte;
END;
$function$
;

-- usp_contabilidad_depreciacion_generar
DROP FUNCTION IF EXISTS public.usp_contabilidad_depreciacion_generar(character varying, character varying, character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_depreciacion_generar(p_periodo character varying, p_cod_usuario character varying, p_centro_costo character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_fecha        DATE;
    v_ultimo_dia   DATE;
    v_detalle_json JSONB;
    v_asiento_id   BIGINT;
    v_numero       VARCHAR(40);
    v_res          INT;
    v_msg          TEXT;
    v_concepto     VARCHAR(400);
    rec            RECORD;
BEGIN
    v_fecha      := (p_periodo || '-01')::DATE;
    v_ultimo_dia := (v_fecha + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

    -- Crear tabla temporal de activos a depreciar
    CREATE TEMP TABLE _tmp_deprec (
        "ActivoId"       BIGINT,
        "CuentaGasto"    VARCHAR(40),
        "CuentaDepAcum"  VARCHAR(40),
        "CentroCosto"    VARCHAR(20),
        "Monto"          NUMERIC(18,2)
    ) ON COMMIT DROP;

    INSERT INTO _tmp_deprec ("ActivoId", "CuentaGasto", "CuentaDepAcum", "CentroCosto", "Monto")
    SELECT
        a."Id",
        a."CuentaGastoDepreciacion",
        a."CuentaDepreciacionAcum",
        COALESCE(p_centro_costo, a."CentroCosto"),
        ROUND((a."CostoAdquisicion" - a."ValorResidual") / NULLIF(a."VidaUtilMeses", 0), 2)
    FROM "ActivoFijoContable" a
    WHERE a."Activo" = TRUE
      AND a."VidaUtilMeses" > 0
      AND NOT EXISTS (
          SELECT 1 FROM "DepreciacionContable" d WHERE d."ActivoId" = a."Id" AND d."Periodo" = p_periodo
      );

    IF NOT EXISTS (SELECT 1 FROM _tmp_deprec) THEN
        RETURN QUERY SELECT 1, 'Sin activos pendientes para depreciar'::TEXT;
        RETURN;
    END IF;

    -- Construir JSON del detalle (equivalente a FOR XML PATH)
    SELECT jsonb_agg(row_to_json(x)::JSONB) INTO v_detalle_json
    FROM (
        SELECT
            t."CuentaGasto"                                AS "codCuenta",
            'Depreciacion del periodo ' || p_periodo       AS "descripcion",
            COALESCE(t."CentroCosto", 'ADM')               AS "centroCosto",
            t."Monto"                                       AS "debe",
            0::NUMERIC(18,2)                                AS "haber"
        FROM _tmp_deprec t
        UNION ALL
        SELECT
            t."CuentaDepAcum"                                       AS "codCuenta",
            'Depreciacion acumulada del periodo ' || p_periodo      AS "descripcion",
            COALESCE(t."CentroCosto", 'ADM')                        AS "centroCosto",
            0::NUMERIC(18,2)                                         AS "debe",
            t."Monto"                                                AS "haber"
        FROM _tmp_deprec t
    ) x;

    v_concepto := 'Depreciacion contable ' || p_periodo;

    SELECT * INTO rec
    FROM usp_contabilidad_asiento_crear(
        v_ultimo_dia,
        'DEP',
        p_periodo,
        v_concepto,
        'VES',
        1,
        'ACTIVOS_FIJOS',
        p_periodo,
        p_cod_usuario,
        v_detalle_json
    );

    v_asiento_id := rec."AsientoId";
    v_res        := rec."Resultado";
    v_msg        := rec."Mensaje";

    IF v_res <> 1 THEN
        RETURN QUERY SELECT v_res, v_msg;
        RETURN;
    END IF;

    INSERT INTO "DepreciacionContable" ("ActivoId", "Periodo", "Fecha", "Monto", "AsientoId", "Estado")
    SELECT "ActivoId", p_periodo, v_ultimo_dia, "Monto", v_asiento_id, 'GENERADO'
    FROM _tmp_deprec;

    RETURN QUERY SELECT 1, 'OK'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::TEXT;
END;
$function$
;

-- usp_contabilidad_estado_resultados
DROP FUNCTION IF EXISTS public.usp_contabilidad_estado_resultados(date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_estado_resultados(p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("Grupo" character varying, "CodCuenta" character varying, "CuentaDescripcion" character varying, "Debe" numeric, "Haber" numeric, "Neto" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH base AS (
        SELECT
            d."CodCuenta",
            c."DESCRIPCION" AS "CuentaDescripcion",
            SUM(d."Debe") AS "Debe",
            SUM(d."Haber") AS "Haber",
            SUM(d."Haber" - d."Debe") AS "Neto"
        FROM "AsientoContableDetalle" d
        INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
        LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
        WHERE a."Estado" <> 'ANULADO'
          AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
          AND (d."CodCuenta" LIKE '4%' OR d."CodCuenta" LIKE '5%'
               OR d."CodCuenta" LIKE '6%' OR d."CodCuenta" LIKE '7%')
        GROUP BY d."CodCuenta", c."DESCRIPCION"
    )
    SELECT
        CASE
            WHEN b."CodCuenta" LIKE '4%' THEN 'INGRESOS'::VARCHAR
            WHEN b."CodCuenta" LIKE '5%' THEN 'COSTOS'::VARCHAR
            WHEN b."CodCuenta" LIKE '6%' THEN 'GASTOS'::VARCHAR
            WHEN b."CodCuenta" LIKE '7%' THEN 'CIERRE'::VARCHAR
            ELSE 'OTROS'::VARCHAR
        END,
        b."CodCuenta",
        b."CuentaDescripcion",
        b."Debe",
        b."Haber",
        b."Neto"
    FROM base b
    ORDER BY b."CodCuenta";
END;
$function$
;

-- usp_contabilidad_estado_resultados_resumen
DROP FUNCTION IF EXISTS public.usp_contabilidad_estado_resultados_resumen(date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_estado_resultados_resumen(p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("TotalIngresos" numeric, "TotalCostos" numeric, "TotalGastos" numeric, "ResultadoNeto" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        SUM(CASE WHEN d."CodCuenta" LIKE '4%' THEN (d."Haber" - d."Debe") ELSE 0 END),
        SUM(CASE WHEN d."CodCuenta" LIKE '5%' THEN (d."Debe" - d."Haber") ELSE 0 END),
        SUM(CASE WHEN d."CodCuenta" LIKE '6%' THEN (d."Debe" - d."Haber") ELSE 0 END),
        SUM(CASE
            WHEN d."CodCuenta" LIKE '4%' THEN (d."Haber" - d."Debe")
            WHEN d."CodCuenta" LIKE '5%' OR d."CodCuenta" LIKE '6%' THEN -(d."Debe" - d."Haber")
            ELSE 0
        END)
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    WHERE a."Estado" <> 'ANULADO'
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta;
END;
$function$
;

-- usp_contabilidad_libro_mayor
DROP FUNCTION IF EXISTS public.usp_contabilidad_libro_mayor(date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_libro_mayor(p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("CodCuenta" character varying, "CuentaDescripcion" character varying, "Debe" numeric, "Haber" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."CodCuenta",
        c."DESCRIPCION",
        SUM(d."Debe"),
        SUM(d."Haber"),
        SUM(d."Debe" - d."Haber")
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
    WHERE a."Estado" <> 'ANULADO'
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY d."CodCuenta", c."DESCRIPCION"
    ORDER BY d."CodCuenta";
END;
$function$
;

-- usp_contabilidad_mayor_analitico
DROP FUNCTION IF EXISTS public.usp_contabilidad_mayor_analitico(character varying, date, date) CASCADE;
DROP FUNCTION IF EXISTS public.usp_contabilidad_mayor_analitico(p_cod_cuenta character varying, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("Fecha" date, "NumeroAsiento" character varying, "Referencia" character varying, "Concepto" character varying, "Renglon" integer, "CodCuenta" character varying, "CuentaDescripcion" character varying, "CentroCosto" character varying, "AuxiliarTipo" character varying, "AuxiliarCodigo" character varying, "Documento" character varying, "Debe" numeric, "Haber" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        a."Fecha",
        a."NumeroAsiento",
        a."Referencia",
        a."Concepto",
        d."Renglon",
        d."CodCuenta",
        c."DESCRIPCION",
        d."CentroCosto",
        d."AuxiliarTipo",
        d."AuxiliarCodigo",
        d."Documento",
        d."Debe",
        d."Haber"
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    LEFT JOIN "Cuentas" c ON c."COD_CUENTA" = d."CodCuenta"
    WHERE d."CodCuenta" = p_cod_cuenta
      AND a."Estado" <> 'ANULADO'
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    ORDER BY a."Fecha", a."Id", d."Renglon";
END;
$function$
;

-- usp_cuentas_delete
DROP FUNCTION IF EXISTS public.usp_cuentas_delete(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cuentas_delete(p_cod_cuenta character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta) THEN
        RETURN QUERY SELECT -1, 'Cuenta no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    DELETE FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_cuentas_getbycodigo
DROP FUNCTION IF EXISTS public.usp_cuentas_getbycodigo(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cuentas_getbycodigo(p_cod_cuenta character varying)
 RETURNS TABLE("COD_CUENTA" character varying, "DESCRIPCION" character varying, "TIPO" character varying, "PRESUPUESTO" integer, "SALDO" integer, "COD_USUARIO" character varying, grupo character varying, "LINEA" character varying, "USO" character varying, "Nivel" integer, "Porcentaje" double precision)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."COD_CUENTA",
        c."DESCRIPCION",
        c."TIPO",
        c."PRESUPUESTO",
        c."SALDO",
        c."COD_USUARIO",
        c."grupo",
        c."LINEA",
        c."USO",
        c."Nivel",
        c."Porcentaje"
    FROM public."Cuentas" c
    WHERE c."COD_CUENTA" = p_cod_cuenta;
END;
$function$
;

-- usp_cuentas_insert
DROP FUNCTION IF EXISTS public.usp_cuentas_insert(jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cuentas_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_resultado INT := 0;
    v_mensaje   VARCHAR(500) := '';
BEGIN
    -- Verificar duplicado
    IF EXISTS (
        SELECT 1 FROM public."Cuentas"
        WHERE "COD_CUENTA" = (p_row_json->>'COD_CUENTA')
    ) THEN
        RETURN QUERY SELECT -1, 'Cuenta ya existe'::VARCHAR(500);
        RETURN;
    END IF;

    INSERT INTO public."Cuentas" (
        "COD_CUENTA", "DESCRIPCION", "TIPO", "PRESUPUESTO", "SALDO",
        "COD_USUARIO", "grupo", "LINEA", "USO", "Nivel", "Porcentaje"
    ) VALUES (
        NULLIF(p_row_json->>'COD_CUENTA', ''::character varying),
        NULLIF(p_row_json->>'DESCRIPCION', ''::character varying),
        NULLIF(p_row_json->>'TIPO', ''::character varying),
        CASE WHEN COALESCE(p_row_json->>'PRESUPUESTO', '') = '' THEN NULL
             ELSE (p_row_json->>'PRESUPUESTO')::INT END,
        CASE WHEN COALESCE(p_row_json->>'SALDO', '') = '' THEN NULL
             ELSE (p_row_json->>'SALDO')::INT END,
        NULLIF(p_row_json->>'COD_USUARIO', ''::character varying),
        NULLIF(p_row_json->>'grupo', ''::character varying),
        NULLIF(p_row_json->>'LINEA', ''::character varying),
        NULLIF(p_row_json->>'USO', ''::character varying),
        CASE WHEN COALESCE(p_row_json->>'Nivel', '') = '' THEN NULL
             ELSE (p_row_json->>'Nivel')::INT END,
        CASE WHEN COALESCE(p_row_json->>'Porcentaje', '') = '' THEN NULL
             ELSE (p_row_json->>'Porcentaje')::DOUBLE PRECISION END
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

-- usp_cuentas_list
DROP FUNCTION IF EXISTS public.usp_cuentas_list(character varying, character varying, character varying, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cuentas_list(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_grupo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" integer, "COD_CUENTA" character varying, "DESCRIPCION" character varying, "TIPO" character varying, "PRESUPUESTO" integer, "SALDO" integer, "COD_USUARIO" character varying, grupo character varying, "LINEA" character varying, "USO" character varying, "Nivel" integer, "Porcentaje" double precision)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset   INT;
    v_limit    INT;
    v_search   VARCHAR(100);
    v_total    INT;
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    -- Contar total
    SELECT COUNT(1) INTO v_total
    FROM public."Cuentas" c
    WHERE (v_search IS NULL OR c."COD_CUENTA" LIKE v_search OR c."DESCRIPCION" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR c."TIPO" = p_tipo)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR c."grupo" = p_grupo);

    -- Devolver filas
    RETURN QUERY
    SELECT
        v_total,
        c."COD_CUENTA",
        c."DESCRIPCION",
        c."TIPO",
        c."PRESUPUESTO",
        c."SALDO",
        c."COD_USUARIO",
        c."grupo",
        c."LINEA",
        c."USO",
        c."Nivel",
        c."Porcentaje"
    FROM public."Cuentas" c
    WHERE (v_search IS NULL OR c."COD_CUENTA" LIKE v_search OR c."DESCRIPCION" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR c."TIPO" = p_tipo)
      AND (p_grupo IS NULL OR TRIM(p_grupo) = '' OR c."grupo" = p_grupo)
    ORDER BY c."COD_CUENTA"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_cuentas_update
DROP FUNCTION IF EXISTS public.usp_cuentas_update(character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.usp_cuentas_update(p_cod_cuenta character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Cuentas" WHERE "COD_CUENTA" = p_cod_cuenta) THEN
        RETURN QUERY SELECT -1, 'Cuenta no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Cuentas" SET
        "DESCRIPCION" = COALESCE(NULLIF(p_row_json->>'DESCRIPCION', ''::character varying), "DESCRIPCION")::character varying,
        "TIPO"        = COALESCE(NULLIF(p_row_json->>'TIPO', ''::character varying), "TIPO")::character varying,
        "grupo"       = COALESCE(NULLIF(p_row_json->>'grupo', ''::character varying), "grupo")::character varying,
        "LINEA"       = COALESCE(NULLIF(p_row_json->>'LINEA', ''::character varying), "LINEA")::character varying,
        "USO"         = COALESCE(NULLIF(p_row_json->>'USO', ''::character varying), "USO")::character varying,
        "Nivel"       = CASE WHEN COALESCE(p_row_json->>'Nivel', '') = '' THEN "Nivel"
                             ELSE (p_row_json->>'Nivel')::INT END,
        "Porcentaje"  = CASE WHEN COALESCE(p_row_json->>'Porcentaje', '') = '' THEN "Porcentaje"
                             ELSE (p_row_json->>'Porcentaje')::DOUBLE PRECISION END
    WHERE "COD_CUENTA" = p_cod_cuenta;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$function$
;

