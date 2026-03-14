-- =============================================
-- Añadir SERIALTIPO y Memoria/Tipo_Orden donde falten para relacionar documentos
-- El serial fiscal y el número de memoria son clave para documentos EMITIDOS POR NOSOTROS.
-- No se tocan Compras ni P_Pagar/P_Pagarc: la factura de compra es del proveedor y se
-- identifica por (NUM_FACT, COD_PROVEEDOR); esa combinación nunca se repite.
-- Ejecutar antes o después de cleanup_fix_fk_datqbox.sql (una vez).
-- =============================================

SET NOCOUNT ON;

-- ---------- 1. P_Cobrar: añadir SERIALTIPO y Tipo_Orden ----------
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.P_Cobrar') AND name = 'SERIALTIPO')
BEGIN
    ALTER TABLE dbo.P_Cobrar ADD SERIALTIPO NVARCHAR(40) NULL;
    PRINT N'P_Cobrar: columna SERIALTIPO añadida.';
END
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.P_Cobrar') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
BEGIN
    ALTER TABLE dbo.P_Cobrar ADD Tipo_Orden NVARCHAR(6) NULL;
    PRINT N'P_Cobrar: columna Tipo_Orden añadida.';
END
GO

-- Rellenar P_Cobrar desde Facturas (TIPO = 'FACT')
UPDATE p SET p.SERIALTIPO = f.SERIALTIPO, p.Tipo_Orden = f.Tipo_Orden
FROM dbo.P_Cobrar p
INNER JOIN dbo.Facturas f ON f.NUM_FACT = p.DOCUMENTO AND p.TIPO = N'FACT'
WHERE p.SERIALTIPO IS NULL OR p.Tipo_Orden IS NULL;
PRINT N'P_Cobrar: SERIALTIPO y Tipo_Orden rellenados desde Facturas.';

-- Rellenar P_Cobrar desde Presupuestos (TIPO = 'PRESUP')
UPDATE p SET p.SERIALTIPO = pr.SERIALTIPO, p.Tipo_Orden = pr.tipo_orden
FROM dbo.P_Cobrar p
INNER JOIN dbo.Presupuestos pr ON pr.NUM_FACT = p.DOCUMENTO AND p.TIPO = N'PRESUP'
WHERE p.SERIALTIPO IS NULL OR p.Tipo_Orden IS NULL;
PRINT N'P_Cobrar: SERIALTIPO y Tipo_Orden rellenados desde Presupuestos.';

-- Rellenar P_Cobrar desde Cotizacion (TIPO puede ser COTIZ u otro según su lógica; si existe)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.P_Cobrar') AND name = 'SERIALTIPO')
BEGIN
    UPDATE p SET p.SERIALTIPO = c.SERIALTIPO
    FROM dbo.P_Cobrar p
    INNER JOIN dbo.Cotizacion c ON c.NUM_FACT = p.DOCUMENTO
    WHERE p.TIPO IN (N'COTIZ', N'COT') AND p.SERIALTIPO IS NULL;
    PRINT N'P_Cobrar: SERIALTIPO rellenado desde Cotizacion donde aplica.';
END
GO

-- ---------- 2. P_Cobrarc: añadir SERIALTIPO y Tipo_Orden ----------
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.P_Cobrarc') AND name = 'SERIALTIPO')
BEGIN
    ALTER TABLE dbo.P_Cobrarc ADD SERIALTIPO NVARCHAR(40) NULL;
    PRINT N'P_Cobrarc: columna SERIALTIPO añadida.';
END
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.P_Cobrarc') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
BEGIN
    ALTER TABLE dbo.P_Cobrarc ADD Tipo_Orden NVARCHAR(6) NULL;
    PRINT N'P_Cobrarc: columna Tipo_Orden añadida.';
END
GO

