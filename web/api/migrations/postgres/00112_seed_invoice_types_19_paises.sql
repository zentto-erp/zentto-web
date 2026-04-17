-- +goose Up

-- Seed fiscal.InvoiceType para 19 paises.
-- Excluye ES (cubierto por migracion del agente Espana).
-- Fuente: autoridades tributarias de cada pais (AFIP, DIAN, SAT, SUNAT, SRI, SII, DGII, etc.)
-- Idempotente: DELETE + INSERT por UQ_fiscal_InvType (CountryCode, InvoiceTypeCode).

-- +goose StatementBegin
DELETE FROM fiscal."InvoiceType"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- Venezuela (SENIAT)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('VE','FACTURA','Factura',            FALSE, TRUE,  TRUE,  TRUE, 10),
  ('VE','NC',     'Nota de Credito',    TRUE,  TRUE,  TRUE,  TRUE, 20),
  ('VE','ND',     'Nota de Debito',     FALSE, TRUE,  TRUE,  TRUE, 30),
  ('VE','NE',     'Nota de Entrega',    FALSE, FALSE, FALSE, TRUE, 40);
-- +goose StatementEnd

-- Argentina (AFIP)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('AR','FA',    'Factura A (Resp. Inscripto)',       FALSE, TRUE,  FALSE, TRUE, 10),
  ('AR','FB',    'Factura B (Consumidor Final)',      FALSE, FALSE, FALSE, TRUE, 20),
  ('AR','FC',    'Factura C (Monotributista)',        FALSE, TRUE,  FALSE, TRUE, 30),
  ('AR','FE',    'Factura E (Exportacion)',           FALSE, TRUE,  FALSE, TRUE, 40),
  ('AR','FM',    'Factura M',                         FALSE, TRUE,  FALSE, TRUE, 50),
  ('AR','NCA',   'Nota Credito A',                    TRUE,  TRUE,  FALSE, TRUE, 60),
  ('AR','NCB',   'Nota Credito B',                    TRUE,  FALSE, FALSE, TRUE, 70),
  ('AR','NCC',   'Nota Credito C',                    TRUE,  TRUE,  FALSE, TRUE, 80),
  ('AR','NCE',   'Nota Credito E',                    TRUE,  TRUE,  FALSE, TRUE, 90),
  ('AR','NDA',   'Nota Debito A',                     FALSE, TRUE,  FALSE, TRUE, 100),
  ('AR','NDB',   'Nota Debito B',                     FALSE, FALSE, FALSE, TRUE, 110),
  ('AR','FCEA',  'Factura Credito Electronica A',     FALSE, TRUE,  FALSE, TRUE, 120);
-- +goose StatementEnd

-- Colombia (DIAN)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('CO','FE',   'Factura Electronica de Venta',          FALSE, TRUE,  FALSE, TRUE, 10),
  ('CO','NCE',  'Nota Credito Electronica',              TRUE,  TRUE,  FALSE, TRUE, 20),
  ('CO','NDE',  'Nota Debito Electronica',               FALSE, TRUE,  FALSE, TRUE, 30),
  ('CO','DS',   'Documento Soporte Adquisicion',         FALSE, TRUE,  FALSE, TRUE, 40),
  ('CO','DSNC', 'Doc Soporte No Obligados Facturar',     FALSE, FALSE, FALSE, TRUE, 50),
  ('CO','FEC',  'Factura Electronica Contingencia',      FALSE, TRUE,  FALSE, TRUE, 60);
-- +goose StatementEnd

-- Mexico (SAT CFDI 4.0)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('MX','I',  'CFDI Ingreso',   FALSE, TRUE,  FALSE, TRUE, 10),
  ('MX','E',  'CFDI Egreso',    TRUE,  TRUE,  FALSE, TRUE, 20),
  ('MX','T',  'CFDI Traslado',  FALSE, TRUE,  FALSE, TRUE, 30),
  ('MX','N',  'CFDI Nomina',    FALSE, TRUE,  FALSE, TRUE, 40),
  ('MX','P',  'CFDI Pago',      FALSE, TRUE,  FALSE, TRUE, 50);
-- +goose StatementEnd

-- Peru (SUNAT)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('PE','01', 'Factura',                 FALSE, TRUE,  FALSE, TRUE, 10),
  ('PE','03', 'Boleta de Venta',         FALSE, FALSE, FALSE, TRUE, 20),
  ('PE','07', 'Nota de Credito',         TRUE,  TRUE,  FALSE, TRUE, 30),
  ('PE','08', 'Nota de Debito',          FALSE, TRUE,  FALSE, TRUE, 40),
  ('PE','09', 'Guia de Remision Remite', FALSE, TRUE,  FALSE, TRUE, 50),
  ('PE','20', 'Comprobante Retencion',   FALSE, TRUE,  FALSE, TRUE, 60),
  ('PE','40', 'Comprobante Percepcion',  FALSE, TRUE,  FALSE, TRUE, 70);
-- +goose StatementEnd

