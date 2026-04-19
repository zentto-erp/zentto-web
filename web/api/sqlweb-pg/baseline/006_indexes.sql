-- ============================================
-- Zentto ERP — Index definitions
-- Extracted from zentto_dev via pg_dump
-- Date: 2026-03-30
-- ============================================


CREATE INDEX "IX_BankDeposit_Customer" ON acct."BankDeposit" USING btree ("CustomerCode") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_FixedAssetDepreciation_AssetPeriod" ON acct."FixedAssetDepreciation" USING btree ("AssetId", "PeriodCode");


CREATE INDEX "IX_FixedAsset_CategoryId" ON acct."FixedAsset" USING btree ("CategoryId");


CREATE INDEX "IX_FixedAsset_CompanyCode" ON acct."FixedAsset" USING btree ("CompanyId", "AssetCode");


CREATE INDEX "IX_acct_Account_Company_Parent" ON acct."Account" USING btree ("CompanyId", "ParentAccountId", "AccountCode");


CREATE INDEX "IX_acct_EM_Year" ON acct."EquityMovement" USING btree ("CompanyId", "FiscalYear");


CREATE INDEX "IX_acct_IAL_Header" ON acct."InflationAdjustmentLine" USING btree ("InflationAdjustmentId");


CREATE INDEX "IX_acct_JEL_Account" ON acct."JournalEntryLine" USING btree ("AccountId", "JournalEntryId");


CREATE INDEX "IX_acct_JE_Date" ON acct."JournalEntry" USING btree ("CompanyId", "BranchId", "EntryDate", "JournalEntryId");


CREATE INDEX "IX_acct_RTV_Template" ON acct."ReportTemplateVariable" USING btree ("ReportTemplateId");


CREATE INDEX "IX_PurchDocLine_DocKey" ON ap."PurchaseDocumentLine" USING btree ("DocumentNumber", "OperationType") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_PurchDocLine_Product" ON ap."PurchaseDocumentLine" USING btree ("ProductCode");


CREATE INDEX "IX_PurchDocPay_DocKey" ON ap."PurchaseDocumentPayment" USING btree ("DocumentNumber", "OperationType") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_PurchaseDocument_OpDate" ON ap."PurchaseDocument" USING btree ("OperationType", "DocumentDate") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_PurchaseDocument_Supplier" ON ap."PurchaseDocument" USING btree ("SupplierCode");


CREATE INDEX "IX_SalesDocLine_DocKey" ON ar."SalesDocumentLine" USING btree ("DocumentNumber", "OperationType") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_SalesDocLine_Product" ON ar."SalesDocumentLine" USING btree ("ProductCode");


CREATE INDEX "IX_SalesDocPay_DocKey" ON ar."SalesDocumentPayment" USING btree ("DocumentNumber", "OperationType") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_SalesDocument_Customer" ON ar."SalesDocument" USING btree ("CustomerCode");


CREATE INDEX "IX_SalesDocument_OpDate" ON ar."SalesDocument" USING btree ("OperationType", "DocumentDate" DESC) WHERE ("IsDeleted" = false);


CREATE INDEX "IX_AuditLog_Company_Date" ON audit."AuditLog" USING btree ("CompanyId", "BranchId", "CreatedAt" DESC);


CREATE INDEX "IX_AuditLog_Module" ON audit."AuditLog" USING btree ("ModuleName", "CreatedAt" DESC);


CREATE INDEX "IX_AuditLog_User" ON audit."AuditLog" USING btree ("UserName", "CreatedAt" DESC);


CREATE INDEX "IX_cfg_Company_OwnerEmail" ON cfg."Company" USING btree ("OwnerEmail") WHERE ("OwnerEmail" IS NOT NULL);


CREATE INDEX "IX_cfg_Company_TenantStatus" ON cfg."Company" USING btree ("TenantStatus");


CREATE UNIQUE INDEX "UQ_CompanyProfile_CompanyId" ON cfg."CompanyProfile" USING btree ("CompanyId");


CREATE UNIQUE INDEX "UQ_DocumentSequence_Branch" ON cfg."DocumentSequence" USING btree ("CompanyId", "BranchId", "DocumentType") WHERE ("BranchId" IS NOT NULL);


CREATE UNIQUE INDEX "UQ_DocumentSequence_NoBranch" ON cfg."DocumentSequence" USING btree ("CompanyId", "DocumentType") WHERE ("BranchId" IS NULL);


