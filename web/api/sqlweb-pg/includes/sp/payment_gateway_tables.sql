-- ============================================================
-- DatqBox Payment Gateway — Multi-country, multi-provider - PostgreSQL
-- Schema: pay
-- Traducido de SQL Server a PostgreSQL
-- ============================================================

CREATE SCHEMA IF NOT EXISTS pay;

-- ============================================================
-- 1. Payment Methods (catalogo global de formas de pago)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentMethods" (
    "Id"              SERIAL PRIMARY KEY,
    "Code"            VARCHAR(30) NOT NULL,
    "Name"            VARCHAR(100) NOT NULL,
    "Category"        VARCHAR(30) NOT NULL,
    "CountryCode"     CHAR(2),
    "IconName"        VARCHAR(50),
    "RequiresGateway" BOOLEAN DEFAULT FALSE,
    "IsActive"        BOOLEAN DEFAULT TRUE,
    "SortOrder"       INT DEFAULT 0,
    "CreatedAt"       TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_PayMethod" UNIQUE ("Code", "CountryCode")
);

-- ============================================================
-- 2. Payment Providers / Gateways
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentProviders" (
    "Id"              SERIAL PRIMARY KEY,
    "Code"            VARCHAR(30) NOT NULL UNIQUE,
    "Name"            VARCHAR(150) NOT NULL,
    "CountryCode"     CHAR(2),
    "ProviderType"    VARCHAR(30) NOT NULL,
    "BaseUrlSandbox"  VARCHAR(500),
    "BaseUrlProd"     VARCHAR(500),
    "AuthType"        VARCHAR(30),
    "DocsUrl"         VARCHAR(500),
    "LogoUrl"         VARCHAR(500),
    "IsActive"        BOOLEAN DEFAULT TRUE,
    "CreatedAt"       TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- 3. Provider Capabilities
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ProviderCapabilities" (
    "Id"              SERIAL PRIMARY KEY,
    "ProviderId"      INT NOT NULL REFERENCES pay."PaymentProviders"("Id"),
    "Capability"      VARCHAR(50) NOT NULL,
    "PaymentMethod"   VARCHAR(30),
    "EndpointPath"    VARCHAR(200),
    "HttpMethod"      VARCHAR(10) DEFAULT 'POST',
    "IsActive"        BOOLEAN DEFAULT TRUE,
    CONSTRAINT "UQ_ProvCap" UNIQUE ("ProviderId", "Capability", "PaymentMethod")
);

-- ============================================================
-- 4. Company Payment Config
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CompanyPaymentConfig" (
    "Id"              SERIAL PRIMARY KEY,
    "EmpresaId"       INT NOT NULL,
    "SucursalId"      INT NOT NULL DEFAULT 0,
    "CountryCode"     CHAR(2) NOT NULL,
    "ProviderId"      INT NOT NULL REFERENCES pay."PaymentProviders"("Id"),
    "Environment"     VARCHAR(10) DEFAULT 'sandbox',
    "ClientId"        VARCHAR(500),
    "ClientSecret"    VARCHAR(500),
    "MerchantId"      VARCHAR(100),
    "TerminalId"      VARCHAR(100),
    "IntegratorId"    VARCHAR(50),
    "CertificatePath" VARCHAR(500),
    "ExtraConfig"     JSONB,
    "AutoCapture"     BOOLEAN DEFAULT TRUE,
    "AllowRefunds"    BOOLEAN DEFAULT TRUE,
    "MaxRefundDays"   INT DEFAULT 30,
    "IsActive"        BOOLEAN DEFAULT TRUE,
    "CreatedAt"       TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_CompanyPayConfig" UNIQUE ("EmpresaId", "SucursalId", "ProviderId")
);

-- ============================================================
-- 5. Accepted Payment Methods per Company
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."AcceptedPaymentMethods" (
    "Id"                  SERIAL PRIMARY KEY,
    "EmpresaId"           INT NOT NULL,
    "SucursalId"          INT NOT NULL DEFAULT 0,
    "PaymentMethodId"     INT NOT NULL REFERENCES pay."PaymentMethods"("Id"),
    "ProviderId"          INT REFERENCES pay."PaymentProviders"("Id"),
    "AppliesToPOS"        BOOLEAN DEFAULT TRUE,
    "AppliesToWeb"        BOOLEAN DEFAULT TRUE,
    "AppliesToRestaurant" BOOLEAN DEFAULT TRUE,
    "MinAmount"           NUMERIC(18,2),
    "MaxAmount"           NUMERIC(18,2),
    "CommissionPct"       NUMERIC(5,4),
    "CommissionFixed"     NUMERIC(18,2),
    "IsActive"            BOOLEAN DEFAULT TRUE,
    "SortOrder"           INT DEFAULT 0,
    CONSTRAINT "UQ_AcceptedPM" UNIQUE ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId")
);

