SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @DefaultBranchId INT = (
    SELECT TOP 1 BranchId
    FROM cfg.Branch
    WHERE CompanyId = @DefaultCompanyId AND BranchCode = N'MAIN'
  );

  IF @DefaultCompanyId IS NULL OR @DefaultBranchId IS NULL
    RAISERROR('Missing DEFAULT company/MAIN branch.',16,1);

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.FiscalCountryConfig
    WHERE EmpresaId = @DefaultCompanyId
      AND SucursalId = @DefaultBranchId
      AND CountryCode = 'VE'
  )
  BEGIN
    INSERT INTO dbo.FiscalCountryConfig (
      EmpresaId, SucursalId, CountryCode, Currency, TaxRegime, DefaultTaxCode, DefaultTaxRate,
      FiscalPrinterEnabled, VerifactuEnabled, VerifactuMode, SenderRIF, PosEnabled, RestaurantEnabled, IsActive
    )
    VALUES (
      @DefaultCompanyId, @DefaultBranchId, 'VE', 'VES', N'GENERAL', N'IVA_GENERAL', 0.1600,
      1, 0, N'manual', N'J-00000000-0', 1, 1, 1
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.FiscalCountryConfig
    WHERE EmpresaId = @DefaultCompanyId
      AND SucursalId = @DefaultBranchId
      AND CountryCode = 'ES'
  )
  BEGIN
    INSERT INTO dbo.FiscalCountryConfig (
      EmpresaId, SucursalId, CountryCode, Currency, TaxRegime, DefaultTaxCode, DefaultTaxRate,
      FiscalPrinterEnabled, VerifactuEnabled, VerifactuMode, AEATEndpoint, SenderNIF,
      PosEnabled, RestaurantEnabled, IsActive
    )
    VALUES (
      @DefaultCompanyId, @DefaultBranchId, 'ES', 'EUR', N'GENERAL', N'IVA_REDUCIDO', 0.1000,
      0, 1, N'manual',
      N'https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/RegistroFacturacion',
      N'B12345678',
      1, 1, 1
    );
  END;

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_GENERAL', N'IVA General', 0.1600, 1, 1, 1, 10);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_REDUCIDO', N'IVA Reducido', 0.0800, 1, 1, 0, 20);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'IVA_ADICIONAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'IVA_ADICIONAL', N'IVA Adicional', 0.3100, 1, 0, 0, 30);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'VE' AND Code = 'EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('VE', 'EXENTO', N'Exento', 0.0000, 1, 1, 0, 40);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_GENERAL', N'IVA General', 0.2100, 1, 0, 1, 10);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_REDUCIDO', N'IVA Reducido', 0.1000, 1, 1, 0, 20);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'IVA_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'IVA_SUPERREDUCIDO', N'IVA Superreducido', 0.0400, 1, 0, 0, 30);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'EXENTO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'EXENTO', N'Exento', 0.0000, 1, 1, 0, 40);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_GENERAL')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_GENERAL', N'Recargo Equivalencia General', 0.0520, 0.0520, 1, 0, 0, 50);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_REDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_REDUCIDO', N'Recargo Equivalencia Reducido', 0.0140, 0.0140, 1, 0, 0, 60);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalTaxRates WHERE CountryCode = 'ES' AND Code = 'RE_SUPERREDUCIDO')
    INSERT INTO dbo.FiscalTaxRates (CountryCode, Code, Name, Rate, SurchargeRate, AppliesToPOS, AppliesToRestaurant, IsDefault, SortOrder)
    VALUES ('ES', 'RE_SUPERREDUCIDO', N'Recargo Equivalencia Superreducido', 0.0050, 0.0050, 0, 0, 0, 70);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'FACTURA')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'FACTURA', N'Factura Fiscal', 0, 1, 1, 10);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'NOTA_CREDITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'NOTA_CREDITO', N'Nota de Credito Fiscal', 1, 1, 1, 20);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'NOTA_DEBITO')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'NOTA_DEBITO', N'Nota de Debito Fiscal', 0, 1, 1, 30);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'VE' AND Code = 'NOTA_ENTREGA')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, RequiresFiscalPrinter, SortOrder)
    VALUES ('VE', 'NOTA_ENTREGA', N'Nota de Entrega', 0, 0, 0, 40);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F1', N'Factura Completa', 0, 1, NULL, 0, 10);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F2', N'Factura Simplificada', 0, 0, 400.00, 0, 20);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'F3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'F3', N'Factura Sustitucion Simplificada', 0, 1, NULL, 0, 30);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R1')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R1', N'Rectificativa R1', 1, 1, NULL, 0, 40);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R2')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R2', N'Rectificativa R2', 1, 1, NULL, 0, 50);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R3')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R3', N'Rectificativa R3', 1, 1, NULL, 0, 60);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R4')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R4', N'Rectificativa R4', 1, 1, NULL, 0, 70);

  IF NOT EXISTS (SELECT 1 FROM dbo.FiscalInvoiceTypes WHERE CountryCode = 'ES' AND Code = 'R5')
    INSERT INTO dbo.FiscalInvoiceTypes (CountryCode, Code, Name, IsRectificative, RequiresRecipientId, MaxAmount, RequiresFiscalPrinter, SortOrder)
    VALUES ('ES', 'R5', N'Rectificativa R5', 1, 0, NULL, 0, 80);

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 06_seed_reference_data.sql: %s',16,1,@Err);
END CATCH;
GO
