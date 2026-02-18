-- =============================================
-- Normalización fase 2: Pagos, Abonos, NOTADEBITO y relaciones
-- Ejecutar después de cleanup_fix_fk_datqbox.sql y cleanup_add_serialtipo_memoria.sql
-- - Limpieza de huérfanos en Pagos, Abonos y sus detalles
-- - FKs Pagos->Clientes, Abonos->Proveedores, detalles->cabecera
-- - NOTADEBITO/Detalle_notadebito: columna Tipo_Orden y FK compuesta si aplica
-- =============================================

SET NOCOUNT ON;

-- ---------- A. Huérfanos: Pagos y Pagos_Detalle ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos')
BEGIN
    -- Pagos sin cliente
    DELETE p FROM dbo.Pagos p
    WHERE p.CODIGO IS NOT NULL AND LTRIM(RTRIM(p.CODIGO)) <> N''
      AND NOT EXISTS (SELECT 1 FROM dbo.Clientes c WHERE c.CODIGO = p.CODIGO);
    PRINT N'Limpiados Pagos huérfanos (sin Clientes).';

    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos_Detalle')
    BEGIN
        -- Pagos_Detalle sin Pagos (por RECNUM y CODIGO)
        DELETE d FROM dbo.Pagos_Detalle d
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Pagos p
            WHERE p.CODIGO = d.CODIGO AND p.RECNUM = d.RECNUM
        );
        PRINT N'Limpiados Pagos_Detalle huérfanos.';
    END
END

-- ---------- B. Huérfanos: Abonos y Abonos_Detalle ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos')
BEGIN
    DELETE a FROM dbo.Abonos a
    WHERE a.CODIGO IS NOT NULL AND LTRIM(RTRIM(a.CODIGO)) <> N''
      AND NOT EXISTS (SELECT 1 FROM dbo.Proveedores pr WHERE pr.CODIGO = a.CODIGO);
    PRINT N'Limpiados Abonos huérfanos (sin Proveedores).';

    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos_Detalle')
    BEGIN
        DELETE d FROM dbo.Abonos_Detalle d
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Abonos a
            WHERE a.CODIGO = d.codigo AND a.RECNUM = d.RECNUM
        );
        PRINT N'Limpiados Abonos_Detalle huérfanos.';
    END
END

-- ---------- C. Alinear longitudes: Pagos.CODIGO, Pagos_Detalle.CODIGO -> Clientes (12) ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Pagos' AND COLUMN_NAME = N'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
BEGIN
    ALTER TABLE dbo.Pagos ALTER COLUMN CODIGO NVARCHAR(12) NULL;
    PRINT N'Pagos.CODIGO ajustado a NVARCHAR(12).';
END
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos_Detalle')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Pagos_Detalle') AND name = 'CODIGO')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Pagos_Detalle' AND COLUMN_NAME = N'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 12)
BEGIN
    ALTER TABLE dbo.Pagos_Detalle ALTER COLUMN CODIGO NVARCHAR(12) NULL;
    PRINT N'Pagos_Detalle.CODIGO ajustado a NVARCHAR(12).';
END

-- Abonos.CODIGO y Abonos_Detalle.codigo -> Proveedores (10)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Abonos' AND COLUMN_NAME = N'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 10)
BEGIN
    ALTER TABLE dbo.Abonos ALTER COLUMN CODIGO NVARCHAR(10) NULL;
    PRINT N'Abonos.CODIGO ajustado a NVARCHAR(10).';
END
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos_Detalle')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Abonos_Detalle') AND name IN ('codigo','CODIGO'))
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Abonos_Detalle' AND COLUMN_NAME = N'codigo' AND CHARACTER_MAXIMUM_LENGTH <> 10)
    BEGIN
        ALTER TABLE dbo.Abonos_Detalle ALTER COLUMN codigo NVARCHAR(10) NULL;
        PRINT N'Abonos_Detalle.codigo ajustado a NVARCHAR(10).';
    END
END
GO

