-- Add Descripcion column to master.Product (SQL Server)
-- Matches PostgreSQL migration 00006_product_datqbox_columns.sql
IF COL_LENGTH('master.Product', 'Descripcion') IS NULL
    ALTER TABLE [master].[Product] ADD Descripcion NVARCHAR(MAX) NULL;
GO
