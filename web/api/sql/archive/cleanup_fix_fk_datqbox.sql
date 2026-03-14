-- =============================================
-- PASO 3: Corregir FKs (PK compuestas + alinear longitudes)
-- Ejecutar DESPUÉS de cleanup_create_fk_datqbox.sql
-- Ajusta columnas y crea FKs compuestas donde la PK del padre tiene varias columnas.
--
-- CLAVE COMPUESTA FACTURAS/DETALLE (NUM_FACT, SERIALTIPO, Tipo_Orden):
--   NUM_FACT   = Número de factura (por máquina fiscal y memoria).
--   SERIALTIPO = Serial de la máquina fiscal (identifica el equipo; si se cambia la memoria, el serial es el mismo).
--   Tipo_Orden = Número de memoria física del equipo fiscal. Si se reemplaza la memoria, el serial sigue igual
--                pero las facturas empiezan de 1 en la nueva memoria; por eso Tipo_Orden 1 = primera memoria,
--                Tipo_Orden 2 = segunda memoria (tras reemplazo), etc. Los detalles también llevan estos campos
--                (aunque por comodidad se use Id en detalle).
-- =============================================

SET NOCOUNT ON;

-- ---------- 0. Limpieza extra: huérfanos por clave compuesta (NUM_FACT + SERIALTIPO) ----------
DELETE d FROM dbo.Detalle_Cotizacion d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Cotizacion c WHERE c.NUM_FACT = d.NUM_FACT AND c.SERIALTIPO = d.SERIALTIPO);
PRINT N'Limpiados Detalle_Cotizacion huérfanos (clave compuesta).';

DELETE d FROM dbo.Detalle_Pedidos d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedidos p WHERE p.NUM_FACT = d.NUM_FACT AND p.SERIALTIPO = d.SERIALTIPO);
PRINT N'Limpiados Detalle_Pedidos huérfanos (clave compuesta).';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Presupuestos')
BEGIN
    DELETE d FROM dbo.Detalle_Presupuestos d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Presupuestos pr WHERE pr.NUM_FACT = d.NUM_FACT AND pr.SERIALTIPO = d.SERIALTIPO);
    PRINT N'Limpiados Detalle_Presupuestos huérfanos (clave compuesta).';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Ordenes')
BEGIN
    DELETE d FROM dbo.Detalle_Ordenes d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Ordenes o WHERE o.NUM_FACT = d.NUM_FACT AND o.SERIALTIPO = d.SERIALTIPO);
    PRINT N'Limpiados Detalle_Ordenes huérfanos (clave compuesta).';
END

-- Detalle_Compras: huérfanos por (NUM_FACT, COD_PROVEEDOR)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_Compras') AND name = 'COD_PROVEEDOR')
BEGIN
    DELETE d FROM dbo.Detalle_Compras d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Compras c WHERE c.NUM_FACT = d.NUM_FACT AND c.COD_PROVEEDOR = d.COD_PROVEEDOR);
    PRINT N'Limpiados Detalle_Compras huérfanos (clave compuesta).';
END

-- Detalle_facturas: COD_SERV vacío -> NULL para poder crear FK a Inventario
UPDATE dbo.Detalle_facturas SET COD_SERV = NULL WHERE COD_SERV = N'' OR (COD_SERV IS NOT NULL AND LTRIM(RTRIM(COD_SERV)) = N'');
PRINT N'Normalizado COD_SERV vacío a NULL en Detalle_facturas.';

-- Detalle_FormaPagoFacturas: huérfanos por clave fiscal (Num_fact, SerialFiscal, Memoria) = (NUM_FACT, SERIALTIPO, Tipo_Orden)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoFacturas')
BEGIN
    DELETE d FROM dbo.Detalle_FormaPagoFacturas d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Facturas f WHERE f.NUM_FACT = d.Num_fact AND f.SERIALTIPO = d.SerialFiscal AND f.Tipo_Orden = d.Memoria);
    PRINT N'Limpiados Detalle_FormaPagoFacturas huérfanos (clave fiscal compuesta).';
END

-- Detalle_FormaPagoCotizacion: huérfanos por (Num_fact, SerialFiscal) = (NUM_FACT, SERIALTIPO)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCotizacion')
BEGIN
    DELETE d FROM dbo.Detalle_FormaPagoCotizacion d
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Cotizacion c WHERE c.NUM_FACT = d.Num_fact AND c.SERIALTIPO = d.SerialFiscal);
    PRINT N'Limpiados Detalle_FormaPagoCotizacion huérfanos (clave compuesta).';
