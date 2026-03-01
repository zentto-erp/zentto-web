USE BrokerDB;
GO

-- Expandiendo Properties para soportar información rica del Agregator
IF COL_LENGTH('Properties', 'address') IS NULL
BEGIN
    ALTER TABLE Properties ADD address NVARCHAR(300) NULL;
END
GO

IF COL_LENGTH('Properties', 'zip_code') IS NULL
BEGIN
    ALTER TABLE Properties ADD zip_code NVARCHAR(50) NULL;
END
GO

IF COL_LENGTH('Properties', 'phone') IS NULL
BEGIN
    ALTER TABLE Properties ADD phone NVARCHAR(50) NULL;
END
GO

IF COL_LENGTH('Properties', 'website') IS NULL
BEGIN
    ALTER TABLE Properties ADD website NVARCHAR(500) NULL;
END
GO

IF COL_LENGTH('Properties', 'external_rating') IS NULL
BEGIN
    ALTER TABLE Properties ADD external_rating DECIMAL(3,2) NULL;
END
GO

-- Reparando PropertyRates para incluir la columna de mínimo de noches que fallaba
IF COL_LENGTH('PropertyRates', 'min_nights') IS NULL
BEGIN
    ALTER TABLE PropertyRates ADD min_nights INT NOT NULL DEFAULT 1;
END
GO

PRINT 'Base de datos expandida correctamente para BrokerPlatform.';
GO
