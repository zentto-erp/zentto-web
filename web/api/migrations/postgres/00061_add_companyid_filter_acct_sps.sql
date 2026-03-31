-- +goose Up
-- Migration: Agregar CompanyId a tablas contabilidad legacy y filtrar en SPs de contabilidad/acct
-- Las tablas "AsientoContable", "AsientoContableDetalle" y "AjusteContable" son legacy (public schema)
-- y no tenían CompanyId. Se agrega la columna y se actualizan todas las funciones para filtrar por empresa.

-- ============================================================
-- 1) ALTER TABLE: agregar CompanyId a tablas legacy contabilidad
-- ============================================================

-- +goose StatementBegin
DO $$
BEGIN
    -- AsientoContable (tabla legacy, puede no existir en todos los entornos)
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'AsientoContable'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'AsientoContable' AND column_name = 'CompanyId'
    ) THEN
        ALTER TABLE public."AsientoContable" ADD COLUMN "CompanyId" INTEGER;
        CREATE INDEX IF NOT EXISTS "IX_AsientoContable_CompanyId" ON public."AsientoContable" ("CompanyId");
    END IF;

    -- AsientoContableDetalle (no necesita CompanyId propio, se filtra via JOIN con AsientoContable)

    -- AjusteContable (tabla legacy, puede no existir en todos los entornos)
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'AjusteContable'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'AjusteContable' AND column_name = 'CompanyId'
    ) THEN
        ALTER TABLE public."AjusteContable" ADD COLUMN "CompanyId" INTEGER;
    END IF;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 2) Child-table functions: agregar p_company_id con validación via parent JOIN
-- ============================================================

-- 2a) usp_acct_budget_getlines — child de Budget (que ya tiene CompanyId)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_budget_getlines(
    p_company_id integer,
    p_budget_id integer
) RETURNS TABLE(
    "BudgetLineId" bigint,
    "AccountCode" character varying,
    "AccountName" character varying,
    "Month01" numeric, "Month02" numeric, "Month03" numeric, "Month04" numeric,
    "Month05" numeric, "Month06" numeric, "Month07" numeric, "Month08" numeric,
    "Month09" numeric, "Month10" numeric, "Month11" numeric, "Month12" numeric,
    "AnnualTotal" numeric,
    "Notes" character varying
)
    LANGUAGE plpgsql
    AS $$
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
    INNER JOIN acct."Budget" b ON b."BudgetId" = bl."BudgetId" AND b."CompanyId" = p_company_id
    LEFT JOIN acct."Account" a ON a."AccountCode" = bl."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE bl."BudgetId" = p_budget_id
    ORDER BY bl."AccountCode";
END;
$$;
-- +goose StatementEnd

-- 2b) usp_acct_recurringentry_getlines — child de RecurringEntry (que ya tiene CompanyId)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_recurringentry_getlines(
    p_company_id integer,
    p_recurring_entry_id integer
) RETURNS TABLE(
    "LineId" integer,
    "AccountCode" character varying,
    "AccountName" character varying,
    "Description" character varying,
    "CostCenterCode" character varying,
    "Debit" numeric,
    "Credit" numeric
)
    LANGUAGE plpgsql
    AS $$
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
    INNER JOIN acct."RecurringEntry" re ON re."RecurringEntryId" = rel."RecurringEntryId" AND re."CompanyId" = p_company_id
    LEFT JOIN acct."Account" a ON a."AccountCode" = rel."AccountCode" AND COALESCE(a."IsDeleted", FALSE) = FALSE
    WHERE rel."RecurringEntryId" = p_recurring_entry_id
    ORDER BY rel."LineId";
END;
$$;
-- +goose StatementEnd

