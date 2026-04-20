-- usp_Store_Product_Images_Set
-- Reemplaza todas las imágenes del producto (soft-delete previas + insert nuevas).
-- Recibe @ImagesJson con array [{url, altText, role, isPrimary, sortOrder}]
-- Compat SQL Server 2012+: usa OPENJSON que requiere compat_level >= 130 en realidad.
-- En 2012 no existe OPENJSON → se usa sp_executesql con OPENJSON envuelto si está disponible,
-- o se iteran pares via tabla temporal. Aquí usamos OPENJSON (target: 2012+ con compat 130 a futuro).
-- Si el motor es 2012 puro se puede parsear con JSON.NET externo o switch a XML.

IF OBJECT_ID('dbo.usp_Store_Product_Images_Set', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_Images_Set;
GO

CREATE PROCEDURE dbo.usp_Store_Product_Images_Set
    @CompanyId  INT            = 1,
    @BranchId   INT            = 1,
    @Code       NVARCHAR(80)    = NULL,
    @ImagesJson NVARCHAR(MAX)   = NULL,
    @UserId     INT            = NULL,
    @Resultado  INT            OUTPUT,
    @Mensaje    NVARCHAR(500)  OUTPUT,
    @Count      INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @now         DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @productId   BIGINT;
    DECLARE @inserted    INT = 0;

    BEGIN TRY
        SELECT TOP 1 @productId = ProductId
          FROM mstr.Product
         WHERE CompanyId = @CompanyId AND ProductCode = @Code AND IsDeleted = 0;

        IF @productId IS NULL
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Producto no encontrado'; SET @Count = 0; RETURN;
        END

        BEGIN TRAN;

        UPDATE cfg.EntityImage SET
            IsDeleted = 1,
            IsActive  = 0,
            UpdatedAt = @now
         WHERE CompanyId  = @CompanyId
           AND EntityType = 'MASTER_PRODUCT'
           AND EntityId   = @productId
           AND IsDeleted  = 0;

        IF @ImagesJson IS NOT NULL AND LEN(@ImagesJson) > 2
        BEGIN
            DECLARE @tmp TABLE (
                rowIdx    INT IDENTITY(0,1),
                url       NVARCHAR(500),
                altText   NVARCHAR(255),
                roleCode  NVARCHAR(50),
                isPrimary BIT,
                sortOrder INT,
                storageKey NVARCHAR(500),
                storageProvider NVARCHAR(30),
                mimeType  NVARCHAR(100),
                origName  NVARCHAR(255)
            );

            INSERT INTO @tmp (url, altText, roleCode, isPrimary, sortOrder, storageKey, storageProvider, mimeType, origName)
            SELECT
                JSON_VALUE(value, '$.url'),
                JSON_VALUE(value, '$.altText'),
                ISNULL(JSON_VALUE(value, '$.role'), 'PRODUCT_IMAGE'),
                CASE WHEN JSON_VALUE(value, '$.isPrimary') = 'true' THEN 1 ELSE 0 END,
                TRY_CAST(JSON_VALUE(value, '$.sortOrder') AS INT),
                ISNULL(JSON_VALUE(value, '$.storageKey'), JSON_VALUE(value, '$.url')),
                ISNULL(JSON_VALUE(value, '$.storageProvider'), 'external'),
                JSON_VALUE(value, '$.mimeType'),
                JSON_VALUE(value, '$.originalFileName')
              FROM OPENJSON(@ImagesJson);

            DECLARE @rowIdx INT, @url NVARCHAR(500), @altText NVARCHAR(255), @roleCode NVARCHAR(50);
            DECLARE @isPrimary BIT, @sortOrder INT, @storageKey NVARCHAR(500), @storageProvider NVARCHAR(30);
            DECLARE @mimeType NVARCHAR(100), @origName NVARCHAR(255), @mediaId BIGINT;

            DECLARE img_cur CURSOR LOCAL FAST_FORWARD FOR
                SELECT rowIdx, url, altText, roleCode, isPrimary, sortOrder, storageKey, storageProvider, mimeType, origName
                  FROM @tmp
                 ORDER BY rowIdx;
            OPEN img_cur;
            FETCH NEXT FROM img_cur INTO @rowIdx, @url, @altText, @roleCode, @isPrimary, @sortOrder, @storageKey, @storageProvider, @mimeType, @origName;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @url IS NULL OR LEN(@url) = 0
                BEGIN
                    FETCH NEXT FROM img_cur INTO @rowIdx, @url, @altText, @roleCode, @isPrimary, @sortOrder, @storageKey, @storageProvider, @mimeType, @origName;
                    CONTINUE;
                END

                SELECT TOP 1 @mediaId = MediaAssetId
                  FROM cfg.MediaAsset
                 WHERE CompanyId = @CompanyId AND PublicUrl = @url AND IsDeleted = 0;

                IF @mediaId IS NULL
                BEGIN
                    INSERT INTO cfg.MediaAsset (
                        CompanyId, BranchId, StorageProvider, StorageKey, PublicUrl,
                        OriginalFileName, MimeType, AltText, IsActive, IsDeleted, CreatedAt, UpdatedAt
                    ) VALUES (
                        @CompanyId, @BranchId, @storageProvider, @storageKey, @url,
                        @origName, @mimeType, @altText, 1, 0, @now, @now
                    );
                    SET @mediaId = SCOPE_IDENTITY();
                END

                INSERT INTO cfg.EntityImage (
                    CompanyId, BranchId, EntityType, EntityId, MediaAssetId,
                    RoleCode, SortOrder, IsPrimary, IsActive, IsDeleted, CreatedAt, UpdatedAt
                ) VALUES (
                    @CompanyId, @BranchId, 'MASTER_PRODUCT', @productId, @mediaId,
                    ISNULL(@roleCode, 'PRODUCT_IMAGE'),
                    ISNULL(@sortOrder, @inserted),
                    CASE WHEN @isPrimary = 1 OR @inserted = 0 THEN 1 ELSE 0 END,
                    1, 0, @now, @now
                );

                SET @inserted = @inserted + 1;
                SET @mediaId = NULL;

                FETCH NEXT FROM img_cur INTO @rowIdx, @url, @altText, @roleCode, @isPrimary, @sortOrder, @storageKey, @storageProvider, @mimeType, @origName;
            END
            CLOSE img_cur;
            DEALLOCATE img_cur;
        END

        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = CASE WHEN @inserted = 0 THEN N'Imágenes removidas' ELSE N'Imágenes actualizadas' END;
        SET @Count     = @inserted;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        SET @Resultado = -99;
        SET @Mensaje   = LEFT(ERROR_MESSAGE(), 500);
        SET @Count     = 0;
    END CATCH
END
GO
