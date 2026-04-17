-- +goose Up

-- Seed fiscal.WithholdingConcept para 19 paises.
-- CompanyId=1 (seed global, los tenants lo sobreescriben/extienden).
-- Excluye ES (cubierto por migracion del agente Espana).
-- Fuente: tablas de retencion vigentes por autoridad (AFIP, DIAN, SAT, SUNAT, SRI, SII, DGII, etc.)
-- Idempotente: DELETE + INSERT por UQ_fiscal_WHConcept (CompanyId, CountryCode, ConceptCode).

-- +goose StatementBegin
DELETE FROM fiscal."WithholdingConcept"
WHERE "CompanyId" = 1
  AND "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd

-- Venezuela (SENIAT) - ISLR + IVA Contribuyentes Especiales
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","SubtrahendUT","MinBaseUT","SeniatCode","IsActive") VALUES
  (1,'VE','ISLR_HON_PN',  'ISLR Honorarios Profesionales Persona Natural', 'NATURAL',  'ISLR', 0.0300, 83.3400, 25.0000, '001', TRUE),
  (1,'VE','ISLR_HON_PJ',  'ISLR Honorarios Persona Juridica',              'JURIDICA', 'ISLR', 0.0500, 0.0000,  0.0000,  '002', TRUE),
  (1,'VE','ISLR_COM_PN',  'ISLR Comisiones Persona Natural',               'NATURAL',  'ISLR', 0.0300, 83.3400, 25.0000, '003', TRUE),
  (1,'VE','ISLR_SRV_PJ',  'ISLR Servicios Persona Juridica',               'JURIDICA', 'ISLR', 0.0200, 0.0000,  0.0000,  '004', TRUE),
  (1,'VE','IVA_RET_75',   'IVA Retenido 75% Contribuyente Especial',       'AMBOS',    'IVA',  0.7500, 0.0000,  0.0000,  '100', TRUE),
  (1,'VE','IVA_RET_100',  'IVA Retenido 100% Sin RIF o No Domiciliado',    'AMBOS',    'IVA',  1.0000, 0.0000,  0.0000,  '101', TRUE);
-- +goose StatementEnd

-- Argentina (AFIP - RG 830/2000 Ganancias + RG 2408 IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'AR','GAN_HON',   'Ganancias Honorarios Profesionales no Inscripto', 'NATURAL',  'ISR',       0.2800, TRUE),
  (1,'AR','GAN_HON_I', 'Ganancias Honorarios Profesionales Inscripto',    'NATURAL',  'ISR',       0.0200, TRUE),
  (1,'AR','GAN_BIE',   'Ganancias Compra Bienes',                         'AMBOS',    'ISR',       0.0200, TRUE),
  (1,'AR','GAN_SRV',   'Ganancias Locacion Servicios',                    'AMBOS',    'ISR',       0.0200, TRUE),
  (1,'AR','GAN_ALQ',   'Ganancias Alquileres',                            'NATURAL',  'ISR',       0.0600, TRUE),
  (1,'AR','IVA_PER',   'IVA Percepcion RG 2408',                          'AMBOS',    'IVA',       0.0300, TRUE);
-- +goose StatementEnd

-- Colombia (DIAN - Retefuente ET + Estatuto Municipal)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'CO','RF_HON_PN',    'Retefuente Honorarios PN No Declarante',      'NATURAL',  'RETEFUENTE', 0.1100, TRUE),
  (1,'CO','RF_HON_PJ',    'Retefuente Honorarios Persona Juridica',      'JURIDICA', 'RETEFUENTE', 0.1100, TRUE),
  (1,'CO','RF_SRV_PN',    'Retefuente Servicios PN',                      'NATURAL',  'RETEFUENTE', 0.0400, TRUE),
  (1,'CO','RF_SRV_PJ',    'Retefuente Servicios Persona Juridica',        'JURIDICA', 'RETEFUENTE', 0.0600, TRUE),
  (1,'CO','RF_COMPRAS',   'Retefuente Compras Generales',                 'AMBOS',    'RETEFUENTE', 0.0250, TRUE),
  (1,'CO','RF_ARRENDA',   'Retefuente Arrendamientos',                    'AMBOS',    'RETEFUENTE', 0.0350, TRUE),
  (1,'CO','IVA_RET_15',   'Reteiva 15% Regimen Comun',                    'AMBOS',    'IVA',        0.1500, TRUE),
  (1,'CO','ICA_RET',      'Retencion ICA Municipal (Bogota promedio)',    'AMBOS',    'MUNICIPAL',  0.0069, TRUE);
