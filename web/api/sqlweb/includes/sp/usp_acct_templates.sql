/*
 * ============================================================================
 *  Archivo : usp_acct_templates.sql
 *  Esquema : acct (plantillas de reportes legales)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-15
 *
 *  Procedimientos (5):
 *    usp_Acct_ReportTemplate_List, usp_Acct_ReportTemplate_Get,
 *    usp_Acct_ReportTemplate_Upsert, usp_Acct_ReportTemplate_Delete,
 *    usp_Acct_ReportTemplate_Render
 *
 *  Patron : DROP + CREATE (SQL Server 2012 compat)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Acct_ReportTemplate_List
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_ReportTemplate_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_ReportTemplate_List;
GO
CREATE PROCEDURE dbo.usp_Acct_ReportTemplate_List
    @CompanyId   INT,
    @CountryCode CHAR(2)       = NULL,
    @ReportCode  NVARCHAR(50)  = NULL,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.ReportTemplate
    WHERE  CompanyId = @CompanyId
      AND  IsActive  = 1
      AND  (@CountryCode IS NULL OR CountryCode = @CountryCode)
      AND  (@ReportCode  IS NULL OR ReportCode  = @ReportCode);

    SELECT ReportTemplateId,
           CountryCode,
           ReportCode,
           ReportName,
           LegalFramework,
           LegalReference,
           IsDefault,
           Version,
           CreatedAt,
           UpdatedAt
    FROM   acct.ReportTemplate
    WHERE  CompanyId = @CompanyId
      AND  IsActive  = 1
      AND  (@CountryCode IS NULL OR CountryCode = @CountryCode)
      AND  (@ReportCode  IS NULL OR ReportCode  = @ReportCode)
    ORDER BY CountryCode, ReportCode;
END;
GO

-- =============================================================================
--  SP 2: usp_Acct_ReportTemplate_Get
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_ReportTemplate_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_ReportTemplate_Get;
GO
CREATE PROCEDURE dbo.usp_Acct_ReportTemplate_Get
    @CompanyId       INT,
    @ReportTemplateId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: cabecera
    SELECT ReportTemplateId, CountryCode, ReportCode, ReportName,
           LegalFramework, LegalReference, TemplateContent,
           HeaderJson, FooterJson, IsDefault, Version,
           CreatedAt, UpdatedAt
    FROM   acct.ReportTemplate
    WHERE  ReportTemplateId = @ReportTemplateId AND CompanyId = @CompanyId;

    -- Recordset 2: variables
    SELECT VariableId, VariableName, VariableType, DataSource,
           DefaultValue, Description, SortOrder
    FROM   acct.ReportTemplateVariable
    WHERE  ReportTemplateId = @ReportTemplateId
    ORDER BY SortOrder;
END;
GO

-- =============================================================================
--  SP 3: usp_Acct_ReportTemplate_Upsert
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_ReportTemplate_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_ReportTemplate_Upsert;
GO
CREATE PROCEDURE dbo.usp_Acct_ReportTemplate_Upsert
    @CompanyId       INT,
    @ReportTemplateId INT          = NULL,
    @CountryCode     CHAR(2)       = NULL,
    @ReportCode      NVARCHAR(50)  = NULL,
    @ReportName      NVARCHAR(200) = NULL,
    @LegalFramework  NVARCHAR(50)  = NULL,
    @LegalReference  NVARCHAR(300) = NULL,
    @TemplateContent NVARCHAR(MAX) = NULL,
    @HeaderJson      NVARCHAR(MAX) = NULL,
    @FooterJson      NVARCHAR(MAX) = NULL,
    @UserId          INT           = NULL,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @ReportTemplateId IS NOT NULL AND EXISTS (SELECT 1 FROM acct.ReportTemplate WHERE ReportTemplateId = @ReportTemplateId AND CompanyId = @CompanyId)
    BEGIN
        UPDATE acct.ReportTemplate
        SET    ReportName      = ISNULL(@ReportName, ReportName),
               LegalFramework  = ISNULL(@LegalFramework, LegalFramework),
               LegalReference  = ISNULL(@LegalReference, LegalReference),
               TemplateContent = ISNULL(@TemplateContent, TemplateContent),
               HeaderJson      = ISNULL(@HeaderJson, HeaderJson),
               FooterJson      = ISNULL(@FooterJson, FooterJson),
               Version         = Version + 1,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  ReportTemplateId = @ReportTemplateId;

        SET @Resultado = 1;
        SET @Mensaje   = N'Plantilla actualizada correctamente.';
    END
    ELSE
    BEGIN
        IF @CountryCode IS NULL OR @ReportCode IS NULL OR @ReportName IS NULL OR @TemplateContent IS NULL
        BEGIN
            SET @Mensaje = N'CountryCode, ReportCode, ReportName y TemplateContent son obligatorios para crear.';
            RETURN;
        END;

        INSERT INTO acct.ReportTemplate (CompanyId, CountryCode, ReportCode, ReportName, LegalFramework, LegalReference, TemplateContent, HeaderJson, FooterJson, CreatedByUserId)
        VALUES (@CompanyId, @CountryCode, @ReportCode, @ReportName, ISNULL(@LegalFramework, 'VEN-NIF'), @LegalReference, @TemplateContent, @HeaderJson, @FooterJson, @UserId);

        SET @ReportTemplateId = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje   = CONCAT(N'Plantilla creada. ID: ', @ReportTemplateId);
    END;
END;
GO

-- =============================================================================
--  SP 4: usp_Acct_ReportTemplate_Delete
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_ReportTemplate_Delete', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_ReportTemplate_Delete;
GO
CREATE PROCEDURE dbo.usp_Acct_ReportTemplate_Delete
    @CompanyId        INT,
    @ReportTemplateId INT,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (SELECT 1 FROM acct.ReportTemplate WHERE ReportTemplateId = @ReportTemplateId AND CompanyId = @CompanyId)
    BEGIN
        SET @Mensaje = N'Plantilla no encontrada.';
        RETURN;
    END;

    UPDATE acct.ReportTemplate
    SET    IsActive = 0, UpdatedAt = SYSUTCDATETIME()
    WHERE  ReportTemplateId = @ReportTemplateId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Plantilla eliminada correctamente.';
END;
GO

-- =============================================================================
--  SP 5: usp_Acct_ReportTemplate_Render
--  Descripcion : Retorna los datos para renderizar una plantilla.
--    Retorna cabecera de plantilla + datos de empresa para variables comunes.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_ReportTemplate_Render', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_ReportTemplate_Render;
GO
CREATE PROCEDURE dbo.usp_Acct_ReportTemplate_Render
    @CompanyId        INT,
    @ReportTemplateId INT,
    @FechaDesde       DATE = NULL,
    @FechaHasta       DATE = NULL,
    @FechaCorte       DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: plantilla
    SELECT ReportTemplateId, CountryCode, ReportCode, ReportName,
           LegalFramework, LegalReference, TemplateContent,
           HeaderJson, FooterJson
    FROM   acct.ReportTemplate
    WHERE  ReportTemplateId = @ReportTemplateId AND CompanyId = @CompanyId;

    -- Recordset 2: datos de la empresa (para variables comunes)
    SELECT c.CompanyId,
           c.CompanyCode,
           c.LegalName    AS companyName,
           c.FiscalId     AS companyRIF,
           c.FiscalId     AS companyNIF,
           b.AddressLine  AS companyAddress,
           c.FiscalCountryCode AS companyCountry,
           ISNULL(@FechaCorte, @FechaHasta) AS reportDate,
           @FechaDesde    AS fechaDesde,
           @FechaHasta    AS fechaHasta,
           c.BaseCurrency AS currency
    FROM   cfg.Company c
    LEFT JOIN cfg.Branch b ON b.CompanyId = c.CompanyId AND b.IsActive = 1
    WHERE  c.CompanyId = @CompanyId;

    -- Recordset 3: variables definidas para esta plantilla
    SELECT VariableId, VariableName, VariableType, DataSource, DefaultValue, Description
    FROM   acct.ReportTemplateVariable
    WHERE  ReportTemplateId = @ReportTemplateId
    ORDER BY SortOrder;
END;
GO

PRINT '=== usp_acct_templates.sql completado: 5 SPs creados ===';
GO
