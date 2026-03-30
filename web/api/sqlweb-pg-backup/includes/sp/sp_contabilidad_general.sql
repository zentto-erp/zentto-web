-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_contabilidad_general.sql
-- Funciones de contabilidad general: asientos, reportes, depreciacion
-- ============================================================

/*
  Funciones contabilidad general (PostgreSQL 14+)
  Traducido de: web/api/sqlweb/includes/sp/sp_contabilidad_general.sql
  Todos los procesos criticos usan transaccion auto-gestionada por PG.
  XML -> JSONB para parametros de detalle.
  Multiple result sets del SP original se dividen en funciones separadas.
*/

-- =============================================
-- 1. Listar asientos contables (paginado)
-- Original: dbo.usp_Contabilidad_Asientos_List
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_asientos_list(DATE, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, INT);

CREATE OR REPLACE FUNCTION usp_contabilidad_asientos_list(
    p_fecha_desde      DATE DEFAULT NULL,
    p_fecha_hasta      DATE DEFAULT NULL,
    p_tipo_asiento     VARCHAR(20) DEFAULT NULL,
    p_estado           VARCHAR(20) DEFAULT NULL,
    p_origen_modulo    VARCHAR(40) DEFAULT NULL,
    p_origen_documento VARCHAR(120) DEFAULT NULL,
    p_page             INT DEFAULT 1,
    p_limit            INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"        BIGINT,
    "Id"                BIGINT,
    "NumeroAsiento"     VARCHAR,
    "Fecha"             DATE,
    "Periodo"           VARCHAR,
    "TipoAsiento"       VARCHAR,
    "Referencia"        VARCHAR,
    "Concepto"          VARCHAR,
    "Moneda"            VARCHAR,
    "Tasa"              NUMERIC,
    "TotalDebe"         NUMERIC,
    "TotalHaber"        NUMERIC,
    "Estado"            VARCHAR,
    "OrigenModulo"      VARCHAR,
    "OrigenDocumento"   VARCHAR,
    "CodUsuario"        VARCHAR,
    "FechaCreacion"     TIMESTAMP,
    "FechaAnulacion"    TIMESTAMP,
    "UsuarioAnulacion"  VARCHAR,
    "MotivoAnulacion"   VARCHAR
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 2. Obtener un asiento contable - cabecera
-- Original: dbo.usp_Contabilidad_Asiento_Get (result set 1)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_asiento_get_header(BIGINT);

CREATE OR REPLACE FUNCTION usp_contabilidad_asiento_get_header(
    p_asiento_id BIGINT
)
RETURNS TABLE(
    "Id"                BIGINT,
    "NumeroAsiento"     VARCHAR,
    "Fecha"             DATE,
    "Periodo"           VARCHAR,
    "TipoAsiento"       VARCHAR,
    "Referencia"        VARCHAR,
    "Concepto"          VARCHAR,
    "Moneda"            VARCHAR,
    "Tasa"              NUMERIC,
    "TotalDebe"         NUMERIC,
    "TotalHaber"        NUMERIC,
    "Estado"            VARCHAR,
    "OrigenModulo"      VARCHAR,
    "OrigenDocumento"   VARCHAR,
    "CodUsuario"        VARCHAR,
    "FechaCreacion"     TIMESTAMP,
    "FechaAnulacion"    TIMESTAMP,
    "UsuarioAnulacion"  VARCHAR,
    "MotivoAnulacion"   VARCHAR
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 3. Obtener un asiento contable - detalle
-- Original: dbo.usp_Contabilidad_Asiento_Get (result set 2)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_asiento_get_detalle(BIGINT);

CREATE OR REPLACE FUNCTION usp_contabilidad_asiento_get_detalle(
    p_asiento_id BIGINT
)
RETURNS TABLE(
    "Id"              BIGINT,
    "AsientoId"       BIGINT,
    "Renglon"         INT,
    "CodCuenta"       VARCHAR,
    "Descripcion"     VARCHAR,
    "CentroCosto"     VARCHAR,
    "AuxiliarTipo"    VARCHAR,
    "AuxiliarCodigo"  VARCHAR,
    "Documento"       VARCHAR,
    "Debe"            NUMERIC,
    "Haber"           NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT d."Id", d."AsientoId", d."Renglon", d."CodCuenta", d."Descripcion",
           d."CentroCosto", d."AuxiliarTipo", d."AuxiliarCodigo", d."Documento",
           d."Debe", d."Haber"
    FROM "AsientoContableDetalle" d
    WHERE d."AsientoId" = p_asiento_id
    ORDER BY d."Renglon", d."Id";
END;
$$;

-- =============================================
-- 4. Crear asiento contable
-- Original: dbo.usp_Contabilidad_Asiento_Crear
-- XML -> JSONB: p_detalle_json reemplaza @DetalleXml
-- SCOPE_IDENTITY() -> RETURNING INTO
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_asiento_crear(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, VARCHAR, JSONB);

CREATE OR REPLACE FUNCTION usp_contabilidad_asiento_crear(
    p_fecha             DATE,
    p_tipo_asiento      VARCHAR(20),
    p_referencia        VARCHAR(120) DEFAULT NULL,
    p_concepto          VARCHAR(400) DEFAULT '',
    p_moneda            VARCHAR(10) DEFAULT 'VES',
    p_tasa              NUMERIC(18,6) DEFAULT 1,
    p_origen_modulo     VARCHAR(40) DEFAULT NULL,
    p_origen_documento  VARCHAR(120) DEFAULT NULL,
    p_cod_usuario       VARCHAR(40) DEFAULT NULL,
    p_detalle_json      JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "AsientoId"      BIGINT,
    "NumeroAsiento"  VARCHAR,
    "Resultado"      INT,
    "Mensaje"        TEXT
)
LANGUAGE plpgsql
AS $$
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
        NULLIF(item->>'codCuenta', ''::VARCHAR),
        NULLIF(item->>'descripcion', ''::VARCHAR),
        NULLIF(item->>'centroCosto', ''::VARCHAR),
        NULLIF(item->>'auxiliarTipo', ''::VARCHAR),
        NULLIF(item->>'auxiliarCodigo', ''::VARCHAR),
        NULLIF(item->>'documento', ''::VARCHAR),
        COALESCE(NULLIF(item->>'debe', ''::VARCHAR)::NUMERIC(18,2), 0),
        COALESCE(NULLIF(item->>'haber', ''::VARCHAR)::NUMERIC(18,2), 0)
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
$$;

-- =============================================
-- 5. Anular asiento contable
-- Original: dbo.usp_Contabilidad_Asiento_Anular
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_asiento_anular(BIGINT, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION usp_contabilidad_asiento_anular(
    p_asiento_id  BIGINT,
    p_motivo      VARCHAR(400),
    p_cod_usuario VARCHAR(40)
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   TEXT
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 6. Crear ajuste contable
-- Original: dbo.usp_Contabilidad_Ajuste_Crear
-- Llama internamente a usp_contabilidad_asiento_crear
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_ajuste_crear(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, JSONB);

CREATE OR REPLACE FUNCTION usp_contabilidad_ajuste_crear(
    p_fecha         DATE,
    p_tipo_ajuste   VARCHAR(40),
    p_referencia    VARCHAR(120) DEFAULT NULL,
    p_motivo        VARCHAR(500) DEFAULT '',
    p_cod_usuario   VARCHAR(40) DEFAULT NULL,
    p_detalle_json  JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "AsientoId" BIGINT,
    "Resultado" INT,
    "Mensaje"   TEXT
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 7. Generar depreciacion contable
-- Original: dbo.usp_Contabilidad_Depreciacion_Generar
-- DECLARE @var TABLE -> CREATE TEMP TABLE ... ON COMMIT DROP
-- FOR XML PATH -> jsonb_agg(row_to_json(...))
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_depreciacion_generar(VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION usp_contabilidad_depreciacion_generar(
    p_periodo      VARCHAR(7),    -- YYYY-MM
    p_cod_usuario  VARCHAR(40),
    p_centro_costo VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   TEXT
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 8. Mayor Analitico
-- Original: dbo.usp_Contabilidad_Mayor_Analitico
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_mayor_analitico(VARCHAR, DATE, DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_mayor_analitico(
    p_cod_cuenta  VARCHAR(40),
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "Fecha"              DATE,
    "NumeroAsiento"      VARCHAR,
    "Referencia"         VARCHAR,
    "Concepto"           VARCHAR,
    "Renglon"            INT,
    "CodCuenta"          VARCHAR,
    "CuentaDescripcion"  VARCHAR,
    "CentroCosto"        VARCHAR,
    "AuxiliarTipo"       VARCHAR,
    "AuxiliarCodigo"     VARCHAR,
    "Documento"          VARCHAR,
    "Debe"               NUMERIC,
    "Haber"              NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 9. Libro Mayor
-- Original: dbo.usp_Contabilidad_Libro_Mayor
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_libro_mayor(DATE, DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_libro_mayor(
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "CodCuenta"          VARCHAR,
    "CuentaDescripcion"  VARCHAR,
    "Debe"               NUMERIC,
    "Haber"              NUMERIC,
    "Saldo"              NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 10. Balance de Comprobacion
-- Original: dbo.usp_Contabilidad_Balance_Comprobacion
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_balance_comprobacion(DATE, DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_balance_comprobacion(
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "CodCuenta"          VARCHAR,
    "CuentaDescripcion"  VARCHAR,
    "TotalDebe"          NUMERIC,
    "TotalHaber"         NUMERIC,
    "SaldoDeudor"        NUMERIC,
    "SaldoAcreedor"      NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 11. Estado de Resultados - detalle por cuenta
-- Original: dbo.usp_Contabilidad_Estado_Resultados (result set 1)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_estado_resultados(DATE, DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_estado_resultados(
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "Grupo"              VARCHAR,
    "CodCuenta"          VARCHAR,
    "CuentaDescripcion"  VARCHAR,
    "Debe"               NUMERIC,
    "Haber"              NUMERIC,
    "Neto"               NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 12. Estado de Resultados - resumen
-- Original: dbo.usp_Contabilidad_Estado_Resultados (result set 2)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_estado_resultados_resumen(DATE, DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_estado_resultados_resumen(
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "TotalIngresos"  NUMERIC,
    "TotalCostos"    NUMERIC,
    "TotalGastos"    NUMERIC,
    "ResultadoNeto"  NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 13. Balance General - detalle por cuenta
-- Original: dbo.usp_Contabilidad_Balance_General (result set 1)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_balance_general(DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_balance_general(
    p_fecha_corte DATE
)
RETURNS TABLE(
    "Grupo"              VARCHAR,
    "CodCuenta"          VARCHAR,
    "CuentaDescripcion"  VARCHAR,
    "Saldo"              NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================
-- 14. Balance General - resumen
-- Original: dbo.usp_Contabilidad_Balance_General (result set 2)
-- =============================================
DROP FUNCTION IF EXISTS usp_contabilidad_balance_general_resumen(DATE);

CREATE OR REPLACE FUNCTION usp_contabilidad_balance_general_resumen(
    p_fecha_corte DATE
)
RETURNS TABLE(
    "TotalActivos"    NUMERIC,
    "TotalPasivos"    NUMERIC,
    "TotalPatrimonio" NUMERIC
)
LANGUAGE plpgsql
AS $$
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
$$;
