-- usp_Store_Product_Specs_Set
-- Reemplaza todas las specs del producto.
-- @SpecsJson: [{group, key, value, sortOrder}]

IF OBJECT_ID('dbo.usp_Store_Product_Specs_Set', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Store_Product_Specs_Set;
GO

CREATE PROCEDURE dbo.usp_Store_Product_Specs_Set
    @CompanyId  INT            = 1,
    @Code       NVARCHAR(80)    = NULL,
    @SpecsJson  NVARCHAR(MAX)   = NULL,
    @Resultado  INT            OUTPUT,
    @Mensaje    NVARCHAR(500)  OUTPUT,
    @Count      INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

    BEGIN TRY
        IF @Code IS NULL
        BEGIN
            SET @Resultado = 0; SET @Mensaje = N'Código requerido'; SET @Count = 0; RETURN;
        END

        BEGIN TRAN;

        DELETE FROM store.ProductSpec
         WHERE CompanyId = @CompanyId AND ProductCode = @Code;

        DECLARE @inserted INT = 0;

        IF @SpecsJson IS NOT NULL AND LEN(@SpecsJson) > 2
        BEGIN
            INSERT INTO store.ProductSpec (
                CompanyId, ProductCode, SpecGroup, SpecKey, SpecValue, SortOrder, IsActive, CreatedAt
            )
            SELECT
                @CompanyId,
                @Code,
                ISNULL(JSON_VALUE(value, '$.group'), 'General'),
                ISNULL(JSON_VALUE(value, '$.key'), ''),
                ISNULL(JSON_VALUE(value, '$.value'), ''),
                ISNULL(TRY_CAST(JSON_VALUE(value, '$.sortOrder') AS INT),
                       CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS INT) - 1),
                1, @now
              FROM OPENJSON(@SpecsJson);

            SET @inserted = @@ROWCOUNT;
        END

        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = CASE WHEN @inserted = 0 THEN N'Specs removidas' ELSE N'Specs actualizadas' END;
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
