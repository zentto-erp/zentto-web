-- ============================================================
-- DatqBoxWeb PostgreSQL - 15_seed_contabilidad.sql
-- Seed: Plan de cuentas básico
-- ============================================================

BEGIN;

DO $$
DECLARE
  v_company_id INT;
BEGIN
  SELECT "CompanyId" INTO v_company_id
  FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'No DEFAULT company found, skipping seed.';
    RETURN;
  END IF;

  -- Plan de cuentas básico (Venezuela)
  INSERT INTO acct."Account" ("CompanyId", "AccountCode", "AccountName", "AccountType", "AccountLevel", "AllowsPosting")
  VALUES
    (v_company_id, '1',       'ACTIVO',                    'A', 1, FALSE),
    (v_company_id, '1.1',     'ACTIVO CIRCULANTE',         'A', 2, FALSE),
    (v_company_id, '1.1.01',  'CAJA',                      'A', 3, TRUE),
    (v_company_id, '1.1.02',  'BANCOS',                    'A', 3, TRUE),
    (v_company_id, '1.1.03',  'CUENTAS POR COBRAR',        'A', 3, TRUE),
    (v_company_id, '1.1.04',  'INVENTARIO',                'A', 3, TRUE),
    (v_company_id, '1.1.05',  'IVA CREDITO FISCAL',        'A', 3, TRUE),
    (v_company_id, '1.2',     'ACTIVO NO CIRCULANTE',      'A', 2, FALSE),
    (v_company_id, '1.2.01',  'PROPIEDAD PLANTA Y EQUIPO', 'A', 3, TRUE),
    (v_company_id, '1.2.02',  'DEPRECIACION ACUMULADA',    'A', 3, TRUE),
    (v_company_id, '2',       'PASIVO',                    'P', 1, FALSE),
    (v_company_id, '2.1',     'PASIVO CIRCULANTE',         'P', 2, FALSE),
    (v_company_id, '2.1.01',  'CUENTAS POR PAGAR',         'P', 3, TRUE),
    (v_company_id, '2.1.02',  'IVA DEBITO FISCAL',         'P', 3, TRUE),
    (v_company_id, '2.1.03',  'RETENCIONES POR PAGAR',     'P', 3, TRUE),
    (v_company_id, '2.1.04',  'PRESTACIONES SOCIALES',     'P', 3, TRUE),
    (v_company_id, '3',       'CAPITAL',                   'C', 1, FALSE),
    (v_company_id, '3.1',     'CAPITAL SOCIAL',            'C', 2, TRUE),
    (v_company_id, '3.2',     'RESERVA LEGAL',             'C', 2, TRUE),
    (v_company_id, '3.3',     'UTILIDADES RETENIDAS',      'C', 2, TRUE),
    (v_company_id, '4',       'INGRESOS',                  'I', 1, FALSE),
    (v_company_id, '4.1',     'VENTAS',                    'I', 2, TRUE),
    (v_company_id, '4.2',     'OTROS INGRESOS',            'I', 2, TRUE),
    (v_company_id, '5',       'GASTOS',                    'G', 1, FALSE),
    (v_company_id, '5.1',     'COSTO DE VENTAS',           'G', 2, TRUE),
    (v_company_id, '5.2',     'GASTOS OPERATIVOS',         'G', 2, TRUE),
    (v_company_id, '5.3',     'GASTOS DE PERSONAL',        'G', 2, TRUE),
    (v_company_id, '5.4',     'GASTOS ADMINISTRATIVOS',    'G', 2, TRUE)
  ON CONFLICT ("CompanyId", "AccountCode") DO NOTHING;

  RAISE NOTICE 'Seed contabilidad: plan de cuentas insertado.';
END $$;

COMMIT;
