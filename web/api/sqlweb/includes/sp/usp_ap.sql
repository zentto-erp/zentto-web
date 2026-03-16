-- =============================================================================
-- usp_ap.sql
-- Procedimientos de Cuentas por Pagar (Accounts Payable)
-- Operaciones sobre ap.PayableDocument y ap.PayableApplication.
--
-- Procedimientos incluidos:
--   1. usp_AP_Application_List          - Listado paginado de pagos realizados
--   2. usp_AP_Application_Get           - Detalle de un pago
--   3. usp_AP_Application_Apply         - Aplicar un pago a un documento por pagar
--   4. usp_AP_Application_Reverse       - Reversar (eliminar) un pago aplicado
--   5. usp_AP_Application_ListByContext - Listado paginado por contexto empresa/sucursal
--   6. usp_AP_Application_GetByContext  - Detalle de un pago por contexto
--   7. usp_AP_Application_Resolve       - Resuelve documento por pagar para aplicar pago
--   8. usp_AP_Application_Update        - Actualiza una aplicacion de pago existente
--
-- Dependencias:
--   - dbo.usp_Master_Supplier_UpdateBalance (usp_master_balance.sql)
--
-- Fecha creacion: 2026-03-14
-- =============================================================================
USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_AP_Application_List
--    Listado paginado de aplicaciones (pagos) realizados a proveedores.
--    Permite filtrar por proveedor, tipo de documento y rango de fechas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_List
    @SupplierId    BIGINT        = NULL,
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
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
    WHERE (@SupplierId   IS NULL OR d.SupplierId    = @SupplierId)
      AND (@DocumentType IS NULL OR d.DocumentType  = @DocumentType)
      AND (@FromDate     IS NULL OR a.ApplyDate    >= @FromDate)
      AND (@ToDate       IS NULL OR a.ApplyDate    <= @ToDate);

    -- Retornar pagina solicitada
    SELECT
        a.PayableApplicationId,
        a.PayableDocumentId,
        a.ApplyDate,
        a.AppliedAmount,
        a.PaymentReference,
        a.CreatedAt,
        d.DocumentNumber,
        d.DocumentType,
        d.TotalAmount,
        d.PendingAmount,
        d.Status        AS DocumentStatus,
        s.SupplierId,
        s.SupplierCode,
        s.SupplierName
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d  ON d.PayableDocumentId = a.PayableDocumentId
    INNER JOIN [master].Supplier s   ON s.SupplierId        = d.SupplierId
    WHERE (@SupplierId   IS NULL OR d.SupplierId    = @SupplierId)
      AND (@DocumentType IS NULL OR d.DocumentType  = @DocumentType)
      AND (@FromDate     IS NULL OR a.ApplyDate    >= @FromDate)
      AND (@ToDate       IS NULL OR a.ApplyDate    <= @ToDate)
    ORDER BY a.ApplyDate DESC, a.PayableApplicationId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 2. usp_AP_Application_Get
--    Obtiene el detalle de una aplicacion (pago) especifica junto con la
--    informacion del documento y del proveedor asociado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_Get
    @ApplicationId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.PayableApplicationId,
        a.PayableDocumentId,
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
        s.SupplierId,
        s.SupplierCode,
        s.SupplierName,
        s.FiscalId      AS SupplierFiscalId
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d  ON d.PayableDocumentId = a.PayableDocumentId
    INNER JOIN [master].Supplier s   ON s.SupplierId        = d.SupplierId
    WHERE a.PayableApplicationId = @ApplicationId;
END;
GO