-- ============================================================
-- 6. Payment Transactions
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."Transactions" (
    "Id"                BIGSERIAL PRIMARY KEY,
    "TransactionUUID"   VARCHAR(36) NOT NULL UNIQUE,
    "EmpresaId"         INT NOT NULL,
    "SucursalId"        INT NOT NULL DEFAULT 0,
    "SourceType"        VARCHAR(30) NOT NULL,
    "SourceId"          INT,
    "SourceNumber"      VARCHAR(50),
    "PaymentMethodCode" VARCHAR(30) NOT NULL,
    "ProviderId"        INT REFERENCES pay."PaymentProviders"("Id"),
    "Currency"          VARCHAR(3) NOT NULL,
    "Amount"            NUMERIC(18,2) NOT NULL,
    "CommissionAmount"  NUMERIC(18,2),
    "NetAmount"         NUMERIC(18,2),
    "ExchangeRate"      NUMERIC(18,6),
    "AmountInBase"      NUMERIC(18,2),
    "TrxType"           VARCHAR(20) NOT NULL,
    "Status"            VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "GatewayTrxId"      VARCHAR(100),
    "GatewayAuthCode"   VARCHAR(50),
    "GatewayResponse"   JSONB,
    "GatewayMessage"    VARCHAR(500),
    "CardLastFour"      VARCHAR(4),
    "CardBrand"         VARCHAR(20),
    "MobileNumber"      VARCHAR(20),
    "BankCode"          VARCHAR(10),
    "PaymentRef"        VARCHAR(50),
    "IsReconciled"      BOOLEAN DEFAULT FALSE,
    "ReconciledAt"      TIMESTAMP,
    "ReconciliationId"  BIGINT,
    "StationId"         VARCHAR(50),
    "CashierId"         VARCHAR(20),
    "IpAddress"         VARCHAR(45),
    "UserAgent"         VARCHAR(500),
    "Notes"             VARCHAR(500),
    "CreatedAt"         TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"         TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_PayTrx_Source" ON pay."Transactions" ("SourceType", "SourceId");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Status" ON pay."Transactions" ("Status", "CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Recon" ON pay."Transactions" ("IsReconciled", "ProviderId");

-- ============================================================
-- 7. Payment Reconciliation batches
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ReconciliationBatches" (
    "Id"                BIGSERIAL PRIMARY KEY,
    "EmpresaId"         INT NOT NULL,
    "ProviderId"        INT NOT NULL REFERENCES pay."PaymentProviders"("Id"),
    "DateFrom"          DATE NOT NULL,
    "DateTo"            DATE NOT NULL,
    "TotalTransactions" INT DEFAULT 0,
    "TotalAmount"       NUMERIC(18,2) DEFAULT 0,
    "MatchedCount"      INT DEFAULT 0,
    "UnmatchedCount"    INT DEFAULT 0,
    "Status"            VARCHAR(20) DEFAULT 'PENDING',
    "ResultJson"        JSONB,
    "CreatedAt"         TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "CompletedAt"       TIMESTAMP,
    "UserId"            VARCHAR(20)
);

-- ============================================================
-- 8. Card Reader Devices
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CardReaderDevices" (
    "Id"               SERIAL PRIMARY KEY,
    "EmpresaId"        INT NOT NULL,
    "SucursalId"       INT NOT NULL DEFAULT 0,
    "StationId"        VARCHAR(50) NOT NULL,
    "DeviceName"       VARCHAR(100) NOT NULL,
    "DeviceType"       VARCHAR(30) NOT NULL,
    "ConnectionType"   VARCHAR(30) NOT NULL,
    "ConnectionConfig" JSONB,
    "ProviderId"       INT REFERENCES pay."PaymentProviders"("Id"),
    "IsActive"         BOOLEAN DEFAULT TRUE,
    "LastSeenAt"       TIMESTAMP,
    "CreatedAt"        TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- SEED: Payment methods