END
GO

SET NOCOUNT ON;
-- ---------- C. (Primero) Añadir Tipo_Orden a Detalle_facturas y rellenar ----------
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_facturas') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
BEGIN
    ALTER TABLE dbo.Detalle_facturas ADD Tipo_Orden NVARCHAR(3) NULL;
    PRINT N'Columna Tipo_Orden añadida a Detalle_facturas.';
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_facturas') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
BEGIN
    UPDATE d SET d.Tipo_Orden = f.Tipo_Orden
    FROM dbo.Detalle_facturas d
    INNER JOIN dbo.Facturas f ON f.NUM_FACT = d.NUM_FACT AND f.SERIALTIPO = d.SERIALTIPO
    WHERE d.Tipo_Orden IS NULL;
    UPDATE d SET d.Tipo_Orden = (SELECT TOP 1 f.Tipo_Orden FROM dbo.Facturas f WHERE f.NUM_FACT = d.NUM_FACT AND f.SERIALTIPO = d.SERIALTIPO)
    FROM dbo.Detalle_facturas d
    WHERE d.Tipo_Orden IS NULL AND EXISTS (SELECT 1 FROM dbo.Facturas f WHERE f.NUM_FACT = d.NUM_FACT AND f.SERIALTIPO = d.SERIALTIPO);
    PRINT N'Detalle_facturas.Tipo_Orden rellenado desde Facturas.';
END
GO

SET NOCOUNT ON;
-- ---------- A. Alinear longitudes de columnas para FKs ----------

-- P_Cobrar.CODIGO y P_Cobrarc.CODIGO -> mismo tipo que Clientes.CODIGO (nvarchar(12))
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrar')
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'p_cobrar' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'PC_COD' AND object_id = OBJECT_ID('dbo.P_Cobrar'))
            DROP INDEX PC_COD ON dbo.P_Cobrar;
        ALTER TABLE dbo.P_Cobrar ALTER COLUMN CODIGO NVARCHAR(12) NULL;
        PRINT N'P_Cobrar.CODIGO ajustado a NVARCHAR(12).';
    END
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Cobrarc')
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'P_Cobrarc' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'PC_COD' AND object_id = OBJECT_ID('dbo.P_Cobrarc'))
            DROP INDEX PC_COD ON dbo.P_Cobrarc;
        ALTER TABLE dbo.P_Cobrarc ALTER COLUMN CODIGO NVARCHAR(12) NULL;
        PRINT N'P_Cobrarc.CODIGO ajustado a NVARCHAR(12).';
    END
END

-- P_Pagar.CODIGO -> mismo que Proveedores.CODIGO (nvarchar(10))
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'P_Pagar')
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'P_Pagar' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 10)
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'PC_COD' AND object_id = OBJECT_ID('dbo.P_Pagar'))
            DROP INDEX PC_COD ON dbo.P_Pagar;
        IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'PC_REL' AND object_id = OBJECT_ID('dbo.P_Pagar'))
            DROP INDEX PC_REL ON dbo.P_Pagar;
        ALTER TABLE dbo.P_Pagar ALTER COLUMN CODIGO NVARCHAR(10) NULL;
        PRINT N'P_Pagar.CODIGO ajustado a NVARCHAR(10).';
    END
END

-- Detalle_Deposito.Cliente -> Clientes.CODIGO (nvarchar(12))
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Deposito')
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Detalle_Deposito' AND COLUMN_NAME = 'Cliente' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    BEGIN
        ALTER TABLE dbo.Detalle_Deposito ALTER COLUMN Cliente NVARCHAR(12) NULL;
        PRINT N'Detalle_Deposito.Cliente ajustado a NVARCHAR(12).';
    END
END

-- Tablas documento que referencian Clientes: CODIGO debe ser NVARCHAR(12) como Clientes
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Cotizacion' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    ALTER TABLE dbo.Cotizacion ALTER COLUMN CODIGO NVARCHAR(12) NULL;
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Pedidos' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    ALTER TABLE dbo.Pedidos ALTER COLUMN CODIGO NVARCHAR(12) NULL;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Presupuestos') AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Presupuestos' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    ALTER TABLE dbo.Presupuestos ALTER COLUMN CODIGO NVARCHAR(12) NULL;
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NOTACREDITO' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    ALTER TABLE dbo.NOTACREDITO ALTER COLUMN CODIGO NVARCHAR(12) NULL;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'NOTADEBITO') AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NOTADEBITO' AND COLUMN_NAME = 'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
    ALTER TABLE dbo.NOTADEBITO ALTER COLUMN CODIGO NVARCHAR(12) NULL;