-- 2c) usp_acct_reporttemplate_get_variables — child de ReportTemplate (que ya tiene CompanyId)
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_reporttemplate_get_variables(
    p_company_id integer,
    p_report_template_id integer
) RETURNS TABLE(
    "VariableId" integer,
    "VariableName" character varying,
    "VariableType" character varying,
    "DataSource" character varying,
    "DefaultValue" character varying,
    "Description" character varying,
    "SortOrder" integer
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT rtv."VariableId", rtv."VariableName", rtv."VariableType", rtv."DataSource",
           rtv."DefaultValue", rtv."Description", rtv."SortOrder"
    FROM acct."ReportTemplateVariable" rtv
    INNER JOIN acct."ReportTemplate" rt ON rt."ReportTemplateId" = rtv."ReportTemplateId" AND rt."CompanyId" = p_company_id
    WHERE rtv."ReportTemplateId" = p_report_template_id
    ORDER BY rtv."SortOrder";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 3) Contabilidad functions: agregar p_company_id como primer parametro
-- ============================================================

-- 3a) usp_contabilidad_asiento_get_header
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_asiento_get_header(
    p_company_id integer,
    p_asiento_id bigint
) RETURNS TABLE(
    "Id" bigint, "NumeroAsiento" character varying, "Fecha" date, "Periodo" character varying,
    "TipoAsiento" character varying, "Referencia" character varying, "Concepto" character varying,
    "Moneda" character varying, "Tasa" numeric, "TotalDebe" numeric, "TotalHaber" numeric,
    "Estado" character varying, "OrigenModulo" character varying, "OrigenDocumento" character varying,
    "CodUsuario" character varying, "FechaCreacion" timestamp without time zone,
    "FechaAnulacion" timestamp without time zone, "UsuarioAnulacion" character varying,
    "MotivoAnulacion" character varying
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
    WHERE a."Id" = p_asiento_id
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL);
END;
$$;
-- +goose StatementEnd

-- 3b) usp_contabilidad_asiento_get_detalle
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_asiento_get_detalle(
    p_company_id integer,
    p_asiento_id bigint
) RETURNS TABLE(
    "Id" bigint, "AsientoId" bigint, "Renglon" integer,
    "CodCuenta" character varying, "Descripcion" character varying,
    "CentroCosto" character varying, "AuxiliarTipo" character varying,
    "AuxiliarCodigo" character varying, "Documento" character varying,
    "Debe" numeric, "Haber" numeric
)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d."Id", d."AsientoId", d."Renglon", d."CodCuenta", d."Descripcion",
           d."CentroCosto", d."AuxiliarTipo", d."AuxiliarCodigo", d."Documento",
           d."Debe", d."Haber"
    FROM "AsientoContableDetalle" d
    INNER JOIN "AsientoContable" a ON a."Id" = d."AsientoId"
    WHERE d."AsientoId" = p_asiento_id
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
    ORDER BY d."Renglon", d."Id";
END;
$$;
-- +goose StatementEnd

