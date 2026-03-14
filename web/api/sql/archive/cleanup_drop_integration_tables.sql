-- =============================================
-- PASO 1: Eliminar tablas de integración (inglés)
-- Creadas por integración e-commerce (NopCommerce u otro). No son parte del sistema DatqBox.
-- Ejecutar sobre backup o con precaución. Requiere permisos DDL.
-- =============================================

SET NOCOUNT ON;

-- Tablas a eliminar (nombres en inglés / integración)
DECLARE @DropTables TABLE (Nombre NVARCHAR(128) PRIMARY KEY);
INSERT INTO @DropTables (Nombre) VALUES
 (N'ActivityLog'),(N'ActivityLogType'),(N'Address'),(N'Affiliate'),(N'BackInStockSubscription'),
 (N'BlogComment'),(N'BlogPost'),(N'Campaign'),(N'Category'),(N'CategoryTemplate'),
 (N'CheckoutAttribute'),(N'CheckoutAttributeValue'),(N'Country'),(N'CrossSellProduct'),(N'Currency'),
 (N'Customer'),(N'Customer_CustomerRole_Mapping'),(N'CustomerAddresses'),(N'CustomerAttribute'),(N'CustomerContent'),(N'CustomerRole'),
 (N'Discount'),(N'Discount_AppliedToCategories'),(N'Discount_AppliedToProductVariants'),(N'DiscountRequirement'),(N'DiscountUsageHistory'),
 (N'Download'),(N'EdmMetadata'),(N'EmailAccount'),(N'ExternalAuthenticationRecord'),
 (N'Forums_Forum'),(N'Forums_Group'),(N'Forums_Post'),(N'Forums_PrivateMessage'),(N'Forums_Subscription'),(N'Forums_Topic'),
 (N'GiftCard'),(N'GiftCardUsageHistory'),(N'GoogleProduct'),(N'Language'),(N'LocaleStringResource'),(N'LocalizedProperty'),(N'Log'),
 (N'Manufacturer'),(N'ManufacturerTemplate'),(N'MeasureDimension'),(N'MeasureWeight'),(N'MessageTemplate'),
 (N'News'),(N'NewsComment'),(N'NewsLetterSubscription'), (N'Order'),(N'OrderNote'),(N'OrderProductVariant'),
 (N'PermissionRecord'),(N'PermissionRecord_Role_Mapping'),(N'Picture'),
 (N'Poll'),(N'PollAnswer'),(N'PollVotingRecord'),
 (N'Product'),(N'Product_Category_Mapping'),(N'Product_Manufacturer_Mapping'),(N'Product_Picture_Mapping'),
 (N'Product_ProductTag_Mapping'),(N'Product_SpecificationAttribute_Mapping'),
 (N'ProductAttribute'),(N'ProductReview'),(N'ProductReviewHelpfulness'),(N'ProductTag'),(N'ProductTemplate'),
 (N'ProductVariant'),(N'ProductVariant_ProductAttribute_Mapping'),(N'ProductVariantAttributeCombination'),(N'ProductVariantAttributeValue'),
 (N'QueuedEmail'),(N'RecurringPayment'),(N'RecurringPaymentHistory'),(N'RelatedProduct'),(N'ReturnRequest'),(N'RewardPointsHistory'),
 (N'ScheduleTask'),(N'Setting'),(N'ShippingByWeight'),(N'ShippingMethod'),(N'ShippingMethodRestrictions'),(N'ShoppingCartItem'),
 (N'SpecificationAttribute'),(N'SpecificationAttributeOption'),(N'StateProvince'),(N'TaxCategory'),(N'TaxRate'),(N'TierPrice'),(N'Topic'),(N'Widget');

-- 1) Eliminar FKs donde la tabla padre o la referenciada esté en @DropTables
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @fk SYSNAME, @sch SYSNAME, @tbl SYSNAME;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT fk.name, OBJECT_SCHEMA_NAME(fk.parent_object_id), OBJECT_NAME(fk.parent_object_id)
FROM sys.foreign_keys fk
WHERE (OBJECT_NAME(fk.referenced_object_id) IN (SELECT Nombre FROM @DropTables))
   OR (OBJECT_NAME(fk.parent_object_id) IN (SELECT Nombre FROM @DropTables));

OPEN cur;
FETCH NEXT FROM cur INTO @fk, @sch, @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'ALTER TABLE [' + @sch + N'].[' + @tbl + N'] DROP CONSTRAINT [' + @fk + N'];';
    BEGIN TRY
        EXEC sp_executesql @sql;
        PRINT N'Dropped FK: ' + @fk;
    END TRY
    BEGIN CATCH
        PRINT N'Error dropping ' + @fk + N': ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM cur INTO @fk, @sch, @tbl;
END
CLOSE cur;
DEALLOCATE cur;

-- 2) DROP TABLE para cada tabla de integración (solo si existe)
DECLARE @t NVARCHAR(128);
DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR SELECT Nombre FROM @DropTables;
OPEN cur2;
FETCH NEXT FROM cur2 INTO @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = @t AND schema_id = SCHEMA_ID('dbo'))
    BEGIN
        SET @sql = N'DROP TABLE [dbo].[' + @t + N'];';
        BEGIN TRY
            EXEC sp_executesql @sql;
            PRINT N'Dropped table: ' + @t;
        END TRY
        BEGIN CATCH
            PRINT N'Error dropping table ' + @t + N': ' + ERROR_MESSAGE();
        END CATCH
    END
    FETCH NEXT FROM cur2 INTO @t;
END
CLOSE cur2;
DEALLOCATE cur2;

PRINT N'Paso 1 completado. Ejecute cleanup_create_fk_datqbox.sql para integridad referencial.';
