-- =============================================================================
-- usp_ar.sql
-- Procedimientos de Cuentas por Cobrar (Accounts Receivable)
-- Operaciones sobre ar.ReceivableDocument y ar.ReceivableApplication.
--
-- Procedimientos incluidos:
--   1. usp_AR_Application_List    - Listado paginado de abonos/cobros
--   2. usp_AR_Application_Get     - Detalle de un abono
--   3. usp_AR_Application_Apply   - Aplicar un abono (cobro) a un documento
--   4. usp_AR_Application_Reverse - Reversar (eliminar) un abono aplicado
--
-- Dependencias:
--   - dbo.usp_Master_Customer_UpdateBalance (usp_master_balance.sql)
--
-- Fecha creacion: 2026-03-14
-- =============================================================================
USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_AR_Application_List
--    Listado paginado de aplicaciones (abonos/cobros) recibidos.
--    Permite filtrar por cliente, tipo de documento y rango de fechas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_List
    @CustomerId    BIGINT        = NULL,
    @DocumentType  NVARCHAR(20)  = NULL,
    @FromDate      DATE          = NULL,
    @ToDate        DATE          = NULL,
    @Page          INT           = 1,
    @Limit         INT           = 50,
    @TotalCount    INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar registros totales que cumplen los filtros
    SELECT @TotalCount = COUNT(*)
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    WHERE (@CustomerId   IS NULL OR d.CustomerId    = @CustomerId)
      AND (@DocumentType IS NULL OR d.DocumentType  = @DocumentType)
      AND (@FromDate     IS NULL OR a.ApplyDate    >= @FromDate)
      AND (@ToDate       IS NULL OR a.ApplyDate    <= @ToDate);

    -- Retornar pagina solicitada
    SELECT
        a.ReceivableApplicationId,
        a.ReceivableDocumentId,
        a.ApplyDate,
        a.AppliedAmount,
        a.PaymentReference,
        a.CreatedAt,
        d.DocumentNumber,
        d.DocumentType,
        d.TotalAmount,
        d.PendingAmount,
        d.Status        AS DocumentStatus,
        c.CustomerId,
        c.CustomerCode,
        c.CustomerName
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    INNER JOIN [master].Customer c     ON c.CustomerId           = d.CustomerId
    WHERE (@CustomerId   IS NULL OR d.CustomerId    = @CustomerId)
      AND (@DocumentType IS NULL OR d.DocumentType  = @DocumentType)
      AND (@FromDate     IS NULL OR a.ApplyDate    >= @FromDate)
      AND (@ToDate       IS NULL OR a.ApplyDate    <= @ToDate)
    ORDER BY a.ApplyDate DESC, a.ReceivableApplicationId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 2. usp_AR_Application_Get
--    Obtiene el detalle de una aplicacion (abono) especifica junto con la
--    informacion del documento y del cliente asociado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_Get
    @ApplicationId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.ReceivableApplicationId,
        a.ReceivableDocumentId,
        a.ApplyDate,
        a.AppliedAmount,
        a.PaymentReference,
        a.CreatedAt,
        d.DocumentNumber,
        d.DocumentType,
        d.IssueDate,
        d.DueDate,
        d.CurrencyCode,
        d.TotalAmount,
        d.PendingAmount,
        d.PaidFlag,
        d.Status        AS DocumentStatus,
        d.Notes         AS DocumentNotes,
        c.CustomerId,
        c.CustomerCode,
        c.CustomerName,
        c.FiscalId      AS CustomerFiscalId
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    INNER JOIN [master].Customer c     ON c.CustomerId           = d.CustomerId
    WHERE a.ReceivableApplicationId = @ApplicationId;
END;
GO

