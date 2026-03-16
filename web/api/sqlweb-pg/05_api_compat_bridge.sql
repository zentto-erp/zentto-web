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
-- TABLAS LEGACY en schema public (equivalente a dbo.*)
-- ============================================================

-- Cuentas
CREATE TABLE IF NOT EXISTS public."Cuentas" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Cod_Cuenta"      VARCHAR(40)   NOT NULL,
  "Desc_Cta"        VARCHAR(200)  NOT NULL,
  "Tipo"            CHAR(1)       NOT NULL,
  "Nivel"           INT           NOT NULL DEFAULT 1,
  "Cod_CtaPadre"    VARCHAR(40)   NULL,
  "Activo"          BOOLEAN       NOT NULL DEFAULT TRUE,
  "Accepta_Detalle" BOOLEAN       NOT NULL DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_Cuentas_CodCuenta" UNIQUE ("Cod_Cuenta"),
  CONSTRAINT "CK_Cuentas_Tipo" CHECK ("Tipo" IN ('A','P','C','I','G'))
);

-- Asientos
CREATE TABLE IF NOT EXISTS public."Asientos" (
  "Id"                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Fecha"              DATE          NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
  "Tipo_Asiento"       VARCHAR(20)   NOT NULL,
  "Concepto"           VARCHAR(400)  NOT NULL,
  "Referencia"         VARCHAR(120)  NULL,
  "Estado"             VARCHAR(20)   NOT NULL DEFAULT 'APROBADO',
  "Total_Debe"         NUMERIC(18,2) NOT NULL DEFAULT 0,
  "Total_Haber"        NUMERIC(18,2) NOT NULL DEFAULT 0,
  "Origen_Modulo"      VARCHAR(40)   NULL,
  "Cod_Usuario"        VARCHAR(120)  NULL,
  "AsientoContableId"  BIGINT        NULL,
  "FechaCreacion"      TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "FechaActualizacion" TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_Asientos_Fecha"
  ON public."Asientos" ("Fecha" DESC, "Id" DESC);
CREATE INDEX IF NOT EXISTS "IX_Asientos_AsientoContableId"
  ON public."Asientos" ("AsientoContableId");

-- Asientos_Detalle
CREATE TABLE IF NOT EXISTS public."Asientos_Detalle" (
  "Id"             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Id_Asiento"     INT           NOT NULL,
  "Cod_Cuenta"     VARCHAR(40)   NOT NULL,
  "Descripcion"    VARCHAR(400)  NULL,
  "CentroCosto"    VARCHAR(20)   NULL,
  "AuxiliarTipo"   VARCHAR(30)   NULL,
  "AuxiliarCodigo" VARCHAR(120)  NULL,
  "Documento"      VARCHAR(120)  NULL,
  "Debe"           NUMERIC(18,2) NOT NULL DEFAULT 0,
  "Haber"          NUMERIC(18,2) NOT NULL DEFAULT 0,
  "FechaCreacion"  TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "FK_AsientosDetalle_Asientos" FOREIGN KEY ("Id_Asiento") REFERENCES public."Asientos"("Id")
);

CREATE INDEX IF NOT EXISTS "IX_AsientosDetalle_IdAsiento"
  ON public."Asientos_Detalle" ("Id_Asiento", "Id");
CREATE INDEX IF NOT EXISTS "IX_AsientosDetalle_CodCuenta"
  ON public."Asientos_Detalle" ("Cod_Cuenta");

-- TasasDiarias
CREATE TABLE IF NOT EXISTS public."TasasDiarias" (
  "Id"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Moneda"    VARCHAR(10)    NOT NULL,
  "Tasa"      NUMERIC(18,6)  NOT NULL,
  "Fecha"     TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "Origen"    VARCHAR(120)   NULL,
  "CreatedAt" TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_TasasDiarias_Moneda_Fecha"
  ON public."TasasDiarias" ("Moneda", "Fecha" DESC);

-- FiscalCountryConfig
CREATE TABLE IF NOT EXISTS public."FiscalCountryConfig" (
  "Id"                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"            INT        NOT NULL,
  "SucursalId"           INT        NOT NULL,
  "CountryCode"          CHAR(2)    NOT NULL,
  "Currency"             CHAR(3)    NOT NULL,
  "TaxRegime"            VARCHAR(50) NULL,
  "DefaultTaxCode"       VARCHAR(30) NULL,
  "DefaultTaxRate"       NUMERIC(9,4) NOT NULL,
  "FiscalPrinterEnabled" BOOLEAN    NOT NULL DEFAULT FALSE,
  "PrinterBrand"         VARCHAR(30) NULL,
  "PrinterPort"          VARCHAR(20) NULL,
  "VerifactuEnabled"     BOOLEAN    NOT NULL DEFAULT FALSE,
  "VerifactuMode"        VARCHAR(10) NULL,
  "CertificatePath"      VARCHAR(500) NULL,
  "CertificatePassword"  VARCHAR(255) NULL,
  "AEATEndpoint"         VARCHAR(500) NULL,
  "SenderNIF"            VARCHAR(20) NULL,
  "SenderRIF"            VARCHAR(20) NULL,
  "SoftwareId"           VARCHAR(100) NULL,
  "SoftwareName"         VARCHAR(200) NULL,
  "SoftwareVersion"      VARCHAR(20)  NULL,
  "PosEnabled"           BOOLEAN    NOT NULL DEFAULT TRUE,
  "RestaurantEnabled"    BOOLEAN    NOT NULL DEFAULT TRUE,
  "IsActive"             BOOLEAN    NOT NULL DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_FiscalCountryConfig" UNIQUE ("EmpresaId", "SucursalId", "CountryCode"),
  CONSTRAINT "FK_FiscalCountryConfig_Company" FOREIGN KEY ("EmpresaId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_FiscalCountryConfig_Branch" FOREIGN KEY ("SucursalId") REFERENCES cfg."Branch"("BranchId")
);

-- FiscalTaxRates
CREATE TABLE IF NOT EXISTS public."FiscalTaxRates" (
  "Id"                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CountryCode"         CHAR(2)       NOT NULL,
  "Code"                VARCHAR(30)   NOT NULL,
  "Name"                VARCHAR(120)  NOT NULL,
  "Rate"                NUMERIC(9,4)  NOT NULL,
  "SurchargeRate"       NUMERIC(9,4)  NULL,
  "AppliesToPOS"        BOOLEAN       NOT NULL DEFAULT TRUE,
  "AppliesToRestaurant" BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsDefault"           BOOLEAN       NOT NULL DEFAULT FALSE,
  "IsActive"            BOOLEAN       NOT NULL DEFAULT TRUE,
  "SortOrder"           INT           NOT NULL DEFAULT 0,
  "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_FiscalTaxRates" UNIQUE ("CountryCode", "Code")
);

-- FiscalInvoiceTypes
CREATE TABLE IF NOT EXISTS public."FiscalInvoiceTypes" (
  "Id"                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CountryCode"           CHAR(2)      NOT NULL,
  "Code"                  VARCHAR(20)  NOT NULL,
  "Name"                  VARCHAR(120) NOT NULL,
  "IsRectificative"       BOOLEAN      NOT NULL DEFAULT FALSE,
  "RequiresRecipientId"   BOOLEAN      NOT NULL DEFAULT FALSE,
  "MaxAmount"             NUMERIC(18,2) NULL,
  "RequiresFiscalPrinter" BOOLEAN      NOT NULL DEFAULT FALSE,
  "IsActive"              BOOLEAN      NOT NULL DEFAULT TRUE,
  "SortOrder"             INT          NOT NULL DEFAULT 0,
  "CreatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"             TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_FiscalInvoiceTypes" UNIQUE ("CountryCode", "Code")
);

-- FiscalRecords
CREATE TABLE IF NOT EXISTS public."FiscalRecords" (
  "Id"                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"           INT           NOT NULL,
  "SucursalId"          INT           NOT NULL,
  "CountryCode"         CHAR(2)       NOT NULL,
  "InvoiceId"           INT           NOT NULL,
  "InvoiceType"         VARCHAR(20)   NOT NULL,
  "InvoiceNumber"       VARCHAR(50)   NOT NULL,
  "InvoiceDate"         DATE          NOT NULL,
  "RecipientId"         VARCHAR(20)   NULL,
  "TotalAmount"         NUMERIC(18,2) NOT NULL,
  "RecordHash"          VARCHAR(64)   NOT NULL,
  "PreviousRecordHash"  VARCHAR(64)   NULL,
  "XmlContent"          TEXT          NULL,
  "DigitalSignature"    TEXT          NULL,
  "QRCodeData"          VARCHAR(800)  NULL,
  "SentToAuthority"     BOOLEAN       NOT NULL DEFAULT FALSE,
  "SentAt"              TIMESTAMP     NULL,
  "AuthorityResponse"   TEXT          NULL,
  "AuthorityStatus"     VARCHAR(20)   NULL,
  "FiscalPrinterSerial" VARCHAR(30)   NULL,
  "FiscalControlNumber" VARCHAR(30)   NULL,
  "ZReportNumber"       INT           NULL,
  "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_FiscalRecords_Hash" UNIQUE ("RecordHash"),
  CONSTRAINT "FK_FiscalRecords_Config" FOREIGN KEY ("EmpresaId", "SucursalId", "CountryCode")
    REFERENCES public."FiscalCountryConfig"("EmpresaId", "SucursalId", "CountryCode")
);

CREATE INDEX IF NOT EXISTS "IX_FiscalRecords_Search"
  ON public."FiscalRecords" ("EmpresaId", "SucursalId", "CountryCode", "Id" DESC);

-- ============================================================
-- VISTA: DtllAsiento (compatibilidad)
-- ============================================================
CREATE OR REPLACE VIEW public."DtllAsiento" AS
  SELECT
    "Id"::BIGINT          AS "Id",
    "Id_Asiento"::BIGINT  AS "Id_Asiento",
    "Cod_Cuenta",
    "Descripcion",
    "Debe",
    "Haber"
  FROM public."Asientos_Detalle";

-- ============================================================
-- FUNCIONES de compatibilidad contable (equivalentes a SPs)
-- ============================================================

-- sp_CxC_Documentos_List
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
