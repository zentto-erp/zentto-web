-- =============================================
-- Crear UNIQUE en Inventario(CODIGO) y FKs DocumentosVentaDetalle/DocumentosCompraDetalle -> Inventario
-- Si hay duplicados en Inventario.CODIGO, se renombran (CODIGO + _ + Id o _ + rn) para que las FK funcionen.
-- =============================================

USE [Sanjose]
GO

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- ---------- 0. Asegurar columna Id en Inventario (para poder identificar duplicados) ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
   AND NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inventario') AND name = N'Id')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.Inventario ADD Id INT IDENTITY(1,1) NOT NULL;
        PRINT N'Inventario: columna Id agregada.';
    END TRY
    BEGIN CATCH
        PRINT N'Inventario.Id: ' + ERROR_MESSAGE();
    END CATCH
END
GO

SET NOCOUNT ON;

-- ---------- 1. Resolver duplicados solo si aún no existe índice único en CODIGO ----------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Inventario_CODIGO' AND object_id = OBJECT_ID('dbo.Inventario'))
   AND EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
BEGIN
    -- 1a. Si Inventario tiene columna Id: dejar un registro por CODIGO (MIN(Id)), el resto CODIGO + '_' + Id
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inventario') AND name = N'Id')
    BEGIN
        -- Asegurar que CODIGO tenga longitud suficiente para CODIGO + '_' + Id (ej. 80)
        DECLARE @MaxLen INT;
        SELECT @MaxLen = CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'Inventario' AND COLUMN_NAME = N'CODIGO';
        IF @MaxLen IS NOT NULL AND @MaxLen < 80
        BEGIN
            ALTER TABLE dbo.Inventario ALTER COLUMN CODIGO NVARCHAR(80) NULL;
            PRINT N'Inventario.CODIGO ampliado a NVARCHAR(80) para sufijos.';
        END

        ;WITH Duplicados AS (
            SELECT CODIGO, MIN(Id) AS IdMantener
            FROM dbo.Inventario
            WHERE CODIGO IS NOT NULL AND LTRIM(RTRIM(CODIGO)) <> N''
            GROUP BY CODIGO
            HAVING COUNT(*) > 1
        )
        UPDATE i
        SET i.CODIGO = LEFT(i.CODIGO, 68) + N'_' + CAST(i.Id AS NVARCHAR(10))
        FROM dbo.Inventario i
        INNER JOIN Duplicados d ON d.CODIGO = i.CODIGO AND i.Id <> d.IdMantener;
        IF @@ROWCOUNT > 0
            PRINT N'Inventario: duplicados en CODIGO renombrados a CODIGO_Id (se mantuvo un registro por valor).';
    END
    ELSE
        PRINT N'Inventario no tiene columna Id: si hay duplicados en CODIGO, se intentará crear el índice único; si falla, unifique duplicados manualmente o añada columna Id.';
END
GO

-- ---------- 3. Un solo NULL en CODIGO (UNIQUE no filtrado solo permite un NULL) ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Inventario') AND name = N'Id')
BEGIN
    ;WITH Nulls AS (
        SELECT Id, ROW_NUMBER() OVER (ORDER BY Id) AS rn
        FROM dbo.Inventario WHERE CODIGO IS NULL
    )
    UPDATE i SET i.CODIGO = N'_NULL_' + CAST(n.Id AS NVARCHAR(10))
    FROM dbo.Inventario i INNER JOIN Nulls n ON n.Id = i.Id WHERE n.rn > 1;
    IF @@ROWCOUNT > 0
        PRINT N'Inventario: varios NULL en CODIGO reemplazados por _NULL_Id (se dejó un NULL).';
END
GO

-- ---------- 4. Crear índice UNIQUE en Inventario(CODIGO) (no filtrado para que las FK lo referencien) ----------
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Inventario_CODIGO' AND object_id = OBJECT_ID('dbo.Inventario') AND has_filter = 1)
BEGIN
    DROP INDEX UQ_Inventario_CODIGO ON dbo.Inventario;
    PRINT N'Índice UQ_Inventario_CODIGO (filtrado) eliminado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Inventario_CODIGO' AND object_id = OBJECT_ID('dbo.Inventario'))
BEGIN
    BEGIN TRY
        SET QUOTED_IDENTIFIER ON;
        SET ANSI_NULLS ON;
        CREATE UNIQUE NONCLUSTERED INDEX UQ_Inventario_CODIGO ON dbo.Inventario(CODIGO);
        PRINT N'Índice UQ_Inventario_CODIGO creado.';
    END TRY
    BEGIN CATCH
        PRINT N'Error UQ_Inventario_CODIGO: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ---------- 5. Igualar longitud COD_SERV y CODIGO a 80 para que la FK sea válida ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosVentaDetalle')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'DocumentosVentaDetalle' AND COLUMN_NAME = N'COD_SERV' AND CHARACTER_MAXIMUM_LENGTH <> 80)
BEGIN
    ALTER TABLE dbo.DocumentosVentaDetalle ALTER COLUMN COD_SERV NVARCHAR(80) NULL;
    PRINT N'DocumentosVentaDetalle.COD_SERV ajustado a NVARCHAR(80).';
END
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosCompraDetalle')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = N'dbo' AND TABLE_NAME = N'DocumentosCompraDetalle' AND COLUMN_NAME = N'CODIGO' AND CHARACTER_MAXIMUM_LENGTH <> 80)
BEGIN
    ALTER TABLE dbo.DocumentosCompraDetalle ALTER COLUMN CODIGO NVARCHAR(80) NULL;
    PRINT N'DocumentosCompraDetalle.CODIGO ajustado a NVARCHAR(80).';
END

-- ---------- 6. FK DocumentosVentaDetalle.COD_SERV -> Inventario.CODIGO ----------
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosVentaDetalle')
   AND EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Inventario_CODIGO' AND object_id = OBJECT_ID('dbo.Inventario'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosVentaDetalle_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.DocumentosVentaDetalle ADD CONSTRAINT FK_DocumentosVentaDetalle_Inventario
            FOREIGN KEY (COD_SERV) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'FK_DocumentosVentaDetalle_Inventario creada.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_DocumentosVentaDetalle_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

-- ---------- 7. FK DocumentosCompraDetalle.CODIGO -> Inventario.CODIGO ----------
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'DocumentosCompraDetalle')
   AND EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Inventario')
   AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Inventario_CODIGO' AND object_id = OBJECT_ID('dbo.Inventario'))
   AND NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DocumentosCompraDetalle_Inventario')
BEGIN
    BEGIN TRY
        ALTER TABLE dbo.DocumentosCompraDetalle ADD CONSTRAINT FK_DocumentosCompraDetalle_Inventario
            FOREIGN KEY (CODIGO) REFERENCES dbo.Inventario(CODIGO);
        PRINT N'FK_DocumentosCompraDetalle_Inventario creada.';
    END TRY
    BEGIN CATCH
        PRINT N'Error FK_DocumentosCompraDetalle_Inventario: ' + ERROR_MESSAGE();
    END CATCH
END

PRINT N'--- Fin fix_fk_documentos_inventario.sql ---';
