-- Paridad SQL Server de migración goose 00160_publish_existing_products.sql
-- Publica todos los productos activos pre-existentes en el storefront.

UPDATE mstr.Product
   SET IsPublishedStore = 1,
       PublishedAt      = COALESCE(PublishedAt, GETUTCDATE())
 WHERE IsDeleted        = 0
   AND IsActive         = 1
   AND IsPublishedStore = 0;
