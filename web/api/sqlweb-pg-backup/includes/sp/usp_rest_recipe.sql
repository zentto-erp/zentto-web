-- ============================================================================
--  usp_Rest_Recipe_GetIngredients
--  Obtiene ingredientes de receta para un producto del menu (RestauranteRecetas).
--  Busca por ProductCode del producto maestro vinculado al plato del restaurante.
-- ============================================================================
DROP FUNCTION IF EXISTS usp_rest_recipe_getingredients(VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_rest_recipe_getingredients(
  p_product_code VARCHAR(60)
)
RETURNS TABLE (
  "InventarioId" VARCHAR(15),
  "Cantidad"     NUMERIC(10,3)
)
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'RestauranteRecetas') THEN
    RETURN QUERY
    SELECT
      r."InventarioId",
      r."Cantidad"
    FROM "RestauranteRecetas" r
    INNER JOIN "RestauranteProductos" p ON p."Id" = r."ProductoId"
    WHERE p."Codigo" = p_product_code;
  END IF;
END;
$$;
