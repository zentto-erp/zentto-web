-- =============================================
-- PASO 2: Limpiar huérfanos y crear integridad referencial (FK)
-- Ejecutar DESPUÉS de cleanup_drop_integration_tables.sql
-- Elimina filas hijas cuyo padre no existe y luego crea las FK del modelo DatqBox.
-- =============================================

SET NOCOUNT ON;

-- ---------- PARTE A: Eliminar datos huérfanos (orden: de hijo a padre) ----------

-- Detalle_facturas sin factura
DELETE d FROM dbo.Detalle_facturas d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Facturas f WHERE f.NUM_FACT = d.NUM_FACT);
PRINT N'Limpiados Detalle_facturas huérfanos.';

-- Detalle_FormaPagoFacturas sin factura
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoFacturas')
BEGIN
    DELETE d FROM dbo.Detalle_FormaPagoFacturas d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Facturas f WHERE f.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_FormaPagoFacturas huérfanos.';
END

-- Detalle_facturas sin producto en Inventario (COD_SERV)
DELETE d FROM dbo.Detalle_facturas d
WHERE d.COD_SERV IS NOT NULL AND d.COD_SERV <> N''
  AND NOT EXISTS (SELECT 1 FROM dbo.Inventario i WHERE i.CODIGO = d.COD_SERV);
PRINT N'Limpiados Detalle_facturas sin Inventario.';

-- Facturas sin cliente
DELETE f FROM dbo.Facturas f
WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = f.CODIGO);
PRINT N'Limpiados Facturas huérfanos (sin Clientes).';

-- P_Cobrar sin cliente
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrar')
BEGIN
    DELETE p FROM dbo.P_Cobrar p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = p.CODIGO);
    PRINT N'Limpiados P_Cobrar huérfanos.';
END

-- P_Cobrarc sin cliente
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrarc')
BEGIN
    DELETE p FROM dbo.P_Cobrarc p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = p.CODIGO);
    PRINT N'Limpiados P_Cobrarc huérfanos.';
END

-- Detalle_Compras sin compra
DELETE d FROM dbo.Detalle_Compras d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Compras c WHERE c.NUM_FACT = d.NUM_FACT);
PRINT N'Limpiados Detalle_Compras huérfanos.';

-- Detalle_Compras sin producto (CODIGO -> Inventario)
DELETE d FROM dbo.Detalle_Compras d
WHERE d.CODIGO IS NOT NULL AND d.CODIGO <> N''
  AND NOT EXISTS (SELECT 1 FROM dbo.Inventario i WHERE i.CODIGO = d.CODIGO);
PRINT N'Limpiados Detalle_Compras sin Inventario.';

-- Detalle_FormaPagoCompras sin compra
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCompras')
BEGIN
    DELETE d FROM dbo.Detalle_FormaPagoCompras d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Compras c WHERE c.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_FormaPagoCompras huérfanos.';
END

-- Compras sin proveedor
DELETE c FROM dbo.Compras c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Proveedores p WHERE p.CODIGO = c.COD_PROVEEDOR);
PRINT N'Limpiados Compras huérfanos.';

-- P_Pagar sin proveedor
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Pagar')
BEGIN
    DELETE p FROM dbo.P_Pagar p
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Proveedores pr WHERE pr.CODIGO = p.CODIGO);
    PRINT N'Limpiados P_Pagar huérfanos.';
END

-- Detalle_Cotizacion sin cotización
DELETE d FROM dbo.Detalle_Cotizacion d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Cotizacion c WHERE c.NUM_FACT = d.NUM_FACT);
PRINT N'Limpiados Detalle_Cotizacion huérfanos.';

-- Detalle_FormaPagoCotizacion sin cotización
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCotizacion')
BEGIN
    DELETE d FROM dbo.Detalle_FormaPagoCotizacion d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Cotizacion c WHERE c.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_FormaPagoCotizacion huérfanos.';
END

-- Cotizacion sin cliente
DELETE c FROM dbo.Cotizacion c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes cl WHERE cl.CODIGO = c.CODIGO);
PRINT N'Limpiados Cotizacion huérfanos.';

