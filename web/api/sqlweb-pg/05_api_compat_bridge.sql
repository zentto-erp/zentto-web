-- ============================================================
-- DatqBoxWeb PostgreSQL - 05_api_compat_bridge.sql
-- Tablas legacy de compatibilidad (dbo.* -> public.*),
-- vistas de compatibilidad, y stored procedures contables
-- ============================================================

BEGIN;

-- ============================================================
-- Obtener IDs por defecto
-- ============================================================
DO $$
DECLARE
  v_DefaultCompanyId INT;
  v_DefaultBranchId  INT;
  v_SystemUserId     INT;
BEGIN
  SELECT "CompanyId" INTO v_DefaultCompanyId
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
  SELECT "BranchId" INTO v_DefaultBranchId
    FROM cfg."Branch" WHERE "CompanyId" = v_DefaultCompanyId AND "BranchCode" = 'MAIN' LIMIT 1;

  IF v_DefaultCompanyId IS NULL OR v_DefaultBranchId IS NULL THEN
    RAISE EXCEPTION 'Missing DEFAULT company/MAIN branch. Run 01_core_foundation.sql first.';
  END IF;
END $$;

-- ============================================================
-- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
-- Usar esquemas canonicos: acct.*, fiscal.*, cfg.*, etc.
-- Tablas eliminadas: Cuentas, Asientos, Asientos_Detalle,
--   TasasDiarias, FiscalCountryConfig, FiscalTaxRates,
--   FiscalInvoiceTypes, FiscalRecords, vista DtllAsiento.
-- ============================================================

-- ============================================================
-- FUNCIONES de compatibilidad contable (equivalentes a SPs)
-- ============================================================

-- sp_CxC_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxC_Documentos_List"(VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."sp_CxC_Documentos_List"(
  p_CodCliente  VARCHAR DEFAULT NULL,
  p_TipoDoc     VARCHAR DEFAULT NULL,
  p_Estado      VARCHAR DEFAULT NULL,
  p_FechaDesde  DATE    DEFAULT NULL,
  p_FechaHasta  DATE    DEFAULT NULL,
  p_Page        INT     DEFAULT 1,
  p_Limit       INT     DEFAULT 50
)
RETURNS TABLE (
  "codCliente"   VARCHAR,
  "tipoDoc"      VARCHAR,
  "numDoc"       VARCHAR,
  "fecha"        DATE,
  "total"        NUMERIC,
  "pendiente"    NUMERIC,
  "estado"       VARCHAR,
  "observacion"  VARCHAR,
  "codUsuario"   VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
BEGIN
  RETURN QUERY
  SELECT
    c."CustomerCode"::VARCHAR      AS "codCliente",
    d."DocumentType"::VARCHAR      AS "tipoDoc",
    d."DocumentNumber"::VARCHAR    AS "numDoc",
    d."IssueDate"                  AS "fecha",
    d."TotalAmount"                AS "total",
    d."PendingAmount"              AS "pendiente",
    d."Status"::VARCHAR            AS "estado",
    d."Notes"::VARCHAR             AS "observacion",
    u."UserCode"::VARCHAR          AS "codUsuario"
  FROM ar."ReceivableDocument" d
  INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"
  WHERE (p_CodCliente IS NULL OR c."CustomerCode" = p_CodCliente)
    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)
    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)
    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)
  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."ReceivableDocumentId" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$$;

-- sp_CxP_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxP_Documentos_List"(VARCHAR, VARCHAR, VARCHAR, DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."sp_CxP_Documentos_List"(
  p_CodProveedor VARCHAR DEFAULT NULL,
  p_TipoDoc      VARCHAR DEFAULT NULL,
  p_Estado       VARCHAR DEFAULT NULL,
  p_FechaDesde   DATE    DEFAULT NULL,
  p_FechaHasta   DATE    DEFAULT NULL,
  p_Page         INT     DEFAULT 1,
  p_Limit        INT     DEFAULT 50
)
RETURNS TABLE (
  "codProveedor" VARCHAR,
  "tipoDoc"      VARCHAR,
  "numDoc"       VARCHAR,
  "fecha"        DATE,
  "total"        NUMERIC,
  "pendiente"    NUMERIC,
  "estado"       VARCHAR,
  "observacion"  VARCHAR,
  "codUsuario"   VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);
  v_Offset INT := (v_Page - 1) * v_Limit;
