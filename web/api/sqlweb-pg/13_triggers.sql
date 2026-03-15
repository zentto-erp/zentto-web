-- ============================================================
-- DatqBoxWeb PostgreSQL - 13_triggers.sql
-- Triggers: row_ver (ROWVERSION), updated_at automatico
-- ============================================================

-- Funcion reutilizable para incrementar RowVer en UPDATE
CREATE OR REPLACE FUNCTION trg_increment_row_ver()
RETURNS TRIGGER AS $$
BEGIN
    NEW."RowVer" := COALESCE(OLD."RowVer", 0) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Funcion reutilizable para auto-actualizar UpdatedAt
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."UpdatedAt" := NOW() AT TIME ZONE 'UTC';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- sec."User"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_sec_User_row_ver" ON sec."User";
CREATE TRIGGER "trg_sec_User_row_ver"
    BEFORE UPDATE ON sec."User"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_sec_User_updated_at" ON sec."User";
CREATE TRIGGER "trg_sec_User_updated_at"
    BEFORE UPDATE ON sec."User"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- cfg."Company"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_cfg_Company_row_ver" ON cfg."Company";
CREATE TRIGGER "trg_cfg_Company_row_ver"
    BEFORE UPDATE ON cfg."Company"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_cfg_Company_updated_at" ON cfg."Company";
CREATE TRIGGER "trg_cfg_Company_updated_at"
    BEFORE UPDATE ON cfg."Company"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- cfg."Branch"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_cfg_Branch_row_ver" ON cfg."Branch";
CREATE TRIGGER "trg_cfg_Branch_row_ver"
    BEFORE UPDATE ON cfg."Branch"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_cfg_Branch_updated_at" ON cfg."Branch";
CREATE TRIGGER "trg_cfg_Branch_updated_at"
    BEFORE UPDATE ON cfg."Branch"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Customer"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Customer_row_ver" ON master."Customer";
CREATE TRIGGER "trg_master_Customer_row_ver"
    BEFORE UPDATE ON master."Customer"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Customer_updated_at" ON master."Customer";
CREATE TRIGGER "trg_master_Customer_updated_at"
    BEFORE UPDATE ON master."Customer"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Supplier"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Supplier_row_ver" ON master."Supplier";
CREATE TRIGGER "trg_master_Supplier_row_ver"
    BEFORE UPDATE ON master."Supplier"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Supplier_updated_at" ON master."Supplier";
CREATE TRIGGER "trg_master_Supplier_updated_at"
    BEFORE UPDATE ON master."Supplier"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Employee"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Employee_row_ver" ON master."Employee";
CREATE TRIGGER "trg_master_Employee_row_ver"
    BEFORE UPDATE ON master."Employee"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Employee_updated_at" ON master."Employee";
CREATE TRIGGER "trg_master_Employee_updated_at"
    BEFORE UPDATE ON master."Employee"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- master."Product"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_master_Product_row_ver" ON master."Product";
CREATE TRIGGER "trg_master_Product_row_ver"
    BEFORE UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_master_Product_updated_at" ON master."Product";
CREATE TRIGGER "trg_master_Product_updated_at"
    BEFORE UPDATE ON master."Product"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."Account"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_Account_row_ver" ON acct."Account";
CREATE TRIGGER "trg_acct_Account_row_ver"
    BEFORE UPDATE ON acct."Account"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_Account_updated_at" ON acct."Account";
CREATE TRIGGER "trg_acct_Account_updated_at"
    BEFORE UPDATE ON acct."Account"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."JournalEntry"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_JournalEntry_row_ver" ON acct."JournalEntry";
CREATE TRIGGER "trg_acct_JournalEntry_row_ver"
    BEFORE UPDATE ON acct."JournalEntry"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_JournalEntry_updated_at" ON acct."JournalEntry";
CREATE TRIGGER "trg_acct_JournalEntry_updated_at"
    BEFORE UPDATE ON acct."JournalEntry"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- acct."JournalEntryLine"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_acct_JournalEntryLine_row_ver" ON acct."JournalEntryLine";
CREATE TRIGGER "trg_acct_JournalEntryLine_row_ver"
    BEFORE UPDATE ON acct."JournalEntryLine"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_acct_JournalEntryLine_updated_at" ON acct."JournalEntryLine";
CREATE TRIGGER "trg_acct_JournalEntryLine_updated_at"
    BEFORE UPDATE ON acct."JournalEntryLine"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- ar."ReceivableDocument"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_ar_ReceivableDocument_row_ver" ON ar."ReceivableDocument";
