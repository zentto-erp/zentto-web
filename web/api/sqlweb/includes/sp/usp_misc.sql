USE DatqBoxWeb;
GO

/* ============================================================================
 *  usp_misc.sql
 *  ---------------------------------------------------------------------------
 *  Stored Procedures miscelaneos para modulos CxC, CxP, Nomina
 *  y Conceptos Legales de Nomina.
 *
 *  Convenciones de nombre:
 *    - CxC  : usp_AR_Receivable_*, usp_AR_Balance_*
 *    - CxP  : usp_AP_Payable_*, usp_AP_Balance_*
 *    - Nomina: usp_HR_Payroll_*, usp_HR_LegalConcept_*
 *
 *  Patron: CREATE OR ALTER (idempotente)
 * ============================================================================ */


-- =============================================================================
--  SECCION 1: CUENTAS POR COBRAR (AR - Accounts Receivable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_ApplyPayment
--  Aplica un cobro transaccional a documentos CxC de un cliente.
--  Recibe la lista de documentos como JSON.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_ApplyPayment
    @CodCliente      NVARCHAR(24),
    @Fecha           DATE             = NULL,
    @RequestId       NVARCHAR(120)    = NULL,
    @NumRecibo       NVARCHAR(120),
    @DocumentosJson  NVARCHAR(MAX),
    @Resultado       INT              OUTPUT,
    @Mensaje         NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CustomerId BIGINT;
    DECLARE @ApplyDate  DATE = COALESCE(@Fecha, CAST(GETDATE() AS DATE));
    DECLARE @Applied    DECIMAL(18,2) = 0;

    -- Resolver cliente
    SELECT TOP 1 @CustomerId = CustomerId
    FROM [master].Customer
    WHERE CustomerCode = @CodCliente
      AND IsDeleted = 0;

    IF @CustomerId IS NULL OR @CustomerId <= 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Cliente no encontrado en esquema canonico';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Tabla temporal para documentos
        DECLARE @Docs TABLE (
            TipoDoc       NVARCHAR(20),
            NumDoc        NVARCHAR(120),
            MontoAplicar  DECIMAL(18,2)
        );

        INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
        SELECT
            JSON_VALUE(j.[value], '$.tipoDoc'),
            JSON_VALUE(j.[value], '$.numDoc'),
            CAST(JSON_VALUE(j.[value], '$.montoAplicar') AS DECIMAL(18,2))
        FROM OPENJSON(@DocumentosJson) j;

        -- Cursor por cada documento
        DECLARE @TipoDoc NVARCHAR(20), @NumDoc NVARCHAR(120), @MontoAplicar DECIMAL(18,2);
        DECLARE @DocId BIGINT, @Pending DECIMAL(18,2), @ApplyAmount DECIMAL(18,2);

        DECLARE doc_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT TipoDoc, NumDoc, MontoAplicar FROM @Docs;

        OPEN doc_cursor;
        FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Buscar documento con lock
            SELECT TOP 1
                @DocId   = ReceivableDocumentId,
                @Pending = PendingAmount
            FROM ar.ReceivableDocument WITH (UPDLOCK, ROWLOCK)
            WHERE CustomerId    = @CustomerId
              AND DocumentType  = @TipoDoc
              AND DocumentNumber = @NumDoc
              AND Status <> 'VOIDED'
            ORDER BY ReceivableDocumentId DESC;

            SET @ApplyAmount = CASE
                WHEN @Pending IS NULL THEN 0
                WHEN @MontoAplicar < @Pending THEN @MontoAplicar
                ELSE @Pending
            END;

            IF @ApplyAmount > 0 AND @DocId IS NOT NULL
            BEGIN
                -- Insertar aplicacion
                INSERT INTO ar.ReceivableApplication (
                    ReceivableDocumentId, ApplyDate, AppliedAmount, PaymentReference
                )
                VALUES (
                    @DocId, @ApplyDate, @ApplyAmount,
                    CONCAT(@RequestId, N':', @NumRecibo)
                );

                -- Actualizar documento
                UPDATE ar.ReceivableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @ApplyAmount < 0 THEN 0
                                         ELSE PendingAmount - @ApplyAmount END,
                    PaidFlag = CASE WHEN PendingAmount - @ApplyAmount <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                               WHEN PendingAmount - @ApplyAmount <= 0 THEN 'PAID'
                               WHEN PendingAmount - @ApplyAmount < TotalAmount THEN 'PARTIAL'
                               ELSE 'PENDING'
                             END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE ReceivableDocumentId = @DocId;

                SET @Applied = @Applied + @ApplyAmount;
            END;

            SET @DocId = NULL;
            SET @Pending = NULL;

            FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;
        END;

        CLOSE doc_cursor;
        DEALLOCATE doc_cursor;

        IF @Applied <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Resultado = -2;
            SET @Mensaje = N'No hay montos aplicables para cobrar';
            RETURN;
        END;

        -- Recalcular saldo del cliente
        UPDATE [master].Customer
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ar.ReceivableDocument
                WHERE CustomerId = @CustomerId
                  AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CustomerId = @CustomerId;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = N'Cobro aplicado en esquema canonico';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error aplicando cobro canonico: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_List
--  Lista paginada de documentos CxC.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_List
    @CodCliente   NVARCHAR(24)   = NULL,
    @TipoDoc      NVARCHAR(20)   = NULL,
    @Estado       NVARCHAR(20)   = NULL,
    @FechaDesde   DATE           = NULL,
    @FechaHasta   DATE           = NULL,
    @Offset       INT            = 0,
    @Limit        INT            = 50,
    @TotalCount   INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE (@CodCliente IS NULL OR c.CustomerCode = @CodCliente)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@Estado IS NULL OR d.Status = @Estado)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta);

    SELECT
        c.CustomerCode   AS codCliente,
        d.DocumentType   AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate      AS fecha,
        d.TotalAmount    AS total,
        d.PendingAmount  AS pendiente,
        d.Status         AS estado,
        d.Notes          AS observacion
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE (@CodCliente IS NULL OR c.CustomerCode = @CodCliente)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@Estado IS NULL OR d.Status = @Estado)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
    ORDER BY d.IssueDate DESC, d.ReceivableDocumentId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_GetPending
--  Obtiene documentos pendientes de un cliente.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_GetPending
    @CodCliente  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.DocumentType   AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate      AS fecha,
        d.PendingAmount  AS pendiente,
        d.TotalAmount    AS total
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE c.CustomerCode = @CodCliente
      AND d.PendingAmount > 0
      AND d.Status IN ('PENDING', 'PARTIAL')
    ORDER BY d.IssueDate ASC, d.ReceivableDocumentId ASC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Balance_GetByCustomer
--  Obtiene saldo de un cliente.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Balance_GetByCustomer
    @CodCliente  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(c.TotalBalance, 0)    AS saldoTotal,
        CAST(0 AS DECIMAL(18,2))     AS saldo30,
        CAST(0 AS DECIMAL(18,2))     AS saldo60,
        CAST(0 AS DECIMAL(18,2))     AS saldo90,
        CAST(0 AS DECIMAL(18,2))     AS saldo91
    FROM [master].Customer c
    WHERE c.CustomerCode = @CodCliente
      AND c.IsDeleted = 0;
END;
GO