-- Ecuador (SRI)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('EC','01', 'Factura',                  FALSE, TRUE,  FALSE, TRUE, 10),
  ('EC','03', 'Liquidacion de Compra',    FALSE, TRUE,  FALSE, TRUE, 20),
  ('EC','04', 'Nota de Credito',          TRUE,  TRUE,  FALSE, TRUE, 30),
  ('EC','05', 'Nota de Debito',           FALSE, TRUE,  FALSE, TRUE, 40),
  ('EC','06', 'Guia de Remision',         FALSE, TRUE,  FALSE, TRUE, 50),
  ('EC','07', 'Comprobante de Retencion', FALSE, TRUE,  FALSE, TRUE, 60);
-- +goose StatementEnd

-- Chile (SII)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('CL','33', 'Factura Electronica',            FALSE, TRUE,  FALSE, TRUE, 10),
  ('CL','34', 'Factura Exenta Electronica',     FALSE, TRUE,  FALSE, TRUE, 20),
  ('CL','39', 'Boleta Electronica',             FALSE, FALSE, FALSE, TRUE, 30),
  ('CL','41', 'Boleta Exenta Electronica',      FALSE, FALSE, FALSE, TRUE, 40),
  ('CL','46', 'Factura de Compra',              FALSE, TRUE,  FALSE, TRUE, 50),
  ('CL','52', 'Guia de Despacho',               FALSE, TRUE,  FALSE, TRUE, 60),
  ('CL','56', 'Nota de Debito Electronica',     FALSE, TRUE,  FALSE, TRUE, 70),
  ('CL','61', 'Nota de Credito Electronica',    TRUE,  TRUE,  FALSE, TRUE, 80),
  ('CL','110','Factura Exportacion Electronica',FALSE, TRUE,  FALSE, TRUE, 90);
-- +goose StatementEnd

-- Bolivia (SIN)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('BO','FA',  'Factura',                       FALSE, TRUE,  FALSE, TRUE, 10),
  ('BO','FCE', 'Factura Comercial Exportacion', FALSE, TRUE,  FALSE, TRUE, 20),
  ('BO','NC',  'Nota de Credito-Debito',        TRUE,  TRUE,  FALSE, TRUE, 30);
-- +goose StatementEnd

-- Uruguay (DGI)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('UY','101', 'e-Factura',                  FALSE, TRUE,  FALSE, TRUE, 10),
  ('UY','102', 'e-Nota de Credito',          TRUE,  TRUE,  FALSE, TRUE, 20),
  ('UY','103', 'e-Nota de Debito',           FALSE, TRUE,  FALSE, TRUE, 30),
  ('UY','111', 'e-Factura de Exportacion',   FALSE, TRUE,  FALSE, TRUE, 40),
  ('UY','181', 'e-Resguardo',                FALSE, TRUE,  FALSE, TRUE, 50),
  ('UY','182', 'e-Remito',                   FALSE, TRUE,  FALSE, TRUE, 60),
  ('UY','113', 'e-Ticket',                   FALSE, FALSE, FALSE, TRUE, 70);
-- +goose StatementEnd

-- Paraguay (SET)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('PY','FA',  'Factura Electronica',        FALSE, TRUE,  FALSE, TRUE, 10),
  ('PY','NC',  'Nota de Credito',            TRUE,  TRUE,  FALSE, TRUE, 20),
  ('PY','ND',  'Nota de Debito',             FALSE, TRUE,  FALSE, TRUE, 30),
  ('PY','AF',  'Autofactura',                FALSE, TRUE,  FALSE, TRUE, 40),
  ('PY','NR',  'Nota de Remision',           FALSE, TRUE,  FALSE, TRUE, 50);
-- +goose StatementEnd

-- Panama (DGI)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('PA','FE',  'Factura Electronica',       FALSE, TRUE,  FALSE, TRUE, 10),
  ('PA','NC',  'Nota de Credito',           TRUE,  TRUE,  FALSE, TRUE, 20),
  ('PA','ND',  'Nota de Debito',            FALSE, TRUE,  FALSE, TRUE, 30),
  ('PA','FEX', 'Factura Exportacion',       FALSE, TRUE,  FALSE, TRUE, 40);
-- +goose StatementEnd

-- Costa Rica (Hacienda)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('CR','FE',   'Factura Electronica',               FALSE, TRUE,  FALSE, TRUE, 10),
  ('CR','TE',   'Tiquete Electronico',               FALSE, FALSE, FALSE, TRUE, 20),
  ('CR','NC',   'Nota de Credito Electronica',       TRUE,  TRUE,  FALSE, TRUE, 30),
  ('CR','ND',   'Nota de Debito Electronica',        FALSE, TRUE,  FALSE, TRUE, 40),
  ('CR','FEE',  'Factura Electronica Exportacion',   FALSE, TRUE,  FALSE, TRUE, 50),
  ('CR','FEC',  'Factura Electronica Compra',        FALSE, TRUE,  FALSE, TRUE, 60);
-- +goose StatementEnd

