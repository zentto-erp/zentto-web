-- +goose Up
-- Migración: Agregar CompanyId a tablas de negocio críticas que no lo tienen.
-- Estas tablas almacenan datos transaccionales que DEBEN ser filtrados por empresa
-- para garantizar aislamiento multi-tenant.

-- ============================================================
-- 1. AR — SalesDocument (Facturas/Notas de venta)
-- ============================================================
ALTER TABLE ar."SalesDocument"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

ALTER TABLE ar."SalesDocument"
    ADD COLUMN IF NOT EXISTS "BranchId" integer;

CREATE INDEX IF NOT EXISTS idx_salesdocument_companyid
    ON ar."SalesDocument" ("CompanyId");

-- ============================================================
-- 2. AP — PurchaseDocument (Facturas de compra)
-- ============================================================
ALTER TABLE ap."PurchaseDocument"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

ALTER TABLE ap."PurchaseDocument"
    ADD COLUMN IF NOT EXISTS "BranchId" integer;

CREATE INDEX IF NOT EXISTS idx_purchasedocument_companyid
    ON ap."PurchaseDocument" ("CompanyId");

-- ============================================================
-- 3. ACCT — BankDeposit (Depósitos bancarios)
-- ============================================================
ALTER TABLE acct."BankDeposit"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_bankdeposit_companyid
    ON acct."BankDeposit" ("CompanyId");

-- ============================================================
-- 4. FIN — BankMovement (Movimientos bancarios)
-- ============================================================
ALTER TABLE fin."BankMovement"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_bankmovement_companyid
    ON fin."BankMovement" ("CompanyId");

-- ============================================================
-- 5. FIN — BankStatementLine (Extractos bancarios)
-- ============================================================
ALTER TABLE fin."BankStatementLine"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_bankstatementline_companyid
    ON fin."BankStatementLine" ("CompanyId");

-- ============================================================
-- 6. FIN — PettyCashExpense (Gastos de caja chica)
-- ============================================================
ALTER TABLE fin."PettyCashExpense"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_pettycashexpense_companyid
    ON fin."PettyCashExpense" ("CompanyId");

-- ============================================================
-- 7. FIN — PettyCashSession (Sesiones de caja chica)
-- ============================================================
ALTER TABLE fin."PettyCashSession"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_pettycashsession_companyid
    ON fin."PettyCashSession" ("CompanyId");

-- ============================================================
-- 8. FIN — BankReconciliationMatch (Conciliaciones)
-- ============================================================
ALTER TABLE fin."BankReconciliationMatch"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_bankreconciliationmatch_companyid
    ON fin."BankReconciliationMatch" ("CompanyId");

-- ============================================================
-- 9. HR — PayrollCalcVariable
-- ============================================================
ALTER TABLE hr."PayrollCalcVariable"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_payrollcalcvariable_companyid
    ON hr."PayrollCalcVariable" ("CompanyId");

-- ============================================================
-- 10. HR — EmployeeTaxProfile
-- ============================================================
ALTER TABLE hr."EmployeeTaxProfile"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_employeetaxprofile_companyid
    ON hr."EmployeeTaxProfile" ("CompanyId");

-- ============================================================
-- 11. HR — SavingsLoan
-- ============================================================
ALTER TABLE hr."SavingsLoan"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_savingsloan_companyid
    ON hr."SavingsLoan" ("CompanyId");

-- ============================================================
-- 12. HR — ObligationRiskLevel
-- ============================================================
ALTER TABLE hr."ObligationRiskLevel"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_obligationrisklevel_companyid
    ON hr."ObligationRiskLevel" ("CompanyId");

-- ============================================================
-- 13. PAY — Transactions (Pagos/transacciones)
-- ============================================================
-- Esta tabla usa "EmpresaId" como legacy. Agregar CompanyId canónico.
ALTER TABLE pay."Transactions"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_transactions_companyid
    ON pay."Transactions" ("CompanyId");

-- ============================================================
-- 14. PAY — CompanyPaymentConfig
-- ============================================================
-- Usa "EmpresaId" legacy. Agregar CompanyId canónico.
ALTER TABLE pay."CompanyPaymentConfig"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_companypaymentconfig_companyid
    ON pay."CompanyPaymentConfig" ("CompanyId");

-- ============================================================
-- 15. PAY — CardReaderDevices
-- ============================================================
ALTER TABLE pay."CardReaderDevices"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_cardreaderdevices_companyid
    ON pay."CardReaderDevices" ("CompanyId");

-- ============================================================
-- 16. PAY — ReconciliationBatches
-- ============================================================
ALTER TABLE pay."ReconciliationBatches"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_reconciliationbatches_companyid
    ON pay."ReconciliationBatches" ("CompanyId");

-- ============================================================
-- 17. PAY — AcceptedPaymentMethods
-- ============================================================
ALTER TABLE pay."AcceptedPaymentMethods"
    ADD COLUMN IF NOT EXISTS "CompanyId" integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_acceptedpaymentmethods_companyid
    ON pay."AcceptedPaymentMethods" ("CompanyId");


-- +goose Down
-- Rollback: eliminar columnas CompanyId agregadas

ALTER TABLE ar."SalesDocument" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE ar."SalesDocument" DROP COLUMN IF EXISTS "BranchId";
ALTER TABLE ap."PurchaseDocument" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE ap."PurchaseDocument" DROP COLUMN IF EXISTS "BranchId";
ALTER TABLE acct."BankDeposit" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE fin."BankMovement" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE fin."BankStatementLine" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE fin."PettyCashExpense" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE fin."PettyCashSession" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE fin."BankReconciliationMatch" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE hr."PayrollCalcVariable" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE hr."EmployeeTaxProfile" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE hr."SavingsLoan" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE hr."ObligationRiskLevel" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE pay."Transactions" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE pay."CompanyPaymentConfig" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE pay."CardReaderDevices" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE pay."ReconciliationBatches" DROP COLUMN IF EXISTS "CompanyId";
ALTER TABLE pay."AcceptedPaymentMethods" DROP COLUMN IF EXISTS "CompanyId";