-- =============================================================================
--  SECCION 2: CUENTAS POR PAGAR (AP - Accounts Payable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_ApplyPayment
--  Aplica un pago transaccional a documentos CxP de un proveedor.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_ApplyPayment
    @CodProveedor    NVARCHAR(24),
    @Fecha           DATE             = NULL,
    @RequestId       NVARCHAR(120)    = NULL,
    @NumPago         NVARCHAR(120),
    @DocumentosJson  NVARCHAR(MAX),
    @Resultado       INT              OUTPUT,
    @Mensaje         NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SupplierId BIGINT;
    DECLARE @ApplyDate  DATE = COALESCE(@Fecha, CAST(GETDATE() AS DATE));
    DECLARE @Applied    DECIMAL(18,2) = 0;

    -- Resolver proveedor
    SELECT TOP 1 @SupplierId = SupplierId
    FROM [master].Supplier
    WHERE SupplierCode = @CodProveedor
      AND IsDeleted = 0;

    IF @SupplierId IS NULL OR @SupplierId <= 0
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Proveedor no encontrado en esquema canonico';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Docs TABLE (
            TipoDoc       NVARCHAR(20),
            NumDoc        NVARCHAR(120),
            MontoAplicar  DECIMAL(18,2)
        );

        INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
        SELECT
            JSON_VALUE(j.[value], '$.tipoDoc'),
            JSON_VALUE(j.[value], '$.numDoc'),
            CAST(JSON_VALUE(j.[value], '$.montoAplicar') AS DECIMAL(18,2))
        FROM OPENJSON(@DocumentosJson) j;

        DECLARE @TipoDoc NVARCHAR(20), @NumDoc NVARCHAR(120), @MontoAplicar DECIMAL(18,2);
        DECLARE @DocId BIGINT, @Pending DECIMAL(18,2), @ApplyAmount DECIMAL(18,2);

        DECLARE doc_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT TipoDoc, NumDoc, MontoAplicar FROM @Docs;

        OPEN doc_cursor;
        FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT TOP 1
                @DocId   = PayableDocumentId,
                @Pending = PendingAmount
            FROM ap.PayableDocument WITH (UPDLOCK, ROWLOCK)
            WHERE SupplierId     = @SupplierId
              AND DocumentType   = @TipoDoc
              AND DocumentNumber = @NumDoc
              AND Status <> 'VOIDED'
            ORDER BY PayableDocumentId DESC;

            SET @ApplyAmount = CASE
                WHEN @Pending IS NULL THEN 0
                WHEN @MontoAplicar < @Pending THEN @MontoAplicar
                ELSE @Pending
            END;

            IF @ApplyAmount > 0 AND @DocId IS NOT NULL
            BEGIN
                INSERT INTO ap.PayableApplication (
                    PayableDocumentId, ApplyDate, AppliedAmount, PaymentReference
                )
                VALUES (
                    @DocId, @ApplyDate, @ApplyAmount,
                    CONCAT(@RequestId, N':', @NumPago)
                );

                UPDATE ap.PayableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @ApplyAmount < 0 THEN 0
                                         ELSE PendingAmount - @ApplyAmount END,
                    PaidFlag = CASE WHEN PendingAmount - @ApplyAmount <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                               WHEN PendingAmount - @ApplyAmount <= 0 THEN 'PAID'
                               WHEN PendingAmount - @ApplyAmount < TotalAmount THEN 'PARTIAL'
                               ELSE 'PENDING'
                             END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE PayableDocumentId = @DocId;

                SET @Applied = @Applied + @ApplyAmount;
            END;

            SET @DocId = NULL;
            SET @Pending = NULL;

            FETCH NEXT FROM doc_cursor INTO @TipoDoc, @NumDoc, @MontoAplicar;
        END;

        CLOSE doc_cursor;
        DEALLOCATE doc_cursor;

        IF @Applied <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Resultado = -2;
            SET @Mensaje = N'No hay montos aplicables para pagar';
            RETURN;
        END;

        UPDATE [master].Supplier
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ap.PayableDocument
                WHERE SupplierId = @SupplierId
                  AND Status <> 'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE SupplierId = @SupplierId;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = N'Pago aplicado en esquema canonico';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error aplicando pago canonico: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_List
--  Lista paginada de documentos CxP.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_List
    @CodProveedor  NVARCHAR(24)   = NULL,
    @TipoDoc       NVARCHAR(20)   = NULL,
    @Estado        NVARCHAR(20)   = NULL,
    @FechaDesde    DATE           = NULL,
    @FechaHasta    DATE           = NULL,
    @Offset        INT            = 0,
    @Limit         INT            = 50,
    @TotalCount    INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE (@CodProveedor IS NULL OR s.SupplierCode = @CodProveedor)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@Estado IS NULL OR d.Status = @Estado)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta);

    SELECT
        s.SupplierCode   AS codProveedor,
        d.DocumentType   AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate      AS fecha,
        d.TotalAmount    AS total,
        d.PendingAmount  AS pendiente,
        d.Status         AS estado,
        d.Notes          AS observacion
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE (@CodProveedor IS NULL OR s.SupplierCode = @CodProveedor)
      AND (@TipoDoc IS NULL OR d.DocumentType = @TipoDoc)
      AND (@Estado IS NULL OR d.Status = @Estado)
      AND (@FechaDesde IS NULL OR d.IssueDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR d.IssueDate <= @FechaHasta)
    ORDER BY d.IssueDate DESC, d.PayableDocumentId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_GetPending
--  Obtiene documentos pendientes de un proveedor.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_GetPending
    @CodProveedor  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.DocumentType   AS tipoDoc,
        d.DocumentNumber AS numDoc,
        d.IssueDate      AS fecha,
        d.PendingAmount  AS pendiente,
        d.TotalAmount    AS total
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE s.SupplierCode = @CodProveedor
      AND d.PendingAmount > 0
      AND d.Status IN ('PENDING', 'PARTIAL')
    ORDER BY d.IssueDate ASC, d.PayableDocumentId ASC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Balance_GetBySupplier
--  Obtiene saldo de un proveedor.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Balance_GetBySupplier
    @CodProveedor  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(s.TotalBalance, 0)    AS saldoTotal,
        CAST(0 AS DECIMAL(18,2))     AS saldo30,
        CAST(0 AS DECIMAL(18,2))     AS saldo60,
        CAST(0 AS DECIMAL(18,2))     AS saldo90,
        CAST(0 AS DECIMAL(18,2))     AS saldo91
    FROM [master].Supplier s
    WHERE s.SupplierCode = @CodProveedor
      AND s.IsDeleted = 0;
END;
GO