-- Detalle_Pedidos sin pedido
DELETE d FROM dbo.Detalle_Pedidos d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedidos p WHERE p.NUM_FACT = d.NUM_FACT);
PRINT N'Limpiados Detalle_Pedidos huérfanos.';

-- Detalle_Pedidos sin producto
DELETE d FROM dbo.Detalle_Pedidos d
WHERE d.COD_SERV IS NOT NULL AND d.COD_SERV <> N''
  AND NOT EXISTS (SELECT 1 FROM dbo.Inventario i WHERE i.CODIGO = d.COD_SERV);
PRINT N'Limpiados Detalle_Pedidos sin Inventario.';

-- Pedidos sin cliente
DELETE p FROM dbo.Pedidos p
WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = p.CODIGO);
PRINT N'Limpiados Pedidos huérfanos.';

-- Detalle_Presupuestos sin presupuesto
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Presupuestos')
BEGIN
    DELETE d FROM dbo.Detalle_Presupuestos d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Presupuestos pr WHERE pr.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_Presupuestos huérfanos.';
END

-- Presupuestos sin cliente
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Presupuestos')
BEGIN
    DELETE pr FROM dbo.Presupuestos pr
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = pr.CODIGO);
    PRINT N'Limpiados Presupuestos huérfanos.';
END

-- Detalle_Ordenes sin orden
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Ordenes')
BEGIN
    DELETE d FROM dbo.Detalle_Ordenes d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Ordenes o WHERE o.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_Ordenes huérfanos.';
END

-- Ordenes sin proveedor (CODIGO en Ordenes = proveedor)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Ordenes')
BEGIN
    DELETE o FROM dbo.Ordenes o
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Proveedores p WHERE p.CODIGO = o.CODIGO);
    PRINT N'Limpiados Ordenes huérfanos.';
END

-- Detalle_notacredito sin NOTACREDITO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notacredito')
BEGIN
    DELETE d FROM dbo.Detalle_notacredito d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.NOTACREDITO n WHERE n.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_notacredito huérfanos.';
END

-- NOTACREDITO sin cliente
DELETE n FROM dbo.NOTACREDITO n
WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = n.CODIGO);
PRINT N'Limpiados NOTACREDITO huérfanos.';

-- Detalle_notadebito sin NOTADEBITO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notadebito')
BEGIN
    DELETE d FROM dbo.Detalle_notadebito d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.NOTADEBITO n WHERE n.NUM_FACT = d.NUM_FACT);
    PRINT N'Limpiados Detalle_notadebito huérfanos.';
END

-- NOTADEBITO sin cliente
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'NOTADEBITO')
BEGIN
    DELETE n FROM dbo.NOTADEBITO n
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = n.CODIGO);
    PRINT N'Limpiados NOTADEBITO huérfanos.';
END

-- MovInvent sin producto en Inventario
DELETE m FROM dbo.MovInvent m
WHERE m.CODIGO IS NOT NULL AND m.CODIGO <> N''
  AND NOT EXISTS (SELECT 1 FROM dbo.Inventario i WHERE i.CODIGO = m.CODIGO);
PRINT N'Limpiados MovInvent sin Inventario.';

-- Inventario_Aux sin producto
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario_Aux')
BEGIN
    DELETE a FROM dbo.Inventario_Aux a
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Inventario i WHERE i.CODIGO = a.CODIGO);
    PRINT N'Limpiados Inventario_Aux huérfanos.';
END

-- Detalle_Deposito / DETALLE_DEPOSITO sin cliente
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Deposito')
BEGIN
    DELETE d FROM dbo.Detalle_Deposito d
    WHERE d.CLIENTE IS NOT NULL AND d.CLIENTE <> N''
      AND NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = d.CLIENTE);
    PRINT N'Limpiados Detalle_Deposito huérfanos.';
END
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DETALLE_DEPOSITO')
BEGIN
    DELETE d FROM dbo.DETALLE_DEPOSITO d
    WHERE d.CLIENTE IS NOT NULL AND d.CLIENTE <> N''
      AND NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = d.CLIENTE);
    PRINT N'Limpiados DETALLE_DEPOSITO huérfanos.';
END

PRINT N'--- Fin limpieza de huérfanos ---';

-- ---------- PARTE B: Crear claves foráneas (solo si no existen) ----------

DECLARE @sql NVARCHAR(MAX);