CREATE INDEX "IX_CallLog_Agent" ON crm."CallLog" USING btree ("AgentId", "CallStartTime" DESC);


CREATE INDEX "IX_CallLog_CompanyDate" ON crm."CallLog" USING btree ("CompanyId", "CallStartTime" DESC);


CREATE INDEX "IX_CallLog_CustomerCode" ON crm."CallLog" USING btree ("CompanyId", "CustomerCode");


CREATE INDEX "IX_CampaignContact_Status" ON crm."CampaignContact" USING btree ("CampaignId", "Status", "Priority");


CREATE INDEX "IX_crm_Activity_Pending" ON crm."Activity" USING btree ("CompanyId", "IsCompleted", "DueDate") WHERE (("IsDeleted" = false) AND ("IsCompleted" = false));


CREATE INDEX "IX_crm_AutomationLog_Rule" ON crm."AutomationLog" USING btree ("RuleId", "ExecutedAt" DESC);


CREATE INDEX "IX_crm_AutomationRule_Company" ON crm."AutomationRule" USING btree ("CompanyId", "IsActive") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_crm_LeadHistory_Lead" ON crm."LeadHistory" USING btree ("LeadId", "CreatedAt" DESC);


CREATE INDEX "IX_crm_LeadScore_LeadId" ON crm."LeadScore" USING btree ("LeadId", "ScoreDate" DESC);


CREATE INDEX "IX_crm_Lead_Status_Stage" ON crm."Lead" USING btree ("CompanyId", "Status", "StageId") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_crm_Lead_Code" ON crm."Lead" USING btree ("CompanyId", "LeadCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_crm_PipelineStage_Code" ON crm."PipelineStage" USING btree ("PipelineId", "StageCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_crm_Pipeline_Code" ON crm."Pipeline" USING btree ("CompanyId", "PipelineCode") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_crm_SavedView_UserEntity" ON crm."SavedView" USING btree ("CompanyId", "UserId", "Entity");


CREATE INDEX "IX_crm_SavedView_Shared" ON crm."SavedView" USING btree ("CompanyId", "Entity", "IsShared") WHERE ("IsShared" = true);


CREATE INDEX "IX_fin_BankAccount_Search" ON fin."BankAccount" USING btree ("CompanyId", "BranchId", "IsActive", "AccountNumber");


CREATE INDEX "IX_fin_BankMovement_JournalEntry" ON fin."BankMovement" USING btree ("JournalEntryId") WHERE ("JournalEntryId" IS NOT NULL);


CREATE INDEX "IX_fin_BankMovement_Search" ON fin."BankMovement" USING btree ("BankAccountId", "MovementDate" DESC, "BankMovementId" DESC);


CREATE INDEX "IX_fin_BankRec_Search" ON fin."BankReconciliation" USING btree ("BankAccountId", "Status", "DateFrom", "DateTo");


CREATE INDEX "IX_fin_BankStatementLine_Search" ON fin."BankStatementLine" USING btree ("ReconciliationId", "IsMatched", "StatementDate");


CREATE INDEX "IX_ISLRTariff_Year" ON fiscal."ISLRTariff" USING btree ("CountryCode", "TaxYear", "IsActive");


CREATE INDEX "IX_TaxBookEntry_Declaration" ON fiscal."TaxBookEntry" USING btree ("DeclarationId") WHERE ("DeclarationId" IS NOT NULL);


CREATE INDEX "IX_TaxBookEntry_Period_Book" ON fiscal."TaxBookEntry" USING btree ("CompanyId", "BookType", "PeriodCode");


CREATE INDEX "IX_TaxDeclaration_Country_Period" ON fiscal."TaxDeclaration" USING btree ("CountryCode", "PeriodCode", "Status");


CREATE INDEX "IX_WithholdingVoucher_Period" ON fiscal."WithholdingVoucher" USING btree ("CompanyId", "PeriodCode", "WithholdingType");


CREATE INDEX "IX_fiscal_Record_Search" ON fiscal."Record" USING btree ("CompanyId", "BranchId", "CountryCode", "FiscalRecordId" DESC);


CREATE INDEX "IX_fleet_FuelLog_Company" ON fleet."FuelLog" USING btree ("CompanyId", "FuelDate" DESC) WHERE ("IsDeleted" = false);


CREATE INDEX "IX_fleet_FuelLog_Vehicle" ON fleet."FuelLog" USING btree ("VehicleId", "FuelDate" DESC);