-- =============================================================================
--  SECCION 3: CUENTAS POR PAGAR CRUD (cuentas-por-pagar/service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_ListFull
--  Lista paginada de documentos CxP con busqueda y contexto empresa/sucursal.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_ListFull
    @Search       NVARCHAR(200)  = NULL,
    @Codigo       NVARCHAR(24)   = NULL,
    @Offset       INT            = 0,
    @Limit        INT            = 50,
    @TotalCount   INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT;

    -- Resolver contexto
    SELECT TOP 1 @CompanyId = CompanyId
    FROM cfg.Company WHERE IsDeleted = 0
    ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

    SELECT TOP 1 @BranchId = BranchId
    FROM cfg.Branch WHERE CompanyId = @CompanyId AND IsDeleted = 0
    ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId;

    DECLARE @SearchPattern NVARCHAR(202) = CASE WHEN @Search IS NOT NULL THEN N'%' + @Search + N'%' ELSE NULL END;

    SELECT @TotalCount = COUNT(1)
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (d.DocumentNumber LIKE @SearchPattern OR d.Notes LIKE @SearchPattern OR s.SupplierName LIKE @SearchPattern))
      AND (@Codigo IS NULL OR s.SupplierCode = @Codigo);

    SELECT
        d.PayableDocumentId AS id,
        s.SupplierCode      AS codigo,
        s.SupplierName      AS nombre,
        d.DocumentType      AS tipo,
        d.DocumentNumber    AS documento,
        d.IssueDate         AS fecha,
        d.DueDate           AS fechaVence,
        d.TotalAmount       AS total,
        d.PendingAmount     AS pendiente,
        d.Status            AS estado,
        d.CurrencyCode      AS moneda,
        d.Notes             AS observacion
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (d.DocumentNumber LIKE @SearchPattern OR d.Notes LIKE @SearchPattern OR s.SupplierName LIKE @SearchPattern))
      AND (@Codigo IS NULL OR s.SupplierCode = @Codigo)
    ORDER BY d.IssueDate DESC, d.PayableDocumentId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_GetById
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_GetById
    @Id  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.PayableDocumentId AS id,
        s.SupplierCode      AS codigo,
        s.SupplierName      AS nombre,
        d.DocumentType      AS tipo,
        d.DocumentNumber    AS documento,
        d.IssueDate         AS fecha,
        d.DueDate           AS fechaVence,
        d.TotalAmount       AS total,
        d.PendingAmount     AS pendiente,
        d.Status            AS estado,
        d.CurrencyCode      AS moneda,
        d.Notes             AS observacion
    FROM ap.PayableDocument d
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE d.PayableDocumentId = @Id;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_Create
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_Create
    @Codigo         NVARCHAR(24),
    @DocumentType   NVARCHAR(20)    = N'COMPRA',
    @DocumentNumber NVARCHAR(120)   = NULL,
    @IssueDate      DATE            = NULL,
    @DueDate        DATE            = NULL,
    @CurrencyCode   NVARCHAR(10)    = N'USD',
    @TotalAmount    DECIMAL(18,2)   = 0,
    @PendingAmount  DECIMAL(18,2)   = NULL,
    @Notes          NVARCHAR(500)   = NULL,
    @Resultado      INT             OUTPUT,
    @Mensaje        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT, @SupplierId BIGINT;
    DECLARE @Pend DECIMAL(18,2) = COALESCE(@PendingAmount, @TotalAmount);

    SELECT TOP 1 @CompanyId = CompanyId
    FROM cfg.Company WHERE IsDeleted = 0
    ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

    SELECT TOP 1 @BranchId = BranchId
    FROM cfg.Branch WHERE CompanyId = @CompanyId AND IsDeleted = 0
    ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId;

    SELECT TOP 1 @SupplierId = SupplierId
    FROM [master].Supplier
    WHERE CompanyId = @CompanyId AND SupplierCode = @Codigo AND IsDeleted = 0;

    IF @SupplierId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'proveedor_no_encontrado';
        RETURN;
    END;

    INSERT INTO ap.PayableDocument (
        CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber,
        IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount,
        PaidFlag, Status, Notes, CreatedAt, UpdatedAt
    )
    VALUES (
        @CompanyId, @BranchId, @SupplierId, @DocumentType, @DocumentNumber,
        COALESCE(@IssueDate, CAST(GETDATE() AS DATE)),
        COALESCE(@DueDate, @IssueDate, CAST(GETDATE() AS DATE)),
        @CurrencyCode, @TotalAmount, @Pend,
        CASE WHEN @Pend <= 0 THEN 1 ELSE 0 END,
        CASE WHEN @Pend <= 0 THEN 'PAID' WHEN @Pend < @TotalAmount THEN 'PARTIAL' ELSE 'PENDING' END,
        @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_Update
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_Update
    @Id              BIGINT,
    @DocumentType    NVARCHAR(20)    = NULL,
    @DocumentNumber  NVARCHAR(120)   = NULL,
    @IssueDate       DATE            = NULL,
    @DueDate         DATE            = NULL,
    @TotalAmount     DECIMAL(18,2)   = NULL,
    @PendingAmount   DECIMAL(18,2)   = NULL,
    @Status          NVARCHAR(20)    = NULL,
    @CurrencyCode    NVARCHAR(10)    = NULL,
    @Notes           NVARCHAR(500)   = NULL,
    @Resultado       INT             OUTPUT,
    @Mensaje         NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ap.PayableDocument
    SET DocumentType   = COALESCE(@DocumentType, DocumentType),
        DocumentNumber = COALESCE(@DocumentNumber, DocumentNumber),
        IssueDate      = COALESCE(@IssueDate, IssueDate),
        DueDate        = COALESCE(@DueDate, DueDate),
        TotalAmount    = COALESCE(@TotalAmount, TotalAmount),
        PendingAmount  = COALESCE(@PendingAmount, PendingAmount),
        Status         = COALESCE(@Status, Status),
        CurrencyCode   = COALESCE(@CurrencyCode, CurrencyCode),
        Notes          = COALESCE(@Notes, Notes),
        UpdatedAt      = SYSUTCDATETIME()
    WHERE PayableDocumentId = @Id;

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AP_Payable_Void
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AP_Payable_Void
    @Id          BIGINT,
    @Resultado   INT             OUTPUT,
    @Mensaje     NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ap.PayableDocument
    SET PendingAmount = 0,
        PaidFlag      = 1,
        Status        = 'VOIDED',
        UpdatedAt     = SYSUTCDATETIME()
    WHERE PayableDocumentId = @Id;

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO


-- =============================================================================
--  SECCION 4: CUENTAS POR COBRAR CRUD (p-cobrar/service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_ListFull
--  Lista paginada con busqueda, contexto y moneda.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_ListFull
    @Search        NVARCHAR(200)  = NULL,
    @Codigo        NVARCHAR(24)   = NULL,
    @CurrencyCode  NVARCHAR(10)   = NULL,
    @Offset        INT            = 0,
    @Limit         INT            = 50,
    @TotalCount    INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT;

    SELECT TOP 1 @CompanyId = CompanyId
    FROM cfg.Company WHERE IsDeleted = 0
    ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

    SELECT TOP 1 @BranchId = BranchId
    FROM cfg.Branch WHERE CompanyId = @CompanyId AND IsDeleted = 0
    ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId;

    DECLARE @SearchPattern NVARCHAR(202) = CASE WHEN @Search IS NOT NULL THEN N'%' + @Search + N'%' ELSE NULL END;

    SELECT @TotalCount = COUNT(1)
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (d.DocumentNumber LIKE @SearchPattern OR d.Notes LIKE @SearchPattern OR c.CustomerName LIKE @SearchPattern))
      AND (@Codigo IS NULL OR c.CustomerCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode);

    SELECT
        d.ReceivableDocumentId AS id,
        c.CustomerCode         AS codigo,
        c.CustomerName         AS nombre,
        d.DocumentType         AS tipo,
        d.DocumentNumber       AS documento,
        d.IssueDate            AS fecha,
        d.DueDate              AS fechaVence,
        d.TotalAmount          AS total,
        d.PendingAmount        AS pendiente,
        d.Status               AS estado,
        d.CurrencyCode         AS moneda,
        d.Notes                AS observacion
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (d.DocumentNumber LIKE @SearchPattern OR d.Notes LIKE @SearchPattern OR c.CustomerName LIKE @SearchPattern))
      AND (@Codigo IS NULL OR c.CustomerCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode)
    ORDER BY d.IssueDate DESC, d.ReceivableDocumentId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_GetById
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_GetById
    @Id  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.ReceivableDocumentId AS id,
        c.CustomerCode         AS codigo,
        c.CustomerName         AS nombre,
        d.DocumentType         AS tipo,
        d.DocumentNumber       AS documento,
        d.IssueDate            AS fecha,
        d.DueDate              AS fechaVence,
        d.TotalAmount          AS total,
        d.PendingAmount        AS pendiente,
        d.Status               AS estado,
        d.CurrencyCode         AS moneda,
        d.Notes                AS observacion
    FROM ar.ReceivableDocument d
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE d.ReceivableDocumentId = @Id;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_Create
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_Create
    @Codigo         NVARCHAR(24),
    @DocumentType   NVARCHAR(20)    = N'FACT',
    @DocumentNumber NVARCHAR(120)   = NULL,
    @IssueDate      DATE            = NULL,
    @DueDate        DATE            = NULL,
    @CurrencyCode   NVARCHAR(10)    = N'USD',
    @TotalAmount    DECIMAL(18,2)   = 0,
    @PendingAmount  DECIMAL(18,2)   = NULL,
    @Notes          NVARCHAR(500)   = NULL,
    @Resultado      INT             OUTPUT,
    @Mensaje        NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyId INT, @BranchId INT, @CustomerId BIGINT;
    DECLARE @Pend DECIMAL(18,2) = COALESCE(@PendingAmount, @TotalAmount);

    SELECT TOP 1 @CompanyId = CompanyId
    FROM cfg.Company WHERE IsDeleted = 0
    ORDER BY CASE WHEN CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

    SELECT TOP 1 @BranchId = BranchId
    FROM cfg.Branch WHERE CompanyId = @CompanyId AND IsDeleted = 0
    ORDER BY CASE WHEN BranchCode = 'MAIN' THEN 0 ELSE 1 END, BranchId;

    SELECT TOP 1 @CustomerId = CustomerId
    FROM [master].Customer
    WHERE CompanyId = @CompanyId AND CustomerCode = @Codigo AND IsDeleted = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'cliente_no_encontrado';
        RETURN;
    END;

    INSERT INTO ar.ReceivableDocument (
        CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber,
        IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount,
        PaidFlag, Status, Notes, CreatedAt, UpdatedAt
    )
    VALUES (
        @CompanyId, @BranchId, @CustomerId, @DocumentType, @DocumentNumber,
        COALESCE(@IssueDate, CAST(GETDATE() AS DATE)),
        COALESCE(@DueDate, @IssueDate, CAST(GETDATE() AS DATE)),
        @CurrencyCode, @TotalAmount, @Pend,
        CASE WHEN @Pend <= 0 THEN 1 ELSE 0 END,
        CASE WHEN @Pend <= 0 THEN 'PAID' WHEN @Pend < @TotalAmount THEN 'PARTIAL' ELSE 'PENDING' END,
        @Notes, SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_Update
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_Update
    @Id              BIGINT,
    @DocumentType    NVARCHAR(20)    = NULL,
    @DocumentNumber  NVARCHAR(120)   = NULL,
    @IssueDate       DATE            = NULL,
    @DueDate         DATE            = NULL,
    @TotalAmount     DECIMAL(18,2)   = NULL,
    @PendingAmount   DECIMAL(18,2)   = NULL,
    @Status          NVARCHAR(20)    = NULL,
    @CurrencyCode    NVARCHAR(10)    = NULL,
    @Notes           NVARCHAR(500)   = NULL,
    @Resultado       INT             OUTPUT,
    @Mensaje         NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ar.ReceivableDocument
    SET DocumentType   = COALESCE(@DocumentType, DocumentType),
        DocumentNumber = COALESCE(@DocumentNumber, DocumentNumber),
        IssueDate      = COALESCE(@IssueDate, IssueDate),
        DueDate        = COALESCE(@DueDate, DueDate),
        TotalAmount    = COALESCE(@TotalAmount, TotalAmount),
        PendingAmount  = COALESCE(@PendingAmount, PendingAmount),
        Status         = COALESCE(@Status, Status),
        CurrencyCode   = COALESCE(@CurrencyCode, CurrencyCode),
        Notes          = COALESCE(@Notes, Notes),
        UpdatedAt      = SYSUTCDATETIME()
    WHERE ReceivableDocumentId = @Id;

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_AR_Receivable_Void
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AR_Receivable_Void
    @Id          BIGINT,
    @Resultado   INT             OUTPUT,
    @Mensaje     NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ar.ReceivableDocument
    SET PendingAmount = 0,
        PaidFlag      = 1,
        Status        = 'VOIDED',
        UpdatedAt     = SYSUTCDATETIME()
    WHERE ReceivableDocumentId = @Id;

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO


-- =============================================================================
--  SECCION 5: NOMINA (HR - Human Resources)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ResolveScope
--  Resuelve CompanyId, BranchId y UserId del sistema.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ResolveScope
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        c.CompanyId  AS companyId,
        b.BranchId   AS branchId,
        su.UserId    AS systemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
        ON b.CompanyId = c.CompanyId
       AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] su
        ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ResolveUser
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ResolveUser
    @UserCode  NVARCHAR(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @UserCode IS NOT NULL AND LTRIM(RTRIM(@UserCode)) <> N''
    BEGIN
        SELECT TOP 1 UserId AS userId
        FROM sec.[User]
        WHERE UPPER(UserCode) = UPPER(@UserCode)
        ORDER BY UserId;
        RETURN;
    END;

    -- Fallback: usuario SYSTEM
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UserCode = N'SYSTEM'
    ORDER BY UserId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetConstant
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetConstant
    @CompanyId  INT,
    @Code       NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 ConstantValue AS value
    FROM hr.PayrollConstant
    WHERE CompanyId = @CompanyId
      AND ConstantCode = @Code
      AND IsActive = 1
    ORDER BY PayrollConstantId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_EnsureType
--  Crea el PayrollType si no existe.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_EnsureType
    @CompanyId    INT,
    @PayrollCode  NVARCHAR(15),
    @UserId       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM hr.PayrollType
        WHERE CompanyId = @CompanyId AND PayrollCode = @PayrollCode
    )
    BEGIN
        INSERT INTO hr.PayrollType (CompanyId, PayrollCode, PayrollName, IsActive, CreatedByUserId, UpdatedByUserId)
        VALUES (@CompanyId, @PayrollCode, N'Nomina ' + @PayrollCode, 1, @UserId, @UserId);
    END;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_EnsureEmployee