-- Helper: crear FK solo si no existe
-- FK: Facturas.CODIGO -> Clientes.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Facturas_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Facturas ADD CONSTRAINT FK_Facturas_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Facturas_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Facturas_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_facturas.NUM_FACT -> Facturas.NUM_FACT
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_facturas_Facturas')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_facturas ADD CONSTRAINT FK_Detalle_facturas_Facturas
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Facturas(NUM_FACT);
        PRINT N'Creada FK_Detalle_facturas_Facturas.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_facturas_Facturas: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_facturas.COD_SERV -> Inventario.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_facturas_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_facturas ADD CONSTRAINT FK_Detalle_facturas_Inventario
            FOREIGN KEY (COD_SERV) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_Detalle_facturas_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_facturas_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_FormaPagoFacturas.NUM_FACT -> Facturas.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoFacturas')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoFacturas_Facturas')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoFacturas ADD CONSTRAINT FK_Detalle_FormaPagoFacturas_Facturas
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Facturas(NUM_FACT);
        PRINT N'Creada FK_Detalle_FormaPagoFacturas_Facturas.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_FormaPagoFacturas_Facturas: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Compras.COD_PROVEEDOR -> Proveedores.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Compras_Proveedores')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Compras ADD CONSTRAINT FK_Compras_Proveedores
            FOREIGN KEY (COD_PROVEEDOR) REFERENCES dbo.Proveedores(CODIGO);
        PRINT N'Creada FK_Compras_Proveedores.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Compras_Proveedores: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Compras.NUM_FACT -> Compras.NUM_FACT
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Compras_Compras')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Compras ADD CONSTRAINT FK_Detalle_Compras_Compras
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Compras(NUM_FACT);
        PRINT N'Creada FK_Detalle_Compras_Compras.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Compras_Compras: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Compras.CODIGO -> Inventario.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Compras_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Compras ADD CONSTRAINT FK_Detalle_Compras_Inventario
            FOREIGN KEY (CODIGO) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_Detalle_Compras_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Compras_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_FormaPagoCompras.NUM_FACT -> Compras.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCompras')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoCompras_Compras')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoCompras ADD CONSTRAINT FK_Detalle_FormaPagoCompras_Compras
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Compras(NUM_FACT);
        PRINT N'Creada FK_Detalle_FormaPagoCompras_Compras.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_FormaPagoCompras_Compras: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: P_Cobrar.CODIGO -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrar')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_P_Cobrar_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.P_Cobrar ADD CONSTRAINT FK_P_Cobrar_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_P_Cobrar_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_P_Cobrar_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: P_Cobrarc.CODIGO -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrarc')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_P_Cobrarc_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.P_Cobrarc ADD CONSTRAINT FK_P_Cobrarc_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_P_Cobrarc_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_P_Cobrarc_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: P_Pagar.CODIGO -> Proveedores.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Pagar')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_P_Pagar_Proveedores')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.P_Pagar ADD CONSTRAINT FK_P_Pagar_Proveedores
            FOREIGN KEY (CODIGO) REFERENCES dbo.Proveedores(CODIGO);
        PRINT N'Creada FK_P_Pagar_Proveedores.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_P_Pagar_Proveedores: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Cotizacion.CODIGO -> Clientes.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Cotizacion_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Cotizacion ADD CONSTRAINT FK_Cotizacion_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Cotizacion_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Cotizacion_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Cotizacion.NUM_FACT -> Cotizacion.NUM_FACT
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Cotizacion_Cotizacion')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Cotizacion ADD CONSTRAINT FK_Detalle_Cotizacion_Cotizacion
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Cotizacion(NUM_FACT);
        PRINT N'Creada FK_Detalle_Cotizacion_Cotizacion.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Cotizacion_Cotizacion: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_FormaPagoCotizacion.NUM_FACT -> Cotizacion.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCotizacion')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoCotizacion_Cotizacion')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoCotizacion ADD CONSTRAINT FK_Detalle_FormaPagoCotizacion_Cotizacion
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Cotizacion(NUM_FACT);
        PRINT N'Creada FK_Detalle_FormaPagoCotizacion_Cotizacion.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_FormaPagoCotizacion_Cotizacion: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Pedidos.CODIGO -> Clientes.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Pedidos_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Pedidos ADD CONSTRAINT FK_Pedidos_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Pedidos_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Pedidos_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Pedidos.NUM_FACT -> Pedidos.NUM_FACT
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Pedidos_Pedidos')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Pedidos ADD CONSTRAINT FK_Detalle_Pedidos_Pedidos
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Pedidos(NUM_FACT);
        PRINT N'Creada FK_Detalle_Pedidos_Pedidos.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Pedidos_Pedidos: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Pedidos.COD_SERV -> Inventario.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Pedidos_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Pedidos ADD CONSTRAINT FK_Detalle_Pedidos_Inventario
            FOREIGN KEY (COD_SERV) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_Detalle_Pedidos_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Pedidos_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Presupuestos.CODIGO -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Presupuestos')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Presupuestos_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Presupuestos ADD CONSTRAINT FK_Presupuestos_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Presupuestos_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Presupuestos_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Presupuestos.NUM_FACT -> Presupuestos.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Presupuestos')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Presupuestos_Presupuestos')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Presupuestos ADD CONSTRAINT FK_Detalle_Presupuestos_Presupuestos
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Presupuestos(NUM_FACT);
        PRINT N'Creada FK_Detalle_Presupuestos_Presupuestos.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Presupuestos_Presupuestos: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Ordenes.CODIGO -> Proveedores.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Ordenes')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Ordenes_Proveedores')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Ordenes ADD CONSTRAINT FK_Ordenes_Proveedores
            FOREIGN KEY (CODIGO) REFERENCES dbo.Proveedores(CODIGO);
        PRINT N'Creada FK_Ordenes_Proveedores.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Ordenes_Proveedores: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Ordenes.NUM_FACT -> Ordenes.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Ordenes')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Ordenes_Ordenes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Ordenes ADD CONSTRAINT FK_Detalle_Ordenes_Ordenes
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.Ordenes(NUM_FACT);
        PRINT N'Creada FK_Detalle_Ordenes_Ordenes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Ordenes_Ordenes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: NOTACREDITO.CODIGO -> Clientes.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NOTACREDITO_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.NOTACREDITO ADD CONSTRAINT FK_NOTACREDITO_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_NOTACREDITO_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_NOTACREDITO_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_notacredito.NUM_FACT -> NOTACREDITO.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notacredito')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_notacredito_NOTACREDITO')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_notacredito ADD CONSTRAINT FK_Detalle_notacredito_NOTACREDITO
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.NOTACREDITO(NUM_FACT);
        PRINT N'Creada FK_Detalle_notacredito_NOTACREDITO.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_notacredito_NOTACREDITO: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: NOTADEBITO.CODIGO -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'NOTADEBITO')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_NOTADEBITO_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.NOTADEBITO ADD CONSTRAINT FK_NOTADEBITO_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_NOTADEBITO_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_NOTADEBITO_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_notadebito.NUM_FACT -> NOTADEBITO.NUM_FACT
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notadebito')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_notadebito_NOTADEBITO')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_notadebito ADD CONSTRAINT FK_Detalle_notadebito_NOTADEBITO
            FOREIGN KEY (NUM_FACT) REFERENCES dbo.NOTADEBITO(NUM_FACT);
        PRINT N'Creada FK_Detalle_notadebito_NOTADEBITO.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_notadebito_NOTADEBITO: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: MovInvent.CODIGO -> Inventario.CODIGO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MovInvent_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.MovInvent ADD CONSTRAINT FK_MovInvent_Inventario
            FOREIGN KEY (CODIGO) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_MovInvent_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_MovInvent_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Inventario_Aux.CODIGO -> Inventario.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario_Aux')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventario_Aux_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Inventario_Aux ADD CONSTRAINT FK_Inventario_Aux_Inventario
            FOREIGN KEY (CODIGO) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_Inventario_Aux_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Inventario_Aux_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Deposito.CLIENTE -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id WHERE t.name = N'Detalle_Deposito' AND c.name = N'CLIENTE')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Deposito_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Deposito ADD CONSTRAINT FK_Detalle_Deposito_Clientes
            FOREIGN KEY (CLIENTE) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Detalle_Deposito_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Deposito_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

PRINT N'--- Fin creación de FKs ---';