-- 3c) usp_contabilidad_asientos_list
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_asientos_list(
    p_company_id integer,
    p_fecha_desde date DEFAULT NULL::date,
    p_fecha_hasta date DEFAULT NULL::date,
    p_tipo_asiento character varying DEFAULT NULL::character varying,
    p_estado character varying DEFAULT NULL::character varying,
    p_origen_modulo character varying DEFAULT NULL::character varying,
    p_origen_documento character varying DEFAULT NULL::character varying,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 50
) RETURNS TABLE(
    "TotalCount" bigint, "Id" bigint, "NumeroAsiento" character varying, "Fecha" date,
    "Periodo" character varying, "TipoAsiento" character varying, "Referencia" character varying,
    "Concepto" character varying, "Moneda" character varying, "Tasa" numeric,
    "TotalDebe" numeric, "TotalHaber" numeric, "Estado" character varying,
    "OrigenModulo" character varying, "OrigenDocumento" character varying,
    "CodUsuario" character varying, "FechaCreacion" timestamp without time zone,
    "FechaAnulacion" timestamp without time zone, "UsuarioAnulacion" character varying,
    "MotivoAnulacion" character varying
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
    WHERE (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND (p_fecha_desde IS NULL OR a."Fecha" >= p_fecha_desde)
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
    WHERE (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND (p_fecha_desde IS NULL OR a."Fecha" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR a."Fecha" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR a."TipoAsiento" = p_tipo_asiento)
      AND (p_estado IS NULL OR a."Estado" = p_estado)
      AND (p_origen_modulo IS NULL OR a."OrigenModulo" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR a."OrigenDocumento" = p_origen_documento)
    ORDER BY a."Id" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- 3d) usp_contabilidad_balance_comprobacion
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_balance_comprobacion(
    p_company_id integer,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE(
    "CodCuenta" character varying, "CuentaDescripcion" character varying,
    "TotalDebe" numeric, "TotalHaber" numeric,
    "SaldoDeudor" numeric, "SaldoAcreedor" numeric
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
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY d."CodCuenta", c."DESCRIPCION"
    ORDER BY d."CodCuenta";
END;
$$;
-- +goose StatementEnd

-- 3e) usp_contabilidad_balance_general
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_balance_general(
    p_company_id integer,
    p_fecha_corte date
) RETURNS TABLE(
    "Grupo" character varying, "CodCuenta" character varying,
    "CuentaDescripcion" character varying, "Saldo" numeric
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
          AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
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
-- +goose StatementEnd

-- 3f) usp_contabilidad_balance_general_resumen
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_balance_general_resumen(
    p_company_id integer,
    p_fecha_corte date
) RETURNS TABLE("TotalActivos" numeric, "TotalPasivos" numeric, "TotalPatrimonio" numeric)
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
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND a."Fecha" <= p_fecha_corte;
END;
$$;
-- +goose StatementEnd

-- 3g) usp_contabilidad_estado_resultados
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_estado_resultados(
    p_company_id integer,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE(
    "Grupo" character varying, "CodCuenta" character varying,
    "CuentaDescripcion" character varying, "Debe" numeric, "Haber" numeric, "Neto" numeric
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
          AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
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
-- +goose StatementEnd

-- 3h) usp_contabilidad_estado_resultados_resumen
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_estado_resultados_resumen(
    p_company_id integer,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE("TotalIngresos" numeric, "TotalCostos" numeric, "TotalGastos" numeric, "ResultadoNeto" numeric)
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
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta;
END;
$$;
-- +goose StatementEnd

-- 3i) usp_contabilidad_libro_mayor
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_libro_mayor(
    p_company_id integer,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE(
    "CodCuenta" character varying, "CuentaDescripcion" character varying,
    "Debe" numeric, "Haber" numeric, "Saldo" numeric
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
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    GROUP BY d."CodCuenta", c."DESCRIPCION"
    ORDER BY d."CodCuenta";
END;
$$;
-- +goose StatementEnd

-- 3j) usp_contabilidad_mayor_analitico
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_mayor_analitico(
    p_company_id integer,
    p_cod_cuenta character varying,
    p_fecha_desde date,
    p_fecha_hasta date
) RETURNS TABLE(
    "Fecha" date, "NumeroAsiento" character varying, "Referencia" character varying,
    "Concepto" character varying, "Renglon" integer, "CodCuenta" character varying,
    "CuentaDescripcion" character varying, "CentroCosto" character varying,
    "AuxiliarTipo" character varying, "AuxiliarCodigo" character varying,
    "Documento" character varying, "Debe" numeric, "Haber" numeric
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
      AND (a."CompanyId" = p_company_id OR a."CompanyId" IS NULL)
      AND a."Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
    ORDER BY a."Fecha", a."Id", d."Renglon";
END;
$$;
-- +goose StatementEnd

-- 3k) usp_contabilidad_asiento_crear — INSERT: guarda CompanyId en AsientoContable
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_asiento_crear(
    p_company_id integer,
    p_fecha date,
    p_tipo_asiento character varying,
    p_referencia character varying DEFAULT NULL::character varying,
    p_concepto character varying DEFAULT ''::character varying,
    p_moneda character varying DEFAULT 'VES'::character varying,
    p_tasa numeric DEFAULT 1,
    p_origen_modulo character varying DEFAULT NULL::character varying,
    p_origen_documento character varying DEFAULT NULL::character varying,
    p_cod_usuario character varying DEFAULT NULL::character varying,
    p_detalle_json jsonb DEFAULT '[]'::jsonb
) RETURNS TABLE("AsientoId" bigint, "NumeroAsiento" character varying, "Resultado" integer, "Mensaje" text)
    LANGUAGE plpgsql
    AS $_$
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

    -- Generar numero secuencial (filtrado por company)
    SELECT COALESCE(MAX(
        CASE WHEN RIGHT("NumeroAsiento", 8) ~ '^\d+$'
             THEN RIGHT("NumeroAsiento", 8)::INT
             ELSE 0 END
    ), 0) + 1
    INTO v_next
    FROM "AsientoContable"
    WHERE "CompanyId" = p_company_id OR "CompanyId" IS NULL;

    v_numero_asiento := 'AST-' || LPAD(v_next::TEXT, 8, '0');

    INSERT INTO "AsientoContable" (
        "CompanyId", "NumeroAsiento", "Fecha", "Periodo", "TipoAsiento", "Referencia", "Concepto", "Moneda", "Tasa",
        "TotalDebe", "TotalHaber", "Estado", "OrigenModulo", "OrigenDocumento", "CodUsuario", "FechaCreacion"
    )
    VALUES (
        p_company_id, v_numero_asiento, p_fecha, v_periodo, p_tipo_asiento, p_referencia, p_concepto, p_moneda, p_tasa,
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
$_$;
-- +goose StatementEnd

-- 3l) usp_contabilidad_asiento_anular — UPDATE: valida CompanyId
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_asiento_anular(
    p_company_id integer,
    p_asiento_id bigint,
    p_motivo character varying,
    p_cod_usuario character varying
) RETURNS TABLE("Resultado" integer, "Mensaje" text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM "AsientoContable"
        WHERE "Id" = p_asiento_id
          AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL)
    ) THEN
        RETURN QUERY SELECT -1, 'Asiento no encontrado'::TEXT;
        RETURN;
    END IF;

    UPDATE "AsientoContable"
    SET "Estado" = 'ANULADO',
        "FechaAnulacion" = NOW() AT TIME ZONE 'UTC',
        "UsuarioAnulacion" = p_cod_usuario,
        "MotivoAnulacion" = p_motivo
    WHERE "Id" = p_asiento_id
      AND ("CompanyId" = p_company_id OR "CompanyId" IS NULL);

    RETURN QUERY SELECT 1, 'OK'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::TEXT;
END;
$$;
-- +goose StatementEnd

-- 3m) usp_contabilidad_ajuste_crear — INSERT: pasa CompanyId a asiento_crear y guarda en AjusteContable
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_contabilidad_ajuste_crear(
    p_company_id integer,
    p_fecha date,
    p_tipo_ajuste character varying,
    p_referencia character varying DEFAULT NULL::character varying,
    p_motivo character varying DEFAULT ''::character varying,
    p_cod_usuario character varying DEFAULT NULL::character varying,
    p_detalle_json jsonb DEFAULT '[]'::jsonb
) RETURNS TABLE("AsientoId" bigint, "Resultado" integer, "Mensaje" text)
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
        p_company_id,
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
        INSERT INTO "AjusteContable" ("AsientoId", "TipoAjuste", "Motivo", "Fecha", "Estado", "CodUsuario", "CompanyId")
        VALUES (v_asiento_id, p_tipo_ajuste, p_motivo, p_fecha, 'APROBADO', p_cod_usuario, p_company_id);
    END IF;

    RETURN QUERY SELECT v_asiento_id, v_resultado, v_mensaje;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- Revert: solo comentarios — no se eliminan columnas CompanyId para no perder datos
-- Las funciones antiguas sin p_company_id quedarían desactualizadas; un rollback completo
-- requeriría recrearlas con las firmas originales, lo cual es destructivo.