--  Busca o crea un empleado por cedula/codigo.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_EnsureEmployee
    @CompanyId  INT,
    @Document   NVARCHAR(24),
    @UserId     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Buscar existente
    IF EXISTS (
        SELECT 1 FROM [master].Employee
        WHERE CompanyId = @CompanyId AND IsDeleted = 0
          AND (EmployeeCode = @Document OR FiscalId = @Document)
    )
    BEGIN
        SELECT TOP 1
            EmployeeId   AS employeeId,
            EmployeeCode AS employeeCode,
            EmployeeName AS employeeName,
            HireDate     AS hireDate
        FROM [master].Employee
        WHERE CompanyId = @CompanyId AND IsDeleted = 0
          AND (EmployeeCode = @Document OR FiscalId = @Document)
        ORDER BY EmployeeId;
        RETURN;
    END;

    -- Crear nuevo
    INSERT INTO [master].Employee (
        CompanyId, EmployeeCode, EmployeeName, FiscalId,
        HireDate, IsActive, CreatedByUserId, UpdatedByUserId
    )
    OUTPUT
        INSERTED.EmployeeId   AS employeeId,
        INSERTED.EmployeeCode AS employeeCode,
        INSERTED.EmployeeName AS employeeName,
        INSERTED.HireDate     AS hireDate
    VALUES (
        @CompanyId, @Document, N'Empleado ' + @Document, @Document,
        CAST(GETDATE() AS DATE), 1, @UserId, @UserId
    );
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListConcepts
--  Lista paginada de conceptos de nomina.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListConcepts
    @CompanyId    INT,
    @PayrollCode  NVARCHAR(15)  = NULL,
    @ConceptType  NVARCHAR(15)  = NULL,
    @Search       NVARCHAR(200) = NULL,
    @Offset       INT           = 0,
    @Limit        INT           = 50,
    @TotalCount   INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SearchPattern NVARCHAR(202) = CASE WHEN @Search IS NOT NULL THEN N'%' + @Search + N'%' ELSE NULL END;

    SELECT @TotalCount = COUNT(1)
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND IsActive = 1
      AND (@PayrollCode IS NULL OR PayrollCode = @PayrollCode)
      AND (@ConceptType IS NULL OR ConceptType = @ConceptType)
      AND (@SearchPattern IS NULL OR (ConceptCode LIKE @SearchPattern OR ConceptName LIKE @SearchPattern));

    SELECT
        ConceptCode          AS codigo,
        PayrollCode          AS codigoNomina,
        ConceptName          AS nombre,
        Formula              AS formula,
        BaseExpression       AS sobre,
        ConceptClass         AS clase,
        ConceptType          AS tipo,
        UsageType            AS uso,
        CASE WHEN IsBonifiable = 1 THEN N'S' ELSE N'N' END AS bonificable,
        CASE WHEN IsSeniority  = 1 THEN N'S' ELSE N'N' END AS esAntiguedad,
        AccountingAccountCode AS cuentaContable,
        CASE WHEN AppliesFlag  = 1 THEN N'S' ELSE N'N' END AS aplica,
        DefaultValue         AS valorDefecto
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND IsActive = 1
      AND (@PayrollCode IS NULL OR PayrollCode = @PayrollCode)
      AND (@ConceptType IS NULL OR ConceptType = @ConceptType)
      AND (@SearchPattern IS NULL OR (ConceptCode LIKE @SearchPattern OR ConceptName LIKE @SearchPattern))
    ORDER BY PayrollCode, SortOrder, ConceptCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_SaveConcept
