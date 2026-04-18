-- +goose Up

-- ESPAÑA — Corrección tramos IRPF 2026 + Ampliación retenciones
-- Fuente: AEAT — Ley IRPF Art. 66. Escala estatal 2026 (sin cambios vs 2025).
-- Los tramos combinados (estatal + autonomía promedio) son: 19%, 24%, 30%, 37%, 45%, 47%.
-- La migration 00103 puso tramos estatales solos (9.5-24.5%) — se corrigen ahora.

-- ─── Corrección IRPF tramos ES 2026 ──────────────────────────────────
-- +goose StatementBegin
DELETE FROM fiscal."ISLRTariff" WHERE "CountryCode" = 'ES' AND "TaxYear" = 2026;
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO fiscal."ISLRTariff" ("CountryCode","TaxYear","BracketFrom","BracketTo","Rate","Subtrahend","IsActive") VALUES
  ('ES', 2026,      0.00,   12450.00,  19.00,      0.00,  TRUE),
  ('ES', 2026,  12450.00,   20200.00,  24.00,    622.50,  TRUE),
  ('ES', 2026,  20200.00,   35200.00,  30.00,   1834.50,  TRUE),
  ('ES', 2026,  35200.00,   60000.00,  37.00,   4298.50,  TRUE),
  ('ES', 2026,  60000.00,  300000.00,  45.00,   9098.50,  TRUE),
  ('ES', 2026, 300000.00,       NULL,  47.00, 15098.50,   TRUE);
-- +goose StatementEnd

-- ─── Ampliación fiscal.WithholdingConcept ES 2026 ────────────────────
-- Fuente: AEAT. Tipos retención IRPF vigentes 2026
-- La tabla ya tiene 4 conceptos básicos (IRPF_PROF, IRPF_NUEVO, IRPF_ALQ, IRPF_CAP).
-- Rate se almacena como porcentaje (19.00 = 19%)
-- RetentionType válidos: ISLR, IVA, IRPF, ISR, RETEFUENTE, MUNICIPAL

-- +goose StatementBegin
DELETE FROM fiscal."WithholdingConcept"
WHERE "CountryCode" = 'ES' AND "CompanyId" = 1
  AND "ConceptCode" IN ('IRPF_ADMIN','IRPF_ADMIN_PYME','IRPF_CURSO','IRPF_PREMIO','IRPF_ATLETA',
                         'IRPF_AGRICOLA','IRPF_AGR_ENGORDE','IRPF_MODULO','IRPF_FONDO',
                         'IRPF_PROP_INTEL','IRPF_GAN_FONDOS');
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO fiscal."WithholdingConcept"
  ("CompanyId","CountryCode","ConceptCode","Description","SupplierType","RetentionType","Rate","IsActive")
VALUES
  (1,'ES','IRPF_ADMIN',            'Administradores/Consejeros (empresas >100k€)',      'AMBOS',    'IRPF', 35.00, TRUE),
  (1,'ES','IRPF_ADMIN_PYME',       'Administradores/Consejeros (empresas <100k€)',      'AMBOS',    'IRPF', 19.00, TRUE),
  (1,'ES','IRPF_CURSO',            'Cursos, conferencias, coloquios',                    'NATURAL',  'IRPF', 15.00, TRUE),
  (1,'ES','IRPF_PREMIO',           'Premios juegos, concursos, rifas',                   'AMBOS',    'IRPF', 19.00, TRUE),
  (1,'ES','IRPF_ATLETA',           'Deportistas profesionales',                          'NATURAL',  'IRPF', 15.00, TRUE),
  (1,'ES','IRPF_AGRICOLA',         'Actividades agricolas y ganaderas',                  'AMBOS',    'IRPF',  2.00, TRUE),
  (1,'ES','IRPF_AGR_ENGORDE',      'Actividades ganaderas de engorde porcino/avicola',   'AMBOS',    'IRPF',  1.00, TRUE),
  (1,'ES','IRPF_MODULO',           'Actividades en estimacion objetiva (modulos)',       'NATURAL',  'IRPF',  1.00, TRUE),
  (1,'ES','IRPF_FONDO',            'Rendimientos de fondos de inversion',                'AMBOS',    'IRPF', 19.00, TRUE),
  (1,'ES','IRPF_PROP_INTEL', 'Propiedad intelectual/industrial (autores)',         'NATURAL',  'IRPF', 15.00, TRUE),
  (1,'ES','IRPF_GAN_FONDOS',       'Ganancias patrimoniales transmision fondos',         'AMBOS',    'IRPF', 19.00, TRUE);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM fiscal."WithholdingConcept"
WHERE "CountryCode" = 'ES' AND "CompanyId" = 1
  AND "ConceptCode" IN ('IRPF_ADMIN','IRPF_ADMIN_PYME','IRPF_CURSO','IRPF_PREMIO','IRPF_ATLETA',
                         'IRPF_AGRICOLA','IRPF_AGR_ENGORDE','IRPF_MODULO','IRPF_FONDO',
                         'IRPF_PROP_INTEL','IRPF_GAN_FONDOS');
-- +goose StatementEnd