PRINT N'CODIGO (12) en tablas documento ajustado.';

-- Inventario_Aux.CODIGO -> Inventario.CODIGO (nvarchar(15)). Solo si no hay valores > 15 caracteres.
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario_Aux')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Inventario_Aux WHERE LEN(ISNULL(CODIGO,'')) > 15)
    BEGIN
        ALTER TABLE dbo.Inventario_Aux ALTER COLUMN CODIGO NVARCHAR(15) NULL;
        PRINT N'Inventario_Aux.CODIGO ajustado a NVARCHAR(15).';
    END
    ELSE
        PRINT N'Inventario_Aux: no se altera CODIGO (hay valores > 15 caracteres).';
END

-- ---------- B. Detalle_Compras: COD_PROVEEDOR misma longitud que Compras (10) y sincronizado ----------
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_Compras') AND name = 'COD_PROVEEDOR')
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Detalle_Compras' AND COLUMN_NAME = 'COD_PROVEEDOR' AND CHARACTER_MAXIMUM_LENGTH <> 10)
        ALTER TABLE dbo.Detalle_Compras ALTER COLUMN COD_PROVEEDOR NVARCHAR(10) NULL;
    UPDATE d SET d.COD_PROVEEDOR = c.COD_PROVEEDOR
    FROM dbo.Detalle_Compras d
    INNER JOIN dbo.Compras c ON c.NUM_FACT = d.NUM_FACT
    WHERE d.COD_PROVEEDOR IS NULL OR d.COD_PROVEEDOR <> c.COD_PROVEEDOR;
    PRINT N'Detalle_Compras.COD_PROVEEDOR actualizado desde Compras.';
END

-- ---------- D. Añadir Tipo_Orden a Detalle_notacredito y rellenar desde NOTACREDITO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notacredito')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notacredito') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
    BEGIN
        ALTER TABLE dbo.Detalle_notacredito ADD Tipo_Orden NVARCHAR(3) NULL;
        PRINT N'Columna Tipo_Orden añadida a Detalle_notacredito.';
    END
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notacredito')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notacredito') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
BEGIN
    UPDATE d SET d.Tipo_Orden = n.Tipo_Orden
    FROM dbo.Detalle_notacredito d
    INNER JOIN dbo.NOTACREDITO n ON n.NUM_FACT = d.NUM_FACT AND n.SERIALTIPO = d.SERIALTIPO
    WHERE d.Tipo_Orden IS NULL;
    UPDATE d SET d.Tipo_Orden = (SELECT TOP 1 n.Tipo_Orden FROM dbo.NOTACREDITO n WHERE n.NUM_FACT = d.NUM_FACT AND n.SERIALTIPO = d.SERIALTIPO)
    FROM dbo.Detalle_notacredito d
    WHERE d.Tipo_Orden IS NULL AND EXISTS (SELECT 1 FROM dbo.NOTACREDITO n WHERE n.NUM_FACT = d.NUM_FACT AND n.SERIALTIPO = d.SERIALTIPO);
    PRINT N'Detalle_notacredito.Tipo_Orden rellenado desde NOTACREDITO.';
END
GO

-- ---------- E. Crear FKs que faltan (compuestas y de longitud corregida) ----------

-- FK: Detalle_facturas (NUM_FACT, SERIALTIPO, Tipo_Orden) -> Facturas
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_facturas_Facturas')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_facturas ADD CONSTRAINT FK_Detalle_facturas_Facturas
            FOREIGN KEY (NUM_FACT, SERIALTIPO, Tipo_Orden) REFERENCES dbo.Facturas(NUM_FACT, SERIALTIPO, Tipo_Orden);
        PRINT N'Creada FK_Detalle_facturas_Facturas (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_facturas_Facturas: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_facturas.COD_SERV -> Inventario.CODIGO (solo si Inventario tiene PK o UNIQUE en CODIGO)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_facturas_Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id AND c.name = 'CODIGO' WHERE i.object_id = OBJECT_ID('dbo.Inventario') AND (i.is_primary_key = 1 OR i.is_unique = 1))
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
ELSE IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_facturas_Inventario')
    PRINT N'FK_Detalle_facturas_Inventario omitida (Inventario sin PK/UNIQUE en CODIGO).';