--  Inserta o actualiza un concepto de nomina.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_SaveConcept
    @CompanyId              INT,
    @PayrollCode            NVARCHAR(15),
    @ConceptCode            NVARCHAR(20),
    @ConceptName            NVARCHAR(120),
    @Formula                NVARCHAR(500)  = NULL,
    @BaseExpression         NVARCHAR(200)  = NULL,
    @ConceptClass           NVARCHAR(30)   = NULL,
    @ConceptType            NVARCHAR(15)   = N'ASIGNACION',
    @UsageType              NVARCHAR(30)   = NULL,
    @IsBonifiable           BIT            = 0,
    @IsSeniority            BIT            = 0,
    @AccountingAccountCode  NVARCHAR(50)   = NULL,
    @AppliesFlag            BIT            = 1,
    @DefaultValue           DECIMAL(18,4)  = 0,
    @UserId                 INT            = NULL,
    @Resultado              INT            OUTPUT,
    @Mensaje                NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExistingId BIGINT;

    SELECT TOP 1 @ExistingId = PayrollConceptId
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND PayrollCode = @PayrollCode
      AND ConceptCode = @ConceptCode
      AND ConventionCode IS NULL
      AND CalculationType IS NULL
    ORDER BY PayrollConceptId;

    IF @ExistingId IS NOT NULL
    BEGIN
        UPDATE hr.PayrollConcept
        SET ConceptName           = @ConceptName,
            Formula               = @Formula,
            BaseExpression        = @BaseExpression,
            ConceptClass          = @ConceptClass,
            ConceptType           = @ConceptType,
            UsageType             = @UsageType,
            IsBonifiable          = @IsBonifiable,
            IsSeniority           = @IsSeniority,
            AccountingAccountCode = @AccountingAccountCode,
            AppliesFlag           = @AppliesFlag,
            DefaultValue          = @DefaultValue,
            UpdatedAt             = SYSUTCDATETIME(),
            UpdatedByUserId       = @UserId
        WHERE PayrollConceptId = @ExistingId;
    END
    ELSE
    BEGIN
        INSERT INTO hr.PayrollConcept (
            CompanyId, PayrollCode, ConceptCode, ConceptName,
            Formula, BaseExpression, ConceptClass, ConceptType,
            UsageType, IsBonifiable, IsSeniority, AccountingAccountCode,
            AppliesFlag, DefaultValue, ConventionCode, CalculationType,
            SortOrder, IsActive, CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @PayrollCode, @ConceptCode, @ConceptName,
            @Formula, @BaseExpression, @ConceptClass, @ConceptType,
            @UsageType, @IsBonifiable, @IsSeniority, @AccountingAccountCode,
            @AppliesFlag, @DefaultValue, NULL, NULL,
            0, 1, @UserId, @UserId
        );
    END;

    SET @Resultado = 1;
    SET @Mensaje = N'Concepto guardado';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_LoadConceptsForRun
--  Carga conceptos activos para un run de nomina.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_LoadConceptsForRun
    @CompanyId        INT,
    @PayrollCode      NVARCHAR(15),
    @ConceptType      NVARCHAR(15)  = NULL,
    @ConventionCode   NVARCHAR(30)  = NULL,
    @CalculationType  NVARCHAR(30)  = NULL,
    @SoloLegales      BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConceptCode              AS conceptCode,
        ConceptName              AS conceptName,
        ConceptType              AS conceptType,
        DefaultValue             AS defaultValue,
        Formula                  AS formula,
        AccountingAccountCode    AS accountingAccountCode
    FROM hr.PayrollConcept
    WHERE CompanyId   = @CompanyId
      AND PayrollCode = @PayrollCode
      AND IsActive    = 1
      AND AppliesFlag = 1
      AND (@ConceptType IS NULL OR ConceptType = @ConceptType)
      AND (
            (@SoloLegales = 1 AND (
                (@ConventionCode IS NOT NULL AND ConventionCode = @ConventionCode)
                OR
                (@ConventionCode IS NULL AND ConventionCode IS NOT NULL)
            ))
            OR
            (@SoloLegales = 0 AND (
                (@ConventionCode IS NOT NULL AND (ConventionCode = @ConventionCode OR ConventionCode IS NULL))
                OR
                (@ConventionCode IS NULL)
            ))
          )
      AND (@CalculationType IS NULL OR CalculationType = @CalculationType OR CalculationType IS NULL)
    ORDER BY SortOrder, ConceptCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_UpsertRun
