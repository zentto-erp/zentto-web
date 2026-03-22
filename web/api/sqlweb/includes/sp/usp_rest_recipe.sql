-- ============================================================================
--  usp_Rest_Recipe_GetIngredients
--  Obtiene ingredientes de receta para un producto del menu (RestauranteRecetas).
--  Busca por ProductCode del producto maestro vinculado al plato del restaurante.
-- ============================================================================
IF OBJECT_ID('dbo.usp_Rest_Recipe_GetIngredients', 'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Rest_Recipe_GetIngredients;
GO

CREATE PROCEDURE dbo.usp_Rest_Recipe_GetIngredients
  @ProductCode NVARCHAR(60)
AS
BEGIN
  SET NOCOUNT ON;

  IF OBJECT_ID('dbo.RestauranteRecetas', 'U') IS NOT NULL
  BEGIN
    SELECT
      r.InventarioId,
      r.Cantidad
    FROM dbo.RestauranteRecetas r
    INNER JOIN dbo.RestauranteProductos p ON p.Id = r.ProductoId
    WHERE p.Codigo = @ProductCode;
  END
END
GO
