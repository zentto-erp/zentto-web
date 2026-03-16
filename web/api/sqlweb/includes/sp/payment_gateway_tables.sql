-- ============================================================
-- DatqBox Payment Gateway — Multi-country, multi-provider
-- Schema: pay
-- ============================================================

-- Create schema if not exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'pay')
    EXEC('CREATE SCHEMA pay');
GO

-- ============================================================
-- 1. Payment Methods (catálogo global de formas de pago)
-- ============================================================
IF OBJECT_ID('pay.PaymentMethods', 'U') IS NULL
CREATE TABLE pay.PaymentMethods (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(30) NOT NULL,           -- 'EFECTIVO','TDC','TDD','C2P','TRANSFER','CRYPTO','QR','BOTON_WEB'
    Name            NVARCHAR(100) NOT NULL,         -- 'Tarjeta de Crédito'
    Category        VARCHAR(30) NOT NULL,           -- 'CASH','CARD','MOBILE','TRANSFER','CRYPTO','DIGITAL_WALLET','OTHER'
    CountryCode     CHAR(2) NULL,                   -- NULL = global, 'VE','ES','US' etc.
    IconName        VARCHAR(50) NULL,               -- MUI icon name for frontend
    RequiresGateway BIT DEFAULT 0,                  -- Does this method need an external gateway?
    IsActive        BIT DEFAULT 1,
    SortOrder       INT DEFAULT 0,
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_PayMethod UNIQUE (Code, CountryCode)
);
GO

