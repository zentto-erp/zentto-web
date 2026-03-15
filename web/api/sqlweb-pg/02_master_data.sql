-- ============================================================
-- DatqBoxWeb PostgreSQL - 02_master_data.sql
-- Tablas maestras: Customer, Supplier, Employee, Product
-- ============================================================

BEGIN;

-- ---------------------------------------------------------
-- master."Customer"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Customer" (
  "CustomerId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "CustomerCode"         VARCHAR(24) NOT NULL,
  "CustomerName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "Email"                VARCHAR(150) NULL,
  "Phone"                VARCHAR(40) NULL,
  "AddressLine"          VARCHAR(250) NULL,
  "CreditLimit"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Customer_CreditLimit" DEFAULT 0,
  "TotalBalance"         NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Customer_TotalBalance" DEFAULT 0,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Customer_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Customer_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Customer_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Customer_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Customer" UNIQUE ("CompanyId", "CustomerCode"),
  CONSTRAINT "FK_master_Customer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Customer_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Customer_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Supplier"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Supplier" (
  "SupplierId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "SupplierCode"         VARCHAR(24) NOT NULL,
  "SupplierName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "Email"                VARCHAR(150) NULL,
  "Phone"                VARCHAR(40) NULL,
  "AddressLine"          VARCHAR(250) NULL,
  "CreditLimit"          NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Supplier_CreditLimit" DEFAULT 0,
  "TotalBalance"         NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Supplier_TotalBalance" DEFAULT 0,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Supplier_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Supplier_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Supplier_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Supplier_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Supplier" UNIQUE ("CompanyId", "SupplierCode"),
  CONSTRAINT "FK_master_Supplier_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Supplier_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Supplier_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Employee"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Employee" (
  "EmployeeId"           BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "EmployeeCode"         VARCHAR(24) NOT NULL,
  "EmployeeName"         VARCHAR(200) NOT NULL,
  "FiscalId"             VARCHAR(30) NULL,
  "HireDate"             DATE NULL,
  "TerminationDate"      DATE NULL,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Employee_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Employee_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Employee_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Employee_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Employee" UNIQUE ("CompanyId", "EmployeeCode"),
  CONSTRAINT "FK_master_Employee_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Employee_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Employee_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

-- ---------------------------------------------------------
-- master."Product"
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS master."Product" (
  "ProductId"            BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY,
  "CompanyId"            INT NOT NULL,
  "ProductCode"          VARCHAR(80) NOT NULL,
  "ProductName"          VARCHAR(250) NOT NULL,
  "CategoryCode"         VARCHAR(50) NULL,
  "UnitCode"             VARCHAR(20) NULL,
  "SalesPrice"           NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Product_SalesPrice" DEFAULT 0,
  "CostPrice"            NUMERIC(18,2) NOT NULL CONSTRAINT "DF_master_Product_CostPrice" DEFAULT 0,
  "DefaultTaxCode"       VARCHAR(30) NULL,
  "DefaultTaxRate"       NUMERIC(9,4) NOT NULL CONSTRAINT "DF_master_Product_DefaultTaxRate" DEFAULT 0,
  "StockQty"             NUMERIC(18,3) NOT NULL CONSTRAINT "DF_master_Product_StockQty" DEFAULT 0,
  "IsService"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsService" DEFAULT FALSE,
  "IsActive"             BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsActive" DEFAULT TRUE,
  "CreatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Product_CreatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP NOT NULL CONSTRAINT "DF_master_Product_UpdatedAt" DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedByUserId"      INT NULL,
  "UpdatedByUserId"      INT NULL,
  "IsDeleted"            BOOLEAN NOT NULL CONSTRAINT "DF_master_Product_IsDeleted" DEFAULT FALSE,
  "DeletedAt"            TIMESTAMP NULL,
  "DeletedByUserId"      INT NULL,
  "RowVer"               INT NOT NULL DEFAULT 1,
  CONSTRAINT "UQ_master_Product" UNIQUE ("CompanyId", "ProductCode"),
  CONSTRAINT "FK_master_Product_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId"),
  CONSTRAINT "FK_master_Product_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId"),
  CONSTRAINT "FK_master_Product_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId")
);

CREATE INDEX IF NOT EXISTS "IX_master_Product_Company_IsActive"
  ON master."Product" ("CompanyId", "IsActive", "ProductCode");

COMMIT;
