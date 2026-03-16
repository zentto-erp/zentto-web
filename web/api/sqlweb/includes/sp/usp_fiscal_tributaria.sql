-- =============================================================================
-- usp_fiscal_tributaria.sql
-- Procedimientos de Gestion Fiscal y Tributaria
-- Operaciones sobre fiscal.TaxBookEntry, fiscal.TaxDeclaration,
-- fiscal.WithholdingVoucher y fiscal.DeclarationTemplate.
--
-- Procedimientos incluidos:
--   1.  usp_Fiscal_TaxBook_Populate       - Genera libro fiscal desde documentos
--   2.  usp_Fiscal_TaxBook_List           - Listado paginado de entradas de libro
--   3.  usp_Fiscal_TaxBook_Summary        - Resumen agrupado por tasa impositiva
--   4.  usp_Fiscal_Declaration_Calculate  - Calcula declaracion de impuestos
--   5.  usp_Fiscal_Declaration_List       - Listado paginado de declaraciones
--   6.  usp_Fiscal_Declaration_Get        - Detalle de una declaracion
--   7.  usp_Fiscal_Declaration_Submit     - Marca declaracion como presentada
--   8.  usp_Fiscal_Declaration_Amend      - Marca declaracion como enmendada
--   9.  usp_Fiscal_Withholding_Generate   - Genera comprobante de retencion
--  10.  usp_Fiscal_Withholding_List       - Listado paginado de retenciones
--  11.  usp_Fiscal_Withholding_Get        - Detalle de un comprobante de retencion
--  12.  usp_Fiscal_Export_TaxBook         - Exporta libro fiscal completo
--  13.  usp_Fiscal_Export_Declaration     - Exporta declaracion para presentacion
--
-- Columnas reales de las tablas:
--   fiscal.TaxBookEntry: EntryId, CompanyId, BookType, PeriodCode, EntryDate,
--     DocumentNumber, DocumentType, ControlNumber, ThirdPartyId, ThirdPartyName,
--     TaxableBase, ExemptAmount, TaxRate, TaxAmount, WithholdingRate,
--     WithholdingAmount, TotalAmount, SourceDocumentId, SourceModule,
--     CountryCode, DeclarationId, CreatedAt
--   fiscal.TaxDeclaration: DeclarationId, CompanyId, BranchId, CountryCode,
--     DeclarationType, PeriodCode, PeriodStart, PeriodEnd, SalesBase, SalesTax,
--     PurchasesBase, PurchasesTax, TaxableBase, TaxAmount, WithholdingsCredit,
--     PreviousBalance, NetPayable, Status, SubmittedAt, SubmittedFile,
--     AuthorityResponse, PaidAt, PaymentReference, JournalEntryId, Notes,
--     CreatedBy, UpdatedBy, CreatedAt, UpdatedAt
--   fiscal.WithholdingVoucher: VoucherId, CompanyId, VoucherNumber, VoucherDate,
--     WithholdingType, ThirdPartyId, ThirdPartyName, DocumentNumber,
--     DocumentDate, TaxableBase, WithholdingRate, WithholdingAmount,
--     PeriodCode, Status, CountryCode, JournalEntryId, CreatedBy, CreatedAt
--
-- Dependencias:
--   - fiscal.TaxBookEntry, fiscal.TaxDeclaration, fiscal.WithholdingVoucher
--   - fiscal.DeclarationTemplate, fiscal.ISLRTariff
--   - master.TaxRetention
--   - dbo.DocumentosVenta, dbo.DocumentosCompra
--
-- Fecha creacion: 2026-03-16
-- =============================================================================
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- 1. usp_Fiscal_TaxBook_Populate
--    Genera (o regenera) las entradas del libro fiscal para un periodo dado,
--    a partir de los documentos de venta o compra segun @BookType.
--    Fuente SALES: dbo.DocumentosVenta
--    Fuente PURCHASE: dbo.DocumentosCompra
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_TaxBook_Populate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_TaxBook_Populate;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.usp_Fiscal_TaxBook_Populate
    @CompanyId   INT,
    @BookType    NVARCHAR(10),
    @PeriodCode  NVARCHAR(7),
    @CountryCode NVARCHAR(2),
    @CodUsuario  NVARCHAR(40),
    @Resultado   INT            OUTPUT,
    @Mensaje     NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PeriodStart DATE;
    DECLARE @PeriodEnd   DATE;
    DECLARE @RowsInserted INT = 0;

    -- Calcular inicio y fin del periodo desde @PeriodCode (YYYY-MM)
    SET @PeriodStart = CAST(@PeriodCode + '-01' AS DATE);
    SET @PeriodEnd   = EOMONTH(@PeriodStart);

    -- Validar parametros
    IF @BookType NOT IN ('SALES', 'PURCHASE')
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'BookType debe ser SALES o PURCHASE';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Eliminar entradas existentes para regenerar
        DELETE FROM fiscal.TaxBookEntry
        WHERE CompanyId   = @CompanyId
          AND BookType    = @BookType
          AND PeriodCode  = @PeriodCode
          AND CountryCode = @CountryCode;

        IF @BookType = 'SALES'
        BEGIN
            -- Fuente: dbo.DocumentosVenta
            -- Columnas: ID, NUM_DOC, SERIALTIPO, TIPO_OPERACION, CODIGO, NOMBRE,
            --           RIF, FECHA, SUBTOTAL, MONTO_GRA, MONTO_EXE, IVA, ALICUOTA,
            --           TOTAL, DESCUENTO, ANULADA, NUM_CONTROL
            INSERT INTO fiscal.TaxBookEntry
            (
                CompanyId,
                BookType,
                PeriodCode,
                EntryDate,
                DocumentNumber,
                DocumentType,
                ControlNumber,
                ThirdPartyId,
                ThirdPartyName,
                TaxableBase,
                ExemptAmount,
                TaxRate,
                TaxAmount,
                WithholdingRate,
                WithholdingAmount,
                TotalAmount,
                SourceDocumentId,
                SourceModule,
                CountryCode,
                CreatedAt
            )
            SELECT
                @CompanyId,
                'SALES',
                @PeriodCode,
                v.FECHA,
                v.NUM_DOC,
                CASE v.SERIALTIPO
                    WHEN 'FAC' THEN 'FACTURA'
                    WHEN 'NC'  THEN 'NOTA_CREDITO'
                    WHEN 'ND'  THEN 'NOTA_DEBITO'
                    ELSE v.SERIALTIPO
                END,
                v.NUM_CONTROL,
                v.RIF,
                v.NOMBRE,
                ISNULL(v.MONTO_GRA, 0),
                ISNULL(v.MONTO_EXE, 0),
                ISNULL(v.ALICUOTA, 0),
                ISNULL(v.IVA, 0),
                0,  -- WithholdingRate: se actualizara con comprobantes
                0,  -- WithholdingAmount: se actualizara con comprobantes
                ISNULL(v.TOTAL, 0),
                v.ID,
                'AR',
                @CountryCode,
                SYSUTCDATETIME()
            FROM dbo.DocumentosVenta v
            WHERE v.FECHA BETWEEN @PeriodStart AND @PeriodEnd
              AND v.ANULADA = 0;

            SET @RowsInserted = @@ROWCOUNT;
        END
        ELSE IF @BookType = 'PURCHASE'
        BEGIN
            -- Fuente: dbo.DocumentosCompra
            -- Columnas: ID, NUM_DOC, SERIALTIPO, TIPO_OPERACION, COD_PROVEEDOR,
            --           NOMBRE, RIF, FECHA, SUBTOTAL, MONTO_GRA, MONTO_EXE, IVA,
            --           ALICUOTA, TOTAL, EXENTO, DESCUENTO, ANULADA, NUM_CONTROL,
            --           NRO_COMPROBANTE
            INSERT INTO fiscal.TaxBookEntry
            (
                CompanyId,
                BookType,
                PeriodCode,
                EntryDate,
                DocumentNumber,
                DocumentType,
                ControlNumber,
                ThirdPartyId,
                ThirdPartyName,
                TaxableBase,
                ExemptAmount,
                TaxRate,
                TaxAmount,
                WithholdingRate,
                WithholdingAmount,
                TotalAmount,
                SourceDocumentId,
                SourceModule,
                CountryCode,
                CreatedAt
            )
            SELECT
                @CompanyId,
                'PURCHASE',
                @PeriodCode,
                c.FECHA,
                c.NUM_DOC,
                CASE c.SERIALTIPO
                    WHEN 'FAC' THEN 'FACTURA'
                    WHEN 'NC'  THEN 'NOTA_CREDITO'
                    WHEN 'ND'  THEN 'NOTA_DEBITO'
                    ELSE c.SERIALTIPO
                END,
                c.NUM_CONTROL,
                c.RIF,
                c.NOMBRE,
                ISNULL(c.MONTO_GRA, 0),
                ISNULL(c.MONTO_EXE, 0),
                ISNULL(c.ALICUOTA, 0),
                ISNULL(c.IVA, 0),
                0,  -- WithholdingRate: se actualizara con comprobantes
                0,  -- WithholdingAmount: se actualizara con comprobantes
                ISNULL(c.TOTAL, 0),
                c.ID,
                'AP',
                @CountryCode,
                SYSUTCDATETIME()
            FROM dbo.DocumentosCompra c
            WHERE c.FECHA BETWEEN @PeriodStart AND @PeriodEnd
              AND c.ANULADA = 0;

            SET @RowsInserted = @@ROWCOUNT;
        END;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Libro fiscal generado: ' + CAST(@RowsInserted AS NVARCHAR(10)) + N' registros';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
