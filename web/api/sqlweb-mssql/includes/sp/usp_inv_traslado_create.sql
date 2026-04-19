-- usp_inv_traslado_create — SQL Server equivalent
IF OBJECT_ID('dbo.usp_inv_traslado_create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_inv_traslado_create;
GO

CREATE PROCEDURE dbo.usp_inv_traslado_create
    @CompanyId      INT,
    @WarehouseFrom  NVARCHAR(20),
    @WarehouseTo    NVARCHAR(20),
    @UserId         INT,
    @Notas          NVARCHAR(MAX) = NULL,
    @Resultado      INT           OUTPUT,
    @Mensaje        NVARCHAR(500) OUTPUT,
    @TrasladoId     INT           OUTPUT,
    @Numero         NVARCHAR(40)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @CompanyId IS NULL OR @CompanyId <= 0
    BEGIN SET @Mensaje = 'CompanyId requerido'; RETURN; END

    IF @WarehouseFrom = @WarehouseTo
    BEGIN SET @Mensaje = 'WarehouseFrom y WarehouseTo no pueden ser iguales'; RETURN; END

    DECLARE @Prefix NVARCHAR(20) = 'TRL-' + FORMAT(GETUTCDATE(), 'yyyyMM') + '-';
    DECLARE @Seq BIGINT;
    SELECT @Seq = ISNULL(MAX(CAST(SUBSTRING(Numero, LEN(@Prefix)+1, 5) AS INT)), 0) + 1
    FROM inv.TrasladoMultiPaso
    WHERE CompanyId = @CompanyId AND Numero LIKE @Prefix + '%';

    SET @Numero = @Prefix + RIGHT('00000' + CAST(@Seq AS NVARCHAR(5)), 5);

    INSERT INTO inv.TrasladoMultiPaso
        (CompanyId, Numero, Estado, WarehouseFrom, WarehouseTo,
         FechaSolicitud, Notas, SolicitadoPorId)
    VALUES
        (@CompanyId, @Numero, 'BORRADOR', @WarehouseFrom, @WarehouseTo,
         GETUTCDATE(), @Notas, @UserId);

    SET @TrasladoId = SCOPE_IDENTITY();
    SET @Resultado = 1;
    SET @Mensaje = 'Traslado creado';
END;
GO
