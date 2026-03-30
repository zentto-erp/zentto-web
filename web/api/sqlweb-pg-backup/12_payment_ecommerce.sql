-- ============================================================
-- DatqBoxWeb PostgreSQL - 12_payment_ecommerce.sql
-- Payment gateway + E-commerce tables
-- ============================================================

BEGIN;

-- Crear schemas si no existen
CREATE SCHEMA IF NOT EXISTS pay;
CREATE SCHEMA IF NOT EXISTS store;

-- ============================================================
-- PAYMENT GATEWAY TABLES (pay.*)
-- ============================================================

-- ============================================================
-- 1. pay."PaymentMethods" (catalogo global de formas de pago)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentMethods" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Code"            VARCHAR(30)  NOT NULL,
  "Name"            VARCHAR(100) NOT NULL,
  "Category"        VARCHAR(30)  NOT NULL,
  "CountryCode"     CHAR(2)      NULL,
  "IconName"        VARCHAR(50)  NULL,
  "RequiresGateway" BOOLEAN      DEFAULT FALSE,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "SortOrder"       INT          DEFAULT 0,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_PayMethod" UNIQUE ("Code", "CountryCode")
);

-- ============================================================
-- 2. pay."PaymentProviders" (Mercantil, Stripe, Binance, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."PaymentProviders" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "Code"            VARCHAR(30)  NOT NULL UNIQUE,
  "Name"            VARCHAR(150) NOT NULL,
  "CountryCode"     CHAR(2)      NULL,
  "ProviderType"    VARCHAR(30)  NOT NULL,
  "BaseUrlSandbox"  VARCHAR(500) NULL,
  "BaseUrlProd"     VARCHAR(500) NULL,
  "AuthType"        VARCHAR(30)  NULL,
  "DocsUrl"         VARCHAR(500) NULL,
  "LogoUrl"         VARCHAR(500) NULL,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- 3. pay."ProviderCapabilities"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ProviderCapabilities" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ProviderId"      INT          NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "Capability"      VARCHAR(50)  NOT NULL,
  "PaymentMethod"   VARCHAR(30)  NULL,
  "EndpointPath"    VARCHAR(200) NULL,
  "HttpMethod"      VARCHAR(10)  DEFAULT 'POST',
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  CONSTRAINT "UQ_ProvCap" UNIQUE ("ProviderId", "Capability", "PaymentMethod")
);

-- ============================================================
-- 4. pay."CompanyPaymentConfig"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CompanyPaymentConfig" (
  "Id"              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"       INT          NOT NULL,
  "SucursalId"      INT          NOT NULL DEFAULT 0,
  "CountryCode"     CHAR(2)      NOT NULL,
  "ProviderId"      INT          NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "Environment"     VARCHAR(10)  DEFAULT 'sandbox',
  "ClientId"        VARCHAR(500) NULL,
  "ClientSecret"    VARCHAR(500) NULL,
  "MerchantId"      VARCHAR(100) NULL,
  "TerminalId"      VARCHAR(100) NULL,
  "IntegratorId"    VARCHAR(50)  NULL,
  "CertificatePath" VARCHAR(500) NULL,
  "ExtraConfig"     TEXT         NULL,
  "AutoCapture"     BOOLEAN      DEFAULT TRUE,
  "AllowRefunds"    BOOLEAN      DEFAULT TRUE,
  "MaxRefundDays"   INT          DEFAULT 30,
  "IsActive"        BOOLEAN      DEFAULT TRUE,
  "CreatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"       TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_CompanyPayConfig" UNIQUE ("EmpresaId", "SucursalId", "ProviderId")
);

-- ============================================================
-- 5. pay."AcceptedPaymentMethods"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."AcceptedPaymentMethods" (
  "Id"                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"           INT            NOT NULL,
  "SucursalId"          INT            NOT NULL DEFAULT 0,
  "PaymentMethodId"     INT            NOT NULL REFERENCES pay."PaymentMethods"("Id"),
  "ProviderId"          INT            NULL REFERENCES pay."PaymentProviders"("Id"),
  "AppliesToPOS"        BOOLEAN        DEFAULT TRUE,
  "AppliesToWeb"        BOOLEAN        DEFAULT TRUE,
  "AppliesToRestaurant" BOOLEAN        DEFAULT TRUE,
  "MinAmount"           NUMERIC(18,2)  NULL,
  "MaxAmount"           NUMERIC(18,2)  NULL,
  "CommissionPct"       NUMERIC(5,4)   NULL,
  "CommissionFixed"     NUMERIC(18,2)  NULL,
  "IsActive"            BOOLEAN        DEFAULT TRUE,
  "SortOrder"           INT            DEFAULT 0,
  CONSTRAINT "UQ_AcceptedPM" UNIQUE ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId")
);

