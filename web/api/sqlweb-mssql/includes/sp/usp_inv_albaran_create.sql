-- usp_inv_albaran_create — SQL Server equivalent
IF OBJECT_ID('dbo.usp_inv_albaran_create', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_inv_albaran_create;
GO

CREATE PROCEDURE dbo.usp_inv_albaran_create
    @CompanyId             INT,
    @Tipo                  NVARCHAR(20),
    @WarehouseFrom         NVARCHAR(20)  = NULL,
    @WarehouseTo           NVARCHAR(20)  = NULL,
    @DestinatarioNombre    NVARCHAR(200) = NULL,
    @DestinatarioRif       NVARCHAR(30)  = NULL,
    @SourceType            NVARCHAR(30)  = NULL,
    @SourceId              INT           = NULL,
    @Observaciones         NVARCHAR(MAX) = NULL,
    @UserId                INT           = NULL,
    @Resultado             INT           OUTPUT,
    @Mensaje               NVARCHAR(500) OUTPUT,
    @AlbaranId             INT           OUTPUT,
    @Numero                NVARCHAR(40)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    IF @CompanyId IS NULL OR @CompanyId <= 0
    BEGIN SET @Mensaje = 'CompanyId requerido'; RETURN; END

    IF @Tipo NOT IN ('DESPACHO','RECEPCION','TRASLADO')
    BEGIN SET @Mensaje = 'Tipo inválido: ' + ISNULL(@Tipo,'NULL'); RETURN; END

    DECLARE @Prefix NVARCHAR(10) =
        CASE @Tipo WHEN 'DESPACHO' THEN 'ALB-D-' WHEN 'RECEPCION' THEN 'ALB-R-' ELSE 'ALB-T-' END
        + FORMAT(GETUTCDATE(), 'yyyyMM') + '-';

    DECLARE @Seq BIGINT;
    SELECT @Seq = ISNULL(MAX(CAST(SUBSTRING(Numero, LEN(@Prefix)+1, 5) AS INT)), 0) + 1
    FROM inv.Albaran
    WHERE CompanyId = @CompanyId AND Numero LIKE @Prefix + '%';

    SET @Numero = @Prefix + RIGHT('00000' + CAST(@Seq AS NVARCHAR(5)), 5);

    INSERT INTO inv.Albaran
        (CompanyId, Numero, Tipo, Estado, FechaEmision,
         WarehouseFrom, WarehouseTo, DestinatarioNombre, DestinatarioRif,
         SourceDocumentType, SourceDocumentId, Observaciones, CreatedByUserId)
    VALUES
        (@CompanyId, @Numero, @Tipo, 'BORRADOR', GETUTCDATE(),
         @WarehouseFrom, @WarehouseTo, @DestinatarioNombre, @DestinatarioRif,
         @SourceType, @SourceId, @Observaciones, @UserId);

    SET @AlbaranId = SCOPE_IDENTITY();
    SET @Resultado = 1;
    SET @Mensaje = 'Albarán creado';
END;
GO