-- ============================================================
INSERT INTO pay."PaymentMethods" ("Code", "Name", "Category", "CountryCode", "IconName", "RequiresGateway", "IsActive", "SortOrder")
VALUES
    ('EFECTIVO',    'Efectivo',                     'CASH',           NULL, 'Payments',          FALSE, TRUE, 1),
    ('TDC',         'Tarjeta de Credito',           'CARD',           NULL, 'CreditCard',        TRUE,  TRUE, 2),
    ('TDD',         'Tarjeta de Debito',            'CARD',           NULL, 'CreditCard',        TRUE,  TRUE, 3),
    ('C2P',         'Pago Movil (C2P)',             'MOBILE',         'VE', 'PhoneIphone',       TRUE,  TRUE, 4),
    ('TRANSFER',    'Transferencia Bancaria',       'TRANSFER',       NULL, 'AccountBalance',    FALSE, TRUE, 5),
    ('ZELLE',       'Zelle',                        'TRANSFER',       'US', 'SwapHoriz',         FALSE, TRUE, 6),
    ('BIZUM',       'Bizum',                        'MOBILE',         'ES', 'PhoneIphone',       TRUE,  TRUE, 7),
    ('CRYPTO_USDT', 'USDT (Tether)',                'CRYPTO',         NULL, 'CurrencyBitcoin',   TRUE,  TRUE, 8),
    ('CRYPTO_BTC',  'Bitcoin',                      'CRYPTO',         NULL, 'CurrencyBitcoin',   TRUE,  TRUE, 9),
    ('BINANCE_PAY', 'Binance Pay',                  'DIGITAL_WALLET', NULL, 'AccountBalanceWallet', TRUE, TRUE, 10),
    ('PAYPAL',      'PayPal',                       'DIGITAL_WALLET', NULL, 'AccountBalanceWallet', TRUE, TRUE, 11),
    ('QR_PAY',      'Pago por QR',                  'QR',             NULL, 'QrCode2',           TRUE,  TRUE, 12),
    ('CHEQUE',      'Cheque',                       'OTHER',          NULL, 'Receipt',           FALSE, TRUE, 13),
    ('CREDITO',     'Credito / Fiado',              'OTHER',          NULL, 'CreditScore',       FALSE, TRUE, 14),
    ('BOTON_WEB',   'Boton de Pagos Web',           'DIGITAL_WALLET', 'VE', 'Language',          TRUE,  TRUE, 15),
    ('SDI',         'Solicitud Debito Inmediato',   'TRANSFER',       'VE', 'AccountBalance',    TRUE,  TRUE, 16),
    ('REDSYS',      'Redsys (TPV Virtual)',         'CARD',           'ES', 'CreditCard',        TRUE,  TRUE, 17),
    ('VUELTO_C2P',  'Vuelto Pago Movil',           'MOBILE',         'VE', 'PhoneIphone',       TRUE,  TRUE, 18)
ON CONFLICT ("Code", "CountryCode") DO NOTHING;

-- ============================================================
-- SEED: Payment Providers
-- ============================================================
INSERT INTO pay."PaymentProviders" ("Code", "Name", "CountryCode", "ProviderType", "BaseUrlSandbox", "BaseUrlProd", "AuthType", "DocsUrl", "LogoUrl")
VALUES
    ('MERCANTIL',    'Banco Mercantil - API Payment',    'VE', 'BANK_API',
     'https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1',
     'https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1',
     'API_KEY', 'https://apiportal.mercantilbanco.com/mercantil-banco/produccion/product', NULL),
    ('BINANCE',      'Binance Pay',                      NULL, 'CRYPTO_EXCHANGE',
     'https://bpay.binanceapi.com', 'https://bpay.binanceapi.com',
     'HMAC', 'https://developers.binance.com/docs/binance-pay', NULL),
    ('STRIPE',       'Stripe',                           NULL, 'PAYMENT_GATEWAY',
     'https://api.stripe.com', 'https://api.stripe.com',
     'API_KEY', 'https://docs.stripe.com/', NULL),
    ('REDSYS',       'Redsys (Espana)',                  'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/realizarPago', 'https://sis.redsys.es/sis/realizarPago',
     'HMAC', 'https://pagosonline.redsys.es/desarrolladores.html', NULL),
    ('BANESCO',      'Banco Banesco - Pago Movil',       'VE', 'BANK_API', NULL, NULL, 'API_KEY', NULL, NULL),
    ('PROVINCIAL',   'BBVA Provincial',                  'VE', 'BANK_API', NULL, NULL, 'API_KEY', NULL, NULL),
    ('BDV',          'Banco de Venezuela',               'VE', 'BANK_API', NULL, NULL, 'API_KEY', 'https://www.bancodevenezuela.com/', NULL),
    ('BANCA_AMIGA',  'Banca Amiga',                      'VE', 'BANK_API', NULL, NULL, 'API_KEY', 'https://www.bancaamiga.com/', NULL),
    ('CAIXABANK',    'CaixaBank (via Redsys)',           'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST', 'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC', 'https://www.caixabank.es/empresa/tpv-virtual.html', NULL),
    ('BBVA_ES',      'BBVA Espana (via Redsys)',         'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST', 'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC', 'https://www.bbva.es/empresas/productos/cobros/tpv-virtual.html', NULL),
    ('SANTANDER_ES', 'Banco Santander Espana (via Redsys)', 'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST', 'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC', 'https://www.bancosantander.es/empresas/cobros-pagos/tpv', NULL),
    ('SABADELL',     'Banco Sabadell (via Redsys)',      'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST', 'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC', 'https://www.bancsabadell.com/cs/Satellite/SabAtl/TPV-virtual/6000002059', NULL),
    ('BANKINTER',    'Bankinter (via Redsys)',           'ES', 'CARD_PROCESSOR',
     'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST', 'https://sis.redsys.es/sis/rest/trataPeticionREST',
     'HMAC', 'https://www.bankinter.com/banca/nav/empresas', NULL)