-- FK: Detalle_FormaPagoFacturas (Num_fact, SerialFiscal, Memoria) -> Facturas (NUM_FACT, SERIALTIPO, Tipo_Orden)
-- SerialFiscal = SERIALTIPO máquina fiscal; Memoria = Tipo_Orden (número de memoria física)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoFacturas')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoFacturas_Facturas')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoFacturas ADD CONSTRAINT FK_Detalle_FormaPagoFacturas_Facturas
            FOREIGN KEY (Num_fact, SerialFiscal, Memoria) REFERENCES dbo.Facturas(NUM_FACT, SERIALTIPO, Tipo_Orden);
        PRINT N'Creada FK_Detalle_FormaPagoFacturas_Facturas (clave fiscal compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_FormaPagoFacturas_Facturas: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Compras (NUM_FACT, COD_PROVEEDOR) -> Compras
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Compras_Compras')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Compras ADD CONSTRAINT FK_Detalle_Compras_Compras
            FOREIGN KEY (NUM_FACT, COD_PROVEEDOR) REFERENCES dbo.Compras(NUM_FACT, COD_PROVEEDOR);
        PRINT N'Creada FK_Detalle_Compras_Compras (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Compras_Compras: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Compras.CODIGO -> Inventario.CODIGO (solo si Inventario tiene PK/UNIQUE en CODIGO)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Compras_Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id AND c.name = 'CODIGO' WHERE i.object_id = OBJECT_ID('dbo.Inventario') AND (i.is_primary_key = 1 OR i.is_unique = 1))
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
ELSE IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Compras_Inventario')
    PRINT N'FK_Detalle_Compras_Inventario omitida (Inventario sin PK/UNIQUE en CODIGO).';

-- FK: Detalle_FormaPagoCompras (Num_fact, Cod_Proveedor) -> Compras (NUM_FACT, COD_PROVEEDOR)
-- Nota: requiere que longitudes coincidan; si la PK de Detalle_FormaPagoCompras usa Num_fact no se puede alterar.
IF EXISTS (SELECT 1 FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id WHERE t.name = N'Detalle_FormaPagoCompras' AND c.name IN ('Num_fact','Cod_Proveedor'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoCompras_Compras')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoCompras ADD CONSTRAINT FK_Detalle_FormaPagoCompras_Compras
            FOREIGN KEY (Num_fact, Cod_Proveedor) REFERENCES dbo.Compras(NUM_FACT, COD_PROVEEDOR);
        PRINT N'Creada FK_Detalle_FormaPagoCompras_Compras (compuesta).';
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

-- FK: Detalle_Cotizacion (NUM_FACT, SERIALTIPO) -> Cotizacion
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Cotizacion_Cotizacion')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Cotizacion ADD CONSTRAINT FK_Detalle_Cotizacion_Cotizacion
            FOREIGN KEY (NUM_FACT, SERIALTIPO) REFERENCES dbo.Cotizacion(NUM_FACT, SERIALTIPO);
        PRINT N'Creada FK_Detalle_Cotizacion_Cotizacion (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Cotizacion_Cotizacion: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_FormaPagoCotizacion (Num_fact, SerialFiscal) -> Cotizacion (NUM_FACT, SERIALTIPO)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_FormaPagoCotizacion')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_FormaPagoCotizacion_Cotizacion')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_FormaPagoCotizacion ADD CONSTRAINT FK_Detalle_FormaPagoCotizacion_Cotizacion
            FOREIGN KEY (Num_fact, SerialFiscal) REFERENCES dbo.Cotizacion(NUM_FACT, SERIALTIPO);
        PRINT N'Creada FK_Detalle_FormaPagoCotizacion_Cotizacion (clave compuesta).';
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

-- FK: Detalle_Pedidos (NUM_FACT, SERIALTIPO) -> Pedidos
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Pedidos_Pedidos')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Pedidos ADD CONSTRAINT FK_Detalle_Pedidos_Pedidos
            FOREIGN KEY (NUM_FACT, SERIALTIPO) REFERENCES dbo.Pedidos(NUM_FACT, SERIALTIPO);
        PRINT N'Creada FK_Detalle_Pedidos_Pedidos (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Pedidos_Pedidos: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Pedidos.COD_SERV -> Inventario.CODIGO (solo si Inventario tiene PK/UNIQUE en CODIGO)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Pedidos_Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id AND c.name = 'CODIGO' WHERE i.object_id = OBJECT_ID('dbo.Inventario') AND (i.is_primary_key = 1 OR i.is_unique = 1))
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
ELSE IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Pedidos_Inventario')
    PRINT N'FK_Detalle_Pedidos_Inventario omitida (Inventario sin PK/UNIQUE en CODIGO).';

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

-- FK: Detalle_Presupuestos (NUM_FACT, SERIALTIPO) -> Presupuestos
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Presupuestos')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Presupuestos_Presupuestos')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Presupuestos ADD CONSTRAINT FK_Detalle_Presupuestos_Presupuestos
            FOREIGN KEY (NUM_FACT, SERIALTIPO) REFERENCES dbo.Presupuestos(NUM_FACT, SERIALTIPO);
        PRINT N'Creada FK_Detalle_Presupuestos_Presupuestos (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Presupuestos_Presupuestos: ' + ERROR_MESSAGE();
    END CATCH
