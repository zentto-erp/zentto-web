-- =============================================================================
-- ALTER: Agregar ShippingAddressId y BillingAddressId a ar.SalesDocument
-- Permite vincular ordenes ecommerce con direcciones del cliente.
-- Nota: doc.SalesDocument es una VISTA sobre ar.SalesDocument.
-- =============================================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='ar' AND table_name='SalesDocument' AND column_name='ShippingAddressId') THEN
        ALTER TABLE ar."SalesDocument" ADD COLUMN "ShippingAddressId" INT NULL;
        ALTER TABLE ar."SalesDocument" ADD COLUMN "BillingAddressId" INT NULL;
        ALTER TABLE ar."SalesDocument" ADD COLUMN "ShippingAddress" VARCHAR(500) NULL;
        ALTER TABLE ar."SalesDocument" ADD COLUMN "BillingAddress" VARCHAR(500) NULL;
    END IF;
END $$;
