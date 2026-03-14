/*
 * ============================================================================
 *  Archivo : usp_pay.sql
 *  Esquema : pay (gateway de pagos y configuracion)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados para gestion de configuracion de medios de pago,
 *    proveedores, capacidades, configuracion por empresa y dispositivos lectores.
 *
 *    - usp_Pay_Method_List                  : Lista metodos de pago con filtro por pais.
 *    - usp_Pay_Method_Upsert               : Inserta o actualiza metodo de pago.
 *    - usp_Pay_Provider_List               : Lista proveedores activos.
 *    - usp_Pay_Provider_Get                : Obtiene un proveedor por su codigo.
 *    - usp_Pay_Provider_GetCapabilities    : Obtiene capacidades de un proveedor.
 *    - usp_Pay_CompanyConfig_List          : Lista configuracion de pago por empresa (legacy).
 *    - usp_Pay_CompanyConfig_ListByCompany : Lista config por empresa con filtro opcional de sucursal.
 *    - usp_Pay_CompanyConfig_Upsert        : Inserta o actualiza config empresa (simple, legacy).
 *    - usp_Pay_CompanyConfig_UpsertFull    : Inserta o actualiza config con TODOS los campos.
 *    - usp_Pay_CompanyConfig_Deactivate    : Desactiva config por empresa + proveedor (legacy).
 *    - usp_Pay_CompanyConfig_DeactivateById: Desactiva config por Id.
 *    - usp_Pay_AcceptedMethod_List         : Lista metodos aceptados con filtros de canal.
 *    - usp_Pay_AcceptedMethod_Upsert       : Inserta o actualiza metodo aceptado (completo).
 *    - usp_Pay_AcceptedMethod_Deactivate   : Desactiva metodo aceptado por Id.
 *    - usp_Pay_CardReader_List             : Lista dispositivos lectores (legacy).
 *    - usp_Pay_CardReader_ListByCompany    : Lista dispositivos con filtro empresa + sucursal.
 *    - usp_Pay_CardReader_Upsert           : Inserta o actualiza dispositivo lector (completo).
 *
 *  Tablas principales:
 *    pay.PaymentMethods, pay.PaymentProviders, pay.ProviderCapabilities,
 *    pay.CompanyPaymentConfig, pay.AcceptedPaymentMethods, pay.CardReaderDevices
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Pay_Method_List
--  Descripcion : Lista los metodos de pago disponibles, con filtro opcional
--                por codigo de pais.
--  Parametros  :
--    @CountryCode  CHAR(2) = NULL  - Filtro por pais (NULL = todos).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_Method_List
    @CountryCode  CHAR(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id,
           Code,
           Name,
           Category,
           CountryCode,
           IconName,
           RequiresGateway,
           IsActive,
           SortOrder
    FROM   pay.PaymentMethods
    WHERE  IsActive = 1
      AND  (@CountryCode IS NULL
            OR CountryCode = @CountryCode
            OR CountryCode IS NULL)
    ORDER BY SortOrder, Name;
END;
GO

-- =============================================================================
--  SP 2: usp_Pay_Method_Upsert
--  Descripcion : Inserta un nuevo metodo de pago o actualiza uno existente
--                usando MERGE sobre el codigo del metodo + pais.
--  Parametros  :
--    @MethodCode      NVARCHAR(30)  - Codigo unico del metodo (obligatorio).
--    @MethodName      NVARCHAR(100) - Nombre descriptivo (obligatorio).
--    @CountryCode     CHAR(2)       - Codigo de pais (NULL = global).
--    @MethodType      NVARCHAR(30)  - Categoria/tipo del metodo (opcional).
--    @IsActive        BIT           - Activo/inactivo (default 1).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_Method_Upsert
    @MethodCode   NVARCHAR(30),
    @MethodName   NVARCHAR(100),
    @CountryCode  CHAR(2)       = NULL,
    @MethodType   NVARCHAR(30)  = NULL,
    @IsActive     BIT           = 1
AS
BEGIN
    SET NOCOUNT ON;

    MERGE pay.PaymentMethods AS target
    USING (
        SELECT @MethodCode  AS Code,
               @MethodName  AS Name,
               @CountryCode AS CountryCode,
               @MethodType  AS Category,
               @IsActive    AS IsActive
    ) AS source
    ON target.Code = source.Code
       AND ISNULL(target.CountryCode, '__') = ISNULL(source.CountryCode, '__')
    WHEN MATCHED THEN
        UPDATE SET Name      = source.Name,
                   Category  = COALESCE(source.Category, target.Category),
                   IsActive  = source.IsActive
    WHEN NOT MATCHED THEN
        INSERT (Code, Name, Category, CountryCode, IsActive)
        VALUES (source.Code, source.Name, source.Category, source.CountryCode, source.IsActive);
END;
GO

-- =============================================================================
--  SP 3: usp_Pay_Provider_List
--  Descripcion : Lista todos los proveedores de pago activos.
--  Parametros  : Ninguno.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_Provider_List
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id,
           Code,
           Name,
           CountryCode,
           ProviderType,
           BaseUrlSandbox,
           BaseUrlProd,
           AuthType,
           DocsUrl,
           LogoUrl,
           IsActive
    FROM   pay.PaymentProviders
    WHERE  IsActive = 1
    ORDER BY Name;
END;
GO

-- =============================================================================
--  SP 4: usp_Pay_Provider_Get
--  Descripcion : Obtiene un proveedor de pago especifico por su codigo.
--  Parametros  :
--    @ProviderCode  NVARCHAR(30) - Codigo del proveedor (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_Provider_Get
    @ProviderCode  NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
           Id,
           Code,
           Name,
           CountryCode,
           ProviderType,
           BaseUrlSandbox,
           BaseUrlProd,
           AuthType,
           DocsUrl,
           LogoUrl,
           IsActive,
           CreatedAt
    FROM   pay.PaymentProviders
    WHERE  Code = @ProviderCode;
END;
GO

-- =============================================================================
--  SP 5: usp_Pay_Provider_GetCapabilities
--  Descripcion : Obtiene las capacidades de un proveedor dado su codigo,
--                incluyendo informacion del proveedor mediante JOIN.
--  Parametros  :
--    @ProviderCode  NVARCHAR(30) - Codigo del proveedor (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_Provider_GetCapabilities
    @ProviderCode  NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.Code          AS ProviderCode,
           p.Name          AS ProviderName,
           p.ProviderType,
           c.Id            AS CapabilityId,
           c.Capability,
           c.PaymentMethod,
           c.EndpointPath,
           c.HttpMethod,
           c.IsActive
    FROM   pay.ProviderCapabilities c
    INNER JOIN pay.PaymentProviders p ON p.Id = c.ProviderId
    WHERE  p.Code = @ProviderCode
      AND  c.IsActive = 1
    ORDER BY c.Capability, c.PaymentMethod;
END;
GO

-- =============================================================================
--  SP 6: usp_Pay_CompanyConfig_List (legacy — usar ListByCompany preferentemente)
--  Descripcion : Lista la configuracion de proveedores de pago por empresa.
--  Parametros  :
--    @CompanyId  INT = NULL - ID de la empresa (opcional).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_List
    @CompanyId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT cc.Id,
           cc.EmpresaId,
           cc.SucursalId,
           cc.CountryCode,
           cc.ProviderId,
           p.Code           AS ProviderCode,
           p.Name           AS ProviderName,
           p.ProviderType,
           cc.Environment,
           cc.AutoCapture,
           cc.AllowRefunds,
           cc.MaxRefundDays,
           cc.IsActive,
           cc.CreatedAt,
           cc.UpdatedAt
    FROM   pay.CompanyPaymentConfig cc
    INNER JOIN pay.PaymentProviders p ON p.Id = cc.ProviderId
    WHERE  (@CompanyId IS NULL OR cc.EmpresaId = @CompanyId)
    ORDER BY cc.EmpresaId, p.Code;
END;
GO

-- =============================================================================
--  SP 6b: usp_Pay_CompanyConfig_ListByCompany
--  Descripcion : Lista la configuracion de proveedores de pago por empresa
--                con filtro opcional de sucursal. Incluye datos del proveedor.
--  Parametros  :
--    @CompanyId  INT       - ID de la empresa (obligatorio).
--    @BranchId   INT = NULL - ID de la sucursal (NULL = todas).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_ListByCompany
    @CompanyId  INT,
    @BranchId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT cc.Id,
           cc.EmpresaId,
           cc.SucursalId,
           cc.CountryCode,
           cc.ProviderId,
           p.Code           AS ProviderCode,
           p.Name           AS ProviderName,
           p.ProviderType,
           cc.Environment,
           cc.ClientId,
           cc.ClientSecret,
           cc.MerchantId,
           cc.TerminalId,
           cc.IntegratorId,
           cc.CertificatePath,
           cc.ExtraConfig,
           cc.AutoCapture,
           cc.AllowRefunds,
           cc.MaxRefundDays,
           cc.IsActive,
           cc.CreatedAt,
           cc.UpdatedAt
    FROM   pay.CompanyPaymentConfig cc
    INNER JOIN pay.PaymentProviders p ON p.Id = cc.ProviderId
    WHERE  cc.EmpresaId = @CompanyId
      AND  (@BranchId IS NULL OR cc.SucursalId = @BranchId)
    ORDER BY p.Name;
END;
GO

-- =============================================================================
--  SP 7: usp_Pay_CompanyConfig_Upsert (legacy — simple)
--  Descripcion : Inserta o actualiza la configuracion de un proveedor de pago
--                para una empresa. Usa MERGE sobre CompanyId + ProviderCode.
--  Parametros  :
--    @CompanyId     INT             - ID de la empresa (obligatorio).
--    @ProviderCode  NVARCHAR(30)    - Codigo del proveedor (obligatorio).
--    @IsActive      BIT             - Activo/inactivo (default 1).
--    @ConfigJson    NVARCHAR(MAX)   - JSON de configuracion adicional (opcional).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_Upsert
    @CompanyId     INT,
    @ProviderCode  NVARCHAR(30),
    @IsActive      BIT           = 1,
    @ConfigJson    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProviderId INT;
    SELECT @ProviderId = Id
    FROM   pay.PaymentProviders
    WHERE  Code = @ProviderCode;

    IF @ProviderId IS NULL
    BEGIN
        RAISERROR(N'Proveedor con codigo ''%s'' no encontrado.', 16, 1, @ProviderCode);
        RETURN;
    END;

    MERGE pay.CompanyPaymentConfig AS target
    USING (
        SELECT @CompanyId  AS EmpresaId,
               @ProviderId AS ProviderId,
               @IsActive   AS IsActive,
               @ConfigJson AS ExtraConfig
    ) AS source
    ON target.EmpresaId  = source.EmpresaId
       AND target.ProviderId = source.ProviderId
    WHEN MATCHED THEN
        UPDATE SET IsActive    = source.IsActive,
                   ExtraConfig = COALESCE(source.ExtraConfig, target.ExtraConfig),
                   UpdatedAt   = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (EmpresaId, SucursalId, CountryCode, ProviderId, IsActive, ExtraConfig, CreatedAt, UpdatedAt)
        VALUES (source.EmpresaId,
                0,
                ISNULL((SELECT TOP 1 CountryCode FROM pay.PaymentProviders WHERE Id = source.ProviderId), 'XX'),
                source.ProviderId,
                source.IsActive,
                source.ExtraConfig,
                GETDATE(),
                GETDATE());
END;
GO

-- =============================================================================
--  SP 7b: usp_Pay_CompanyConfig_UpsertFull
--  Descripcion : Inserta o actualiza la configuracion COMPLETA de un proveedor
--                de pago para una empresa+sucursal. Resuelve ProviderId
--                internamente desde @ProviderCode. Usa MERGE sobre
--                EmpresaId + SucursalId + ProviderId.
--  Parametros  :
--    @CompanyId       INT              - ID de la empresa (obligatorio).
--    @BranchId        INT              - ID de la sucursal (default 0).
--    @CountryCode     CHAR(2)          - Codigo de pais (obligatorio).
--    @ProviderCode    NVARCHAR(30)     - Codigo del proveedor (obligatorio).
--    @Environment     NVARCHAR(10)     - 'sandbox' o 'production' (default 'sandbox').
--    @ClientId        NVARCHAR(500)    - ID de cliente del proveedor.
--    @ClientSecret    NVARCHAR(500)    - Secreto del cliente.
--    @MerchantId      NVARCHAR(100)    - ID de comercio.
--    @TerminalId      NVARCHAR(100)    - ID de terminal.
--    @IntegratorId    NVARCHAR(50)     - ID de integrador.
--    @CertificatePath NVARCHAR(500)    - Ruta al certificado.
--    @ExtraConfig     NVARCHAR(MAX)    - JSON de configuracion adicional.
--    @AutoCapture     BIT              - Auto-captura (default 1).
--    @AllowRefunds    BIT              - Permitir devoluciones (default 1).
--    @MaxRefundDays   INT              - Dias maximos para devolucion (default 30).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_UpsertFull
    @CompanyId       INT,
    @BranchId        INT            = 0,
    @CountryCode     CHAR(2),
    @ProviderCode    NVARCHAR(30),
    @Environment     NVARCHAR(10)   = 'sandbox',
    @ClientId        NVARCHAR(500)  = NULL,
    @ClientSecret    NVARCHAR(500)  = NULL,
    @MerchantId      NVARCHAR(100)  = NULL,
    @TerminalId      NVARCHAR(100)  = NULL,
    @IntegratorId    NVARCHAR(50)   = NULL,
    @CertificatePath NVARCHAR(500)  = NULL,
    @ExtraConfig     NVARCHAR(MAX)  = NULL,
    @AutoCapture     BIT            = 1,
    @AllowRefunds    BIT            = 1,
    @MaxRefundDays   INT            = 30
AS
BEGIN
    SET NOCOUNT ON;

    -- Resolver ProviderId desde ProviderCode
    DECLARE @ProviderId INT;
    SELECT @ProviderId = Id
    FROM   pay.PaymentProviders
    WHERE  Code = @ProviderCode;

    IF @ProviderId IS NULL
    BEGIN
        RAISERROR(N'Proveedor con codigo ''%s'' no encontrado.', 16, 1, @ProviderCode);
        RETURN;
    END;

    MERGE pay.CompanyPaymentConfig AS target
    USING (
        SELECT @CompanyId  AS EmpresaId,
               @BranchId   AS SucursalId,
               @ProviderId AS ProviderId
    ) AS source
    ON  target.EmpresaId  = source.EmpresaId
    AND target.SucursalId = source.SucursalId
    AND target.ProviderId = source.ProviderId
    WHEN MATCHED THEN
        UPDATE SET CountryCode    = @CountryCode,
                   Environment    = @Environment,
                   ClientId       = COALESCE(@ClientId,       target.ClientId),
                   ClientSecret   = COALESCE(@ClientSecret,   target.ClientSecret),
                   MerchantId     = COALESCE(@MerchantId,     target.MerchantId),
                   TerminalId     = COALESCE(@TerminalId,     target.TerminalId),
                   IntegratorId   = COALESCE(@IntegratorId,   target.IntegratorId),
                   CertificatePath = COALESCE(@CertificatePath, target.CertificatePath),
                   ExtraConfig    = COALESCE(@ExtraConfig,    target.ExtraConfig),
                   AutoCapture    = @AutoCapture,
                   AllowRefunds   = @AllowRefunds,
                   MaxRefundDays  = @MaxRefundDays,
                   IsActive       = 1,
                   UpdatedAt      = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (EmpresaId, SucursalId, CountryCode, ProviderId, Environment,
                ClientId, ClientSecret, MerchantId, TerminalId, IntegratorId,
                CertificatePath, ExtraConfig, AutoCapture, AllowRefunds, MaxRefundDays,
                IsActive, CreatedAt, UpdatedAt)
        VALUES (@CompanyId, @BranchId, @CountryCode, @ProviderId, @Environment,
                @ClientId, @ClientSecret, @MerchantId, @TerminalId, @IntegratorId,
                @CertificatePath, @ExtraConfig, @AutoCapture, @AllowRefunds, @MaxRefundDays,
                1, GETDATE(), GETDATE());
END;
GO

-- =============================================================================
--  SP 8: usp_Pay_CompanyConfig_Deactivate (legacy — por empresa + proveedor)
--  Descripcion : Desactiva la configuracion de un proveedor para una empresa
--                sin eliminarla (soft deactivation).
--  Parametros  :
--    @CompanyId     INT          - ID de la empresa (obligatorio).
--    @ProviderCode  NVARCHAR(30) - Codigo del proveedor (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_Deactivate
    @CompanyId     INT,
    @ProviderCode  NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE cc
    SET    cc.IsActive  = 0,
           cc.UpdatedAt = GETDATE()
    FROM   pay.CompanyPaymentConfig cc
    INNER JOIN pay.PaymentProviders p ON p.Id = cc.ProviderId
    WHERE  cc.EmpresaId = @CompanyId
      AND  p.Code       = @ProviderCode;
END;
GO

-- =============================================================================
--  SP 8b: usp_Pay_CompanyConfig_DeactivateById
--  Descripcion : Desactiva una configuracion de pago especifica por su Id.
--  Parametros  :
--    @Id  INT - ID del registro en pay.CompanyPaymentConfig (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CompanyConfig_DeactivateById
    @Id  INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pay.CompanyPaymentConfig
    SET    IsActive  = 0,
           UpdatedAt = GETDATE()
    WHERE  Id = @Id;
END;
GO

-- =============================================================================
--  SP 9: usp_Pay_AcceptedMethod_List
--  Descripcion : Lista los metodos de pago aceptados por empresa, con filtros
--                opcionales de canal (POS, Web, Restaurante) y sucursal.
--                Incluye informacion del metodo y del proveedor mediante JOINs.
--  Parametros  :
--    @CompanyId          INT      - ID de la empresa (obligatorio).
--    @SucursalId         INT      - ID de la sucursal (NULL = todas).
--    @AppliesToPOS       BIT      - Filtrar por aplica a POS (NULL = sin filtro).
--    @AppliesToWeb       BIT      - Filtrar por aplica a Web (NULL = sin filtro).
--    @AppliesToRestaurant BIT     - Filtrar por aplica a Restaurante (NULL = sin filtro).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_AcceptedMethod_List
    @CompanyId           INT,
    @SucursalId          INT  = NULL,
    @AppliesToPOS        BIT  = NULL,
    @AppliesToWeb        BIT  = NULL,
    @AppliesToRestaurant BIT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT am.Id,
           am.EmpresaId,
           am.SucursalId,
           am.PaymentMethodId,
           m.Code           AS MethodCode,
           m.Name           AS MethodName,
           m.Category       AS MethodCategory,
           m.IconName,
           am.ProviderId,
           p.Code           AS ProviderCode,
           p.Name           AS ProviderName,
           am.AppliesToPOS,
           am.AppliesToWeb,
           am.AppliesToRestaurant,
           am.MinAmount,
           am.MaxAmount,
           am.CommissionPct,
           am.CommissionFixed,
           am.SortOrder,
           am.IsActive
    FROM   pay.AcceptedPaymentMethods am
    INNER JOIN pay.PaymentMethods m ON m.Id = am.PaymentMethodId
    LEFT  JOIN pay.PaymentProviders p ON p.Id = am.ProviderId
    WHERE  am.EmpresaId = @CompanyId
      AND  am.IsActive = 1
      AND  (@SucursalId IS NULL          OR am.SucursalId = @SucursalId)
      AND  (@AppliesToPOS IS NULL        OR am.AppliesToPOS = @AppliesToPOS)
      AND  (@AppliesToWeb IS NULL        OR am.AppliesToWeb = @AppliesToWeb)
      AND  (@AppliesToRestaurant IS NULL OR am.AppliesToRestaurant = @AppliesToRestaurant)
    ORDER BY am.SortOrder, m.Name;
END;
GO

-- =============================================================================
--  SP 10: usp_Pay_AcceptedMethod_Upsert
--  Descripcion : Inserta o actualiza un metodo de pago aceptado por una empresa.
--                Usa MERGE sobre EmpresaId + SucursalId + PaymentMethodId + ProviderId.
--                Acepta PaymentMethodId directamente (no resuelve por codigo).
--  Parametros  :
--    @CompanyId          INT              - ID de la empresa (obligatorio).
--    @BranchId           INT              - ID de la sucursal (obligatorio).
--    @PaymentMethodId    INT              - ID del metodo de pago (obligatorio).
--    @ProviderId         INT              - ID del proveedor (NULL = sin proveedor).
--    @AppliesToPOS       BIT              - Aplica a POS (default 1).
--    @AppliesToWeb       BIT              - Aplica a Web (default 1).
--    @AppliesToRestaurant BIT             - Aplica a Restaurante (default 1).
--    @MinAmount          DECIMAL(18,2)    - Monto minimo (NULL = sin limite).
--    @MaxAmount          DECIMAL(18,2)    - Monto maximo (NULL = sin limite).
--    @CommissionPct      DECIMAL(5,4)     - Porcentaje de comision (NULL = sin comision).
--    @CommissionFixed    DECIMAL(18,2)    - Comision fija (NULL = sin comision).
--    @SortOrder          INT              - Orden de visualizacion (default 0).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_AcceptedMethod_Upsert
    @CompanyId           INT,
    @BranchId            INT,
    @PaymentMethodId     INT,
    @ProviderId          INT             = NULL,
    @AppliesToPOS        BIT             = 1,
    @AppliesToWeb        BIT             = 1,
    @AppliesToRestaurant BIT             = 1,
    @MinAmount           DECIMAL(18,2)   = NULL,
    @MaxAmount           DECIMAL(18,2)   = NULL,
    @CommissionPct       DECIMAL(5,4)    = NULL,
    @CommissionFixed     DECIMAL(18,2)   = NULL,
    @SortOrder           INT             = 0
AS
BEGIN
    SET NOCOUNT ON;

    MERGE pay.AcceptedPaymentMethods AS target
    USING (
        SELECT @CompanyId       AS EmpresaId,
               @BranchId        AS SucursalId,
               @PaymentMethodId AS PaymentMethodId,
               @ProviderId      AS ProviderId
    ) AS source
    ON  target.EmpresaId        = source.EmpresaId
    AND target.SucursalId       = source.SucursalId
    AND target.PaymentMethodId  = source.PaymentMethodId
    AND ISNULL(target.ProviderId, 0) = ISNULL(source.ProviderId, 0)
    WHEN MATCHED THEN
        UPDATE SET AppliesToPOS        = @AppliesToPOS,
                   AppliesToWeb        = @AppliesToWeb,
                   AppliesToRestaurant = @AppliesToRestaurant,
                   MinAmount           = @MinAmount,
                   MaxAmount           = @MaxAmount,
                   CommissionPct       = @CommissionPct,
                   CommissionFixed     = @CommissionFixed,
                   SortOrder           = @SortOrder,
                   IsActive            = 1
    WHEN NOT MATCHED THEN
        INSERT (EmpresaId, SucursalId, PaymentMethodId, ProviderId,
                AppliesToPOS, AppliesToWeb, AppliesToRestaurant,
                MinAmount, MaxAmount, CommissionPct, CommissionFixed, SortOrder)
        VALUES (@CompanyId, @BranchId, @PaymentMethodId, @ProviderId,
                @AppliesToPOS, @AppliesToWeb, @AppliesToRestaurant,
                @MinAmount, @MaxAmount, @CommissionPct, @CommissionFixed, @SortOrder);
END;
GO

-- =============================================================================
--  SP 10b: usp_Pay_AcceptedMethod_Deactivate
--  Descripcion : Desactiva un metodo de pago aceptado por su Id
--                (soft deactivation, no elimina el registro).
--  Parametros  :
--    @Id  INT - ID del registro en pay.AcceptedPaymentMethods (obligatorio).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_AcceptedMethod_Deactivate
    @Id  INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pay.AcceptedPaymentMethods
    SET    IsActive = 0
    WHERE  Id = @Id;
END;
GO

-- =============================================================================
--  SP 11: usp_Pay_CardReader_List (legacy — usar ListByCompany preferentemente)
--  Descripcion : Lista los dispositivos lectores de tarjeta, con filtro
--                opcional por empresa.
--  Parametros  :
--    @CompanyId  INT = NULL - ID de la empresa (opcional; NULL = todos).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CardReader_List
    @CompanyId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id,
           EmpresaId,
           SucursalId,
           StationId,
           DeviceName,
           DeviceType,
           ConnectionType,
           ConnectionConfig,
           ProviderId,
           IsActive,
           LastSeenAt,
           CreatedAt
    FROM   pay.CardReaderDevices
    WHERE  (@CompanyId IS NULL OR EmpresaId = @CompanyId)
    ORDER BY EmpresaId, StationId, DeviceName;
END;
GO

-- =============================================================================
--  SP 11b: usp_Pay_CardReader_ListByCompany
--  Descripcion : Lista dispositivos lectores de tarjeta por empresa con filtro
--                opcional de sucursal. Solo activos.
--  Parametros  :
--    @CompanyId  INT       - ID de la empresa (obligatorio).
--    @BranchId   INT = NULL - ID de la sucursal (NULL = todas).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CardReader_ListByCompany
    @CompanyId  INT,
    @BranchId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id,
           EmpresaId,
           SucursalId,
           StationId,
           DeviceName,
           DeviceType,
           ConnectionType,
           ConnectionConfig,
           ProviderId,
           IsActive,
           LastSeenAt,
           CreatedAt
    FROM   pay.CardReaderDevices
    WHERE  EmpresaId = @CompanyId
      AND  IsActive = 1
      AND  (@BranchId IS NULL OR SucursalId = @BranchId)
    ORDER BY StationId, DeviceName;
END;
GO

-- =============================================================================
--  SP 12: usp_Pay_CardReader_Upsert
--  Descripcion : Inserta un nuevo dispositivo lector de tarjeta o actualiza
--                uno existente. Si @DeviceId no es NULL, actualiza; de lo
--                contrario, inserta un nuevo registro.
--  Parametros  :
--    @DeviceId         INT             - ID del dispositivo (NULL = insertar nuevo).
--    @CompanyId        INT             - ID de la empresa (obligatorio).
--    @BranchId         INT             - ID de la sucursal (default 0).
--    @StationId        NVARCHAR(50)    - ID de estacion.
--    @DeviceName       NVARCHAR(100)   - Nombre descriptivo del dispositivo.
--    @DeviceType       NVARCHAR(30)    - Tipo: PINPAD, CONTACTLESS, CHIP, etc.
--    @ConnectionType   NVARCHAR(30)    - Tipo de conexion: USB, SERIAL, etc.
--    @ConnectionConfig NVARCHAR(500)   - JSON de configuracion de conexion (opcional).
--    @ProviderId       INT             - ID del proveedor asociado (opcional).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Pay_CardReader_Upsert
    @DeviceId         INT           = NULL,
    @CompanyId        INT,
    @BranchId         INT           = 0,
    @StationId        NVARCHAR(50)  = 'DEFAULT',
    @DeviceName       NVARCHAR(100),
    @DeviceType       NVARCHAR(30),
    @ConnectionType   NVARCHAR(30)  = 'USB',
    @ConnectionConfig NVARCHAR(500) = NULL,
    @ProviderId       INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @DeviceId IS NOT NULL
    BEGIN
        -- Actualizar dispositivo existente
        UPDATE pay.CardReaderDevices
        SET    DeviceName       = @DeviceName,
               DeviceType       = @DeviceType,
               ConnectionType   = @ConnectionType,
               ConnectionConfig = COALESCE(@ConnectionConfig, ConnectionConfig),
               ProviderId       = @ProviderId,
               StationId        = @StationId
        WHERE  Id = @DeviceId;
    END
    ELSE
    BEGIN
        -- Insertar nuevo dispositivo
        INSERT INTO pay.CardReaderDevices (
            EmpresaId,
            SucursalId,
            StationId,
            DeviceName,
            DeviceType,
            ConnectionType,
            ConnectionConfig,
            ProviderId,
            IsActive,
            CreatedAt
        )
        VALUES (
            @CompanyId,
            @BranchId,
            @StationId,
            @DeviceName,
            @DeviceType,
            @ConnectionType,
            @ConnectionConfig,
            @ProviderId,
            1,
            GETDATE()
        );
    END;
END;
GO

PRINT 'usp_pay.sql: 18 procedimientos de pagos creados/actualizados exitosamente.';
GO