ON CONFLICT ("Code") DO NOTHING;

-- ============================================================
-- SEED: Provider Capabilities (Mercantil, Redsys, Binance, Spanish banks)
-- Using DO block to resolve provider IDs dynamically
-- ============================================================
DO $$
DECLARE
    v_provider_id INT;
    v_bank_code VARCHAR(30);
    v_bank_codes VARCHAR(30)[] := ARRAY['REDSYS', 'CAIXABANK', 'BBVA_ES', 'SANTANDER_ES', 'SABADELL', 'BANKINTER'];
BEGIN
    -- Redsys and Spanish bank capabilities
    FOREACH v_bank_code IN ARRAY v_bank_codes
    LOOP
        SELECT "Id" INTO v_provider_id FROM pay."PaymentProviders" WHERE "Code" = v_bank_code;
        IF v_provider_id IS NOT NULL THEN
            INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod")
            VALUES
                (v_provider_id, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
                (v_provider_id, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
            ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
        END IF;
    END LOOP;

    -- Binance Pay capabilities
    SELECT "Id" INTO v_provider_id FROM pay."PaymentProviders" WHERE "Code" = 'BINANCE';
    IF v_provider_id IS NOT NULL THEN
        INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod")
        VALUES
            (v_provider_id, 'SALE',   'CRYPTO_USDT', '/binancepay/openapi/v2/order',        'POST'),
            (v_provider_id, 'SALE',   'CRYPTO_BTC',  '/binancepay/openapi/v2/order',        'POST'),
            (v_provider_id, 'SALE',   'BINANCE_PAY', '/binancepay/openapi/v2/order',        'POST'),
            (v_provider_id, 'SEARCH', NULL,          '/binancepay/openapi/v2/order/query',  'POST'),
            (v_provider_id, 'VOID',   NULL,          '/binancepay/openapi/v2/order/close',  'POST'),
            (v_provider_id, 'REFUND', NULL,          '/binancepay/openapi/v3/order/refund', 'POST')
        ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
    END IF;

    -- Mercantil capabilities
    SELECT "Id" INTO v_provider_id FROM pay."PaymentProviders" WHERE "Code" = 'MERCANTIL';
    IF v_provider_id IS NOT NULL THEN
        INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod")
        VALUES
            (v_provider_id, 'SALE',      'C2P',      '/payment/c2p',             'POST'),
            (v_provider_id, 'REFUND',    'C2P',      '/payment/c2p',             'POST'),
            (v_provider_id, 'VOID',      'C2P',      '/payment/c2p',             'POST'),
            (v_provider_id, 'SCP',       'C2P',      '/mobile-payment/scp',      'POST'),
            (v_provider_id, 'SEARCH',    'C2P',      '/mobile-payment/search',   'POST'),
            (v_provider_id, 'AUTH',      'TDD',      '/payment/getauth',         'POST'),
            (v_provider_id, 'SALE',      'TDC',      '/payment/pay',             'POST'),
            (v_provider_id, 'SALE',      'TDD',      '/payment/pay',             'POST'),
            (v_provider_id, 'SEARCH',    'TDC',      '/payment/search',          'POST'),
            (v_provider_id, 'SEARCH',    'TDD',      '/payment/search',          'POST'),
            (v_provider_id, 'SEARCH',    'TRANSFER', '/payment/transfer-search', 'POST'),
            (v_provider_id, 'RECONCILE', NULL,        '/payment/search',          'POST')
        ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
    END IF;
END;
$$;