-- =============================================================================
-- 3. usp_AR_Application_Apply
--    Aplica un cobro (abono) a un documento por cobrar.
--    Operacion transaccional:
--      - Bloquea el documento con UPDLOCK/ROWLOCK
--      - Valida que el monto no exceda el saldo pendiente
--      - Inserta la aplicacion en ar.ReceivableApplication
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), ApplicationId, NewPending, Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_Apply
    @ReceivableDocumentId  BIGINT,
    @Amount                DECIMAL(18,2),
    @PaymentReference      NVARCHAR(120)  = NULL,
    @ApplyDate             DATE           = NULL,
    @UpdatedByUserId       INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Valores por defecto
    IF @ApplyDate IS NULL SET @ApplyDate = CAST(SYSUTCDATETIME() AS DATE);

    DECLARE @CurrentPending  DECIMAL(18,2);
    DECLARE @NewPending      DECIMAL(18,2);
    DECLARE @CustomerId      BIGINT;
    DECLARE @TotalAmount     DECIMAL(18,2);
    DECLARE @ApplicationId   BIGINT;
    DECLARE @DocStatus       NVARCHAR(20);

    -- Validaciones basicas
    IF @Amount IS NULL OR @Amount <= 0
    BEGIN
        SELECT 0 AS ok, NULL AS ApplicationId, NULL AS NewPending, N'El monto debe ser mayor a cero.' AS Message;
        RETURN;
    END

    BEGIN TRANSACTION;

        -- Obtener documento con bloqueo para evitar concurrencia
        SELECT
            @CurrentPending = d.PendingAmount,
            @TotalAmount    = d.TotalAmount,
            @CustomerId     = d.CustomerId,
            @DocStatus      = d.Status
        FROM ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK)
        WHERE d.ReceivableDocumentId = @ReceivableDocumentId;

        -- Validar que el documento existe
        IF @CurrentPending IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS ApplicationId, NULL AS NewPending, N'Documento por cobrar no encontrado.' AS Message;
            RETURN;
        END

        -- Validar que el documento no este anulado
        IF @DocStatus = N'VOIDED'
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS ApplicationId, NULL AS NewPending, N'No se puede aplicar abono a un documento anulado.' AS Message;
            RETURN;
        END

        -- Validar que el monto no exceda el saldo pendiente
        IF @Amount > @CurrentPending
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS ApplicationId, @CurrentPending AS NewPending,
                   N'El monto (' + CAST(@Amount AS NVARCHAR(30)) + N') excede el saldo pendiente (' + CAST(@CurrentPending AS NVARCHAR(30)) + N').' AS Message;
            RETURN;
        END

        -- Insertar la aplicacion (abono)
        INSERT INTO ar.ReceivableApplication (ReceivableDocumentId, ApplyDate, AppliedAmount, PaymentReference)
        VALUES (@ReceivableDocumentId, @ApplyDate, @Amount, @PaymentReference);

        SET @ApplicationId = SCOPE_IDENTITY();

        -- Calcular nuevo saldo pendiente
        SET @NewPending = @CurrentPending - @Amount;

        -- Actualizar documento
        UPDATE ar.ReceivableDocument
        SET PendingAmount   = @NewPending,
            PaidFlag        = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END,
            Status          = CASE
                                WHEN @NewPending <= 0      THEN N'PAID'
                                WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                                ELSE N'PENDING'
                              END,
            UpdatedAt       = SYSUTCDATETIME(),
            UpdatedByUserId = @UpdatedByUserId
        WHERE ReceivableDocumentId = @ReceivableDocumentId;

        -- Recalcular saldo total del cliente
        EXEC dbo.usp_Master_Customer_UpdateBalance
            @CustomerId      = @CustomerId,
            @UpdatedByUserId = @UpdatedByUserId;

    COMMIT TRANSACTION;

    -- Retornar resultado exitoso
    SELECT 1 AS ok, @ApplicationId AS ApplicationId, @NewPending AS NewPending, N'Abono aplicado correctamente.' AS Message;
END;
GO