-- 2. usp_Fiscal_TaxBook_List
--    Listado paginado de entradas del libro fiscal.
--    Filtra por empresa, tipo de libro, periodo y pais.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_TaxBook_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_TaxBook_List;
GO
CREATE PROCEDURE dbo.usp_Fiscal_TaxBook_List
    @CompanyId   INT,
    @BookType    NVARCHAR(10),
    @PeriodCode  NVARCHAR(7),
    @CountryCode NVARCHAR(2),
    @Page        INT         = 1,
    @Limit       INT         = 100,
    @TotalCount  INT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 100;
    IF @Limit > 500  SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM fiscal.TaxBookEntry
    WHERE CompanyId   = @CompanyId
      AND BookType    = @BookType
      AND PeriodCode  = @PeriodCode
      AND CountryCode = @CountryCode;

    -- Retornar pagina solicitada
    SELECT
        EntryId,
        CompanyId,
        BookType,
        PeriodCode,
        EntryDate,
        DocumentNumber,
        DocumentType,
        ControlNumber,
        ThirdPartyId,
        ThirdPartyName,
        TaxableBase,
        ExemptAmount,
        TaxRate,
        TaxAmount,
        WithholdingRate,
        WithholdingAmount,
        TotalAmount,
        SourceDocumentId,
        SourceModule,
        CountryCode,
        DeclarationId,
        CreatedAt
    FROM fiscal.TaxBookEntry
    WHERE CompanyId   = @CompanyId
      AND BookType    = @BookType
      AND PeriodCode  = @PeriodCode
      AND CountryCode = @CountryCode
    ORDER BY EntryDate, DocumentNumber
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 3. usp_Fiscal_TaxBook_Summary
--    Resumen del libro fiscal agrupado por tasa impositiva.
--    Retorna totales de base imponible, exento, impuesto, retenciones y conteo.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_TaxBook_Summary', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_TaxBook_Summary;
GO
CREATE PROCEDURE dbo.usp_Fiscal_TaxBook_Summary
    @CompanyId   INT,
    @BookType    NVARCHAR(10),
    @PeriodCode  NVARCHAR(7),
    @CountryCode NVARCHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TaxRate,
        SUM(TaxableBase)        AS TaxableBase,
        SUM(ExemptAmount)       AS ExemptAmount,
        SUM(TaxAmount)          AS TaxAmount,
        SUM(WithholdingAmount)  AS WithholdingAmount,
        SUM(TotalAmount)        AS TotalAmount,
        COUNT(*)                AS EntryCount
    FROM fiscal.TaxBookEntry
    WHERE CompanyId   = @CompanyId
      AND BookType    = @BookType
      AND PeriodCode  = @PeriodCode
      AND CountryCode = @CountryCode
    GROUP BY TaxRate
    ORDER BY TaxRate;
