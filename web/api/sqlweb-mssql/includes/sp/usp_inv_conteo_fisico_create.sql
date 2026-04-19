-- usp_inv_conteo_fisico_create — SQL Server equivalent of PG function
-- Creates a physical inventory count sheet (HojaConteo)
IF OBJECT_ID('dbo.usp_inv_conteo_fisico_create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_inv_conteo_fisico_create;
GO

CREATE PROCEDURE dbo.usp_inv_conteo_fisico_create
    @CompanyId      INT,
    @WarehouseCode  NVARCHAR(20),
    @UserId         INT,
    @Notas          NVARCHAR(MAX) = NULL,
    @Resultado      INT           OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT,
    @HojaConteoId   INT           OUTPUT,
    @Numero         NVARCHAR(30)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @CompanyId IS NULL OR @CompanyId <= 0
    BEGIN
        SET @Mensaje = 'CompanyId requerido'; RETURN;
    END

    DECLARE @Seq BIGINT, @NumPrefix NVARCHAR(10);
    SET @NumPrefix = 'CNT-' + FORMAT(GETUTCDATE(), 'yyyyMM') + '-';

    SELECT @Seq = ISNULL(MAX(CAST(SUBSTRING(Numero, LEN(@NumPrefix)+1, 5) AS INT)), 0) + 1
    FROM inv.HojaConteo
    WHERE CompanyId = @CompanyId AND Numero LIKE @NumPrefix + '%';

    SET @Numero = @NumPrefix + RIGHT('00000' + CAST(@Seq AS NVARCHAR(5)), 5);

    INSERT INTO inv.HojaConteo
        (CompanyId, WarehouseCode, Numero, Estado, FechaConteo, Notas, CreatedByUserId)
    VALUES
        (@CompanyId, @WarehouseCode, @Numero, 'BORRADOR', GETUTCDATE(), @Notas, @UserId);

    SET @HojaConteoId = SCOPE_IDENTITY();
    SET @Resultado = 1;
    SET @Mensaje = 'Hoja de conteo creada';
END;
GO