-- =============================================================================
-- 4. usp_AR_Application_Reverse
--    Reversa (elimina) una aplicacion de cobro previamente registrada.
--    Operacion transaccional:
--      - Bloquea la aplicacion con UPDLOCK
--      - Elimina el registro de ar.ReceivableApplication
--      - Restaura el PendingAmount del documento y recalcula PaidFlag/Status
--      - Recalcula el saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), NewPending, Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_Reverse
    @ApplicationId    BIGINT,
    @UpdatedByUserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AppliedAmount          DECIMAL(18,2);
    DECLARE @ReceivableDocumentId   BIGINT;
    DECLARE @CustomerId             BIGINT;
    DECLARE @TotalAmount            DECIMAL(18,2);
    DECLARE @NewPending             DECIMAL(18,2);

    BEGIN TRANSACTION;

        -- Obtener datos de la aplicacion con bloqueo
        SELECT
            @AppliedAmount        = a.AppliedAmount,
            @ReceivableDocumentId = a.ReceivableDocumentId
        FROM ar.ReceivableApplication a WITH (UPDLOCK, ROWLOCK)
        WHERE a.ReceivableApplicationId = @ApplicationId;

        -- Validar que la aplicacion existe
        IF @AppliedAmount IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS NewPending, N'Aplicacion de cobro no encontrada.' AS Message;
            RETURN;
        END

        -- Obtener datos del documento asociado
        SELECT
            @CustomerId  = d.CustomerId,
            @TotalAmount = d.TotalAmount
        FROM ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK)
        WHERE d.ReceivableDocumentId = @ReceivableDocumentId;

        -- Eliminar la aplicacion
        DELETE FROM ar.ReceivableApplication
        WHERE ReceivableApplicationId = @ApplicationId;

        -- Calcular nuevo saldo pendiente
        SET @NewPending = (
            SELECT d.TotalAmount - ISNULL(SUM(a.AppliedAmount), 0)
            FROM ar.ReceivableDocument d
            LEFT JOIN ar.ReceivableApplication a ON a.ReceivableDocumentId = d.ReceivableDocumentId
            WHERE d.ReceivableDocumentId = @ReceivableDocumentId
            GROUP BY d.TotalAmount
        );

        -- Actualizar documento
        UPDATE ar.ReceivableDocument
        SET PendingAmount   = @NewPending,
            PaidFlag        = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END,
            Status          = CASE
                                WHEN @NewPending <= 0           THEN N'PAID'
                                WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                                ELSE N'PENDING'
                              END,
            UpdatedAt       = SYSUTCDATETIME(),
            UpdatedByUserId = @UpdatedByUserId
        WHERE ReceivableDocumentId = @ReceivableDocumentId;

        -- Recalcular saldo total del cliente
        EXEC dbo.usp_Master_Customer_UpdateBalance
            @CustomerId      = @CustomerId,
            @UpdatedByUserId = @UpdatedByUserId;

    COMMIT TRANSACTION;

    -- Retornar resultado exitoso
    SELECT 1 AS ok, @NewPending AS NewPending, N'Abono reversado correctamente.' AS Message;
END;
GO

-- =============================================================================
-- 5. usp_AR_Application_ListByContext
--    Listado paginado de aplicaciones filtrado por contexto (Company/Branch).
--    Permite busqueda por DocumentNumber, CustomerName, PaymentReference,
--    filtro por CustomerCode y CurrencyCode.
--    Retorna las columnas alias legacy + canonical para compatibilidad VB6.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_ListByContext
    @CompanyId      INT,
    @BranchId       INT,
    @Search         NVARCHAR(100)  = NULL,
    @Codigo         NVARCHAR(60)   = NULL,
    @CurrencyCode   NVARCHAR(10)   = NULL,
    @Page           INT            = 1,
    @Limit          INT            = 50,
    @TotalCount     INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page  < 1   SET @Page  = 1;
    IF @Limit < 1   SET @Limit = 50;
    IF @Limit > 500  SET @Limit = 500;

    DECLARE @SearchPattern NVARCHAR(102);
    IF @Search IS NOT NULL AND LEN(LTRIM(RTRIM(@Search))) > 0
        SET @SearchPattern = N'%' + LTRIM(RTRIM(@Search)) + N'%';

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    INNER JOIN [master].Customer c     ON c.CustomerId           = d.CustomerId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL
           OR d.DocumentNumber    LIKE @SearchPattern
           OR c.CustomerName      LIKE @SearchPattern
           OR a.PaymentReference  LIKE @SearchPattern)
      AND (@Codigo       IS NULL OR c.CustomerCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode);

    -- Retornar pagina solicitada
    SELECT
        a.ReceivableApplicationId   AS Id,
        a.ReceivableApplicationId   AS ApplicationId,
        d.ReceivableDocumentId      AS DocumentoId,
        c.CustomerCode              AS CODIGO,
        c.CustomerCode              AS Codigo,
        c.CustomerName              AS NOMBRE,
        d.DocumentType              AS TIPO_DOC,
        d.DocumentType              AS TipoDoc,
        d.DocumentNumber            AS DOCUMENTO,
        d.DocumentNumber            AS Num_fact,
        a.ApplyDate                 AS FECHA,
        a.ApplyDate                 AS Fecha,
        a.AppliedAmount             AS MONTO,
        a.AppliedAmount             AS Monto,
        d.CurrencyCode              AS MONEDA,
        a.PaymentReference          AS REFERENCIA,
        a.PaymentReference          AS Concepto,
        d.PendingAmount             AS PENDIENTE,
        d.TotalAmount               AS TOTAL,
        d.Status                    AS ESTADO_DOC
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    INNER JOIN [master].Customer c     ON c.CustomerId           = d.CustomerId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL
           OR d.DocumentNumber    LIKE @SearchPattern
           OR c.CustomerName      LIKE @SearchPattern
           OR a.PaymentReference  LIKE @SearchPattern)
      AND (@Codigo       IS NULL OR c.CustomerCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode)
    ORDER BY a.ApplyDate DESC, a.ReceivableApplicationId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 6. usp_AR_Application_GetByContext