CREATE TRIGGER "trg_ar_ReceivableDocument_row_ver"
    BEFORE UPDATE ON ar."ReceivableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_ar_ReceivableDocument_updated_at" ON ar."ReceivableDocument";
CREATE TRIGGER "trg_ar_ReceivableDocument_updated_at"
    BEFORE UPDATE ON ar."ReceivableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- ap."PayableDocument"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_ap_PayableDocument_row_ver" ON ap."PayableDocument";
CREATE TRIGGER "trg_ap_PayableDocument_row_ver"
    BEFORE UPDATE ON ap."PayableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_ap_PayableDocument_updated_at" ON ap."PayableDocument";
CREATE TRIGGER "trg_ap_PayableDocument_updated_at"
    BEFORE UPDATE ON ap."PayableDocument"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."CountryConfig"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_CountryConfig_row_ver" ON fiscal."CountryConfig";
CREATE TRIGGER "trg_fiscal_CountryConfig_row_ver"
    BEFORE UPDATE ON fiscal."CountryConfig"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_CountryConfig_updated_at" ON fiscal."CountryConfig";
CREATE TRIGGER "trg_fiscal_CountryConfig_updated_at"
    BEFORE UPDATE ON fiscal."CountryConfig"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."TaxRate"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_TaxRate_row_ver" ON fiscal."TaxRate";
CREATE TRIGGER "trg_fiscal_TaxRate_row_ver"
    BEFORE UPDATE ON fiscal."TaxRate"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_TaxRate_updated_at" ON fiscal."TaxRate";
CREATE TRIGGER "trg_fiscal_TaxRate_updated_at"
    BEFORE UPDATE ON fiscal."TaxRate"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- fiscal."InvoiceType"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_fiscal_InvoiceType_row_ver" ON fiscal."InvoiceType";
CREATE TRIGGER "trg_fiscal_InvoiceType_row_ver"
    BEFORE UPDATE ON fiscal."InvoiceType"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_fiscal_InvoiceType_updated_at" ON fiscal."InvoiceType";
CREATE TRIGGER "trg_fiscal_InvoiceType_updated_at"
    BEFORE UPDATE ON fiscal."InvoiceType"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."WaitTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_WaitTicket_row_ver" ON pos."WaitTicket";
CREATE TRIGGER "trg_pos_WaitTicket_row_ver"
    BEFORE UPDATE ON pos."WaitTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_WaitTicket_updated_at" ON pos."WaitTicket";
CREATE TRIGGER "trg_pos_WaitTicket_updated_at"
    BEFORE UPDATE ON pos."WaitTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."SaleTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_SaleTicket_row_ver" ON pos."SaleTicket";
CREATE TRIGGER "trg_pos_SaleTicket_row_ver"
    BEFORE UPDATE ON pos."SaleTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_SaleTicket_updated_at" ON pos."SaleTicket";
CREATE TRIGGER "trg_pos_SaleTicket_updated_at"
    BEFORE UPDATE ON pos."SaleTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- pos."FiscalCorrelative"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_pos_FiscalCorrelative_row_ver" ON pos."FiscalCorrelative";
CREATE TRIGGER "trg_pos_FiscalCorrelative_row_ver"
    BEFORE UPDATE ON pos."FiscalCorrelative"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_pos_FiscalCorrelative_updated_at" ON pos."FiscalCorrelative";
CREATE TRIGGER "trg_pos_FiscalCorrelative_updated_at"
    BEFORE UPDATE ON pos."FiscalCorrelative"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- rest."OrderTicket"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_rest_OrderTicket_row_ver" ON rest."OrderTicket";
CREATE TRIGGER "trg_rest_OrderTicket_row_ver"
    BEFORE UPDATE ON rest."OrderTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_rest_OrderTicket_updated_at" ON rest."OrderTicket";
CREATE TRIGGER "trg_rest_OrderTicket_updated_at"
    BEFORE UPDATE ON rest."OrderTicket"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- rest."DiningTable"
-- ============================================================
DROP TRIGGER IF EXISTS "trg_rest_DiningTable_row_ver" ON rest."DiningTable";
CREATE TRIGGER "trg_rest_DiningTable_row_ver"
    BEFORE UPDATE ON rest."DiningTable"
    FOR EACH ROW EXECUTE FUNCTION trg_increment_row_ver();

DROP TRIGGER IF EXISTS "trg_rest_DiningTable_updated_at" ON rest."DiningTable";
CREATE TRIGGER "trg_rest_DiningTable_updated_at"
    BEFORE UPDATE ON rest."DiningTable"
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