--  Inserta o actualiza un PayrollRun con sus lineas (JSON).
--  Las lineas se pasan como JSON para evitar multiples round-trips.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_UpsertRun
    @CompanyId         INT,
    @BranchId          INT,
    @PayrollCode       NVARCHAR(15),
    @EmployeeId        BIGINT,
    @EmployeeCode      NVARCHAR(24),
    @EmployeeName      NVARCHAR(200),
    @FromDate          DATE,
    @ToDate            DATE,
    @TotalAssignments  DECIMAL(18,2),
    @TotalDeductions   DECIMAL(18,2),
    @NetTotal          DECIMAL(18,2),
    @PayrollTypeName   NVARCHAR(50)  = NULL,
    @UserId            INT           = NULL,
    @LinesJson         NVARCHAR(MAX) = NULL,
    @Resultado         INT           OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunId BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Buscar run existente
        SELECT TOP 1 @RunId = PayrollRunId
        FROM hr.PayrollRun
        WHERE CompanyId    = @CompanyId
          AND BranchId     = @BranchId
          AND PayrollCode  = @PayrollCode
          AND EmployeeCode = @EmployeeCode
          AND DateFrom     = @FromDate
          AND DateTo       = @ToDate
          AND RunSource    = N'MANUAL'
        ORDER BY PayrollRunId DESC;

        IF @RunId IS NOT NULL
        BEGIN
            UPDATE hr.PayrollRun
            SET ProcessDate      = CAST(GETDATE() AS DATE),
                TotalAssignments = @TotalAssignments,
                TotalDeductions  = @TotalDeductions,
                NetTotal         = @NetTotal,
                PayrollTypeName  = COALESCE(@PayrollTypeName, PayrollTypeName),
                UpdatedAt        = SYSUTCDATETIME(),
                UpdatedByUserId  = @UserId
            WHERE PayrollRunId = @RunId;

            DELETE FROM hr.PayrollRunLine WHERE PayrollRunId = @RunId;
        END
        ELSE
        BEGIN
            INSERT INTO hr.PayrollRun (
                CompanyId, BranchId, PayrollCode, EmployeeId, EmployeeCode,
                EmployeeName, PositionName, ProcessDate, DateFrom, DateTo,
                TotalAssignments, TotalDeductions, NetTotal, PayrollTypeName,
                RunSource, CreatedByUserId, UpdatedByUserId
            )
            VALUES (
                @CompanyId, @BranchId, @PayrollCode, @EmployeeId, @EmployeeCode,
                @EmployeeName, NULL, CAST(GETDATE() AS DATE), @FromDate, @ToDate,
                @TotalAssignments, @TotalDeductions, @NetTotal, @PayrollTypeName,
                N'MANUAL', @UserId, @UserId
            );

            SET @RunId = SCOPE_IDENTITY();
        END;

        -- Insertar lineas desde JSON
        IF @LinesJson IS NOT NULL AND LEN(@LinesJson) > 2
        BEGIN
            INSERT INTO hr.PayrollRunLine (
                PayrollRunId, ConceptCode, ConceptName, ConceptType,
                Quantity, Amount, Total, DescriptionText, AccountingAccountCode
            )
            SELECT
                @RunId,
                JSON_VALUE(j.[value], '$.code'),
                JSON_VALUE(j.[value], '$.name'),
                JSON_VALUE(j.[value], '$.type'),
                CAST(JSON_VALUE(j.[value], '$.quantity') AS DECIMAL(18,4)),
                CAST(JSON_VALUE(j.[value], '$.amount') AS DECIMAL(18,4)),
                CAST(JSON_VALUE(j.[value], '$.total') AS DECIMAL(18,2)),
                JSON_VALUE(j.[value], '$.description'),
                JSON_VALUE(j.[value], '$.account')
            FROM OPENJSON(@LinesJson) j;
        END;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje = N'ok';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @Resultado = -99;
        SET @Mensaje = N'Error en upsert run: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListActiveEmployees
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListActiveEmployees
    @CompanyId    INT,
    @SoloActivos  BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EmployeeCode AS employeeCode
    FROM [master].Employee
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND (@SoloActivos = 0 OR IsActive = 1)
    ORDER BY EmployeeCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListRuns
--  Lista paginada de runs de nomina.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListRuns
    @CompanyId      INT,
    @PayrollCode    NVARCHAR(15)  = NULL,
    @EmployeeCode   NVARCHAR(24)  = NULL,
    @FromDate       DATE          = NULL,
    @ToDate         DATE          = NULL,
    @SoloAbiertas   BIT           = 0,
    @Offset         INT           = 0,
    @Limit          INT           = 50,
    @TotalCount     INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM hr.PayrollRun
    WHERE CompanyId = @CompanyId
      AND (@PayrollCode IS NULL OR PayrollCode = @PayrollCode)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate IS NULL OR DateFrom >= @FromDate)
      AND (@ToDate IS NULL OR DateTo <= @ToDate)
      AND (@SoloAbiertas = 0 OR IsClosed = 0);

    SELECT
        PayrollCode       AS nomina,
        EmployeeCode      AS cedula,
        EmployeeName      AS nombreEmpleado,
        PositionName      AS cargo,
        ProcessDate       AS fechaProceso,
        DateFrom          AS fechaInicio,
        DateTo            AS fechaHasta,
        TotalAssignments  AS totalAsignaciones,
        TotalDeductions   AS totalDeducciones,
        NetTotal          AS totalNeto,
        IsClosed          AS cerrada,
        PayrollTypeName   AS tipoNomina
    FROM hr.PayrollRun
    WHERE CompanyId = @CompanyId
      AND (@PayrollCode IS NULL OR PayrollCode = @PayrollCode)
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
      AND (@FromDate IS NULL OR DateFrom >= @FromDate)
      AND (@ToDate IS NULL OR DateTo <= @ToDate)
      AND (@SoloAbiertas = 0 OR IsClosed = 0)
    ORDER BY ProcessDate DESC, PayrollRunId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetRun
--  Obtiene un run con su detalle.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetRun
    @CompanyId     INT,
    @PayrollCode   NVARCHAR(15),
    @EmployeeCode  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RunId BIGINT;

    SELECT TOP 1 @RunId = PayrollRunId
    FROM hr.PayrollRun
    WHERE CompanyId    = @CompanyId
      AND PayrollCode  = @PayrollCode
      AND EmployeeCode = @EmployeeCode
    ORDER BY ProcessDate DESC, PayrollRunId DESC;

    -- Resultado 1: cabecera
    SELECT
        PayrollRunId      AS runId,
        PayrollCode       AS nomina,
        EmployeeCode      AS cedula,
        EmployeeName      AS nombreEmpleado,
        PositionName      AS cargo,
        ProcessDate       AS fechaProceso,
        DateFrom          AS fechaInicio,
        DateTo            AS fechaHasta,
        TotalAssignments  AS totalAsignaciones,
        TotalDeductions   AS totalDeducciones,
        NetTotal          AS totalNeto,
        IsClosed          AS cerrada,
        PayrollTypeName   AS tipoNomina
    FROM hr.PayrollRun
    WHERE PayrollRunId = @RunId;

    -- Resultado 2: detalle
    SELECT
        ConceptCode              AS coConcepto,
        ConceptName              AS nombreConcepto,
        ConceptType              AS tipoConcepto,
        Quantity                 AS cantidad,
        Amount                   AS monto,
        Total                    AS total,
        DescriptionText          AS descripcion,
        AccountingAccountCode    AS cuentaContable
    FROM hr.PayrollRunLine
    WHERE PayrollRunId = @RunId
    ORDER BY PayrollRunLineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_CloseRun
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_CloseRun
    @CompanyId     INT,
    @PayrollCode   NVARCHAR(15),
    @EmployeeCode  NVARCHAR(24)  = NULL,
    @UserId        INT           = NULL,
    @Resultado     INT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE hr.PayrollRun
    SET IsClosed        = 1,
        ClosedAt        = SYSUTCDATETIME(),
        ClosedByUserId  = @UserId,
        UpdatedAt       = SYSUTCDATETIME(),
        UpdatedByUserId = @UserId
    WHERE CompanyId   = @CompanyId
      AND PayrollCode = @PayrollCode
      AND IsClosed    = 0
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode);

    DECLARE @Affected INT = @@ROWCOUNT;

    IF @Affected > 0
    BEGIN
        SET @Resultado = @Affected;
        SET @Mensaje = N'Nomina cerrada';
    END
    ELSE
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'No se encontraron registros abiertos';
    END;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_UpsertVacation
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_UpsertVacation
    @CompanyId       INT,
    @BranchId        INT,
    @VacationCode    NVARCHAR(60),
    @EmployeeId      BIGINT,
    @EmployeeCode    NVARCHAR(24),
    @EmployeeName    NVARCHAR(200),
    @StartDate       DATE,
    @EndDate         DATE,
    @ReintegrationDate DATE = NULL,
    @TotalAmount     DECIMAL(18,2),
    @UserId          INT = NULL,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VacationProcessId BIGINT;

    SELECT TOP 1 @VacationProcessId = VacationProcessId
    FROM hr.VacationProcess
    WHERE CompanyId = @CompanyId AND VacationCode = @VacationCode;

    IF @VacationProcessId IS NOT NULL
    BEGIN
        UPDATE hr.VacationProcess
        SET EmployeeId         = @EmployeeId,
            EmployeeCode       = @EmployeeCode,
            EmployeeName       = @EmployeeName,
            StartDate          = @StartDate,
            EndDate            = @EndDate,
            ReintegrationDate  = @ReintegrationDate,
            ProcessDate        = CAST(GETDATE() AS DATE),
            TotalAmount        = @TotalAmount,
            CalculatedAmount   = @TotalAmount,
            UpdatedAt          = SYSUTCDATETIME(),
            UpdatedByUserId    = @UserId
        WHERE VacationProcessId = @VacationProcessId;
    END
    ELSE
    BEGIN
        INSERT INTO hr.VacationProcess (
            CompanyId, BranchId, VacationCode, EmployeeId, EmployeeCode,
            EmployeeName, StartDate, EndDate, ReintegrationDate,
            ProcessDate, TotalAmount, CalculatedAmount,
            CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @VacationCode, @EmployeeId, @EmployeeCode,
            @EmployeeName, @StartDate, @EndDate, @ReintegrationDate,
            CAST(GETDATE() AS DATE), @TotalAmount, @TotalAmount,
            @UserId, @UserId
        );

        SET @VacationProcessId = SCOPE_IDENTITY();
    END;

    -- Reemplazar lineas
    DELETE FROM hr.VacationProcessLine WHERE VacationProcessId = @VacationProcessId;

    INSERT INTO hr.VacationProcessLine (VacationProcessId, ConceptCode, ConceptName, Amount)
    VALUES (@VacationProcessId, N'VACACIONES', N'Pago de vacaciones', @TotalAmount);

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListVacations
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListVacations
    @CompanyId     INT,
    @EmployeeCode  NVARCHAR(24) = NULL,
    @Offset        INT          = 0,
    @Limit         INT          = 50,
    @TotalCount    INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM hr.VacationProcess
    WHERE CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode);

    SELECT
        VacationCode     AS vacacion,
        EmployeeCode     AS cedula,
        EmployeeName     AS nombreEmpleado,
        StartDate        AS inicio,
        EndDate          AS hasta,
        ReintegrationDate AS reintegro,
        ProcessDate      AS fechaCalculo,
        TotalAmount      AS total,
        CalculatedAmount AS totalCalculado
    FROM hr.VacationProcess
    WHERE CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
    ORDER BY VacationProcessId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetVacation
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetVacation
    @CompanyId     INT,
    @VacationCode  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VacationProcessId BIGINT;

    -- Resultado 1: cabecera
    SELECT TOP 1
        @VacationProcessId = VacationProcessId,
        VacationProcessId AS id,
        VacationCode      AS vacacion,
        EmployeeCode      AS cedula,
        EmployeeName      AS nombreEmpleado,
        StartDate         AS inicio,
        EndDate           AS hasta,
        ReintegrationDate AS reintegro,
        ProcessDate       AS fechaCalculo,
        TotalAmount       AS total,
        CalculatedAmount  AS totalCalculado
    FROM hr.VacationProcess
    WHERE CompanyId = @CompanyId AND VacationCode = @VacationCode;

    -- Resultado 2: detalle
    SELECT
        ConceptCode  AS codigo,
        ConceptName  AS nombre,
        Amount       AS monto
    FROM hr.VacationProcessLine
    WHERE VacationProcessId = @VacationProcessId
    ORDER BY VacationProcessLineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_UpsertSettlement
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_UpsertSettlement
    @CompanyId        INT,
    @BranchId         INT,
    @SettlementCode   NVARCHAR(60),
    @EmployeeId       BIGINT,
    @EmployeeCode     NVARCHAR(24),
    @EmployeeName     NVARCHAR(200),
    @RetirementDate   DATE,
    @RetirementCause  NVARCHAR(120) = NULL,
    @TotalAmount      DECIMAL(18,2),
    @Prestaciones     DECIMAL(18,2),
    @VacPendientes    DECIMAL(18,2),
    @BonoSalida       DECIMAL(18,2),
    @UserId           INT           = NULL,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SettlementId BIGINT;

    SELECT TOP 1 @SettlementId = SettlementProcessId
    FROM hr.SettlementProcess
    WHERE CompanyId = @CompanyId AND SettlementCode = @SettlementCode;

    IF @SettlementId IS NOT NULL
    BEGIN
        UPDATE hr.SettlementProcess
        SET EmployeeId      = @EmployeeId,
            EmployeeCode    = @EmployeeCode,
            EmployeeName    = @EmployeeName,
            RetirementDate  = @RetirementDate,
            RetirementCause = @RetirementCause,
            TotalAmount     = @TotalAmount,
            UpdatedAt       = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE SettlementProcessId = @SettlementId;
    END
    ELSE
    BEGIN
        INSERT INTO hr.SettlementProcess (
            CompanyId, BranchId, SettlementCode, EmployeeId, EmployeeCode,
            EmployeeName, RetirementDate, RetirementCause, TotalAmount,
            CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @SettlementCode, @EmployeeId, @EmployeeCode,
            @EmployeeName, @RetirementDate, @RetirementCause, @TotalAmount,
            @UserId, @UserId
        );

        SET @SettlementId = SCOPE_IDENTITY();
    END;

    -- Reemplazar lineas
    DELETE FROM hr.SettlementProcessLine WHERE SettlementProcessId = @SettlementId;

    INSERT INTO hr.SettlementProcessLine (SettlementProcessId, ConceptCode, ConceptName, Amount)
    VALUES
        (@SettlementId, N'PRESTACIONES', N'Prestaciones sociales', @Prestaciones),
        (@SettlementId, N'VACACIONES_PEND', N'Vacaciones pendientes', @VacPendientes),
        (@SettlementId, N'BONO_SALIDA', N'Bono de salida', @BonoSalida);

    SET @Resultado = 1;
    SET @Mensaje = N'ok';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListSettlements
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListSettlements
    @CompanyId     INT,
    @EmployeeCode  NVARCHAR(24) = NULL,
    @Offset        INT          = 0,
    @Limit         INT          = 50,
    @TotalCount    INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM hr.SettlementProcess
    WHERE CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode);

    SELECT
        SettlementCode   AS liquidacion,
        EmployeeCode     AS cedula,
        EmployeeName     AS nombreEmpleado,
        RetirementDate   AS fechaRetiro,
        RetirementCause  AS causaRetiro,
        TotalAmount      AS total
    FROM hr.SettlementProcess
    WHERE CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR EmployeeCode = @EmployeeCode)
    ORDER BY SettlementProcessId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetSettlement
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetSettlement
    @CompanyId       INT,
    @SettlementCode  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SettlementId BIGINT;

    -- Resultado 1: total
    SELECT TOP 1
        @SettlementId = SettlementProcessId,
        SettlementProcessId AS id,
        TotalAmount         AS total
    FROM hr.SettlementProcess
    WHERE CompanyId = @CompanyId AND SettlementCode = @SettlementCode;

    -- Resultado 2: detalle
    SELECT
        ConceptCode  AS codigo,
        ConceptName  AS nombre,
        Amount       AS monto
    FROM hr.SettlementProcessLine
    WHERE SettlementProcessId = @SettlementId
    ORDER BY SettlementProcessLineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_ListConstants
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_ListConstants
    @CompanyId   INT,
    @Offset      INT = 0,
    @Limit       INT = 50,
    @TotalCount  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM hr.PayrollConstant
    WHERE CompanyId = @CompanyId;

    SELECT
        ConstantCode   AS codigo,
        ConstantName   AS nombre,
        ConstantValue  AS valor,
        SourceName     AS origen,
        IsActive       AS activo
    FROM hr.PayrollConstant
    WHERE CompanyId = @CompanyId
    ORDER BY ConstantCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_SaveConstant
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_SaveConstant
    @CompanyId    INT,
    @Code         NVARCHAR(60),
    @Name         NVARCHAR(200)   = NULL,
    @Value        DECIMAL(18,4)   = NULL,
    @SourceName   NVARCHAR(120)   = NULL,
    @UserId       INT             = NULL,
    @Resultado    INT             OUTPUT,
    @Mensaje      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExistingId BIGINT;

    SELECT TOP 1 @ExistingId = PayrollConstantId
    FROM hr.PayrollConstant
    WHERE CompanyId = @CompanyId AND ConstantCode = @Code;

    IF @ExistingId IS NOT NULL
    BEGIN
        UPDATE hr.PayrollConstant
        SET ConstantName  = COALESCE(@Name, ConstantName),
            ConstantValue = COALESCE(@Value, ConstantValue),
            SourceName    = COALESCE(@SourceName, SourceName),
            UpdatedAt     = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE PayrollConstantId = @ExistingId;
    END
    ELSE
    BEGIN
        INSERT INTO hr.PayrollConstant (
            CompanyId, ConstantCode, ConstantName, ConstantValue,
            SourceName, IsActive, CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @Code, COALESCE(@Name, @Code), COALESCE(@Value, 0),
            @SourceName, 1, @UserId, @UserId
        );
    END;

    SET @Resultado = 1;
    SET @Mensaje = N'Constante guardada';