END

-- FK: Detalle_Ordenes (NUM_FACT, SERIALTIPO) -> Ordenes
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_Ordenes')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Ordenes_Ordenes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Ordenes ADD CONSTRAINT FK_Detalle_Ordenes_Ordenes
            FOREIGN KEY (NUM_FACT, SERIALTIPO) REFERENCES dbo.Ordenes(NUM_FACT, SERIALTIPO);
        PRINT N'Creada FK_Detalle_Ordenes_Ordenes (compuesta).';
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

-- FK: Detalle_notacredito (NUM_FACT, SERIALTIPO, Tipo_Orden) -> NOTACREDITO
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notacredito')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notacredito') AND name = 'Tipo_Orden')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_notacredito_NOTACREDITO')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_notacredito ADD CONSTRAINT FK_Detalle_notacredito_NOTACREDITO
            FOREIGN KEY (NUM_FACT, SERIALTIPO, Tipo_Orden) REFERENCES dbo.NOTACREDITO(NUM_FACT, SERIALTIPO, Tipo_Orden);
        PRINT N'Creada FK_Detalle_notacredito_NOTACREDITO (compuesta).';
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

-- FK: MovInvent.Codigo -> Inventario.CODIGO (solo si Inventario tiene PK/UNIQUE en CODIGO)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MovInvent_Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id AND c.name = 'CODIGO' WHERE i.object_id = OBJECT_ID('dbo.Inventario') AND (i.is_primary_key = 1 OR i.is_unique = 1))
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.MovInvent ADD CONSTRAINT FK_MovInvent_Inventario
            FOREIGN KEY (Codigo) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'Creada FK_MovInvent_Inventario.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_MovInvent_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_MovInvent_Inventario')
    PRINT N'FK_MovInvent_Inventario omitida (Inventario sin PK/UNIQUE en CODIGO).';

-- FK: Inventario_Aux.CODIGO -> Inventario.CODIGO (solo si Inventario tiene PK/UNIQUE en CODIGO)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario_Aux')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventario_Aux_Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id AND c.name = 'CODIGO' WHERE i.object_id = OBJECT_ID('dbo.Inventario') AND (i.is_primary_key = 1 OR i.is_unique = 1))
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
ELSE IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario_Aux') AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Inventario_Aux_Inventario')
    PRINT N'FK_Inventario_Aux_Inventario omitida (Inventario sin PK/UNIQUE en CODIGO).';

-- FK: Detalle_Deposito.Cliente -> Clientes.CODIGO
IF EXISTS (SELECT 1 FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id WHERE t.name = N'Detalle_Deposito' AND c.name = 'Cliente')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_Deposito_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_Deposito ADD CONSTRAINT FK_Detalle_Deposito_Clientes
            FOREIGN KEY (Cliente) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Detalle_Deposito_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_Deposito_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

PRINT N'--- Fin script de corrección FKs ---';
PRINT N'Nota: Las FKs a Inventario(CODIGO) solo se crean si Inventario tiene PK o UNIQUE en CODIGO (actualmente tiene duplicados).';
