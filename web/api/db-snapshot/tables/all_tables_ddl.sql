-- =============================================
-- TABLE: acct.Account
-- =============================================
CREATE TABLE [acct].[Account] (
    [AccountId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[AccountCode] NVARCHAR(40) NOT NULL
   ,[AccountName] NVARCHAR(200) NOT NULL
   ,[AccountType] NCHAR(1) NOT NULL
   ,[AccountLevel] INT NOT NULL DEFAULT ((1))
   ,[ParentAccountId] BIGINT NULL
   ,[AllowsPosting] BIT NOT NULL DEFAULT ((1))
   ,[RequiresAuxiliary] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Account__349DA5A6824F87AB] PRIMARY KEY CLUSTERED ([AccountId])
   ,CONSTRAINT [UQ_acct_Account] UNIQUE NONCLUSTERED ([CompanyId], [AccountCode])
   ,CONSTRAINT [CK_acct_Account_AccountType] CHECK ([AccountType]=N'G' OR [AccountType]=N'I' OR [AccountType]=N'C' OR [AccountType]=N'P' OR [AccountType]=N'A')
);
GO
ALTER TABLE [acct].[Account] ADD CONSTRAINT [FK_acct_Account_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [acct].[Account] ADD CONSTRAINT [FK_acct_Account_Parent] FOREIGN KEY ([ParentAccountId]) REFERENCES [acct].[Account] ([AccountId]);
GO
ALTER TABLE [acct].[Account] ADD CONSTRAINT [FK_acct_Account_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [acct].[Account] ADD CONSTRAINT [FK_acct_Account_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_acct_Account_Company_Parent] ON [acct].[Account] ([CompanyId] ASC, [ParentAccountId] ASC, [AccountCode] ASC);
GO
 
 
-- =============================================
-- TABLE: acct.AccountingPolicy
-- =============================================
CREATE TABLE [acct].[AccountingPolicy] (
    [AccountingPolicyId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[ModuleCode] NVARCHAR(20) NOT NULL
   ,[ProcessCode] NVARCHAR(40) NOT NULL
   ,[Nature] NVARCHAR(10) NOT NULL
   ,[AccountId] BIGINT NOT NULL
   ,[PriorityOrder] INT NOT NULL DEFAULT ((1))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Accounti__85BE4BEA4BE30D35] PRIMARY KEY CLUSTERED ([AccountingPolicyId])
   ,CONSTRAINT [UQ_acct_Policy] UNIQUE NONCLUSTERED ([CompanyId], [ModuleCode], [ProcessCode], [Nature], [AccountId])
   ,CONSTRAINT [CK_acct_Policy_Nature] CHECK ([Nature]='CREDIT' OR [Nature]='DEBIT')
);
GO
ALTER TABLE [acct].[AccountingPolicy] ADD CONSTRAINT [FK_acct_Policy_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [acct].[AccountingPolicy] ADD CONSTRAINT [FK_acct_Policy_Account] FOREIGN KEY ([AccountId]) REFERENCES [acct].[Account] ([AccountId]);
GO
 
 
-- =============================================
-- TABLE: acct.DocumentLink
-- =============================================
CREATE TABLE [acct].[DocumentLink] (
    [DocumentLinkId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[ModuleCode] NVARCHAR(20) NOT NULL
   ,[DocumentType] NVARCHAR(20) NOT NULL
   ,[DocumentNumber] NVARCHAR(120) NOT NULL
   ,[NativeDocumentId] BIGINT NULL
   ,[JournalEntryId] BIGINT NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Document__7862CD238992A98E] PRIMARY KEY CLUSTERED ([DocumentLinkId])
   ,CONSTRAINT [UQ_acct_DocLink] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [ModuleCode], [DocumentType], [DocumentNumber])
);
GO
ALTER TABLE [acct].[DocumentLink] ADD CONSTRAINT [FK_acct_DocLink_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [acct].[DocumentLink] ADD CONSTRAINT [FK_acct_DocLink_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [acct].[DocumentLink] ADD CONSTRAINT [FK_acct_DocLink_JE] FOREIGN KEY ([JournalEntryId]) REFERENCES [acct].[JournalEntry] ([JournalEntryId]);
GO
 
 
-- =============================================
-- TABLE: acct.JournalEntry
-- =============================================
CREATE TABLE [acct].[JournalEntry] (
    [JournalEntryId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[EntryNumber] NVARCHAR(40) NOT NULL
   ,[EntryDate] DATE NOT NULL
   ,[PeriodCode] NVARCHAR(7) NOT NULL
   ,[EntryType] NVARCHAR(20) NOT NULL
   ,[ReferenceNumber] NVARCHAR(120) NULL
   ,[Concept] NVARCHAR(400) NOT NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[ExchangeRate] DECIMAL(18,6) NOT NULL DEFAULT ((1))
   ,[TotalDebit] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalCredit] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT ('APPROVED')
   ,[SourceModule] NVARCHAR(40) NULL
   ,[SourceDocumentType] NVARCHAR(40) NULL
   ,[SourceDocumentNo] NVARCHAR(120) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__JournalE__575A70DB06D7BF98] PRIMARY KEY CLUSTERED ([JournalEntryId])
   ,CONSTRAINT [UQ_acct_JE] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [EntryNumber])
   ,CONSTRAINT [CK_acct_JE_Status] CHECK ([Status]='VOIDED' OR [Status]='APPROVED' OR [Status]='DRAFT')
);
GO
ALTER TABLE [acct].[JournalEntry] ADD CONSTRAINT [FK_acct_JE_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [acct].[JournalEntry] ADD CONSTRAINT [FK_acct_JE_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [acct].[JournalEntry] ADD CONSTRAINT [FK_acct_JE_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [acct].[JournalEntry] ADD CONSTRAINT [FK_acct_JE_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_acct_JE_Date] ON [acct].[JournalEntry] ([CompanyId] ASC, [BranchId] ASC, [EntryDate] ASC, [JournalEntryId] ASC);
GO
 
 
-- =============================================
-- TABLE: acct.JournalEntryLine
-- =============================================
CREATE TABLE [acct].[JournalEntryLine] (
    [JournalEntryLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[JournalEntryId] BIGINT NOT NULL
   ,[LineNumber] INT NOT NULL
   ,[AccountId] BIGINT NOT NULL
   ,[AccountCodeSnapshot] NVARCHAR(40) NOT NULL
   ,[Description] NVARCHAR(400) NULL
   ,[DebitAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[CreditAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[AuxiliaryType] NVARCHAR(20) NULL
   ,[AuxiliaryCode] NVARCHAR(80) NULL
   ,[CostCenterCode] NVARCHAR(20) NULL
   ,[SourceDocumentNo] NVARCHAR(120) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__JournalE__38207DB81DDF32A4] PRIMARY KEY CLUSTERED ([JournalEntryLineId])
   ,CONSTRAINT [UQ_acct_JEL] UNIQUE NONCLUSTERED ([JournalEntryId], [LineNumber])
   ,CONSTRAINT [CK_acct_JEL_DebitCredit] CHECK ([DebitAmount]>=(0) AND [CreditAmount]>=(0) AND NOT ([DebitAmount]>(0) AND [CreditAmount]>(0)))
);
GO
ALTER TABLE [acct].[JournalEntryLine] ADD CONSTRAINT [FK_acct_JEL_JE] FOREIGN KEY ([JournalEntryId]) REFERENCES [acct].[JournalEntry] ([JournalEntryId]);
GO
ALTER TABLE [acct].[JournalEntryLine] ADD CONSTRAINT [FK_acct_JEL_Account] FOREIGN KEY ([AccountId]) REFERENCES [acct].[Account] ([AccountId]);
GO
CREATE NONCLUSTERED INDEX [IX_acct_JEL_Account] ON [acct].[JournalEntryLine] ([AccountId] ASC, [JournalEntryId] ASC);
GO
 
 
-- =============================================
-- TABLE: ap.PayableApplication
-- =============================================
CREATE TABLE [ap].[PayableApplication] (
    [PayableApplicationId] BIGINT IDENTITY(1,1) NOT NULL
   ,[PayableDocumentId] BIGINT NOT NULL
   ,[ApplyDate] DATE NOT NULL
   ,[AppliedAmount] DECIMAL(18,2) NOT NULL
   ,[PaymentReference] NVARCHAR(120) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__PayableA__F4D271798B823F83] PRIMARY KEY CLUSTERED ([PayableApplicationId])
);
GO
ALTER TABLE [ap].[PayableApplication] ADD CONSTRAINT [FK_ap_PayApp_Doc] FOREIGN KEY ([PayableDocumentId]) REFERENCES [ap].[PayableDocument] ([PayableDocumentId]);
GO
 
 
-- =============================================
-- TABLE: ap.PayableDocument
-- =============================================
CREATE TABLE [ap].[PayableDocument] (
    [PayableDocumentId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[SupplierId] BIGINT NOT NULL
   ,[DocumentType] NVARCHAR(20) NOT NULL
   ,[DocumentNumber] NVARCHAR(120) NOT NULL
   ,[IssueDate] DATE NOT NULL
   ,[DueDate] DATE NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[PendingAmount] DECIMAL(18,2) NOT NULL
   ,[PaidFlag] BIT NOT NULL DEFAULT ((0))
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT ('PENDING')
   ,[Notes] NVARCHAR(500) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__PayableD__4FD224788A7858D3] PRIMARY KEY CLUSTERED ([PayableDocumentId])
   ,CONSTRAINT [UQ_ap_PayDoc] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [DocumentType], [DocumentNumber])
   ,CONSTRAINT [CK_ap_PayDoc_Status] CHECK ([Status]='VOIDED' OR [Status]='PAID' OR [Status]='PARTIAL' OR [Status]='PENDING')
);
GO
ALTER TABLE [ap].[PayableDocument] ADD CONSTRAINT [FK_ap_PayDoc_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [ap].[PayableDocument] ADD CONSTRAINT [FK_ap_PayDoc_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [ap].[PayableDocument] ADD CONSTRAINT [FK_ap_PayDoc_Supplier] FOREIGN KEY ([SupplierId]) REFERENCES [master].[Supplier] ([SupplierId]);
GO
ALTER TABLE [ap].[PayableDocument] ADD CONSTRAINT [FK_ap_PayDoc_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [ap].[PayableDocument] ADD CONSTRAINT [FK_ap_PayDoc_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: ap.PurchaseDocument
-- =============================================
CREATE TABLE [ap].[PurchaseDocument] (
    [DocumentId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[SerialType] NVARCHAR(60) NOT NULL DEFAULT (N'')
   ,[OperationType] NVARCHAR(20) NOT NULL DEFAULT (N'COMPRA')
   ,[SupplierCode] NVARCHAR(60) NULL
   ,[SupplierName] NVARCHAR(255) NULL
   ,[FiscalId] NVARCHAR(15) NULL
   ,[DocumentDate] DATETIME NULL DEFAULT (getdate())
   ,[DueDate] DATETIME NULL
   ,[ReceiptDate] DATETIME NULL
   ,[PaymentDate] DATETIME NULL
   ,[DocumentTime] NVARCHAR(20) NULL DEFAULT (CONVERT([nvarchar](8),getdate(),(108)))
   ,[SubTotal] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxableAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ExemptAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxRate] DECIMAL(8,4) NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ExemptTotalAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsVoided] BIT NULL DEFAULT ((0))
   ,[IsPaid] NVARCHAR(1) NULL DEFAULT (N'N')
   ,[IsReceived] NVARCHAR(1) NULL DEFAULT (N'N')
   ,[IsLegal] BIT NULL DEFAULT ((0))
   ,[OriginDocumentNumber] NVARCHAR(60) NULL
   ,[ControlNumber] NVARCHAR(60) NULL
   ,[VoucherNumber] NVARCHAR(50) NULL
   ,[VoucherDate] DATETIME NULL
   ,[RetainedTax] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsrCode] NVARCHAR(50) NULL
   ,[IsrAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsrSubjectAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[RetentionRate] DECIMAL(8,4) NULL DEFAULT ((0))
   ,[ImportAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ImportTax] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ImportBase] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[FreightAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[Concept] NVARCHAR(255) NULL
   ,[Notes] NVARCHAR(500) NULL
   ,[OrderNumber] NVARCHAR(20) NULL
   ,[ReceivedBy] NVARCHAR(20) NULL
   ,[WarehouseCode] NVARCHAR(50) NULL
   ,[CurrencyCode] NVARCHAR(20) NULL DEFAULT (N'BS')
   ,[ExchangeRate] DECIMAL(18,6) NULL DEFAULT ((1))
   ,[UsdAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[ShortUserCode] NVARCHAR(10) NULL
   ,[ReportDate] DATETIME NULL DEFAULT (getdate())
   ,[HostName] NVARCHAR(255) NULL DEFAULT (host_name())
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_PurchaseDocument] PRIMARY KEY CLUSTERED ([DocumentId])
   ,CONSTRAINT [UQ_PurchaseDocument_NumDocOp] UNIQUE NONCLUSTERED ([DocumentNumber], [OperationType])
);
GO
CREATE NONCLUSTERED INDEX [IX_PurchaseDocument_OpDate] ON [ap].[PurchaseDocument] ([OperationType] ASC, [DocumentDate] DESC) WHERE ([IsDeleted]=(0));
GO
CREATE NONCLUSTERED INDEX [IX_PurchaseDocument_Supplier] ON [ap].[PurchaseDocument] ([SupplierCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: ap.PurchaseDocumentLine
-- =============================================
CREATE TABLE [ap].[PurchaseDocumentLine] (
    [LineId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[OperationType] NVARCHAR(20) NOT NULL DEFAULT (N'COMPRA')
   ,[LineNumber] INT NULL DEFAULT ((0))
   ,[ProductCode] NVARCHAR(60) NULL
   ,[Description] NVARCHAR(255) NULL
   ,[Quantity] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[UnitPrice] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[UnitCost] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[SubTotal] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxRate] DECIMAL(8,4) NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsVoided] BIT NULL DEFAULT ((0))
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[LineDate] DATETIME NULL DEFAULT (getdate())
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_PurchaseDocumentLine] PRIMARY KEY CLUSTERED ([LineId])
);
GO
ALTER TABLE [ap].[PurchaseDocumentLine] ADD CONSTRAINT [FK_PurchDocLine_PurchDoc] FOREIGN KEY ([DocumentNumber], [OperationType]) REFERENCES [ap].[PurchaseDocument] ([DocumentNumber], [OperationType]);
GO
CREATE NONCLUSTERED INDEX [IX_PurchaseDocLine_DocNum] ON [ap].[PurchaseDocumentLine] ([DocumentNumber] ASC, [OperationType] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: ap.PurchaseDocumentPayment
-- =============================================
CREATE TABLE [ap].[PurchaseDocumentPayment] (
    [PaymentId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[OperationType] NVARCHAR(20) NOT NULL DEFAULT (N'COMPRA')
   ,[PaymentMethod] NVARCHAR(30) NULL
   ,[BankCode] NVARCHAR(60) NULL
   ,[PaymentNumber] NVARCHAR(60) NULL
   ,[Amount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[PaymentDate] DATETIME NULL DEFAULT (getdate())
   ,[DueDate] DATETIME NULL
   ,[ReferenceNumber] NVARCHAR(100) NULL
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_PurchaseDocumentPayment] PRIMARY KEY CLUSTERED ([PaymentId])
);
GO
ALTER TABLE [ap].[PurchaseDocumentPayment] ADD CONSTRAINT [FK_PurchDocPay_PurchDoc] FOREIGN KEY ([DocumentNumber], [OperationType]) REFERENCES [ap].[PurchaseDocument] ([DocumentNumber], [OperationType]);
GO
CREATE NONCLUSTERED INDEX [IX_PurchaseDocPayment_DocNum] ON [ap].[PurchaseDocumentPayment] ([DocumentNumber] ASC, [OperationType] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: ar.ReceivableApplication
-- =============================================
CREATE TABLE [ar].[ReceivableApplication] (
    [ReceivableApplicationId] BIGINT IDENTITY(1,1) NOT NULL
   ,[ReceivableDocumentId] BIGINT NOT NULL
   ,[ApplyDate] DATE NOT NULL
   ,[AppliedAmount] DECIMAL(18,2) NOT NULL
   ,[PaymentReference] NVARCHAR(120) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Receivab__AFC36A1FFC0983F4] PRIMARY KEY CLUSTERED ([ReceivableApplicationId])
);
GO
ALTER TABLE [ar].[ReceivableApplication] ADD CONSTRAINT [FK_ar_RecApp_Doc] FOREIGN KEY ([ReceivableDocumentId]) REFERENCES [ar].[ReceivableDocument] ([ReceivableDocumentId]);
GO
 
 
-- =============================================
-- TABLE: ar.ReceivableDocument
-- =============================================
CREATE TABLE [ar].[ReceivableDocument] (
    [ReceivableDocumentId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CustomerId] BIGINT NOT NULL
   ,[DocumentType] NVARCHAR(20) NOT NULL
   ,[DocumentNumber] NVARCHAR(120) NOT NULL
   ,[IssueDate] DATE NOT NULL
   ,[DueDate] DATE NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[PendingAmount] DECIMAL(18,2) NOT NULL
   ,[PaidFlag] BIT NOT NULL DEFAULT ((0))
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT ('PENDING')
   ,[Notes] NVARCHAR(500) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Receivab__EC7F1608955A64BE] PRIMARY KEY CLUSTERED ([ReceivableDocumentId])
   ,CONSTRAINT [UQ_ar_RecDoc] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [DocumentType], [DocumentNumber])
   ,CONSTRAINT [CK_ar_RecDoc_Status] CHECK ([Status]='VOIDED' OR [Status]='PAID' OR [Status]='PARTIAL' OR [Status]='PENDING')
);
GO
ALTER TABLE [ar].[ReceivableDocument] ADD CONSTRAINT [FK_ar_RecDoc_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [ar].[ReceivableDocument] ADD CONSTRAINT [FK_ar_RecDoc_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [ar].[ReceivableDocument] ADD CONSTRAINT [FK_ar_RecDoc_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [master].[Customer] ([CustomerId]);
GO
ALTER TABLE [ar].[ReceivableDocument] ADD CONSTRAINT [FK_ar_RecDoc_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [ar].[ReceivableDocument] ADD CONSTRAINT [FK_ar_RecDoc_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: ar.SalesDocument
-- =============================================
CREATE TABLE [ar].[SalesDocument] (
    [DocumentId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[SerialType] NVARCHAR(60) NOT NULL DEFAULT (N'')
   ,[OperationType] NVARCHAR(20) NOT NULL
   ,[CustomerCode] NVARCHAR(60) NULL
   ,[CustomerName] NVARCHAR(255) NULL
   ,[FiscalId] NVARCHAR(20) NULL
   ,[DocumentDate] DATETIME NULL DEFAULT (getdate())
   ,[DueDate] DATETIME NULL
   ,[DocumentTime] NVARCHAR(20) NULL DEFAULT (CONVERT([nvarchar](8),getdate(),(108)))
   ,[SubTotal] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxableAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ExemptAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxRate] DECIMAL(8,4) NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsVoided] BIT NULL DEFAULT ((0))
   ,[IsPaid] NVARCHAR(1) NULL DEFAULT (N'N')
   ,[IsInvoiced] NVARCHAR(1) NULL DEFAULT (N'N')
   ,[IsDelivered] NVARCHAR(1) NULL DEFAULT (N'N')
   ,[OriginDocumentNumber] NVARCHAR(60) NULL
   ,[OriginDocumentType] NVARCHAR(20) NULL
   ,[ControlNumber] NVARCHAR(60) NULL
   ,[IsLegal] BIT NULL DEFAULT ((0))
   ,[IsPrinted] BIT NULL DEFAULT ((0))
   ,[Notes] NVARCHAR(500) NULL
   ,[Concept] NVARCHAR(255) NULL
   ,[PaymentTerms] NVARCHAR(255) NULL
   ,[ShipToAddress] NVARCHAR(255) NULL
   ,[SellerCode] NVARCHAR(60) NULL
   ,[DepartmentCode] NVARCHAR(50) NULL
   ,[LocationCode] NVARCHAR(100) NULL
   ,[CurrencyCode] NVARCHAR(20) NULL DEFAULT (N'BS')
   ,[ExchangeRate] DECIMAL(18,6) NULL DEFAULT ((1))
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[ReportDate] DATETIME NULL DEFAULT (getdate())
   ,[HostName] NVARCHAR(255) NULL DEFAULT (host_name())
   ,[VehiclePlate] NVARCHAR(20) NULL
   ,[Mileage] INT NULL
   ,[TollAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_SalesDocument] PRIMARY KEY CLUSTERED ([DocumentId])
   ,CONSTRAINT [UQ_SalesDocument_NumDocOp] UNIQUE NONCLUSTERED ([DocumentNumber], [OperationType])
);
GO
CREATE NONCLUSTERED INDEX [IX_SalesDocument_OpDate] ON [ar].[SalesDocument] ([OperationType] ASC, [DocumentDate] DESC) WHERE ([IsDeleted]=(0));
GO
CREATE NONCLUSTERED INDEX [IX_SalesDocument_Customer] ON [ar].[SalesDocument] ([CustomerCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: ar.SalesDocumentLine
-- =============================================
CREATE TABLE [ar].[SalesDocumentLine] (
    [LineId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[OperationType] NVARCHAR(20) NOT NULL
   ,[LineNumber] INT NULL DEFAULT ((0))
   ,[ProductCode] NVARCHAR(60) NULL
   ,[Description] NVARCHAR(255) NULL
   ,[AlternateCode] NVARCHAR(60) NULL
   ,[Quantity] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[UnitPrice] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[DiscountedPrice] DECIMAL(18,4) NULL
   ,[UnitCost] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[SubTotal] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[TaxRate] DECIMAL(8,4) NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[IsVoided] BIT NULL DEFAULT ((0))
   ,[RelatedRef] NVARCHAR(10) NULL DEFAULT (N'0')
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[LineDate] DATETIME NULL DEFAULT (getdate())
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_SalesDocumentLine] PRIMARY KEY CLUSTERED ([LineId])
);
GO
ALTER TABLE [ar].[SalesDocumentLine] ADD CONSTRAINT [FK_SalesDocLine_SalesDoc] FOREIGN KEY ([DocumentNumber], [OperationType]) REFERENCES [ar].[SalesDocument] ([DocumentNumber], [OperationType]);
GO
CREATE NONCLUSTERED INDEX [IX_SalesDocLine_DocNum] ON [ar].[SalesDocumentLine] ([DocumentNumber] ASC, [OperationType] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: ar.SalesDocumentPayment
-- =============================================
CREATE TABLE [ar].[SalesDocumentPayment] (
    [PaymentId] INT IDENTITY(1,1) NOT NULL
   ,[DocumentNumber] NVARCHAR(60) NOT NULL
   ,[OperationType] NVARCHAR(20) NOT NULL DEFAULT (N'FACT')
   ,[PaymentMethod] NVARCHAR(30) NULL
   ,[BankCode] NVARCHAR(60) NULL
   ,[PaymentNumber] NVARCHAR(60) NULL
   ,[Amount] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[AmountBs] DECIMAL(18,4) NULL DEFAULT ((0))
   ,[ExchangeRate] DECIMAL(18,6) NULL DEFAULT ((1))
   ,[PaymentDate] DATETIME NULL DEFAULT (getdate())
   ,[DueDate] DATETIME NULL
   ,[ReferenceNumber] NVARCHAR(100) NULL
   ,[UserCode] NVARCHAR(60) NULL DEFAULT (N'API')
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK_SalesDocumentPayment] PRIMARY KEY CLUSTERED ([PaymentId])
);
GO
ALTER TABLE [ar].[SalesDocumentPayment] ADD CONSTRAINT [FK_SalesDocPay_SalesDoc] FOREIGN KEY ([DocumentNumber], [OperationType]) REFERENCES [ar].[SalesDocument] ([DocumentNumber], [OperationType]);
GO
CREATE NONCLUSTERED INDEX [IX_SalesDocPayment_DocNum] ON [ar].[SalesDocumentPayment] ([DocumentNumber] ASC, [OperationType] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: cfg.AppSetting
-- =============================================
CREATE TABLE [cfg].[AppSetting] (
    [SettingId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[Module] NVARCHAR(60) NOT NULL
   ,[SettingKey] NVARCHAR(120) NOT NULL
   ,[SettingValue] NVARCHAR(MAX) NOT NULL DEFAULT ('')
   ,[ValueType] NVARCHAR(20) NOT NULL DEFAULT ('string')
   ,[Description] NVARCHAR(500) NULL
   ,[IsReadOnly] BIT NOT NULL DEFAULT ((0))
   ,[UpdatedAt] DATETIME2(7) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK__AppSetti__54372B1DBDA8666E] PRIMARY KEY CLUSTERED ([SettingId])
   ,CONSTRAINT [UQ_AppSetting_Company_Module_Key] UNIQUE NONCLUSTERED ([CompanyId], [Module], [SettingKey])
);
GO
 
 
-- =============================================
-- TABLE: cfg.Branch
-- =============================================
CREATE TABLE [cfg].[Branch] (
    [BranchId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchCode] NVARCHAR(20) NOT NULL
   ,[BranchName] NVARCHAR(150) NOT NULL
   ,[AddressLine] NVARCHAR(250) NULL
   ,[Phone] NVARCHAR(40) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,[CountryCode] CHAR(2) NULL
   ,CONSTRAINT [PK__Branch__A1682FC58A930AEE] PRIMARY KEY CLUSTERED ([BranchId])
   ,CONSTRAINT [UQ_cfg_Branch] UNIQUE NONCLUSTERED ([CompanyId], [BranchCode])
);
GO
ALTER TABLE [cfg].[Branch] ADD CONSTRAINT [FK_cfg_Branch_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [cfg].[Branch] ADD CONSTRAINT [FK_cfg_Branch_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [cfg].[Branch] ADD CONSTRAINT [FK_cfg_Branch_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [cfg].[Branch] ADD CONSTRAINT [FK_cfg_Branch_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
CREATE NONCLUSTERED INDEX [IX_cfg_Branch_CountryCode] ON [cfg].[Branch] ([CountryCode] ASC);
GO
 
 
-- =============================================
-- TABLE: cfg.Company
-- =============================================
CREATE TABLE [cfg].[Company] (
    [CompanyId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyCode] NVARCHAR(20) NOT NULL
   ,[LegalName] NVARCHAR(200) NOT NULL
   ,[TradeName] NVARCHAR(200) NULL
   ,[FiscalCountryCode] CHAR(2) NOT NULL
   ,[FiscalId] NVARCHAR(30) NULL
   ,[BaseCurrency] CHAR(3) NOT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Company__2D971CAC15398BC8] PRIMARY KEY CLUSTERED ([CompanyId])
   ,CONSTRAINT [UQ_cfg_Company_CompanyCode] UNIQUE NONCLUSTERED ([CompanyCode])
);
GO
ALTER TABLE [cfg].[Company] ADD CONSTRAINT [FK_cfg_Company_Country] FOREIGN KEY ([FiscalCountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [cfg].[Company] ADD CONSTRAINT [FK_cfg_Company_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [cfg].[Company] ADD CONSTRAINT [FK_cfg_Company_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: cfg.CompanyProfile
-- =============================================
CREATE TABLE [cfg].[CompanyProfile] (
    [ProfileId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[Phone] NVARCHAR(60) NULL
   ,[AddressLine] NVARCHAR(250) NULL
   ,[NitCode] NVARCHAR(50) NULL
   ,[AltFiscalId] NVARCHAR(50) NULL
   ,[WebSite] NVARCHAR(150) NULL
   ,[LogoBase64] NVARCHAR(MAX) NULL
   ,[Notes] NVARCHAR(500) NULL
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_CompanyProfile] PRIMARY KEY CLUSTERED ([ProfileId])
);
GO
ALTER TABLE [cfg].[CompanyProfile] ADD CONSTRAINT [FK_CompanyProfile_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_CompanyProfile_CompanyId] ON [cfg].[CompanyProfile] ([CompanyId] ASC);
GO
 
 
-- =============================================
-- TABLE: cfg.Country
-- =============================================
CREATE TABLE [cfg].[Country] (
    [CountryCode] CHAR(2) NOT NULL
   ,[CountryName] NVARCHAR(80) NOT NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[TaxAuthorityCode] NVARCHAR(20) NOT NULL
   ,[FiscalIdName] NVARCHAR(20) NOT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[TimeZoneIana] NVARCHAR(64) NULL
   ,CONSTRAINT [PK__Country__5D9B0D2D6125EA6F] PRIMARY KEY CLUSTERED ([CountryCode])
);
GO
 
 
-- =============================================
-- TABLE: cfg.Currency
-- =============================================
CREATE TABLE [cfg].[Currency] (
    [CurrencyId] INT IDENTITY(1,1) NOT NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[CurrencyName] NVARCHAR(60) NOT NULL
   ,[Symbol] NVARCHAR(10) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_Currency] PRIMARY KEY CLUSTERED ([CurrencyId])
   ,CONSTRAINT [UQ_Currency_Code] UNIQUE NONCLUSTERED ([CurrencyCode])
);
GO
 
 
-- =============================================
-- TABLE: cfg.DocumentSequence
-- =============================================
CREATE TABLE [cfg].[DocumentSequence] (
    [SequenceId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[BranchId] INT NULL
   ,[DocumentType] NVARCHAR(20) NOT NULL
   ,[Prefix] NVARCHAR(10) NULL
   ,[Suffix] NVARCHAR(10) NULL
   ,[CurrentNumber] BIGINT NOT NULL DEFAULT ((1))
   ,[PaddingLength] INT NOT NULL DEFAULT ((8))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_DocumentSequence] PRIMARY KEY CLUSTERED ([SequenceId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DocumentSequence_NoBranch] ON [cfg].[DocumentSequence] ([CompanyId] ASC, [DocumentType] ASC) WHERE ([BranchId] IS NULL);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_DocumentSequence_Branch] ON [cfg].[DocumentSequence] ([CompanyId] ASC, [BranchId] ASC, [DocumentType] ASC) WHERE ([BranchId] IS NOT NULL);
GO
 
 
-- =============================================
-- TABLE: cfg.EntityImage
-- =============================================
CREATE TABLE [cfg].[EntityImage] (
    [EntityImageId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[EntityType] NVARCHAR(80) NOT NULL
   ,[EntityId] BIGINT NOT NULL
   ,[MediaAssetId] BIGINT NOT NULL
   ,[RoleCode] NVARCHAR(30) NULL
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsPrimary] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__EntityIm__B242D60112FBFD17] PRIMARY KEY CLUSTERED ([EntityImageId])
   ,CONSTRAINT [UQ_cfg_EntityImage_Link] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [EntityType], [EntityId], [MediaAssetId])
);
GO
ALTER TABLE [cfg].[EntityImage] ADD CONSTRAINT [FK_cfg_EntityImage_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [cfg].[EntityImage] ADD CONSTRAINT [FK_cfg_EntityImage_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [cfg].[EntityImage] ADD CONSTRAINT [FK_cfg_EntityImage_MediaAsset] FOREIGN KEY ([MediaAssetId]) REFERENCES [cfg].[MediaAsset] ([MediaAssetId]);
GO
ALTER TABLE [cfg].[EntityImage] ADD CONSTRAINT [FK_cfg_EntityImage_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [cfg].[EntityImage] ADD CONSTRAINT [FK_cfg_EntityImage_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_cfg_EntityImage_Entity] ON [cfg].[EntityImage] ([CompanyId] ASC, [BranchId] ASC, [EntityType] ASC, [EntityId] ASC, [IsDeleted] ASC, [IsActive] ASC, [SortOrder] ASC, [EntityImageId] ASC);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_cfg_EntityImage_Primary] ON [cfg].[EntityImage] ([CompanyId] ASC, [BranchId] ASC, [EntityType] ASC, [EntityId] ASC) WHERE ([IsPrimary]=(1) AND [IsDeleted]=(0) AND [IsActive]=(1));
GO
 
 
-- =============================================
-- TABLE: cfg.ExchangeRateDaily
-- =============================================
CREATE TABLE [cfg].[ExchangeRateDaily] (
    [ExchangeRateDailyId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[RateToBase] DECIMAL(18,6) NOT NULL
   ,[RateDate] DATE NOT NULL
   ,[SourceName] NVARCHAR(120) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,CONSTRAINT [PK__Exchange__D5677FB82C771732] PRIMARY KEY CLUSTERED ([ExchangeRateDailyId])
   ,CONSTRAINT [UQ_cfg_ExchangeRateDaily] UNIQUE NONCLUSTERED ([CurrencyCode], [RateDate])
);
GO
ALTER TABLE [cfg].[ExchangeRateDaily] ADD CONSTRAINT [FK_cfg_ExchangeRateDaily_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: cfg.Holiday
-- =============================================
CREATE TABLE [cfg].[Holiday] (
    [HolidayId] INT IDENTITY(1,1) NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL DEFAULT (N'VE')
   ,[HolidayDate] DATE NOT NULL
   ,[HolidayName] NVARCHAR(100) NOT NULL
   ,[IsRecurring] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_Holiday] PRIMARY KEY CLUSTERED ([HolidayId])
);
GO
 
 
-- =============================================
-- TABLE: cfg.MediaAsset
-- =============================================
CREATE TABLE [cfg].[MediaAsset] (
    [MediaAssetId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[StorageProvider] NVARCHAR(20) NOT NULL DEFAULT (N'LOCAL')
   ,[StorageKey] NVARCHAR(400) NOT NULL
   ,[PublicUrl] NVARCHAR(700) NOT NULL
   ,[OriginalFileName] NVARCHAR(260) NULL
   ,[MimeType] NVARCHAR(120) NOT NULL
   ,[FileExtension] NVARCHAR(20) NULL
   ,[FileSizeBytes] BIGINT NOT NULL DEFAULT ((0))
   ,[ChecksumSha256] CHAR(64) NULL
   ,[AltText] NVARCHAR(200) NULL
   ,[WidthPx] INT NULL
   ,[HeightPx] INT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__MediaAss__0F3E13BE50DACEDE] PRIMARY KEY CLUSTERED ([MediaAssetId])
   ,CONSTRAINT [UQ_cfg_MediaAsset_Storage] UNIQUE NONCLUSTERED ([StorageProvider], [StorageKey])
);
GO
ALTER TABLE [cfg].[MediaAsset] ADD CONSTRAINT [FK_cfg_MediaAsset_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [cfg].[MediaAsset] ADD CONSTRAINT [FK_cfg_MediaAsset_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [cfg].[MediaAsset] ADD CONSTRAINT [FK_cfg_MediaAsset_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [cfg].[MediaAsset] ADD CONSTRAINT [FK_cfg_MediaAsset_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_cfg_MediaAsset_Scope] ON [cfg].[MediaAsset] ([CompanyId] ASC, [BranchId] ASC, [IsDeleted] ASC, [IsActive] ASC, [MediaAssetId] DESC);
GO
 
 
-- =============================================
-- TABLE: cfg.ReportTemplate
-- =============================================
CREATE TABLE [cfg].[ReportTemplate] (
    [ReportId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[ReportCode] NVARCHAR(50) NOT NULL
   ,[ReportName] NVARCHAR(150) NOT NULL
   ,[ReportType] NVARCHAR(20) NOT NULL DEFAULT (N'REPORT')
   ,[QueryText] NVARCHAR(MAX) NULL
   ,[Parameters] NVARCHAR(MAX) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_ReportTemplate] PRIMARY KEY CLUSTERED ([ReportId])
);
GO
 
 
-- =============================================
-- TABLE: dbo.EndpointDependency
-- =============================================
CREATE TABLE [dbo].[EndpointDependency] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL
   ,[ModuleName] NVARCHAR(60) NOT NULL
   ,[ObjectType] NVARCHAR(10) NOT NULL
   ,[ObjectName] NVARCHAR(256) NOT NULL
   ,[IsCritical] BIT NOT NULL DEFAULT ((1))
   ,[SourceTag] NVARCHAR(40) NOT NULL DEFAULT ('governance_core')
   ,[Notes] NVARCHAR(300) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Endpoint__3214EC075FE6263F] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ_EndpointDependency] UNIQUE NONCLUSTERED ([ModuleName], [ObjectType], [ObjectName], [SourceTag])
);
GO
 
 
-- =============================================
-- TABLE: dbo.SchemaGovernanceDecision
-- =============================================
CREATE TABLE [dbo].[SchemaGovernanceDecision] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL
   ,[DecisionGroup] NVARCHAR(60) NOT NULL
   ,[ObjectType] NVARCHAR(20) NOT NULL
   ,[ObjectName] NVARCHAR(256) NOT NULL
   ,[DecisionStatus] NVARCHAR(20) NOT NULL DEFAULT ('PENDING')
   ,[RiskLevel] NVARCHAR(20) NOT NULL DEFAULT ('MEDIUM')
   ,[ProposedAction] NVARCHAR(500) NULL
   ,[Notes] NVARCHAR(MAX) NULL
   ,[Owner] NVARCHAR(80) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedBy] NVARCHAR(40) NULL
   ,[UpdatedBy] NVARCHAR(40) NULL
   ,CONSTRAINT [PK__SchemaGo__3214EC07684DF512] PRIMARY KEY CLUSTERED ([Id])
);
GO
 
 
-- =============================================
-- TABLE: dbo.SchemaGovernanceSnapshot
-- =============================================
CREATE TABLE [dbo].[SchemaGovernanceSnapshot] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL
   ,[SnapshotAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[TotalTables] INT NOT NULL
   ,[TablesWithoutPK] INT NOT NULL
   ,[TablesWithoutCreatedAt] INT NOT NULL
   ,[TablesWithoutUpdatedAt] INT NOT NULL
   ,[TablesWithoutCreatedBy] INT NOT NULL
   ,[TablesWithoutDateColumns] INT NOT NULL
   ,[DuplicateNameCandidatePairs] INT NOT NULL
   ,[SimilarityCandidatePairs] INT NOT NULL
   ,[Notes] NVARCHAR(500) NULL
   ,CONSTRAINT [PK__SchemaGo__3214EC0779AE7439] PRIMARY KEY CLUSTERED ([Id])
);
GO
 
 
-- =============================================
-- TABLE: dbo.Sys_Mensajes
-- =============================================
CREATE TABLE [dbo].[Sys_Mensajes] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[DestinatarioId] NVARCHAR(50) NOT NULL
   ,[RemitenteId] NVARCHAR(50) NULL
   ,[RemitenteNombre] NVARCHAR(120) NULL
   ,[Asunto] NVARCHAR(150) NOT NULL
   ,[Cuerpo] NVARCHAR(MAX) NOT NULL
   ,[Leido] BIT NOT NULL DEFAULT ((0))
   ,[FechaEnvio] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Sys_Mens__3214EC070B9BCB6A] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_Sys_Mensajes_DestinatarioLeidoFecha] ON [dbo].[Sys_Mensajes] ([DestinatarioId] ASC, [Leido] ASC, [FechaEnvio] DESC);
GO
 
 
-- =============================================
-- TABLE: dbo.Sys_Notificaciones
-- =============================================
CREATE TABLE [dbo].[Sys_Notificaciones] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[UsuarioId] NVARCHAR(50) NULL
   ,[Tipo] NVARCHAR(30) NOT NULL DEFAULT (N'info')
   ,[Titulo] NVARCHAR(150) NOT NULL
   ,[Mensaje] NVARCHAR(500) NOT NULL
   ,[RutaNavegacion] NVARCHAR(200) NULL
   ,[Leido] BIT NOT NULL DEFAULT ((0))
   ,[FechaCreacion] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Sys_Noti__3214EC07A12F4FF7] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_Sys_Notificaciones_UsuarioLeidoFecha] ON [dbo].[Sys_Notificaciones] ([UsuarioId] ASC, [Leido] ASC, [FechaCreacion] DESC);
GO
 
 
-- =============================================
-- TABLE: dbo.Sys_Tareas
-- =============================================
CREATE TABLE [dbo].[Sys_Tareas] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[Titulo] NVARCHAR(150) NOT NULL
   ,[Descripcion] NVARCHAR(500) NULL
   ,[Progreso] INT NOT NULL DEFAULT ((0))
   ,[Color] NVARCHAR(20) NOT NULL DEFAULT (N'primary')
   ,[AsignadoA] NVARCHAR(50) NULL
   ,[FechaVencimiento] DATETIME2(0) NULL
   ,[Completado] BIT NOT NULL DEFAULT ((0))
   ,[FechaCreacion] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Sys_Tare__3214EC07EB8B70C8] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_Sys_Tareas_AsignadoCompletadoFecha] ON [dbo].[Sys_Tareas] ([AsignadoA] ASC, [Completado] ASC, [FechaCreacion] DESC);
GO
 
 
-- =============================================
-- TABLE: fin.Bank
-- =============================================
CREATE TABLE [fin].[Bank] (
    [BankId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BankCode] NVARCHAR(30) NOT NULL
   ,[BankName] NVARCHAR(120) NOT NULL
   ,[ContactName] NVARCHAR(120) NULL
   ,[AddressLine] NVARCHAR(250) NULL
   ,[Phones] NVARCHAR(120) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Bank__AA08CB136B0FB53C] PRIMARY KEY CLUSTERED ([BankId])
   ,CONSTRAINT [UQ_fin_Bank_Name] UNIQUE NONCLUSTERED ([CompanyId], [BankName])
   ,CONSTRAINT [UQ_fin_Bank_Code] UNIQUE NONCLUSTERED ([CompanyId], [BankCode])
);
GO
ALTER TABLE [fin].[Bank] ADD CONSTRAINT [FK_fin_Bank_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [fin].[Bank] ADD CONSTRAINT [FK_fin_Bank_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fin].[Bank] ADD CONSTRAINT [FK_fin_Bank_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: fin.BankAccount
-- =============================================
CREATE TABLE [fin].[BankAccount] (
    [BankAccountId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[BankId] BIGINT NOT NULL
   ,[AccountNumber] NVARCHAR(40) NOT NULL
   ,[AccountName] NVARCHAR(150) NULL
   ,[CurrencyCode] CHAR(3) NOT NULL
   ,[Balance] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[AvailableBalance] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__BankAcco__4FC8E4A1B8273891] PRIMARY KEY CLUSTERED ([BankAccountId])
   ,CONSTRAINT [UQ_fin_BankAccount] UNIQUE NONCLUSTERED ([CompanyId], [AccountNumber])
);
GO
ALTER TABLE [fin].[BankAccount] ADD CONSTRAINT [FK_fin_BankAccount_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [fin].[BankAccount] ADD CONSTRAINT [FK_fin_BankAccount_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [fin].[BankAccount] ADD CONSTRAINT [FK_fin_BankAccount_Bank] FOREIGN KEY ([BankId]) REFERENCES [fin].[Bank] ([BankId]);
GO
ALTER TABLE [fin].[BankAccount] ADD CONSTRAINT [FK_fin_BankAccount_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fin].[BankAccount] ADD CONSTRAINT [FK_fin_BankAccount_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_fin_BankAccount_Search] ON [fin].[BankAccount] ([CompanyId] ASC, [BranchId] ASC, [IsActive] ASC, [AccountNumber] ASC);
GO
 
 
-- =============================================
-- TABLE: fin.BankMovement
-- =============================================
CREATE TABLE [fin].[BankMovement] (
    [BankMovementId] BIGINT IDENTITY(1,1) NOT NULL
   ,[BankAccountId] BIGINT NOT NULL
   ,[ReconciliationId] BIGINT NULL
   ,[MovementDate] DATETIME2(0) NOT NULL
   ,[MovementType] NVARCHAR(12) NOT NULL
   ,[MovementSign] SMALLINT NOT NULL
   ,[Amount] DECIMAL(18,2) NOT NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL
   ,[ReferenceNo] NVARCHAR(50) NULL
   ,[Beneficiary] NVARCHAR(255) NULL
   ,[Concept] NVARCHAR(255) NULL
   ,[CategoryCode] NVARCHAR(50) NULL
   ,[RelatedDocumentNo] NVARCHAR(60) NULL
   ,[RelatedDocumentType] NVARCHAR(20) NULL
   ,[BalanceAfter] DECIMAL(18,2) NULL
   ,[IsReconciled] BIT NOT NULL DEFAULT ((0))
   ,[ReconciledAt] DATETIME2(0) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__BankMove__9C809F9FF3472A10] PRIMARY KEY CLUSTERED ([BankMovementId])
   ,CONSTRAINT [CK_fin_BankMovement_Sign] CHECK ([MovementSign]=(1) OR [MovementSign]=(-1))
   ,CONSTRAINT [CK_fin_BankMovement_Amount] CHECK ([Amount]>=(0))
);
GO
ALTER TABLE [fin].[BankMovement] ADD CONSTRAINT [FK_fin_BankMovement_Account] FOREIGN KEY ([BankAccountId]) REFERENCES [fin].[BankAccount] ([BankAccountId]);
GO
ALTER TABLE [fin].[BankMovement] ADD CONSTRAINT [FK_fin_BankMovement_Reconciliation] FOREIGN KEY ([ReconciliationId]) REFERENCES [fin].[BankReconciliation] ([BankReconciliationId]);
GO
ALTER TABLE [fin].[BankMovement] ADD CONSTRAINT [FK_fin_BankMovement_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_fin_BankMovement_Search] ON [fin].[BankMovement] ([BankAccountId] ASC, [MovementDate] DESC, [BankMovementId] DESC);
GO
 
 
-- =============================================
-- TABLE: fin.BankReconciliation
-- =============================================
CREATE TABLE [fin].[BankReconciliation] (
    [BankReconciliationId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[BankAccountId] BIGINT NOT NULL
   ,[DateFrom] DATE NOT NULL
   ,[DateTo] DATE NOT NULL
   ,[OpeningSystemBalance] DECIMAL(18,2) NOT NULL
   ,[ClosingSystemBalance] DECIMAL(18,2) NOT NULL
   ,[OpeningBankBalance] DECIMAL(18,2) NOT NULL
   ,[ClosingBankBalance] DECIMAL(18,2) NULL
   ,[DifferenceAmount] DECIMAL(18,2) NULL
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT (N'OPEN')
   ,[Notes] NVARCHAR(500) NULL
   ,[ClosedAt] DATETIME2(0) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[ClosedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__BankReco__C9995CAAEC1CCC71] PRIMARY KEY CLUSTERED ([BankReconciliationId])
   ,CONSTRAINT [CK_fin_BankRec_Status] CHECK ([Status]=N'CLOSED_WITH_DIFF' OR [Status]=N'CLOSED' OR [Status]=N'OPEN')
);
GO
ALTER TABLE [fin].[BankReconciliation] ADD CONSTRAINT [FK_fin_BankRec_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [fin].[BankReconciliation] ADD CONSTRAINT [FK_fin_BankRec_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [fin].[BankReconciliation] ADD CONSTRAINT [FK_fin_BankRec_Account] FOREIGN KEY ([BankAccountId]) REFERENCES [fin].[BankAccount] ([BankAccountId]);
GO
ALTER TABLE [fin].[BankReconciliation] ADD CONSTRAINT [FK_fin_BankRec_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fin].[BankReconciliation] ADD CONSTRAINT [FK_fin_BankRec_ClosedBy] FOREIGN KEY ([ClosedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_fin_BankRec_Search] ON [fin].[BankReconciliation] ([BankAccountId] ASC, [Status] ASC, [DateFrom] ASC, [DateTo] ASC);
GO
 
 
-- =============================================
-- TABLE: fin.BankReconciliationMatch
-- =============================================
CREATE TABLE [fin].[BankReconciliationMatch] (
    [BankReconciliationMatchId] BIGINT IDENTITY(1,1) NOT NULL
   ,[ReconciliationId] BIGINT NOT NULL
   ,[BankMovementId] BIGINT NOT NULL
   ,[StatementLineId] BIGINT NULL
   ,[MatchedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[MatchedByUserId] INT NULL
   ,CONSTRAINT [PK__BankReco__0E09650E0F218281] PRIMARY KEY CLUSTERED ([BankReconciliationMatchId])
   ,CONSTRAINT [UQ_fin_BankRecMatch_Statement] UNIQUE NONCLUSTERED ([ReconciliationId], [StatementLineId])
   ,CONSTRAINT [UQ_fin_BankRecMatch_Movement] UNIQUE NONCLUSTERED ([ReconciliationId], [BankMovementId])
);
GO
ALTER TABLE [fin].[BankReconciliationMatch] ADD CONSTRAINT [FK_fin_BankRecMatch_Reconciliation] FOREIGN KEY ([ReconciliationId]) REFERENCES [fin].[BankReconciliation] ([BankReconciliationId]);
GO
ALTER TABLE [fin].[BankReconciliationMatch] ADD CONSTRAINT [FK_fin_BankRecMatch_Movement] FOREIGN KEY ([BankMovementId]) REFERENCES [fin].[BankMovement] ([BankMovementId]);
GO
ALTER TABLE [fin].[BankReconciliationMatch] ADD CONSTRAINT [FK_fin_BankRecMatch_Statement] FOREIGN KEY ([StatementLineId]) REFERENCES [fin].[BankStatementLine] ([StatementLineId]);
GO
ALTER TABLE [fin].[BankReconciliationMatch] ADD CONSTRAINT [FK_fin_BankRecMatch_User] FOREIGN KEY ([MatchedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: fin.BankStatementLine
-- =============================================
CREATE TABLE [fin].[BankStatementLine] (
    [StatementLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[ReconciliationId] BIGINT NOT NULL
   ,[StatementDate] DATETIME2(0) NOT NULL
   ,[DescriptionText] NVARCHAR(255) NULL
   ,[ReferenceNo] NVARCHAR(50) NULL
   ,[EntryType] NVARCHAR(12) NOT NULL
   ,[Amount] DECIMAL(18,2) NOT NULL
   ,[Balance] DECIMAL(18,2) NULL
   ,[IsMatched] BIT NOT NULL DEFAULT ((0))
   ,[MatchedAt] DATETIME2(0) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__BankStat__A2C21D23EC58F4E7] PRIMARY KEY CLUSTERED ([StatementLineId])
   ,CONSTRAINT [CK_fin_BankStatementLine_EntryType] CHECK ([EntryType]=N'CREDITO' OR [EntryType]=N'DEBITO')
   ,CONSTRAINT [CK_fin_BankStatementLine_Amount] CHECK ([Amount]>=(0))
);
GO
ALTER TABLE [fin].[BankStatementLine] ADD CONSTRAINT [FK_fin_BankStatementLine_Reconciliation] FOREIGN KEY ([ReconciliationId]) REFERENCES [fin].[BankReconciliation] ([BankReconciliationId]);
GO
ALTER TABLE [fin].[BankStatementLine] ADD CONSTRAINT [FK_fin_BankStatementLine_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_fin_BankStatementLine_Search] ON [fin].[BankStatementLine] ([ReconciliationId] ASC, [IsMatched] ASC, [StatementDate] ASC);
GO
 
 
-- =============================================
-- TABLE: fiscal.CountryConfig
-- =============================================
CREATE TABLE [fiscal].[CountryConfig] (
    [CountryConfigId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[Currency] CHAR(3) NOT NULL
   ,[TaxRegime] NVARCHAR(50) NULL
   ,[DefaultTaxCode] NVARCHAR(30) NULL
   ,[DefaultTaxRate] DECIMAL(9,4) NOT NULL
   ,[FiscalPrinterEnabled] BIT NOT NULL DEFAULT ((0))
   ,[PrinterBrand] NVARCHAR(30) NULL
   ,[PrinterPort] NVARCHAR(20) NULL
   ,[VerifactuEnabled] BIT NOT NULL DEFAULT ((0))
   ,[VerifactuMode] NVARCHAR(10) NULL
   ,[CertificatePath] NVARCHAR(500) NULL
   ,[CertificatePassword] NVARCHAR(255) NULL
   ,[AEATEndpoint] NVARCHAR(500) NULL
   ,[SenderNIF] NVARCHAR(20) NULL
   ,[SenderRIF] NVARCHAR(20) NULL
   ,[SoftwareId] NVARCHAR(100) NULL
   ,[SoftwareName] NVARCHAR(200) NULL
   ,[SoftwareVersion] NVARCHAR(20) NULL
   ,[PosEnabled] BIT NOT NULL DEFAULT ((1))
   ,[RestaurantEnabled] BIT NOT NULL DEFAULT ((1))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__CountryC__40E7824D5B26199F] PRIMARY KEY CLUSTERED ([CountryConfigId])
   ,CONSTRAINT [UQ_fiscal_CountryCfg] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [CountryCode])
   ,CONSTRAINT [CK_fiscal_CountryCfg_VerifactuMode] CHECK ([VerifactuMode]='manual' OR [VerifactuMode]='auto' OR [VerifactuMode] IS NULL)
);
GO
ALTER TABLE [fiscal].[CountryConfig] ADD CONSTRAINT [FK_fiscal_CountryCfg_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [fiscal].[CountryConfig] ADD CONSTRAINT [FK_fiscal_CountryCfg_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [fiscal].[CountryConfig] ADD CONSTRAINT [FK_fiscal_CountryCfg_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [fiscal].[CountryConfig] ADD CONSTRAINT [FK_fiscal_CountryCfg_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fiscal].[CountryConfig] ADD CONSTRAINT [FK_fiscal_CountryCfg_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: fiscal.InvoiceType
-- =============================================
CREATE TABLE [fiscal].[InvoiceType] (
    [InvoiceTypeId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[InvoiceTypeCode] NVARCHAR(20) NOT NULL
   ,[InvoiceTypeName] NVARCHAR(120) NOT NULL
   ,[IsRectificative] BIT NOT NULL DEFAULT ((0))
   ,[RequiresRecipientId] BIT NOT NULL DEFAULT ((0))
   ,[MaxAmount] DECIMAL(18,2) NULL
   ,[RequiresFiscalPrinter] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__InvoiceT__BFD396BC63BEF8CA] PRIMARY KEY CLUSTERED ([InvoiceTypeId])
   ,CONSTRAINT [UQ_fiscal_InvType] UNIQUE NONCLUSTERED ([CountryCode], [InvoiceTypeCode])
);
GO
ALTER TABLE [fiscal].[InvoiceType] ADD CONSTRAINT [FK_fiscal_InvType_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [fiscal].[InvoiceType] ADD CONSTRAINT [FK_fiscal_InvType_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fiscal].[InvoiceType] ADD CONSTRAINT [FK_fiscal_InvType_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: fiscal.Record
-- =============================================
CREATE TABLE [fiscal].[Record] (
    [FiscalRecordId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[InvoiceId] INT NOT NULL
   ,[InvoiceType] NVARCHAR(20) NOT NULL
   ,[InvoiceNumber] NVARCHAR(50) NOT NULL
   ,[InvoiceDate] DATE NOT NULL
   ,[RecipientId] NVARCHAR(20) NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[RecordHash] VARCHAR(64) NOT NULL
   ,[PreviousRecordHash] VARCHAR(64) NULL
   ,[XmlContent] NVARCHAR(MAX) NULL
   ,[DigitalSignature] NVARCHAR(MAX) NULL
   ,[QRCodeData] NVARCHAR(800) NULL
   ,[SentToAuthority] BIT NOT NULL DEFAULT ((0))
   ,[SentAt] DATETIME2(0) NULL
   ,[AuthorityResponse] NVARCHAR(MAX) NULL
   ,[AuthorityStatus] NVARCHAR(20) NULL
   ,[FiscalPrinterSerial] NVARCHAR(30) NULL
   ,[FiscalControlNumber] NVARCHAR(30) NULL
   ,[ZReportNumber] INT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Record__D78A81509493E2AF] PRIMARY KEY CLUSTERED ([FiscalRecordId])
   ,CONSTRAINT [UQ_fiscal_Record_Hash] UNIQUE NONCLUSTERED ([RecordHash])
);
GO
ALTER TABLE [fiscal].[Record] ADD CONSTRAINT [FK_fiscal_Record_CountryCfg] FOREIGN KEY ([CompanyId], [BranchId], [CountryCode]) REFERENCES [fiscal].[CountryConfig] ([CompanyId], [BranchId], [CountryCode]);
GO
ALTER TABLE [fiscal].[Record] ADD CONSTRAINT [FK_fiscal_Record_PrevHash] FOREIGN KEY ([PreviousRecordHash]) REFERENCES [fiscal].[Record] ([RecordHash]);
GO
CREATE NONCLUSTERED INDEX [IX_fiscal_Record_Search] ON [fiscal].[Record] ([CompanyId] ASC, [BranchId] ASC, [CountryCode] ASC, [FiscalRecordId] DESC);
GO
 
 
-- =============================================
-- TABLE: fiscal.TaxRate
-- =============================================
CREATE TABLE [fiscal].[TaxRate] (
    [TaxRateId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[TaxCode] NVARCHAR(30) NOT NULL
   ,[TaxName] NVARCHAR(120) NOT NULL
   ,[Rate] DECIMAL(9,4) NOT NULL
   ,[SurchargeRate] DECIMAL(9,4) NULL
   ,[AppliesToPOS] BIT NOT NULL DEFAULT ((1))
   ,[AppliesToRestaurant] BIT NOT NULL DEFAULT ((1))
   ,[IsDefault] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__TaxRate__B114CEC150105F4E] PRIMARY KEY CLUSTERED ([TaxRateId])
   ,CONSTRAINT [UQ_fiscal_TaxRate] UNIQUE NONCLUSTERED ([CountryCode], [TaxCode])
   ,CONSTRAINT [CK_fiscal_TaxRate_Rate] CHECK ([Rate]>=(0) AND [Rate]<=(1))
   ,CONSTRAINT [CK_fiscal_TaxRate_Surcharge] CHECK ([SurchargeRate] IS NULL OR [SurchargeRate]>=(0) AND [SurchargeRate]<=(1))
);
GO
ALTER TABLE [fiscal].[TaxRate] ADD CONSTRAINT [FK_fiscal_TaxRate_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [fiscal].[TaxRate] ADD CONSTRAINT [FK_fiscal_TaxRate_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [fiscal].[TaxRate] ADD CONSTRAINT [FK_fiscal_TaxRate_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollCalcVariable
-- =============================================
CREATE TABLE [hr].[PayrollCalcVariable] (
    [SessionID] NVARCHAR(80) NOT NULL
   ,[Variable] NVARCHAR(120) NOT NULL
   ,[Valor] DECIMAL(18,6) NOT NULL DEFAULT ((0))
   ,[Descripcion] NVARCHAR(255) NULL
   ,[CreatedAt] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_PayrollCalcVariable] PRIMARY KEY CLUSTERED ([SessionID], [Variable])
);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollConcept
-- =============================================
CREATE TABLE [hr].[PayrollConcept] (
    [PayrollConceptId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[PayrollCode] NVARCHAR(15) NOT NULL
   ,[ConceptCode] NVARCHAR(20) NOT NULL
   ,[ConceptName] NVARCHAR(120) NOT NULL
   ,[Formula] NVARCHAR(500) NULL
   ,[BaseExpression] NVARCHAR(255) NULL
   ,[ConceptClass] NVARCHAR(20) NULL
   ,[ConceptType] NVARCHAR(15) NOT NULL DEFAULT (N'ASIGNACION')
   ,[UsageType] NVARCHAR(20) NULL
   ,[IsBonifiable] BIT NOT NULL DEFAULT ((0))
   ,[IsSeniority] BIT NOT NULL DEFAULT ((0))
   ,[AccountingAccountCode] NVARCHAR(50) NULL
   ,[AppliesFlag] BIT NOT NULL DEFAULT ((1))
   ,[DefaultValue] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[ConventionCode] NVARCHAR(50) NULL
   ,[CalculationType] NVARCHAR(50) NULL
   ,[LotttArticle] NVARCHAR(50) NULL
   ,[CcpClause] NVARCHAR(50) NULL
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__PayrollC__B70D1E9358EE67DB] PRIMARY KEY CLUSTERED ([PayrollConceptId])
   ,CONSTRAINT [UQ_hr_PayrollConcept] UNIQUE NONCLUSTERED ([CompanyId], [PayrollCode], [ConceptCode], [ConventionCode], [CalculationType])
   ,CONSTRAINT [CK_hr_PayrollConcept_Type] CHECK ([ConceptType]=N'BONO' OR [ConceptType]=N'DEDUCCION' OR [ConceptType]=N'ASIGNACION')
);
GO
ALTER TABLE [hr].[PayrollConcept] ADD CONSTRAINT [FK_hr_PayrollConcept_PayrollType] FOREIGN KEY ([CompanyId], [PayrollCode]) REFERENCES [hr].[PayrollType] ([CompanyId], [PayrollCode]);
GO
ALTER TABLE [hr].[PayrollConcept] ADD CONSTRAINT [FK_hr_PayrollConcept_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[PayrollConcept] ADD CONSTRAINT [FK_hr_PayrollConcept_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_hr_PayrollConcept_Search] ON [hr].[PayrollConcept] ([CompanyId] ASC, [PayrollCode] ASC, [IsActive] ASC, [ConceptType] ASC, [SortOrder] ASC, [ConceptCode] ASC);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollConstant
-- =============================================
CREATE TABLE [hr].[PayrollConstant] (
    [PayrollConstantId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[ConstantCode] NVARCHAR(50) NOT NULL
   ,[ConstantName] NVARCHAR(120) NOT NULL
   ,[ConstantValue] DECIMAL(18,4) NOT NULL
   ,[SourceName] NVARCHAR(60) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__PayrollC__5FFB63718BFB67F8] PRIMARY KEY CLUSTERED ([PayrollConstantId])
   ,CONSTRAINT [UQ_hr_PayrollConstant] UNIQUE NONCLUSTERED ([CompanyId], [ConstantCode])
);
GO
ALTER TABLE [hr].[PayrollConstant] ADD CONSTRAINT [FK_hr_PayrollConstant_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [hr].[PayrollConstant] ADD CONSTRAINT [FK_hr_PayrollConstant_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[PayrollConstant] ADD CONSTRAINT [FK_hr_PayrollConstant_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollRun
-- =============================================
CREATE TABLE [hr].[PayrollRun] (
    [PayrollRunId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[PayrollCode] NVARCHAR(15) NOT NULL
   ,[EmployeeId] BIGINT NULL
   ,[EmployeeCode] NVARCHAR(24) NOT NULL
   ,[EmployeeName] NVARCHAR(200) NOT NULL
   ,[PositionName] NVARCHAR(120) NULL
   ,[ProcessDate] DATE NOT NULL
   ,[DateFrom] DATE NOT NULL
   ,[DateTo] DATE NOT NULL
   ,[TotalAssignments] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalDeductions] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[NetTotal] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[IsClosed] BIT NOT NULL DEFAULT ((0))
   ,[PayrollTypeName] NVARCHAR(50) NULL
   ,[RunSource] NVARCHAR(20) NOT NULL DEFAULT (N'MANUAL')
   ,[ClosedAt] DATETIME2(0) NULL
   ,[ClosedByUserId] INT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__PayrollR__8B3CCD4D4F8F09FA] PRIMARY KEY CLUSTERED ([PayrollRunId])
   ,CONSTRAINT [UQ_hr_PayrollRun] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [PayrollCode], [EmployeeCode], [DateFrom], [DateTo], [RunSource])
);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [master].[Employee] ([EmployeeId]);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[PayrollRun] ADD CONSTRAINT [FK_hr_PayrollRun_ClosedBy] FOREIGN KEY ([ClosedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_hr_PayrollRun_Search] ON [hr].[PayrollRun] ([CompanyId] ASC, [PayrollCode] ASC, [EmployeeCode] ASC, [ProcessDate] DESC, [IsClosed] ASC);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollRunLine
-- =============================================
CREATE TABLE [hr].[PayrollRunLine] (
    [PayrollRunLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[PayrollRunId] BIGINT NOT NULL
   ,[ConceptCode] NVARCHAR(20) NOT NULL
   ,[ConceptName] NVARCHAR(120) NOT NULL
   ,[ConceptType] NVARCHAR(15) NOT NULL
   ,[Quantity] DECIMAL(18,4) NOT NULL DEFAULT ((1))
   ,[Amount] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[Total] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[DescriptionText] NVARCHAR(255) NULL
   ,[AccountingAccountCode] NVARCHAR(50) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__PayrollR__CCEE71D9623B0A3E] PRIMARY KEY CLUSTERED ([PayrollRunLineId])
);
GO
ALTER TABLE [hr].[PayrollRunLine] ADD CONSTRAINT [FK_hr_PayrollRunLine_Run] FOREIGN KEY ([PayrollRunId]) REFERENCES [hr].[PayrollRun] ([PayrollRunId]) ON DELETE CASCADE;
GO
CREATE NONCLUSTERED INDEX [IX_hr_PayrollRunLine_Run] ON [hr].[PayrollRunLine] ([PayrollRunId] ASC, [ConceptType] ASC, [ConceptCode] ASC);
GO
 
 
-- =============================================
-- TABLE: hr.PayrollType
-- =============================================
CREATE TABLE [hr].[PayrollType] (
    [PayrollTypeId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[PayrollCode] NVARCHAR(15) NOT NULL
   ,[PayrollName] NVARCHAR(120) NOT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__PayrollT__BA8751EE37F7A40B] PRIMARY KEY CLUSTERED ([PayrollTypeId])
   ,CONSTRAINT [UQ_hr_PayrollType] UNIQUE NONCLUSTERED ([CompanyId], [PayrollCode])
);
GO
ALTER TABLE [hr].[PayrollType] ADD CONSTRAINT [FK_hr_PayrollType_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [hr].[PayrollType] ADD CONSTRAINT [FK_hr_PayrollType_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[PayrollType] ADD CONSTRAINT [FK_hr_PayrollType_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: hr.SettlementProcess
-- =============================================
CREATE TABLE [hr].[SettlementProcess] (
    [SettlementProcessId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[SettlementCode] NVARCHAR(50) NOT NULL
   ,[EmployeeId] BIGINT NULL
   ,[EmployeeCode] NVARCHAR(24) NOT NULL
   ,[EmployeeName] NVARCHAR(200) NOT NULL
   ,[RetirementDate] DATE NOT NULL
   ,[RetirementCause] NVARCHAR(40) NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Settleme__622B69D79D8CBBCE] PRIMARY KEY CLUSTERED ([SettlementProcessId])
   ,CONSTRAINT [UQ_hr_SettlementProcess] UNIQUE NONCLUSTERED ([CompanyId], [SettlementCode])
);
GO
ALTER TABLE [hr].[SettlementProcess] ADD CONSTRAINT [FK_hr_SettlementProcess_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [hr].[SettlementProcess] ADD CONSTRAINT [FK_hr_SettlementProcess_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [hr].[SettlementProcess] ADD CONSTRAINT [FK_hr_SettlementProcess_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [master].[Employee] ([EmployeeId]);
GO
ALTER TABLE [hr].[SettlementProcess] ADD CONSTRAINT [FK_hr_SettlementProcess_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[SettlementProcess] ADD CONSTRAINT [FK_hr_SettlementProcess_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: hr.SettlementProcessLine
-- =============================================
CREATE TABLE [hr].[SettlementProcessLine] (
    [SettlementProcessLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[SettlementProcessId] BIGINT NOT NULL
   ,[ConceptCode] NVARCHAR(20) NOT NULL
   ,[ConceptName] NVARCHAR(120) NOT NULL
   ,[Amount] DECIMAL(18,2) NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Settleme__9AACCB6FEA221079] PRIMARY KEY CLUSTERED ([SettlementProcessLineId])
);
GO
ALTER TABLE [hr].[SettlementProcessLine] ADD CONSTRAINT [FK_hr_SettlementProcessLine_Process] FOREIGN KEY ([SettlementProcessId]) REFERENCES [hr].[SettlementProcess] ([SettlementProcessId]) ON DELETE CASCADE;
GO
 
 
-- =============================================
-- TABLE: hr.VacationProcess
-- =============================================
CREATE TABLE [hr].[VacationProcess] (
    [VacationProcessId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[VacationCode] NVARCHAR(50) NOT NULL
   ,[EmployeeId] BIGINT NULL
   ,[EmployeeCode] NVARCHAR(24) NOT NULL
   ,[EmployeeName] NVARCHAR(200) NOT NULL
   ,[StartDate] DATE NOT NULL
   ,[EndDate] DATE NOT NULL
   ,[ReintegrationDate] DATE NULL
   ,[ProcessDate] DATE NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[CalculatedAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Vacation__E5BC9472F1C4C8C0] PRIMARY KEY CLUSTERED ([VacationProcessId])
   ,CONSTRAINT [UQ_hr_VacationProcess] UNIQUE NONCLUSTERED ([CompanyId], [VacationCode])
);
GO
ALTER TABLE [hr].[VacationProcess] ADD CONSTRAINT [FK_hr_VacationProcess_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [hr].[VacationProcess] ADD CONSTRAINT [FK_hr_VacationProcess_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [hr].[VacationProcess] ADD CONSTRAINT [FK_hr_VacationProcess_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [master].[Employee] ([EmployeeId]);
GO
ALTER TABLE [hr].[VacationProcess] ADD CONSTRAINT [FK_hr_VacationProcess_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [hr].[VacationProcess] ADD CONSTRAINT [FK_hr_VacationProcess_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: hr.VacationProcessLine
-- =============================================
CREATE TABLE [hr].[VacationProcessLine] (
    [VacationProcessLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[VacationProcessId] BIGINT NOT NULL
   ,[ConceptCode] NVARCHAR(20) NOT NULL
   ,[ConceptName] NVARCHAR(120) NOT NULL
   ,[Amount] DECIMAL(18,2) NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Vacation__575D2A59D9AACCDF] PRIMARY KEY CLUSTERED ([VacationProcessLineId])
);
GO
ALTER TABLE [hr].[VacationProcessLine] ADD CONSTRAINT [FK_hr_VacationProcessLine_Process] FOREIGN KEY ([VacationProcessId]) REFERENCES [hr].[VacationProcess] ([VacationProcessId]) ON DELETE CASCADE;
GO
 
 
-- =============================================
-- TABLE: master.Brand
-- =============================================
CREATE TABLE [master].[Brand] (
    [BrandId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[BrandCode] NVARCHAR(20) NULL
   ,[BrandName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[UserCode] NVARCHAR(20) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_Brand] PRIMARY KEY CLUSTERED ([BrandId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Brand_CompanyName] ON [master].[Brand] ([CompanyId] ASC, [BrandName] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.Category
-- =============================================
CREATE TABLE [master].[Category] (
    [CategoryId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[CategoryCode] NVARCHAR(20) NULL
   ,[CategoryName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[UserCode] NVARCHAR(20) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_Category] PRIMARY KEY CLUSTERED ([CategoryId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Category_CompanyName] ON [master].[Category] ([CompanyId] ASC, [CategoryName] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.CostCenter
-- =============================================
CREATE TABLE [master].[CostCenter] (
    [CostCenterId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[CostCenterCode] NVARCHAR(20) NOT NULL
   ,[CostCenterName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_CostCenter] PRIMARY KEY CLUSTERED ([CostCenterId])
);
GO
 
 
-- =============================================
-- TABLE: master.Customer
-- =============================================
CREATE TABLE [master].[Customer] (
    [CustomerId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[CustomerCode] NVARCHAR(24) NOT NULL
   ,[CustomerName] NVARCHAR(200) NOT NULL
   ,[FiscalId] NVARCHAR(30) NULL
   ,[Email] NVARCHAR(150) NULL
   ,[Phone] NVARCHAR(40) NULL
   ,[AddressLine] NVARCHAR(250) NULL
   ,[CreditLimit] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalBalance] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Customer__A4AE64D85B93AF59] PRIMARY KEY CLUSTERED ([CustomerId])
   ,CONSTRAINT [UQ_master_Customer] UNIQUE NONCLUSTERED ([CompanyId], [CustomerCode])
);
GO
ALTER TABLE [master].[Customer] ADD CONSTRAINT [FK_master_Customer_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [master].[Customer] ADD CONSTRAINT [FK_master_Customer_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [master].[Customer] ADD CONSTRAINT [FK_master_Customer_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: master.Employee
-- =============================================
CREATE TABLE [master].[Employee] (
    [EmployeeId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[EmployeeCode] NVARCHAR(24) NOT NULL
   ,[EmployeeName] NVARCHAR(200) NOT NULL
   ,[FiscalId] NVARCHAR(30) NULL
   ,[HireDate] DATE NULL
   ,[TerminationDate] DATE NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Employee__7AD04F111B0DC47D] PRIMARY KEY CLUSTERED ([EmployeeId])
   ,CONSTRAINT [UQ_master_Employee] UNIQUE NONCLUSTERED ([CompanyId], [EmployeeCode])
);
GO
ALTER TABLE [master].[Employee] ADD CONSTRAINT [FK_master_Employee_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [master].[Employee] ADD CONSTRAINT [FK_master_Employee_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [master].[Employee] ADD CONSTRAINT [FK_master_Employee_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: master.InventoryMovement
-- =============================================
CREATE TABLE [master].[InventoryMovement] (
    [MovementId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[BranchId] INT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[ProductName] NVARCHAR(250) NULL
   ,[DocumentRef] NVARCHAR(60) NULL
   ,[MovementType] NVARCHAR(20) NOT NULL DEFAULT (N'ENTRADA')
   ,[MovementDate] DATE NOT NULL DEFAULT (CONVERT([date],sysutcdatetime()))
   ,[Quantity] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[UnitCost] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[TotalCost] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[Notes] NVARCHAR(300) NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_InventoryMovement] PRIMARY KEY CLUSTERED ([MovementId])
);
GO
CREATE NONCLUSTERED INDEX [IX_InventoryMovement_ProductDate] ON [master].[InventoryMovement] ([ProductCode] ASC, [MovementDate] DESC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.InventoryPeriodSummary
-- =============================================
CREATE TABLE [master].[InventoryPeriodSummary] (
    [SummaryId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[Period] CHAR(6) NOT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[OpeningQty] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[InboundQty] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[OutboundQty] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[ClosingQty] DECIMAL(18,4) NOT NULL DEFAULT ((0))
   ,[SummaryDate] DATE NOT NULL DEFAULT (CONVERT([date],sysutcdatetime()))
   ,[IsClosed] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_InventoryPeriodSummary] PRIMARY KEY CLUSTERED ([SummaryId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_InventoryPeriodSummary_Key] ON [master].[InventoryPeriodSummary] ([CompanyId] ASC, [Period] ASC, [ProductCode] ASC);
GO
 
 
-- =============================================
-- TABLE: master.Product
-- =============================================
CREATE TABLE [master].[Product] (
    [ProductId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[ProductName] NVARCHAR(250) NOT NULL
   ,[CategoryCode] NVARCHAR(50) NULL
   ,[UnitCode] NVARCHAR(20) NULL
   ,[SalesPrice] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[CostPrice] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[DefaultTaxCode] NVARCHAR(30) NULL
   ,[DefaultTaxRate] DECIMAL(9,4) NOT NULL DEFAULT ((0))
   ,[StockQty] DECIMAL(18,3) NOT NULL DEFAULT ((0))
   ,[IsService] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Product__B40CC6CDEBD75ADC] PRIMARY KEY CLUSTERED ([ProductId])
   ,CONSTRAINT [UQ_master_Product] UNIQUE NONCLUSTERED ([CompanyId], [ProductCode])
);
GO
ALTER TABLE [master].[Product] ADD CONSTRAINT [FK_master_Product_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [master].[Product] ADD CONSTRAINT [FK_master_Product_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [master].[Product] ADD CONSTRAINT [FK_master_Product_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_master_Product_Company_IsActive] ON [master].[Product] ([CompanyId] ASC, [IsActive] ASC, [ProductCode] ASC);
GO
 
 
-- =============================================
-- TABLE: master.ProductClass
-- =============================================
CREATE TABLE [master].[ProductClass] (
    [ClassId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[ClassCode] NVARCHAR(20) NOT NULL
   ,[ClassName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_ProductClass] PRIMARY KEY CLUSTERED ([ClassId])
);
GO
 
 
-- =============================================
-- TABLE: master.ProductGroup
-- =============================================
CREATE TABLE [master].[ProductGroup] (
    [GroupId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[GroupCode] NVARCHAR(20) NOT NULL
   ,[GroupName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_ProductGroup] PRIMARY KEY CLUSTERED ([GroupId])
);
GO
 
 
-- =============================================
-- TABLE: master.ProductLine
-- =============================================
CREATE TABLE [master].[ProductLine] (
    [LineId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[LineCode] NVARCHAR(20) NOT NULL
   ,[LineName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_ProductLine] PRIMARY KEY CLUSTERED ([LineId])
);
GO
 
 
-- =============================================
-- TABLE: master.ProductType
-- =============================================
CREATE TABLE [master].[ProductType] (
    [TypeId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[TypeCode] NVARCHAR(20) NOT NULL
   ,[TypeName] NVARCHAR(100) NOT NULL
   ,[CategoryCode] NVARCHAR(50) NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_ProductType] PRIMARY KEY CLUSTERED ([TypeId])
);
GO
 
 
-- =============================================
-- TABLE: master.Seller
-- =============================================
CREATE TABLE [master].[Seller] (
    [SellerId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[SellerCode] NVARCHAR(10) NOT NULL
   ,[SellerName] NVARCHAR(120) NOT NULL
   ,[Commission] DECIMAL(5,2) NOT NULL DEFAULT ((0))
   ,[Address] NVARCHAR(250) NULL
   ,[Phone] NVARCHAR(60) NULL
   ,[Email] NVARCHAR(150) NULL
   ,[SellerType] NVARCHAR(20) NOT NULL DEFAULT (N'INTERNO')
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_Seller] PRIMARY KEY CLUSTERED ([SellerId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Seller_CompanyCode] ON [master].[Seller] ([CompanyId] ASC, [SellerCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.Supplier
-- =============================================
CREATE TABLE [master].[Supplier] (
    [SupplierId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[SupplierCode] NVARCHAR(24) NOT NULL
   ,[SupplierName] NVARCHAR(200) NOT NULL
   ,[FiscalId] NVARCHAR(30) NULL
   ,[Email] NVARCHAR(150) NULL
   ,[Phone] NVARCHAR(40) NULL
   ,[AddressLine] NVARCHAR(250) NULL
   ,[CreditLimit] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalBalance] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Supplier__4BE666B49B4E54B4] PRIMARY KEY CLUSTERED ([SupplierId])
   ,CONSTRAINT [UQ_master_Supplier] UNIQUE NONCLUSTERED ([CompanyId], [SupplierCode])
);
GO
ALTER TABLE [master].[Supplier] ADD CONSTRAINT [FK_master_Supplier_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [master].[Supplier] ADD CONSTRAINT [FK_master_Supplier_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [master].[Supplier] ADD CONSTRAINT [FK_master_Supplier_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: master.SupplierLine
-- =============================================
CREATE TABLE [master].[SupplierLine] (
    [SupplierLineId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[LineCode] NVARCHAR(20) NOT NULL
   ,[LineName] NVARCHAR(100) NOT NULL
   ,[Description] NVARCHAR(500) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_SupplierLine] PRIMARY KEY CLUSTERED ([SupplierLineId])
);
GO
 
 
-- =============================================
-- TABLE: master.TaxRetention
-- =============================================
CREATE TABLE [master].[TaxRetention] (
    [RetentionId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[RetentionCode] NVARCHAR(20) NOT NULL
   ,[Description] NVARCHAR(200) NOT NULL
   ,[RetentionType] NVARCHAR(20) NOT NULL DEFAULT (N'ISLR')
   ,[RetentionRate] DECIMAL(8,4) NOT NULL DEFAULT ((0))
   ,[CountryCode] CHAR(2) NOT NULL DEFAULT (N'VE')
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_TaxRetention] PRIMARY KEY CLUSTERED ([RetentionId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_TaxRetention_CompanyCode] ON [master].[TaxRetention] ([CompanyId] ASC, [RetentionCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.UnitOfMeasure
-- =============================================
CREATE TABLE [master].[UnitOfMeasure] (
    [UnitId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[UnitCode] NVARCHAR(20) NOT NULL
   ,[Description] NVARCHAR(100) NOT NULL
   ,[Symbol] NVARCHAR(10) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[ConversionFactor] DECIMAL(18,4) NULL
   ,CONSTRAINT [PK_UnitOfMeasure] PRIMARY KEY CLUSTERED ([UnitId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UnitOfMeasure_CompanyCode] ON [master].[UnitOfMeasure] ([CompanyId] ASC, [UnitCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: master.Warehouse
-- =============================================
CREATE TABLE [master].[Warehouse] (
    [WarehouseId] INT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL DEFAULT ((1))
   ,[BranchId] INT NULL
   ,[WarehouseCode] NVARCHAR(20) NOT NULL
   ,[Description] NVARCHAR(200) NOT NULL
   ,[WarehouseType] NVARCHAR(20) NOT NULL DEFAULT (N'PRINCIPAL')
   ,[AddressLine] NVARCHAR(250) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,CONSTRAINT [PK_Warehouse] PRIMARY KEY CLUSTERED ([WarehouseId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Warehouse_CompanyCode] ON [master].[Warehouse] ([CompanyId] ASC, [WarehouseCode] ASC) WHERE ([IsDeleted]=(0));
GO
 
 
-- =============================================
-- TABLE: pay.AcceptedPaymentMethods
-- =============================================
CREATE TABLE [pay].[AcceptedPaymentMethods] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[EmpresaId] INT NOT NULL
   ,[SucursalId] INT NOT NULL DEFAULT ((0))
   ,[PaymentMethodId] INT NOT NULL
   ,[ProviderId] INT NULL
   ,[AppliesToPOS] BIT NULL DEFAULT ((1))
   ,[AppliesToWeb] BIT NULL DEFAULT ((1))
   ,[AppliesToRestaurant] BIT NULL DEFAULT ((1))
   ,[MinAmount] DECIMAL(18,2) NULL
   ,[MaxAmount] DECIMAL(18,2) NULL
   ,[CommissionPct] DECIMAL(5,4) NULL
   ,[CommissionFixed] DECIMAL(18,2) NULL
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,[SortOrder] INT NULL DEFAULT ((0))
   ,CONSTRAINT [PK__Accepted__3214EC0731799B92] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ_AcceptedPM] UNIQUE NONCLUSTERED ([EmpresaId], [SucursalId], [PaymentMethodId], [ProviderId])
);
GO
ALTER TABLE [pay].[AcceptedPaymentMethods] ADD CONSTRAINT [FK__AcceptedP__Payme__1F398B65] FOREIGN KEY ([PaymentMethodId]) REFERENCES [pay].[PaymentMethods] ([Id]);
GO
ALTER TABLE [pay].[AcceptedPaymentMethods] ADD CONSTRAINT [FK__AcceptedP__Provi__202DAF9E] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
 
 
-- =============================================
-- TABLE: pay.CardReaderDevices
-- =============================================
CREATE TABLE [pay].[CardReaderDevices] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[EmpresaId] INT NOT NULL
   ,[SucursalId] INT NOT NULL DEFAULT ((0))
   ,[StationId] VARCHAR(50) NOT NULL
   ,[DeviceName] NVARCHAR(100) NOT NULL
   ,[DeviceType] VARCHAR(30) NOT NULL
   ,[ConnectionType] VARCHAR(30) NOT NULL
   ,[ConnectionConfig] NVARCHAR(500) NULL
   ,[ProviderId] INT NULL
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,[LastSeenAt] DATETIME NULL
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,CONSTRAINT [PK__CardRead__3214EC0759322E2B] PRIMARY KEY CLUSTERED ([Id])
);
GO
ALTER TABLE [pay].[CardReaderDevices] ADD CONSTRAINT [FK__CardReade__Provi__31583BA0] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
 
 
-- =============================================
-- TABLE: pay.CompanyPaymentConfig
-- =============================================
CREATE TABLE [pay].[CompanyPaymentConfig] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[EmpresaId] INT NOT NULL
   ,[SucursalId] INT NOT NULL DEFAULT ((0))
   ,[CountryCode] CHAR(2) NOT NULL
   ,[ProviderId] INT NOT NULL
   ,[Environment] VARCHAR(10) NULL DEFAULT ('sandbox')
   ,[ClientId] VARCHAR(500) NULL
   ,[ClientSecret] VARCHAR(500) NULL
   ,[MerchantId] VARCHAR(100) NULL
   ,[TerminalId] VARCHAR(100) NULL
   ,[IntegratorId] VARCHAR(50) NULL
   ,[CertificatePath] VARCHAR(500) NULL
   ,[ExtraConfig] NVARCHAR(MAX) NULL
   ,[AutoCapture] BIT NULL DEFAULT ((1))
   ,[AllowRefunds] BIT NULL DEFAULT ((1))
   ,[MaxRefundDays] INT NULL DEFAULT ((30))
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,[UpdatedAt] DATETIME NULL DEFAULT (getdate())
   ,CONSTRAINT [PK__CompanyP__3214EC07E4D08CC4] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ_CompanyPayConfig] UNIQUE NONCLUSTERED ([EmpresaId], [SucursalId], [ProviderId])
);
GO
ALTER TABLE [pay].[CompanyPaymentConfig] ADD CONSTRAINT [FK__CompanyPa__Provi__13C7D8B9] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
 
 
-- =============================================
-- TABLE: pay.PaymentMethods
-- =============================================
CREATE TABLE [pay].[PaymentMethods] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[Code] VARCHAR(30) NOT NULL
   ,[Name] NVARCHAR(100) NOT NULL
   ,[Category] VARCHAR(30) NOT NULL
   ,[CountryCode] CHAR(2) NULL
   ,[IconName] VARCHAR(50) NULL
   ,[RequiresGateway] BIT NULL DEFAULT ((0))
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,[SortOrder] INT NULL DEFAULT ((0))
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,CONSTRAINT [PK__PaymentM__3214EC07F896F72E] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ_PayMethod] UNIQUE NONCLUSTERED ([Code], [CountryCode])
);
GO
 
 
-- =============================================
-- TABLE: pay.PaymentProviders
-- =============================================
CREATE TABLE [pay].[PaymentProviders] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[Code] VARCHAR(30) NOT NULL
   ,[Name] NVARCHAR(150) NOT NULL
   ,[CountryCode] CHAR(2) NULL
   ,[ProviderType] VARCHAR(30) NOT NULL
   ,[BaseUrlSandbox] VARCHAR(500) NULL
   ,[BaseUrlProd] VARCHAR(500) NULL
   ,[AuthType] VARCHAR(30) NULL
   ,[DocsUrl] VARCHAR(500) NULL
   ,[LogoUrl] VARCHAR(500) NULL
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,CONSTRAINT [PK__PaymentP__3214EC0780325EB3] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ__PaymentP__A25C5AA74825AB67] UNIQUE NONCLUSTERED ([Code])
);
GO
 
 
-- =============================================
-- TABLE: pay.ProviderCapabilities
-- =============================================
CREATE TABLE [pay].[ProviderCapabilities] (
    [Id] INT IDENTITY(1,1) NOT NULL
   ,[ProviderId] INT NOT NULL
   ,[Capability] VARCHAR(50) NOT NULL
   ,[PaymentMethod] VARCHAR(30) NULL
   ,[EndpointPath] VARCHAR(200) NULL
   ,[HttpMethod] VARCHAR(10) NULL DEFAULT ('POST')
   ,[IsActive] BIT NULL DEFAULT ((1))
   ,CONSTRAINT [PK__Provider__3214EC070027A5EF] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ_ProvCap] UNIQUE NONCLUSTERED ([ProviderId], [Capability], [PaymentMethod])
);
GO
ALTER TABLE [pay].[ProviderCapabilities] ADD CONSTRAINT [FK__ProviderC__Provi__0D1ADB2A] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
 
 
-- =============================================
-- TABLE: pay.ReconciliationBatches
-- =============================================
CREATE TABLE [pay].[ReconciliationBatches] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL
   ,[EmpresaId] INT NOT NULL
   ,[ProviderId] INT NOT NULL
   ,[DateFrom] DATE NOT NULL
   ,[DateTo] DATE NOT NULL
   ,[TotalTransactions] INT NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,2) NULL DEFAULT ((0))
   ,[MatchedCount] INT NULL DEFAULT ((0))
   ,[UnmatchedCount] INT NULL DEFAULT ((0))
   ,[Status] VARCHAR(20) NULL DEFAULT ('PENDING')
   ,[ResultJson] NVARCHAR(MAX) NULL
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,[CompletedAt] DATETIME NULL
   ,[UserId] VARCHAR(20) NULL
   ,CONSTRAINT [PK__Reconcil__3214EC0762BAD74E] PRIMARY KEY CLUSTERED ([Id])
);
GO
ALTER TABLE [pay].[ReconciliationBatches] ADD CONSTRAINT [FK__Reconcili__Provi__27CED166] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
 
 
-- =============================================
-- TABLE: pay.Transactions
-- =============================================
CREATE TABLE [pay].[Transactions] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL
   ,[TransactionUUID] VARCHAR(36) NOT NULL
   ,[EmpresaId] INT NOT NULL
   ,[SucursalId] INT NOT NULL DEFAULT ((0))
   ,[SourceType] VARCHAR(30) NOT NULL
   ,[SourceId] INT NULL
   ,[SourceNumber] VARCHAR(50) NULL
   ,[PaymentMethodCode] VARCHAR(30) NOT NULL
   ,[ProviderId] INT NULL
   ,[Currency] VARCHAR(3) NOT NULL
   ,[Amount] DECIMAL(18,2) NOT NULL
   ,[CommissionAmount] DECIMAL(18,2) NULL
   ,[NetAmount] DECIMAL(18,2) NULL
   ,[ExchangeRate] DECIMAL(18,6) NULL
   ,[AmountInBase] DECIMAL(18,2) NULL
   ,[TrxType] VARCHAR(20) NOT NULL
   ,[Status] VARCHAR(20) NOT NULL DEFAULT ('PENDING')
   ,[GatewayTrxId] VARCHAR(100) NULL
   ,[GatewayAuthCode] VARCHAR(50) NULL
   ,[GatewayResponse] NVARCHAR(MAX) NULL
   ,[GatewayMessage] NVARCHAR(500) NULL
   ,[CardLastFour] VARCHAR(4) NULL
   ,[CardBrand] VARCHAR(20) NULL
   ,[MobileNumber] VARCHAR(20) NULL
   ,[BankCode] VARCHAR(10) NULL
   ,[PaymentRef] VARCHAR(50) NULL
   ,[IsReconciled] BIT NULL DEFAULT ((0))
   ,[ReconciledAt] DATETIME NULL
   ,[ReconciliationId] BIGINT NULL
   ,[StationId] VARCHAR(50) NULL
   ,[CashierId] VARCHAR(20) NULL
   ,[IpAddress] VARCHAR(45) NULL
   ,[UserAgent] VARCHAR(500) NULL
   ,[Notes] NVARCHAR(500) NULL
   ,[CreatedAt] DATETIME NULL DEFAULT (getdate())
   ,[UpdatedAt] DATETIME NULL DEFAULT (getdate())
   ,CONSTRAINT [PK__Transact__3214EC07FD360EB7] PRIMARY KEY CLUSTERED ([Id])
   ,CONSTRAINT [UQ__Transact__21899633E7DE43BA] UNIQUE NONCLUSTERED ([TransactionUUID])
);
GO
ALTER TABLE [pay].[Transactions] ADD CONSTRAINT [FK__Transacti__Provi__3805392F] FOREIGN KEY ([ProviderId]) REFERENCES [pay].[PaymentProviders] ([Id]);
GO
CREATE NONCLUSTERED INDEX [IX_PayTrx_Source] ON [pay].[Transactions] ([SourceType] ASC, [SourceId] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_PayTrx_Status] ON [pay].[Transactions] ([Status] ASC, [CreatedAt] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_PayTrx_Recon] ON [pay].[Transactions] ([IsReconciled] ASC, [ProviderId] ASC);
GO
 
 
-- =============================================
-- TABLE: pos.FiscalCorrelative
-- =============================================
CREATE TABLE [pos].[FiscalCorrelative] (
    [FiscalCorrelativeId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CorrelativeType] NVARCHAR(20) NOT NULL DEFAULT (N'FACTURA')
   ,[CashRegisterCode] NVARCHAR(10) NOT NULL DEFAULT (N'GLOBAL')
   ,[SerialFiscal] NVARCHAR(40) NOT NULL
   ,[CurrentNumber] INT NOT NULL DEFAULT ((0))
   ,[Description] NVARCHAR(200) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__FiscalCo__2D9BC5D292E43FC7] PRIMARY KEY CLUSTERED ([FiscalCorrelativeId])
   ,CONSTRAINT [UQ_pos_FiscalCorrelative] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [CorrelativeType], [CashRegisterCode])
);
GO
ALTER TABLE [pos].[FiscalCorrelative] ADD CONSTRAINT [FK_pos_FiscalCorrelative_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [pos].[FiscalCorrelative] ADD CONSTRAINT [FK_pos_FiscalCorrelative_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [pos].[FiscalCorrelative] ADD CONSTRAINT [FK_pos_FiscalCorrelative_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [pos].[FiscalCorrelative] ADD CONSTRAINT [FK_pos_FiscalCorrelative_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_pos_FiscalCorrelative_Search] ON [pos].[FiscalCorrelative] ([CompanyId] ASC, [BranchId] ASC, [CorrelativeType] ASC, [CashRegisterCode] ASC, [IsActive] ASC);
GO
 
 
-- =============================================
-- TABLE: pos.SaleTicket
-- =============================================
CREATE TABLE [pos].[SaleTicket] (
    [SaleTicketId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[InvoiceNumber] NVARCHAR(20) NOT NULL
   ,[CashRegisterCode] NVARCHAR(10) NOT NULL
   ,[SoldByUserId] INT NULL
   ,[CustomerId] BIGINT NULL
   ,[CustomerCode] NVARCHAR(24) NULL
   ,[CustomerName] NVARCHAR(200) NULL
   ,[CustomerFiscalId] NVARCHAR(30) NULL
   ,[PriceTier] NVARCHAR(20) NOT NULL DEFAULT ('DETAIL')
   ,[PaymentMethod] NVARCHAR(50) NULL
   ,[FiscalPayload] NVARCHAR(MAX) NULL
   ,[WaitTicketId] BIGINT NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[SoldAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__SaleTick__449DB9898E7E902E] PRIMARY KEY CLUSTERED ([SaleTicketId])
   ,CONSTRAINT [UQ_pos_SaleTicket] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [InvoiceNumber])
);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [master].[Customer] ([CustomerId]);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_WaitTicket] FOREIGN KEY ([WaitTicketId]) REFERENCES [pos].[WaitTicket] ([WaitTicketId]);
GO
ALTER TABLE [pos].[SaleTicket] ADD CONSTRAINT [FK_pos_SaleTicket_SoldBy] FOREIGN KEY ([SoldByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: pos.SaleTicketLine
-- =============================================
CREATE TABLE [pos].[SaleTicketLine] (
    [SaleTicketLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[SaleTicketId] BIGINT NOT NULL
   ,[LineNumber] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[ProductId] BIGINT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[ProductName] NVARCHAR(250) NOT NULL
   ,[Quantity] DECIMAL(10,3) NOT NULL
   ,[UnitPrice] DECIMAL(18,2) NOT NULL
   ,[DiscountAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxCode] NVARCHAR(30) NOT NULL
   ,[TaxRate] DECIMAL(9,4) NOT NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL
   ,[TaxAmount] DECIMAL(18,2) NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[SupervisorApprovalId] BIGINT NULL
   ,[LineMetaJson] NVARCHAR(1000) NULL
   ,CONSTRAINT [PK__SaleTick__222C8A923747D168] PRIMARY KEY CLUSTERED ([SaleTicketLineId])
   ,CONSTRAINT [UQ_pos_SaleTicketLine] UNIQUE NONCLUSTERED ([SaleTicketId], [LineNumber])
);
GO
ALTER TABLE [pos].[SaleTicketLine] ADD CONSTRAINT [FK_pos_SaleTicketLine_SaleTicket] FOREIGN KEY ([SaleTicketId]) REFERENCES [pos].[SaleTicket] ([SaleTicketId]) ON DELETE CASCADE;
GO
ALTER TABLE [pos].[SaleTicketLine] ADD CONSTRAINT [FK_pos_SaleTicketLine_Product] FOREIGN KEY ([ProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
ALTER TABLE [pos].[SaleTicketLine] ADD CONSTRAINT [FK_pos_SaleTicketLine_Tax] FOREIGN KEY ([CountryCode], [TaxCode]) REFERENCES [fiscal].[TaxRate] ([CountryCode], [TaxCode]);
GO
 
 
-- =============================================
-- TABLE: pos.WaitTicket
-- =============================================
CREATE TABLE [pos].[WaitTicket] (
    [WaitTicketId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[CashRegisterCode] NVARCHAR(10) NOT NULL
   ,[StationName] NVARCHAR(50) NULL
   ,[CreatedByUserId] INT NULL
   ,[CustomerId] BIGINT NULL
   ,[CustomerCode] NVARCHAR(24) NULL
   ,[CustomerName] NVARCHAR(200) NULL
   ,[CustomerFiscalId] NVARCHAR(30) NULL
   ,[PriceTier] NVARCHAR(20) NOT NULL DEFAULT ('DETAIL')
   ,[Reason] NVARCHAR(200) NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[DiscountAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT ('WAITING')
   ,[RecoveredByUserId] INT NULL
   ,[RecoveredAtRegister] NVARCHAR(10) NULL
   ,[RecoveredAt] DATETIME2(0) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__WaitTick__856DCDD639840415] PRIMARY KEY CLUSTERED ([WaitTicketId])
   ,CONSTRAINT [CK_pos_WaitTicket_Status] CHECK ([Status]='VOIDED' OR [Status]='RECOVERED' OR [Status]='WAITING')
);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [master].[Customer] ([CustomerId]);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_RecoveredBy] FOREIGN KEY ([RecoveredByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [pos].[WaitTicket] ADD CONSTRAINT [FK_pos_WaitTicket_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
 
 
-- =============================================
-- TABLE: pos.WaitTicketLine
-- =============================================
CREATE TABLE [pos].[WaitTicketLine] (
    [WaitTicketLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[WaitTicketId] BIGINT NOT NULL
   ,[LineNumber] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[ProductId] BIGINT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[ProductName] NVARCHAR(250) NOT NULL
   ,[Quantity] DECIMAL(10,3) NOT NULL
   ,[UnitPrice] DECIMAL(18,2) NOT NULL
   ,[DiscountAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxCode] NVARCHAR(30) NOT NULL
   ,[TaxRate] DECIMAL(9,4) NOT NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL
   ,[TaxAmount] DECIMAL(18,2) NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[SupervisorApprovalId] BIGINT NULL
   ,[LineMetaJson] NVARCHAR(1000) NULL
   ,CONSTRAINT [PK__WaitTick__FA990A06B5A4C387] PRIMARY KEY CLUSTERED ([WaitTicketLineId])
   ,CONSTRAINT [UQ_pos_WaitTicketLine] UNIQUE NONCLUSTERED ([WaitTicketId], [LineNumber])
);
GO
ALTER TABLE [pos].[WaitTicketLine] ADD CONSTRAINT [FK_pos_WaitTicketLine_WaitTicket] FOREIGN KEY ([WaitTicketId]) REFERENCES [pos].[WaitTicket] ([WaitTicketId]) ON DELETE CASCADE;
GO
ALTER TABLE [pos].[WaitTicketLine] ADD CONSTRAINT [FK_pos_WaitTicketLine_Product] FOREIGN KEY ([ProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
ALTER TABLE [pos].[WaitTicketLine] ADD CONSTRAINT [FK_pos_WaitTicketLine_Tax] FOREIGN KEY ([CountryCode], [TaxCode]) REFERENCES [fiscal].[TaxRate] ([CountryCode], [TaxCode]);
GO
 
 
-- =============================================
-- TABLE: rest.DiningTable
-- =============================================
CREATE TABLE [rest].[DiningTable] (
    [DiningTableId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[TableNumber] NVARCHAR(20) NOT NULL
   ,[TableName] NVARCHAR(100) NULL
   ,[Capacity] INT NOT NULL DEFAULT ((4))
   ,[EnvironmentCode] NVARCHAR(20) NULL
   ,[EnvironmentName] NVARCHAR(80) NULL
   ,[PositionX] INT NULL
   ,[PositionY] INT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__DiningTa__1D0E7D8D9142D6FC] PRIMARY KEY CLUSTERED ([DiningTableId])
   ,CONSTRAINT [UQ_rest_DiningTable] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [TableNumber])
);
GO
ALTER TABLE [rest].[DiningTable] ADD CONSTRAINT [FK_rest_DiningTable_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[DiningTable] ADD CONSTRAINT [FK_rest_DiningTable_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[DiningTable] ADD CONSTRAINT [FK_rest_DiningTable_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[DiningTable] ADD CONSTRAINT [FK_rest_DiningTable_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_rest_DiningTable_Search] ON [rest].[DiningTable] ([CompanyId] ASC, [BranchId] ASC, [IsActive] ASC, [EnvironmentCode] ASC, [TableNumber] ASC);
GO
 
 
-- =============================================
-- TABLE: rest.MenuCategory
-- =============================================
CREATE TABLE [rest].[MenuCategory] (
    [MenuCategoryId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CategoryCode] NVARCHAR(30) NOT NULL
   ,[CategoryName] NVARCHAR(120) NOT NULL
   ,[DescriptionText] NVARCHAR(250) NULL
   ,[ColorHex] NVARCHAR(10) NULL
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__MenuCate__5AF617FB9E51BA18] PRIMARY KEY CLUSTERED ([MenuCategoryId])
   ,CONSTRAINT [UQ_rest_MenuCategory] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [CategoryCode])
);
GO
ALTER TABLE [rest].[MenuCategory] ADD CONSTRAINT [FK_rest_MenuCategory_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[MenuCategory] ADD CONSTRAINT [FK_rest_MenuCategory_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[MenuCategory] ADD CONSTRAINT [FK_rest_MenuCategory_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[MenuCategory] ADD CONSTRAINT [FK_rest_MenuCategory_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: rest.MenuComponent
-- =============================================
CREATE TABLE [rest].[MenuComponent] (
    [MenuComponentId] BIGINT IDENTITY(1,1) NOT NULL
   ,[MenuProductId] BIGINT NOT NULL
   ,[ComponentName] NVARCHAR(120) NOT NULL
   ,[IsRequired] BIT NOT NULL DEFAULT ((0))
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__MenuComp__409921A9BC6DE1A0] PRIMARY KEY CLUSTERED ([MenuComponentId])
);
GO
ALTER TABLE [rest].[MenuComponent] ADD CONSTRAINT [FK_rest_MenuComponent_Product] FOREIGN KEY ([MenuProductId]) REFERENCES [rest].[MenuProduct] ([MenuProductId]) ON DELETE CASCADE;
GO
 
 
-- =============================================
-- TABLE: rest.MenuEnvironment
-- =============================================
CREATE TABLE [rest].[MenuEnvironment] (
    [MenuEnvironmentId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[EnvironmentCode] NVARCHAR(30) NOT NULL
   ,[EnvironmentName] NVARCHAR(120) NOT NULL
   ,[ColorHex] NVARCHAR(10) NULL
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__MenuEnvi__AE8659DFECFC3BEE] PRIMARY KEY CLUSTERED ([MenuEnvironmentId])
   ,CONSTRAINT [UQ_rest_MenuEnvironment] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [EnvironmentCode])
);
GO
ALTER TABLE [rest].[MenuEnvironment] ADD CONSTRAINT [FK_rest_MenuEnvironment_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[MenuEnvironment] ADD CONSTRAINT [FK_rest_MenuEnvironment_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[MenuEnvironment] ADD CONSTRAINT [FK_rest_MenuEnvironment_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[MenuEnvironment] ADD CONSTRAINT [FK_rest_MenuEnvironment_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: rest.MenuOption
-- =============================================
CREATE TABLE [rest].[MenuOption] (
    [MenuOptionId] BIGINT IDENTITY(1,1) NOT NULL
   ,[MenuComponentId] BIGINT NOT NULL
   ,[OptionName] NVARCHAR(120) NOT NULL
   ,[ExtraPrice] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[SortOrder] INT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__MenuOpti__C9B7746358B5461F] PRIMARY KEY CLUSTERED ([MenuOptionId])
);
GO
ALTER TABLE [rest].[MenuOption] ADD CONSTRAINT [FK_rest_MenuOption_Component] FOREIGN KEY ([MenuComponentId]) REFERENCES [rest].[MenuComponent] ([MenuComponentId]) ON DELETE CASCADE;
GO
 
 
-- =============================================
-- TABLE: rest.MenuProduct
-- =============================================
CREATE TABLE [rest].[MenuProduct] (
    [MenuProductId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[ProductCode] NVARCHAR(40) NOT NULL
   ,[ProductName] NVARCHAR(200) NOT NULL
   ,[DescriptionText] NVARCHAR(500) NULL
   ,[MenuCategoryId] BIGINT NULL
   ,[PriceAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[EstimatedCost] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxRatePercent] DECIMAL(9,4) NOT NULL DEFAULT ((16))
   ,[IsComposite] BIT NOT NULL DEFAULT ((0))
   ,[PrepMinutes] INT NOT NULL DEFAULT ((0))
   ,[ImageUrl] NVARCHAR(500) NULL
   ,[IsDailySuggestion] BIT NOT NULL DEFAULT ((0))
   ,[IsAvailable] BIT NOT NULL DEFAULT ((1))
   ,[InventoryProductId] BIGINT NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__MenuProd__E7D522C382420064] PRIMARY KEY CLUSTERED ([MenuProductId])
   ,CONSTRAINT [UQ_rest_MenuProduct] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [ProductCode])
);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_Category] FOREIGN KEY ([MenuCategoryId]) REFERENCES [rest].[MenuCategory] ([MenuCategoryId]);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_InventoryProduct] FOREIGN KEY ([InventoryProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[MenuProduct] ADD CONSTRAINT [FK_rest_MenuProduct_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_rest_MenuProduct_Search] ON [rest].[MenuProduct] ([CompanyId] ASC, [BranchId] ASC, [IsActive] ASC, [IsAvailable] ASC, [ProductCode] ASC, [ProductName] ASC);
GO
 
 
-- =============================================
-- TABLE: rest.MenuRecipe
-- =============================================
CREATE TABLE [rest].[MenuRecipe] (
    [MenuRecipeId] BIGINT IDENTITY(1,1) NOT NULL
   ,[MenuProductId] BIGINT NOT NULL
   ,[IngredientProductId] BIGINT NOT NULL
   ,[Quantity] DECIMAL(18,4) NOT NULL
   ,[UnitCode] NVARCHAR(20) NULL
   ,[Notes] NVARCHAR(200) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__MenuReci__B7F43C8935615572] PRIMARY KEY CLUSTERED ([MenuRecipeId])
);
GO
ALTER TABLE [rest].[MenuRecipe] ADD CONSTRAINT [FK_rest_MenuRecipe_MenuProduct] FOREIGN KEY ([MenuProductId]) REFERENCES [rest].[MenuProduct] ([MenuProductId]) ON DELETE CASCADE;
GO
ALTER TABLE [rest].[MenuRecipe] ADD CONSTRAINT [FK_rest_MenuRecipe_Ingredient] FOREIGN KEY ([IngredientProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
 
 
-- =============================================
-- TABLE: rest.OrderTicket
-- =============================================
CREATE TABLE [rest].[OrderTicket] (
    [OrderTicketId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[TableNumber] NVARCHAR(20) NULL
   ,[OpenedByUserId] INT NULL
   ,[ClosedByUserId] INT NULL
   ,[CustomerName] NVARCHAR(200) NULL
   ,[CustomerFiscalId] NVARCHAR(30) NULL
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT ('OPEN')
   ,[NetAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[OpenedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[ClosedAt] DATETIME2(0) NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__OrderTic__2E41818CDBDF45BE] PRIMARY KEY CLUSTERED ([OrderTicketId])
   ,CONSTRAINT [CK_rest_OrderTicket_Status] CHECK ([Status]='VOIDED' OR [Status]='CLOSED' OR [Status]='SENT' OR [Status]='OPEN')
);
GO
ALTER TABLE [rest].[OrderTicket] ADD CONSTRAINT [FK_rest_OrderTicket_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[OrderTicket] ADD CONSTRAINT [FK_rest_OrderTicket_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[OrderTicket] ADD CONSTRAINT [FK_rest_OrderTicket_Country] FOREIGN KEY ([CountryCode]) REFERENCES [cfg].[Country] ([CountryCode]);
GO
ALTER TABLE [rest].[OrderTicket] ADD CONSTRAINT [FK_rest_OrderTicket_OpenedBy] FOREIGN KEY ([OpenedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[OrderTicket] ADD CONSTRAINT [FK_rest_OrderTicket_ClosedBy] FOREIGN KEY ([ClosedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
 
 
-- =============================================
-- TABLE: rest.OrderTicketLine
-- =============================================
CREATE TABLE [rest].[OrderTicketLine] (
    [OrderTicketLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[OrderTicketId] BIGINT NOT NULL
   ,[LineNumber] INT NOT NULL
   ,[CountryCode] CHAR(2) NOT NULL
   ,[ProductId] BIGINT NULL
   ,[ProductCode] NVARCHAR(80) NOT NULL
   ,[ProductName] NVARCHAR(250) NOT NULL
   ,[Quantity] DECIMAL(10,3) NOT NULL
   ,[UnitPrice] DECIMAL(18,2) NOT NULL
   ,[TaxCode] NVARCHAR(30) NOT NULL
   ,[TaxRate] DECIMAL(9,4) NOT NULL
   ,[NetAmount] DECIMAL(18,2) NOT NULL
   ,[TaxAmount] DECIMAL(18,2) NOT NULL
   ,[TotalAmount] DECIMAL(18,2) NOT NULL
   ,[Notes] NVARCHAR(300) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[SupervisorApprovalId] BIGINT NULL
   ,CONSTRAINT [PK__OrderTic__6AE1AA44EB342D62] PRIMARY KEY CLUSTERED ([OrderTicketLineId])
   ,CONSTRAINT [UQ_rest_OrderTicketLine] UNIQUE NONCLUSTERED ([OrderTicketId], [LineNumber])
);
GO
ALTER TABLE [rest].[OrderTicketLine] ADD CONSTRAINT [FK_rest_OrderTicketLine_Order] FOREIGN KEY ([OrderTicketId]) REFERENCES [rest].[OrderTicket] ([OrderTicketId]) ON DELETE CASCADE;
GO
ALTER TABLE [rest].[OrderTicketLine] ADD CONSTRAINT [FK_rest_OrderTicketLine_Product] FOREIGN KEY ([ProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
ALTER TABLE [rest].[OrderTicketLine] ADD CONSTRAINT [FK_rest_OrderTicketLine_Tax] FOREIGN KEY ([CountryCode], [TaxCode]) REFERENCES [fiscal].[TaxRate] ([CountryCode], [TaxCode]);
GO
 
 
-- =============================================
-- TABLE: rest.Purchase
-- =============================================
CREATE TABLE [rest].[Purchase] (
    [PurchaseId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[PurchaseNumber] NVARCHAR(30) NOT NULL
   ,[SupplierId] BIGINT NULL
   ,[PurchaseDate] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT (N'PENDIENTE')
   ,[SubtotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TaxAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[TotalAmount] DECIMAL(18,2) NOT NULL DEFAULT ((0))
   ,[Notes] NVARCHAR(500) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Purchase__6B0A6BBE44BB7C6A] PRIMARY KEY CLUSTERED ([PurchaseId])
   ,CONSTRAINT [UQ_rest_Purchase] UNIQUE NONCLUSTERED ([CompanyId], [BranchId], [PurchaseNumber])
);
GO
ALTER TABLE [rest].[Purchase] ADD CONSTRAINT [FK_rest_Purchase_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [rest].[Purchase] ADD CONSTRAINT [FK_rest_Purchase_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
ALTER TABLE [rest].[Purchase] ADD CONSTRAINT [FK_rest_Purchase_Supplier] FOREIGN KEY ([SupplierId]) REFERENCES [master].[Supplier] ([SupplierId]);
GO
ALTER TABLE [rest].[Purchase] ADD CONSTRAINT [FK_rest_Purchase_CreatedBy] FOREIGN KEY ([CreatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [rest].[Purchase] ADD CONSTRAINT [FK_rest_Purchase_UpdatedBy] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [sec].[User] ([UserId]);
GO
CREATE NONCLUSTERED INDEX [IX_rest_Purchase_Search] ON [rest].[Purchase] ([CompanyId] ASC, [BranchId] ASC, [PurchaseDate] DESC, [Status] ASC);
GO
 
 
-- =============================================
-- TABLE: rest.PurchaseLine
-- =============================================
CREATE TABLE [rest].[PurchaseLine] (
    [PurchaseLineId] BIGINT IDENTITY(1,1) NOT NULL
   ,[PurchaseId] BIGINT NOT NULL
   ,[IngredientProductId] BIGINT NULL
   ,[DescriptionText] NVARCHAR(200) NOT NULL
   ,[Quantity] DECIMAL(18,4) NOT NULL
   ,[UnitPrice] DECIMAL(18,2) NOT NULL
   ,[TaxRatePercent] DECIMAL(9,4) NOT NULL
   ,[SubtotalAmount] DECIMAL(18,2) NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Purchase__8BC954DE166A7ECE] PRIMARY KEY CLUSTERED ([PurchaseLineId])
);
GO
ALTER TABLE [rest].[PurchaseLine] ADD CONSTRAINT [FK_rest_PurchaseLine_Purchase] FOREIGN KEY ([PurchaseId]) REFERENCES [rest].[Purchase] ([PurchaseId]) ON DELETE CASCADE;
GO
ALTER TABLE [rest].[PurchaseLine] ADD CONSTRAINT [FK_rest_PurchaseLine_Ingredient] FOREIGN KEY ([IngredientProductId]) REFERENCES [master].[Product] ([ProductId]);
GO
 
 
-- =============================================
-- TABLE: sec.AuthIdentity
-- =============================================
CREATE TABLE [sec].[AuthIdentity] (
    [UserCode] NVARCHAR(10) NOT NULL
   ,[Email] NVARCHAR(254) NULL
   ,[EmailNormalized] NVARCHAR(254) NULL
   ,[EmailVerifiedAtUtc] DATETIME2(0) NULL
   ,[IsRegistrationPending] BIT NOT NULL DEFAULT ((0))
   ,[FailedLoginCount] INT NOT NULL DEFAULT ((0))
   ,[LastFailedLoginAtUtc] DATETIME2(0) NULL
   ,[LastFailedLoginIp] NVARCHAR(64) NULL
   ,[LockoutUntilUtc] DATETIME2(0) NULL
   ,[LastLoginAtUtc] DATETIME2(0) NULL
   ,[PasswordChangedAtUtc] DATETIME2(0) NULL
   ,[CreatedAtUtc] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAtUtc] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_sec_AuthIdentity] PRIMARY KEY CLUSTERED ([UserCode])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_sec_AuthIdentity_EmailNormalized] ON [sec].[AuthIdentity] ([EmailNormalized] ASC) WHERE ([EmailNormalized] IS NOT NULL);
GO
 
 
-- =============================================
-- TABLE: sec.AuthToken
-- =============================================
CREATE TABLE [sec].[AuthToken] (
    [TokenId] BIGINT IDENTITY(1,1) NOT NULL
   ,[UserCode] NVARCHAR(10) NOT NULL
   ,[TokenType] VARCHAR(32) NOT NULL
   ,[TokenHash] CHAR(64) NOT NULL
   ,[EmailNormalized] NVARCHAR(254) NULL
   ,[ExpiresAtUtc] DATETIME2(0) NOT NULL
   ,[ConsumedAtUtc] DATETIME2(0) NULL
   ,[MetaIp] NVARCHAR(64) NULL
   ,[MetaUserAgent] NVARCHAR(256) NULL
   ,[CreatedAtUtc] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__AuthToke__658FEEEAF5F6B11B] PRIMARY KEY CLUSTERED ([TokenId])
   ,CONSTRAINT [CK_sec_AuthToken_Type] CHECK ([TokenType]='RESET_PASSWORD' OR [TokenType]='VERIFY_EMAIL')
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_sec_AuthToken_TokenHash] ON [sec].[AuthToken] ([TokenHash] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_sec_AuthToken_UserCode_Type_Expires] ON [sec].[AuthToken] ([UserCode] ASC, [TokenType] ASC, [ExpiresAtUtc] ASC, [ConsumedAtUtc] ASC);
GO
 
 
-- =============================================
-- TABLE: sec.Role
-- =============================================
CREATE TABLE [sec].[Role] (
    [RoleId] INT IDENTITY(1,1) NOT NULL
   ,[RoleCode] NVARCHAR(40) NOT NULL
   ,[RoleName] NVARCHAR(120) NOT NULL
   ,[IsSystem] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__Role__8AFACE1A70D1EAD6] PRIMARY KEY CLUSTERED ([RoleId])
   ,CONSTRAINT [UQ_sec_Role_RoleCode] UNIQUE NONCLUSTERED ([RoleCode])
);
GO
 
 
-- =============================================
-- TABLE: sec.SupervisorBiometricCredential
-- =============================================
CREATE TABLE [sec].[SupervisorBiometricCredential] (
    [BiometricCredentialId] BIGINT IDENTITY(1,1) NOT NULL
   ,[SupervisorUserCode] NVARCHAR(10) NOT NULL
   ,[CredentialHash] CHAR(64) NOT NULL
   ,[CredentialId] NVARCHAR(512) NOT NULL
   ,[CredentialLabel] NVARCHAR(120) NULL
   ,[DeviceInfo] NVARCHAR(300) NULL
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[LastValidatedAtUtc] DATETIME2(3) NULL
   ,[CreatedAtUtc] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAtUtc] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserCode] NVARCHAR(10) NULL
   ,[UpdatedByUserCode] NVARCHAR(10) NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Supervis__49A9DCB84B7E9C44] PRIMARY KEY CLUSTERED ([BiometricCredentialId])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_SupervisorBiometricCredential_UserHash] ON [sec].[SupervisorBiometricCredential] ([SupervisorUserCode] ASC, [CredentialHash] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_SupervisorBiometricCredential_Active] ON [sec].[SupervisorBiometricCredential] ([SupervisorUserCode] ASC, [IsActive] ASC, [LastValidatedAtUtc] DESC);
GO
 
 
-- =============================================
-- TABLE: sec.SupervisorOverride
-- =============================================
CREATE TABLE [sec].[SupervisorOverride] (
    [OverrideId] BIGINT IDENTITY(1,1) NOT NULL
   ,[ModuleCode] NVARCHAR(32) NOT NULL
   ,[ActionCode] NVARCHAR(64) NOT NULL
   ,[Status] NVARCHAR(20) NOT NULL DEFAULT (N'APPROVED')
   ,[CompanyId] INT NULL
   ,[BranchId] INT NULL
   ,[RequestedByUserCode] NVARCHAR(50) NULL
   ,[SupervisorUserCode] NVARCHAR(50) NOT NULL
   ,[Reason] NVARCHAR(300) NOT NULL
   ,[PayloadJson] NVARCHAR(MAX) NULL
   ,[SourceDocumentId] BIGINT NULL
   ,[SourceLineId] BIGINT NULL
   ,[ReversalLineId] BIGINT NULL
   ,[ApprovedAtUtc] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[ConsumedAtUtc] DATETIME2(3) NULL
   ,[ConsumedByUserCode] NVARCHAR(50) NULL
   ,[CreatedAt] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(3) NOT NULL DEFAULT (sysutcdatetime())
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__Supervis__37B512242387C85B] PRIMARY KEY CLUSTERED ([OverrideId])
);
GO
CREATE NONCLUSTERED INDEX [IX_SupervisorOverride_Status] ON [sec].[SupervisorOverride] ([Status] ASC, [ModuleCode] ASC, [ActionCode] ASC, [ApprovedAtUtc] DESC);
GO
CREATE NONCLUSTERED INDEX [IX_SupervisorOverride_Source] ON [sec].[SupervisorOverride] ([ModuleCode] ASC, [ActionCode] ASC, [SourceDocumentId] ASC, [SourceLineId] ASC);
GO
 
 
-- =============================================
-- TABLE: sec.User
-- =============================================
CREATE TABLE [sec].[User] (
    [UserId] INT IDENTITY(1,1) NOT NULL
   ,[UserCode] NVARCHAR(40) NOT NULL
   ,[UserName] NVARCHAR(150) NOT NULL
   ,[PasswordHash] NVARCHAR(255) NULL
   ,[Email] NVARCHAR(150) NULL
   ,[IsAdmin] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[LastLoginAt] DATETIME2(0) NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[IsDeleted] BIT NOT NULL DEFAULT ((0))
   ,[DeletedAt] DATETIME2(0) NULL
   ,[DeletedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,[UserType] NVARCHAR(10) NULL
   ,[CanUpdate] BIT NOT NULL DEFAULT ((1))
   ,[CanCreate] BIT NOT NULL DEFAULT ((1))
   ,[CanDelete] BIT NOT NULL DEFAULT ((0))
   ,[IsCreator] BIT NOT NULL DEFAULT ((0))
   ,[CanChangePwd] BIT NOT NULL DEFAULT ((1))
   ,[CanChangePrice] BIT NOT NULL DEFAULT ((0))
   ,[CanGiveCredit] BIT NOT NULL DEFAULT ((0))
   ,[Avatar] NVARCHAR(MAX) NULL
   ,CONSTRAINT [PK__User__1788CC4CBA828C16] PRIMARY KEY CLUSTERED ([UserId])
   ,CONSTRAINT [UQ_sec_User_UserCode] UNIQUE NONCLUSTERED ([UserCode])
);
GO
 
 
-- =============================================
-- TABLE: sec.UserCompanyAccess
-- =============================================
CREATE TABLE [sec].[UserCompanyAccess] (
    [UserCompanyAccessId] BIGINT IDENTITY(1,1) NOT NULL
   ,[CodUsuario] NVARCHAR(50) NOT NULL
   ,[CompanyId] INT NOT NULL
   ,[BranchId] INT NOT NULL
   ,[IsDefault] BIT NOT NULL DEFAULT ((0))
   ,[IsActive] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(7) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(7) NOT NULL DEFAULT (sysutcdatetime())
   ,[CreatedByUserId] INT NULL
   ,[UpdatedByUserId] INT NULL
   ,[RowVer] TIMESTAMP NOT NULL
   ,CONSTRAINT [PK__UserComp__243F7E6FFDEDF774] PRIMARY KEY CLUSTERED ([UserCompanyAccessId])
);
GO
ALTER TABLE [sec].[UserCompanyAccess] ADD CONSTRAINT [FK_sec_UserCompanyAccess_Company] FOREIGN KEY ([CompanyId]) REFERENCES [cfg].[Company] ([CompanyId]);
GO
ALTER TABLE [sec].[UserCompanyAccess] ADD CONSTRAINT [FK_sec_UserCompanyAccess_Branch] FOREIGN KEY ([BranchId]) REFERENCES [cfg].[Branch] ([BranchId]);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_sec_UserCompanyAccess_CodEmpresaSucursal] ON [sec].[UserCompanyAccess] ([CodUsuario] ASC, [CompanyId] ASC, [BranchId] ASC);
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_sec_UserCompanyAccess_DefaultPorUsuario] ON [sec].[UserCompanyAccess] ([CodUsuario] ASC) WHERE ([IsDefault]=(1) AND [IsActive]=(1));
GO
CREATE NONCLUSTERED INDEX [IX_sec_UserCompanyAccess_CompanyBranch] ON [sec].[UserCompanyAccess] ([CompanyId] ASC, [BranchId] ASC, [IsActive] ASC);
GO
 
 
-- =============================================
-- TABLE: sec.UserModuleAccess
-- =============================================
CREATE TABLE [sec].[UserModuleAccess] (
    [AccessId] INT IDENTITY(1,1) NOT NULL
   ,[UserCode] NVARCHAR(20) NOT NULL
   ,[ModuleCode] NVARCHAR(60) NOT NULL
   ,[IsAllowed] BIT NOT NULL DEFAULT ((1))
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,[UpdatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK_UserModuleAccess] PRIMARY KEY CLUSTERED ([AccessId])
   ,CONSTRAINT [UQ_UserModuleAccess] UNIQUE NONCLUSTERED ([UserCode], [ModuleCode])
);
GO
 
 
-- =============================================
-- TABLE: sec.UserRole
-- =============================================
CREATE TABLE [sec].[UserRole] (
    [UserRoleId] BIGINT IDENTITY(1,1) NOT NULL
   ,[UserId] INT NOT NULL
   ,[RoleId] INT NOT NULL
   ,[CreatedAt] DATETIME2(0) NOT NULL DEFAULT (sysutcdatetime())
   ,CONSTRAINT [PK__UserRole__3D978A35F69039C4] PRIMARY KEY CLUSTERED ([UserRoleId])
   ,CONSTRAINT [UQ_sec_UserRole] UNIQUE NONCLUSTERED ([UserId], [RoleId])
);
GO
ALTER TABLE [sec].[UserRole] ADD CONSTRAINT [FK_sec_UserRole_User] FOREIGN KEY ([UserId]) REFERENCES [sec].[User] ([UserId]);
GO
ALTER TABLE [sec].[UserRole] ADD CONSTRAINT [FK_sec_UserRole_Role] FOREIGN KEY ([RoleId]) REFERENCES [sec].[Role] ([RoleId]);
GO
 
 