CREATE INDEX "IX_fleet_MOLine_Order" ON fleet."MaintenanceOrderLine" USING btree ("MaintenanceOrderId");


CREATE INDEX "IX_fleet_MaintOrder_Status" ON fleet."MaintenanceOrder" USING btree ("CompanyId", "Status") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_fleet_MaintOrder_Vehicle" ON fleet."MaintenanceOrder" USING btree ("VehicleId", "OrderDate" DESC);


CREATE INDEX "IX_fleet_MaintType_Company" ON fleet."MaintenanceType" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_fleet_Trip_Company" ON fleet."Trip" USING btree ("CompanyId", "TripDate" DESC) WHERE ("IsDeleted" = false);


CREATE INDEX "IX_fleet_Trip_DeliveryNote" ON fleet."Trip" USING btree ("DeliveryNoteId") WHERE ("DeliveryNoteId" IS NOT NULL);


CREATE INDEX "IX_fleet_Trip_Vehicle" ON fleet."Trip" USING btree ("VehicleId", "TripDate" DESC);


CREATE INDEX "IX_fleet_VehicleDoc_Expiry" ON fleet."VehicleDocument" USING btree ("ExpiresAt") WHERE (("ExpiresAt" IS NOT NULL) AND ("IsDeleted" = false));


CREATE INDEX "IX_fleet_VehicleDoc_Vehicle" ON fleet."VehicleDocument" USING btree ("VehicleId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_fleet_Vehicle_Company" ON fleet."Vehicle" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_fleet_Vehicle_Status" ON fleet."Vehicle" USING btree ("CompanyId", "Status") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_CommitteeMeeting_Committee" ON hr."SafetyCommitteeMeeting" USING btree ("SafetyCommitteeId", "MeetingDate" DESC);


CREATE INDEX "IX_CommitteeMember_Committee" ON hr."SafetyCommitteeMember" USING btree ("SafetyCommitteeId");


CREATE INDEX "IX_Committee_Company" ON hr."SafetyCommittee" USING btree ("CompanyId", "IsActive");


CREATE INDEX "IX_MedExam_Company_Type" ON hr."MedicalExam" USING btree ("CompanyId", "ExamType", "ExamDate" DESC);


CREATE INDEX "IX_MedExam_Employee" ON hr."MedicalExam" USING btree ("EmployeeCode", "CompanyId");


CREATE INDEX "IX_MedExam_NextDue" ON hr."MedicalExam" USING btree ("CompanyId", "NextDueDate") WHERE ("NextDueDate" IS NOT NULL);


CREATE INDEX "IX_MedOrder_Company_Status" ON hr."MedicalOrder" USING btree ("CompanyId", "Status", "OrderDate" DESC);


CREATE INDEX "IX_MedOrder_Employee" ON hr."MedicalOrder" USING btree ("EmployeeCode", "CompanyId");


CREATE INDEX "IX_OccHealth_Company_RecordType" ON hr."OccupationalHealth" USING btree ("CompanyId", "RecordType", "OccurrenceDate" DESC);


CREATE INDEX "IX_OccHealth_Company_Status" ON hr."OccupationalHealth" USING btree ("CompanyId", "Status");


CREATE INDEX "IX_OccHealth_Employee" ON hr."OccupationalHealth" USING btree ("EmployeeId") WHERE ("EmployeeId" IS NOT NULL);


CREATE INDEX "IX_ProfitSharingLine_Employee" ON hr."ProfitSharingLine" USING btree ("EmployeeCode");


CREATE INDEX "IX_ProfitSharingLine_Header" ON hr."ProfitSharingLine" USING btree ("ProfitSharingId");


CREATE INDEX "IX_SavingsFund_Status" ON hr."SavingsFund" USING btree ("CompanyId", "Status");


CREATE INDEX "IX_SavingsLoan_Employee" ON hr."SavingsLoan" USING btree ("EmployeeCode");


CREATE INDEX "IX_SavingsLoan_Fund" ON hr."SavingsLoan" USING btree ("SavingsFundId");


CREATE INDEX "IX_SavingsLoan_Status" ON hr."SavingsLoan" USING btree ("Status");


CREATE INDEX "IX_SavingsTx_Fund" ON hr."SavingsFundTransaction" USING btree ("SavingsFundId", "TransactionDate");


CREATE INDEX "IX_SavingsTx_Type" ON hr."SavingsFundTransaction" USING btree ("TransactionType");


CREATE INDEX "IX_Training_Company_Type" ON hr."TrainingRecord" USING btree ("CompanyId", "TrainingType", "StartDate" DESC);


CREATE INDEX "IX_Training_Employee" ON hr."TrainingRecord" USING btree ("EmployeeCode", "CompanyId");


CREATE INDEX "IX_Training_Regulatory" ON hr."TrainingRecord" USING btree ("CompanyId", "IsRegulatory") WHERE ("IsRegulatory" = true);


CREATE INDEX "IX_Trust_Company_Year" ON hr."SocialBenefitsTrust" USING btree ("CompanyId", "FiscalYear", "Quarter");


CREATE INDEX "IX_Trust_Employee" ON hr."SocialBenefitsTrust" USING btree ("EmployeeCode", "FiscalYear");


CREATE INDEX "IX_VacationRequestDay_Request" ON hr."VacationRequestDay" USING btree ("RequestId");


CREATE INDEX "IX_VacationRequest_Employee" ON hr."VacationRequest" USING btree ("CompanyId", "EmployeeCode", "Status");


CREATE INDEX "IX_VacationRequest_Status" ON hr."VacationRequest" USING btree ("Status", "RequestDate");


CREATE INDEX "IX_hr_PayrollBatchLine_Batch" ON hr."PayrollBatchLine" USING btree ("BatchId", "EmployeeCode", "ConceptType") INCLUDE ("ConceptCode", "Total");


CREATE INDEX "IX_hr_PayrollBatchLine_Employee" ON hr."PayrollBatchLine" USING btree ("BatchId", "EmployeeCode") INCLUDE ("ConceptType", "Total", "IsModified");


CREATE INDEX "IX_hr_PayrollBatch_Company" ON hr."PayrollBatch" USING btree ("CompanyId", "PayrollCode", "Status") INCLUDE ("FromDate", "ToDate");


CREATE INDEX "IX_hr_PayrollConcept_Search" ON hr."PayrollConcept" USING btree ("CompanyId", "PayrollCode", "IsActive", "ConceptType", "SortOrder", "ConceptCode");


CREATE INDEX "IX_hr_PayrollRunLine_Run" ON hr."PayrollRunLine" USING btree ("PayrollRunId", "ConceptType", "ConceptCode");


CREATE INDEX "IX_hr_PayrollRun_Search" ON hr."PayrollRun" USING btree ("CompanyId", "PayrollCode", "EmployeeCode", "ProcessDate" DESC, "IsClosed");


CREATE INDEX "IX_Lot_Product" ON inv."ProductLot" USING btree ("CompanyId", "ProductId", "Status");


CREATE INDEX "IX_Movement_Company" ON inv."StockMovement" USING btree ("CompanyId", "CreatedAt" DESC);


CREATE INDEX "IX_Movement_Product" ON inv."StockMovement" USING btree ("CompanyId", "ProductId", "CreatedAt" DESC);


CREATE INDEX "IX_Serial_Product" ON inv."ProductSerial" USING btree ("CompanyId", "ProductId", "Status");


CREATE INDEX "IX_inv_ProductBinStock_Warehouse" ON inv."ProductBinStock" USING btree ("WarehouseId", "ProductId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_inv_ProductLot_Expiry" ON inv."ProductLot" USING btree ("CompanyId", "ExpiryDate") WHERE (("ExpiryDate" IS NOT NULL) AND ("IsDeleted" = false) AND (("Status")::text = 'ACTIVE'::text));


CREATE INDEX "IX_inv_ProductLot_Product" ON inv."ProductLot" USING btree ("CompanyId", "ProductId", "Status");


CREATE INDEX "IX_inv_ProductSerial_Product" ON inv."ProductSerial" USING btree ("CompanyId", "ProductId", "Status");


CREATE INDEX "IX_inv_ProductSerial_Warehouse" ON inv."ProductSerial" USING btree ("WarehouseId", "Status") WHERE (("IsDeleted" = false) AND (("Status")::text = 'AVAILABLE'::text));


CREATE INDEX "IX_inv_StockMovement_Date" ON inv."StockMovement" USING btree ("CompanyId", "MovementDate" DESC);


CREATE INDEX "IX_inv_StockMovement_Product" ON inv."StockMovement" USING btree ("CompanyId", "ProductId", "MovementDate" DESC);


CREATE INDEX "IX_inv_StockMovement_Type" ON inv."StockMovement" USING btree ("CompanyId", "MovementType", "MovementDate" DESC);


CREATE INDEX "IX_inv_ValLayer_Product" ON inv."InventoryValuationLayer" USING btree ("CompanyId", "ProductId", "LayerDate");


CREATE INDEX "IX_inv_ValLayer_Remaining" ON inv."InventoryValuationLayer" USING btree ("CompanyId", "ProductId") WHERE ("RemainingQuantity" > (0)::numeric);


CREATE INDEX "IX_inv_WarehouseBin_Zone" ON inv."WarehouseBin" USING btree ("ZoneId", "IsDeleted", "IsActive");


CREATE INDEX "IX_inv_WarehouseZone_Warehouse" ON inv."WarehouseZone" USING btree ("WarehouseId", "IsDeleted", "IsActive");


CREATE INDEX "IX_inv_Warehouse_Company" ON inv."Warehouse" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE UNIQUE INDEX "UQ_inv_ProductLot" ON inv."ProductLot" USING btree ("CompanyId", "ProductId", "LotNumber") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_inv_ProductSerial" ON inv."ProductSerial" USING btree ("CompanyId", "ProductId", "SerialNumber") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_inv_ValMethod_Product" ON inv."InventoryValuationMethod" USING btree ("CompanyId", "ProductId") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_inv_Warehouse_Code" ON inv."Warehouse" USING btree ("CompanyId", "WarehouseCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UX_BinStock" ON inv."ProductBinStock" USING btree ("CompanyId", "ProductId", "WarehouseId", COALESCE("BinId", (0)::bigint), COALESCE("LotId", (0)::bigint));


CREATE UNIQUE INDEX "UX_Bin_Code" ON inv."WarehouseBin" USING btree ("ZoneId", "BinCode");


CREATE UNIQUE INDEX "UX_Lot_Number" ON inv."ProductLot" USING btree ("CompanyId", "ProductId", "LotNumber");


CREATE UNIQUE INDEX "UX_Serial_Number" ON inv."ProductSerial" USING btree ("CompanyId", "SerialNumber");


CREATE UNIQUE INDEX "UX_Valuation" ON inv."InventoryValuationMethod" USING btree ("CompanyId", "ProductId");


CREATE UNIQUE INDEX "UX_Warehouse_Code" ON inv."Warehouse" USING btree ("CompanyId", "WarehouseCode");


CREATE UNIQUE INDEX "UX_Zone_Code" ON inv."WarehouseZone" USING btree ("WarehouseId", "ZoneCode");


CREATE UNIQUE INDEX "UX_inv_ProductBinStock_Location" ON inv."ProductBinStock" USING btree ("CompanyId", "ProductId", "WarehouseId", COALESCE("BinId", (0)::bigint), COALESCE("LotId", (0)::bigint));


CREATE INDEX "IX_Carrier_CompanyActive" ON logistics."Carrier" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_DeliveryNoteLine_Note" ON logistics."DeliveryNoteLine" USING btree ("DeliveryNoteId", "LineNumber");


CREATE INDEX "IX_DeliveryNote_ActiveStatus" ON logistics."DeliveryNote" USING btree ("CompanyId", "Status") WHERE (("IsDeleted" = false) AND (("Status")::text <> ALL ((ARRAY['DELIVERED'::character varying, 'VOIDED'::character varying])::text[])));


CREATE INDEX "IX_DeliveryNote_Customer" ON logistics."DeliveryNote" USING btree ("CustomerId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_DeliveryNote_Date" ON logistics."DeliveryNote" USING btree ("CompanyId", "DeliveryDate" DESC);


CREATE INDEX "IX_Delivery_Date" ON logistics."DeliveryNote" USING btree ("CompanyId", "BranchId", "DeliveryDate" DESC);


CREATE INDEX "IX_Driver_Carrier" ON logistics."Driver" USING btree ("CarrierId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_Driver_CompanyActive" ON logistics."Driver" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_GoodsReceiptLine_Receipt" ON logistics."GoodsReceiptLine" USING btree ("GoodsReceiptId", "LineNumber");


CREATE INDEX "IX_GoodsReceipt_Date" ON logistics."GoodsReceipt" USING btree ("CompanyId", "ReceiptDate" DESC);


CREATE INDEX "IX_GoodsReceipt_Status" ON logistics."GoodsReceipt" USING btree ("CompanyId", "Status") WHERE (("IsDeleted" = false) AND (("Status")::text <> 'VOIDED'::text));


CREATE INDEX "IX_GoodsReturnLine_Return" ON logistics."GoodsReturnLine" USING btree ("GoodsReturnId", "LineNumber");


CREATE INDEX "IX_GoodsReturn_Date" ON logistics."GoodsReturn" USING btree ("CompanyId", "ReturnDate" DESC);


CREATE INDEX "IX_Receipt_Date" ON logistics."GoodsReceipt" USING btree ("CompanyId", "BranchId", "ReceiptDate" DESC);


CREATE UNIQUE INDEX "UQ_Carrier_CompanyCode" ON logistics."Carrier" USING btree ("CompanyId", "CarrierCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_DeliveryNote_Number" ON logistics."DeliveryNote" USING btree ("CompanyId", "BranchId", "DeliveryNumber") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_Driver_CompanyCode" ON logistics."Driver" USING btree ("CompanyId", "DriverCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_GoodsReceipt_Number" ON logistics."GoodsReceipt" USING btree ("CompanyId", "BranchId", "ReceiptNumber") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_GoodsReturn_Number" ON logistics."GoodsReturn" USING btree ("CompanyId", "BranchId", "ReturnNumber") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UX_Carrier_Code" ON logistics."Carrier" USING btree ("CompanyId", "CarrierCode");


CREATE UNIQUE INDEX "UX_Delivery_Number" ON logistics."DeliveryNote" USING btree ("CompanyId", "DeliveryNumber");


CREATE UNIQUE INDEX "UX_Driver_Code" ON logistics."Driver" USING btree ("CompanyId", "DriverCode");


CREATE UNIQUE INDEX "UX_Receipt_Number" ON logistics."GoodsReceipt" USING btree ("CompanyId", "ReceiptNumber");


CREATE UNIQUE INDEX "UX_Return_Number" ON logistics."GoodsReturn" USING btree ("CompanyId", "ReturnNumber");


CREATE INDEX "IX_InventoryMovement_ProductDate" ON master."InventoryMovement" USING btree ("ProductCode", "MovementDate" DESC) WHERE ("IsDeleted" = false);


CREATE INDEX "IX_Product_ProductCode" ON master."Product" USING btree ("ProductCode") INCLUDE ("ProductName", "StockQty", "CostPrice", "SalesPrice");


CREATE INDEX "IX_master_Product_Company_IsActive" ON master."Product" USING btree ("CompanyId", "IsActive", "ProductCode");


CREATE INDEX "IX_master_Product_code_trgm" ON master."Product" USING gin ("ProductCode" public.gin_trgm_ops);


CREATE INDEX "IX_master_Product_fulltext" ON master."Product" USING gin ("SearchVector");


CREATE UNIQUE INDEX "UQ_Brand_CompanyName" ON master."Brand" USING btree ("CompanyId", "BrandName") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_Category_CompanyName" ON master."Category" USING btree ("CompanyId", "CategoryName") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_InventoryPeriodSummary_Key" ON master."InventoryPeriodSummary" USING btree ("CompanyId", "Period", "ProductCode");


CREATE UNIQUE INDEX "UQ_Seller_CompanyCode" ON master."Seller" USING btree ("CompanyId", "SellerCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_TaxRetention_CompanyCode" ON master."TaxRetention" USING btree ("CompanyId", "RetentionCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_UnitOfMeasure_CompanyCode" ON master."UnitOfMeasure" USING btree ("CompanyId", "UnitCode") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UQ_Warehouse_CompanyCode" ON master."Warehouse" USING btree ("CompanyId", "WarehouseCode") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_mfg_BOMLine_BOM" ON mfg."BOMLine" USING btree ("BOMId");


CREATE INDEX "IX_mfg_BOMLine_Component" ON mfg."BOMLine" USING btree ("ComponentProductId");


CREATE INDEX "IX_mfg_BOM_Company" ON mfg."BillOfMaterials" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_mfg_BOM_Product" ON mfg."BillOfMaterials" USING btree ("ProductId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_mfg_Routing_BOM" ON mfg."Routing" USING btree ("BOMId", "OperationNumber");


CREATE INDEX "IX_mfg_WOMaterial_WorkOrder" ON mfg."WorkOrderMaterial" USING btree ("WorkOrderId");


CREATE INDEX "IX_mfg_WOOutput_WorkOrder" ON mfg."WorkOrderOutput" USING btree ("WorkOrderId");


CREATE INDEX "IX_mfg_WorkCenter_Company" ON mfg."WorkCenter" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_mfg_WorkOrder_BOM" ON mfg."WorkOrder" USING btree ("BOMId") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_mfg_WorkOrder_Company" ON mfg."WorkOrder" USING btree ("CompanyId", "BranchId", "Status") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_mfg_WorkOrder_Planned" ON mfg."WorkOrder" USING btree ("CompanyId", "PlannedStartDate") WHERE ((("Status")::text = ANY ((ARRAY['DRAFT'::character varying, 'CONFIRMED'::character varying])::text[])) AND ("IsDeleted" = false));


CREATE INDEX "IX_PayTrx_Recon" ON pay."Transactions" USING btree ("IsReconciled", "ProviderId");


CREATE INDEX "IX_PayTrx_Source" ON pay."Transactions" USING btree ("SourceType", "SourceId");


CREATE INDEX "IX_PayTrx_Status" ON pay."Transactions" USING btree ("Status", "CreatedAt");


CREATE INDEX "IX_pos_FiscalCorrelative_Search" ON pos."FiscalCorrelative" USING btree ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode", "IsActive");


CREATE INDEX "IX_ConcDet_Conciliacion" ON public."ConciliacionDetalle" USING btree ("Conciliacion_ID");


CREATE INDEX "IX_Conciliacion_NroCta" ON public."ConciliacionBancaria" USING btree ("Nro_Cta", "Fecha_Desde");


CREATE INDEX "IX_Extracto_Conciliado" ON public."ExtractoBancario" USING btree ("Conciliado");


CREATE INDEX "IX_Extracto_NroCta" ON public."ExtractoBancario" USING btree ("Nro_Cta", "Fecha");


CREATE INDEX "IX_Extracto_Ref" ON public."ExtractoBancario" USING btree ("Referencia");


CREATE INDEX "IX_rest_DiningTable_Search" ON rest."DiningTable" USING btree ("CompanyId", "BranchId", "IsActive", "EnvironmentCode", "TableNumber");


CREATE INDEX "IX_rest_MenuProduct_Search" ON rest."MenuProduct" USING btree ("CompanyId", "BranchId", "IsActive", "IsAvailable", "ProductCode", "ProductName");


CREATE INDEX "IX_rest_Purchase_Search" ON rest."Purchase" USING btree ("CompanyId", "BranchId", "PurchaseDate" DESC, "Status");


CREATE UNIQUE INDEX "UQ_MenuComponent_ProductName" ON rest."MenuComponent" USING btree ("MenuProductId", "ComponentName");


CREATE UNIQUE INDEX "UQ_MenuOption_ComponentOption" ON rest."MenuOption" USING btree ("MenuComponentId", "OptionName");


CREATE UNIQUE INDEX "UQ_MenuRecipe_ProductIngredient" ON rest."MenuRecipe" USING btree ("MenuProductId", "IngredientProductId");


CREATE INDEX "IX_SupervisorBiometricCredential_Active" ON sec."SupervisorBiometricCredential" USING btree ("SupervisorUserCode", "IsActive", "LastValidatedAtUtc" DESC);


CREATE INDEX "IX_SupervisorOverride_Source" ON sec."SupervisorOverride" USING btree ("ModuleCode", "ActionCode", "SourceDocumentId", "SourceLineId");


CREATE INDEX "IX_SupervisorOverride_Status" ON sec."SupervisorOverride" USING btree ("Status", "ModuleCode", "ActionCode", "ApprovedAtUtc" DESC);


CREATE INDEX "IX_sec_ApprovalAction_Request" ON sec."ApprovalAction" USING btree ("ApprovalRequestId", "ActionAt");


CREATE INDEX "IX_sec_ApprovalAction_User" ON sec."ApprovalAction" USING btree ("ActionByUserId", "ActionAt" DESC);


CREATE INDEX "IX_sec_ApprovalReq_Document" ON sec."ApprovalRequest" USING btree ("DocumentType", "DocumentId");


CREATE INDEX "IX_sec_ApprovalReq_RequestedBy" ON sec."ApprovalRequest" USING btree ("RequestedByUserId", "Status");


CREATE INDEX "IX_sec_ApprovalReq_Status" ON sec."ApprovalRequest" USING btree ("CompanyId", "Status") WHERE (("Status")::text = 'PENDING'::text);


CREATE INDEX "IX_sec_ApprovalRule_Company" ON sec."ApprovalRule" USING btree ("CompanyId", "DocumentType", "IsActive") WHERE ("IsDeleted" = false);


CREATE INDEX "IX_sec_AuthToken_UserCode_Type_Expires" ON sec."AuthToken" USING btree ("UserCode", "TokenType", "ExpiresAtUtc", "ConsumedAtUtc");


CREATE INDEX "IX_sec_Permission_Module" ON sec."Permission" USING btree ("Module", "IsDeleted", "IsActive");


CREATE INDEX "IX_sec_PriceRestr_Role" ON sec."PriceRestriction" USING btree ("RoleId") WHERE (("RoleId" IS NOT NULL) AND ("IsDeleted" = false));


CREATE INDEX "IX_sec_PriceRestr_User" ON sec."PriceRestriction" USING btree ("UserId") WHERE (("UserId" IS NOT NULL) AND ("IsDeleted" = false));


CREATE INDEX "IX_sec_RolePermission_Permission" ON sec."RolePermission" USING btree ("PermissionId");


CREATE INDEX "IX_sec_RolePermission_Role" ON sec."RolePermission" USING btree ("RoleId");


CREATE INDEX "IX_sec_UPOverride_User" ON sec."UserPermissionOverride" USING btree ("UserId") WHERE ("IsDeleted" = false);


CREATE UNIQUE INDEX "UX_SupervisorBiometricCredential_UserHash" ON sec."SupervisorBiometricCredential" USING btree ("SupervisorUserCode", "CredentialHash");


CREATE UNIQUE INDEX "UX_sec_AuthIdentity_EmailNormalized" ON sec."AuthIdentity" USING btree ("EmailNormalized") WHERE ("EmailNormalized" IS NOT NULL);


CREATE UNIQUE INDEX "UX_sec_AuthToken_TokenHash" ON sec."AuthToken" USING btree ("TokenHash");


CREATE INDEX "IX_ProductAttribute_Product" ON store."ProductAttribute" USING btree ("CompanyId", "ProductCode", "IsDeleted", "IsActive");


CREATE INDEX "IX_ProductHighlight_Product" ON store."ProductHighlight" USING btree ("CompanyId", "ProductCode", "IsActive");


CREATE INDEX "IX_ProductReview_Product" ON store."ProductReview" USING btree ("CompanyId", "ProductCode", "IsDeleted", "IsApproved");


CREATE INDEX "IX_ProductSpec_Product" ON store."ProductSpec" USING btree ("CompanyId", "ProductCode", "IsActive");


CREATE INDEX "IX_ProductVariantGroup_Company" ON store."ProductVariantGroup" USING btree ("CompanyId", "IsDeleted", "IsActive");


CREATE INDEX "IX_ProductVariantOption_Group" ON store."ProductVariantOption" USING btree ("VariantGroupId", "IsDeleted", "IsActive");


CREATE INDEX "IX_ProductVariant_Parent" ON store."ProductVariant" USING btree ("CompanyId", "ParentProductCode", "IsDeleted", "IsActive");


CREATE INDEX "IX_TemplateAttribute_Template" ON store."IndustryTemplateAttribute" USING btree ("CompanyId", "TemplateCode", "IsDeleted", "IsActive");


CREATE INDEX "IX_PushDevice_User" ON sys."PushDevice" USING btree ("CompanyId", "UserId") WHERE ("IsActive" = true);


CREATE INDEX idx_backup_company ON sys."TenantBackup" USING btree ("CompanyId");


CREATE INDEX idx_backup_status ON sys."TenantBackup" USING btree ("Status");


CREATE INDEX idx_billing_event_company ON sys."BillingEvent" USING btree ("CompanyId", "CreatedAt");


CREATE INDEX idx_cleanup_status ON sys."CleanupQueue" USING btree ("Status") WHERE (("Status")::text = 'PENDING'::text);


CREATE INDEX idx_license_company ON sys."License" USING btree ("CompanyId");


CREATE INDEX idx_license_key ON sys."License" USING btree ("LicenseKey");


CREATE INDEX idx_resource_log_company ON sys."TenantResourceLog" USING btree ("CompanyId");


CREATE INDEX idx_resource_log_recorded ON sys."TenantResourceLog" USING btree ("RecordedAt" DESC);


CREATE INDEX idx_subscription_company ON sys."Subscription" USING btree ("CompanyId");