-- +goose StatementEnd

-- Mexico (SAT - ISR LISR + IVA Retenido CFF)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'MX','ISR_HON_PF',   'ISR Honorarios Persona Fisica Art. 106',        'NATURAL',  'ISR',  0.1000, TRUE),
  (1,'MX','ISR_ARR_PF',   'ISR Arrendamiento Persona Fisica Art. 116',     'NATURAL',  'ISR',  0.1000, TRUE),
  (1,'MX','ISR_DIV',      'ISR Dividendos Persona Fisica',                 'NATURAL',  'ISR',  0.1000, TRUE),
  (1,'MX','IVA_RET_FL',   'IVA Retenido Autotransporte Fletes 4%',          'AMBOS',    'IVA',  0.0400, TRUE),
  (1,'MX','IVA_RET_SR',   'IVA Retenido Servicios Profesionales 10.67%',    'AMBOS',    'IVA',  0.1067, TRUE);
-- +goose StatementEnd

-- Peru (SUNAT - IGV Retencion + Renta 4ta/5ta Categoria)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'PE','IGV_RET',   'IGV Retencion 3% Agente Retenedor',    'AMBOS',    'IVA',  0.0300, TRUE),
  (1,'PE','IGV_PER',   'IGV Percepcion 2% Combustibles/Bienes','AMBOS',    'IVA',  0.0200, TRUE),
  (1,'PE','REN_4TA',   'Retencion Rentas 4ta Categoria 8%',     'NATURAL',  'ISR',  0.0800, TRUE),
  (1,'PE','REN_5TA',   'Retencion Rentas 5ta Categoria Dep.',   'NATURAL',  'ISR',  0.0800, TRUE);
-- +goose StatementEnd

-- Ecuador (SRI - Retenciones Renta + IVA 30/70/100)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'EC','RF_HON_PN',  'Retencion Honorarios PN No Obligados',     'NATURAL',  'ISR',  0.1000, TRUE),
  (1,'EC','RF_HON_PJ',  'Retencion Honorarios Persona Juridica',    'JURIDICA', 'ISR',  0.0800, TRUE),
  (1,'EC','RF_SRV_PRE', 'Retencion Servicios Predominio Intelect.', 'AMBOS',    'ISR',  0.0800, TRUE),
  (1,'EC','RF_SRV_MAT', 'Retencion Servicios Predominio Material',  'AMBOS',    'ISR',  0.0200, TRUE),
  (1,'EC','RF_BIENES',  'Retencion Compra Bienes',                  'AMBOS',    'ISR',  0.0175, TRUE),
  (1,'EC','IVA_RET_30', 'IVA Retenido 30% Bienes',                  'AMBOS',    'IVA',  0.3000, TRUE),
  (1,'EC','IVA_RET_70', 'IVA Retenido 70% Servicios',               'AMBOS',    'IVA',  0.7000, TRUE),
  (1,'EC','IVA_RET_100','IVA Retenido 100% Prof./Arriendo/Sin RUC', 'AMBOS',    'IVA',  1.0000, TRUE);
-- +goose StatementEnd

-- Chile (SII - Retenciones 2da Categoria + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'CL','HON_13_75', 'Retencion Honorarios 2da Categoria 13.75%',  'NATURAL',  'ISR', 0.1375, TRUE),
  (1,'CL','IVA_19',    'IVA Retenido Facturas Compra',                'AMBOS',    'IVA', 0.1900, TRUE),
  (1,'CL','IMP_UNICO', 'Impuesto Unico Trabajadores',                 'NATURAL',  'ISR', 0.0000, TRUE);