-- ============================================================
-- 6. pay."Transactions" (log de transacciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."Transactions" (
  "Id"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "TransactionUUID"   VARCHAR(36)    NOT NULL UNIQUE,
  "EmpresaId"         INT            NOT NULL,
  "SucursalId"        INT            NOT NULL DEFAULT 0,
  "SourceType"        VARCHAR(30)    NOT NULL,
  "SourceId"          INT            NULL,
  "SourceNumber"      VARCHAR(50)    NULL,
  "PaymentMethodCode" VARCHAR(30)    NOT NULL,
  "ProviderId"        INT            NULL REFERENCES pay."PaymentProviders"("Id"),
  "Currency"          VARCHAR(3)     NOT NULL,
  "Amount"            NUMERIC(18,2)  NOT NULL,
  "CommissionAmount"  NUMERIC(18,2)  NULL,
  "NetAmount"         NUMERIC(18,2)  NULL,
  "ExchangeRate"      NUMERIC(18,6)  NULL,
  "AmountInBase"      NUMERIC(18,2)  NULL,
  "TrxType"           VARCHAR(20)    NOT NULL,
  "Status"            VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
  "GatewayTrxId"      VARCHAR(100)   NULL,
  "GatewayAuthCode"   VARCHAR(50)    NULL,
  "GatewayResponse"   TEXT           NULL,
  "GatewayMessage"    VARCHAR(500)   NULL,
  "CardLastFour"      VARCHAR(4)     NULL,
  "CardBrand"         VARCHAR(20)    NULL,
  "MobileNumber"      VARCHAR(20)    NULL,
  "BankCode"          VARCHAR(10)    NULL,
  "PaymentRef"        VARCHAR(50)    NULL,
  "IsReconciled"      BOOLEAN        DEFAULT FALSE,
  "ReconciledAt"      TIMESTAMP      NULL,
  "ReconciliationId"  BIGINT         NULL,
  "StationId"         VARCHAR(50)    NULL,
  "CashierId"         VARCHAR(20)    NULL,
  "IpAddress"         VARCHAR(45)    NULL,
  "UserAgent"         VARCHAR(500)   NULL,
  "Notes"             VARCHAR(500)   NULL,
  "CreatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_PayTrx_Source"
  ON pay."Transactions" ("SourceType", "SourceId");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Status"
  ON pay."Transactions" ("Status", "CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_PayTrx_Recon"
  ON pay."Transactions" ("IsReconciled", "ProviderId");

-- ============================================================
-- 7. pay."ReconciliationBatches"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."ReconciliationBatches" (
  "Id"                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"         INT            NOT NULL,
  "ProviderId"        INT            NOT NULL REFERENCES pay."PaymentProviders"("Id"),
  "DateFrom"          DATE           NOT NULL,
  "DateTo"            DATE           NOT NULL,
  "TotalTransactions" INT            DEFAULT 0,
  "TotalAmount"       NUMERIC(18,2)  DEFAULT 0,
  "MatchedCount"      INT            DEFAULT 0,
  "UnmatchedCount"    INT            DEFAULT 0,
  "Status"            VARCHAR(20)    DEFAULT 'PENDING',
  "ResultJson"        TEXT           NULL,
  "CreatedAt"         TIMESTAMP      DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CompletedAt"       TIMESTAMP      NULL,
  "UserId"            VARCHAR(20)    NULL
);

-- ============================================================
-- 8. pay."CardReaderDevices"
-- ============================================================
CREATE TABLE IF NOT EXISTS pay."CardReaderDevices" (
  "Id"               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "EmpresaId"        INT          NOT NULL,
  "SucursalId"       INT          NOT NULL DEFAULT 0,
  "StationId"        VARCHAR(50)  NOT NULL,
  "DeviceName"       VARCHAR(100) NOT NULL,
  "DeviceType"       VARCHAR(30)  NOT NULL,
  "ConnectionType"   VARCHAR(30)  NOT NULL,
  "ConnectionConfig" VARCHAR(500) NULL,
  "ProviderId"       INT          NULL REFERENCES pay."PaymentProviders"("Id"),
  "IsActive"         BOOLEAN      DEFAULT TRUE,
  "LastSeenAt"       TIMESTAMP    NULL,
  "CreatedAt"        TIMESTAMP    DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- ============================================================
-- E-COMMERCE TABLES (store.*)
-- ============================================================

-- ============================================================
-- 9. store."ProductReview" (resenas de productos)
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductReview" (
  "ReviewId"      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "ProductCode"   VARCHAR(80)  NOT NULL,
  "Rating"        INT          NOT NULL CHECK ("Rating" BETWEEN 1 AND 5),
  "Title"         VARCHAR(200) NULL,
  "Comment"       VARCHAR(2000) NOT NULL,
  "ReviewerName"  VARCHAR(200) NOT NULL DEFAULT 'Cliente',
  "ReviewerEmail" VARCHAR(150) NULL,
  "IsVerified"    BOOLEAN      NOT NULL DEFAULT FALSE,
  "IsApproved"    BOOLEAN      NOT NULL DEFAULT TRUE,
  "IsDeleted"     BOOLEAN      NOT NULL DEFAULT FALSE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductReview_Product"
  ON store."ProductReview" ("CompanyId", "ProductCode", "IsDeleted", "IsApproved");

-- ============================================================
-- 10. store."ProductHighlight" (bullets "Acerca de este articulo")
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductHighlight" (
  "HighlightId"   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"     INT          NOT NULL DEFAULT 1,
  "ProductCode"   VARCHAR(80)  NOT NULL,
  "SortOrder"     INT          NOT NULL DEFAULT 0,
  "HighlightText" VARCHAR(500) NOT NULL,
  "IsActive"      BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductHighlight_Product"
  ON store."ProductHighlight" ("CompanyId", "ProductCode", "IsActive");

-- ============================================================
-- 11. store."ProductSpec" (especificaciones tecnicas key-value)
-- ============================================================
CREATE TABLE IF NOT EXISTS store."ProductSpec" (
  "SpecId"       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"    INT          NOT NULL DEFAULT 1,
  "ProductCode"  VARCHAR(80)  NOT NULL,
  "SpecGroup"    VARCHAR(100) NOT NULL DEFAULT 'General',
  "SpecKey"      VARCHAR(100) NOT NULL,
  "SpecValue"    VARCHAR(500) NOT NULL,
  "SortOrder"    INT          NOT NULL DEFAULT 0,
  "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"    TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ProductSpec_Product"
  ON store."ProductSpec" ("CompanyId", "ProductCode", "IsActive");

-- ============================================================
-- SEED: Metodos de pago globales
-- ============================================================
INSERT INTO pay."PaymentMethods" ("Code", "Name", "Category", "CountryCode", "IconName", "RequiresGateway", "IsActive", "SortOrder") VALUES
  ('EFECTIVO',    'Efectivo',                     'CASH',          NULL, 'Payments',           FALSE, TRUE, 1),
  ('TDC',         'Tarjeta de Credito',           'CARD',          NULL, 'CreditCard',         TRUE,  TRUE, 2),
  ('TDD',         'Tarjeta de Debito',            'CARD',          NULL, 'CreditCard',         TRUE,  TRUE, 3),
  ('C2P',         'Pago Movil (C2P)',             'MOBILE',        'VE', 'PhoneIphone',        TRUE,  TRUE, 4),
  ('TRANSFER',    'Transferencia Bancaria',       'TRANSFER',      NULL, 'AccountBalance',     FALSE, TRUE, 5),
  ('ZELLE',       'Zelle',                        'TRANSFER',      'US', 'SwapHoriz',          FALSE, TRUE, 6),
  ('BIZUM',       'Bizum',                        'MOBILE',        'ES', 'PhoneIphone',        TRUE,  TRUE, 7),
  ('CRYPTO_USDT', 'USDT (Tether)',                'CRYPTO',        NULL, 'CurrencyBitcoin',    TRUE,  TRUE, 8),
  ('CRYPTO_BTC',  'Bitcoin',                      'CRYPTO',        NULL, 'CurrencyBitcoin',    TRUE,  TRUE, 9),
  ('BINANCE_PAY', 'Binance Pay',                  'DIGITAL_WALLET',NULL, 'AccountBalanceWallet',TRUE, TRUE, 10),
  ('PAYPAL',      'PayPal',                       'DIGITAL_WALLET',NULL, 'AccountBalanceWallet',TRUE, TRUE, 11),
  ('QR_PAY',      'Pago por QR',                  'QR',            NULL, 'QrCode2',            TRUE,  TRUE, 12),
  ('CHEQUE',      'Cheque',                       'OTHER',         NULL, 'Receipt',            FALSE, TRUE, 13),
  ('CREDITO',     'Credito / Fiado',              'OTHER',         NULL, 'CreditScore',        FALSE, TRUE, 14),
  ('BOTON_WEB',   'Boton de Pagos Web',           'DIGITAL_WALLET','VE', 'Language',           TRUE,  TRUE, 15),
  ('SDI',         'Solicitud Debito Inmediato',   'TRANSFER',      'VE', 'AccountBalance',     TRUE,  TRUE, 16),
  ('REDSYS',      'Redsys (TPV Virtual)',         'CARD',          'ES', 'CreditCard',         TRUE,  TRUE, 17),
  ('VUELTO_C2P',  'Vuelto Pago Movil',           'MOBILE',        'VE', 'PhoneIphone',        TRUE,  TRUE, 18)
ON CONFLICT ("Code", "CountryCode") DO NOTHING;

-- ============================================================
-- SEED: Proveedores de pago
-- ============================================================
INSERT INTO pay."PaymentProviders" ("Code", "Name", "CountryCode", "ProviderType", "BaseUrlSandbox", "BaseUrlProd", "AuthType", "DocsUrl", "LogoUrl") VALUES
  ('MERCANTIL',    'Banco Mercantil - API Payment',          'VE', 'BANK_API',
   'https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1',
   'https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1',
   'API_KEY',
   'https://apiportal.mercantilbanco.com/mercantil-banco/produccion/product', NULL),
  ('BINANCE',      'Binance Pay',                            NULL, 'CRYPTO_EXCHANGE',
   'https://bpay.binanceapi.com', 'https://bpay.binanceapi.com',
   'HMAC', 'https://developers.binance.com/docs/binance-pay', NULL),
  ('STRIPE',       'Stripe',                                 NULL, 'PAYMENT_GATEWAY',
   'https://api.stripe.com', 'https://api.stripe.com',
   'API_KEY', 'https://docs.stripe.com/', NULL),
  ('REDSYS',       'Redsys (Espana)',                        'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/realizarPago',
   'https://sis.redsys.es/sis/realizarPago',
   'HMAC', 'https://pagosonline.redsys.es/desarrolladores.html', NULL),
  ('BANESCO',      'Banco Banesco - Pago Movil',             'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', NULL, NULL),
  ('PROVINCIAL',   'BBVA Provincial',                        'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', NULL, NULL),
  ('BDV',          'Banco de Venezuela',                     'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', 'https://www.bancodevenezuela.com/', NULL),
  ('BANCA_AMIGA',  'Banca Amiga',                            'VE', 'BANK_API',
   NULL, NULL, 'API_KEY', 'https://www.bancaamiga.com/', NULL),
  ('CAIXABANK',    'CaixaBank (via Redsys)',                 'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.caixabank.es/empresa/tpv-virtual.html', NULL),
  ('BBVA_ES',      'BBVA Espana (via Redsys)',               'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bbva.es/empresas/productos/cobros/tpv-virtual.html', NULL),
  ('SANTANDER_ES', 'Banco Santander Espana (via Redsys)',    'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bancosantander.es/empresas/cobros-pagos/tpv', NULL),
  ('SABADELL',     'Banco Sabadell (via Redsys)',            'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bancsabadell.com/cs/Satellite/SabAtl/TPV-virtual/6000002059', NULL),
  ('BANKINTER',    'Bankinter (via Redsys)',                 'ES', 'CARD_PROCESSOR',
   'https://sis-t.redsys.es:25443/sis/rest/trataPeticionREST',
   'https://sis.redsys.es/sis/rest/trataPeticionREST',
   'HMAC', 'https://www.bankinter.com/banca/nav/empresas', NULL)
ON CONFLICT ("Code") DO NOTHING;

-- ============================================================
-- SEED: Capabilities para proveedores
-- ============================================================
DO $$
DECLARE
  v_redsysId    INT;
  v_binanceId   INT;
  v_mercantilId INT;
  v_bankId      INT;
  v_bankCode    VARCHAR(30);
  v_bankCodes   VARCHAR(30)[] := ARRAY['CAIXABANK','BBVA_ES','SANTANDER_ES','SABADELL','BANKINTER'];
BEGIN
  SELECT "Id" INTO v_redsysId FROM pay."PaymentProviders" WHERE "Code" = 'REDSYS';
  SELECT "Id" INTO v_binanceId FROM pay."PaymentProviders" WHERE "Code" = 'BINANCE';
  SELECT "Id" INTO v_mercantilId FROM pay."PaymentProviders" WHERE "Code" = 'MERCANTIL';

  -- Redsys capabilities
  IF v_redsysId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_redsysId, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
      (v_redsysId, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;

  -- Clonar capabilities para cada banco espanol
  FOREACH v_bankCode IN ARRAY v_bankCodes LOOP
    SELECT "Id" INTO v_bankId FROM pay."PaymentProviders" WHERE "Code" = v_bankCode;
    IF v_bankId IS NOT NULL THEN
      INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
        (v_bankId, 'SALE',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'SALE',    'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'AUTH',    'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'CAPTURE', 'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'REFUND',  'TDC',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'REFUND',  'TDD',   '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'VOID',    NULL,    '/sis/rest/trataPeticionREST', 'POST'),
        (v_bankId, 'SALE',    'BIZUM', '/sis/rest/trataPeticionREST', 'POST')
      ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
    END IF;
  END LOOP;

  -- Binance Pay capabilities
  IF v_binanceId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_binanceId, 'SALE',   'CRYPTO_USDT', '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SALE',   'CRYPTO_BTC',  '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SALE',   'BINANCE_PAY', '/binancepay/openapi/v2/order',        'POST'),
      (v_binanceId, 'SEARCH', NULL,          '/binancepay/openapi/v2/order/query',  'POST'),
      (v_binanceId, 'VOID',   NULL,          '/binancepay/openapi/v2/order/close',  'POST'),
      (v_binanceId, 'REFUND', NULL,          '/binancepay/openapi/v3/order/refund', 'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;

  -- Mercantil capabilities
  IF v_mercantilId IS NOT NULL THEN
    INSERT INTO pay."ProviderCapabilities" ("ProviderId", "Capability", "PaymentMethod", "EndpointPath", "HttpMethod") VALUES
      (v_mercantilId, 'SALE',       'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'REFUND',     'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'VOID',       'C2P',      '/payment/c2p',             'POST'),
      (v_mercantilId, 'SCP',        'C2P',      '/mobile-payment/scp',      'POST'),
      (v_mercantilId, 'SEARCH',     'C2P',      '/mobile-payment/search',   'POST'),
      (v_mercantilId, 'AUTH',       'TDD',      '/payment/getauth',         'POST'),
      (v_mercantilId, 'SALE',       'TDC',      '/payment/pay',             'POST'),
      (v_mercantilId, 'SALE',       'TDD',      '/payment/pay',             'POST'),
      (v_mercantilId, 'SEARCH',     'TDC',      '/payment/search',          'POST'),
      (v_mercantilId, 'SEARCH',     'TDD',      '/payment/search',          'POST'),
      (v_mercantilId, 'SEARCH',     'TRANSFER', '/payment/transfer-search', 'POST'),
      (v_mercantilId, 'RECONCILE',  NULL,       '/payment/search',          'POST')
    ON CONFLICT ("ProviderId", "Capability", "PaymentMethod") DO NOTHING;
  END IF;
END $$;

COMMIT;
