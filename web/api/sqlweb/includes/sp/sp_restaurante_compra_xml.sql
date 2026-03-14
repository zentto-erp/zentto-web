-- SP Compra Restaurante con XML (compatible SQL Server 2012)
IF OBJECT_ID('usp_REST_Compra_Crear', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Compra_Crear;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE usp_REST_Compra_Crear
  @ProveedorId   NVARCHAR(12) = NULL,
  @Observaciones NVARCHAR(500) = NULL,
  @CodUsuario    NVARCHAR(10) = NULL,
  @DetalleXml    XML,  -- <items><item desc="" cant="" precio="" iva="" invId="" /></items>
  @CompraId      INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    DECLARE @NumCompra NVARCHAR(20);
    DECLARE @Seq INT = (SELECT ISNULL(MAX(Id), 0) + 1 FROM RestauranteCompras);
    SET @NumCompra = 'RC-' + REPLACE(CONVERT(NVARCHAR(7), GETDATE(), 120), '-', '') + '-' + RIGHT('0000' + CAST(@Seq AS NVARCHAR), 4);

    INSERT INTO RestauranteCompras (NumCompra, ProveedorId, Estado, Observaciones, CodUsuario)
    VALUES (@NumCompra, @ProveedorId, 'pendiente', @Observaciones, @CodUsuario);
    SET @CompraId = SCOPE_IDENTITY();

    INSERT INTO RestauranteComprasDetalle (CompraId, InventarioId, Descripcion, Cantidad, PrecioUnit, Subtotal, IVA)
    SELECT
      @CompraId,
      t.c.value('@invId', 'NVARCHAR(15)'),
      t.c.value('@desc', 'NVARCHAR(200)'),
      t.c.value('@cant', 'DECIMAL(10,3)'),
      t.c.value('@precio', 'DECIMAL(18,2)'),
      t.c.value('@cant', 'DECIMAL(10,3)') * t.c.value('@precio', 'DECIMAL(18,2)'),
      ISNULL(t.c.value('@iva', 'DECIMAL(5,2)'), 16)
    FROM @DetalleXml.nodes('/items/item') t(c);

    UPDATE RestauranteCompras SET
      Subtotal = (SELECT ISNULL(SUM(Subtotal), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
      IVA = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
      Total = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId)
    WHERE Id = @CompraId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

PRINT N'✅ SP usp_REST_Compra_Crear (XML) creado exitosamente.'
GO
