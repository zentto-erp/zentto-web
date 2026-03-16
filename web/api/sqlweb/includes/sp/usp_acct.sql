/*
 * ============================================================================
 *  Archivo : usp_acct.sql
 *  Esquema : acct (contabilidad)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados para gestion del plan de cuentas contable.
 *    - usp_Acct_Account_List    : Lista paginada de cuentas con filtros.
 *    - usp_Acct_Account_Get     : Obtiene una cuenta por su codigo.
 *    - usp_Acct_Account_Insert  : Inserta una nueva cuenta contable.
 *    - usp_Acct_Account_Update  : Actualiza campos de una cuenta existente.
 *    - usp_Acct_Account_Delete  : Eliminacion logica (soft delete).
 *
 *  Tabla principal: acct.Account
 *    Columnas: AccountId, CompanyId, AccountCode, AccountName, AccountType,
 *              AccountLevel, ParentAccountId, AllowsPosting, RequiresAuxiliary,
 *              IsActive, CreatedAt, UpdatedAt, IsDeleted, RowVer
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Acct_Account_List
--  Descripcion : Devuelve una lista paginada de cuentas contables con filtros
--                opcionales por texto de busqueda, tipo de cuenta y grupo.
--  Parametros  :
--    @CompanyId   INT              - ID de la empresa (obligatorio).
--    @Search      NVARCHAR(100)    - Texto a buscar en codigo o nombre (opcional).
--    @Tipo        NVARCHAR(1)      - Tipo de cuenta: A=Activo, P=Pasivo, etc. (opcional).
--    @Grupo       NVARCHAR(20)     - Prefijo de grupo para filtrar por codigo (opcional).
--    @Page        INT              - Numero de pagina (default 1).
--    @Limit       INT              - Registros por pagina (default 50).
--    @TotalCount  INT OUTPUT       - Total de registros que cumplen los filtros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_List
    @CompanyId   INT,
    @Search      NVARCHAR(100) = NULL,
    @Tipo        NVARCHAR(1)   = NULL,
    @Grupo       NVARCHAR(20)  = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar total de registros que cumplen los filtros
    SELECT @TotalCount = COUNT(*)
    FROM   acct.Account
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@Search IS NULL
            OR AccountCode LIKE '%' + @Search + '%'
            OR AccountName LIKE '%' + @Search + '%')
      AND  (@Tipo IS NULL OR AccountType = @Tipo)
      AND  (@Grupo IS NULL OR AccountCode LIKE @Grupo + '%');

    -- Devolver pagina solicitada
    SELECT AccountId,
           AccountCode,
           AccountName,
           AccountType,
           AccountLevel,
           AllowsPosting,
           IsActive
    FROM   acct.Account
    WHERE  CompanyId = @CompanyId
      AND  IsDeleted = 0
      AND  (@Search IS NULL
            OR AccountCode LIKE '%' + @Search + '%'
            OR AccountName LIKE '%' + @Search + '%')
      AND  (@Tipo IS NULL OR AccountType = @Tipo)
      AND  (@Grupo IS NULL OR AccountCode LIKE @Grupo + '%')
    ORDER BY AccountCode
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 2: usp_Acct_Account_Get
--  Descripcion : Obtiene todos los campos de una cuenta contable dado su codigo.
--  Parametros  :
--    @CompanyId    INT             - ID de la empresa (obligatorio).
--    @AccountCode  NVARCHAR(20)    - Codigo de la cuenta (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_Get
    @CompanyId    INT,
    @AccountCode  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 *
    FROM   acct.Account
    WHERE  CompanyId   = @CompanyId
      AND  AccountCode = @AccountCode
      AND  IsDeleted   = 0;
END;
GO

-- =============================================================================
--  SP 3: usp_Acct_Account_Insert
--  Descripcion : Inserta una nueva cuenta contable. Valida que no exista
--                duplicado por CompanyId + AccountCode.
--  Parametros  :
--    @CompanyId       INT             - ID de la empresa (obligatorio).
--    @AccountCode     NVARCHAR(20)    - Codigo de la cuenta (obligatorio).
--    @AccountName     NVARCHAR(200)   - Nombre/descripcion de la cuenta (obligatorio).
--    @AccountType     NVARCHAR(1)     - Tipo: A=Activo, P=Pasivo, etc. (default 'A').
--    @AccountLevel    INT             - Nivel jerarquico (default 1).
--    @ParentAccountId INT             - ID de la cuenta padre (opcional).
--    @AllowsPosting   BIT             - Permite movimientos directos (default 1).
--    @Resultado       INT OUTPUT      - 1=exito, 0=error.
--    @Mensaje         NVARCHAR(500) OUTPUT - Mensaje descriptivo del resultado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_Insert
    @CompanyId       INT,
    @AccountCode     NVARCHAR(20),
    @AccountName     NVARCHAR(200),
    @AccountType     NVARCHAR(1)   = 'A',
    @AccountLevel    INT           = NULL,
    @ParentAccountId INT           = NULL,
    @AllowsPosting   BIT           = 1,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Validar que no exista duplicado
    IF EXISTS (
        SELECT 1
        FROM   acct.Account
        WHERE  CompanyId   = @CompanyId
          AND  AccountCode = @AccountCode
          AND  IsDeleted   = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Ya existe una cuenta con el codigo ' + @AccountCode
                       + N' para esta empresa.';
        RETURN;
    END;

    -- Auto-resolver nivel desde AccountCode si no se proporciono
    IF @AccountLevel IS NULL OR @AccountLevel < 1
    BEGIN
        -- Contar segmentos separados por '.'
        SET @AccountLevel = LEN(@AccountCode) - LEN(REPLACE(@AccountCode, '.', '')) + 1;
        IF @AccountLevel < 1 SET @AccountLevel = 1;
    END;

    -- Auto-resolver cuenta padre desde AccountCode si no se proporciono
    IF @ParentAccountId IS NULL AND CHARINDEX('.', @AccountCode) > 0
    BEGIN
        DECLARE @ParentCode NVARCHAR(20);
        SET @ParentCode = LEFT(@AccountCode,
            LEN(@AccountCode) - CHARINDEX('.', REVERSE(@AccountCode)));

        SELECT TOP 1 @ParentAccountId = AccountId
        FROM   acct.Account
        WHERE  CompanyId   = @CompanyId
          AND  AccountCode = @ParentCode
          AND  IsDeleted   = 0;

        -- Si la cuenta tiene padre implicito pero no se encontro, rechazar
        IF @ParentAccountId IS NULL
        BEGIN
            SET @Resultado = 0;
            SET @Mensaje   = N'Cuenta padre ' + @ParentCode + N' no encontrada.';
            RETURN;
        END;
    END;

    BEGIN TRY
        INSERT INTO acct.Account (
            CompanyId,
            AccountCode,
            AccountName,
            AccountType,
            AccountLevel,
            ParentAccountId,
            AllowsPosting,
            RequiresAuxiliary,
            IsActive,
            CreatedAt,
            UpdatedAt,
            IsDeleted
        )
        VALUES (
            @CompanyId,
            @AccountCode,
            @AccountName,
            @AccountType,
            @AccountLevel,
            @ParentAccountId,
            @AllowsPosting,
            0,           -- RequiresAuxiliary default
            1,           -- IsActive default
            SYSUTCDATETIME(),
            SYSUTCDATETIME(),
            0            -- IsDeleted
        );

        SET @Resultado = 1;
        SET @Mensaje   = N'Cuenta ' + @AccountCode + N' creada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al insertar cuenta: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 4: usp_Acct_Account_Update
--  Descripcion : Actualiza campos de una cuenta existente usando el patron
--                COALESCE para aplicar solo los valores proporcionados.
--  Parametros  :
--    @CompanyId     INT             - ID de la empresa (obligatorio).
--    @AccountCode   NVARCHAR(20)    - Codigo de la cuenta a actualizar (obligatorio).
--    @AccountName   NVARCHAR(200)   - Nuevo nombre (opcional, NULL = sin cambio).
--    @AccountType   NVARCHAR(1)     - Nuevo tipo (opcional, NULL = sin cambio).
--    @AccountLevel  INT             - Nuevo nivel (opcional, NULL = sin cambio).
--    @AllowsPosting BIT             - Permite movimientos (opcional, NULL = sin cambio).
--    @Resultado     INT OUTPUT      - 1=exito, 0=error.
--    @Mensaje       NVARCHAR(500) OUTPUT - Mensaje descriptivo del resultado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_Update
    @CompanyId     INT,
    @AccountCode   NVARCHAR(20),
    @AccountName   NVARCHAR(200) = NULL,
    @AccountType   NVARCHAR(1)   = NULL,
    @AccountLevel  INT           = NULL,
    @AllowsPosting BIT           = NULL,
    @Resultado     INT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Verificar que la cuenta exista y no este eliminada
    IF NOT EXISTS (
        SELECT 1
        FROM   acct.Account
        WHERE  CompanyId   = @CompanyId
          AND  AccountCode = @AccountCode
          AND  IsDeleted   = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'No se encontro la cuenta con codigo ' + @AccountCode + N'.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE acct.Account
        SET    AccountName   = COALESCE(@AccountName,   AccountName),
               AccountType   = COALESCE(@AccountType,   AccountType),
               AccountLevel  = COALESCE(@AccountLevel,  AccountLevel),
               AllowsPosting = COALESCE(@AllowsPosting, AllowsPosting),
               UpdatedAt     = SYSUTCDATETIME()
        WHERE  CompanyId   = @CompanyId
          AND  AccountCode = @AccountCode
          AND  IsDeleted   = 0;

        SET @Resultado = 1;
        SET @Mensaje   = N'Cuenta ' + @AccountCode + N' actualizada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al actualizar cuenta: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 5: usp_Acct_Account_Delete
--  Descripcion : Realiza una eliminacion logica (soft delete) marcando
--                IsDeleted=1 y registrando la fecha de eliminacion.
--  Parametros  :
--    @CompanyId    INT             - ID de la empresa (obligatorio).
--    @AccountCode  NVARCHAR(20)    - Codigo de la cuenta a eliminar (obligatorio).
--    @Resultado    INT OUTPUT      - 1=exito, 0=error.
--    @Mensaje      NVARCHAR(500) OUTPUT - Mensaje descriptivo del resultado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_Delete
    @CompanyId    INT,
    @AccountCode  NVARCHAR(20),
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @AccountId INT;

    -- Verificar que la cuenta exista y no este ya eliminada
    SELECT TOP 1 @AccountId = AccountId
    FROM   acct.Account
    WHERE  CompanyId   = @CompanyId
      AND  AccountCode = @AccountCode
      AND  IsDeleted   = 0;

    IF @AccountId IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'No se encontro la cuenta con codigo ' + @AccountCode
                       + N' o ya fue eliminada.';
        RETURN;
    END;

    -- Verificar que no tenga cuentas hijas activas
    IF EXISTS (
        SELECT 1
        FROM   acct.Account
        WHERE  CompanyId       = @CompanyId
          AND  ParentAccountId = @AccountId
          AND  IsDeleted       = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'No se puede eliminar: la cuenta tiene cuentas hijas activas.';
        RETURN;
    END;

    BEGIN TRY
        UPDATE acct.Account
        SET    IsDeleted = 1,
               IsActive  = 0,
               UpdatedAt = SYSUTCDATETIME()
        WHERE  AccountId = @AccountId
          AND  IsDeleted = 0;

        SET @Resultado = 1;
        SET @Mensaje   = N'Cuenta ' + @AccountCode + N' eliminada exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al eliminar cuenta: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 6: usp_Acct_Infra_Check
--  Descripcion : Verifica si las tablas de contabilidad existen.
--  Retorna     : Una fila con columna 'ok' (1 o 0).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Infra_Check
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CASE WHEN
        OBJECT_ID('acct.Account', 'U') IS NOT NULL
        AND OBJECT_ID('acct.JournalEntry', 'U') IS NOT NULL
        AND OBJECT_ID('acct.JournalEntryLine', 'U') IS NOT NULL
    THEN 1 ELSE 0 END AS ok;
END;
GO

-- =============================================================================
--  SP 7: usp_Acct_Account_Exists
--  Descripcion : Verifica si una cuenta existe por su codigo.
--  Parametros  :
--    @CompanyId    INT            - ID de la empresa.
--    @AccountCode  NVARCHAR(40)   - Codigo de la cuenta.
--  Retorna     : Una fila con columna 'ok' (1 o 0).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Account_Exists
    @CompanyId    INT,
    @AccountCode  NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CASE WHEN EXISTS (
        SELECT 1
        FROM acct.Account
        WHERE CompanyId = @CompanyId
          AND LTRIM(RTRIM(AccountCode)) = LTRIM(RTRIM(@AccountCode))
          AND IsDeleted = 0
    ) THEN 1 ELSE 0 END AS ok;
END;
GO

-- =============================================================================
--  SP 8: usp_Acct_Policy_Load
--  Descripcion : Carga las politicas contables para un modulo de ventas.
--  Parametros  :
--    @CompanyId  INT            - ID de la empresa.
--    @Module     NVARCHAR(40)   - Codigo del modulo (POS, RESTAURANTE).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Policy_Load
    @CompanyId  INT,
    @Module     NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProcessCode       AS Proceso,
        CASE WHEN p.Nature = 'DEBIT' THEN N'DEBE' ELSE N'HABER' END AS Naturaleza,
        a.AccountCode       AS CuentaContable,
        CAST(NULL AS NVARCHAR(20)) AS CentroCostoDefault
    FROM acct.AccountingPolicy p
    INNER JOIN acct.Account a ON a.AccountId = p.AccountId
    WHERE p.CompanyId = @CompanyId
      AND p.ModuleCode = @Module
      AND p.IsActive = 1
      AND p.ProcessCode IN ('VENTA_TOTAL', 'VENTA_TOTAL_CAJA', 'VENTA_TOTAL_BANCO', 'VENTA_BASE', 'VENTA_IVA')
    ORDER BY p.PriorityOrder, p.AccountingPolicyId;
END;
GO

-- =============================================================================
--  SP 9: usp_Acct_Entry_FindByOrigin
--  Descripcion : Busca un asiento contable existente por origen (modulo + doc).
--  Parametros  :
--    @CompanyId       INT            - ID de la empresa.
--    @BranchId        INT            - ID de la sucursal.
--    @Module          NVARCHAR(40)   - Modulo origen (POS, RESTAURANTE).
--    @OriginDocument  NVARCHAR(120)  - Documento de origen.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_FindByOrigin
    @CompanyId       INT,
    @BranchId        INT,
    @Module          NVARCHAR(40),
    @OriginDocument  NVARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        je.JournalEntryId AS asientoId,
        je.EntryNumber    AS numeroAsiento
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.SourceModule = @Module
      AND je.SourceDocumentNo = @OriginDocument
      AND je.IsDeleted = 0
    ORDER BY je.JournalEntryId DESC;
END;
GO

-- =============================================================================
--  SP 10: usp_Acct_Entry_ResolveIdBySource
--  Descripcion : Resuelve el JournalEntryId por modulo/documento origen.
--  Parametros  :
--    @CompanyId       INT            - ID de la empresa.
--    @BranchId        INT            - ID de la sucursal.
--    @Module          NVARCHAR(40)   - Modulo origen.
--    @OriginDocument  NVARCHAR(120)  - Documento de origen.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_ResolveIdBySource
    @CompanyId       INT,
    @BranchId        INT,
    @Module          NVARCHAR(40),
    @OriginDocument  NVARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        CAST(je.JournalEntryId AS BIGINT) AS journalEntryId
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.SourceModule = @Module
      AND je.SourceDocumentNo = @OriginDocument
      AND je.IsDeleted = 0
    ORDER BY je.JournalEntryId DESC;
END;
GO

-- =============================================================================
--  SP 11: usp_Acct_DocumentLink_Upsert
--  Descripcion : Inserta un link de documento contable si no existe.
--  Parametros  :
--    @CompanyId       INT            - ID de la empresa.
--    @BranchId        INT            - ID de la sucursal.
--    @Module          NVARCHAR(40)   - Modulo (POS, RESTAURANTE).
--    @DocumentType    NVARCHAR(40)   - Tipo de documento.
--    @OriginDocument  NVARCHAR(120)  - Numero de documento.
--    @JournalEntryId  BIGINT         - ID del asiento contable.
--    @Resultado       INT OUTPUT     - 1=insertado, 0=ya existia.
--    @Mensaje         NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_DocumentLink_Upsert
    @CompanyId       INT,
    @BranchId        INT,
    @Module          NVARCHAR(40),
    @DocumentType    NVARCHAR(40),
    @OriginDocument  NVARCHAR(120),
    @JournalEntryId  BIGINT,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF EXISTS (
        SELECT 1
        FROM acct.DocumentLink
        WHERE CompanyId = @CompanyId
          AND BranchId = @BranchId
          AND ModuleCode = @Module
          AND DocumentType = @DocumentType
          AND DocumentNumber = @OriginDocument
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'El enlace de documento ya existe.';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO acct.DocumentLink (
            CompanyId,
            BranchId,
            ModuleCode,
            DocumentType,
            DocumentNumber,
            NativeDocumentId,
            JournalEntryId
        )
        VALUES (
            @CompanyId,
            @BranchId,
            @Module,
            @DocumentType,
            @OriginDocument,
            NULL,
            @JournalEntryId
        );

        SET @Resultado = 1;
        SET @Mensaje   = N'Enlace de documento creado exitosamente.';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al insertar enlace: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 12: usp_Acct_Pos_GetHeader
--  Descripcion : Obtiene la cabecera de una venta POS para contabilizacion.
--  Parametros  :
--    @SaleTicketId  INT  - ID de la venta POS.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Pos_GetHeader
    @SaleTicketId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        v.SaleTicketId   AS id,
        v.InvoiceNumber  AS numFactura,
        v.SoldAt         AS fechaVenta,
        v.PaymentMethod  AS metodoPago,
        u.UserCode       AS codUsuario,
        v.NetAmount      AS subtotal,
        v.TaxAmount      AS impuestos,
        v.TotalAmount    AS total
    FROM pos.SaleTicket v
    LEFT JOIN sec.[User] u ON u.UserId = v.SoldByUserId
    WHERE v.SaleTicketId = @SaleTicketId;
END;
GO

-- =============================================================================
--  SP 13: usp_Acct_Pos_GetTaxSummary
--  Descripcion : Obtiene resumen de impuestos por tasa de una venta POS.
--  Parametros  :
--    @SaleTicketId  INT  - ID de la venta POS.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Pos_GetTaxSummary
    @SaleTicketId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TaxRate       AS taxRate,
        SUM(NetAmount)   AS baseAmount,
        SUM(TaxAmount)   AS taxAmount,
        SUM(TotalAmount) AS totalAmount
    FROM pos.SaleTicketLine
    WHERE SaleTicketId = @SaleTicketId
    GROUP BY TaxRate;
END;
GO

-- =============================================================================
--  SP 14: usp_Acct_Rest_GetHeader
--  Descripcion : Obtiene la cabecera de un pedido restaurante para contabilizacion.
--  Parametros  :
--    @OrderTicketId  INT  - ID del pedido.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Rest_GetHeader
    @OrderTicketId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        o.OrderTicketId  AS id,
        o.TotalAmount    AS total,
        o.ClosedAt       AS fechaCierre,
        COALESCE(uClose.UserCode, uOpen.UserCode) AS codUsuario
    FROM rest.OrderTicket o
    LEFT JOIN sec.[User] uOpen  ON uOpen.UserId  = o.OpenedByUserId
    LEFT JOIN sec.[User] uClose ON uClose.UserId = o.ClosedByUserId
    WHERE o.OrderTicketId = @OrderTicketId;
END;
GO

-- =============================================================================
--  SP 15: usp_Acct_Rest_GetTaxSummary
--  Descripcion : Obtiene resumen de impuestos por tasa de un pedido restaurante.
--  Parametros  :
--    @OrderTicketId  INT  - ID del pedido.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Rest_GetTaxSummary
    @OrderTicketId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TaxRate       AS taxRate,
        SUM(NetAmount)   AS baseAmount,
        SUM(TaxAmount)   AS taxAmount,
        SUM(TotalAmount) AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @OrderTicketId
    GROUP BY TaxRate;
END;
GO

-- =============================================================================
--  SP 16: usp_Acct_Entry_List
--  Descripcion : Lista paginada de asientos contables con filtros opcionales.
--  Parametros  :
--    @CompanyId        INT            - ID de la empresa (obligatorio).
--    @BranchId         INT            - ID de la sucursal (obligatorio).
--    @FechaDesde       DATE           - Fecha inicio (opcional).
--    @FechaHasta       DATE           - Fecha fin (opcional).
--    @TipoAsiento      NVARCHAR(20)   - Tipo de asiento (opcional).
--    @Estado           NVARCHAR(20)   - Estado del asiento (opcional).
--    @OrigenModulo     NVARCHAR(40)   - Modulo de origen (opcional).
--    @OrigenDocumento  NVARCHAR(120)  - Documento de origen (opcional).
--    @Page             INT            - Numero de pagina (default 1).
--    @Limit            INT            - Registros por pagina (default 50).
--    @TotalCount       INT OUTPUT     - Total de registros que cumplen los filtros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_List
    @CompanyId        INT,
    @BranchId         INT,
    @FechaDesde       DATE           = NULL,
    @FechaHasta       DATE           = NULL,
    @TipoAsiento      NVARCHAR(20)   = NULL,
    @Estado           NVARCHAR(20)   = NULL,
    @OrigenModulo     NVARCHAR(40)   = NULL,
    @OrigenDocumento  NVARCHAR(120)  = NULL,
    @Page             INT            = 1,
    @Limit            INT            = 50,
    @TotalCount       INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1  SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    SELECT @TotalCount = COUNT(1)
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND (@FechaDesde IS NULL OR je.EntryDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR je.EntryDate <= @FechaHasta)
      AND (@TipoAsiento IS NULL OR je.EntryType = @TipoAsiento)
      AND (@Estado IS NULL OR je.Status = @Estado)
      AND (@OrigenModulo IS NULL OR je.SourceModule = @OrigenModulo)
      AND (@OrigenDocumento IS NULL OR je.SourceDocumentNo = @OrigenDocumento);

    SELECT
        je.JournalEntryId    AS asientoId,
        je.EntryNumber       AS numeroAsiento,
        je.EntryDate         AS fecha,
        je.EntryType         AS tipoAsiento,
        je.ReferenceNumber   AS referencia,
        je.Concept           AS concepto,
        je.CurrencyCode      AS moneda,
        je.ExchangeRate      AS tasa,
        je.TotalDebit        AS totalDebe,
        je.TotalCredit       AS totalHaber,
        je.Status            AS estado,
        je.SourceModule      AS origenModulo,
        je.SourceDocumentNo  AS origenDocumento,
        je.CreatedAt
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND (@FechaDesde IS NULL OR je.EntryDate >= @FechaDesde)
      AND (@FechaHasta IS NULL OR je.EntryDate <= @FechaHasta)
      AND (@TipoAsiento IS NULL OR je.EntryType = @TipoAsiento)
      AND (@Estado IS NULL OR je.Status = @Estado)
      AND (@OrigenModulo IS NULL OR je.SourceModule = @OrigenModulo)
      AND (@OrigenDocumento IS NULL OR je.SourceDocumentNo = @OrigenDocumento)
    ORDER BY je.EntryDate DESC, je.JournalEntryId DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  SP 17: usp_Acct_Entry_Get
--  Descripcion : Obtiene la cabecera de un asiento contable por su ID.
--  Parametros  :
--    @CompanyId     INT    - ID de la empresa.
--    @BranchId      INT    - ID de la sucursal.
--    @AsientoId     BIGINT - ID del asiento.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_Get
    @CompanyId   INT,
    @BranchId    INT,
    @AsientoId   BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        je.JournalEntryId    AS asientoId,
        je.EntryNumber       AS numeroAsiento,
        je.EntryDate         AS fecha,
        je.EntryType         AS tipoAsiento,
        je.ReferenceNumber   AS referencia,
        je.Concept           AS concepto,
        je.CurrencyCode      AS moneda,
        je.ExchangeRate      AS tasa,
        je.TotalDebit        AS totalDebe,
        je.TotalCredit       AS totalHaber,
        je.Status            AS estado,
        je.SourceModule      AS origenModulo,
        je.SourceDocumentNo  AS origenDocumento,
        je.CreatedAt
    FROM acct.JournalEntry je
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.JournalEntryId = @AsientoId
      AND je.IsDeleted = 0;
END;
GO

-- =============================================================================
--  SP 18: usp_Acct_Entry_GetDetail
--  Descripcion : Obtiene el detalle (lineas) de un asiento contable.
--  Parametros  :
--    @CompanyId     INT    - ID de la empresa.
--    @BranchId      INT    - ID de la sucursal.
--    @AsientoId     BIGINT - ID del asiento.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_GetDetail
    @CompanyId   INT,
    @BranchId    INT,
    @AsientoId   BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.JournalEntryLineId    AS detalleId,
        l.LineNumber             AS renglon,
        l.AccountCodeSnapshot    AS codCuenta,
        a.AccountName            AS nombreCuenta,
        l.Description            AS descripcion,
        l.CostCenterCode         AS centroCosto,
        l.AuxiliaryType          AS auxiliarTipo,
        l.AuxiliaryCode          AS auxiliarCodigo,
        l.SourceDocumentNo       AS documento,
        l.DebitAmount            AS debe,
        l.CreditAmount           AS haber
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.JournalEntryId = @AsientoId
    ORDER BY l.LineNumber, l.JournalEntryLineId;
END;
GO

-- =============================================================================
--  SP 19: usp_Acct_Entry_Insert
--  Descripcion : Crea un asiento contable completo (cabecera + lineas) en una
--                sola transaccion. Recibe las lineas como XML.
--  Parametros  :
--    @CompanyId          INT            - ID empresa.
--    @BranchId           INT            - ID sucursal.
--    @EntryNumber        NVARCHAR(40)   - Numero de asiento generado.
--    @EntryDate          DATE           - Fecha del asiento.
--    @PeriodCode         NVARCHAR(10)   - Codigo de periodo (YYYYMM).
--    @EntryType          NVARCHAR(20)   - Tipo de asiento.
--    @ReferenceNumber    NVARCHAR(120)  - Referencia (opcional).
--    @Concept            NVARCHAR(400)  - Concepto del asiento.
--    @CurrencyCode       CHAR(3)        - Moneda.
--    @ExchangeRate       DECIMAL(18,6)  - Tasa de cambio.
--    @TotalDebit         DECIMAL(18,2)  - Total debe.
--    @TotalCredit        DECIMAL(18,2)  - Total haber.
--    @SourceModule       NVARCHAR(40)   - Modulo origen (opcional).
--    @SourceDocumentNo   NVARCHAR(120)  - Documento origen (opcional).
--    @DetalleXml         XML            - XML con lineas del asiento.
--    @AsientoId          BIGINT OUTPUT  - ID del asiento creado.
--    @Resultado          INT OUTPUT     - 1=exito, 0=error.
--    @Mensaje            NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Entry_Insert','P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Entry_Insert;
GO
CREATE PROCEDURE dbo.usp_Acct_Entry_Insert
    @CompanyId          INT,
    @BranchId           INT,
    @EntryNumber        NVARCHAR(40),
    @EntryDate          DATE,
    @PeriodCode         NVARCHAR(10),
    @EntryType          NVARCHAR(20),
    @ReferenceNumber    NVARCHAR(120)  = NULL,
    @Concept            NVARCHAR(400),
    @CurrencyCode       CHAR(3)        = 'VES',
    @ExchangeRate       DECIMAL(18,6)  = 1.0,
    @TotalDebit         DECIMAL(18,2),
    @TotalCredit        DECIMAL(18,2),
    @SourceModule       NVARCHAR(40)   = NULL,
    @SourceDocumentNo   NVARCHAR(120)  = NULL,
    @DetalleXml         XML,
    @AsientoId          BIGINT         OUTPUT,
    @Resultado          INT            OUTPUT,
    @Mensaje            NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @AsientoId = 0;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Validar balance
    IF ABS(@TotalDebit - @TotalCredit) > 0.005
    BEGIN
        SET @Mensaje = N'Asiento desbalanceado: debe=' + CAST(@TotalDebit AS NVARCHAR)
                     + N' haber=' + CAST(@TotalCredit AS NVARCHAR);
        RETURN;
    END;

    -- Parsear XML de detalle
    DECLARE @Detalle TABLE (
        idx             INT IDENTITY(1,1),
        codCuenta       NVARCHAR(40),
        descripcion     NVARCHAR(300),
        centroCosto     NVARCHAR(20),
        auxiliarTipo    NVARCHAR(30),
        auxiliarCodigo  NVARCHAR(60),
        documento       NVARCHAR(120),
        debe            DECIMAL(18,2),
        haber           DECIMAL(18,2)
    );

    BEGIN TRY
        INSERT INTO @Detalle (codCuenta, descripcion, centroCosto, auxiliarTipo, auxiliarCodigo, documento, debe, haber)
        SELECT
            r.value('@codCuenta',      'NVARCHAR(40)'),
            r.value('@descripcion',    'NVARCHAR(300)'),
            r.value('@centroCosto',    'NVARCHAR(20)'),
            r.value('@auxiliarTipo',   'NVARCHAR(30)'),
            r.value('@auxiliarCodigo', 'NVARCHAR(60)'),
            r.value('@documento',      'NVARCHAR(120)'),
            ISNULL(r.value('@debe',    'DECIMAL(18,2)'), 0),
            ISNULL(r.value('@haber',   'DECIMAL(18,2)'), 0)
        FROM @DetalleXml.nodes('/rows/row') AS t(r);
    END TRY
    BEGIN CATCH
        SET @Mensaje = N'Error parseando XML de detalle: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH;

    IF NOT EXISTS (SELECT 1 FROM @Detalle)
    BEGIN
        SET @Mensaje = N'Detalle de asiento requerido';
        RETURN;
    END;

    -- Verificar que todas las cuentas existen (FOR XML PATH en vez de STRING_AGG)
    DECLARE @Missing NVARCHAR(500);
    SELECT @Missing = STUFF((
        SELECT ', ' + d.codCuenta
        FROM @Detalle d
        LEFT JOIN acct.Account a
            ON a.CompanyId = @CompanyId
           AND a.AccountCode = d.codCuenta
           AND a.IsDeleted = 0
        WHERE a.AccountId IS NULL
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(500)'), 1, 2, '');

    IF @Missing IS NOT NULL AND LEN(@Missing) > 0
    BEGIN
        SET @Mensaje = N'Cuentas no encontradas: ' + @Missing;
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insertar cabecera
        INSERT INTO acct.JournalEntry (
            CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType,
            ReferenceNumber, Concept, CurrencyCode, ExchangeRate,
            TotalDebit, TotalCredit, Status,
            SourceModule, SourceDocumentType, SourceDocumentNo,
            CreatedAt, UpdatedAt, IsDeleted
        )
        VALUES (
            @CompanyId, @BranchId, @EntryNumber, @EntryDate, @PeriodCode, @EntryType,
            @ReferenceNumber, @Concept, @CurrencyCode, @ExchangeRate,
            @TotalDebit, @TotalCredit, N'APPROVED',
            @SourceModule, @SourceModule, @SourceDocumentNo,
            SYSUTCDATETIME(), SYSUTCDATETIME(), 0
        );

        SET @AsientoId = SCOPE_IDENTITY();

        -- Insertar lineas
        INSERT INTO acct.JournalEntryLine (
            JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
            Description, DebitAmount, CreditAmount,
            AuxiliaryType, AuxiliaryCode, CostCenterCode, SourceDocumentNo,
            CreatedAt, UpdatedAt
        )
        SELECT
            @AsientoId,
            d.idx,
            a.AccountId,
            d.codCuenta,
            d.descripcion,
            d.debe,
            d.haber,
            d.auxiliarTipo,
            d.auxiliarCodigo,
            d.centroCosto,
            COALESCE(d.documento, @SourceDocumentNo),
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        FROM @Detalle d
        INNER JOIN acct.Account a
            ON a.CompanyId = @CompanyId
           AND a.AccountCode = d.codCuenta
           AND a.IsDeleted = 0;

        COMMIT TRANSACTION;

        SET @Resultado = 1;
        SET @Mensaje   = N'Asiento creado en modelo canonico';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @AsientoId = 0;
        SET @Resultado = 0;
        SET @Mensaje   = N'Error creando asiento canonico: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 20: usp_Acct_Entry_Void
--  Descripcion : Anula un asiento contable.
--  Parametros  :
--    @CompanyId   INT            - ID empresa.
--    @BranchId    INT            - ID sucursal.
--    @AsientoId   BIGINT         - ID del asiento a anular.
--    @Motivo      NVARCHAR(400)  - Motivo de la anulacion.
--    @Resultado   INT OUTPUT     - 1=exito, 0=error.
--    @Mensaje     NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Entry_Void
    @CompanyId   INT,
    @BranchId    INT,
    @AsientoId   BIGINT,
    @Motivo      NVARCHAR(400),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (
        SELECT 1
        FROM acct.JournalEntry
        WHERE CompanyId = @CompanyId
          AND BranchId = @BranchId
          AND JournalEntryId = @AsientoId
          AND IsDeleted = 0
    )
    BEGIN
        SET @Mensaje = N'Asiento no encontrado';
        RETURN;
    END;

    BEGIN TRY
        UPDATE acct.JournalEntry
        SET Status    = N'VOIDED',
            Concept   = CONCAT(
                ISNULL(Concept, ''),
                CASE WHEN ISNULL(Concept, '') = '' THEN '' ELSE ' | ' END,
                'ANULADO: ',
                @Motivo
            ),
            UpdatedAt = SYSUTCDATETIME()
        WHERE CompanyId = @CompanyId
          AND BranchId = @BranchId
          AND JournalEntryId = @AsientoId
          AND IsDeleted = 0;

        IF @@ROWCOUNT > 0
        BEGIN
            SET @Resultado = 1;
            SET @Mensaje   = N'Asiento anulado';
        END
        ELSE
        BEGIN
            SET @Mensaje = N'Asiento no encontrado';
        END;
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error al anular asiento: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 21: usp_Acct_Report_LibroMayor
--  Descripcion : Reporte de libro mayor (todas las cuentas con movimiento).
--  Parametros  :
--    @CompanyId   INT   - ID empresa.
--    @BranchId    INT   - ID sucursal.
--    @FechaDesde  DATE  - Fecha inicio.
--    @FechaHasta  DATE  - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_LibroMayor
    @CompanyId   INT,
    @BranchId    INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        je.EntryDate           AS fecha,
        je.EntryNumber         AS numeroAsiento,
        l.AccountCodeSnapshot  AS codCuenta,
        a.AccountName          AS cuenta,
        l.Description          AS descripcion,
        l.DebitAmount          AS debe,
        l.CreditAmount         AS haber,
        SUM(l.DebitAmount - l.CreditAmount) OVER (
            PARTITION BY l.AccountCodeSnapshot
            ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS saldo
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND je.Status <> 'VOIDED'
      AND je.EntryDate >= @FechaDesde
      AND je.EntryDate <= @FechaHasta
    ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber;
END;
GO

-- =============================================================================
--  SP 22: usp_Acct_Report_MayorAnalitico
--  Descripcion : Reporte de mayor analitico para una cuenta especifica.
--  Parametros  :
--    @CompanyId   INT           - ID empresa.
--    @BranchId    INT           - ID sucursal.
--    @CodCuenta   NVARCHAR(40)  - Codigo de cuenta.
--    @FechaDesde  DATE          - Fecha inicio.
--    @FechaHasta  DATE          - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_MayorAnalitico
    @CompanyId   INT,
    @BranchId    INT,
    @CodCuenta   NVARCHAR(40),
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        je.EntryDate           AS fecha,
        je.EntryNumber         AS numeroAsiento,
        l.LineNumber           AS renglon,
        l.Description          AS descripcion,
        l.DebitAmount          AS debe,
        l.CreditAmount         AS haber,
        SUM(l.DebitAmount - l.CreditAmount) OVER (
            ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS saldo
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND je.Status <> 'VOIDED'
      AND l.AccountCodeSnapshot = @CodCuenta
      AND je.EntryDate >= @FechaDesde
      AND je.EntryDate <= @FechaHasta
    ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber;
END;
GO

-- =============================================================================
--  SP 23: usp_Acct_Report_BalanceComprobacion
--  Descripcion : Reporte de balance de comprobacion.
--  Parametros  :
--    @CompanyId   INT   - ID empresa.
--    @BranchId    INT   - ID sucursal.
--    @FechaDesde  DATE  - Fecha inicio.
--    @FechaHasta  DATE  - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_BalanceComprobacion
    @CompanyId   INT,
    @BranchId    INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.AccountCodeSnapshot  AS codCuenta,
        MAX(a.AccountName)     AS cuenta,
        SUM(l.DebitAmount)     AS totalDebe,
        SUM(l.CreditAmount)    AS totalHaber,
        SUM(l.DebitAmount - l.CreditAmount) AS saldo
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND je.Status <> 'VOIDED'
      AND je.EntryDate >= @FechaDesde
      AND je.EntryDate <= @FechaHasta
    GROUP BY l.AccountCodeSnapshot
    ORDER BY l.AccountCodeSnapshot;
END;
GO

-- =============================================================================
--  SP 24: usp_Acct_Report_EstadoResultados
--  Descripcion : Reporte de estado de resultados (ingresos y gastos).
--  Parametros  :
--    @CompanyId   INT   - ID empresa.
--    @BranchId    INT   - ID sucursal.
--    @FechaDesde  DATE  - Fecha inicio.
--    @FechaHasta  DATE  - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_EstadoResultados
    @CompanyId   INT,
    @BranchId    INT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.AccountCodeSnapshot  AS codCuenta,
        MAX(a.AccountName)     AS cuenta,
        MAX(a.AccountType)     AS tipo,
        SUM(l.DebitAmount)     AS totalDebe,
        SUM(l.CreditAmount)    AS totalHaber,
        CASE
            WHEN MAX(a.AccountType) = 'I' THEN SUM(l.CreditAmount - l.DebitAmount)
            WHEN MAX(a.AccountType) = 'G' THEN SUM(l.DebitAmount - l.CreditAmount)
            ELSE 0
        END AS monto
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    INNER JOIN acct.Account a ON a.AccountId = l.AccountId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND je.Status <> 'VOIDED'
      AND a.AccountType IN ('I', 'G')
      AND je.EntryDate >= @FechaDesde
      AND je.EntryDate <= @FechaHasta
    GROUP BY l.AccountCodeSnapshot
    ORDER BY l.AccountCodeSnapshot;
END;
GO

-- =============================================================================
--  SP 25: usp_Acct_Report_BalanceGeneral
--  Descripcion : Reporte de balance general (activos, pasivos, patrimonio).
--  Parametros  :
--    @CompanyId   INT   - ID empresa.
--    @BranchId    INT   - ID sucursal.
--    @FechaCorte  DATE  - Fecha de corte.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_BalanceGeneral
    @CompanyId   INT,
    @BranchId    INT,
    @FechaCorte  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.AccountCodeSnapshot  AS codCuenta,
        MAX(a.AccountName)     AS cuenta,
        MAX(a.AccountType)     AS tipo,
        SUM(l.DebitAmount)     AS totalDebe,
        SUM(l.CreditAmount)    AS totalHaber,
        CASE
            WHEN MAX(a.AccountType) = 'A' THEN SUM(l.DebitAmount - l.CreditAmount)
            WHEN MAX(a.AccountType) IN ('P','C') THEN SUM(l.CreditAmount - l.DebitAmount)
            ELSE 0
        END AS saldo
    FROM acct.JournalEntryLine l
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
    INNER JOIN acct.Account a ON a.AccountId = l.AccountId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId = @BranchId
      AND je.IsDeleted = 0
      AND je.Status <> 'VOIDED'
      AND a.AccountType IN ('A', 'P', 'C')
      AND je.EntryDate <= @FechaCorte
    GROUP BY l.AccountCodeSnapshot
    ORDER BY l.AccountCodeSnapshot;
END;
GO

-- =============================================================================
--  SP 26: usp_Acct_SeedPlanCuentas
--  Descripcion : Siembra el plan de cuentas base para una empresa.
--  Parametros  :
--    @CompanyId     INT  - ID empresa.
--    @SystemUserId  INT  - ID usuario SYSTEM (opcional).
--    @Resultado     INT OUTPUT     - 1=exito, 0=error.
--    @Mensaje       NVARCHAR(500) OUTPUT - Mensaje descriptivo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_SeedPlanCuentas
    @CompanyId     INT,
    @SystemUserId  INT           = NULL,
    @Resultado     INT           OUTPUT,
    @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @CompanyId IS NULL OR @CompanyId <= 0
    BEGIN
        SET @Mensaje = N'No existe cfg.Company DEFAULT para sembrar plan de cuentas';
        RETURN;
    END;

    DECLARE @Plan TABLE (
        AccountCode   NVARCHAR(40)  NOT NULL,
        AccountName   NVARCHAR(200) NOT NULL,
        AccountType   NCHAR(1)      NOT NULL,
        AccountLevel  INT           NOT NULL,
        ParentCode    NVARCHAR(40)  NULL,
        AllowsPosting BIT           NOT NULL
    );

    INSERT INTO @Plan (AccountCode, AccountName, AccountType, AccountLevel, ParentCode, AllowsPosting)
    VALUES
        (N'1',       N'ACTIVO',                    N'A', 1, NULL,   0),
        (N'1.1',     N'ACTIVO CORRIENTE',           N'A', 2, N'1',   0),
        (N'1.2',     N'ACTIVO NO CORRIENTE',        N'A', 2, N'1',   0),
        (N'1.1.01',  N'CAJA',                       N'A', 3, N'1.1', 1),
        (N'1.1.02',  N'BANCOS',                     N'A', 3, N'1.1', 1),
        (N'1.1.03',  N'INVERSIONES TEMPORALES',     N'A', 3, N'1.1', 1),
        (N'1.1.04',  N'CLIENTES',                   N'A', 3, N'1.1', 1),
        (N'1.1.05',  N'DOCUMENTOS POR COBRAR',      N'A', 3, N'1.1', 1),
        (N'1.1.06',  N'INVENTARIOS',                N'A', 3, N'1.1', 1),
        (N'1.2.01',  N'PROPIEDAD PLANTA Y EQUIPO',  N'A', 3, N'1.2', 1),
        (N'1.2.02',  N'DEPRECIACION ACUMULADA',     N'A', 3, N'1.2', 1),
        (N'2',       N'PASIVO',                     N'P', 1, NULL,   0),
        (N'2.1',     N'PASIVO CORRIENTE',           N'P', 2, N'2',   0),
        (N'2.2',     N'PASIVO NO CORRIENTE',        N'P', 2, N'2',   0),
        (N'2.1.01',  N'PROVEEDORES',                N'P', 3, N'2.1', 1),
        (N'2.1.02',  N'DOCUMENTOS POR PAGAR',       N'P', 3, N'2.1', 1),
        (N'2.1.03',  N'IMPUESTOS POR PAGAR',        N'P', 3, N'2.1', 1),
        (N'2.1.04',  N'SUELDOS POR PAGAR',          N'P', 3, N'2.1', 1),
        (N'3',       N'PATRIMONIO',                 N'C', 1, NULL,   0),
        (N'3.1',     N'CAPITAL SOCIAL',             N'C', 2, N'3',   0),
        (N'3.1.01',  N'CAPITAL SUSCRITO',           N'C', 3, N'3.1', 1),
        (N'4',       N'INGRESOS',                   N'I', 1, NULL,   0),
        (N'4.1',     N'INGRESOS OPERACIONALES',     N'I', 2, N'4',   0),
        (N'4.1.01',  N'VENTAS',                     N'I', 3, N'4.1', 1),
        (N'4.1.02',  N'DESCUENTOS EN VENTAS',       N'I', 3, N'4.1', 1),
        (N'5',       N'COSTOS Y GASTOS',            N'G', 1, NULL,   0),
        (N'5.1',     N'COSTO DE VENTAS',            N'G', 2, N'5',   0),
        (N'5.2',     N'GASTOS OPERACIONALES',       N'G', 2, N'5',   0),
        (N'5.1.01',  N'COSTO DE MERCADERIA',        N'G', 3, N'5.1', 1),
        (N'5.2.01',  N'SUELDOS Y SALARIOS',         N'G', 3, N'5.2', 1),
        (N'5.2.02',  N'ALQUILERES',                 N'G', 3, N'5.2', 1),
        (N'5.2.03',  N'DEPRECIACION',               N'G', 3, N'5.2', 1);

    BEGIN TRY
        DECLARE @Inserted INT = 1;
        WHILE @Inserted > 0
        BEGIN
            INSERT INTO acct.Account (
                CompanyId, AccountCode, AccountName, AccountType, AccountLevel,
                ParentAccountId, AllowsPosting, RequiresAuxiliary,
                IsActive, CreatedAt, UpdatedAt, CreatedByUserId, UpdatedByUserId, IsDeleted
            )
            SELECT
                @CompanyId,
                p.AccountCode,
                p.AccountName,
                p.AccountType,
                p.AccountLevel,
                parent.AccountId,
                p.AllowsPosting,
                0,
                1,
                SYSUTCDATETIME(),
                SYSUTCDATETIME(),
                @SystemUserId,
                @SystemUserId,
                0
            FROM @Plan p
            LEFT JOIN acct.Account existing
                ON existing.CompanyId   = @CompanyId
               AND existing.AccountCode = p.AccountCode
            LEFT JOIN acct.Account parent
                ON parent.CompanyId   = @CompanyId
               AND parent.AccountCode = p.ParentCode
            WHERE existing.AccountId IS NULL
              AND (p.ParentCode IS NULL OR parent.AccountId IS NOT NULL);

            SET @Inserted = @@ROWCOUNT;
        END;

        SET @Resultado = 1;
        SET @Mensaje   = N'Plan de cuentas canonico listo';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje   = N'Error sembrando plan de cuentas: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 27: usp_Acct_Scope_GetDefault
--  Descripcion : Obtiene el CompanyId y BranchId por defecto (DEFAULT/MAIN).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Scope_GetDefault
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        c.CompanyId,
        b.BranchId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId
    WHERE c.IsDeleted = 0
      AND b.IsDeleted = 0
    ORDER BY
        CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId,
        CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId;
END;
GO

-- =============================================================================
--  SP 28: usp_Acct_Scope_GetDefaultForSeed
--  Descripcion : Obtiene CompanyId, BranchId y SystemUserId para seed.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Scope_GetDefaultForSeed
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        c.CompanyId,
        b.BranchId,
        u.UserId AS SystemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] u ON u.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT';
END;
GO

-- =============================================================================
--  SP 29: usp_Acct_Report_LibroDiario
--  Descripcion : Reporte de Libro Diario. Lista todas las lineas de asientos
--                contables para un rango de fechas, agrupadas por asiento.
--  Parametros  :
--    @CompanyId   BIGINT - ID empresa.
--    @BranchId    BIGINT - ID sucursal.
--    @FechaDesde  DATE   - Fecha inicio.
--    @FechaHasta  DATE   - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Report_LibroDiario
    @CompanyId   BIGINT,
    @BranchId    BIGINT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CONVERT(VARCHAR(10), je.EntryDate, 120) AS fecha,
        je.JournalEntryId AS asientoId,
        je.EntryNumber     AS numeroAsiento,
        je.EntryType       AS tipoAsiento,
        je.Concept         AS concepto,
        je.Status          AS estado,
        jel.LineNumber     AS renglon,
        jel.AccountCodeSnapshot AS codCuenta,
        ISNULL(a.AccountName, jel.Description) AS descripcionCuenta,
        jel.Description    AS descripcionLinea,
        jel.DebitAmount    AS debe,
        jel.CreditAmount   AS haber,
        jel.CostCenterCode AS centroCosto
    FROM acct.JournalEntry je
    INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
    LEFT JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
    WHERE je.CompanyId = @CompanyId
      AND je.BranchId  = @BranchId
      AND je.EntryDate >= @FechaDesde
      AND je.EntryDate <= @FechaHasta
      AND je.IsDeleted  = 0
      AND je.Status    <> 'VOIDED'
    ORDER BY je.EntryDate, je.JournalEntryId, jel.LineNumber;
END;
GO

-- =============================================================================
--  SP 30: usp_Acct_Dashboard_Resumen
--  Descripcion : Resumen de dashboard del modulo contable. Retorna un unico
--                recordset con datos agregados (ingresos, gastos, cuentas por
--                pagar, conteos de asientos y cuentas).
--  Parametros  :
--    @CompanyId   BIGINT - ID empresa.
--    @BranchId    BIGINT - ID sucursal.
--    @FechaDesde  DATE   - Fecha inicio.
--    @FechaHasta  DATE   - Fecha fin.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Acct_Dashboard_Resumen
    @CompanyId   BIGINT,
    @BranchId    BIGINT,
    @FechaDesde  DATE,
    @FechaHasta  DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate totals from journal entry lines
    DECLARE @totalIngresos DECIMAL(18,2) = 0;
    DECLARE @totalGastos   DECIMAL(18,2) = 0;
    DECLARE @cuentasPorPagar DECIMAL(18,2) = 0;
    DECLARE @totalAsientos INT = 0;
    DECLARE @totalCuentas  INT = 0;
    DECLARE @totalAnulados INT = 0;

    -- Total Ingresos (account type I = Ingresos) - credit side
    SELECT @totalIngresos = ISNULL(SUM(jel.CreditAmount - jel.DebitAmount), 0)
    FROM acct.JournalEntry je
    INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
    INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
    WHERE je.CompanyId = @CompanyId AND je.BranchId = @BranchId
      AND je.EntryDate >= @FechaDesde AND je.EntryDate <= @FechaHasta
      AND je.IsDeleted = 0 AND je.Status <> 'VOIDED'
      AND a.AccountType = 'I';

    -- Total Gastos (account type G = Gastos) - debit side
    SELECT @totalGastos = ISNULL(SUM(jel.DebitAmount - jel.CreditAmount), 0)
    FROM acct.JournalEntry je
    INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
    INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
    WHERE je.CompanyId = @CompanyId AND je.BranchId = @BranchId
      AND je.EntryDate >= @FechaDesde AND je.EntryDate <= @FechaHasta
      AND je.IsDeleted = 0 AND je.Status <> 'VOIDED'
      AND a.AccountType = 'G';

    -- Cuentas por pagar (account type P, code starts with '2.1')
    SELECT @cuentasPorPagar = ISNULL(SUM(jel.CreditAmount - jel.DebitAmount), 0)
    FROM acct.JournalEntry je
    INNER JOIN acct.JournalEntryLine jel ON jel.JournalEntryId = je.JournalEntryId
    INNER JOIN acct.Account a ON a.AccountId = jel.AccountId AND a.CompanyId = @CompanyId
    WHERE je.CompanyId = @CompanyId AND je.BranchId = @BranchId
      AND je.EntryDate >= @FechaDesde AND je.EntryDate <= @FechaHasta
      AND je.IsDeleted = 0 AND je.Status <> 'VOIDED'
      AND a.AccountType = 'P' AND a.AccountCode LIKE '2.1%';

    -- Counts
    SELECT @totalAsientos = COUNT(*)
    FROM acct.JournalEntry
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND EntryDate >= @FechaDesde AND EntryDate <= @FechaHasta
      AND IsDeleted = 0 AND Status <> 'VOIDED';

    SELECT @totalAnulados = COUNT(*)
    FROM acct.JournalEntry
    WHERE CompanyId = @CompanyId AND BranchId = @BranchId
      AND EntryDate >= @FechaDesde AND EntryDate <= @FechaHasta
      AND IsDeleted = 0 AND Status = 'VOIDED';

    SELECT @totalCuentas = COUNT(*)
    FROM acct.Account
    WHERE CompanyId = @CompanyId AND IsDeleted = 0 AND IsActive = 1;

    -- Return single row with all dashboard data
    SELECT
        @totalIngresos   AS totalIngresos,
        @totalGastos     AS totalGastos,
        CASE WHEN @totalIngresos > 0
             THEN ROUND((@totalIngresos - @totalGastos) / @totalIngresos * 100, 2)
             ELSE 0
        END              AS margenPorcentaje,
        @cuentasPorPagar AS cuentasPorPagar,
        @totalAsientos   AS totalAsientos,
        @totalCuentas    AS totalCuentas,
        @totalAnulados   AS totalAnulados;
END;
GO

PRINT 'usp_acct.sql: 30 procedimientos de contabilidad creados/actualizados exitosamente.';
GO
