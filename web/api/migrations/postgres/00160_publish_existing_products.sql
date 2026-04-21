-- +goose Up
-- Fix: productos del seed/catálogo anterior no visibles en storefront.
--
-- Contexto: migración 00148 añadió columna "IsPublishedStore" con DEFAULT false.
-- El seed y productos pre-existentes quedaron con IsPublishedStore = false.
-- La vista store."UnifiedProduct" (00158) requiere IsPublishedStore = true para
-- incluir un producto. Resultado: productos activos no aparecían en la tienda.
--
-- Solución: marcar como publicados todos los productos que estaban activos
-- y no eliminados antes de la columna. No afecta productos creados después
-- (ya usan usp_store_admin_product_upsert que acepta el flag explícitamente).

UPDATE master."Product"
   SET "IsPublishedStore" = true,
       "PublishedAt"      = COALESCE("PublishedAt", NOW())
 WHERE "IsDeleted"        = false
   AND "IsActive"         = true
   AND "IsPublishedStore" = false;

-- +goose Down
-- No revertimos: volver a ocultar todos los productos sería destructivo.
-- Si se necesita revertir manualmente, usar usp_store_admin_product_toggle_publish.