UPDATE p SET p.SERIALTIPO = f.SERIALTIPO, p.Tipo_Orden = f.Tipo_Orden
FROM dbo.P_Cobrarc p
INNER JOIN dbo.Facturas f ON f.NUM_FACT = p.DOCUMENTO
WHERE p.TIPO = N'FACT' AND (p.SERIALTIPO IS NULL OR p.Tipo_Orden IS NULL);
UPDATE p SET p.SERIALTIPO = pr.SERIALTIPO, p.Tipo_Orden = pr.tipo_orden
FROM dbo.P_Cobrarc p
INNER JOIN dbo.Presupuestos pr ON pr.NUM_FACT = p.DOCUMENTO
WHERE p.TIPO = N'PRESUP' AND (p.SERIALTIPO IS NULL OR p.Tipo_Orden IS NULL);
PRINT N'P_Cobrarc: SERIALTIPO y Tipo_Orden rellenados.';
GO

-- ---------- 3. DetallePago: añadir SerialFiscal y Memoria (relación con documento fiscal) ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DetallePago')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.DetallePago') AND name = 'SerialFiscal')
    BEGIN
        ALTER TABLE dbo.DetallePago ADD SerialFiscal NVARCHAR(40) NULL;
        PRINT N'DetallePago: columna SerialFiscal añadida.';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.DetallePago') AND name = 'Memoria')
    BEGIN
        ALTER TABLE dbo.DetallePago ADD Memoria NVARCHAR(6) NULL;
        PRINT N'DetallePago: columna Memoria añadida.';
    END
    UPDATE d SET d.SerialFiscal = f.SERIALTIPO, d.Memoria = f.Tipo_Orden
    FROM dbo.DetallePago d
    INNER JOIN dbo.Facturas f ON f.NUM_FACT = d.Num_Fact
    WHERE d.SerialFiscal IS NULL OR d.Memoria IS NULL;
    PRINT N'DetallePago: SerialFiscal y Memoria rellenados desde Facturas.';
END
GO

-- ---------- 4. AbonosPagos: añadir SerialFiscal y Memoria ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'AbonosPagos')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.AbonosPagos') AND name = 'SerialFiscal')
    BEGIN
        ALTER TABLE dbo.AbonosPagos ADD SerialFiscal NVARCHAR(40) NULL;
        PRINT N'AbonosPagos: columna SerialFiscal añadida.';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.AbonosPagos') AND name = 'Memoria')
    BEGIN
        ALTER TABLE dbo.AbonosPagos ADD Memoria NVARCHAR(6) NULL;
        PRINT N'AbonosPagos: columna Memoria añadida.';
    END
    -- CxP: documento puede ser compra (NUM_FACT) o factura; si hay match con Facturas rellenar
    UPDATE a SET a.SerialFiscal = f.SERIALTIPO, a.Memoria = f.Tipo_Orden
    FROM dbo.AbonosPagos a
    INNER JOIN dbo.Facturas f ON f.NUM_FACT = a.Num_fact
    WHERE a.SerialFiscal IS NULL OR a.Memoria IS NULL;
    PRINT N'AbonosPagos: SerialFiscal y Memoria rellenados desde Facturas donde aplica.';
END
GO

-- ---------- 5. AbonosPagosClientes: añadir SerialFiscal y Memoria ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'AbonosPagosClientes')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.AbonosPagosClientes') AND name = 'SerialFiscal')
    BEGIN
        ALTER TABLE dbo.AbonosPagosClientes ADD SerialFiscal NVARCHAR(40) NULL;
        PRINT N'AbonosPagosClientes: columna SerialFiscal añadida.';
    END
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.AbonosPagosClientes') AND name = 'Memoria')
    BEGIN
        ALTER TABLE dbo.AbonosPagosClientes ADD Memoria NVARCHAR(6) NULL;
        PRINT N'AbonosPagosClientes: columna Memoria añadida.';
    END
    UPDATE a SET a.SerialFiscal = f.SERIALTIPO, a.Memoria = f.Tipo_Orden
    FROM dbo.AbonosPagosClientes a
    INNER JOIN dbo.Facturas f ON f.NUM_FACT = a.Num_fact
    WHERE a.SerialFiscal IS NULL OR a.Memoria IS NULL;
    PRINT N'AbonosPagosClientes: SerialFiscal y Memoria rellenados desde Facturas donde aplica.';
END
GO

PRINT N'--- Fin: SERIALTIPO y Memoria/Tipo_Orden añadidos donde faltaban ---';
