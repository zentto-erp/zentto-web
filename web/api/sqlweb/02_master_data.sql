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

  IF OBJECT_ID('[master].Customer', 'U') IS NULL
  BEGIN
    CREATE TABLE [master].Customer(
      CustomerId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId            INT NOT NULL,
      CustomerCode         NVARCHAR(24) NOT NULL,
      CustomerName         NVARCHAR(200) NOT NULL,
      FiscalId             NVARCHAR(30) NULL,
      Email                NVARCHAR(150) NULL,
      Phone                NVARCHAR(40) NULL,
      AddressLine          NVARCHAR(250) NULL,
      CreditLimit          DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Customer_CreditLimit DEFAULT(0),
      TotalBalance         DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Customer_TotalBalance DEFAULT(0),
      IsActive             BIT NOT NULL CONSTRAINT DF_master_Customer_IsActive DEFAULT(1),
      CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Customer_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Customer_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId      INT NULL,
      UpdatedByUserId      INT NULL,
      IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Customer_IsDeleted DEFAULT(0),
      DeletedAt            DATETIME2(0) NULL,
      DeletedByUserId      INT NULL,
      RowVer               ROWVERSION NOT NULL,
      CONSTRAINT UQ_master_Customer UNIQUE (CompanyId, CustomerCode),
      CONSTRAINT FK_master_Customer_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_master_Customer_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_master_Customer_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('[master].Supplier', 'U') IS NULL
  BEGIN
    CREATE TABLE [master].Supplier(
      SupplierId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId            INT NOT NULL,
      SupplierCode         NVARCHAR(24) NOT NULL,
      SupplierName         NVARCHAR(200) NOT NULL,
      FiscalId             NVARCHAR(30) NULL,
      Email                NVARCHAR(150) NULL,
      Phone                NVARCHAR(40) NULL,
      AddressLine          NVARCHAR(250) NULL,
      CreditLimit          DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Supplier_CreditLimit DEFAULT(0),
      TotalBalance         DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Supplier_TotalBalance DEFAULT(0),
      IsActive             BIT NOT NULL CONSTRAINT DF_master_Supplier_IsActive DEFAULT(1),
      CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Supplier_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Supplier_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId      INT NULL,
      UpdatedByUserId      INT NULL,
      IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Supplier_IsDeleted DEFAULT(0),
      DeletedAt            DATETIME2(0) NULL,
      DeletedByUserId      INT NULL,
      RowVer               ROWVERSION NOT NULL,
      CONSTRAINT UQ_master_Supplier UNIQUE (CompanyId, SupplierCode),
      CONSTRAINT FK_master_Supplier_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_master_Supplier_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_master_Supplier_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('[master].Employee', 'U') IS NULL
  BEGIN
    CREATE TABLE [master].Employee(
      EmployeeId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId            INT NOT NULL,
      EmployeeCode         NVARCHAR(24) NOT NULL,
      EmployeeName         NVARCHAR(200) NOT NULL,
      FiscalId             NVARCHAR(30) NULL,
      HireDate             DATE NULL,
      TerminationDate      DATE NULL,
      IsActive             BIT NOT NULL CONSTRAINT DF_master_Employee_IsActive DEFAULT(1),
      CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Employee_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Employee_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId      INT NULL,
      UpdatedByUserId      INT NULL,
      IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Employee_IsDeleted DEFAULT(0),
      DeletedAt            DATETIME2(0) NULL,
      DeletedByUserId      INT NULL,
      RowVer               ROWVERSION NOT NULL,
      CONSTRAINT UQ_master_Employee UNIQUE (CompanyId, EmployeeCode),
      CONSTRAINT FK_master_Employee_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_master_Employee_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_master_Employee_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );
  END;

  IF OBJECT_ID('[master].Product', 'U') IS NULL
  BEGIN
    CREATE TABLE [master].Product(
      ProductId            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId            INT NOT NULL,
      ProductCode          NVARCHAR(80) NOT NULL,
      ProductName          NVARCHAR(250) NOT NULL,
      CategoryCode         NVARCHAR(50) NULL,
      UnitCode             NVARCHAR(20) NULL,
      SalesPrice           DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Product_SalesPrice DEFAULT(0),
      CostPrice            DECIMAL(18,2) NOT NULL CONSTRAINT DF_master_Product_CostPrice DEFAULT(0),
      DefaultTaxCode       NVARCHAR(30) NULL,
      DefaultTaxRate       DECIMAL(9,4) NOT NULL CONSTRAINT DF_master_Product_DefaultTaxRate DEFAULT(0),
      StockQty             DECIMAL(18,3) NOT NULL CONSTRAINT DF_master_Product_StockQty DEFAULT(0),
      IsService            BIT NOT NULL CONSTRAINT DF_master_Product_IsService DEFAULT(0),
      IsActive             BIT NOT NULL CONSTRAINT DF_master_Product_IsActive DEFAULT(1),
      CreatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Product_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt            DATETIME2(0) NOT NULL CONSTRAINT DF_master_Product_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId      INT NULL,
      UpdatedByUserId      INT NULL,
      IsDeleted            BIT NOT NULL CONSTRAINT DF_master_Product_IsDeleted DEFAULT(0),
      DeletedAt            DATETIME2(0) NULL,
      DeletedByUserId      INT NULL,
      RowVer               ROWVERSION NOT NULL,
      CONSTRAINT UQ_master_Product UNIQUE (CompanyId, ProductCode),
      CONSTRAINT FK_master_Product_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_master_Product_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_master_Product_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_master_Product_Company_IsActive
      ON [master].Product (CompanyId, IsActive, ProductCode);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 02_master_data.sql: %s',16,1,@Err);
END CATCH;
GO