-- =============================================================================
-- 3. usp_AP_Application_Apply
--    Aplica un pago a un documento por pagar.
--    Operacion transaccional:
--      - Bloquea el documento con UPDLOCK/ROWLOCK
--      - Valida que el monto no exceda el saldo pendiente
--      - Inserta la aplicacion en ap.PayableApplication
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), ApplicationId, NewPending, Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_Apply
    @PayableDocumentId  BIGINT,
    @Amount             DECIMAL(18,2),
    @PaymentReference   NVARCHAR(120)  = NULL,
    @ApplyDate          DATE           = NULL,
    @UpdatedByUserId    INT            = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Valores por defecto
    IF @ApplyDate IS NULL SET @ApplyDate = CAST(SYSUTCDATETIME() AS DATE);

    DECLARE @CurrentPending  DECIMAL(18,2);
    DECLARE @NewPending      DECIMAL(18,2);
    DECLARE @SupplierId      BIGINT;
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
            @SupplierId     = d.SupplierId,
            @DocStatus      = d.Status
        FROM ap.PayableDocument d WITH (UPDLOCK, ROWLOCK)
        WHERE d.PayableDocumentId = @PayableDocumentId;

        -- Validar que el documento existe
        IF @CurrentPending IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS ApplicationId, NULL AS NewPending, N'Documento por pagar no encontrado.' AS Message;
            RETURN;
        END

        -- Validar que el documento no este anulado
        IF @DocStatus = N'VOIDED'
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS ApplicationId, NULL AS NewPending, N'No se puede aplicar pago a un documento anulado.' AS Message;
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

        -- Insertar la aplicacion (pago)
        INSERT INTO ap.PayableApplication (PayableDocumentId, ApplyDate, AppliedAmount, PaymentReference)
        VALUES (@PayableDocumentId, @ApplyDate, @Amount, @PaymentReference);

        SET @ApplicationId = SCOPE_IDENTITY();

        -- Calcular nuevo saldo pendiente
        SET @NewPending = @CurrentPending - @Amount;

        -- Actualizar documento
        UPDATE ap.PayableDocument
        SET PendingAmount   = @NewPending,
            PaidFlag        = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END,
            Status          = CASE
                                WHEN @NewPending <= 0           THEN N'PAID'
                                WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                                ELSE N'PENDING'
                              END,
            UpdatedAt       = SYSUTCDATETIME(),
            UpdatedByUserId = @UpdatedByUserId
        WHERE PayableDocumentId = @PayableDocumentId;

        -- Recalcular saldo total del proveedor
        EXEC dbo.usp_Master_Supplier_UpdateBalance
            @SupplierId      = @SupplierId,
            @UpdatedByUserId = @UpdatedByUserId;

    COMMIT TRANSACTION;

    -- Retornar resultado exitoso
    SELECT 1 AS ok, @ApplicationId AS ApplicationId, @NewPending AS NewPending, N'Pago aplicado correctamente.' AS Message;
END;
GO

-- =============================================================================
-- 4. usp_AP_Application_Reverse
--    Reversa (elimina) una aplicacion de pago previamente registrada.
--    Operacion transaccional:
--      - Bloquea la aplicacion con UPDLOCK
--      - Elimina el registro de ap.PayableApplication
--      - Restaura el PendingAmount del documento y recalcula PaidFlag/Status
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), NewPending, Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_Reverse
    @ApplicationId    BIGINT,
    @UpdatedByUserId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AppliedAmount       DECIMAL(18,2);
    DECLARE @PayableDocumentId   BIGINT;
    DECLARE @SupplierId          BIGINT;
    DECLARE @TotalAmount         DECIMAL(18,2);
    DECLARE @NewPending          DECIMAL(18,2);

    BEGIN TRANSACTION;

        -- Obtener datos de la aplicacion con bloqueo
        SELECT
            @AppliedAmount      = a.AppliedAmount,
            @PayableDocumentId  = a.PayableDocumentId
        FROM ap.PayableApplication a WITH (UPDLOCK, ROWLOCK)
        WHERE a.PayableApplicationId = @ApplicationId;

        -- Validar que la aplicacion existe
        IF @AppliedAmount IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, NULL AS NewPending, N'Aplicacion de pago no encontrada.' AS Message;
            RETURN;
        END

        -- Obtener datos del documento asociado
        SELECT
            @SupplierId  = d.SupplierId,
            @TotalAmount = d.TotalAmount
        FROM ap.PayableDocument d WITH (UPDLOCK, ROWLOCK)
        WHERE d.PayableDocumentId = @PayableDocumentId;

        -- Eliminar la aplicacion
        DELETE FROM ap.PayableApplication
        WHERE PayableApplicationId = @ApplicationId;

        -- Calcular nuevo saldo pendiente
        SET @NewPending = (
            SELECT d.TotalAmount - ISNULL(SUM(a.AppliedAmount), 0)
            FROM ap.PayableDocument d
            LEFT JOIN ap.PayableApplication a ON a.PayableDocumentId = d.PayableDocumentId
            WHERE d.PayableDocumentId = @PayableDocumentId
            GROUP BY d.TotalAmount
        );

        -- Actualizar documento
        UPDATE ap.PayableDocument
        SET PendingAmount   = @NewPending,
            PaidFlag        = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END,
            Status          = CASE
                                WHEN @NewPending <= 0           THEN N'PAID'
                                WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                                ELSE N'PENDING'
                              END,
            UpdatedAt       = SYSUTCDATETIME(),
            UpdatedByUserId = @UpdatedByUserId
        WHERE PayableDocumentId = @PayableDocumentId;

        -- Recalcular saldo total del proveedor
        EXEC dbo.usp_Master_Supplier_UpdateBalance
            @SupplierId      = @SupplierId,
            @UpdatedByUserId = @UpdatedByUserId;

    COMMIT TRANSACTION;

    -- Retornar resultado exitoso
    SELECT 1 AS ok, @NewPending AS NewPending, N'Pago reversado correctamente.' AS Message;