--    Obtiene una aplicacion (abono) por Id, validando Company/Branch y
--    opcionalmente filtrando por moneda.
--    Retorna las mismas columnas alias que ListByContext.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_GetByContext
    @ApplicationId  BIGINT,
    @CompanyId      INT,
    @BranchId       INT,
    @CurrencyCode   NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        a.ReceivableApplicationId   AS Id,
        a.ReceivableApplicationId   AS ApplicationId,
        d.ReceivableDocumentId      AS DocumentoId,
        c.CustomerCode              AS CODIGO,
        c.CustomerCode              AS Codigo,
        c.CustomerName              AS NOMBRE,
        d.DocumentType              AS TIPO_DOC,
        d.DocumentType              AS TipoDoc,
        d.DocumentNumber            AS DOCUMENTO,
        d.DocumentNumber            AS Num_fact,
        a.ApplyDate                 AS FECHA,
        a.ApplyDate                 AS Fecha,
        a.AppliedAmount             AS MONTO,
        a.AppliedAmount             AS Monto,
        d.CurrencyCode              AS MONEDA,
        a.PaymentReference          AS REFERENCIA,
        a.PaymentReference          AS Concepto,
        d.PendingAmount             AS PENDIENTE,
        d.TotalAmount               AS TOTAL,
        d.Status                    AS ESTADO_DOC
    FROM ar.ReceivableApplication a
    INNER JOIN ar.ReceivableDocument d ON d.ReceivableDocumentId = a.ReceivableDocumentId
    INNER JOIN [master].Customer c     ON c.CustomerId           = d.CustomerId
    WHERE a.ReceivableApplicationId = @ApplicationId
      AND d.CompanyId  = @CompanyId
      AND d.BranchId   = @BranchId
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode);
END;
GO

-- =============================================================================
-- 7. usp_AR_Application_Resolve
--    Resuelve un documento por cobrar a partir de DocumentNumber, Company,
--    Branch, y opcionalmente CustomerCode y DocumentType.
--    Bloquea la fila con UPDLOCK/ROWLOCK para uso dentro de transacciones.
--    Retorna: ReceivableDocumentId, PendingAmount, TotalAmount, CustomerId,
--             CurrencyCode.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_Resolve
    @CompanyId       INT,
    @BranchId        INT,
    @DocumentNumber  NVARCHAR(120),
    @CustomerCode    NVARCHAR(24)  = NULL,
    @DocumentType    NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        d.ReceivableDocumentId,
        d.PendingAmount,
        d.TotalAmount,
        d.CustomerId,
        d.CurrencyCode
    FROM ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK)
    INNER JOIN [master].Customer c ON c.CustomerId = d.CustomerId
    WHERE d.CompanyId       = @CompanyId
      AND d.BranchId        = @BranchId
      AND d.DocumentNumber  = @DocumentNumber
      AND (@CustomerCode IS NULL OR c.CustomerCode = @CustomerCode)
      AND (@DocumentType IS NULL OR d.DocumentType = @DocumentType)
    ORDER BY d.ReceivableDocumentId DESC;
END;
GO

