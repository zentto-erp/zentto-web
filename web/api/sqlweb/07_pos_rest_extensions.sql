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

  IF OBJECT_ID('pos.FiscalCorrelative', 'U') IS NULL
  BEGIN
    CREATE TABLE pos.FiscalCorrelative(
      FiscalCorrelativeId     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId               INT NOT NULL,
      BranchId                INT NOT NULL,
      CorrelativeType         NVARCHAR(20) NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_Type DEFAULT(N'FACTURA'),
      CashRegisterCode        NVARCHAR(10) NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_Cash DEFAULT(N'GLOBAL'),
      SerialFiscal            NVARCHAR(40) NOT NULL,
      CurrentNumber           INT NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_Current DEFAULT(0),
      Description             NVARCHAR(200) NULL,
      IsActive                BIT NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_Active DEFAULT(1),
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_pos_FiscalCorrelative_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId         INT NULL,
      UpdatedByUserId         INT NULL,
      RowVer                  ROWVERSION NOT NULL,
      CONSTRAINT UQ_pos_FiscalCorrelative UNIQUE (CompanyId, BranchId, CorrelativeType, CashRegisterCode),
      CONSTRAINT FK_pos_FiscalCorrelative_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_pos_FiscalCorrelative_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_pos_FiscalCorrelative_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_pos_FiscalCorrelative_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_pos_FiscalCorrelative_Search
      ON pos.FiscalCorrelative (CompanyId, BranchId, CorrelativeType, CashRegisterCode, IsActive);
  END;

  IF OBJECT_ID('rest.DiningTable', 'U') IS NULL
  BEGIN
    CREATE TABLE rest.DiningTable(
      DiningTableId           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CompanyId               INT NOT NULL,
      BranchId                INT NOT NULL,
      TableNumber             NVARCHAR(20) NOT NULL,
      TableName               NVARCHAR(100) NULL,
      Capacity                INT NOT NULL CONSTRAINT DF_rest_DiningTable_Capacity DEFAULT(4),
      EnvironmentCode         NVARCHAR(20) NULL,
      EnvironmentName         NVARCHAR(80) NULL,
      PositionX               INT NULL,
      PositionY               INT NULL,
      IsActive                BIT NOT NULL CONSTRAINT DF_rest_DiningTable_Active DEFAULT(1),
      CreatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_DiningTable_CreatedAt DEFAULT(SYSUTCDATETIME()),
      UpdatedAt               DATETIME2(0) NOT NULL CONSTRAINT DF_rest_DiningTable_UpdatedAt DEFAULT(SYSUTCDATETIME()),
      CreatedByUserId         INT NULL,
      UpdatedByUserId         INT NULL,
      RowVer                  ROWVERSION NOT NULL,
      CONSTRAINT UQ_rest_DiningTable UNIQUE (CompanyId, BranchId, TableNumber),
      CONSTRAINT FK_rest_DiningTable_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_rest_DiningTable_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
      CONSTRAINT FK_rest_DiningTable_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES sec.[User](UserId),
      CONSTRAINT FK_rest_DiningTable_UpdatedBy FOREIGN KEY (UpdatedByUserId) REFERENCES sec.[User](UserId)
    );

    CREATE INDEX IX_rest_DiningTable_Search
      ON rest.DiningTable (CompanyId, BranchId, IsActive, EnvironmentCode, TableNumber);
  END;

  DECLARE @DefaultCompanyId INT = (SELECT TOP 1 CompanyId FROM cfg.Company WHERE CompanyCode = N'DEFAULT');
  DECLARE @DefaultBranchId INT = (
    SELECT TOP 1 BranchId
    FROM cfg.Branch
    WHERE CompanyId = @DefaultCompanyId
      AND BranchCode = N'MAIN'
  );
  DECLARE @SystemUserId INT = (SELECT TOP 1 UserId FROM sec.[User] WHERE UserCode = N'SYSTEM');

  IF @DefaultCompanyId IS NOT NULL AND @DefaultBranchId IS NOT NULL
  BEGIN
    IF NOT EXISTS (
      SELECT 1
      FROM pos.FiscalCorrelative
      WHERE CompanyId = @DefaultCompanyId
        AND BranchId = @DefaultBranchId
        AND CorrelativeType = N'FACTURA'
        AND CashRegisterCode = N'GLOBAL'
    )
    BEGIN
      INSERT INTO pos.FiscalCorrelative (
        CompanyId,
        BranchId,
        CorrelativeType,
        CashRegisterCode,
        SerialFiscal,
        CurrentNumber,
        Description,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      VALUES (
        @DefaultCompanyId,
        @DefaultBranchId,
        N'FACTURA',
        N'GLOBAL',
        N'SERIAL-DEMO',
        0,
        N'Correlativo fiscal global por defecto',
        1,
        @SystemUserId,
        @SystemUserId
      );
    END;

    IF NOT EXISTS (
      SELECT 1
      FROM rest.DiningTable
      WHERE CompanyId = @DefaultCompanyId
        AND BranchId = @DefaultBranchId
    )
    BEGIN
      ;WITH N AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1 FROM N WHERE n < 20
      )
      INSERT INTO rest.DiningTable (
        CompanyId,
        BranchId,
        TableNumber,
        TableName,
        Capacity,
        EnvironmentCode,
        EnvironmentName,
        PositionX,
        PositionY,
        IsActive,
        CreatedByUserId,
        UpdatedByUserId
      )
      SELECT
        @DefaultCompanyId,
        @DefaultBranchId,
        CAST(n AS NVARCHAR(20)),
        N'Mesa ' + CAST(n AS NVARCHAR(20)),
        4,
        N'SALON',
        N'Salon Principal',
        ((n - 1) % 5) * 120,
        ((n - 1) / 5) * 120,
        1,
        @SystemUserId,
        @SystemUserId
      FROM N
      OPTION (MAXRECURSION 100);
    END;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 07_pos_rest_extensions.sql: %s',16,1,@Err);
END CATCH;
GO