BEGIN
  RETURN QUERY
  SELECT
    s."SupplierCode"::VARCHAR      AS "codProveedor",
    d."DocumentType"::VARCHAR      AS "tipoDoc",
    d."DocumentNumber"::VARCHAR    AS "numDoc",
    d."IssueDate"                  AS "fecha",
    d."TotalAmount"                AS "total",
    d."PendingAmount"              AS "pendiente",
    d."Status"::VARCHAR            AS "estado",
    d."Notes"::VARCHAR             AS "observacion",
    u."UserCode"::VARCHAR          AS "codUsuario"
  FROM ap."PayableDocument" d
  INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"
  WHERE (p_CodProveedor IS NULL OR s."SupplierCode" = p_CodProveedor)
    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)
    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)
    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)
    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)
  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."PayableDocumentId" DESC
  LIMIT v_Limit OFFSET v_Offset;
END;
$$;

-- ============================================================
-- Funciones contables: usp_Contabilidad_Asientos_List
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asientos_List"(DATE, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asientos_List"(
  p_FechaDesde      DATE    DEFAULT NULL,
  p_FechaHasta      DATE    DEFAULT NULL,
  p_TipoAsiento     VARCHAR DEFAULT NULL,
  p_Estado          VARCHAR DEFAULT NULL,
  p_OrigenModulo    VARCHAR DEFAULT NULL,
  p_OrigenDocumento VARCHAR DEFAULT NULL,
  p_Page            INT     DEFAULT 1,
  p_Limit           INT     DEFAULT 50
)
RETURNS TABLE(
  "AsientoId"      BIGINT,
  "NumeroAsiento"  VARCHAR,
  "Fecha"          DATE,
  "TipoAsiento"    VARCHAR,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Moneda"         VARCHAR,
  "Tasa"           NUMERIC,
  "TotalDebe"      NUMERIC,
  "TotalHaber"     NUMERIC,
  "Estado"         VARCHAR,
  "OrigenModulo"   VARCHAR,
  "CodUsuario"     VARCHAR,
  "TotalCount"     INT
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Asiento_Get
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Get"(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Get"(
  p_AsientoId BIGINT
)
RETURNS TABLE (
  "AsientoId"      BIGINT,
  "NumeroAsiento"  VARCHAR,
  "Fecha"          DATE,
  "TipoAsiento"    VARCHAR,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Moneda"         VARCHAR,
  "Tasa"           NUMERIC,
  "TotalDebe"      NUMERIC,
  "TotalHaber"     NUMERIC,
  "Estado"         VARCHAR,
  "OrigenModulo"   VARCHAR,
  "CodUsuario"     VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Asiento_Crear
-- Usa JSON en lugar de XML para el detalle
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Crear"(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, VARCHAR, JSONB, BIGINT, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Crear"(
  p_Fecha          DATE,
  p_TipoAsiento    VARCHAR,
  p_Referencia     VARCHAR DEFAULT NULL,
  p_Concepto       VARCHAR DEFAULT '',
  p_Moneda         VARCHAR DEFAULT 'VES',
  p_Tasa           NUMERIC DEFAULT 1,
  p_OrigenModulo   VARCHAR DEFAULT NULL,
  p_OrigenDocumento VARCHAR DEFAULT NULL,
  p_CodUsuario     VARCHAR DEFAULT NULL,
  p_DetalleJson    JSONB   DEFAULT '[]'::JSONB,
  OUT p_AsientoId      BIGINT,
  OUT p_NumeroAsiento  VARCHAR,
  OUT p_Resultado      INT,
  OUT p_Mensaje        VARCHAR
)
LANGUAGE plpgsql AS $$
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
    NULLIF(r->>'descripcion', ''),
    NULLIF(r->>'centroCosto', ''),
    NULLIF(r->>'auxiliarTipo', ''),
    NULLIF(r->>'auxiliarCodigo', ''),
    NULLIF(r->>'documento', ''),
    COALESCE((r->>'debe')::NUMERIC, 0),
    COALESCE((r->>'haber')::NUMERIC, 0)
  FROM jsonb_array_elements(p_DetalleJson) r;

  p_NumeroAsiento := 'LEG-' || LPAD(p_AsientoId::TEXT, 10, '0');
  p_Resultado := 1;
  p_Mensaje := 'Asiento creado correctamente.';
END;
$$;

-- ============================================================
-- usp_Contabilidad_Asiento_Anular
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Asiento_Anular"(BIGINT, VARCHAR, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Asiento_Anular"(
  p_AsientoId  BIGINT,
  p_Motivo     VARCHAR,
  p_CodUsuario VARCHAR DEFAULT NULL,
  OUT p_Resultado INT,
  OUT p_Mensaje   VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Ajuste_Crear
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Ajuste_Crear"(DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, JSONB, BIGINT, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Ajuste_Crear"(
  p_Fecha       DATE,
  p_TipoAjuste  VARCHAR,
  p_Referencia   VARCHAR DEFAULT NULL,
  p_Motivo       VARCHAR DEFAULT '',
  p_CodUsuario   VARCHAR DEFAULT NULL,
  p_DetalleJson  JSONB   DEFAULT '[]'::JSONB,
  OUT p_AsientoId  BIGINT,
  OUT p_Resultado  INT,
  OUT p_Mensaje    VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Depreciacion_Generar (stub)
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Depreciacion_Generar"(VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Depreciacion_Generar"(
  p_Periodo     VARCHAR,
  p_CodUsuario  VARCHAR DEFAULT NULL,
  p_CentroCosto VARCHAR DEFAULT NULL,
  OUT p_Resultado INT,
  OUT p_Mensaje   VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  p_Resultado := 1;
  p_Mensaje := 'Proceso de depreciacion preparado (sin reglas cargadas).';
END;
$$;

-- ============================================================
-- usp_Contabilidad_Libro_Mayor
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Libro_Mayor"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Libro_Mayor"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Mayor_Analitico
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Mayor_Analitico"(VARCHAR, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Mayor_Analitico"(
  p_CodCuenta  VARCHAR,
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "AsientoId"      INT,
  "Fecha"          DATE,
  "Referencia"     VARCHAR,
  "Concepto"       VARCHAR,
  "Descripcion"    VARCHAR,
  "Debe"           NUMERIC,
  "Haber"          NUMERIC,
  "SaldoAcumulado" NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Balance_Comprobacion
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_Comprobacion"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Balance_Comprobacion"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Estado_Resultados
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Estado_Resultados"(DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Estado_Resultados"(
  p_FechaDesde DATE,
  p_FechaHasta DATE
)
RETURNS TABLE (
  "Tipo"            CHAR(1),
  "CodCuenta"       VARCHAR,
  "Descripcion"     VARCHAR,
  "Debe"            NUMERIC,
  "Haber"           NUMERIC,
  "SaldoResultado"  NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- usp_Contabilidad_Balance_General
-- ============================================================
DROP FUNCTION IF EXISTS public."usp_Contabilidad_Balance_General"(DATE) CASCADE;
CREATE OR REPLACE FUNCTION public."usp_Contabilidad_Balance_General"(
  p_FechaCorte DATE
)
RETURNS TABLE (
  "Tipo"        CHAR(1),
  "CodCuenta"   VARCHAR,
  "Descripcion" VARCHAR,
  "Debe"        NUMERIC,
  "Haber"       NUMERIC,
  "Saldo"       NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- ============================================================
-- NOTA: Los triggers de sincronizacion bidireccional
-- (TR_Asientos_AI_SyncJournalEntry, TR_Cuentas_AIUD_SyncAccount,
--  TR_FiscalCountryConfig_AIUD_SyncCanonical, etc.) se implementan
-- como trigger functions en PG en un script separado de SPs.
-- Aqui solo se crean las tablas y funciones de consulta.
-- ============================================================

COMMIT;
