/*
 * ============================================================================
 *  Archivo : usp_util.sql
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados utilitarios que eliminan SQL inline de los
 *    servicios TypeScript.  Cada SP sigue el patron CREATE OR ALTER (idempotente).
 *
 *    Secciones:
 *      1. Config (cfg)            - usp_Cfg_ExchangeRate_Upsert
 *      2. Fiscal                  - usp_Cfg_Fiscal_HasTable, usp_Cfg_Fiscal_HasRecordsTable,
 *                                   usp_Cfg_Fiscal_GetLatestRecord, usp_Cfg_Fiscal_InferCountry,
 *                                   usp_Cfg_Fiscal_GetConfig, usp_Cfg_Fiscal_UpsertConfig,
 *                                   usp_Cfg_Fiscal_InsertRecord
 *      3. Sistema                 - usp_Sys_Notificacion_List, usp_Sys_Notificacion_MarkRead,
 *                                   usp_Sys_Tarea_List, usp_Sys_Tarea_Toggle,
 *                                   usp_Sys_Mensaje_List, usp_Sys_Mensaje_MarkRead
 *      4. Maestros                - usp_Master_Generic_List, usp_Master_Generic_Count
 *      5. Retenciones             - usp_Tax_Retention_List, usp_Tax_Retention_Count,
 *                                   usp_Tax_Retention_GetByCode
 *      6. Empleados               - usp_HR_Employee_GetDefaultCompany,
 *                                   usp_HR_Employee_List, usp_HR_Employee_Count,
 *                                   usp_HR_Employee_GetByCode, usp_HR_Employee_ExistsByCode,
 *                                   usp_HR_Employee_Insert, usp_HR_Employee_Update,
 *                                   usp_HR_Employee_Delete
 *      7. Supervisor Biometric    - usp_Sec_Supervisor_Biometric_HasActive,
 *                                   usp_Sec_Supervisor_Biometric_Touch,
 *                                   usp_Sec_Supervisor_Biometric_Enroll,
 *                                   usp_Sec_Supervisor_Biometric_List,
 *                                   usp_Sec_Supervisor_Biometric_Deactivate
 *      8. Supervisor Override     - usp_Sec_Supervisor_GetRecord,
 *                                   usp_Sec_Supervisor_Override_Create,
 *                                   usp_Sec_Supervisor_Override_Consume
 *      9. Payment Engine          - usp_Pay_Transaction_ResolveConfig,
 *                                   usp_Pay_Transaction_Insert,
 *                                   usp_Pay_Transaction_UpdateStatus,
 *                                   usp_Pay_Transaction_Search,
 *                                   usp_Pay_Transaction_SearchCount
 *     10. CRUD Generico           - usp_Sys_GenericList, usp_Sys_GenericCount,
 *                                   usp_Sys_GenericGetByKey, usp_Sys_GenericInsert,
 *                                   usp_Sys_GenericUpdate, usp_Sys_GenericDelete
 *     11. Inventario Cache        - usp_Inventario_CacheLoad, usp_Inventario_GetByCode
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
-- 1. CONFIG: usp_Cfg_ExchangeRate_Upsert
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_ExchangeRate_Upsert
    @RateDate    DATE,
    @TasaUSD     DECIMAL(18,6),
    @TasaEUR     DECIMAL(18,6),
    @SourceName  NVARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;

    -- USD
    IF EXISTS (
        SELECT 1
        FROM cfg.ExchangeRateDaily
        WHERE CurrencyCode = 'USD' AND RateDate = @RateDate
    )
    BEGIN
        UPDATE cfg.ExchangeRateDaily
        SET RateToBase  = @TasaUSD,
            SourceName  = @SourceName
        WHERE CurrencyCode = 'USD' AND RateDate = @RateDate;
    END
    ELSE
    BEGIN
        INSERT INTO cfg.ExchangeRateDaily (CurrencyCode, RateToBase, RateDate, SourceName)
        VALUES ('USD', @TasaUSD, @RateDate, @SourceName);
    END;

    -- EUR
    IF EXISTS (
        SELECT 1
        FROM cfg.ExchangeRateDaily
        WHERE CurrencyCode = 'EUR' AND RateDate = @RateDate
    )
    BEGIN
        UPDATE cfg.ExchangeRateDaily
        SET RateToBase  = @TasaEUR,
            SourceName  = @SourceName
        WHERE CurrencyCode = 'EUR' AND RateDate = @RateDate;
    END
    ELSE
    BEGIN
        INSERT INTO cfg.ExchangeRateDaily (CurrencyCode, RateToBase, RateDate, SourceName)
        VALUES ('EUR', @TasaEUR, @RateDate, @SourceName);
    END;
END;
GO

-- ============================================================================
-- 2. FISCAL: usp_Cfg_Fiscal_HasTable
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_HasTable
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CASE WHEN EXISTS(
        SELECT 1
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE t.name = 'CountryConfig' AND s.name = 'fiscal'
    ) THEN 1 ELSE 0 END AS hasTable;
END;
GO

-- ============================================================================
-- 2b. FISCAL: usp_Cfg_Fiscal_HasRecordsTable
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_HasRecordsTable
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CASE WHEN EXISTS(
        SELECT 1
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE t.name = 'Record' AND s.name = 'fiscal'
    ) THEN 1 ELSE 0 END AS hasTable;
END;
GO

-- ============================================================================
-- 2c. FISCAL: usp_Cfg_Fiscal_GetLatestRecord
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_GetLatestRecord
    @EmpresaId   INT,
    @SucursalId  INT,
    @CountryCode NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'fiscal.Record', N'U') IS NULL
    BEGIN
        -- Tabla no existe, retornar vacio
        SELECT NULL AS Id WHERE 1=0;
        RETURN;
    END;

    SELECT TOP 1
        FiscalRecordId   AS Id,
        InvoiceId,
        CountryCode,
        InvoiceType,
        XmlContent,
        RecordHash,
        PreviousRecordHash,
        DigitalSignature,
        QRCodeData,
        SentToAuthority,
        AuthorityResponse,
        CreatedAt
    FROM fiscal.Record
    WHERE CompanyId   = @EmpresaId
      AND BranchId    = @SucursalId
      AND CountryCode = @CountryCode
    ORDER BY FiscalRecordId DESC;
END;
GO

-- ============================================================================
-- 2d. FISCAL: usp_Cfg_Fiscal_InferCountry
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_InferCountry
    @EmpresaId  INT,
    @SucursalId INT
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'fiscal.CountryConfig', N'U') IS NULL
    BEGIN
        SELECT 'VE' AS CountryCode;
        RETURN;
    END;

    SELECT TOP 1 CountryCode
    FROM fiscal.CountryConfig
    WHERE CompanyId = @EmpresaId
      AND BranchId  = @SucursalId
      AND IsActive  = 1
    ORDER BY UpdatedAt DESC, CountryConfigId DESC;

    -- Si no hay filas, TS recibira array vacio y aplicara fallback 'VE'
END;
GO

-- ============================================================================
-- 2e. FISCAL: usp_Cfg_Fiscal_GetConfig
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_GetConfig
    @EmpresaId   INT,
    @SucursalId  INT,
    @CountryCode NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'fiscal.CountryConfig', N'U') IS NULL
    BEGIN
        SELECT NULL AS EmpresaId WHERE 1=0;
        RETURN;
    END;

    SELECT TOP 1
        CompanyId           AS EmpresaId,
        BranchId            AS SucursalId,
        CountryCode,
        Currency,
        TaxRegime,
        DefaultTaxCode,
        DefaultTaxRate,
        FiscalPrinterEnabled,
        PrinterBrand,
        PrinterPort,
        VerifactuEnabled,
        VerifactuMode,
        CertificatePath,
        CertificatePassword,
        AEATEndpoint,
        SenderNIF,
        SenderRIF,
        SoftwareId,
        SoftwareName,
        SoftwareVersion,
        PosEnabled,
        RestaurantEnabled
    FROM fiscal.CountryConfig
    WHERE CompanyId   = @EmpresaId
      AND BranchId    = @SucursalId
      AND CountryCode = @CountryCode;
END;
GO

-- ============================================================================
-- 2f. FISCAL: usp_Cfg_Fiscal_UpsertConfig
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_UpsertConfig
    @EmpresaId             INT,
    @SucursalId            INT,
    @CountryCode           NVARCHAR(10),
    @Currency              NVARCHAR(10),
    @TaxRegime             NVARCHAR(60),
    @DefaultTaxCode        NVARCHAR(30),
    @DefaultTaxRate        DECIMAL(18,6),
    @FiscalPrinterEnabled  BIT,
    @PrinterBrand          NVARCHAR(60)   = NULL,
    @PrinterPort           NVARCHAR(60)   = NULL,
    @VerifactuEnabled      BIT,
    @VerifactuMode         NVARCHAR(20),
    @CertificatePath       NVARCHAR(500)  = NULL,
    @CertificatePassword   NVARCHAR(500)  = NULL,
    @AEATEndpoint          NVARCHAR(500)  = NULL,
    @SenderNIF             NVARCHAR(30)   = NULL,
    @SenderRIF             NVARCHAR(30)   = NULL,
    @SoftwareId            NVARCHAR(60)   = NULL,
    @SoftwareName          NVARCHAR(120)  = NULL,
    @SoftwareVersion       NVARCHAR(30)   = NULL,
    @PosEnabled            BIT,
    @RestaurantEnabled     BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(N'fiscal.CountryConfig', N'U') IS NULL
    BEGIN
        SELECT 0 AS Affected;
        RETURN;
    END;

    MERGE fiscal.CountryConfig AS target
    USING (
        SELECT @EmpresaId AS CompanyId,
               @SucursalId AS BranchId,
               @CountryCode AS CountryCode
    ) AS src
    ON target.CompanyId   = src.CompanyId
       AND target.BranchId  = src.BranchId
       AND target.CountryCode = src.CountryCode
    WHEN MATCHED THEN
        UPDATE SET
            Currency            = @Currency,
            TaxRegime           = @TaxRegime,
            DefaultTaxCode      = @DefaultTaxCode,
            DefaultTaxRate      = @DefaultTaxRate,
            FiscalPrinterEnabled= @FiscalPrinterEnabled,
            PrinterBrand        = @PrinterBrand,
            PrinterPort         = @PrinterPort,
            VerifactuEnabled    = @VerifactuEnabled,
            VerifactuMode       = @VerifactuMode,
            CertificatePath     = @CertificatePath,
            CertificatePassword = @CertificatePassword,
            AEATEndpoint        = @AEATEndpoint,
            SenderNIF           = @SenderNIF,
            SenderRIF           = @SenderRIF,
            SoftwareId          = @SoftwareId,
            SoftwareName        = @SoftwareName,
            SoftwareVersion     = @SoftwareVersion,
            PosEnabled          = @PosEnabled,
            RestaurantEnabled   = @RestaurantEnabled,
            UpdatedAt           = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (
            CompanyId, BranchId, CountryCode, Currency, TaxRegime,
            DefaultTaxCode, DefaultTaxRate, FiscalPrinterEnabled,
            PrinterBrand, PrinterPort, VerifactuEnabled, VerifactuMode,
            CertificatePath, CertificatePassword, AEATEndpoint,
            SenderNIF, SenderRIF, SoftwareId, SoftwareName, SoftwareVersion,
            PosEnabled, RestaurantEnabled, CreatedAt, UpdatedAt
        )
        VALUES (
            @EmpresaId, @SucursalId, @CountryCode, @Currency, @TaxRegime,
            @DefaultTaxCode, @DefaultTaxRate, @FiscalPrinterEnabled,
            @PrinterBrand, @PrinterPort, @VerifactuEnabled, @VerifactuMode,
            @CertificatePath, @CertificatePassword, @AEATEndpoint,
            @SenderNIF, @SenderRIF, @SoftwareId, @SoftwareName, @SoftwareVersion,
            @PosEnabled, @RestaurantEnabled, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

    SELECT 1 AS Affected;
END;
GO

-- ============================================================================
-- 2g. FISCAL: usp_Cfg_Fiscal_InsertRecord
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Fiscal_InsertRecord
    @EmpresaId           INT,
    @SucursalId          INT,
    @CountryCode         NVARCHAR(10),
    @InvoiceId           INT,
    @InvoiceType         NVARCHAR(30),
    @InvoiceNumber       NVARCHAR(60),
    @InvoiceDate         DATETIME,
    @RecipientId         NVARCHAR(60)   = NULL,
    @TotalAmount         DECIMAL(18,2),
    @RecordHash          NVARCHAR(200),
    @PreviousRecordHash  NVARCHAR(200)  = NULL,
    @XmlContent          NVARCHAR(MAX)  = NULL,
    @DigitalSignature    NVARCHAR(MAX)  = NULL,
    @QRCodeData          NVARCHAR(MAX)  = NULL,
    @SentToAuthority     BIT,
    @SentAt              DATETIME       = NULL,
    @AuthorityResponse   NVARCHAR(MAX)  = NULL,
    @AuthorityStatus     NVARCHAR(30),
    @FiscalPrinterSerial NVARCHAR(60)   = NULL,
    @FiscalControlNumber NVARCHAR(60)   = NULL,
    @ZReportNumber       INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fiscal.Record (
        CompanyId, BranchId, CountryCode,
        InvoiceId, InvoiceType, InvoiceNumber, InvoiceDate,
        RecipientId, TotalAmount, RecordHash, PreviousRecordHash,
        XmlContent, DigitalSignature, QRCodeData,
        SentToAuthority, SentAt, AuthorityResponse, AuthorityStatus,
        FiscalPrinterSerial, FiscalControlNumber, ZReportNumber,
        CreatedAt
    ) VALUES (
        @EmpresaId, @SucursalId, @CountryCode,
        @InvoiceId, @InvoiceType, @InvoiceNumber, @InvoiceDate,
        @RecipientId, @TotalAmount, @RecordHash, @PreviousRecordHash,
        @XmlContent, @DigitalSignature, @QRCodeData,
        @SentToAuthority, @SentAt, @AuthorityResponse, @AuthorityStatus,
        @FiscalPrinterSerial, @FiscalControlNumber, @ZReportNumber,
        SYSUTCDATETIME()
    );
END;
GO

-- ============================================================================
-- 3. SISTEMA: usp_Sys_Notificacion_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Notificacion_List
    @UsuarioId NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 50
        Id, Tipo, Titulo, Mensaje, Leido, FechaCreacion, RutaNavegacion
    FROM Sys_Notificaciones
    WHERE UsuarioId IS NULL OR UsuarioId = @UsuarioId
    ORDER BY FechaCreacion DESC;
END;
GO

-- ============================================================================
-- 3b. SISTEMA: usp_Sys_Notificacion_MarkRead
--     Recibe lista de IDs como CSV string para evitar dynamic IN.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Notificacion_MarkRead
    @IdsCsv NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE n
    SET n.Leido = 1
    FROM Sys_Notificaciones n
    INNER JOIN STRING_SPLIT(@IdsCsv, ',') s
        ON n.Id = TRY_CAST(s.value AS INT)
    WHERE TRY_CAST(s.value AS INT) IS NOT NULL;

    SELECT @@ROWCOUNT AS AffectedCount;
END;
GO

-- ============================================================================
-- 3c. SISTEMA: usp_Sys_Tarea_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Tarea_List
    @AsignadoA NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 50
        Id, Titulo, Descripcion, Progreso, Color, AsignadoA,
        FechaVencimiento, Completado, FechaCreacion
    FROM Sys_Tareas
    WHERE (AsignadoA IS NULL OR AsignadoA = @AsignadoA)
      AND Completado = 0
    ORDER BY FechaCreacion DESC;
END;
GO

-- ============================================================================
-- 3d. SISTEMA: usp_Sys_Tarea_Toggle
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Tarea_Toggle
    @Id         INT,
    @Completado BIT,
    @Progress   INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Sys_Tareas
    SET Completado = @Completado,
        Progreso   = @Progress
    WHERE Id = @Id;
END;
GO

-- ============================================================================
-- 3e. SISTEMA: usp_Sys_Mensaje_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Mensaje_List
    @DestinatarioId NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 50
        Id, RemitenteId, RemitenteNombre, Asunto, Cuerpo, Leido, FechaEnvio
    FROM Sys_Mensajes
    WHERE DestinatarioId = @DestinatarioId
    ORDER BY FechaEnvio DESC;
END;
GO

-- ============================================================================
-- 3f. SISTEMA: usp_Sys_Mensaje_MarkRead
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_Mensaje_MarkRead
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Sys_Mensajes
    SET Leido = 1
    WHERE Id = @Id;
END;
GO

-- ============================================================================
-- 4. MAESTROS: usp_Master_Generic_List
--    Lista con paginacion, filtro de busqueda en columnas de texto.
--    Usa SQL dinamico seguro con QUOTENAME para tabla y columnas.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Master_Generic_List
    @SchemaName  NVARCHAR(128),
    @TableName   NVARCHAR(128),
    @Search      NVARCHAR(200)  = NULL,
    @SortColumn  NVARCHAR(128),
    @Offset      INT            = 0,
    @Limit       INT            = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @CountSql NVARCHAR(MAX);
    DECLARE @WhereClause NVARCHAR(MAX) = '';
    DECLARE @SafeSort NVARCHAR(260) = QUOTENAME(@SortColumn);

    -- Build dynamic LIKE search on string columns
    IF @Search IS NOT NULL AND LEN(LTRIM(RTRIM(@Search))) > 0
    BEGIN
        DECLARE @SearchColumns NVARCHAR(MAX) = '';

        SELECT @SearchColumns = @SearchColumns +
            CASE WHEN LEN(@SearchColumns) > 0 THEN ' OR ' ELSE '' END +
            QUOTENAME(c.COLUMN_NAME) + ' LIKE @Search'
        FROM INFORMATION_SCHEMA.COLUMNS c
        WHERE c.TABLE_SCHEMA = @SchemaName
          AND c.TABLE_NAME   = @TableName
          AND c.DATA_TYPE IN ('varchar','nvarchar','char','nchar','text','ntext');

        IF LEN(@SearchColumns) > 0
            SET @WhereClause = ' WHERE (' + @SearchColumns + ')';
    END;

    -- Count query
    SET @CountSql = 'SELECT COUNT(1) AS total FROM ' + @FullTable + @WhereClause;

    -- Data query
    SET @Sql = 'SELECT * FROM ' + @FullTable + @WhereClause
        + ' ORDER BY ' + @SafeSort + ' ASC'
        + ' OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

    -- Execute count first (resultset 1)
    EXEC sp_executesql @CountSql,
        N'@Search NVARCHAR(200)',
        @Search = CASE WHEN @Search IS NOT NULL THEN '%' + @Search + '%' ELSE NULL END;

    -- Execute data (resultset 2)
    EXEC sp_executesql @Sql,
        N'@Search NVARCHAR(200), @Offset INT, @Limit INT',
        @Search = CASE WHEN @Search IS NOT NULL THEN '%' + @Search + '%' ELSE NULL END,
        @Offset = @Offset,
        @Limit  = @Limit;
END;
GO

-- ============================================================================
-- 5. RETENCIONES: usp_Tax_Retention_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Tax_Retention_List
    @Search NVARCHAR(200) = NULL,
    @Tipo   NVARCHAR(60)  = NULL,
    @Offset INT           = 0,
    @Limit  INT           = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        RetentionId,
        RetentionCode  AS Codigo,
        Description    AS Descripcion,
        RetentionType  AS Tipo,
        RetentionRate  AS Porcentaje,
        CountryCode    AS Pais,
        IsActive
    FROM master.TaxRetention
    WHERE IsDeleted = 0
      AND (@Search IS NULL OR (RetentionCode LIKE '%' + @Search + '%' OR Description LIKE '%' + @Search + '%'))
      AND (@Tipo IS NULL OR RetentionType = @Tipo)
    ORDER BY RetentionCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================================
-- 5b. RETENCIONES: usp_Tax_Retention_Count
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Tax_Retention_Count
    @Search NVARCHAR(200) = NULL,
    @Tipo   NVARCHAR(60)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(1) AS total
    FROM master.TaxRetention
    WHERE IsDeleted = 0
      AND (@Search IS NULL OR (RetentionCode LIKE '%' + @Search + '%' OR Description LIKE '%' + @Search + '%'))
      AND (@Tipo IS NULL OR RetentionType = @Tipo);
END;
GO

-- ============================================================================
-- 5c. RETENCIONES: usp_Tax_Retention_GetByCode
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Tax_Retention_GetByCode
    @Codigo NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        RetentionId,
        RetentionCode  AS Codigo,
        Description    AS Descripcion,
        RetentionType  AS Tipo,
        RetentionRate  AS Porcentaje,
        CountryCode    AS Pais,
        IsActive
    FROM master.TaxRetention
    WHERE RetentionCode = @Codigo
      AND IsDeleted = 0;
END;
GO

-- ============================================================================
-- 6. EMPLEADOS: usp_HR_Employee_GetDefaultCompany
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_GetDefaultCompany
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 CompanyId
    FROM cfg.Company
    WHERE IsDeleted = 0
    ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;
END;
GO

-- ============================================================================
-- 6b. EMPLEADOS: usp_HR_Employee_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_List
    @CompanyId INT,
    @Search    NVARCHAR(200) = NULL,
    @Status    NVARCHAR(20)  = NULL,
    @Offset    INT           = 0,
    @Limit     INT           = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive
    FROM [master].Employee
    WHERE CompanyId = @CompanyId
      AND ISNULL(IsDeleted, 0) = 0
      AND (@Search IS NULL OR (EmployeeCode LIKE '%' + @Search + '%' OR EmployeeName LIKE '%' + @Search + '%' OR FiscalId LIKE '%' + @Search + '%'))
      AND (@Status IS NULL
           OR (@Status = 'ACTIVO' AND IsActive = 1)
           OR (@Status = 'INACTIVO' AND IsActive = 0))
    ORDER BY EmployeeCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================================
-- 6c. EMPLEADOS: usp_HR_Employee_Count
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_Count
    @CompanyId INT,
    @Search    NVARCHAR(200) = NULL,
    @Status    NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(1) AS total
    FROM [master].Employee
    WHERE CompanyId = @CompanyId
      AND ISNULL(IsDeleted, 0) = 0
      AND (@Search IS NULL OR (EmployeeCode LIKE '%' + @Search + '%' OR EmployeeName LIKE '%' + @Search + '%' OR FiscalId LIKE '%' + @Search + '%'))
      AND (@Status IS NULL
           OR (@Status = 'ACTIVO' AND IsActive = 1)
           OR (@Status = 'INACTIVO' AND IsActive = 0));
END;
GO

-- ============================================================================
-- 6d. EMPLEADOS: usp_HR_Employee_GetByCode
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_GetByCode
    @CompanyId INT,
    @Cedula    NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive
    FROM [master].Employee
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @Cedula
      AND ISNULL(IsDeleted, 0) = 0;
END;
GO

-- ============================================================================
-- 6e. EMPLEADOS: usp_HR_Employee_ExistsByCode
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_ExistsByCode
    @CompanyId INT,
    @Code      NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 EmployeeId
    FROM [master].Employee
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @Code
      AND ISNULL(IsDeleted, 0) = 0;
END;
GO

-- ============================================================================
-- 6f. EMPLEADOS: usp_HR_Employee_Insert
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_Insert
    @CompanyId       INT,
    @Code            NVARCHAR(60),
    @Name            NVARCHAR(200),
    @FiscalId        NVARCHAR(60)  = NULL,
    @HireDate        DATE          = NULL,
    @TerminationDate DATE          = NULL,
    @IsActive        BIT           = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [master].Employee
        (CompanyId, EmployeeCode, EmployeeName, FiscalId, HireDate, TerminationDate, IsActive, CreatedAt, UpdatedAt, IsDeleted)
    VALUES
        (@CompanyId, @Code, @Name, @FiscalId, ISNULL(@HireDate, CAST(GETDATE() AS DATE)), @TerminationDate, @IsActive, SYSUTCDATETIME(), SYSUTCDATETIME(), 0);
END;
GO

-- ============================================================================
-- 6g. EMPLEADOS: usp_HR_Employee_Update
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_Update
    @CompanyId       INT,
    @Cedula          NVARCHAR(60),
    @Name            NVARCHAR(200) = NULL,
    @FiscalId        NVARCHAR(60)  = NULL,
    @HireDate        DATE          = NULL,
    @TerminationDate DATE          = NULL,
    @IsActive        BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [master].Employee
    SET EmployeeName   = COALESCE(@Name, EmployeeName),
        FiscalId       = COALESCE(@FiscalId, FiscalId),
        HireDate       = COALESCE(@HireDate, HireDate),
        TerminationDate= COALESCE(@TerminationDate, TerminationDate),
        IsActive       = COALESCE(@IsActive, IsActive),
        UpdatedAt      = SYSUTCDATETIME()
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @Cedula
      AND ISNULL(IsDeleted, 0) = 0;
END;
GO

-- ============================================================================
-- 6h. EMPLEADOS: usp_HR_Employee_Delete
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_HR_Employee_Delete
    @CompanyId INT,
    @Cedula    NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [master].Employee
    SET IsDeleted = 1,
        IsActive  = 0,
        DeletedAt = SYSUTCDATETIME(),
        UpdatedAt = SYSUTCDATETIME()
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @Cedula
      AND ISNULL(IsDeleted, 0) = 0;
END;
GO

-- ============================================================================
-- 7. SUPERVISOR BIOMETRIC: usp_Sec_Supervisor_Biometric_HasActive
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Biometric_HasActive
    @SupervisorUser NVARCHAR(60),
    @CredentialHash NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 BiometricCredentialId AS biometricCredentialId
    FROM sec.SupervisorBiometricCredential
    WHERE SupervisorUserCode = @SupervisorUser
      AND CredentialHash     = @CredentialHash
      AND IsActive = 1;
END;
GO

-- ============================================================================
-- 7b. SUPERVISOR BIOMETRIC: usp_Sec_Supervisor_Biometric_Touch
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Biometric_Touch
    @SupervisorUser NVARCHAR(60),
    @CredentialHash NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sec.SupervisorBiometricCredential
    SET LastValidatedAtUtc = SYSUTCDATETIME(),
        UpdatedAtUtc       = SYSUTCDATETIME()
    WHERE SupervisorUserCode = @SupervisorUser
      AND CredentialHash     = @CredentialHash
      AND IsActive = 1;
END;
GO

-- ============================================================================
-- 7c. SUPERVISOR BIOMETRIC: usp_Sec_Supervisor_Biometric_Enroll
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Biometric_Enroll
    @SupervisorUser  NVARCHAR(60),
    @CredentialHash  NVARCHAR(128),
    @CredentialId    NVARCHAR(500),
    @CredentialLabel NVARCHAR(120) = NULL,
    @DeviceInfo      NVARCHAR(300) = NULL,
    @ActorUser       NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    MERGE sec.SupervisorBiometricCredential AS target
    USING (
        SELECT @SupervisorUser AS SupervisorUserCode,
               @CredentialHash AS CredentialHash
    ) AS source
    ON  target.SupervisorUserCode = source.SupervisorUserCode
    AND target.CredentialHash     = source.CredentialHash
    WHEN MATCHED THEN
        UPDATE SET
            CredentialId       = @CredentialId,
            CredentialLabel    = @CredentialLabel,
            DeviceInfo         = @DeviceInfo,
            IsActive           = 1,
            UpdatedAtUtc       = SYSUTCDATETIME(),
            UpdatedByUserCode  = @ActorUser
    WHEN NOT MATCHED THEN
        INSERT (
            SupervisorUserCode, CredentialHash, CredentialId,
            CredentialLabel, DeviceInfo, IsActive,
            LastValidatedAtUtc, CreatedAtUtc, UpdatedAtUtc,
            CreatedByUserCode, UpdatedByUserCode
        )
        VALUES (
            @SupervisorUser, @CredentialHash, @CredentialId,
            @CredentialLabel, @DeviceInfo, 1,
            NULL, SYSUTCDATETIME(), SYSUTCDATETIME(),
            @ActorUser, @ActorUser
        )
    OUTPUT inserted.BiometricCredentialId AS biometricCredentialId;
END;
GO

-- ============================================================================
-- 7d. SUPERVISOR BIOMETRIC: usp_Sec_Supervisor_Biometric_List
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Biometric_List
    @SupervisorUser NVARCHAR(60) = ''
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        BiometricCredentialId AS biometricCredentialId,
        SupervisorUserCode    AS supervisorUserCode,
        CredentialId          AS credentialId,
        CredentialLabel       AS credentialLabel,
        DeviceInfo            AS deviceInfo,
        IsActive              AS isActive,
        CONVERT(varchar(33), LastValidatedAtUtc, 127) AS lastValidatedAtUtc
    FROM sec.SupervisorBiometricCredential
    WHERE IsActive = 1
      AND (@SupervisorUser = '' OR SupervisorUserCode = @SupervisorUser)
    ORDER BY BiometricCredentialId DESC;
END;
GO

-- ============================================================================
-- 7e. SUPERVISOR BIOMETRIC: usp_Sec_Supervisor_Biometric_Deactivate
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Biometric_Deactivate
    @SupervisorUser NVARCHAR(60),
    @CredentialHash NVARCHAR(128),
    @ActorUser      NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sec.SupervisorBiometricCredential
    SET IsActive          = 0,
        UpdatedAtUtc      = SYSUTCDATETIME(),
        UpdatedByUserCode = @ActorUser
    OUTPUT inserted.BiometricCredentialId AS biometricCredentialId
    WHERE SupervisorUserCode = @SupervisorUser
      AND CredentialHash     = @CredentialHash
      AND IsActive = 1;
END;
GO

-- ============================================================================
-- 8. SUPERVISOR OVERRIDE: usp_Sec_Supervisor_GetRecord
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_GetRecord
    @SupervisorUser NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Cod_Usuario AS codUsuario,
        Nombre      AS nombre,
        Tipo        AS tipo,
        IsAdmin     AS isAdmin,
        Deletes     AS canDelete,
        Password    AS passwordHash
    FROM dbo.Usuarios
    WHERE UPPER(Cod_Usuario) = @SupervisorUser;
END;
GO

-- ============================================================================
-- 8b. SUPERVISOR OVERRIDE: usp_Sec_Supervisor_Override_Create
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Override_Create
    @ModuleCode         NVARCHAR(60),
    @ActionCode         NVARCHAR(60),
    @Status             NVARCHAR(20),
    @CompanyId          INT           = NULL,
    @BranchId           INT           = NULL,
    @RequestedByUserCode NVARCHAR(60) = NULL,
    @SupervisorUserCode NVARCHAR(60),
    @Reason             NVARCHAR(300),
    @PayloadJson        NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO sec.SupervisorOverride (
        ModuleCode, ActionCode, Status,
        CompanyId, BranchId,
        RequestedByUserCode, SupervisorUserCode,
        Reason, PayloadJson, ApprovedAtUtc
    )
    OUTPUT INSERTED.OverrideId AS overrideId
    VALUES (
        @ModuleCode, @ActionCode, @Status,
        @CompanyId, @BranchId,
        @RequestedByUserCode, @SupervisorUserCode,
        @Reason, @PayloadJson, SYSUTCDATETIME()
    );
END;
GO

-- ============================================================================
-- 8c. SUPERVISOR OVERRIDE: usp_Sec_Supervisor_Override_Consume
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sec_Supervisor_Override_Consume
    @OverrideId        INT,
    @ModuleCode        NVARCHAR(60),
    @ActionCode        NVARCHAR(60),
    @ConsumedByUserCode NVARCHAR(60) = NULL,
    @SourceDocumentId  INT           = NULL,
    @SourceLineId      INT           = NULL,
    @ReversalLineId    INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sec.SupervisorOverride
    SET Status             = N'CONSUMED',
        ConsumedAtUtc      = SYSUTCDATETIME(),
        ConsumedByUserCode = @ConsumedByUserCode,
        SourceDocumentId   = @SourceDocumentId,
        SourceLineId       = @SourceLineId,
        ReversalLineId     = @ReversalLineId
    OUTPUT INSERTED.OverrideId AS overrideId
    WHERE OverrideId = @OverrideId
      AND Status = N'APPROVED'
      AND UPPER(ModuleCode) = @ModuleCode
      AND UPPER(ActionCode) = @ActionCode;
END;
GO

-- ============================================================================
-- 9. PAYMENT ENGINE: usp_Pay_Transaction_ResolveConfig
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Pay_Transaction_ResolveConfig
    @EmpresaId    INT,
    @SucursalId   INT,
    @ProviderCode NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.*, p.Code AS ProviderCode
    FROM pay.CompanyPaymentConfig c
    JOIN pay.PaymentProviders p ON p.Id = c.ProviderId
    WHERE c.EmpresaId  = @EmpresaId
      AND c.SucursalId = @SucursalId
      AND p.Code       = @ProviderCode
      AND c.IsActive   = 1;
END;
GO

-- ============================================================================
-- 9b. PAYMENT ENGINE: usp_Pay_Transaction_Insert
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Pay_Transaction_Insert
    @TransactionUUID    VARCHAR(36),
    @EmpresaId          INT,
    @SucursalId         INT,
    @SourceType         VARCHAR(30),
    @SourceId           INT           = NULL,
    @SourceNumber       VARCHAR(50)   = NULL,
    @PaymentMethodCode  VARCHAR(30),
    @ProviderId         INT           = NULL,
    @Currency           VARCHAR(3),
    @Amount             DECIMAL(18,2),
    @TrxType            VARCHAR(20),
    @Status             VARCHAR(20),
    @GatewayTrxId       VARCHAR(100)  = NULL,
    @GatewayAuthCode    VARCHAR(50)   = NULL,
    @GatewayResponse    NVARCHAR(MAX) = NULL,
    @GatewayMessage     NVARCHAR(500) = NULL,
    @CardLastFour       VARCHAR(4)    = NULL,
    @CardBrand          VARCHAR(20)   = NULL,
    @MobileNumber       VARCHAR(20)   = NULL,
    @BankCode           VARCHAR(10)   = NULL,
    @PaymentRef         VARCHAR(50)   = NULL,
    @StationId          VARCHAR(50)   = NULL,
    @CashierId          VARCHAR(20)   = NULL,
    @IpAddress          VARCHAR(45)   = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pay.Transactions (
        TransactionUUID, EmpresaId, SucursalId,
        SourceType, SourceId, SourceNumber,
        PaymentMethodCode, ProviderId,
        Currency, Amount, TrxType, Status,
        GatewayTrxId, GatewayAuthCode, GatewayResponse, GatewayMessage,
        CardLastFour, CardBrand,
        MobileNumber, BankCode, PaymentRef,
        StationId, CashierId, IpAddress
    ) VALUES (
        @TransactionUUID, @EmpresaId, @SucursalId,
        @SourceType, @SourceId, @SourceNumber,
        @PaymentMethodCode, @ProviderId,
        @Currency, @Amount, @TrxType, @Status,
        @GatewayTrxId, @GatewayAuthCode, @GatewayResponse, @GatewayMessage,
        @CardLastFour, @CardBrand,
        @MobileNumber, @BankCode, @PaymentRef,
        @StationId, @CashierId, @IpAddress
    );
END;
GO

-- ============================================================================
-- 9c. PAYMENT ENGINE: usp_Pay_Transaction_UpdateStatus
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Pay_Transaction_UpdateStatus
    @TransactionUUID VARCHAR(36),
    @Status          VARCHAR(20),
    @GatewayTrxId    VARCHAR(100)  = NULL,
    @GatewayAuthCode VARCHAR(50)   = NULL,
    @GatewayResponse NVARCHAR(MAX) = NULL,
    @GatewayMessage  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pay.Transactions
    SET Status          = @Status,
        GatewayTrxId    = COALESCE(@GatewayTrxId, GatewayTrxId),
        GatewayAuthCode = COALESCE(@GatewayAuthCode, GatewayAuthCode),
        GatewayResponse = COALESCE(@GatewayResponse, GatewayResponse),
        GatewayMessage  = COALESCE(@GatewayMessage, GatewayMessage),
        UpdatedAt       = GETDATE()
    WHERE TransactionUUID = @TransactionUUID;
END;
GO

-- ============================================================================
-- 9d. PAYMENT ENGINE: usp_Pay_Transaction_Search
--     Busqueda dinamica con filtros opcionales.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Pay_Transaction_Search
    @EmpresaId     INT,
    @SucursalId    INT           = NULL,
    @ProviderCode  NVARCHAR(30)  = NULL,
    @SourceType    VARCHAR(30)   = NULL,
    @SourceNumber  VARCHAR(50)   = NULL,
    @Status        VARCHAR(20)   = NULL,
    @DateFrom      DATETIME      = NULL,
    @DateTo        DATETIME      = NULL,
    @Offset        INT           = 0,
    @Limit         INT           = 50
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.*, p.Code AS ProviderCode, p.Name AS ProviderName
    FROM pay.Transactions t
    LEFT JOIN pay.PaymentProviders p ON p.Id = t.ProviderId
    WHERE t.EmpresaId  = @EmpresaId
      AND (@SucursalId   IS NULL OR t.SucursalId   = @SucursalId)
      AND (@ProviderCode IS NULL OR p.Code         = @ProviderCode)
      AND (@SourceType   IS NULL OR t.SourceType   = @SourceType)
      AND (@SourceNumber IS NULL OR t.SourceNumber = @SourceNumber)
      AND (@Status       IS NULL OR t.Status       = @Status)
      AND (@DateFrom     IS NULL OR t.CreatedAt   >= @DateFrom)
      AND (@DateTo       IS NULL OR t.CreatedAt   <= @DateTo)
    ORDER BY t.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- ============================================================================
-- 9e. PAYMENT ENGINE: usp_Pay_Transaction_SearchCount
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Pay_Transaction_SearchCount
    @EmpresaId     INT,
    @SucursalId    INT           = NULL,
    @ProviderCode  NVARCHAR(30)  = NULL,
    @SourceType    VARCHAR(30)   = NULL,
    @SourceNumber  VARCHAR(50)   = NULL,
    @Status        VARCHAR(20)   = NULL,
    @DateFrom      DATETIME      = NULL,
    @DateTo        DATETIME      = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(1) AS total
    FROM pay.Transactions t
    LEFT JOIN pay.PaymentProviders p ON p.Id = t.ProviderId
    WHERE t.EmpresaId  = @EmpresaId
      AND (@SucursalId   IS NULL OR t.SucursalId   = @SucursalId)
      AND (@ProviderCode IS NULL OR p.Code         = @ProviderCode)
      AND (@SourceType   IS NULL OR t.SourceType   = @SourceType)
      AND (@SourceNumber IS NULL OR t.SourceNumber = @SourceNumber)
      AND (@Status       IS NULL OR t.Status       = @Status)
      AND (@DateFrom     IS NULL OR t.CreatedAt   >= @DateFrom)
      AND (@DateTo       IS NULL OR t.CreatedAt   <= @DateTo);
END;
GO

-- ============================================================================
-- 10. CRUD GENERICO: usp_Sys_GenericList
--     Lista dinamica segura con QUOTENAME.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_GenericList
    @SchemaName   NVARCHAR(128),
    @TableName    NVARCHAR(128),
    @SortColumn   NVARCHAR(128),
    @SortDir      NVARCHAR(4)    = 'ASC',
    @Offset       INT            = 0,
    @PageSize     INT            = 50,
    @FiltersJson  NVARCHAR(MAX)  = NULL,
    @TotalCount   INT            = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    DECLARE @SafeSort  NVARCHAR(260) = QUOTENAME(@SortColumn);
    DECLARE @Direction NVARCHAR(4)   = CASE WHEN UPPER(@SortDir) = 'DESC' THEN 'DESC' ELSE 'ASC' END;

    DECLARE @SafeWhere NVARCHAR(MAX) = '';

    -- Build WHERE from JSON filters (key=value equality)
    IF @FiltersJson IS NOT NULL AND LEN(@FiltersJson) > 2
    BEGIN
        SELECT @SafeWhere = @SafeWhere +
            CASE WHEN LEN(@SafeWhere) > 0 THEN ' AND ' ELSE ' WHERE ' END +
            QUOTENAME([key]) + ' = N''' + REPLACE(CAST([value] AS NVARCHAR(500)), '''', '''''') + ''''
        FROM OPENJSON(@FiltersJson);
    END;

    -- Count query into OUTPUT param
    DECLARE @CountSql NVARCHAR(MAX) = N'SELECT @cnt = COUNT(1) FROM ' + @FullTable + @SafeWhere;
    EXEC sp_executesql @CountSql, N'@cnt INT OUTPUT', @cnt = @TotalCount OUTPUT;

    -- Data query (single resultset returned to caller)
    DECLARE @DataSql NVARCHAR(MAX) = 'SELECT * FROM ' + @FullTable + @SafeWhere
        + ' ORDER BY ' + @SafeSort + ' ' + @Direction
        + ' OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY';

    EXEC sp_executesql @DataSql, N'@Offset INT, @PageSize INT', @Offset = @Offset, @PageSize = @PageSize;
END;
GO

-- ============================================================================
-- 10b. CRUD GENERICO: usp_Sys_GenericGetByKey
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_GenericGetByKey
    @SchemaName NVARCHAR(128),
    @TableName  NVARCHAR(128),
    @KeyJson    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    DECLARE @WhereClause NVARCHAR(MAX) = '';

    SELECT @WhereClause = @WhereClause +
        CASE WHEN LEN(@WhereClause) > 0 THEN ' AND ' ELSE ' WHERE ' END +
        QUOTENAME([key]) + ' = N''' + REPLACE(CAST([value] AS NVARCHAR(500)), '''', '''''') + ''''
    FROM OPENJSON(@KeyJson);

    DECLARE @Sql NVARCHAR(MAX) = 'SELECT * FROM ' + @FullTable + @WhereClause;
    EXEC sp_executesql @Sql;
END;
GO

-- ============================================================================
-- 10c. CRUD GENERICO: usp_Sys_GenericInsert
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_GenericInsert
    @SchemaName NVARCHAR(128),
    @TableName  NVARCHAR(128),
    @DataJson   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);
    DECLARE @Cols NVARCHAR(MAX) = '';
    DECLARE @Vals NVARCHAR(MAX) = '';

    SELECT
        @Cols = @Cols + CASE WHEN LEN(@Cols) > 0 THEN ', ' ELSE '' END + QUOTENAME([key]),
        @Vals = @Vals + CASE WHEN LEN(@Vals) > 0 THEN ', ' ELSE '' END +
            CASE WHEN [type] = 0 THEN 'NULL'
                 ELSE 'N''' + REPLACE(CAST([value] AS NVARCHAR(MAX)), '''', '''''') + '''' END
    FROM OPENJSON(@DataJson);

    IF LEN(@Cols) = 0
    BEGIN
        RAISERROR('no_writable_fields', 16, 1);
        RETURN;
    END;

    DECLARE @Sql NVARCHAR(MAX) = 'INSERT INTO ' + @FullTable + ' (' + @Cols + ') VALUES (' + @Vals + ')';
    EXEC sp_executesql @Sql;
END;
GO

-- ============================================================================
-- 10d. CRUD GENERICO: usp_Sys_GenericUpdate
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_GenericUpdate
    @SchemaName NVARCHAR(128),
    @TableName  NVARCHAR(128),
    @KeyJson    NVARCHAR(MAX),
    @DataJson   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);

    -- Build SET clause
    DECLARE @SetClause NVARCHAR(MAX) = '';
    SELECT @SetClause = @SetClause +
        CASE WHEN LEN(@SetClause) > 0 THEN ', ' ELSE '' END +
        QUOTENAME([key]) + ' = ' +
        CASE WHEN [type] = 0 THEN 'NULL'
             ELSE 'N''' + REPLACE(CAST([value] AS NVARCHAR(MAX)), '''', '''''') + '''' END
    FROM OPENJSON(@DataJson);

    IF LEN(@SetClause) = 0
    BEGIN
        RAISERROR('no_writable_fields', 16, 1);
        RETURN;
    END;

    -- Build WHERE clause from key
    DECLARE @WhereClause NVARCHAR(MAX) = '';
    SELECT @WhereClause = @WhereClause +
        CASE WHEN LEN(@WhereClause) > 0 THEN ' AND ' ELSE '' END +
        QUOTENAME([key]) + ' = N''' + REPLACE(CAST([value] AS NVARCHAR(500)), '''', '''''') + ''''
    FROM OPENJSON(@KeyJson);

    DECLARE @Sql NVARCHAR(MAX) = 'UPDATE ' + @FullTable + ' SET ' + @SetClause + ' WHERE ' + @WhereClause;
    EXEC sp_executesql @Sql;

    SELECT @@ROWCOUNT AS rowsAffected;
END;
GO

-- ============================================================================
-- 10e. CRUD GENERICO: usp_Sys_GenericDelete
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_GenericDelete
    @SchemaName NVARCHAR(128),
    @TableName  NVARCHAR(128),
    @KeyJson    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FullTable NVARCHAR(260) = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);

    DECLARE @WhereClause NVARCHAR(MAX) = '';
    SELECT @WhereClause = @WhereClause +
        CASE WHEN LEN(@WhereClause) > 0 THEN ' AND ' ELSE '' END +
        QUOTENAME([key]) + ' = N''' + REPLACE(CAST([value] AS NVARCHAR(500)), '''', '''''') + ''''
    FROM OPENJSON(@KeyJson);

    DECLARE @Sql NVARCHAR(MAX) = 'DELETE FROM ' + @FullTable + ' WHERE ' + @WhereClause;
    EXEC sp_executesql @Sql;

    SELECT @@ROWCOUNT AS rowsAffected;
END;
GO

-- ============================================================================
-- 11. INVENTARIO CACHE: usp_Inventario_CacheLoad
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Inventario_CacheLoad
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProductId,
        ProductCode,
        ProductName,
        CategoryCode,
        UnitCode,
        SalesPrice,
        CostPrice,
        DefaultTaxRate,
        StockQty,
        IsService,
        IsDeleted,
        UpdatedAt
    FROM [master].Product
    WHERE CompanyId = @CompanyId
    ORDER BY ProductCode;
END;
GO

-- ============================================================================
-- 11b. INVENTARIO CACHE: usp_Inventario_GetByCode
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Inventario_GetByCode
    @CompanyId INT,
    @Codigo    NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        ProductId,
        ProductCode,
        ProductName,
        CategoryCode,
        UnitCode,
        SalesPrice,
        CostPrice,
        DefaultTaxRate,
        StockQty,
        IsService,
        IsDeleted,
        UpdatedAt
    FROM [master].Product
    WHERE CompanyId   = @CompanyId
      AND ProductCode = @Codigo;
END;
GO

-- ============================================================================
-- 12. TX HELPERS: usp_Sys_HeaderDetailTx
--     Inserta cabecera + detalle en una transaccion.
--     Recibe datos como JSON.
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Sys_HeaderDetailTx
    @HeaderTable  NVARCHAR(260),
    @DetailTable  NVARCHAR(260),
    @HeaderJson   NVARCHAR(MAX),
    @DetailsJson  NVARCHAR(MAX),
    @LinkFieldsCsv NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insert header
        DECLARE @HCols NVARCHAR(MAX) = '';
        DECLARE @HVals NVARCHAR(MAX) = '';

        SELECT
            @HCols = @HCols + CASE WHEN LEN(@HCols) > 0 THEN ', ' ELSE '' END + QUOTENAME([key]),
            @HVals = @HVals + CASE WHEN LEN(@HVals) > 0 THEN ', ' ELSE '' END +
                CASE WHEN [type] = 0 THEN 'NULL'
                     ELSE 'N''' + REPLACE(CAST([value] AS NVARCHAR(MAX)), '''', '''''') + '''' END
        FROM OPENJSON(@HeaderJson);

        DECLARE @InsertHeaderSql NVARCHAR(MAX) = 'INSERT INTO ' + @HeaderTable + ' (' + @HCols + ') VALUES (' + @HVals + ')';
        EXEC sp_executesql @InsertHeaderSql;

        -- Insert details
        DECLARE @DetailIdx INT = 0;
        DECLARE @DetailCount INT = (SELECT COUNT(*) FROM OPENJSON(@DetailsJson));

        WHILE @DetailIdx < @DetailCount
        BEGIN
            DECLARE @DetailRow NVARCHAR(MAX) = (
                SELECT [value] FROM OPENJSON(@DetailsJson)
                WHERE [key] = CAST(@DetailIdx AS NVARCHAR(10))
            );

            -- If link fields specified, merge header values into detail where missing
            IF @LinkFieldsCsv IS NOT NULL AND LEN(@LinkFieldsCsv) > 0
            BEGIN
                DECLARE @lf NVARCHAR(128);
                DECLARE lfCursor CURSOR LOCAL FAST_FORWARD FOR
                    SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@LinkFieldsCsv, ',');
                OPEN lfCursor;
                FETCH NEXT FROM lfCursor INTO @lf;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Add header value if not present in detail
                    IF JSON_VALUE(@DetailRow, '$.' + @lf) IS NULL
                    BEGIN
                        DECLARE @hVal NVARCHAR(MAX) = JSON_VALUE(@HeaderJson, '$.' + @lf);
                        IF @hVal IS NOT NULL
                            SET @DetailRow = JSON_MODIFY(@DetailRow, '$.' + @lf, @hVal);
                    END;
                    FETCH NEXT FROM lfCursor INTO @lf;
                END;
                CLOSE lfCursor;
                DEALLOCATE lfCursor;
            END;

            DECLARE @DCols NVARCHAR(MAX) = '';
            DECLARE @DVals NVARCHAR(MAX) = '';

            SELECT
                @DCols = @DCols + CASE WHEN LEN(@DCols) > 0 THEN ', ' ELSE '' END + QUOTENAME([key]),
                @DVals = @DVals + CASE WHEN LEN(@DVals) > 0 THEN ', ' ELSE '' END +
                    CASE WHEN [type] = 0 THEN 'NULL'
                         ELSE 'N''' + REPLACE(CAST([value] AS NVARCHAR(MAX)), '''', '''''') + '''' END
            FROM OPENJSON(@DetailRow);

            DECLARE @InsertDetailSql NVARCHAR(MAX) = 'INSERT INTO ' + @DetailTable + ' (' + @DCols + ') VALUES (' + @DVals + ')';
            EXEC sp_executesql @InsertDetailSql;

            SET @DetailIdx = @DetailIdx + 1;
            SET @DCols = '';
            SET @DVals = '';
        END;

        COMMIT TRANSACTION;
        SELECT 1 AS ok, @DetailCount AS detailRows;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