-- +goose StatementEnd

-- Bolivia (SIN - IUE + IT + RC-IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'BO','IUE_PN',  'IUE Personas Naturales sin Factura',  'NATURAL',  'ISR', 0.1250, TRUE),
  (1,'BO','IT_PN',   'IT Personas Naturales sin Factura',   'NATURAL',  'IVA', 0.0300, TRUE),
  (1,'BO','RC_IVA',  'RC-IVA Dependientes',                 'NATURAL',  'ISR', 0.1300, TRUE);
-- +goose StatementEnd

-- Uruguay (DGI - IRPF + IRNR)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'UY','IRPF_II',   'IRPF Categoria II Servicios Personales',   'NATURAL',  'IRPF', 0.0700, TRUE),
  (1,'UY','IRNR',      'IRNR No Residentes',                        'AMBOS',    'ISR',  0.1200, TRUE),
  (1,'UY','IVA_MIN',   'IVA Minimo Monotributistas',                'NATURAL',  'IVA',  0.0000, TRUE);
-- +goose StatementEnd

-- Paraguay (SET - IRE + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'PY','IRE_GEN',   'Retencion IRE General',           'AMBOS',    'ISR', 0.0300, TRUE),
  (1,'PY','IVA_RET',   'Retencion IVA Agente Retencion',  'AMBOS',    'IVA', 0.3000, TRUE),
  (1,'PY','IRP',       'Impuesto Rentas Personales',      'NATURAL',  'ISR', 0.0800, TRUE);
-- +goose StatementEnd

-- Panama (DGI - ISR + ITBMS)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'PA','ISR_HON',    'ISR Honorarios Profesionales',       'NATURAL', 'ISR', 0.1000, TRUE),
  (1,'PA','ISR_NODOM',  'ISR No Domiciliados',                'AMBOS',   'ISR', 0.1250, TRUE),
  (1,'PA','ITBMS_RET',  'ITBMS Retenido 50% Agente Retencion','AMBOS',   'IVA', 0.5000, TRUE);
-- +goose StatementEnd

-- Costa Rica (Hacienda - Renta + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'CR','REN_PRO',   'Renta Servicios Profesionales 10%',  'NATURAL',  'ISR', 0.1000, TRUE),
  (1,'CR','REN_EXT',   'Remesas al Exterior 15%',             'JURIDICA', 'ISR', 0.1500, TRUE),
  (1,'CR','IVA_RET_2', 'IVA Retenido 2% Tarjeta Credito',     'AMBOS',    'IVA', 0.0200, TRUE),
  (1,'CR','IVA_RET_4', 'IVA Retenido 4% Empresas Alquileres', 'AMBOS',    'IVA', 0.0400, TRUE);
-- +goose StatementEnd

-- Republica Dominicana (DGII - ISR + ITBIS)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'DO','ITBIS_RET_30',  'ITBIS Retenido 30% Servicios a Profesionales', 'NATURAL',  'IVA', 0.3000, TRUE),
  (1,'DO','ITBIS_RET_100', 'ITBIS Retenido 100% Personas Fisicas',         'NATURAL',  'IVA', 1.0000, TRUE),
  (1,'DO','ISR_HON',       'ISR Honorarios Persona Fisica',                 'NATURAL',  'ISR', 0.1000, TRUE),
  (1,'DO','ISR_ALQ',       'ISR Alquileres a Personas Fisicas',             'NATURAL',  'ISR', 0.1000, TRUE),
  (1,'DO','ISR_NODOM',     'ISR Pagos al Exterior',                         'AMBOS',    'ISR', 0.2700, TRUE);
-- +goose StatementEnd