-- ============================================================
-- 2. Payment Providers / Gateways (Mercantil, Stripe, Binance, etc.)
-- ============================================================
IF OBJECT_ID('pay.PaymentProviders', 'U') IS NULL
CREATE TABLE pay.PaymentProviders (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Code            VARCHAR(30) NOT NULL UNIQUE,    -- 'MERCANTIL','BANESCO','STRIPE','BINANCE','REDSYS'
    Name            NVARCHAR(150) NOT NULL,         -- 'Banco Mercantil - API Payment'
    CountryCode     CHAR(2) NULL,                   -- NULL = international
    ProviderType    VARCHAR(30) NOT NULL,           -- 'BANK_API','CARD_PROCESSOR','CRYPTO_EXCHANGE','PAYMENT_GATEWAY'
    BaseUrlSandbox  VARCHAR(500) NULL,
    BaseUrlProd     VARCHAR(500) NULL,
    AuthType        VARCHAR(30) NULL,               -- 'API_KEY','OAUTH2','HMAC','CERT'
    DocsUrl         VARCHAR(500) NULL,
    LogoUrl         VARCHAR(500) NULL,
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================
-- 3. Provider Capabilities (qué métodos soporta cada provider)
-- ============================================================
IF OBJECT_ID('pay.ProviderCapabilities', 'U') IS NULL
CREATE TABLE pay.ProviderCapabilities (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    ProviderId      INT NOT NULL REFERENCES pay.PaymentProviders(Id),
    Capability      VARCHAR(50) NOT NULL,           -- 'SALE','REFUND','VOID','AUTH','CAPTURE','SEARCH','RECONCILE','QR_GENERATE'
    PaymentMethod   VARCHAR(30) NULL,               -- 'TDC','TDD','C2P' etc. NULL = all
    EndpointPath    VARCHAR(200) NULL,              -- '/v1/payment/pay', '/v1/payment/c2p'
    HttpMethod      VARCHAR(10) DEFAULT 'POST',
    IsActive        BIT DEFAULT 1,
    CONSTRAINT UQ_ProvCap UNIQUE (ProviderId, Capability, PaymentMethod)
);
GO

-- ============================================================
-- 4. Company Payment Config (config por empresa+sucursal)
-- ============================================================
IF OBJECT_ID('pay.CompanyPaymentConfig', 'U') IS NULL
CREATE TABLE pay.CompanyPaymentConfig (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    EmpresaId       INT NOT NULL,
    SucursalId      INT NOT NULL DEFAULT 0,
    CountryCode     CHAR(2) NOT NULL,               -- 'VE','ES'
    ProviderId      INT NOT NULL REFERENCES pay.PaymentProviders(Id),
    Environment     VARCHAR(10) DEFAULT 'sandbox',  -- 'sandbox' | 'production'
    
    -- Credentials (encrypted at app level)
    ClientId        VARCHAR(500) NULL,              -- X-IBM-Client-ID (Mercantil) / API Key (Stripe)
    ClientSecret    VARCHAR(500) NULL,
    MerchantId      VARCHAR(100) NULL,              -- merchantId
    TerminalId      VARCHAR(100) NULL,              -- terminalId (POS físico)
    IntegratorId    VARCHAR(50) NULL,               -- integratorId (Mercantil)
    CertificatePath VARCHAR(500) NULL,              -- For cert-based auth
    ExtraConfig     NVARCHAR(MAX) NULL,             -- JSON for provider-specific settings
    
    -- Behavior
    AutoCapture     BIT DEFAULT 1,                  -- Auto-capture or auth+capture
    AllowRefunds    BIT DEFAULT 1,
    MaxRefundDays   INT DEFAULT 30,
    
    IsActive        BIT DEFAULT 1,
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    
    CONSTRAINT UQ_CompanyPayConfig UNIQUE (EmpresaId, SucursalId, ProviderId)
);
GO

-- ============================================================
-- 5. Accepted Payment Methods per Company (qué acepta cada empresa)
-- ============================================================
IF OBJECT_ID('pay.AcceptedPaymentMethods', 'U') IS NULL
CREATE TABLE pay.AcceptedPaymentMethods (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    EmpresaId       INT NOT NULL,
    SucursalId      INT NOT NULL DEFAULT 0,
    PaymentMethodId INT NOT NULL REFERENCES pay.PaymentMethods(Id),
    ProviderId      INT NULL REFERENCES pay.PaymentProviders(Id), -- NULL = manual/offline
    AppliesToPOS    BIT DEFAULT 1,
    AppliesToWeb    BIT DEFAULT 1,
    AppliesToRestaurant BIT DEFAULT 1,
    MinAmount       DECIMAL(18,2) NULL,
    MaxAmount       DECIMAL(18,2) NULL,
    CommissionPct   DECIMAL(5,4) NULL,              -- e.g. 0.0350 = 3.5%
    CommissionFixed DECIMAL(18,2) NULL,
    IsActive        BIT DEFAULT 1,
    SortOrder       INT DEFAULT 0,
    
    CONSTRAINT UQ_AcceptedPM UNIQUE (EmpresaId, SucursalId, PaymentMethodId, ProviderId)
);
GO

-- ============================================================
-- 6. Payment Transactions (log de transacciones)
-- ============================================================
IF OBJECT_ID('pay.Transactions', 'U') IS NULL
CREATE TABLE pay.Transactions (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    TransactionUUID VARCHAR(36) NOT NULL UNIQUE,    -- UUID for idempotency
    EmpresaId       INT NOT NULL,
    SucursalId      INT NOT NULL DEFAULT 0,
    
    -- Source document
    SourceType      VARCHAR(30) NOT NULL,           -- 'FACTURA','TICKET_POS','TICKET_REST','COBRO','ABONO'
    SourceId        INT NULL,                       -- FK to source table
    SourceNumber    VARCHAR(50) NULL,               -- Invoice/ticket number
    
    -- Payment info
    PaymentMethodCode VARCHAR(30) NOT NULL,
    ProviderId      INT NULL REFERENCES pay.PaymentProviders(Id),
    
    -- Amounts
    Currency        VARCHAR(3) NOT NULL,            -- 'VES','EUR','USD','USDT'
    Amount          DECIMAL(18,2) NOT NULL,
    CommissionAmount DECIMAL(18,2) NULL,
    NetAmount       DECIMAL(18,2) NULL,
    ExchangeRate    DECIMAL(18,6) NULL,             -- If currency conversion applies
    AmountInBase    DECIMAL(18,2) NULL,             -- Amount in base currency
    
    -- Transaction lifecycle
    TrxType         VARCHAR(20) NOT NULL,           -- 'SALE','REFUND','VOID','AUTH','CAPTURE'
    Status          VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING','PROCESSING','APPROVED','DECLINED','ERROR','VOIDED','REFUNDED'
    
    -- Gateway response
    GatewayTrxId    VARCHAR(100) NULL,              -- Provider's transaction ID
    GatewayAuthCode VARCHAR(50) NULL,               -- Authorization code
    GatewayResponse NVARCHAR(MAX) NULL,             -- Full JSON response
    GatewayMessage  NVARCHAR(500) NULL,
    
    -- Card info (masked)
    CardLastFour    VARCHAR(4) NULL,
    CardBrand       VARCHAR(20) NULL,               -- 'VISA','MASTERCARD','AMEX'
    
    -- Mobile payment (C2P) info
    MobileNumber    VARCHAR(20) NULL,               -- Masked
    BankCode        VARCHAR(10) NULL,
    PaymentRef      VARCHAR(50) NULL,
    
    -- Reconciliation
    IsReconciled    BIT DEFAULT 0,
    ReconciledAt    DATETIME NULL,
    ReconciliationId BIGINT NULL,
    
    -- Metadata
    StationId       VARCHAR(50) NULL,               -- POS station / Terminal
    CashierId       VARCHAR(20) NULL,               -- Cashier user
    IpAddress       VARCHAR(45) NULL,
    UserAgent       VARCHAR(500) NULL,
    Notes           NVARCHAR(500) NULL,
    
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    
    INDEX IX_PayTrx_Source (SourceType, SourceId),
    INDEX IX_PayTrx_Status (Status, CreatedAt),
    INDEX IX_PayTrx_Recon (IsReconciled, ProviderId)
);
GO

-- ============================================================
-- 7. Payment Reconciliation batches
-- ============================================================
IF OBJECT_ID('pay.ReconciliationBatches', 'U') IS NULL
CREATE TABLE pay.ReconciliationBatches (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    EmpresaId       INT NOT NULL,
    ProviderId      INT NOT NULL REFERENCES pay.PaymentProviders(Id),
    DateFrom        DATE NOT NULL,
    DateTo          DATE NOT NULL,
    TotalTransactions INT DEFAULT 0,
    TotalAmount     DECIMAL(18,2) DEFAULT 0,
    MatchedCount    INT DEFAULT 0,
    UnmatchedCount  INT DEFAULT 0,
    Status          VARCHAR(20) DEFAULT 'PENDING',  -- 'PENDING','IN_PROGRESS','COMPLETED','FAILED'
    ResultJson      NVARCHAR(MAX) NULL,
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME(),
    CompletedAt     DATETIME NULL,
    UserId          VARCHAR(20) NULL
);
GO

-- ============================================================
-- 8. Card Reader Devices (lectores de tarjeta en estaciones POS)
-- ============================================================
IF OBJECT_ID('pay.CardReaderDevices', 'U') IS NULL
CREATE TABLE pay.CardReaderDevices (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    EmpresaId       INT NOT NULL,
    SucursalId      INT NOT NULL DEFAULT 0,
    StationId       VARCHAR(50) NOT NULL,           -- Estación POS a la que está vinculado
    DeviceName      NVARCHAR(100) NOT NULL,         -- 'Ingenico iCT250', 'Verifone VX520'
    DeviceType      VARCHAR(30) NOT NULL,           -- 'PINPAD','CONTACTLESS','CHIP','MAGSTRIPE','ALL'
    ConnectionType  VARCHAR(30) NOT NULL,           -- 'USB','SERIAL','BLUETOOTH','NETWORK','INTEGRATED'
    ConnectionConfig NVARCHAR(500) NULL,            -- JSON: {"port":"COM3","baudRate":9600} or {"ip":"192.168.1.50","port":8080}
    ProviderId      INT NULL REFERENCES pay.PaymentProviders(Id),
    IsActive        BIT DEFAULT 1,
    LastSeenAt      DATETIME NULL,
    CreatedAt       DATETIME DEFAULT SYSUTCDATETIME()
);
GO

-- ============================================================
-- SEED: Initial payment methods & Mercantil provider
-- ============================================================

-- Global payment methods
MERGE pay.PaymentMethods AS target
USING (VALUES
    ('EFECTIVO',    'Efectivo',                     'CASH',         NULL, 'Payments',          0, 1, 1),
    ('TDC',         'Tarjeta de Crédito',           'CARD',         NULL, 'CreditCard',        1, 1, 2),
    ('TDD',         'Tarjeta de Débito',            'CARD',         NULL, 'CreditCard',        1, 1, 3),
    ('C2P',         'Pago Móvil (C2P)',             'MOBILE',       'VE', 'PhoneIphone',       1, 1, 4),
    ('TRANSFER',    'Transferencia Bancaria',       'TRANSFER',     NULL, 'AccountBalance',    0, 1, 5),
    ('ZELLE',       'Zelle',                        'TRANSFER',     'US', 'SwapHoriz',         0, 1, 6),
    ('BIZUM',       'Bizum',                        'MOBILE',       'ES', 'PhoneIphone',       1, 1, 7),
    ('CRYPTO_USDT', 'USDT (Tether)',                'CRYPTO',       NULL, 'CurrencyBitcoin',   1, 1, 8),
    ('CRYPTO_BTC',  'Bitcoin',                      'CRYPTO',       NULL, 'CurrencyBitcoin',   1, 1, 9),
    ('BINANCE_PAY', 'Binance Pay',                  'DIGITAL_WALLET',NULL,'AccountBalanceWallet',1,1,10),
    ('PAYPAL',      'PayPal',                       'DIGITAL_WALLET',NULL,'AccountBalanceWallet',1,1,11),
    ('QR_PAY',      'Pago por QR',                  'QR',           NULL, 'QrCode2',           1, 1, 12),
    ('CHEQUE',      'Cheque',                       'OTHER',        NULL, 'Receipt',           0, 1, 13),
    ('CREDITO',     'Crédito / Fiado',              'OTHER',        NULL, 'CreditScore',       0, 1, 14),
    ('BOTON_WEB',   'Botón de Pagos Web',           'DIGITAL_WALLET','VE','Language',          1, 1, 15),
    ('SDI',         'Solicitud Débito Inmediato',   'TRANSFER',     'VE', 'AccountBalance',    1, 1, 16),
    ('REDSYS',      'Redsys (TPV Virtual)',         'CARD',         'ES', 'CreditCard',        1, 1, 17),
    ('VUELTO_C2P',  'Vuelto Pago Móvil',           'MOBILE',       'VE', 'PhoneIphone',       1, 1, 18)
) AS source (Code, Name, Category, CountryCode, IconName, RequiresGateway, IsActive, SortOrder)
ON target.Code = source.Code AND ISNULL(target.CountryCode,'__') = ISNULL(source.CountryCode,'__')
WHEN NOT MATCHED THEN
    INSERT (Code, Name, Category, CountryCode, IconName, RequiresGateway, IsActive, SortOrder)
    VALUES (source.Code, source.Name, source.Category, source.CountryCode, source.IconName, source.RequiresGateway, source.IsActive, source.SortOrder);
GO

-- Mercantil Provider
MERGE pay.PaymentProviders AS target
USING (VALUES
    ('MERCANTIL',   'Banco Mercantil - API Payment',    'VE', 'BANK_API',
     'https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1',
     'https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1',
     'API_KEY',
     'https://apiportal.mercantilbanco.com/mercantil-banco/produccion/product',
     NULL),
    ('BINANCE',     'Binance Pay',                      NULL, 'CRYPTO_EXCHANGE',
     'https://bpay.binanceapi.com',
     'https://bpay.binanceapi.com',
     'HMAC',
     'https://developers.binance.com/docs/binance-pay',
     NULL),
    ('STRIPE',      'Stripe',                           NULL, 'PAYMENT_GATEWAY',
     'https://api.stripe.com',
     'https://api.stripe.com',
     'API_KEY',
     'https://docs.stripe.com/',
     NULL),
    ('REDSYS',      'Redsys (España)',                  'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/realizarPago',
     'https://sis.redsys.es/sis/realizarPago',
     'HMAC',
     'https://pagosonline.redsys.es/desarrolladores.html',
     NULL),
    ('BANESCO',     'Banco Banesco - Pago Móvil',       'VE', 'BANK_API',
     NULL, NULL, 'API_KEY', NULL, NULL),
    ('PROVINCIAL',  'BBVA Provincial',                  'VE', 'BANK_API',
     NULL, NULL, 'API_KEY', NULL, NULL),
    -- Venezuela — additional banks
    ('BDV',         'Banco de Venezuela',               'VE', 'BANK_API',
     NULL, NULL, 'API_KEY',
     'https://www.bancodevenezuela.com/',
     NULL),
    ('BANCA_AMIGA', 'Banca Amiga',                      'VE', 'BANK_API',
     NULL, NULL, 'API_KEY',
     'https://www.bancaamiga.com/',
     NULL),
    -- España — banks that operate via Redsys (each has its own merchant/FUC)
    ('CAIXABANK',   'CaixaBank (via Redsys)',           'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
     'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC',
     'https://www.caixabank.es/empresa/tpv-virtual.html',
     NULL),
    ('BBVA_ES',     'BBVA España (via Redsys)',         'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
     'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC',
     'https://www.bbva.es/empresas/productos/cobros/tpv-virtual.html',
     NULL),
    ('SANTANDER_ES','Banco Santander España (via Redsys)','ES','CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
     'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC',
     'https://www.bancosantander.es/empresas/cobros-pagos/tpv',
     NULL),
    ('SABADELL',    'Banco Sabadell (via Redsys)',      'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
     'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC',
     'https://www.bancsabadell.com/cs/Satellite/SabAtl/TPV-virtual/6000002059',
     NULL),
    ('BANKINTER',   'Bankinter (via Redsys)',           'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
     'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC',
     'https://www.bankinter.com/banca/nav/empresas',
     NULL)
) AS source (Code, Name, CountryCode, ProviderType, BaseUrlSandbox, BaseUrlProd, AuthType, DocsUrl, LogoUrl)
ON target.Code = source.Code
WHEN NOT MATCHED THEN
    INSERT (Code, Name, CountryCode, ProviderType, BaseUrlSandbox, BaseUrlProd, AuthType, DocsUrl, LogoUrl)
    VALUES (source.Code, source.Name, source.CountryCode, source.ProviderType, source.BaseUrlSandbox, source.BaseUrlProd, source.AuthType, source.DocsUrl, source.LogoUrl);
GO

-- ============================================================
-- Redsys capabilities for ALL Spanish bank providers
-- (They all route through Redsys with same endpoint structure)
-- ============================================================
DECLARE @redsysId INT = (SELECT Id FROM pay.PaymentProviders WHERE Code = 'REDSYS');
IF @redsysId IS NOT NULL
BEGIN
    MERGE pay.ProviderCapabilities AS target
    USING (VALUES
        (@redsysId, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
        (@redsysId, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
    ) AS source (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
    ON target.ProviderId = source.ProviderId
       AND target.Capability = source.Capability
       AND ISNULL(target.PaymentMethod,'__') = ISNULL(source.PaymentMethod,'__')
    WHEN NOT MATCHED THEN
        INSERT (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
        VALUES (source.ProviderId, source.Capability, source.PaymentMethod, source.EndpointPath, source.HttpMethod);
END
GO

-- Clone same capabilities for each Spanish bank provider
-- (CaixaBank, BBVA ES, Santander ES, Sabadell, Bankinter — all use Redsys engine)
DECLARE @bankCodes TABLE (Code VARCHAR(30));
INSERT @bankCodes VALUES ('CAIXABANK'),('BBVA_ES'),('SANTANDER_ES'),('SABADELL'),('BANKINTER');

DECLARE @bcode VARCHAR(30), @bid INT;
DECLARE bank_cursor CURSOR FOR SELECT Code FROM @bankCodes;
OPEN bank_cursor;
FETCH NEXT FROM bank_cursor INTO @bcode;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @bid = (SELECT Id FROM pay.PaymentProviders WHERE Code = @bcode);
    IF @bid IS NOT NULL
    BEGIN
        MERGE pay.ProviderCapabilities AS target
        USING (VALUES
            (@bid, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
            (@bid, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
        ) AS source (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
        ON target.ProviderId = source.ProviderId
           AND target.Capability = source.Capability
           AND ISNULL(target.PaymentMethod,'__') = ISNULL(source.PaymentMethod,'__')
        WHEN NOT MATCHED THEN
            INSERT (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
            VALUES (source.ProviderId, source.Capability, source.PaymentMethod, source.EndpointPath, source.HttpMethod);
    END
    FETCH NEXT FROM bank_cursor INTO @bcode;
END
CLOSE bank_cursor;
DEALLOCATE bank_cursor;
GO

-- Binance Pay capabilities
DECLARE @binanceId INT = (SELECT Id FROM pay.PaymentProviders WHERE Code = 'BINANCE');
IF @binanceId IS NOT NULL
BEGIN
    MERGE pay.ProviderCapabilities AS target
    USING (VALUES
        (@binanceId, 'SALE',       'CRYPTO_USDT', '/binancepay/openapi/v2/order',        'POST'),
        (@binanceId, 'SALE',       'CRYPTO_BTC',  '/binancepay/openapi/v2/order',        'POST'),
        (@binanceId, 'SALE',       'BINANCE_PAY', '/binancepay/openapi/v2/order',        'POST'),
        (@binanceId, 'SEARCH',     NULL,          '/binancepay/openapi/v2/order/query',  'POST'),
        (@binanceId, 'VOID',       NULL,          '/binancepay/openapi/v2/order/close',  'POST'),
        (@binanceId, 'REFUND',     NULL,          '/binancepay/openapi/v3/order/refund', 'POST')
    ) AS source (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
    ON target.ProviderId = source.ProviderId
       AND target.Capability = source.Capability
       AND ISNULL(target.PaymentMethod,'__') = ISNULL(source.PaymentMethod,'__')
    WHEN NOT MATCHED THEN
        INSERT (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
        VALUES (source.ProviderId, source.Capability, source.PaymentMethod, source.EndpointPath, source.HttpMethod);
END
GO

-- Mercantil Capabilities
DECLARE @mercantilId INT = (SELECT Id FROM pay.PaymentProviders WHERE Code = 'MERCANTIL');
IF @mercantilId IS NOT NULL
BEGIN
    MERGE pay.ProviderCapabilities AS target
    USING (VALUES
        (@mercantilId, 'SALE',       'C2P',      '/payment/c2p',             'POST'),
        (@mercantilId, 'REFUND',     'C2P',      '/payment/c2p',             'POST'),  -- trx_type=vuelto
        (@mercantilId, 'VOID',       'C2P',      '/payment/c2p',             'POST'),  -- trx_type=anulacion
        (@mercantilId, 'SCP',        'C2P',      '/mobile-payment/scp',      'POST'),  -- Solicitud clave pago
        (@mercantilId, 'SEARCH',     'C2P',      '/mobile-payment/search',   'POST'),
        (@mercantilId, 'AUTH',       'TDD',      '/payment/getauth',         'POST'),
        (@mercantilId, 'SALE',       'TDC',      '/payment/pay',             'POST'),
        (@mercantilId, 'SALE',       'TDD',      '/payment/pay',             'POST'),
        (@mercantilId, 'SEARCH',     'TDC',      '/payment/search',          'POST'),
        (@mercantilId, 'SEARCH',     'TDD',      '/payment/search',          'POST'),
        (@mercantilId, 'SEARCH',     'TRANSFER', '/payment/transfer-search', 'POST'),
        (@mercantilId, 'RECONCILE',  NULL,        '/payment/search',          'POST')
    ) AS source (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
    ON target.ProviderId = source.ProviderId 
       AND target.Capability = source.Capability 
       AND ISNULL(target.PaymentMethod,'__') = ISNULL(source.PaymentMethod,'__')
    WHEN NOT MATCHED THEN
        INSERT (ProviderId, Capability, PaymentMethod, EndpointPath, HttpMethod)
        VALUES (source.ProviderId, source.Capability, source.PaymentMethod, source.EndpointPath, source.HttpMethod);
END
GO

PRINT '✅ Payment Gateway tables, providers (VE: Mercantil, BDV, Banca Amiga, Banesco, Provincial | ES: Redsys, CaixaBank, BBVA, Santander, Sabadell, Bankinter | Global: Binance, Stripe), capabilities and seed data created successfully';
GO
