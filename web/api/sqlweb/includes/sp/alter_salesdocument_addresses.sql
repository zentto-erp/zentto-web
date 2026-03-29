-- =============================================================================
-- ALTER: Agregar ShippingAddressId y BillingAddressId a ar.SalesDocument
-- Nota: doc.SalesDocument es una VISTA sobre ar.SalesDocument.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('ar.SalesDocument') AND name='ShippingAddressId')
BEGIN
    ALTER TABLE ar.SalesDocument ADD ShippingAddressId INT NULL;
    ALTER TABLE ar.SalesDocument ADD BillingAddressId INT NULL;
    ALTER TABLE ar.SalesDocument ADD ShippingAddress NVARCHAR(500) NULL;
    ALTER TABLE ar.SalesDocument ADD BillingAddress NVARCHAR(500) NULL;
END;
GO