END;
GO

-- =============================================================================
-- 4. usp_Fiscal_Declaration_Calculate
--    Calcula una declaracion de impuestos (IVA/MODELO_303 o ISLR/IRPF)
--    a partir de los libros fiscales y comprobantes de retencion del periodo.
--    Si existe un borrador previo para el mismo tipo y periodo, lo reemplaza.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Declaration_Calculate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Declaration_Calculate;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Declaration_Calculate
    @CompanyId       INT,
    @DeclarationType NVARCHAR(30),
    @PeriodCode      NVARCHAR(7),
    @CountryCode     NVARCHAR(2),
    @CodUsuario      NVARCHAR(40),
    @DeclarationId   BIGINT          OUTPUT,
    @Resultado       INT             OUTPUT,
    @Mensaje         NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PeriodStart DATE;
    DECLARE @PeriodEnd   DATE;
    DECLARE @SalesBase         DECIMAL(18,2) = 0;
    DECLARE @SalesTax          DECIMAL(18,2) = 0;
    DECLARE @PurchasesBase     DECIMAL(18,2) = 0;
    DECLARE @PurchasesTax      DECIMAL(18,2) = 0;
    DECLARE @WithholdingsCredit DECIMAL(18,2) = 0;
    DECLARE @TaxableBase       DECIMAL(18,2) = 0;
    DECLARE @TaxAmount         DECIMAL(18,2) = 0;
    DECLARE @NetPayable        DECIMAL(18,2) = 0;

    SET @PeriodStart = CAST(@PeriodCode + '-01' AS DATE);
    SET @PeriodEnd   = EOMONTH(@PeriodStart);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @DeclarationType IN ('IVA', 'MODELO_303')
        BEGIN
            -- Totales de ventas
            SELECT
                @SalesBase = ISNULL(SUM(TaxableBase), 0),
                @SalesTax  = ISNULL(SUM(TaxAmount), 0)
            FROM fiscal.TaxBookEntry
            WHERE CompanyId   = @CompanyId
              AND BookType    = 'SALES'
              AND PeriodCode  = @PeriodCode
              AND CountryCode = @CountryCode;

            -- Totales de compras
            SELECT
                @PurchasesBase = ISNULL(SUM(TaxableBase), 0),
                @PurchasesTax  = ISNULL(SUM(TaxAmount), 0)
            FROM fiscal.TaxBookEntry
            WHERE CompanyId   = @CompanyId
              AND BookType    = 'PURCHASE'
              AND PeriodCode  = @PeriodCode
              AND CountryCode = @CountryCode;

            -- Credito por retenciones de IVA
            SELECT
                @WithholdingsCredit = ISNULL(SUM(WithholdingAmount), 0)
            FROM fiscal.WithholdingVoucher
            WHERE CompanyId      = @CompanyId
              AND PeriodCode     = @PeriodCode
              AND WithholdingType = 'IVA'
              AND CountryCode    = @CountryCode;

            SET @TaxableBase = @SalesBase - @PurchasesBase;
            SET @TaxAmount   = @SalesTax  - @PurchasesTax;
            SET @NetPayable  = @TaxAmount - @WithholdingsCredit;
        END
        ELSE IF @DeclarationType IN ('ISLR', 'IRPF')
        BEGIN
            -- Totales de ingresos (ventas)
            SELECT
                @SalesBase = ISNULL(SUM(TaxableBase), 0),
                @SalesTax  = ISNULL(SUM(TaxAmount), 0)
            FROM fiscal.TaxBookEntry
            WHERE CompanyId   = @CompanyId
              AND BookType    = 'SALES'
              AND PeriodCode  = @PeriodCode
              AND CountryCode = @CountryCode;

            -- Deducciones (compras)
            SELECT
                @PurchasesBase = ISNULL(SUM(TaxableBase), 0),
                @PurchasesTax  = ISNULL(SUM(TaxAmount), 0)
            FROM fiscal.TaxBookEntry
            WHERE CompanyId   = @CompanyId
              AND BookType    = 'PURCHASE'
              AND PeriodCode  = @PeriodCode
              AND CountryCode = @CountryCode;

            -- Credito por retenciones de ISLR/IRPF
            SELECT
                @WithholdingsCredit = ISNULL(SUM(WithholdingAmount), 0)
            FROM fiscal.WithholdingVoucher
            WHERE CompanyId       = @CompanyId
              AND PeriodCode      = @PeriodCode
              AND WithholdingType = @DeclarationType
              AND CountryCode     = @CountryCode;

            SET @TaxableBase = @SalesBase - @PurchasesBase;
            SET @TaxAmount   = @SalesTax  - @PurchasesTax;
            SET @NetPayable  = @TaxAmount - @WithholdingsCredit;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Resultado     = 0;
            SET @Mensaje       = N'Tipo de declaracion no soportado: ' + @DeclarationType;
            SET @DeclarationId = 0;
            RETURN;
        END;

        -- Eliminar borrador previo para el mismo tipo y periodo
        DELETE FROM fiscal.TaxDeclaration
        WHERE CompanyId       = @CompanyId
          AND DeclarationType = @DeclarationType
          AND PeriodCode      = @PeriodCode
          AND CountryCode     = @CountryCode
          AND Status          = 'DRAFT';

        -- Insertar nueva declaracion con todas las columnas correctas
        INSERT INTO fiscal.TaxDeclaration
        (
            CompanyId,
            CountryCode,
            DeclarationType,
            PeriodCode,
            PeriodStart,
            PeriodEnd,
            SalesBase,
            SalesTax,
            PurchasesBase,
            PurchasesTax,
            TaxableBase,
            TaxAmount,
            WithholdingsCredit,
            PreviousBalance,
            NetPayable,
            Status,
            CreatedBy,
            CreatedAt
        )
        VALUES
        (
            @CompanyId,
            @CountryCode,
            @DeclarationType,
            @PeriodCode,
            @PeriodStart,
            @PeriodEnd,
            @SalesBase,
            @SalesTax,
            @PurchasesBase,
            @PurchasesTax,
            @TaxableBase,
            @TaxAmount,
            @WithholdingsCredit,
            0,  -- PreviousBalance: por defecto 0, ajustable manualmente
            @NetPayable,
            'CALCULATED',
            @CodUsuario,
            SYSUTCDATETIME()
        );

        SET @DeclarationId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Declaracion calculada. Base: ' + CAST(@TaxableBase AS NVARCHAR(20))
                       + N', Impuesto: ' + CAST(@TaxAmount AS NVARCHAR(20))
                       + N', Neto a pagar: ' + CAST(@NetPayable AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado     = 0;
        SET @DeclarationId = 0;
        SET @Mensaje       = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
-- 5. usp_Fiscal_Declaration_List
--    Listado paginado de declaraciones fiscales.
--    Filtros opcionales por tipo, ano y estado.
--    Usa LEFT(PeriodCode, 4) para filtrar por ano (compatible SQL Server 2012).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Declaration_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Declaration_List;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Declaration_List
    @CompanyId       INT,
    @DeclarationType NVARCHAR(30) = NULL,
    @Year            INT          = NULL,
    @Status          NVARCHAR(20) = NULL,
    @Page            INT          = 1,
    @Limit           INT          = 50,
    @TotalCount      INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500  SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM fiscal.TaxDeclaration
    WHERE CompanyId = @CompanyId
      AND (@DeclarationType IS NULL OR DeclarationType = @DeclarationType)
      AND (@Year            IS NULL OR LEFT(PeriodCode, 4) = CAST(@Year AS VARCHAR(4)))
      AND (@Status          IS NULL OR Status = @Status);

    -- Retornar pagina solicitada
    SELECT
        DeclarationId,
        CompanyId,
        BranchId,
        CountryCode,
        DeclarationType,
        PeriodCode,
        PeriodStart,
        PeriodEnd,
        SalesBase,
        SalesTax,
        PurchasesBase,
        PurchasesTax,
        TaxableBase,
        TaxAmount,
        WithholdingsCredit,
        PreviousBalance,
        NetPayable,
        Status,
        SubmittedAt,
        SubmittedFile,
        AuthorityResponse,
        PaidAt,
        PaymentReference,
        JournalEntryId,
        Notes,
        CreatedBy,
        UpdatedBy,
        CreatedAt,
        UpdatedAt
    FROM fiscal.TaxDeclaration
    WHERE CompanyId = @CompanyId
      AND (@DeclarationType IS NULL OR DeclarationType = @DeclarationType)
      AND (@Year            IS NULL OR LEFT(PeriodCode, 4) = CAST(@Year AS VARCHAR(4)))
      AND (@Status          IS NULL OR Status = @Status)
    ORDER BY PeriodCode DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 6. usp_Fiscal_Declaration_Get
--    Obtiene el detalle completo de una declaracion fiscal por su ID.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Declaration_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Declaration_Get;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Declaration_Get
    @CompanyId     INT,
    @DeclarationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        DeclarationId,
        CompanyId,
        BranchId,
        CountryCode,
        DeclarationType,
        PeriodCode,
        PeriodStart,
        PeriodEnd,
        SalesBase,
        SalesTax,
        PurchasesBase,
        PurchasesTax,
        TaxableBase,
        TaxAmount,
        WithholdingsCredit,
        PreviousBalance,
        NetPayable,
        Status,
        SubmittedAt,
        SubmittedFile,
        AuthorityResponse,
        PaidAt,
        PaymentReference,
        JournalEntryId,
        Notes,
        CreatedBy,
        UpdatedBy,
        CreatedAt,
        UpdatedAt
    FROM fiscal.TaxDeclaration
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;
END;
GO

-- =============================================================================
-- 7. usp_Fiscal_Declaration_Submit
--    Marca una declaracion como presentada (SUBMITTED).
--    Solo aplica si el estado actual es CALCULATED.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Declaration_Submit', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Declaration_Submit;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Declaration_Submit
    @CompanyId     INT,
    @DeclarationId BIGINT,
    @FilePath      NVARCHAR(500)  = NULL,
    @CodUsuario    NVARCHAR(40),
    @Resultado     INT            OUTPUT,
    @Mensaje       NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus NVARCHAR(20);

    SELECT @CurrentStatus = Status
    FROM fiscal.TaxDeclaration
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Declaracion no encontrada';
        RETURN;
    END;

    IF @CurrentStatus <> 'CALCULATED'
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Solo se puede presentar una declaracion en estado CALCULATED. Estado actual: ' + @CurrentStatus;
        RETURN;
    END;

    UPDATE fiscal.TaxDeclaration
    SET Status        = 'SUBMITTED',
        SubmittedAt   = SYSUTCDATETIME(),
        SubmittedFile = @FilePath,
        UpdatedBy     = @CodUsuario,
        UpdatedAt     = SYSUTCDATETIME()
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Declaracion presentada exitosamente';
END;
GO

-- =============================================================================
-- 8. usp_Fiscal_Declaration_Amend
--    Marca una declaracion como enmendada (AMENDED).
--    Solo aplica si el estado actual es SUBMITTED.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Declaration_Amend', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Declaration_Amend;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Declaration_Amend
    @CompanyId     INT,
    @DeclarationId BIGINT,
    @CodUsuario    NVARCHAR(40),
    @Resultado     INT            OUTPUT,
    @Mensaje       NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus NVARCHAR(20);

    SELECT @CurrentStatus = Status
    FROM fiscal.TaxDeclaration
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;

    IF @CurrentStatus IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Declaracion no encontrada';
        RETURN;
    END;

    IF @CurrentStatus <> 'SUBMITTED'
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Solo se puede enmendar una declaracion en estado SUBMITTED. Estado actual: ' + @CurrentStatus;
        RETURN;
    END;

    UPDATE fiscal.TaxDeclaration
    SET Status    = 'AMENDED',
        UpdatedBy = @CodUsuario,
        UpdatedAt = SYSUTCDATETIME()
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;

    SET @Resultado = 1;
    SET @Mensaje   = N'Declaracion marcada como enmendada';
END;
GO

-- =============================================================================
-- 9. usp_Fiscal_Withholding_Generate
--    Genera un comprobante de retencion a partir de un documento de compra.
--    Obtiene la tasa de retencion desde master.TaxRetention.
--    Fuente: dbo.DocumentosCompra (columnas: ID, NUM_DOC, RIF, NOMBRE,
--            MONTO_GRA, FECHA, NRO_COMPROBANTE)
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Withholding_Generate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Withholding_Generate;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Withholding_Generate
    @CompanyId       INT,
    @DocumentId      BIGINT,          -- ID del documento en dbo.DocumentosCompra
    @WithholdingType NVARCHAR(20),
    @CountryCode     NVARCHAR(2),
    @CodUsuario      NVARCHAR(40),
    @VoucherId       BIGINT          OUTPUT,
    @Resultado       INT             OUTPUT,
    @Mensaje         NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TaxableBase       DECIMAL(18,2);
    DECLARE @Rate              DECIMAL(8,4);
    DECLARE @WithholdingAmount DECIMAL(18,2);
    DECLARE @PeriodCode        NVARCHAR(7);
    DECLARE @VoucherNumber     NVARCHAR(50);
    DECLARE @NextSeq           INT;
    DECLARE @DocFecha          DATE;
    DECLARE @DocNumDoc         NVARCHAR(50);
    DECLARE @ThirdPartyId      NVARCHAR(50);
    DECLARE @ThirdPartyName    NVARCHAR(200);

    -- Obtener datos del documento de compra (dbo.DocumentosCompra)
    SELECT
        @TaxableBase    = ISNULL(c.MONTO_GRA, 0),
        @DocFecha       = c.FECHA,
        @DocNumDoc      = c.NUM_DOC,
        @ThirdPartyId   = c.RIF,
        @ThirdPartyName = c.NOMBRE
    FROM dbo.DocumentosCompra c
    WHERE c.ID = @DocumentId;

    IF @TaxableBase IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @VoucherId = 0;
        SET @Mensaje   = N'Documento de compra no encontrado';
        RETURN;
    END;

    -- Obtener tasa de retencion desde master.TaxRetention
    SELECT TOP 1 @Rate = RetentionRate
    FROM master.TaxRetention
    WHERE RetentionType = @WithholdingType
      AND CountryCode   = @CountryCode;

    IF @Rate IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @VoucherId = 0;
        SET @Mensaje   = N'Tasa de retencion no configurada para tipo: ' + @WithholdingType + N', pais: ' + @CountryCode;
        RETURN;
    END;

    -- Calcular monto de retencion
    SET @WithholdingAmount = ROUND(@TaxableBase * @Rate / 100.0, 2);

    -- Calcular PeriodCode desde la fecha del documento
    SET @PeriodCode = FORMAT(@DocFecha, 'yyyy-MM');

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Obtener siguiente secuencial para el numero de comprobante
        SELECT @NextSeq = ISNULL(MAX(
            TRY_CAST(RIGHT(VoucherNumber, 4) AS INT)
        ), 0) + 1
        FROM fiscal.WithholdingVoucher
        WHERE CompanyId       = @CompanyId
          AND WithholdingType = @WithholdingType
          AND PeriodCode      = @PeriodCode
          AND CountryCode     = @CountryCode;

        -- Generar numero de comprobante: TIPO-YYYYMM-0001
        SET @VoucherNumber = @WithholdingType + '-'
                           + REPLACE(@PeriodCode, '-', '') + '-'
                           + RIGHT('0000' + CAST(@NextSeq AS VARCHAR(4)), 4);

        -- Insertar comprobante de retencion
        -- fiscal.WithholdingVoucher columnas: VoucherId, CompanyId, VoucherNumber,
        --   VoucherDate, WithholdingType, ThirdPartyId, ThirdPartyName,
        --   DocumentNumber, DocumentDate, TaxableBase, WithholdingRate,
        --   WithholdingAmount, PeriodCode, Status, CountryCode,
        --   JournalEntryId, CreatedBy, CreatedAt
        INSERT INTO fiscal.WithholdingVoucher
        (
            CompanyId,
            VoucherNumber,
            VoucherDate,
            WithholdingType,
            ThirdPartyId,
            ThirdPartyName,
            DocumentNumber,
            DocumentDate,
            TaxableBase,
            WithholdingRate,
            WithholdingAmount,
            PeriodCode,
            Status,
            CountryCode,
            CreatedBy,
            CreatedAt
        )
        VALUES
        (
            @CompanyId,
            @VoucherNumber,
            SYSUTCDATETIME(),
            @WithholdingType,
            @ThirdPartyId,
            @ThirdPartyName,
            @DocNumDoc,
            @DocFecha,
            @TaxableBase,
            @Rate,
            @WithholdingAmount,
            @PeriodCode,
            'GENERATED',
            @CountryCode,
            @CodUsuario,
            SYSUTCDATETIME()
        );

        SET @VoucherId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Comprobante generado: ' + @VoucherNumber
                       + N', Monto retenido: ' + CAST(@WithholdingAmount AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = 0;
        SET @VoucherId = 0;
        SET @Mensaje   = N'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
-- 10. usp_Fiscal_Withholding_List
--     Listado paginado de comprobantes de retencion.
--     Filtros opcionales por tipo, periodo y pais.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Withholding_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Withholding_List;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Withholding_List
    @CompanyId       INT,
    @WithholdingType NVARCHAR(20) = NULL,
    @PeriodCode      NVARCHAR(7)  = NULL,
    @CountryCode     NVARCHAR(2)  = NULL,
    @Page            INT          = 1,
    @Limit           INT          = 50,
    @TotalCount      INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500  SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM fiscal.WithholdingVoucher
    WHERE CompanyId = @CompanyId
      AND (@WithholdingType IS NULL OR WithholdingType = @WithholdingType)
      AND (@PeriodCode      IS NULL OR PeriodCode      = @PeriodCode)
      AND (@CountryCode     IS NULL OR CountryCode     = @CountryCode);

    -- Retornar pagina solicitada
    SELECT
        VoucherId,
        CompanyId,
        VoucherNumber,
        VoucherDate,
        WithholdingType,
        ThirdPartyId,
        ThirdPartyName,
        DocumentNumber,
        DocumentDate,
        TaxableBase,
        WithholdingRate,
        WithholdingAmount,
        PeriodCode,
        Status,
        CountryCode,
        JournalEntryId,
        CreatedBy,
        CreatedAt
    FROM fiscal.WithholdingVoucher
    WHERE CompanyId = @CompanyId
      AND (@WithholdingType IS NULL OR WithholdingType = @WithholdingType)
      AND (@PeriodCode      IS NULL OR PeriodCode      = @PeriodCode)
      AND (@CountryCode     IS NULL OR CountryCode     = @CountryCode)
    ORDER BY VoucherDate DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 11. usp_Fiscal_Withholding_Get
--     Obtiene el detalle completo de un comprobante de retencion por su ID.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Withholding_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Withholding_Get;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Withholding_Get
    @CompanyId INT,
    @VoucherId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        VoucherId,
        CompanyId,
        VoucherNumber,
        VoucherDate,
        WithholdingType,
        ThirdPartyId,
        ThirdPartyName,
        DocumentNumber,
        DocumentDate,
        TaxableBase,
        WithholdingRate,
        WithholdingAmount,
        PeriodCode,
        Status,
        CountryCode,
        JournalEntryId,
        CreatedBy,
        CreatedAt
    FROM fiscal.WithholdingVoucher
    WHERE CompanyId = @CompanyId
      AND VoucherId = @VoucherId;
END;
GO

-- =============================================================================
-- 12. usp_Fiscal_Export_TaxBook
--     Exporta todas las entradas del libro fiscal para un periodo dado.
--     Retorna todas las columnas ordenadas para generacion de archivo/reporte.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Export_TaxBook', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Export_TaxBook;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Export_TaxBook
    @CompanyId   INT,
    @BookType    NVARCHAR(10),
    @PeriodCode  NVARCHAR(7),
    @CountryCode NVARCHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        EntryId,
        CompanyId,
        BookType,
        PeriodCode,
        EntryDate,
        DocumentNumber,
        DocumentType,
        ControlNumber,
        ThirdPartyId,
        ThirdPartyName,
        TaxableBase,
        ExemptAmount,
        TaxRate,
        TaxAmount,
        WithholdingRate,
        WithholdingAmount,
        TotalAmount,
        SourceDocumentId,
        SourceModule,
        CountryCode,
        DeclarationId,
        CreatedAt
    FROM fiscal.TaxBookEntry
    WHERE CompanyId   = @CompanyId
      AND BookType    = @BookType
      AND PeriodCode  = @PeriodCode
      AND CountryCode = @CountryCode
    ORDER BY EntryDate, DocumentNumber;
END;
GO

-- =============================================================================
-- 13. usp_Fiscal_Export_Declaration
--     Exporta el detalle completo de una declaracion para presentacion o archivo.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Fiscal_Export_Declaration', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Fiscal_Export_Declaration;
GO
CREATE PROCEDURE dbo.usp_Fiscal_Export_Declaration
    @CompanyId     INT,
    @DeclarationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DeclarationId,
        CompanyId,
        BranchId,
        CountryCode,
        DeclarationType,
        PeriodCode,
        PeriodStart,
        PeriodEnd,
        SalesBase,
        SalesTax,
        PurchasesBase,
        PurchasesTax,
        TaxableBase,
        TaxAmount,
        WithholdingsCredit,
        PreviousBalance,
        NetPayable,
        Status,
        SubmittedAt,
        SubmittedFile,
        AuthorityResponse,
        PaidAt,
        PaymentReference,
        JournalEntryId,
        Notes,
        CreatedBy,
        UpdatedBy,
        CreatedAt,
        UpdatedAt
    FROM fiscal.TaxDeclaration
    WHERE CompanyId     = @CompanyId
      AND DeclarationId = @DeclarationId;
END;
GO