-- Guatemala (SAT - ISR + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'GT','ISR_PRO',  'Retencion ISR Regimen Prof. Optativo 7%', 'AMBOS',    'ISR', 0.0700, TRUE),
  (1,'GT','IVA_RET',  'Retencion IVA 15% Pequeno Contribuyente', 'AMBOS',    'IVA', 0.1500, TRUE),
  (1,'GT','ISR_EXT',  'ISR Pagos al Exterior 25%',                'AMBOS',    'ISR', 0.2500, TRUE);
-- +goose StatementEnd

-- Honduras (SAR - ISR + ISV)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'HN','ISR_HON',  'ISR Honorarios Profesionales 12.5%', 'NATURAL',  'ISR', 0.1250, TRUE),
  (1,'HN','ISR_EXT',  'ISR No Residentes 10%',               'AMBOS',    'ISR', 0.1000, TRUE),
  (1,'HN','ISV_RET',  'ISV Retenido Grandes Contribuyentes', 'AMBOS',    'IVA', 0.1500, TRUE);
-- +goose StatementEnd

-- Nicaragua (DGI - IR + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'NI','IR_HON',   'IR Honorarios Profesionales 10%',   'NATURAL',  'ISR', 0.1000, TRUE),
  (1,'NI','IR_SRV',   'IR Servicios y Dietas 10%',         'AMBOS',    'ISR', 0.1000, TRUE),
  (1,'NI','IR_BIE',   'IR Compra Bienes 2%',               'AMBOS',    'ISR', 0.0200, TRUE),
  (1,'NI','IVA_RET',  'IVA Retenido 15%',                   'AMBOS',    'IVA', 0.1500, TRUE);
-- +goose StatementEnd

-- El Salvador (MH - ISR + IVA)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'SV','ISR_HON',   'ISR Honorarios Profesionales 10%',  'NATURAL',  'ISR', 0.1000, TRUE),
  (1,'SV','ISR_EXT',   'ISR Pagos al Exterior 20%',          'AMBOS',    'ISR', 0.2000, TRUE),
  (1,'SV','IVA_RET_1', 'IVA Retencion 1% Grandes Contrib.',  'AMBOS',    'IVA', 0.0100, TRUE),
  (1,'SV','IVA_RET_13','IVA Retencion 13% Otros',            'AMBOS',    'IVA', 0.1300, TRUE);
-- +goose StatementEnd

-- Cuba (ONAT - ISR limitado)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'CU','ISR_HON',  'Retencion Impuesto Ingresos Personales', 'NATURAL', 'ISR', 0.0500, TRUE),
  (1,'CU','ISR_SRV',  'Retencion Servicios Cuentapropistas',     'AMBOS',   'ISR', 0.0500, TRUE);
-- +goose StatementEnd

-- Puerto Rico (Hacienda - SURI)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'PR','IRS_SRV',  'Retencion 480.6A Servicios Profesionales 29%', 'AMBOS',   'ISR', 0.2900, TRUE),
  (1,'PR','IRS_ALQ',  'Retencion Alquileres 29%',                      'AMBOS',   'ISR', 0.2900, TRUE),
  (1,'PR','IVU_RET',  'IVU Retenido Municipal',                         'AMBOS',   'IVA', 0.0100, TRUE);
-- +goose StatementEnd

-- Estados Unidos (IRS - Backup Withholding + 1099 series)
-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept" ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive") VALUES
  (1,'US','1099_NEC',  '1099-NEC Backup Withholding 24%',           'NATURAL',  'ISR', 0.2400, TRUE),
  (1,'US','1099_MISC', '1099-MISC Backup Withholding 24%',          'AMBOS',    'ISR', 0.2400, TRUE),
  (1,'US','FATCA',     'FATCA/Chapter 4 Withholding 30% Extranjero','AMBOS',    'ISR', 0.3000, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."WithholdingConcept"
WHERE "CompanyId" = 1
  AND "CountryCode" IN ('VE','CO','MX','AR','CL','PE','EC','BO','UY','PY','PA','CR','DO','GT','HN','NI','SV','PR','CU','US');
-- +goose StatementEnd