END;
GO

-- =============================================================================
-- 5. usp_AP_Application_ListByContext
--    Listado paginado de aplicaciones (pagos) por contexto empresa/sucursal.
--    Permite filtrar por busqueda libre, codigo de proveedor y moneda.
--    Retorna columnas con alias legacy y canonico para compatibilidad VB6.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_ListByContext
    @CompanyId     INT,
    @BranchId      INT,
    @Search        NVARCHAR(100)  = NULL,
    @Codigo        NVARCHAR(60)   = NULL,
    @CurrencyCode  NVARCHAR(10)   = NULL,
    @Page          INT            = 1,
    @Limit         INT            = 50,
    @TotalCount    INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @SearchPattern NVARCHAR(102);
    IF @Search IS NOT NULL AND LEN(LTRIM(RTRIM(@Search))) > 0
        SET @SearchPattern = N'%' + LTRIM(RTRIM(@Search)) + N'%';

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
    INNER JOIN [master].Supplier  s ON s.SupplierId        = d.SupplierId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (
              d.DocumentNumber LIKE @SearchPattern
           OR s.SupplierName   LIKE @SearchPattern
           OR ISNULL(a.PaymentReference, N'') LIKE @SearchPattern
          ))
      AND (@Codigo       IS NULL OR s.SupplierCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode);

    -- Retornar pagina solicitada
    SELECT
        a.PayableApplicationId  AS Id,
        a.PayableApplicationId  AS ApplicationId,
        d.PayableDocumentId     AS DocumentoId,
        s.SupplierCode          AS CODIGO,
        s.SupplierCode          AS Codigo,
        s.SupplierName          AS NOMBRE,
        d.DocumentType          AS TIPO_DOC,
        d.DocumentType          AS TipoDoc,
        d.DocumentNumber        AS DOCUMENTO,
        d.DocumentNumber        AS Num_fact,
        a.ApplyDate             AS FECHA,
        a.ApplyDate             AS Fecha,
        a.AppliedAmount         AS MONTO,
        a.AppliedAmount         AS Monto,
        d.CurrencyCode          AS MONEDA,
        a.PaymentReference      AS REFERENCIA,
        a.PaymentReference      AS Concepto,
        d.PendingAmount         AS PENDIENTE,
        d.TotalAmount           AS TOTAL,
        d.Status                AS ESTADO_DOC
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
    INNER JOIN [master].Supplier  s ON s.SupplierId        = d.SupplierId
    WHERE d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@SearchPattern IS NULL OR (
              d.DocumentNumber LIKE @SearchPattern
           OR s.SupplierName   LIKE @SearchPattern
           OR ISNULL(a.PaymentReference, N'') LIKE @SearchPattern
          ))
      AND (@Codigo       IS NULL OR s.SupplierCode = @Codigo)
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode)
    ORDER BY a.ApplyDate DESC, a.PayableApplicationId DESC
    OFFSET ((@Page - 1) * @Limit) ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 6. usp_AP_Application_GetByContext
--    Obtiene un registro de aplicacion (pago) por su Id validando contexto
--    empresa/sucursal y opcionalmente moneda.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_GetByContext
    @ApplicationId  BIGINT,
    @CompanyId      INT,
    @BranchId       INT,
    @CurrencyCode   NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        a.PayableApplicationId  AS Id,
        a.PayableApplicationId  AS ApplicationId,
        d.PayableDocumentId     AS DocumentoId,
        s.SupplierCode          AS CODIGO,
        s.SupplierCode          AS Codigo,
        s.SupplierName          AS NOMBRE,
        d.DocumentType          AS TIPO_DOC,
        d.DocumentType          AS TipoDoc,
        d.DocumentNumber        AS DOCUMENTO,
        d.DocumentNumber        AS Num_fact,
        a.ApplyDate             AS FECHA,
        a.ApplyDate             AS Fecha,
        a.AppliedAmount         AS MONTO,
        a.AppliedAmount         AS Monto,
        d.CurrencyCode          AS MONEDA,
        a.PaymentReference      AS REFERENCIA,
        a.PaymentReference      AS Concepto,
        d.PendingAmount         AS PENDIENTE,
        d.TotalAmount           AS TOTAL,
        d.Status                AS ESTADO_DOC
    FROM ap.PayableApplication a
    INNER JOIN ap.PayableDocument d ON d.PayableDocumentId = a.PayableDocumentId
    INNER JOIN [master].Supplier  s ON s.SupplierId        = d.SupplierId
    WHERE a.PayableApplicationId = @ApplicationId
      AND d.CompanyId = @CompanyId
      AND d.BranchId  = @BranchId
      AND (@CurrencyCode IS NULL OR d.CurrencyCode = @CurrencyCode);
END;
GO

-- =============================================================================
-- 7. usp_AP_Application_Resolve
--    Resuelve un documento por pagar a partir de su numero, codigo de proveedor
--    y tipo de documento.  Retorna los datos necesarios para aplicar un pago.
--    Usa UPDLOCK, ROWLOCK para seguridad transaccional.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_Resolve
    @CompanyId       INT,
    @BranchId        INT,
    @DocumentNumber  NVARCHAR(120),
    @SupplierCode    NVARCHAR(24)  = NULL,
    @DocumentType    NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        d.PayableDocumentId,
        d.PendingAmount,
        d.TotalAmount,
        d.SupplierId,
        d.CurrencyCode
    FROM ap.PayableDocument d WITH (UPDLOCK, ROWLOCK)
    INNER JOIN [master].Supplier s ON s.SupplierId = d.SupplierId
    WHERE d.CompanyId      = @CompanyId
      AND d.BranchId       = @BranchId
      AND d.DocumentNumber = @DocumentNumber
      AND (@SupplierCode IS NULL OR s.SupplierCode = @SupplierCode)
      AND (@DocumentType IS NULL OR d.DocumentType = @DocumentType)
    ORDER BY d.PayableDocumentId DESC;
END;
GO

-- =============================================================================
-- 8. usp_AP_Application_Update
--    Actualiza una aplicacion de pago existente.
--    Operacion transaccional:
--      - Obtiene la aplicacion y el documento con UPDLOCK
--      - Valida moneda si se proporciona
--      - Calcula el delta entre monto original y nuevo
--      - Actualiza la aplicacion (monto, fecha, referencia)
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), Message
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_AP_Application_Update
    @ApplicationId     BIGINT,
    @Amount            DECIMAL(18,2)  = NULL,
    @ApplyDate         DATE           = NULL,
    @PaymentReference  NVARCHAR(120)  = NULL,
    @CurrencyCode      NVARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OriginalAmount  DECIMAL(18,2);
    DECLARE @CurrentPending  DECIMAL(18,2);
    DECLARE @TotalAmount     DECIMAL(18,2);
    DECLARE @SupplierId      BIGINT;
    DECLARE @DocCurrency     NVARCHAR(10);
    DECLARE @DocId           BIGINT;
    DECLARE @Delta           DECIMAL(18,2);
    DECLARE @NewPending      DECIMAL(18,2);

    BEGIN TRANSACTION;

        -- Obtener aplicacion y documento con bloqueo
        SELECT
            @OriginalAmount = a.AppliedAmount,
            @DocId          = a.PayableDocumentId,
            @CurrentPending = d.PendingAmount,
            @TotalAmount    = d.TotalAmount,
            @SupplierId     = d.SupplierId,
            @DocCurrency    = d.CurrencyCode
        FROM ap.PayableApplication a WITH (UPDLOCK, ROWLOCK)
        INNER JOIN ap.PayableDocument d WITH (UPDLOCK, ROWLOCK)
            ON d.PayableDocumentId = a.PayableDocumentId
        WHERE a.PayableApplicationId = @ApplicationId;

        -- Validar que la aplicacion existe
        IF @OriginalAmount IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'Aplicacion de pago no encontrada.' AS Message;
            RETURN;
        END

        -- Validar moneda si se especifica
        IF @CurrencyCode IS NOT NULL
           AND UPPER(@DocCurrency) <> UPPER(@CurrencyCode)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'La moneda no coincide con el documento.' AS Message;
            RETURN;
        END

        -- Determinar nuevo monto (si no se pasa, mantener el original)
        DECLARE @UpdatedAmount DECIMAL(18,2) = ISNULL(@Amount, @OriginalAmount);
        SET @Delta = @UpdatedAmount - @OriginalAmount;

        -- Validar saldo si se incrementa
        IF @Delta > 0 AND @CurrentPending < @Delta
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS ok, N'Saldo insuficiente en documento. Pendiente: '
                   + CAST(@CurrentPending AS NVARCHAR(30))
                   + N', Delta: ' + CAST(@Delta AS NVARCHAR(30)) AS Message;
            RETURN;
        END

        -- Calcular nuevo pendiente
        IF @Delta > 0
            SET @NewPending = @CurrentPending - @Delta;
        ELSE IF @Delta < 0
            SET @NewPending = CASE
                WHEN @CurrentPending + ABS(@Delta) > @TotalAmount THEN @TotalAmount
                ELSE @CurrentPending + ABS(@Delta)
            END;
        ELSE
            SET @NewPending = @CurrentPending;

        -- Actualizar la aplicacion
        UPDATE ap.PayableApplication
        SET AppliedAmount    = @UpdatedAmount,
            ApplyDate        = COALESCE(@ApplyDate, ApplyDate),
            PaymentReference = COALESCE(@PaymentReference, PaymentReference)
        WHERE PayableApplicationId = @ApplicationId;

        -- Actualizar documento si hubo cambio de monto
        IF @Delta <> 0
        BEGIN
            UPDATE ap.PayableDocument
            SET PendingAmount   = @NewPending,
                PaidFlag        = CASE WHEN @NewPending <= 0 THEN 1 ELSE 0 END,
                Status          = CASE
                                    WHEN @NewPending <= 0           THEN N'PAID'
                                    WHEN @NewPending < @TotalAmount THEN N'PARTIAL'
                                    ELSE N'PENDING'
                                  END,
                UpdatedAt       = SYSUTCDATETIME()
            WHERE PayableDocumentId = @DocId;

            -- Recalcular saldo del proveedor
            EXEC dbo.usp_Master_Supplier_UpdateBalance
                @SupplierId = @SupplierId;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS ok, N'Pago actualizado correctamente.' AS Message;
END;
GO

PRINT '[usp_ap] Procedimientos de Cuentas por Pagar (AP) creados correctamente.';
GO