-- Republica Dominicana (DGII)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('DO','B01', 'Comprobante Fiscal (Credito Fiscal)',    FALSE, TRUE,  FALSE, TRUE, 10),
  ('DO','B02', 'Comprobante Consumo',                     FALSE, FALSE, FALSE, TRUE, 20),
  ('DO','B03', 'Nota de Debito',                          FALSE, TRUE,  FALSE, TRUE, 30),
  ('DO','B04', 'Nota de Credito',                         TRUE,  TRUE,  FALSE, TRUE, 40),
  ('DO','B11', 'Compras',                                 FALSE, TRUE,  FALSE, TRUE, 50),
  ('DO','B14', 'Regimenes Especiales',                    FALSE, TRUE,  FALSE, TRUE, 60),
  ('DO','B15', 'Gubernamental',                           FALSE, TRUE,  FALSE, TRUE, 70),
  ('DO','B16', 'Exportaciones',                           FALSE, TRUE,  FALSE, TRUE, 80);
-- +goose StatementEnd

-- Guatemala (SAT)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('GT','FACT', 'Factura Electronica FEL',           FALSE, TRUE,  FALSE, TRUE, 10),
  ('GT','FCAM', 'Factura Cambiaria',                 FALSE, TRUE,  FALSE, TRUE, 20),
  ('GT','FESP', 'Factura Especial',                  FALSE, TRUE,  FALSE, TRUE, 30),
  ('GT','NCRE', 'Nota de Credito',                   TRUE,  TRUE,  FALSE, TRUE, 40),
  ('GT','NDEB', 'Nota de Debito',                    FALSE, TRUE,  FALSE, TRUE, 50),
  ('GT','NABN', 'Nota de Abono',                     FALSE, TRUE,  FALSE, TRUE, 60),
  ('GT','RECI', 'Recibo',                            FALSE, TRUE,  FALSE, TRUE, 70);
-- +goose StatementEnd

-- Honduras (SAR)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('HN','FA', 'Factura',          FALSE, TRUE,  TRUE,  TRUE, 10),
  ('HN','NC', 'Nota de Credito',  TRUE,  TRUE,  FALSE, TRUE, 20),
  ('HN','ND', 'Nota de Debito',   FALSE, TRUE,  FALSE, TRUE, 30);
-- +goose StatementEnd

-- Nicaragua (DGI)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('NI','FA', 'Factura',          FALSE, TRUE,  FALSE, TRUE, 10),
  ('NI','NC', 'Nota de Credito',  TRUE,  TRUE,  FALSE, TRUE, 20),
  ('NI','ND', 'Nota de Debito',   FALSE, TRUE,  FALSE, TRUE, 30);
-- +goose StatementEnd

-- El Salvador (MH DTE)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('SV','01', 'Factura Consumidor Final DTE',          FALSE, FALSE, FALSE, TRUE, 10),
  ('SV','03', 'Comprobante Credito Fiscal DTE',        FALSE, TRUE,  FALSE, TRUE, 20),
  ('SV','04', 'Nota de Remision',                       FALSE, TRUE,  FALSE, TRUE, 30),
  ('SV','05', 'Nota de Credito',                        TRUE,  TRUE,  FALSE, TRUE, 40),
  ('SV','06', 'Nota de Debito',                         FALSE, TRUE,  FALSE, TRUE, 50),
  ('SV','07', 'Comprobante Retencion',                  FALSE, TRUE,  FALSE, TRUE, 60),
  ('SV','11', 'Factura Exportacion',                    FALSE, TRUE,  FALSE, TRUE, 70),
  ('SV','14', 'Sujeto Excluido',                        FALSE, TRUE,  FALSE, TRUE, 80);
-- +goose StatementEnd

-- Cuba (ONAT)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('CU','FA', 'Factura',           FALSE, TRUE,  FALSE, TRUE, 10),
  ('CU','NC', 'Nota de Credito',   TRUE,  TRUE,  FALSE, TRUE, 20);
-- +goose StatementEnd

-- Puerto Rico (Hacienda)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('PR','INV','Invoice',       FALSE, FALSE, FALSE, TRUE, 10),
  ('PR','CM', 'Credit Memo',   TRUE,  TRUE,  FALSE, TRUE, 20),
  ('PR','DM', 'Debit Memo',    FALSE, TRUE,  FALSE, TRUE, 30);
-- +goose StatementEnd

-- Estados Unidos (IRS / state-level)
-- +goose StatementBegin
INSERT INTO fiscal."InvoiceType" ("CountryCode","InvoiceTypeCode","InvoiceTypeName","IsRectificative","RequiresRecipientId","RequiresFiscalPrinter","IsActive","SortOrder") VALUES
  ('US','INV','Invoice',        FALSE, FALSE, FALSE, TRUE, 10),
  ('US','CM', 'Credit Memo',    TRUE,  FALSE, FALSE, TRUE, 20),
  ('US','DM', 'Debit Memo',     FALSE, FALSE, FALSE, TRUE, 30),
  ('US','RCT','Sales Receipt',  FALSE, FALSE, FALSE, TRUE, 40);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."InvoiceType"
WHERE "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd
