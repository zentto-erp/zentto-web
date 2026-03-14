SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ar')
BEGIN
    EXEC(N'CREATE SCHEMA ar');
    PRINT N'Schema ar creado.';
END
ELSE
BEGIN
    PRINT N'Schema ar ya existe.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ap')
BEGIN
    EXEC(N'CREATE SCHEMA ap');
    PRINT N'Schema ap creado.';
END
ELSE
BEGIN
    PRINT N'Schema ap ya existe.';
END
GO

IF OBJECT_ID(N'ar.ReceivableDocument', N'U') IS NULL
BEGIN
    CREATE TABLE ar.ReceivableDocument (
        ReceivableDocumentId INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL REFERENCES cfg.Company(CompanyId),
        BranchId INT NOT NULL,
        CustomerId INT NOT NULL REFERENCES [master].Customer(CustomerId),
        DocumentType NVARCHAR(50) NOT NULL,
        DocumentNumber NVARCHAR(50) NOT NULL,
        IssueDate DATE NOT NULL,
        DueDate DATE NOT NULL,
        CurrencyCode NVARCHAR(3) NOT NULL DEFAULT 'USD',
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PendingAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PaidFlag BIT NOT NULL DEFAULT 0,
        Status NVARCHAR(50) NOT NULL DEFAULT 'PENDING',
        Notes NVARCHAR(MAX),
        IsDeleted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT,
        UpdatedByUserId INT
    );
    PRINT N'ar.ReceivableDocument creada.';
END
ELSE
BEGIN
    PRINT N'ar.ReceivableDocument ya existe.';
END
GO

IF OBJECT_ID(N'ar.ReceivableApplication', N'U') IS NULL
BEGIN
    CREATE TABLE ar.ReceivableApplication (
        ReceivableApplicationId INT IDENTITY(1,1) PRIMARY KEY,
        ReceivableDocumentId INT NOT NULL REFERENCES ar.ReceivableDocument(ReceivableDocumentId),
        PaymentMethod NVARCHAR(50) NOT NULL,
        AmountApplied DECIMAL(18,2) NOT NULL,
        ApplicationDate DATE NOT NULL,
        ReferenceNumber NVARCHAR(100),
        IsDeleted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT,
        UpdatedByUserId INT
    );
    PRINT N'ar.ReceivableApplication creada.';
END
ELSE
BEGIN
    PRINT N'ar.ReceivableApplication ya existe.';
END
GO

IF OBJECT_ID(N'ap.PayableDocument', N'U') IS NULL
BEGIN
    CREATE TABLE ap.PayableDocument (
        PayableDocumentId INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId INT NOT NULL REFERENCES cfg.Company(CompanyId),
        BranchId INT NOT NULL,
        SupplierId INT NOT NULL REFERENCES [master].Supplier(SupplierId),
        DocumentType NVARCHAR(50) NOT NULL,
        DocumentNumber NVARCHAR(50) NOT NULL,
        IssueDate DATE NOT NULL,
        DueDate DATE NOT NULL,
        CurrencyCode NVARCHAR(3) NOT NULL DEFAULT 'USD',
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PendingAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        PaidFlag BIT NOT NULL DEFAULT 0,
        Status NVARCHAR(50) NOT NULL DEFAULT 'PENDING',
        Notes NVARCHAR(MAX),
        IsDeleted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT,
        UpdatedByUserId INT
    );
    PRINT N'ap.PayableDocument creada.';
END
ELSE
BEGIN
    PRINT N'ap.PayableDocument ya existe.';
END
GO

IF OBJECT_ID(N'ap.PayableApplication', N'U') IS NULL
BEGIN
    CREATE TABLE ap.PayableApplication (
        PayableApplicationId INT IDENTITY(1,1) PRIMARY KEY,
        PayableDocumentId INT NOT NULL REFERENCES ap.PayableDocument(PayableDocumentId),
        PaymentMethod NVARCHAR(50) NOT NULL,
        AmountApplied DECIMAL(18,2) NOT NULL,
        ApplicationDate DATE NOT NULL,
        ReferenceNumber NVARCHAR(100),
        IsDeleted BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId INT,
        UpdatedByUserId INT
    );
    PRINT N'ap.PayableApplication creada.';
END
ELSE
BEGIN
    PRINT N'ap.PayableApplication ya existe.';
END
GO
