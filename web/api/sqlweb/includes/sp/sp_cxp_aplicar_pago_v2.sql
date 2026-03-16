-- =============================================
-- usp_CxP_AplicarPago v2 (modelo canónico)
-- Esquema: [master].Supplier + ap.PayableDocument/ap.PayableApplication
-- Entrada arrays por XML para compatibilidad con SQL Server 2012
-- =============================================

IF OBJECT_ID(N'dbo.usp_CxP_AplicarPago', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CxP_AplicarPago;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE dbo.usp_CxP_AplicarPago
    @RequestId       NVARCHAR(100),
    @CodProveedor    NVARCHAR(24),
    @Fecha           NVARCHAR(10),
    @MontoTotal      DECIMAL(18,2),
    @CodUsuario      NVARCHAR(40),
    @Observaciones   NVARCHAR(500) = N'',
    @DocumentosXml   NVARCHAR(MAX),
    @FormasPagoXml   NVARCHAR(MAX) = NULL,
    @NumPago         NVARCHAR(50) OUTPUT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NumPago = N'';

    DECLARE @FechaDate DATE = TRY_CONVERT(DATE, @Fecha);
    IF @FechaDate IS NULL
    BEGIN
        SET @Resultado = -91;
        SET @Mensaje = N'Fecha inválida: ' + ISNULL(@Fecha, N'NULL');
        RETURN;
    END

    DECLARE @SupplierId BIGINT;
    SELECT TOP 1 @SupplierId = s.SupplierId
    FROM [master].Supplier s
    WHERE s.SupplierCode = @CodProveedor
      AND s.IsDeleted = 0;

    IF @SupplierId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Proveedor no encontrado: ' + @CodProveedor;
        RETURN;
    END

    DECLARE @DocsXml XML = TRY_CAST(@DocumentosXml AS XML);
    IF @DocsXml IS NULL
    BEGIN
        SET @Resultado = -2;
        SET @Mensaje = N'DocumentosXml inválido';
        RETURN;
    END

    DECLARE @Docs TABLE (
        RowNum INT IDENTITY(1,1) PRIMARY KEY,
        TipoDoc NVARCHAR(20) NOT NULL,
        NumDoc NVARCHAR(120) NOT NULL,
        MontoAplicar DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @Docs (TipoDoc, NumDoc, MontoAplicar)
    SELECT
        UPPER(ISNULL(NULLIF(T.X.value('@tipoDoc', 'NVARCHAR(20)'), N''), N'COMPRA')),
        ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N''),
        ISNULL(TRY_CONVERT(DECIMAL(18,2), NULLIF(T.X.value('@montoAplicar', 'NVARCHAR(40)'), N'')), 0)
    FROM @DocsXml.nodes('/documentos/row') T(X)
    WHERE ISNULL(NULLIF(T.X.value('@numDoc', 'NVARCHAR(120)'), N''), N'') <> N'';

    IF NOT EXISTS (SELECT 1 FROM @Docs)
    BEGIN
        SET @Resultado = -3;
        SET @Mensaje = N'No se recibieron documentos válidos para aplicar';
        RETURN;
    END

    SET @NumPago = N'PAG-' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(19), SYSUTCDATETIME(), 120), N'-', N''), N' ', N''), N':', N'');

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1
            FROM ap.PayableApplication pa
            INNER JOIN ap.PayableDocument pd ON pd.PayableDocumentId = pa.PayableDocumentId
            WHERE pd.SupplierId = @SupplierId
              AND pa.PaymentReference LIKE @RequestId + N':%'
        )
        BEGIN
            SELECT TOP 1 @NumPago = SUBSTRING(pa.PaymentReference, CHARINDEX(N':', pa.PaymentReference) + 1, 50)
            FROM ap.PayableApplication pa
            INNER JOIN ap.PayableDocument pd ON pd.PayableDocumentId = pa.PayableDocumentId
            WHERE pd.SupplierId = @SupplierId
              AND pa.PaymentReference LIKE @RequestId + N':%'
            ORDER BY pa.PayableApplicationId DESC;

            SET @Resultado = 1;
            SET @Mensaje = N'Duplicado idempotente. Pago: ' + ISNULL(@NumPago, N'');
            COMMIT TRAN;
            RETURN;
        END

        DECLARE @Row INT = 1;
        DECLARE @TipoDoc NVARCHAR(20);
        DECLARE @NumDoc NVARCHAR(120);
        DECLARE @MontoAplicar DECIMAL(18,2);
        DECLARE @PayableId BIGINT;
        DECLARE @Pending DECIMAL(18,2);
        DECLARE @Total DECIMAL(18,2);
        DECLARE @Apply DECIMAL(18,2);
        DECLARE @AppliedTotal DECIMAL(18,2) = 0;

        WHILE EXISTS (SELECT 1 FROM @Docs WHERE RowNum = @Row)
        BEGIN
            SELECT
                @TipoDoc = TipoDoc,
                @NumDoc = NumDoc,
                @MontoAplicar = MontoAplicar
            FROM @Docs
            WHERE RowNum = @Row;

            SELECT TOP 1
                @PayableId = pd.PayableDocumentId,
                @Pending = pd.PendingAmount,
                @Total = pd.TotalAmount
            FROM ap.PayableDocument pd WITH (UPDLOCK, ROWLOCK)
            WHERE pd.SupplierId = @SupplierId
              AND pd.DocumentType = @TipoDoc
              AND pd.DocumentNumber = @NumDoc
              AND pd.Status <> N'VOIDED'
            ORDER BY pd.PayableDocumentId DESC;

            IF @PayableId IS NOT NULL AND @Pending > 0 AND @MontoAplicar > 0
            BEGIN
                SET @Apply = CASE WHEN @MontoAplicar > @Pending THEN @Pending ELSE @MontoAplicar END;

                INSERT INTO ap.PayableApplication (
                    PayableDocumentId,
                    ApplyDate,
                    AppliedAmount,
                    PaymentReference
                )
                VALUES (
                    @PayableId,
                    @FechaDate,
                    @Apply,
                    @RequestId + N':' + @NumPago
                );

                UPDATE ap.PayableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @Apply < 0 THEN 0 ELSE PendingAmount - @Apply END,
                    PaidFlag = CASE WHEN PendingAmount - @Apply <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                        WHEN PendingAmount - @Apply <= 0 THEN N'PAID'
                        WHEN PendingAmount - @Apply < @Total THEN N'PARTIAL'
                        ELSE N'PENDING'
                    END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE PayableDocumentId = @PayableId;

                SET @AppliedTotal = @AppliedTotal + @Apply;
            END

            SET @PayableId = NULL;
            SET @Pending = NULL;
            SET @Total = NULL;
            SET @Apply = NULL;
            SET @Row += 1;
        END

        IF @AppliedTotal <= 0
        BEGIN
            ROLLBACK TRAN;
            SET @Resultado = -4;
            SET @Mensaje = N'No se aplicó ningún monto';
            RETURN;
        END

        UPDATE [master].Supplier
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ap.PayableDocument
                WHERE SupplierId = @SupplierId
                  AND Status <> N'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE SupplierId = @SupplierId;

        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje = N'Pago aplicado exitosamente. Pago: ' + @NumPago;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT N'usp_CxP_AplicarPago v2 (modelo canónico) creado.';
GO
