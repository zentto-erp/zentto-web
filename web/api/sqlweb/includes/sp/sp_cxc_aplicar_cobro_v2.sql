-- =============================================
-- usp_CxC_AplicarCobro v2 (modelo canónico)
-- Esquema: [master].Customer + ar.ReceivableDocument/ar.ReceivableApplication
-- Entrada arrays por XML para compatibilidad con SQL Server 2012
-- =============================================

IF OBJECT_ID(N'dbo.usp_CxC_AplicarCobro', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CxC_AplicarCobro;
GO

CREATE PROCEDURE dbo.usp_CxC_AplicarCobro
    @RequestId       NVARCHAR(100),
    @CodCliente      NVARCHAR(24),
    @Fecha           NVARCHAR(10),
    @MontoTotal      DECIMAL(18,2),
    @CodUsuario      NVARCHAR(40),
    @Observaciones   NVARCHAR(500) = N'',
    @DocumentosXml   NVARCHAR(MAX),
    @FormasPagoXml   NVARCHAR(MAX) = NULL,
    @NumRecibo       NVARCHAR(50) OUTPUT,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Resultado = 0;
    SET @Mensaje = N'';
    SET @NumRecibo = N'';

    DECLARE @FechaDate DATE = TRY_CONVERT(DATE, @Fecha);
    IF @FechaDate IS NULL
    BEGIN
        SET @Resultado = -91;
        SET @Mensaje = N'Fecha inválida: ' + ISNULL(@Fecha, N'NULL');
        RETURN;
    END

    DECLARE @CustomerId BIGINT;
    SELECT TOP 1 @CustomerId = c.CustomerId
    FROM [master].Customer c
    WHERE c.CustomerCode = @CodCliente
      AND c.IsDeleted = 0;

    IF @CustomerId IS NULL
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = N'Cliente no encontrado: ' + @CodCliente;
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
        UPPER(ISNULL(NULLIF(T.X.value('@tipoDoc', 'NVARCHAR(20)'), N''), N'FACT')),
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

    SET @NumRecibo = N'RCB-' + REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(19), SYSUTCDATETIME(), 120), N'-', N''), N' ', N''), N':', N'');

    BEGIN TRY
        BEGIN TRAN;

        IF EXISTS (
            SELECT 1
            FROM ar.ReceivableApplication ra
            INNER JOIN ar.ReceivableDocument rd ON rd.ReceivableDocumentId = ra.ReceivableDocumentId
            WHERE rd.CustomerId = @CustomerId
              AND ra.PaymentReference LIKE @RequestId + N':%'
        )
        BEGIN
            SELECT TOP 1 @NumRecibo = SUBSTRING(ra.PaymentReference, CHARINDEX(N':', ra.PaymentReference) + 1, 50)
            FROM ar.ReceivableApplication ra
            INNER JOIN ar.ReceivableDocument rd ON rd.ReceivableDocumentId = ra.ReceivableDocumentId
            WHERE rd.CustomerId = @CustomerId
              AND ra.PaymentReference LIKE @RequestId + N':%'
            ORDER BY ra.ReceivableApplicationId DESC;

            SET @Resultado = 1;
            SET @Mensaje = N'Duplicado idempotente. Recibo: ' + ISNULL(@NumRecibo, N'');
            COMMIT TRAN;
            RETURN;
        END

        DECLARE @Row INT = 1;
        DECLARE @TipoDoc NVARCHAR(20);
        DECLARE @NumDoc NVARCHAR(120);
        DECLARE @MontoAplicar DECIMAL(18,2);
        DECLARE @ReceivableId BIGINT;
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
                @ReceivableId = rd.ReceivableDocumentId,
                @Pending = rd.PendingAmount,
                @Total = rd.TotalAmount
            FROM ar.ReceivableDocument rd WITH (UPDLOCK, ROWLOCK)
            WHERE rd.CustomerId = @CustomerId
              AND rd.DocumentType = @TipoDoc
              AND rd.DocumentNumber = @NumDoc
              AND rd.Status <> N'VOIDED'
            ORDER BY rd.ReceivableDocumentId DESC;

            IF @ReceivableId IS NOT NULL AND @Pending > 0 AND @MontoAplicar > 0
            BEGIN
                SET @Apply = CASE WHEN @MontoAplicar > @Pending THEN @Pending ELSE @MontoAplicar END;

                INSERT INTO ar.ReceivableApplication (
                    ReceivableDocumentId,
                    ApplyDate,
                    AppliedAmount,
                    PaymentReference
                )
                VALUES (
                    @ReceivableId,
                    @FechaDate,
                    @Apply,
                    @RequestId + N':' + @NumRecibo
                );

                UPDATE ar.ReceivableDocument
                SET PendingAmount = CASE WHEN PendingAmount - @Apply < 0 THEN 0 ELSE PendingAmount - @Apply END,
                    PaidFlag = CASE WHEN PendingAmount - @Apply <= 0 THEN 1 ELSE 0 END,
                    Status = CASE
                        WHEN PendingAmount - @Apply <= 0 THEN N'PAID'
                        WHEN PendingAmount - @Apply < @Total THEN N'PARTIAL'
                        ELSE N'PENDING'
                    END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE ReceivableDocumentId = @ReceivableId;

                SET @AppliedTotal = @AppliedTotal + @Apply;
            END

            SET @ReceivableId = NULL;
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

        UPDATE [master].Customer
        SET TotalBalance = (
                SELECT ISNULL(SUM(PendingAmount), 0)
                FROM ar.ReceivableDocument
                WHERE CustomerId = @CustomerId
                  AND Status <> N'VOIDED'
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CustomerId = @CustomerId;

        COMMIT TRAN;

        SET @Resultado = 1;
        SET @Mensaje = N'Cobro aplicado exitosamente. Recibo: ' + @NumRecibo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT N'usp_CxC_AplicarCobro v2 (modelo canónico) creado.';
GO
