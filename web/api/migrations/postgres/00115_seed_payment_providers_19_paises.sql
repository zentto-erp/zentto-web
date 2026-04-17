-- +goose Up

-- Seed pay.PaymentProviders para 19 paises.
-- Pasarelas de pago locales y globales operativas en cada pais.
-- Excluye ES (cubierto por migracion del agente Espana).
-- ProviderType: CARDS / WALLET / BANK_TRANSFER / QR / AGGREGATOR / CASH.
--
-- IDEMPOTENCIA: UPSERT con ON CONFLICT (CountryCode, Code).
-- No se usa DELETE porque pay.AcceptedPaymentMethods tiene FK a PaymentProviders
-- (AcceptedPaymentMethods_ProviderId_fkey, SQLSTATE 23503).

-- Agregar UK (CountryCode, Code) si no existe para permitir UPSERT
-- +goose StatementBegin
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'UQ_pay_PaymentProviders_Country_Code'
      AND conrelid = 'pay."PaymentProviders"'::regclass
  ) THEN
    ALTER TABLE pay."PaymentProviders"
    ADD CONSTRAINT "UQ_pay_PaymentProviders_Country_Code" UNIQUE ("CountryCode","Code");
  END IF;
END $$;
-- +goose StatementEnd

-- Venezuela
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('MERCANTIL_VE', 'Banco Mercantil API C2P',    'VE', 'BANK_TRANSFER', 'OAUTH2', 'https://www.mercantilbanco.com', TRUE),
  ('BANESCO_VE',   'Banesco Pagomovil',          'VE', 'BANK_TRANSFER', 'API_KEY','https://www.banesco.com',       TRUE),
  ('ZELLE_VE',     'Zelle (cuentas US)',         'VE', 'WALLET',        'OAUTH2', 'https://www.zellepay.com',      TRUE),
  ('BINANCE_VE',   'Binance Pay Crypto',         'VE', 'AGGREGATOR',    'API_KEY','https://www.binance.com/pay',   TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Argentina
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('MERCADOPAGO_AR', 'Mercado Pago Argentina',    'AR', 'AGGREGATOR','OAUTH2','https://www.mercadopago.com.ar/developers', TRUE),
  ('MODO_AR',        'MODO Billetera',             'AR', 'WALLET',    'OAUTH2','https://www.modo.com.ar',                  TRUE),
  ('PAYU_AR',        'PayU LATAM Argentina',       'AR', 'AGGREGATOR','API_KEY','https://developers.payulatam.com',        TRUE),
  ('STRIPE_AR',      'Stripe Argentina',           'AR', 'CARDS',     'API_KEY','https://stripe.com/docs',                 TRUE),
  ('DLOCAL_AR',      'dLocal Argentina',           'AR', 'AGGREGATOR','API_KEY','https://docs.dlocal.com',                 TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Colombia
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('PAYU_CO',    'PayU LATAM Colombia',     'CO', 'AGGREGATOR','API_KEY','https://developers.payulatam.com', TRUE),
  ('WOMPI_CO',   'Wompi (Bancolombia)',     'CO', 'AGGREGATOR','API_KEY','https://docs.wompi.co',            TRUE),
  ('NEQUI_CO',   'Nequi',                    'CO', 'WALLET',    'OAUTH2', 'https://www.nequi.com.co',         TRUE),
  ('EPAYCO_CO',  'ePayco',                   'CO', 'AGGREGATOR','API_KEY','https://docs.epayco.co',           TRUE),
  ('BOLD_CO',    'Bold Colombia',            'CO', 'AGGREGATOR','API_KEY','https://developers.bold.co',       TRUE),
  ('MERCADOPAGO_CO','Mercado Pago Colombia','CO', 'AGGREGATOR','OAUTH2','https://www.mercadopago.com.co/developers', TRUE),
  ('STRIPE_CO',  'Stripe Colombia',          'CO', 'CARDS',     'API_KEY','https://stripe.com/docs',          TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Mexico
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('MERCADOPAGO_MX','Mercado Pago Mexico',  'MX','AGGREGATOR','OAUTH2', 'https://www.mercadopago.com.mx/developers', TRUE),
  ('STRIPE_MX',     'Stripe Mexico',         'MX','CARDS',     'API_KEY','https://stripe.com/docs',                 TRUE),
  ('OPENPAY_MX',    'OpenPay',               'MX','AGGREGATOR','API_KEY','https://www.openpay.mx/docs',             TRUE),
  ('CONEKTA_MX',    'Conekta',               'MX','AGGREGATOR','API_KEY','https://developers.conekta.com',          TRUE),
  ('CLIP_MX',       'Clip POS',              'MX','CARDS',     'API_KEY','https://www.clip.mx',                     TRUE),
  ('PAYPAL_MX',     'PayPal Mexico',         'MX','WALLET',    'OAUTH2', 'https://developer.paypal.com',            TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Chile
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('WEBPAY_CL',     'Webpay Plus (Transbank)','CL','CARDS',     'CERT',    'https://www.transbankdevelopers.cl', TRUE),
  ('MERCADOPAGO_CL','Mercado Pago Chile',    'CL','AGGREGATOR','OAUTH2',  'https://www.mercadopago.cl/developers', TRUE),
  ('KHIPU_CL',      'Khipu',                  'CL','BANK_TRANSFER','API_KEY','https://khipu.com/page/api-referencia', TRUE),
  ('FLOW_CL',       'Flow',                   'CL','AGGREGATOR','API_KEY', 'https://www.flow.cl/docs',           TRUE),
  ('STRIPE_CL',     'Stripe Chile',           'CL','CARDS',     'API_KEY', 'https://stripe.com/docs',            TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Peru
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('CULQI_PE',      'Culqi',                  'PE','AGGREGATOR','API_KEY','https://docs.culqi.com',   TRUE),
  ('NIUBIZ_PE',     'Niubiz (VisaNet Peru)', 'PE','CARDS',     'CERT',   'https://desarrolladores.niubiz.com.pe', TRUE),
  ('YAPE_PE',       'Yape (BCP)',             'PE','WALLET',    'OAUTH2', 'https://yape.com.pe',       TRUE),
  ('PLIN_PE',       'Plin',                   'PE','WALLET',    'OAUTH2', 'https://www.plin.pe',       TRUE),
  ('IZIPAY_PE',     'Izipay',                 'PE','AGGREGATOR','API_KEY','https://docs.izipay.pe',    TRUE),
  ('MERCADOPAGO_PE','Mercado Pago Peru',     'PE','AGGREGATOR','OAUTH2', 'https://www.mercadopago.com.pe/developers', TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Ecuador
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('PAYPHONE_EC',   'PayPhone',              'EC','WALLET',    'OAUTH2','https://payphone.com/docs',             TRUE),
  ('KUSHKI_EC',     'Kushki',                 'EC','AGGREGATOR','API_KEY','https://docs.kushkipagos.com',       TRUE),
  ('PLACETOPAY_EC', 'PlaceToPay Ecuador',    'EC','AGGREGATOR','API_KEY','https://docs.placetopay.com',         TRUE),
  ('DATAFAST_EC',   'Datafast (Banred)',     'EC','CARDS',     'CERT',   'https://www.datafast.com.ec',         TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Bolivia
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('TIGOMONEY_BO',  'Tigo Money Bolivia',    'BO','WALLET',    'OAUTH2','https://www.tigo.com.bo',          TRUE),
  ('QR_SIMPLE_BO',  'QR Simple BCB',         'BO','QR',        'API_KEY','https://www.bcb.gob.bo',          TRUE),
  ('LIBELULA_BO',   'Libelula',              'BO','AGGREGATOR','API_KEY','https://www.libelula.bo',         TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Uruguay
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('MERCADOPAGO_UY','Mercado Pago Uruguay',  'UY','AGGREGATOR','OAUTH2','https://www.mercadopago.com.uy/developers', TRUE),
  ('REDPAGOS_UY',   'Redpagos',              'UY','CASH',      'API_KEY','https://www.redpagos.com.uy',     TRUE),
  ('ABITAB_UY',     'Abitab',                 'UY','CASH',      'API_KEY','https://www.abitab.com.uy',       TRUE),
  ('SCANNTECH_UY',  'Scanntech',             'UY','AGGREGATOR','API_KEY','https://www.scanntech.com',       TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Paraguay
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('BANCARD_PY',    'Bancard VPos',          'PY','CARDS',     'CERT',   'https://www.bancard.com.py',    TRUE),
  ('INFINITA_PY',   'Infinita Pagos',        'PY','AGGREGATOR','API_KEY','https://www.infinita.com.py',   TRUE),
  ('ZIMPLE_PY',     'Zimple Itau',           'PY','WALLET',    'OAUTH2', 'https://www.itau.com.py',       TRUE),
  ('PAGOPAR_PY',    'Pagopar',                'PY','AGGREGATOR','API_KEY','https://www.pagopar.com',       TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Panama
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('YAPPY_PA',      'Yappy (Banco General)', 'PA','WALLET',    'OAUTH2','https://www.yappy.com.pa',     TRUE),
  ('CLAVE_PA',      'Clave (ACH Panama)',    'PA','BANK_TRANSFER','API_KEY','https://www.clave.com.pa', TRUE),
  ('VISANET_PA',    'VisaNet Panama',        'PA','CARDS',     'CERT',  'https://www.visanetpa.com',    TRUE),
  ('NEQUI_PA',      'Nequi Panama',          'PA','WALLET',    'OAUTH2','https://www.nequi.com',        TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Costa Rica
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('BAC_CR',        'BAC Credomatic Pasarela','CR','CARDS',    'CERT',   'https://www.baccredomatic.com', TRUE),
  ('GREENPAY_CR',   'Greenpay',              'CR','AGGREGATOR','API_KEY','https://greenpay.me',          TRUE),
  ('TILOPAY_CR',    'Tilopay',               'CR','AGGREGATOR','API_KEY','https://www.tilopay.com',      TRUE),
  ('SINPE_CR',      'SINPE Movil BCCR',      'CR','BANK_TRANSFER','API_KEY','https://www.bccr.fi.cr',    TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Republica Dominicana
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('CARDNET_DO',    'CardNet',               'DO','CARDS',     'CERT',   'https://www.cardnet.com.do',  TRUE),
  ('AZUL_DO',       'Azul',                  'DO','CARDS',     'CERT',   'https://dev.azul.com.do',     TRUE),
  ('TPAGO_DO',      'tPago',                 'DO','WALLET',    'OAUTH2', 'https://www.tpago.com',       TRUE),
  ('PAYPAL_DO',     'PayPal DO',             'DO','WALLET',    'OAUTH2', 'https://developer.paypal.com',TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Guatemala
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('VISANET_GT',    'VisaNet Guatemala',     'GT','CARDS',     'CERT',   'https://www.visanet.com.gt',  TRUE),
  ('BAC_GT',        'BAC Credomatic GT',     'GT','CARDS',     'CERT',   'https://www.baccredomatic.com',TRUE),
  ('TIGOMONEY_GT',  'Tigo Money Guatemala',  'GT','WALLET',    'OAUTH2', 'https://www.tigo.com.gt',     TRUE),
  ('CYBERSOURCE_GT','CyberSource GT',        'GT','AGGREGATOR','API_KEY','https://developer.cybersource.com', TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Honduras
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('BAC_HN',        'BAC Credomatic HN',     'HN','CARDS',     'CERT',   'https://www.baccredomatic.com',TRUE),
  ('TIGOMONEY_HN',  'Tigo Money Honduras',   'HN','WALLET',    'OAUTH2', 'https://www.tigo.com.hn',     TRUE),
  ('BANPAIS_HN',    'Banpais Pasarela',      'HN','CARDS',     'CERT',   'https://www.banpaishn.com',   TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Nicaragua
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('BAC_NI',        'BAC Credomatic NI',     'NI','CARDS',     'CERT',   'https://www.baccredomatic.com',TRUE),
  ('TIGOMONEY_NI',  'Tigo Money Nicaragua',  'NI','WALLET',    'OAUTH2', 'https://www.tigo.com.ni',     TRUE),
  ('LAFISE_NI',     'LAFISE Pasarela',       'NI','CARDS',     'CERT',   'https://www.lafise.com',      TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- El Salvador
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('BAC_SV',        'BAC Credomatic SV',     'SV','CARDS',     'CERT',   'https://www.baccredomatic.com',TRUE),
  ('TIGOMONEY_SV',  'Tigo Money El Salvador','SV','WALLET',    'OAUTH2', 'https://www.tigo.com.sv',     TRUE),
  ('WOMPI_SV',      'Wompi El Salvador',     'SV','AGGREGATOR','API_KEY','https://wompi.sv',            TRUE),
  ('N1CO_SV',       'n1co',                  'SV','AGGREGATOR','API_KEY','https://www.n1co.com',        TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Cuba
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('ENZONA_CU',     'EnZona',                'CU','WALLET',    'API_KEY','https://www.enzona.net',      TRUE),
  ('TRANSFERMOVIL_CU','Transfermovil',       'CU','WALLET',    'API_KEY','https://www.transfermovil.cu',TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Puerto Rico
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('STRIPE_PR',     'Stripe Puerto Rico',    'PR','CARDS',     'API_KEY','https://stripe.com/docs',     TRUE),
  ('PAYPAL_PR',     'PayPal Puerto Rico',    'PR','WALLET',    'OAUTH2', 'https://developer.paypal.com',TRUE),
  ('ATH_MOVIL_PR',  'ATH Movil',             'PR','WALLET',    'API_KEY','https://business.athmovil.com',TRUE),
  ('SQUARE_PR',     'Square POS',            'PR','CARDS',     'OAUTH2', 'https://developer.squareup.com',TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- Estados Unidos
-- +goose StatementBegin
INSERT INTO pay."PaymentProviders" ("Code","Name","CountryCode","ProviderType","AuthType","DocsUrl","IsActive") VALUES
  ('STRIPE_US',     'Stripe USA',            'US','CARDS',     'API_KEY','https://stripe.com/docs',         TRUE),
  ('PAYPAL_US',     'PayPal USA',            'US','WALLET',    'OAUTH2', 'https://developer.paypal.com',    TRUE),
  ('SQUARE_US',     'Square',                'US','CARDS',     'OAUTH2', 'https://developer.squareup.com',  TRUE),
  ('AUTHORIZE_US',  'Authorize.Net',         'US','CARDS',     'API_KEY','https://developer.authorize.net', TRUE),
  ('BRAINTREE_US',  'Braintree (PayPal)',    'US','CARDS',     'API_KEY','https://developer.paypal.com/braintree', TRUE),
  ('VENMO_US',      'Venmo Business',        'US','WALLET',    'OAUTH2', 'https://venmo.com',               TRUE),
  ('ZELLE_US',      'Zelle',                 'US','BANK_TRANSFER','OAUTH2','https://www.zellepay.com',      TRUE)
ON CONFLICT ("CountryCode","Code") DO UPDATE SET
  "Name"=EXCLUDED."Name","ProviderType"=EXCLUDED."ProviderType","AuthType"=EXCLUDED."AuthType",
  "DocsUrl"=EXCLUDED."DocsUrl","IsActive"=EXCLUDED."IsActive";
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM pay."PaymentProviders"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- +goose StatementBegin
ALTER TABLE pay."PaymentProviders"
DROP CONSTRAINT IF EXISTS "UQ_pay_PaymentProviders_Country_Code";
-- +goose StatementEnd
