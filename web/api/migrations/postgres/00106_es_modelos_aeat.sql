-- +goose Up

-- ESPAÑA — Modelos AEAT complementarios
-- Ya existen en seed: MODELO_303, MODELO_390, MODELO_349, MODELO_111, MODELO_190.
-- Añadimos los modelos faltantes para cobertura legal completa 2026.

-- +goose StatementBegin
DELETE FROM fiscal."DeclarationTemplate"
WHERE "CountryCode" = 'ES'
  AND "DeclarationType" IN ('MODELO_115','MODELO_130','MODELO_131','MODELO_347','MODELO_200',
                             'MODELO_202','MODELO_100','MODELO_180','MODELO_165','MODELO_184');
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO fiscal."DeclarationTemplate"
  ("CountryCode","DeclarationType","TemplateName","FileFormat","FormatVersion","AuthorityName","AuthorityUrl","IsActive")
VALUES
  ('ES','MODELO_115','Retenciones sobre arrendamientos (trimestral)',                    'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/iva/modelo-115.html',                      TRUE),
  ('ES','MODELO_130','Pagos fraccionados autonomos - Estimacion Directa',                'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/irpf/modelo-130.html',                                       TRUE),
  ('ES','MODELO_131','Pagos fraccionados autonomos - Modulos',                            'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/irpf/modelo-131.html',                                       TRUE),
  ('ES','MODELO_347','Declaracion operaciones con terceros (>3005.06 EUR)',               'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/todas-gestiones/impuestos/modelo-347.html',                   TRUE),
  ('ES','MODELO_200','Impuesto sobre Sociedades',                                         'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/impuesto-sociedades/modelo-200.html',         TRUE),
  ('ES','MODELO_202','Pagos fraccionados Impuesto Sociedades',                            'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/impuesto-sociedades/modelo-202.html',         TRUE),
  ('ES','MODELO_100','Declaracion anual IRPF',                                            'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/irpf/modelo-100.html',                                        TRUE),
  ('ES','MODELO_180','Resumen anual retenciones arrendamientos',                          'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/iva/modelo-180.html',                         TRUE),
  ('ES','MODELO_165','Resumen anual retenciones capital',                                 'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/impuestos-tasas/iva/modelo-165.html',                         TRUE),
  ('ES','MODELO_184','Entidades regimen atribucion rentas',                               'XML','v1.0','AEAT','https://sede.agenciatributaria.gob.es/Sede/irpf/modelo-184.html',                                        TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."DeclarationTemplate"
WHERE "CountryCode" = 'ES'
  AND "DeclarationType" IN ('MODELO_115','MODELO_130','MODELO_131','MODELO_347','MODELO_200',
                             'MODELO_202','MODELO_100','MODELO_180','MODELO_165','MODELO_184');
-- +goose StatementEnd
