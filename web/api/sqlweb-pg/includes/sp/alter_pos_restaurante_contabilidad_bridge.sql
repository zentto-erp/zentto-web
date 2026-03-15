-- ============================================================
-- DatqBoxWeb PostgreSQL - alter_pos_restaurante_contabilidad_bridge.sql
-- Integracion contable POS + Restaurante: vincula documentos
-- origen con AsientoContableId y carga configuracion contable
-- base para ventas POS/Restaurante
-- ============================================================

DO $$
BEGIN

  -- ── PosVentas: agregar columna AsientoContableId ──
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'pos' AND table_name = 'pos_ventas'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'pos'
        AND table_name  = 'pos_ventas'
        AND column_name = 'AsientoContableId'
    ) THEN
      ALTER TABLE pos."PosVentas" ADD COLUMN "AsientoContableId" BIGINT NULL;
    END IF;

    -- FK hacia AsientoContable
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'acct' AND table_name = 'AsientoContable'
    ) AND NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'FK_PosVentas_AsientoContable'
    ) THEN
      ALTER TABLE pos."PosVentas"
        ADD CONSTRAINT "FK_PosVentas_AsientoContable"
        FOREIGN KEY ("AsientoContableId") REFERENCES acct."AsientoContable"("Id");
    END IF;
  END IF;

  -- ── RestaurantePedidos: agregar columna AsientoContableId ──
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'rest' AND table_name = 'RestaurantePedidos'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'rest'
        AND table_name  = 'RestaurantePedidos'
        AND column_name = 'AsientoContableId'
    ) THEN
      ALTER TABLE rest."RestaurantePedidos" ADD COLUMN "AsientoContableId" BIGINT NULL;
    END IF;

    -- FK hacia AsientoContable
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'acct' AND table_name = 'AsientoContable'
    ) AND NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'FK_RestaurantePedidos_AsientoContable'
    ) THEN
      ALTER TABLE rest."RestaurantePedidos"
        ADD CONSTRAINT "FK_RestaurantePedidos_AsientoContable"
        FOREIGN KEY ("AsientoContableId") REFERENCES acct."AsientoContable"("Id");
    END IF;
  END IF;

  -- ── Indices ──
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'pos' AND table_name = 'PosVentas'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'IX_PosVentas_AsientoContableId'
  ) THEN
    CREATE INDEX "IX_PosVentas_AsientoContableId"
      ON pos."PosVentas"("AsientoContableId");
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'rest' AND table_name = 'RestaurantePedidos'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'IX_RestaurantePedidos_AsientoContableId'
  ) THEN
    CREATE INDEX "IX_RestaurantePedidos_AsientoContableId"
      ON rest."RestaurantePedidos"("AsientoContableId");
  END IF;

  -- ── Seed configuracion contable auxiliar ──
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'acct' AND table_name = 'ConfiguracionContableAuxiliar'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'acct' AND table_name = 'Cuentas'
  ) THEN

    INSERT INTO acct."ConfiguracionContableAuxiliar" (
      "Modulo", "Proceso", "Naturaleza", "CuentaContable",
      "CentroCostoDefault", "Descripcion", "Activo"
    )
    SELECT s."Modulo", s."Proceso", s."Naturaleza", s."CuentaContable",
           s."CentroCostoDefault", s."Descripcion", TRUE
    FROM (
      VALUES
        ('POS', 'VENTA_TOTAL_CAJA',  'DEBE',  '1.1.01', 'VEN', 'Cobro venta POS (caja)'),
        ('POS', 'VENTA_TOTAL_BANCO', 'DEBE',  '1.1.02', 'VEN', 'Cobro venta POS (banco/tarjeta)'),
        ('POS', 'VENTA_TOTAL',       'DEBE',  '1.1.01', 'VEN', 'Cobro venta POS'),
        ('POS', 'VENTA_BASE',        'HABER', '4.1.01', 'VEN', 'Ingreso base venta POS'),
        ('POS', 'VENTA_IVA',         'HABER', '2.1.03', 'VEN', 'IVA por pagar venta POS'),

        ('RESTAURANTE', 'VENTA_TOTAL_CAJA',  'DEBE',  '1.1.01', 'VEN', 'Cobro venta restaurante (caja)'),
        ('RESTAURANTE', 'VENTA_TOTAL_BANCO', 'DEBE',  '1.1.02', 'VEN', 'Cobro venta restaurante (banco/tarjeta)'),
        ('RESTAURANTE', 'VENTA_TOTAL',       'DEBE',  '1.1.01', 'VEN', 'Cobro venta restaurante'),
        ('RESTAURANTE', 'VENTA_BASE',        'HABER', '4.1.03', 'VEN', 'Ingreso base venta restaurante'),
        ('RESTAURANTE', 'VENTA_IVA',         'HABER', '2.1.03', 'VEN', 'IVA por pagar venta restaurante')
    ) AS s("Modulo", "Proceso", "Naturaleza", "CuentaContable", "CentroCostoDefault", "Descripcion")
    WHERE EXISTS (
      SELECT 1 FROM acct."Cuentas" c
      WHERE TRIM(c."COD_CUENTA") = TRIM(s."CuentaContable")
    )
    AND NOT EXISTS (
      SELECT 1 FROM acct."ConfiguracionContableAuxiliar" x
      WHERE x."Modulo"         = s."Modulo"
        AND x."Proceso"        = s."Proceso"
        AND x."Naturaleza"     = s."Naturaleza"
        AND x."CuentaContable" = s."CuentaContable"
    );

  END IF;

END $$;