-- =============================================================================
-- 8. usp_AR_Application_Update
--    Actualiza una aplicacion (abono) existente.
--    Operacion transaccional:
--      - Bloquea aplicacion + documento con UPDLOCK
--      - Valida moneda si se especifica @CurrencyCode
--      - Calcula delta de monto y valida saldo suficiente
--      - Actualiza aplicacion (monto, fecha, referencia)
--      - Actualiza PendingAmount/Status/PaidFlag del documento
--      - Recalcula saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AR_Application_Update
    @ApplicationId     BIGINT,
    @Amount            DECIMAL(18,2)  = NULL,
    @ApplyDate         DATE           = NULL,
    @PaymentReference  NVARCHAR(120)  = NULL,
    @CurrencyCode      NVARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentAmount   DECIMAL(18,2);
    DECLARE @DocId           BIGINT;
    DECLARE @Pending         DECIMAL(18,2);
    DECLARE @TotalAmount     DECIMAL(18,2);
    DECLARE @CustomerId      BIGINT;
    DECLARE @DocCurrency     NVARCHAR(10);
    DECLARE @Delta           DECIMAL(18,2);
    DECLARE @NewPending      DECIMAL(18,2);
    DECLARE @NewStatus       NVARCHAR(20);
    DECLARE @NewPaidFlag     BIT;

    BEGIN TRANSACTION;

        -- Obtener aplicacion y documento con bloqueo
        SELECT
            @CurrentAmount = a.AppliedAmount,
            @DocId         = a.ReceivableDocumentId,
            @Pending       = d.PendingAmount,
            @TotalAmount   = d.TotalAmount,
            @CustomerId    = d.CustomerId,
            @DocCurrency   = d.CurrencyCode
        FROM ar.ReceivableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ar.ReceivableDocument d WITH (UPDLOCK, ROWLOCK)
            ON d.ReceivableDocumentId = a.ReceivableDocumentId
        WHERE a.ReceivableApplicationId = @ApplicationId;

        -- Validar que la aplicacion existe
        IF @CurrentAmount IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'Aplicacion de cobro no encontrada.' AS Message;
            RETURN;
        END

        -- Validar moneda si se especifica
        IF @CurrencyCode IS NOT NULL AND UPPER(@DocCurrency) <> UPPER(@CurrencyCode)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'La moneda del documento no coincide con la solicitada.' AS Message;
            RETURN;
        END

        -- Determinar el nuevo monto (si no se especifica, mantener el actual)
        IF @Amount IS NULL SET @Amount = @CurrentAmount;

        -- Validar monto positivo
        IF @Amount <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'El monto debe ser mayor a cero.' AS Message;
            RETURN;
        END

        -- Calcular delta y nuevo saldo pendiente
        SET @Delta = @Amount - @CurrentAmount;

        IF @Delta > 0 AND @Pending < @Delta
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'Saldo insuficiente en el documento. Pendiente actual: ' + CAST(@Pending AS NVARCHAR(30)) AS Message;
            RETURN;
        END

        IF @Delta > 0
            SET @NewPending = @Pending - @Delta;
        ELSE IF @Delta < 0
            SET @NewPending = CASE
                                WHEN @Pending + ABS(@Delta) > @TotalAmount THEN @TotalAmount
                                ELSE @Pending + ABS(@Delta)
                              END;
        ELSE
            SET @NewPending = @Pending;

        -- Calcular nuevo estado del documento
        SET @NewPaidFlag = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END;
        SET @NewStatus   = CASE
                             WHEN @NewPending <= 0           THEN N'PAID'
                             WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                             ELSE N'PENDING'
                           END;

        -- Actualizar la aplicacion
        UPDATE ar.ReceivableApplication
        SET AppliedAmount    = @Amount,
            ApplyDate        = COALESCE(@ApplyDate, ApplyDate),
            PaymentReference = COALESCE(@PaymentReference, PaymentReference)
        WHERE ReceivableApplicationId = @ApplicationId;

        -- Actualizar documento si hubo cambio de monto
        IF @Delta <> 0
        BEGIN
            UPDATE ar.ReceivableDocument
            SET PendingAmount   = @NewPending,
                Status          = @NewStatus,
                PaidFlag        = @NewPaidFlag,
                UpdatedAt       = SYSUTCDATETIME()
            WHERE ReceivableDocumentId = @DocId;

            -- Recalcular saldo total del cliente
            EXEC dbo.usp_Master_Customer_UpdateBalance
                @CustomerId = @CustomerId;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS ok, N'Abono actualizado correctamente.' AS Message;
END;
GO

PRINT '[usp_ar] Procedimientos de Cuentas por Cobrar (AR) creados correctamente.';
GO
