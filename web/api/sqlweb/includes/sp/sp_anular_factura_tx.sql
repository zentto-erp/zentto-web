-- =============================================
-- Stored Procedure: Anular Factura (100% canónico)
-- Tablas: ar.SalesDocument, ar.SalesDocumentLine
-- CxC: ar.ReceivableDocument
-- Inventario: master.Product, master.InventoryMovement, master.AlternateStock
-- Clientes: master.Customer
-- Compatible con: SQL Server 2012+
-- =============================================

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_factura_tx')
    DROP PROCEDURE sp_anular_factura_tx
GO

CREATE PROCEDURE sp_anular_factura_tx
    @NumFact NVARCHAR(60),
    @CodUsuario NVARCHAR(60) = 'API',
    @Motivo NVARCHAR(500) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaAnulacion DATETIME = GETDATE();
    DECLARE @CodCliente NVARCHAR(60);
    DECLARE @CustomerId BIGINT;
    DECLARE @YaAnulada BIT;
    DECLARE @DefaultCompanyId INT = 1;
    DECLARE @DefaultBranchId INT = 1;

    SELECT TOP 1 @DefaultCompanyId = CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT';
    SELECT TOP 1 @DefaultBranchId = BranchId FROM cfg.Branch WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN';

    BEGIN TRY
        -- 1. Validar factura en ar.SalesDocument
        SELECT
            @CodCliente = CustomerCode,
            @YaAnulada = CASE WHEN IsVoided = 1 THEN 1 ELSE 0 END
        FROM ar.SalesDocument
        WHERE DocumentNumber = @NumFact AND OperationType = 'FACT' AND IsDeleted = 0;

        IF @CodCliente IS NULL
        BEGIN RAISERROR('factura_not_found', 16, 1); RETURN; END

        IF @YaAnulada = 1
        BEGIN RAISERROR('factura_already_anulled', 16, 1); RETURN; END

        -- Resolver CustomerId
        SELECT TOP 1 @CustomerId = CustomerId FROM master.Customer
         WHERE CustomerCode = @CodCliente AND ISNULL(IsDeleted, 0) = 0;

        BEGIN TRANSACTION;

        -- 2. Marcar anulada → ar.SalesDocument
        UPDATE ar.SalesDocument
        SET IsVoided = 1,
            Notes = ISNULL(Notes, '') + ' [ANULADA: ' + CONVERT(NVARCHAR(20), @FechaAnulacion, 120) + ']',
            UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumFact AND OperationType = 'FACT';

        -- 3. Anular detalle → ar.SalesDocumentLine
        UPDATE ar.SalesDocumentLine
        SET IsVoided = 1, UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumFact AND OperationType = 'FACT';

        -- 4. Revertir inventario
        DECLARE @Detalles TABLE (COD_SERV NVARCHAR(60), CANTIDAD DECIMAL(18,4), RELACIONADA INT, COD_ALTERNO NVARCHAR(60));

        INSERT INTO @Detalles (COD_SERV, CANTIDAD, RELACIONADA, COD_ALTERNO)
        SELECT ProductCode, ISNULL(Quantity, 0),
            CASE WHEN RelatedRef = '1' THEN 1 ELSE 0 END, AlternateCode
        FROM ar.SalesDocumentLine
        WHERE DocumentNumber = @NumFact AND OperationType = 'FACT' AND ISNULL(IsVoided, 0) = 0;

        -- Movimiento de anulación → master.InventoryMovement
        INSERT INTO master.InventoryMovement (CompanyId, ProductCode, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes)
        SELECT @DefaultCompanyId, D.COD_SERV, @NumFact + '_ANUL', 'ENTRADA',
            CAST(@FechaAnulacion AS DATE), D.CANTIDAD,
            ISNULL(I.COSTO_REFERENCIA, 0), D.CANTIDAD * ISNULL(I.COSTO_REFERENCIA, 0),
            'Anulacion Factura:' + @NumFact + ' - ' + @Motivo
        FROM @Detalles D
        INNER JOIN master.Product I ON I.ProductCode = D.COD_SERV
        WHERE D.COD_SERV IS NOT NULL AND D.CANTIDAD > 0;

        -- Sumar de vuelta stock → master.Product
        ;WITH Totales AS (SELECT COD_SERV, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE COD_SERV IS NOT NULL GROUP BY COD_SERV)
        UPDATE I SET StockQty = ISNULL(I.StockQty, 0) + T.TOTAL
        FROM master.Product I INNER JOIN Totales T ON T.COD_SERV = I.ProductCode;

        -- Sumar de vuelta stock auxiliar → master.AlternateStock
        ;WITH AuxTotales AS (SELECT COD_ALTERNO, SUM(CANTIDAD) AS TOTAL FROM @Detalles WHERE RELACIONADA = 1 AND COD_ALTERNO IS NOT NULL GROUP BY COD_ALTERNO)
        UPDATE A SET A.StockQty = ISNULL(A.StockQty, 0) + AT.TOTAL
        FROM master.AlternateStock A INNER JOIN AuxTotales AT ON AT.COD_ALTERNO = A.ProductCode;

        -- 5. Anular CxC → ar.ReceivableDocument
        UPDATE ar.ReceivableDocument
        SET PaidFlag = 1, PendingAmount = 0, Status = 'VOIDED', UpdatedAt = SYSUTCDATETIME()
        WHERE DocumentNumber = @NumFact AND DocumentType = 'FACT'
          AND CompanyId = @DefaultCompanyId AND BranchId = @DefaultBranchId;

        -- 6. Recalcular saldos → master.Customer.TotalBalance
        IF @CustomerId IS NOT NULL
        BEGIN
            UPDATE master.Customer
               SET TotalBalance = ISNULL((
                   SELECT SUM(PendingAmount)
                   FROM ar.ReceivableDocument
                   WHERE CustomerId = @CustomerId AND Status <> 'VOIDED' AND PaidFlag = 0
               ), 0)
             WHERE CustomerId = @CustomerId AND ISNULL(IsDeleted, 0) = 0;
        END

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS ok, @NumFact AS numFact, @CodCliente AS codCliente,
            'Factura anulada exitosamente' AS mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

SELECT name, create_date FROM sys.objects WHERE type = 'P' AND name = 'sp_anular_factura_tx';
