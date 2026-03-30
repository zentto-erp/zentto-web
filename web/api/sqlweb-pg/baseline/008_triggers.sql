-- ============================================
-- Zentto ERP — Trigger definitions
-- Extracted from zentto_dev via pg_dump
-- Date: 2026-03-30
-- ============================================


CREATE TRIGGER "trg_acct_Account_row_ver" BEFORE UPDATE ON acct."Account" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_acct_Account_updated_at" BEFORE UPDATE ON acct."Account" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_acct_JournalEntryLine_row_ver" BEFORE UPDATE ON acct."JournalEntryLine" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_acct_JournalEntryLine_updated_at" BEFORE UPDATE ON acct."JournalEntryLine" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_acct_JournalEntry_row_ver" BEFORE UPDATE ON acct."JournalEntry" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_acct_JournalEntry_updated_at" BEFORE UPDATE ON acct."JournalEntry" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_ap_PayableDocument_row_ver" BEFORE UPDATE ON ap."PayableDocument" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_ap_PayableDocument_updated_at" BEFORE UPDATE ON ap."PayableDocument" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_ar_ReceivableDocument_row_ver" BEFORE UPDATE ON ar."ReceivableDocument" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_ar_ReceivableDocument_updated_at" BEFORE UPDATE ON ar."ReceivableDocument" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_cfg_Branch_row_ver" BEFORE UPDATE ON cfg."Branch" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_cfg_Branch_updated_at" BEFORE UPDATE ON cfg."Branch" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_cfg_Company_row_ver" BEFORE UPDATE ON cfg."Company" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_cfg_Company_updated_at" BEFORE UPDATE ON cfg."Company" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_fiscal_CountryConfig_row_ver" BEFORE UPDATE ON fiscal."CountryConfig" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_fiscal_CountryConfig_updated_at" BEFORE UPDATE ON fiscal."CountryConfig" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_fiscal_InvoiceType_row_ver" BEFORE UPDATE ON fiscal."InvoiceType" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_fiscal_InvoiceType_updated_at" BEFORE UPDATE ON fiscal."InvoiceType" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_fiscal_TaxRate_row_ver" BEFORE UPDATE ON fiscal."TaxRate" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_fiscal_TaxRate_updated_at" BEFORE UPDATE ON fiscal."TaxRate" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "TR_inv_ProductBinStock_Available" BEFORE INSERT OR UPDATE OF "QuantityOnHand", "QuantityReserved" ON inv."ProductBinStock" FOR EACH ROW EXECUTE FUNCTION inv.trg_product_bin_stock_available();


CREATE TRIGGER "trg_master_Customer_row_ver" BEFORE UPDATE ON master."Customer" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_master_Customer_updated_at" BEFORE UPDATE ON master."Customer" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_master_Employee_row_ver" BEFORE UPDATE ON master."Employee" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_master_Employee_updated_at" BEFORE UPDATE ON master."Employee" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_master_Product_row_ver" BEFORE UPDATE ON master."Product" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_master_Product_search" BEFORE INSERT OR UPDATE ON master."Product" FOR EACH ROW EXECUTE FUNCTION public.trg_product_search_vector();


CREATE TRIGGER "trg_master_Product_updated_at" BEFORE UPDATE ON master."Product" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_master_Supplier_row_ver" BEFORE UPDATE ON master."Supplier" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_master_Supplier_updated_at" BEFORE UPDATE ON master."Supplier" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_pos_FiscalCorrelative_row_ver" BEFORE UPDATE ON pos."FiscalCorrelative" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_pos_FiscalCorrelative_updated_at" BEFORE UPDATE ON pos."FiscalCorrelative" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_pos_SaleTicket_row_ver" BEFORE UPDATE ON pos."SaleTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_pos_SaleTicket_updated_at" BEFORE UPDATE ON pos."SaleTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_pos_WaitTicket_row_ver" BEFORE UPDATE ON pos."WaitTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_pos_WaitTicket_updated_at" BEFORE UPDATE ON pos."WaitTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_rest_DiningTable_row_ver" BEFORE UPDATE ON rest."DiningTable" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_rest_DiningTable_updated_at" BEFORE UPDATE ON rest."DiningTable" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_rest_OrderTicket_row_ver" BEFORE UPDATE ON rest."OrderTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_rest_OrderTicket_updated_at" BEFORE UPDATE ON rest."OrderTicket" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


CREATE TRIGGER "trg_sec_User_row_ver" BEFORE UPDATE ON sec."User" FOR EACH ROW EXECUTE FUNCTION public.trg_increment_row_ver();


CREATE TRIGGER "trg_sec_User_updated_at" BEFORE UPDATE ON sec."User" FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at();


-- Rules (legacy view compatibility)


CREATE RULE "rule_Usuarios_Delete" AS
    ON DELETE TO public."Usuarios" DO INSTEAD  UPDATE sec."User" SET "IsDeleted" = true, "IsActive" = false, "DeletedAt" = (now() AT TIME ZONE 'UTC'::text), "UpdatedAt" = (now() AT TIME ZONE 'UTC'::text)
  WHERE ((upper(("User"."UserCode")::text) = upper((old."Cod_Usuario")::text)) AND ("User"."IsDeleted" = false));


CREATE RULE "rule_Usuarios_Insert" AS
    ON INSERT TO public."Usuarios" DO INSTEAD  INSERT INTO sec."User" ("UserCode", "PasswordHash", "UserName", "IsAdmin", "IsActive", "UserType", "CanUpdate", "CanCreate", "CanDelete", "IsCreator", "CanChangePwd", "CanChangePrice", "CanGiveCredit", "Avatar", "CreatedAt", "UpdatedAt", "IsDeleted")
  VALUES (new."Cod_Usuario", new."Password", new."Nombre", COALESCE(new."IsAdmin", false), true, COALESCE(new."Tipo", 'USER'::character varying), COALESCE(new."Updates", true), COALESCE(new."Addnews", true), COALESCE(new."Deletes", false), COALESCE(new."Creador", false), COALESCE(new."Cambiar", true), COALESCE(new."PrecioMinimo", false), COALESCE(new."Credito", false), new."Avatar", (now() AT TIME ZONE 'UTC'::text), (now() AT TIME ZONE 'UTC'::text), false);


CREATE RULE "rule_Usuarios_Update" AS
    ON UPDATE TO public."Usuarios" DO INSTEAD  UPDATE sec."User" SET "PasswordHash" = new."Password", "UserName" = new."Nombre", "UserType" = new."Tipo", "IsAdmin" = new."IsAdmin", "CanUpdate" = new."Updates", "CanCreate" = new."Addnews", "CanDelete" = new."Deletes", "IsCreator" = new."Creador", "CanChangePwd" = new."Cambiar", "CanChangePrice" = new."PrecioMinimo", "CanGiveCredit" = new."Credito", "Avatar" = new."Avatar", "UpdatedAt" = (now() AT TIME ZONE 'UTC'::text)
  WHERE ((upper(("User"."UserCode")::text) = upper((old."Cod_Usuario")::text)) AND ("User"."IsDeleted" = false));