END;
GO


-- =============================================================================
--  SECCION 6: CONCEPTOS LEGALES DE NOMINA
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_HR_LegalConcept_List
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_LegalConcept_List
    @CompanyId       INT,
    @ConventionCode  NVARCHAR(30)  = NULL,
    @CalculationType NVARCHAR(30)  = NULL,
    @ConceptType     NVARCHAR(15)  = NULL,
    @SoloActivos     BIT           = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        PayrollConceptId AS id,
        ConventionCode   AS convencion,
        CalculationType  AS tipoCalculo,
        ConceptCode      AS coConcept,
        ConceptName      AS nbConcepto,
        Formula          AS formula,
        BaseExpression   AS sobre,
        ConceptType      AS tipo,
        CASE WHEN IsBonifiable = 1 THEN N'S' ELSE N'N' END AS bonificable,
        LotttArticle     AS lotttArticulo,
        CcpClause        AS ccpClausula,
        SortOrder        AS orden,
        IsActive         AS activo
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND ConventionCode IS NOT NULL
      AND (@SoloActivos = 0 OR IsActive = 1)
      AND (@ConventionCode IS NULL OR ConventionCode = @ConventionCode)
      AND (@CalculationType IS NULL OR CalculationType = @CalculationType)
      AND (@ConceptType IS NULL OR ConceptType = @ConceptType)
    ORDER BY ConventionCode, CalculationType, SortOrder, ConceptCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_LegalConcept_ValidateFormulas
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_LegalConcept_ValidateFormulas
    @CompanyId       INT,
    @ConventionCode  NVARCHAR(30) = NULL,
    @CalculationType NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConceptCode  AS coConcept,
        ConceptName  AS nbConcepto,
        Formula      AS formula,
        DefaultValue AS defaultValue
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND ConventionCode IS NOT NULL
      AND IsActive = 1
      AND (@ConventionCode IS NULL OR ConventionCode = @ConventionCode)
      AND (@CalculationType IS NULL OR CalculationType = @CalculationType)
    ORDER BY SortOrder, ConceptCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_LegalConcept_ListConventions
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_LegalConcept_ListConventions
    @CompanyId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConventionCode AS Convencion,
        COUNT(1) AS TotalConceptos,
        COUNT(CASE WHEN CalculationType = 'MENSUAL' THEN 1 END)      AS ConceptosMensual,
        COUNT(CASE WHEN CalculationType = 'VACACIONES' THEN 1 END)   AS ConceptosVacaciones,
        COUNT(CASE WHEN CalculationType = 'LIQUIDACION' THEN 1 END)  AS ConceptosLiquidacion,
        MIN(SortOrder) AS OrdenInicio,
        MAX(SortOrder) AS OrdenFin
    FROM hr.PayrollConcept
    WHERE CompanyId = @CompanyId
      AND IsActive = 1
      AND ConventionCode IS NOT NULL
    GROUP BY ConventionCode
    ORDER BY ConventionCode;
END;
GO

-- =============================================================================
--  SECCION 7: SPs auxiliares para detalle (recordset unico)
--  Estos SPs devuelven un solo recordset para evitar problemas con
--  callSp() que solo retorna el primer recordset.
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetRunHeader
--  Obtiene solo la cabecera de un run.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetRunHeader
    @CompanyId     INT,
    @PayrollCode   NVARCHAR(15),
    @EmployeeCode  NVARCHAR(24)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        PayrollRunId      AS runId,
        PayrollCode       AS nomina,
        EmployeeCode      AS cedula,
        EmployeeName      AS nombreEmpleado,
        PositionName      AS cargo,
        ProcessDate       AS fechaProceso,
        DateFrom          AS fechaInicio,
        DateTo            AS fechaHasta,
        TotalAssignments  AS totalAsignaciones,
        TotalDeductions   AS totalDeducciones,
        NetTotal          AS totalNeto,
        IsClosed          AS cerrada,
        PayrollTypeName   AS tipoNomina
    FROM hr.PayrollRun
    WHERE CompanyId    = @CompanyId
      AND PayrollCode  = @PayrollCode
      AND EmployeeCode = @EmployeeCode
    ORDER BY ProcessDate DESC, PayrollRunId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetRunLines
--  Obtiene solo las lineas de un run.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetRunLines
    @RunId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConceptCode              AS coConcepto,
        ConceptName              AS nombreConcepto,
        ConceptType              AS tipoConcepto,
        Quantity                 AS cantidad,
        Amount                   AS monto,
        Total                    AS total,
        DescriptionText          AS descripcion,
        AccountingAccountCode    AS cuentaContable
    FROM hr.PayrollRunLine
    WHERE PayrollRunId = @RunId
    ORDER BY PayrollRunLineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetVacationHeader
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetVacationHeader
    @CompanyId     INT,
    @VacationCode  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        VacationProcessId AS id,
        VacationCode      AS vacacion,
        EmployeeCode      AS cedula,
        EmployeeName      AS nombreEmpleado,
        StartDate         AS inicio,
        EndDate           AS hasta,
        ReintegrationDate AS reintegro,
        ProcessDate       AS fechaCalculo,
        TotalAmount       AS total,
        CalculatedAmount  AS totalCalculado
    FROM hr.VacationProcess
    WHERE CompanyId = @CompanyId AND VacationCode = @VacationCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetVacationLines
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetVacationLines
    @VacationProcessId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConceptCode  AS codigo,
        ConceptName  AS nombre,
        Amount       AS monto
    FROM hr.VacationProcessLine
    WHERE VacationProcessId = @VacationProcessId
    ORDER BY VacationProcessLineId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetSettlementHeader
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetSettlementHeader
    @CompanyId       INT,
    @SettlementCode  NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        SettlementProcessId AS id,
        TotalAmount         AS total
    FROM hr.SettlementProcess
    WHERE CompanyId = @CompanyId AND SettlementCode = @SettlementCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_HR_Payroll_GetSettlementLines
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_HR_Payroll_GetSettlementLines
    @SettlementProcessId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ConceptCode  AS codigo,
        ConceptName  AS nombre,
        Amount       AS monto
    FROM hr.SettlementProcessLine
    WHERE SettlementProcessId = @SettlementProcessId
    ORDER BY SettlementProcessLineId;
END;
GO

PRINT '>> usp_misc.sql: Todos los SPs creados correctamente.';
GO