-- ---------- D. FK Pagos.CODIGO -> Clientes.CODIGO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Pagos_Clientes')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Pagos ADD CONSTRAINT FK_Pagos_Clientes
            FOREIGN KEY (CODIGO) REFERENCES dbo.Clientes(CODIGO);
        PRINT N'Creada FK_Pagos_Clientes.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Pagos_Clientes: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- E. FK Abonos.CODIGO -> Proveedores.CODIGO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Abonos_Proveedores')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Abonos ADD CONSTRAINT FK_Abonos_Proveedores
            FOREIGN KEY (CODIGO) REFERENCES dbo.Proveedores(CODIGO);
        PRINT N'Creada FK_Abonos_Proveedores.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Abonos_Proveedores: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- F. Índice único Pagos(CODIGO, RECNUM) y FK Pagos_Detalle -> Pagos ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos')
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Pagos_CODIGO_RECNUM' AND object_id = OBJECT_ID('dbo.Pagos'))
BEGIN
    BEGIN TRY
        CREATE UNIQUE NONCLUSTERED INDEX UQ_Pagos_CODIGO_RECNUM ON dbo.Pagos(CODIGO, RECNUM)
            WHERE CODIGO IS NOT NULL AND RECNUM IS NOT NULL;
        PRINT N'Creado índice único UQ_Pagos_CODIGO_RECNUM.';
    END TRY
    BEGIN CATCH
        PRINT N'Índice UQ_Pagos_CODIGO_RECNUM (duplicados o NULL): ' + ERROR_MESSAGE();
    END CATCH
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Pagos_Detalle')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Pagos_CODIGO_RECNUM' AND object_id = OBJECT_ID('dbo.Pagos'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Pagos_Detalle_Pagos')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Pagos_Detalle ADD CONSTRAINT FK_Pagos_Detalle_Pagos
            FOREIGN KEY (CODIGO, RECNUM) REFERENCES dbo.Pagos(CODIGO, RECNUM);
        PRINT N'Creada FK_Pagos_Detalle_Pagos.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Pagos_Detalle_Pagos: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- G. Índice único Abonos(CODIGO, RECNUM) y FK Abonos_Detalle -> Abonos ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos')
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Abonos_CODIGO_RECNUM' AND object_id = OBJECT_ID('dbo.Abonos'))
BEGIN
    BEGIN TRY
        CREATE UNIQUE NONCLUSTERED INDEX UQ_Abonos_CODIGO_RECNUM ON dbo.Abonos(CODIGO, RECNUM)
            WHERE CODIGO IS NOT NULL AND RECNUM IS NOT NULL;
        PRINT N'Creado índice único UQ_Abonos_CODIGO_RECNUM.';
    END TRY
    BEGIN CATCH
        PRINT N'Índice UQ_Abonos_CODIGO_RECNUM: ' + ERROR_MESSAGE();
    END CATCH
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Abonos_Detalle')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Abonos_CODIGO_RECNUM' AND object_id = OBJECT_ID('dbo.Abonos'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Abonos_Detalle_Abonos')
BEGIN
    BEGIN TRY
        -- Abonos_Detalle puede tener columna 'codigo' en minúscula
        ALTER TABLE dbo.Abonos_Detalle ADD CONSTRAINT FK_Abonos_Detalle_Abonos
            FOREIGN KEY (codigo, RECNUM) REFERENCES dbo.Abonos(CODIGO, RECNUM);
        PRINT N'Creada FK_Abonos_Detalle_Abonos.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Abonos_Detalle_Abonos: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- H. NOTADEBITO: columna Tipo_Orden si no existe y rellenar ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'NOTADEBITO')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.NOTADEBITO') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
    BEGIN
        ALTER TABLE dbo.NOTADEBITO ADD Tipo_Orden NVARCHAR(6) NULL;
        PRINT N'NOTADEBITO: columna Tipo_Orden añadida.';
    END
    -- Rellenar con valor por defecto si está vacío (documentos antiguos)
    UPDATE dbo.NOTADEBITO SET Tipo_Orden = N'1' WHERE Tipo_Orden IS NULL OR LTRIM(RTRIM(Tipo_Orden)) = N'';
END
GO

-- ---------- I. Detalle_notadebito: columna Tipo_Orden y rellenar desde NOTADEBITO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notadebito')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notadebito') AND name COLLATE Latin1_General_CI_AS = N'Tipo_Orden')
    BEGIN
        ALTER TABLE dbo.Detalle_notadebito ADD Tipo_Orden NVARCHAR(6) NULL;
        PRINT N'Detalle_notadebito: columna Tipo_Orden añadida.';
    END
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notadebito') AND name = 'SERIALTIPO')
    BEGIN
        UPDATE d SET d.Tipo_Orden = n.Tipo_Orden
        FROM dbo.Detalle_notadebito d
        INNER JOIN dbo.NOTADEBITO n ON n.NUM_FACT = d.NUM_FACT AND (d.SERIALTIPO = n.SERIALTIPO OR (d.SERIALTIPO IS NULL AND n.SERIALTIPO IS NULL))
        WHERE d.Tipo_Orden IS NULL;
        PRINT N'Detalle_notadebito.Tipo_Orden rellenado desde NOTADEBITO.';
    END
END
GO

-- ---------- J. FK Detalle_notadebito (NUM_FACT, SERIALTIPO, Tipo_Orden) -> NOTADEBITO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Detalle_notadebito')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Detalle_notadebito') AND name = 'Tipo_Orden')
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Detalle_notadebito_NOTADEBITO')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Detalle_notadebito ADD CONSTRAINT FK_Detalle_notadebito_NOTADEBITO
            FOREIGN KEY (NUM_FACT, SERIALTIPO, Tipo_Orden) REFERENCES dbo.NOTADEBITO(NUM_FACT, SERIALTIPO, Tipo_Orden);
        PRINT N'Creada FK_Detalle_notadebito_NOTADEBITO (compuesta).';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_Detalle_notadebito_NOTADEBITO: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- K. NOTADEBITO: índice único (NUM_FACT, SERIALTIPO, Tipo_Orden) para la FK ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'NOTADEBITO')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.NOTADEBITO') AND name = 'Tipo_Orden')
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_NOTADEBITO_NUM_SERIAL_TIPO' AND object_id = OBJECT_ID('dbo.NOTADEBITO'))
BEGIN
    BEGIN TRY
        CREATE UNIQUE NONCLUSTERED INDEX UQ_NOTADEBITO_NUM_SERIAL_TIPO
            ON dbo.NOTADEBITO(NUM_FACT, SERIALTIPO, Tipo_Orden)
            WHERE NUM_FACT IS NOT NULL AND SERIALTIPO IS NOT NULL AND Tipo_Orden IS NOT NULL;
        PRINT N'Creado índice único UQ_NOTADEBITO_NUM_SERIAL_TIPO.';
    END TRY
    BEGIN CATCH
        PRINT N'Índice UQ_NOTADEBITO_NUM_SERIAL_TIPO: ' + ERROR_MESSAGE();
    END CATCH
END

PRINT N'--- Fin normalización fase 2 ---';
