-- ============================================
-- Zentto ERP — Constraint definitions (PK, FK, UNIQUE, CHECK)
-- Extracted from zentto_dev via pg_dump
-- Date: 2026-03-30
-- ============================================


ALTER TABLE ONLY acct."AccountMonetaryClass"
    ADD CONSTRAINT "AccountMonetaryClass_pkey" PRIMARY KEY ("AccountMonetaryClassId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "Account_pkey" PRIMARY KEY ("AccountId");


ALTER TABLE ONLY acct."AccountingPolicy"
    ADD CONSTRAINT "AccountingPolicy_pkey" PRIMARY KEY ("AccountingPolicyId");


ALTER TABLE ONLY acct."BankDeposit"
    ADD CONSTRAINT "BankDeposit_pkey" PRIMARY KEY ("BankDepositId");


ALTER TABLE ONLY acct."BudgetLine"
    ADD CONSTRAINT "BudgetLine_pkey" PRIMARY KEY ("BudgetLineId");


ALTER TABLE ONLY acct."Budget"
    ADD CONSTRAINT "Budget_pkey" PRIMARY KEY ("BudgetId");


ALTER TABLE ONLY acct."CostCenter"
    ADD CONSTRAINT "CostCenter_pkey" PRIMARY KEY ("CostCenterId");


ALTER TABLE ONLY acct."DocumentLink"
    ADD CONSTRAINT "DocumentLink_pkey" PRIMARY KEY ("DocumentLinkId");


ALTER TABLE ONLY acct."EquityMovement"
    ADD CONSTRAINT "EquityMovement_pkey" PRIMARY KEY ("EquityMovementId");


ALTER TABLE ONLY acct."FiscalPeriod"
    ADD CONSTRAINT "FiscalPeriod_pkey" PRIMARY KEY ("FiscalPeriodId");


ALTER TABLE ONLY acct."FixedAssetCategory"
    ADD CONSTRAINT "FixedAssetCategory_pkey" PRIMARY KEY ("CategoryId");


ALTER TABLE ONLY acct."FixedAssetDepreciation"
    ADD CONSTRAINT "FixedAssetDepreciation_pkey" PRIMARY KEY ("DepreciationId");


ALTER TABLE ONLY acct."FixedAssetImprovement"
    ADD CONSTRAINT "FixedAssetImprovement_pkey" PRIMARY KEY ("ImprovementId");


ALTER TABLE ONLY acct."FixedAssetRevaluation"
    ADD CONSTRAINT "FixedAssetRevaluation_pkey" PRIMARY KEY ("RevaluationId");


ALTER TABLE ONLY acct."FixedAsset"
    ADD CONSTRAINT "FixedAsset_pkey" PRIMARY KEY ("AssetId");


ALTER TABLE ONLY acct."InflationAdjustmentLine"
    ADD CONSTRAINT "InflationAdjustmentLine_pkey" PRIMARY KEY ("LineId");


ALTER TABLE ONLY acct."InflationAdjustment"
    ADD CONSTRAINT "InflationAdjustment_pkey" PRIMARY KEY ("InflationAdjustmentId");


ALTER TABLE ONLY acct."InflationIndex"
    ADD CONSTRAINT "InflationIndex_pkey" PRIMARY KEY ("InflationIndexId");


ALTER TABLE ONLY acct."JournalEntryLine"
    ADD CONSTRAINT "JournalEntryLine_pkey" PRIMARY KEY ("JournalEntryLineId");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "JournalEntry_pkey" PRIMARY KEY ("JournalEntryId");


ALTER TABLE ONLY acct."RecurringEntryLine"
    ADD CONSTRAINT "RecurringEntryLine_pkey" PRIMARY KEY ("LineId");


ALTER TABLE ONLY acct."RecurringEntry"
    ADD CONSTRAINT "RecurringEntry_pkey" PRIMARY KEY ("RecurringEntryId");


ALTER TABLE ONLY acct."ReportTemplateVariable"
    ADD CONSTRAINT "ReportTemplateVariable_pkey" PRIMARY KEY ("VariableId");


ALTER TABLE ONLY acct."ReportTemplate"
    ADD CONSTRAINT "ReportTemplate_pkey" PRIMARY KEY ("ReportTemplateId");


ALTER TABLE ONLY acct."FixedAssetDepreciation"
    ADD CONSTRAINT "UQ_AssetDeprec" UNIQUE ("AssetId", "PeriodCode");


ALTER TABLE ONLY acct."FixedAssetCategory"
    ADD CONSTRAINT "UQ_FixedAssetCategory" UNIQUE ("CompanyId", "CategoryCode", "CountryCode");


ALTER TABLE ONLY acct."FixedAsset"
    ADD CONSTRAINT "UQ_FixedAsset_Code" UNIQUE ("CompanyId", "AssetCode");


ALTER TABLE ONLY acct."AccountMonetaryClass"
    ADD CONSTRAINT "UQ_acct_AMC" UNIQUE ("CompanyId", "AccountId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "UQ_acct_Account" UNIQUE ("CompanyId", "AccountCode");


ALTER TABLE ONLY acct."DocumentLink"
    ADD CONSTRAINT "UQ_acct_DocLink" UNIQUE ("CompanyId", "BranchId", "ModuleCode", "DocumentType", "DocumentNumber");


ALTER TABLE ONLY acct."InflationAdjustment"
    ADD CONSTRAINT "UQ_acct_IA" UNIQUE ("CompanyId", "BranchId", "PeriodCode");


ALTER TABLE ONLY acct."InflationIndex"
    ADD CONSTRAINT "UQ_acct_II" UNIQUE ("CompanyId", "CountryCode", "IndexName", "PeriodCode");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "UQ_acct_JE" UNIQUE ("CompanyId", "BranchId", "EntryNumber");


ALTER TABLE ONLY acct."JournalEntryLine"
    ADD CONSTRAINT "UQ_acct_JEL" UNIQUE ("JournalEntryId", "LineNumber");


ALTER TABLE ONLY acct."AccountingPolicy"
    ADD CONSTRAINT "UQ_acct_Policy" UNIQUE ("CompanyId", "ModuleCode", "ProcessCode", "Nature", "AccountId");


ALTER TABLE ONLY acct."ReportTemplate"
    ADD CONSTRAINT "UQ_acct_RT" UNIQUE ("CompanyId", "CountryCode", "ReportCode");


ALTER TABLE ONLY acct."CostCenter"
    ADD CONSTRAINT uq_acct_cc UNIQUE ("CompanyId", "CostCenterCode");


ALTER TABLE ONLY acct."FiscalPeriod"
    ADD CONSTRAINT uq_acct_fp UNIQUE ("CompanyId", "PeriodCode");


ALTER TABLE ONLY ap."PurchaseDocument"
    ADD CONSTRAINT "PK_PurchaseDocument" PRIMARY KEY ("DocumentId");


ALTER TABLE ONLY ap."PurchaseDocumentLine"
    ADD CONSTRAINT "PK_PurchaseDocumentLine" PRIMARY KEY ("LineId");


ALTER TABLE ONLY ap."PurchaseDocumentPayment"
    ADD CONSTRAINT "PK_PurchaseDocumentPayment" PRIMARY KEY ("PaymentId");


ALTER TABLE ONLY ap."PayableApplication"
    ADD CONSTRAINT "PayableApplication_pkey" PRIMARY KEY ("PayableApplicationId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "PayableDocument_pkey" PRIMARY KEY ("PayableDocumentId");


ALTER TABLE ONLY ap."PurchaseDocument"
    ADD CONSTRAINT "UQ_PurchaseDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "UQ_ap_PayDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber");


ALTER TABLE ONLY ar."SalesDocument"
    ADD CONSTRAINT "PK_SalesDocument" PRIMARY KEY ("DocumentId");


ALTER TABLE ONLY ar."SalesDocumentLine"
    ADD CONSTRAINT "PK_SalesDocumentLine" PRIMARY KEY ("LineId");


ALTER TABLE ONLY ar."SalesDocumentPayment"
    ADD CONSTRAINT "PK_SalesDocumentPayment" PRIMARY KEY ("PaymentId");


ALTER TABLE ONLY ar."ReceivableApplication"
    ADD CONSTRAINT "ReceivableApplication_pkey" PRIMARY KEY ("ReceivableApplicationId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "ReceivableDocument_pkey" PRIMARY KEY ("ReceivableDocumentId");


ALTER TABLE ONLY ar."SalesDocument"
    ADD CONSTRAINT "UQ_SalesDocument_NumDocOp" UNIQUE ("DocumentNumber", "OperationType");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "UQ_ar_RecDoc" UNIQUE ("CompanyId", "BranchId", "DocumentType", "DocumentNumber");


ALTER TABLE ONLY audit."AuditLog"
    ADD CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("AuditLogId");


ALTER TABLE ONLY cfg."AppSetting"
    ADD CONSTRAINT "AppSetting_pkey" PRIMARY KEY ("SettingId");


ALTER TABLE ONLY cfg."Branch"
    ADD CONSTRAINT "Branch_pkey" PRIMARY KEY ("BranchId");


ALTER TABLE ONLY cfg."CompanyProfile"
    ADD CONSTRAINT "CompanyProfile_pkey" PRIMARY KEY ("ProfileId");


ALTER TABLE ONLY cfg."Company"
    ADD CONSTRAINT "Company_pkey" PRIMARY KEY ("CompanyId");


ALTER TABLE ONLY cfg."Country"
    ADD CONSTRAINT "Country_pkey" PRIMARY KEY ("CountryCode");


ALTER TABLE ONLY cfg."Currency"
    ADD CONSTRAINT "Currency_pkey" PRIMARY KEY ("CurrencyId");


ALTER TABLE ONLY cfg."DocumentSequence"
    ADD CONSTRAINT "DocumentSequence_pkey" PRIMARY KEY ("SequenceId");


ALTER TABLE ONLY cfg."EntityImage"
    ADD CONSTRAINT "EntityImage_pkey" PRIMARY KEY ("EntityImageId");


ALTER TABLE ONLY cfg."ExchangeRateDaily"
    ADD CONSTRAINT "ExchangeRateDaily_pkey" PRIMARY KEY ("ExchangeRateDailyId");


ALTER TABLE ONLY cfg."Holiday"
    ADD CONSTRAINT "Holiday_pkey" PRIMARY KEY ("HolidayId");


ALTER TABLE ONLY cfg."LookupType"
    ADD CONSTRAINT "LookupType_TypeCode_key" UNIQUE ("TypeCode");


ALTER TABLE ONLY cfg."LookupType"
    ADD CONSTRAINT "LookupType_pkey" PRIMARY KEY ("LookupTypeId");


ALTER TABLE ONLY cfg."Lookup"
    ADD CONSTRAINT "Lookup_LookupTypeId_Code_key" UNIQUE ("LookupTypeId", "Code");


ALTER TABLE ONLY cfg."Lookup"
    ADD CONSTRAINT "Lookup_pkey" PRIMARY KEY ("LookupId");


ALTER TABLE ONLY cfg."MediaAsset"
    ADD CONSTRAINT "MediaAsset_pkey" PRIMARY KEY ("MediaAssetId");


ALTER TABLE ONLY cfg."ReportTemplate"
    ADD CONSTRAINT "ReportTemplate_pkey" PRIMARY KEY ("ReportId");


ALTER TABLE ONLY cfg."State"
    ADD CONSTRAINT "State_CountryCode_StateCode_key" UNIQUE ("CountryCode", "StateCode");


ALTER TABLE ONLY cfg."State"
    ADD CONSTRAINT "State_pkey" PRIMARY KEY ("StateId");


ALTER TABLE ONLY cfg."TaxUnit"
    ADD CONSTRAINT "TaxUnit_pkey" PRIMARY KEY ("TaxUnitId");


ALTER TABLE ONLY cfg."AppSetting"
    ADD CONSTRAINT "UQ_AppSetting_Company_Module_Key" UNIQUE ("CompanyId", "Module", "SettingKey");


ALTER TABLE ONLY cfg."Currency"
    ADD CONSTRAINT "UQ_Currency_Code" UNIQUE ("CurrencyCode");


ALTER TABLE ONLY cfg."Branch"
    ADD CONSTRAINT "UQ_cfg_Branch" UNIQUE ("CompanyId", "BranchCode");


ALTER TABLE ONLY cfg."Company"
    ADD CONSTRAINT "UQ_cfg_Company_CompanyCode" UNIQUE ("CompanyCode");


ALTER TABLE ONLY cfg."ExchangeRateDaily"
    ADD CONSTRAINT "UQ_cfg_ExchangeRateDaily" UNIQUE ("CurrencyCode", "RateDate");


ALTER TABLE ONLY cfg."TaxUnit"
    ADD CONSTRAINT "UQ_cfg_TaxUnit" UNIQUE ("CountryCode", "TaxYear", "EffectiveDate");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "Activity_pkey" PRIMARY KEY ("ActivityId");


ALTER TABLE ONLY crm."Agent"
    ADD CONSTRAINT "Agent_pkey" PRIMARY KEY ("AgentId");


ALTER TABLE ONLY crm."AutomationLog"
    ADD CONSTRAINT "AutomationLog_pkey" PRIMARY KEY ("LogId");


ALTER TABLE ONLY crm."AutomationRule"
    ADD CONSTRAINT "AutomationRule_pkey" PRIMARY KEY ("RuleId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_pkey" PRIMARY KEY ("CallLogId");


ALTER TABLE ONLY crm."CallQueue"
    ADD CONSTRAINT "CallQueue_pkey" PRIMARY KEY ("QueueId");


ALTER TABLE ONLY crm."CallScript"
    ADD CONSTRAINT "CallScript_pkey" PRIMARY KEY ("ScriptId");


ALTER TABLE ONLY crm."CampaignContact"
    ADD CONSTRAINT "CampaignContact_pkey" PRIMARY KEY ("CampaignContactId");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "Campaign_pkey" PRIMARY KEY ("CampaignId");


ALTER TABLE ONLY crm."LeadHistory"
    ADD CONSTRAINT "LeadHistory_pkey" PRIMARY KEY ("HistoryId");


ALTER TABLE ONLY crm."LeadScore"
    ADD CONSTRAINT "LeadScore_pkey" PRIMARY KEY ("LeadScoreId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "Lead_pkey" PRIMARY KEY ("LeadId");


ALTER TABLE ONLY crm."PipelineStage"
    ADD CONSTRAINT "PipelineStage_pkey" PRIMARY KEY ("StageId");


ALTER TABLE ONLY crm."Pipeline"
    ADD CONSTRAINT "Pipeline_pkey" PRIMARY KEY ("PipelineId");


ALTER TABLE ONLY crm."SavedView"
    ADD CONSTRAINT "PK_crm_SavedView" PRIMARY KEY ("ViewId");


ALTER TABLE ONLY crm."SavedView"
    ADD CONSTRAINT "UQ_crm_SavedView_Name" UNIQUE ("CompanyId", "UserId", "Entity", "Name");


ALTER TABLE ONLY crm."Agent"
    ADD CONSTRAINT "UQ_Agent_Code" UNIQUE ("CompanyId", "AgentCode");


ALTER TABLE ONLY crm."CallQueue"
    ADD CONSTRAINT "UQ_CallQueue_Code" UNIQUE ("CompanyId", "QueueCode");


ALTER TABLE ONLY crm."CallScript"
    ADD CONSTRAINT "UQ_CallScript_Code" UNIQUE ("CompanyId", "ScriptCode");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "UQ_Campaign_Code" UNIQUE ("CompanyId", "CampaignCode");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "BankAccount_pkey" PRIMARY KEY ("BankAccountId");


ALTER TABLE ONLY fin."BankMovement"
    ADD CONSTRAINT "BankMovement_pkey" PRIMARY KEY ("BankMovementId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "BankReconciliationMatch_pkey" PRIMARY KEY ("BankReconciliationMatchId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "BankReconciliation_pkey" PRIMARY KEY ("BankReconciliationId");


ALTER TABLE ONLY fin."BankStatementLine"
    ADD CONSTRAINT "BankStatementLine_pkey" PRIMARY KEY ("StatementLineId");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "Bank_pkey" PRIMARY KEY ("BankId");


ALTER TABLE ONLY fin."PettyCashBox"
    ADD CONSTRAINT "PettyCashBox_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY fin."PettyCashExpense"
    ADD CONSTRAINT "PettyCashExpense_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY fin."PettyCashSession"
    ADD CONSTRAINT "PettyCashSession_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "UQ_fin_BankAccount" UNIQUE ("CompanyId", "AccountNumber");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "UQ_fin_BankRecMatch_Movement" UNIQUE ("ReconciliationId", "BankMovementId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "UQ_fin_BankRecMatch_Statement" UNIQUE ("ReconciliationId", "StatementLineId");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "UQ_fin_Bank_Code" UNIQUE ("CompanyId", "BankCode");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "UQ_fin_Bank_Name" UNIQUE ("CompanyId", "BankName");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "CountryConfig_pkey" PRIMARY KEY ("CountryConfigId");


ALTER TABLE ONLY fiscal."InvoiceType"
    ADD CONSTRAINT "InvoiceType_pkey" PRIMARY KEY ("InvoiceTypeId");


ALTER TABLE ONLY fiscal."DeclarationTemplate"
    ADD CONSTRAINT "PK_DeclarationTemplate" PRIMARY KEY ("TemplateId");


ALTER TABLE ONLY fiscal."ISLRTariff"
    ADD CONSTRAINT "PK_ISLRTariff" PRIMARY KEY ("TariffId");


ALTER TABLE ONLY fiscal."TaxBookEntry"
    ADD CONSTRAINT "PK_TaxBookEntry" PRIMARY KEY ("EntryId");


ALTER TABLE ONLY fiscal."TaxDeclaration"
    ADD CONSTRAINT "PK_TaxDeclaration" PRIMARY KEY ("DeclarationId");


ALTER TABLE ONLY fiscal."WithholdingVoucher"
    ADD CONSTRAINT "PK_WithholdingVoucher" PRIMARY KEY ("VoucherId");


ALTER TABLE ONLY fiscal."Record"
    ADD CONSTRAINT "Record_pkey" PRIMARY KEY ("FiscalRecordId");


ALTER TABLE ONLY fiscal."TaxRate"
    ADD CONSTRAINT "TaxRate_pkey" PRIMARY KEY ("TaxRateId");


ALTER TABLE ONLY fiscal."DeclarationTemplate"
    ADD CONSTRAINT "UQ_DeclTemplate" UNIQUE ("CountryCode", "DeclarationType");


ALTER TABLE ONLY fiscal."TaxDeclaration"
    ADD CONSTRAINT "UQ_TaxDeclaration" UNIQUE ("CompanyId", "DeclarationType", "PeriodCode");


ALTER TABLE ONLY fiscal."WithholdingVoucher"
    ADD CONSTRAINT "UQ_WithholdingVoucher" UNIQUE ("CompanyId", "VoucherNumber");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "UQ_fiscal_CountryCfg" UNIQUE ("CompanyId", "BranchId", "CountryCode");


ALTER TABLE ONLY fiscal."InvoiceType"
    ADD CONSTRAINT "UQ_fiscal_InvType" UNIQUE ("CountryCode", "InvoiceTypeCode");


ALTER TABLE ONLY fiscal."Record"
    ADD CONSTRAINT "UQ_fiscal_Record_Hash" UNIQUE ("RecordHash");


ALTER TABLE ONLY fiscal."TaxRate"
    ADD CONSTRAINT "UQ_fiscal_TaxRate" UNIQUE ("CountryCode", "TaxCode");


ALTER TABLE ONLY fiscal."WithholdingConcept"
    ADD CONSTRAINT "UQ_fiscal_WHConcept" UNIQUE ("CompanyId", "CountryCode", "ConceptCode");


ALTER TABLE ONLY fiscal."WithholdingConcept"
    ADD CONSTRAINT "WithholdingConcept_pkey" PRIMARY KEY ("ConceptId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FuelLog_pkey" PRIMARY KEY ("FuelLogId");


ALTER TABLE ONLY fleet."MaintenanceOrderLine"
    ADD CONSTRAINT "MaintenanceOrderLine_pkey" PRIMARY KEY ("MaintenanceOrderLineId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "MaintenanceOrder_pkey" PRIMARY KEY ("MaintenanceOrderId");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "MaintenanceType_pkey" PRIMARY KEY ("MaintenanceTypeId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "Trip_pkey" PRIMARY KEY ("TripId");


ALTER TABLE ONLY fleet."MaintenanceOrderLine"
    ADD CONSTRAINT "UQ_fleet_MOLine" UNIQUE ("MaintenanceOrderId", "LineNumber");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "UQ_fleet_MaintOrder_Number" UNIQUE ("CompanyId", "OrderNumber");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "UQ_fleet_MaintType_Code" UNIQUE ("CompanyId", "TypeCode");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "UQ_fleet_Trip_Number" UNIQUE ("CompanyId", "TripNumber");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "UQ_fleet_Vehicle_Code" UNIQUE ("CompanyId", "VehicleCode");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "UQ_fleet_Vehicle_Plate" UNIQUE ("CompanyId", "LicensePlate");


ALTER TABLE ONLY fleet."VehicleDocument"
    ADD CONSTRAINT "VehicleDocument_pkey" PRIMARY KEY ("VehicleDocumentId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("VehicleId");


ALTER TABLE ONLY hr."DocumentTemplate"
    ADD CONSTRAINT "DocumentTemplate_pkey" PRIMARY KEY ("TemplateId");


ALTER TABLE ONLY hr."EmployeeTaxProfile"
    ADD CONSTRAINT "EmployeeTaxProfile_pkey" PRIMARY KEY ("ProfileId");


ALTER TABLE ONLY hr."MedicalExam"
    ADD CONSTRAINT "MedicalExam_pkey" PRIMARY KEY ("MedicalExamId");


ALTER TABLE ONLY hr."MedicalOrder"
    ADD CONSTRAINT "MedicalOrder_pkey" PRIMARY KEY ("MedicalOrderId");


ALTER TABLE ONLY hr."OccupationalHealth"
    ADD CONSTRAINT "OccupationalHealth_pkey" PRIMARY KEY ("OccupationalHealthId");


ALTER TABLE ONLY hr."EmployeeObligation"
    ADD CONSTRAINT "PK_EmployeeObligation" PRIMARY KEY ("EmployeeObligationId");


ALTER TABLE ONLY hr."LegalObligation"
    ADD CONSTRAINT "PK_LegalObligation" PRIMARY KEY ("LegalObligationId");


ALTER TABLE ONLY hr."ObligationFiling"
    ADD CONSTRAINT "PK_ObligationFiling" PRIMARY KEY ("ObligationFilingId");


ALTER TABLE ONLY hr."ObligationFilingDetail"
    ADD CONSTRAINT "PK_ObligationFilingDetail" PRIMARY KEY ("DetailId");


ALTER TABLE ONLY hr."ObligationRiskLevel"
    ADD CONSTRAINT "PK_ObligationRiskLevel" PRIMARY KEY ("ObligationRiskLevelId");


ALTER TABLE ONLY hr."PayrollCalcVariable"
    ADD CONSTRAINT "PK_PayrollCalcVariable" PRIMARY KEY ("SessionID", "Variable");


ALTER TABLE ONLY hr."PayrollBatchLine"
    ADD CONSTRAINT "PayrollBatchLine_pkey" PRIMARY KEY ("LineId");


ALTER TABLE ONLY hr."PayrollBatch"
    ADD CONSTRAINT "PayrollBatch_pkey" PRIMARY KEY ("BatchId");


ALTER TABLE ONLY hr."PayrollConcept"
    ADD CONSTRAINT "PayrollConcept_pkey" PRIMARY KEY ("PayrollConceptId");


ALTER TABLE ONLY hr."PayrollConstant"
    ADD CONSTRAINT "PayrollConstant_pkey" PRIMARY KEY ("PayrollConstantId");


ALTER TABLE ONLY hr."PayrollRunLine"
    ADD CONSTRAINT "PayrollRunLine_pkey" PRIMARY KEY ("PayrollRunLineId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "PayrollRun_pkey" PRIMARY KEY ("PayrollRunId");


ALTER TABLE ONLY hr."PayrollType"
    ADD CONSTRAINT "PayrollType_pkey" PRIMARY KEY ("PayrollTypeId");


ALTER TABLE ONLY hr."ProfitSharingLine"
    ADD CONSTRAINT "ProfitSharingLine_pkey" PRIMARY KEY ("LineId");


ALTER TABLE ONLY hr."ProfitSharing"
    ADD CONSTRAINT "ProfitSharing_pkey" PRIMARY KEY ("ProfitSharingId");


ALTER TABLE ONLY hr."SafetyCommitteeMeeting"
    ADD CONSTRAINT "SafetyCommitteeMeeting_pkey" PRIMARY KEY ("MeetingId");


ALTER TABLE ONLY hr."SafetyCommitteeMember"
    ADD CONSTRAINT "SafetyCommitteeMember_pkey" PRIMARY KEY ("MemberId");


ALTER TABLE ONLY hr."SafetyCommittee"
    ADD CONSTRAINT "SafetyCommittee_pkey" PRIMARY KEY ("SafetyCommitteeId");


ALTER TABLE ONLY hr."SavingsFundTransaction"
    ADD CONSTRAINT "SavingsFundTransaction_pkey" PRIMARY KEY ("TransactionId");


ALTER TABLE ONLY hr."SavingsFund"
    ADD CONSTRAINT "SavingsFund_pkey" PRIMARY KEY ("SavingsFundId");


ALTER TABLE ONLY hr."SavingsLoan"
    ADD CONSTRAINT "SavingsLoan_pkey" PRIMARY KEY ("LoanId");


ALTER TABLE ONLY hr."SettlementProcessLine"
    ADD CONSTRAINT "SettlementProcessLine_pkey" PRIMARY KEY ("SettlementProcessLineId");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "SettlementProcess_pkey" PRIMARY KEY ("SettlementProcessId");


ALTER TABLE ONLY hr."SocialBenefitsTrust"
    ADD CONSTRAINT "SocialBenefitsTrust_pkey" PRIMARY KEY ("TrustId");


ALTER TABLE ONLY hr."TrainingRecord"
    ADD CONSTRAINT "TrainingRecord_pkey" PRIMARY KEY ("TrainingRecordId");


ALTER TABLE ONLY hr."LegalObligation"
    ADD CONSTRAINT "UQ_LegalObligation_Country_Code_From" UNIQUE ("CountryCode", "Code", "EffectiveFrom");


ALTER TABLE ONLY hr."ObligationRiskLevel"
    ADD CONSTRAINT "UQ_ObligationRiskLevel" UNIQUE ("LegalObligationId", "RiskLevel");


ALTER TABLE ONLY hr."DocumentTemplate"
    ADD CONSTRAINT "UQ_hr_DocumentTemplate" UNIQUE ("CompanyId", "TemplateCode");


ALTER TABLE ONLY hr."EmployeeTaxProfile"
    ADD CONSTRAINT "UQ_hr_EmpTaxProfile" UNIQUE ("EmployeeId", "TaxYear");


ALTER TABLE ONLY hr."PayrollConcept"
    ADD CONSTRAINT "UQ_hr_PayrollConcept" UNIQUE ("CompanyId", "PayrollCode", "ConceptCode", "ConventionCode", "CalculationType");


ALTER TABLE ONLY hr."PayrollConstant"
    ADD CONSTRAINT "UQ_hr_PayrollConstant" UNIQUE ("CompanyId", "ConstantCode");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "UQ_hr_PayrollRun" UNIQUE ("CompanyId", "BranchId", "PayrollCode", "EmployeeCode", "DateFrom", "DateTo", "RunSource");


ALTER TABLE ONLY hr."PayrollType"
    ADD CONSTRAINT "UQ_hr_PayrollType" UNIQUE ("CompanyId", "PayrollCode");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "UQ_hr_SettlementProcess" UNIQUE ("CompanyId", "SettlementCode");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "UQ_hr_VacationProcess" UNIQUE ("CompanyId", "VacationCode");


ALTER TABLE ONLY hr."SavingsFund"
    ADD CONSTRAINT "UX_SavingsFund_Employee" UNIQUE ("CompanyId", "EmployeeCode");


ALTER TABLE ONLY hr."SocialBenefitsTrust"
    ADD CONSTRAINT "UX_Trust_Employee_Quarter" UNIQUE ("CompanyId", "EmployeeCode", "FiscalYear", "Quarter");


ALTER TABLE ONLY hr."VacationProcessLine"
    ADD CONSTRAINT "VacationProcessLine_pkey" PRIMARY KEY ("VacationProcessLineId");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "VacationProcess_pkey" PRIMARY KEY ("VacationProcessId");


ALTER TABLE ONLY hr."VacationRequestDay"
    ADD CONSTRAINT "VacationRequestDay_pkey" PRIMARY KEY ("DayId");


ALTER TABLE ONLY hr."VacationRequest"
    ADD CONSTRAINT "VacationRequest_pkey" PRIMARY KEY ("RequestId");


ALTER TABLE ONLY inv."InventoryValuationLayer"
    ADD CONSTRAINT "InventoryValuationLayer_pkey" PRIMARY KEY ("LayerId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "InventoryValuationMethod_pkey" PRIMARY KEY ("ValuationMethodId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "ProductBinStock_pkey" PRIMARY KEY ("ProductBinStockId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "ProductLot_pkey" PRIMARY KEY ("LotId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "ProductSerial_pkey" PRIMARY KEY ("SerialId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "StockMovement_pkey" PRIMARY KEY ("MovementId");


ALTER TABLE ONLY inv."WarehouseBin"
    ADD CONSTRAINT "WarehouseBin_pkey" PRIMARY KEY ("BinId");


ALTER TABLE ONLY inv."WarehouseZone"
    ADD CONSTRAINT "WarehouseZone_pkey" PRIMARY KEY ("ZoneId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "Warehouse_pkey" PRIMARY KEY ("WarehouseId");


ALTER TABLE ONLY logistics."Carrier"
    ADD CONSTRAINT "Carrier_pkey" PRIMARY KEY ("CarrierId");


ALTER TABLE ONLY logistics."DeliveryNoteLine"
    ADD CONSTRAINT "DeliveryNoteLine_pkey" PRIMARY KEY ("DeliveryNoteLineId");


ALTER TABLE ONLY logistics."DeliveryNoteSerial"
    ADD CONSTRAINT "DeliveryNoteSerial_pkey" PRIMARY KEY ("DeliveryNoteSerialId");


ALTER TABLE ONLY logistics."DeliveryNote"
    ADD CONSTRAINT "DeliveryNote_pkey" PRIMARY KEY ("DeliveryNoteId");


ALTER TABLE ONLY logistics."Driver"
    ADD CONSTRAINT "Driver_pkey" PRIMARY KEY ("DriverId");


ALTER TABLE ONLY logistics."GoodsReceiptLine"
    ADD CONSTRAINT "GoodsReceiptLine_pkey" PRIMARY KEY ("GoodsReceiptLineId");


ALTER TABLE ONLY logistics."GoodsReceiptSerial"
    ADD CONSTRAINT "GoodsReceiptSerial_pkey" PRIMARY KEY ("GoodsReceiptSerialId");


ALTER TABLE ONLY logistics."GoodsReceipt"
    ADD CONSTRAINT "GoodsReceipt_pkey" PRIMARY KEY ("GoodsReceiptId");


ALTER TABLE ONLY logistics."GoodsReturnLine"
    ADD CONSTRAINT "GoodsReturnLine_pkey" PRIMARY KEY ("GoodsReturnLineId");


ALTER TABLE ONLY logistics."GoodsReturn"
    ADD CONSTRAINT "GoodsReturn_pkey" PRIMARY KEY ("GoodsReturnId");


ALTER TABLE ONLY master."AlternateStock"
    ADD CONSTRAINT "AlternateStock_pkey" PRIMARY KEY ("AlternateStockId");


ALTER TABLE ONLY master."Brand"
    ADD CONSTRAINT "Brand_pkey" PRIMARY KEY ("BrandId");


ALTER TABLE ONLY master."Category"
    ADD CONSTRAINT "Category_pkey" PRIMARY KEY ("CategoryId");


ALTER TABLE ONLY master."CostCenter"
    ADD CONSTRAINT "CostCenter_pkey" PRIMARY KEY ("CostCenterId");


ALTER TABLE ONLY master."CustomerAddress"
    ADD CONSTRAINT "CustomerAddress_pkey" PRIMARY KEY ("AddressId");


ALTER TABLE ONLY master."CustomerPaymentMethod"
    ADD CONSTRAINT "CustomerPaymentMethod_pkey" PRIMARY KEY ("PaymentMethodId");


ALTER TABLE ONLY master."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY ("CustomerId");


ALTER TABLE ONLY master."Employee"
    ADD CONSTRAINT "Employee_pkey" PRIMARY KEY ("EmployeeId");


ALTER TABLE ONLY master."InventoryMovement"
    ADD CONSTRAINT "InventoryMovement_pkey" PRIMARY KEY ("MovementId");


ALTER TABLE ONLY master."InventoryPeriodSummary"
    ADD CONSTRAINT "InventoryPeriodSummary_pkey" PRIMARY KEY ("SummaryId");


ALTER TABLE ONLY master."ProductClass"
    ADD CONSTRAINT "ProductClass_pkey" PRIMARY KEY ("ClassId");


ALTER TABLE ONLY master."ProductGroup"
    ADD CONSTRAINT "ProductGroup_pkey" PRIMARY KEY ("GroupId");


ALTER TABLE ONLY master."ProductLine"
    ADD CONSTRAINT "ProductLine_pkey" PRIMARY KEY ("LineId");


ALTER TABLE ONLY master."ProductType"
    ADD CONSTRAINT "ProductType_pkey" PRIMARY KEY ("TypeId");


ALTER TABLE ONLY master."Product"
    ADD CONSTRAINT "Product_pkey" PRIMARY KEY ("ProductId");


ALTER TABLE ONLY master."Seller"
    ADD CONSTRAINT "Seller_pkey" PRIMARY KEY ("SellerId");


ALTER TABLE ONLY master."SupplierLine"
    ADD CONSTRAINT "SupplierLine_pkey" PRIMARY KEY ("SupplierLineId");


ALTER TABLE ONLY master."Supplier"
    ADD CONSTRAINT "Supplier_pkey" PRIMARY KEY ("SupplierId");


ALTER TABLE ONLY master."TaxRetention"
    ADD CONSTRAINT "TaxRetention_pkey" PRIMARY KEY ("RetentionId");


ALTER TABLE ONLY master."AlternateStock"
    ADD CONSTRAINT "UQ_AlternateStock_ProductCode" UNIQUE ("ProductCode");


ALTER TABLE ONLY master."Customer"
    ADD CONSTRAINT "UQ_master_Customer" UNIQUE ("CompanyId", "CustomerCode");


ALTER TABLE ONLY master."Employee"
    ADD CONSTRAINT "UQ_master_Employee" UNIQUE ("CompanyId", "EmployeeCode");


ALTER TABLE ONLY master."Product"
    ADD CONSTRAINT "UQ_master_Product" UNIQUE ("CompanyId", "ProductCode");


ALTER TABLE ONLY master."Supplier"
    ADD CONSTRAINT "UQ_master_Supplier" UNIQUE ("CompanyId", "SupplierCode");


ALTER TABLE ONLY master."UnitOfMeasure"
    ADD CONSTRAINT "UnitOfMeasure_pkey" PRIMARY KEY ("UnitId");


ALTER TABLE ONLY master."Warehouse"
    ADD CONSTRAINT "Warehouse_pkey" PRIMARY KEY ("WarehouseId");


ALTER TABLE ONLY mfg."BOMLine"
    ADD CONSTRAINT "BOMLine_pkey" PRIMARY KEY ("BOMLineId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "BillOfMaterials_pkey" PRIMARY KEY ("BOMId");


ALTER TABLE ONLY mfg."Routing"
    ADD CONSTRAINT "Routing_pkey" PRIMARY KEY ("RoutingId");


ALTER TABLE ONLY mfg."BOMLine"
    ADD CONSTRAINT "UQ_mfg_BOMLine" UNIQUE ("BOMId", "LineNumber");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "UQ_mfg_BOM_Code" UNIQUE ("CompanyId", "BOMCode");


ALTER TABLE ONLY mfg."Routing"
    ADD CONSTRAINT "UQ_mfg_Routing_Operation" UNIQUE ("BOMId", "OperationNumber");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "UQ_mfg_WOMaterial" UNIQUE ("WorkOrderId", "LineNumber");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "UQ_mfg_WorkCenter_Code" UNIQUE ("CompanyId", "WorkCenterCode");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "UQ_mfg_WorkOrder_Number" UNIQUE ("CompanyId", "WorkOrderNumber");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "WorkCenter_pkey" PRIMARY KEY ("WorkCenterId");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "WorkOrderMaterial_pkey" PRIMARY KEY ("WorkOrderMaterialId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "WorkOrderOutput_pkey" PRIMARY KEY ("WorkOrderOutputId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "WorkOrder_pkey" PRIMARY KEY ("WorkOrderId");


ALTER TABLE ONLY pay."AcceptedPaymentMethods"
    ADD CONSTRAINT "AcceptedPaymentMethods_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."CardReaderDevices"
    ADD CONSTRAINT "CardReaderDevices_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."CompanyPaymentConfig"
    ADD CONSTRAINT "CompanyPaymentConfig_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."PaymentMethods"
    ADD CONSTRAINT "PaymentMethods_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."PaymentProviders"
    ADD CONSTRAINT "PaymentProviders_Code_key" UNIQUE ("Code");


ALTER TABLE ONLY pay."PaymentProviders"
    ADD CONSTRAINT "PaymentProviders_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."ProviderCapabilities"
    ADD CONSTRAINT "ProviderCapabilities_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."ReconciliationBatches"
    ADD CONSTRAINT "ReconciliationBatches_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."Transactions"
    ADD CONSTRAINT "Transactions_TransactionUUID_key" UNIQUE ("TransactionUUID");


ALTER TABLE ONLY pay."Transactions"
    ADD CONSTRAINT "Transactions_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY pay."AcceptedPaymentMethods"
    ADD CONSTRAINT "UQ_AcceptedPM" UNIQUE ("EmpresaId", "SucursalId", "PaymentMethodId", "ProviderId");


ALTER TABLE ONLY pay."CompanyPaymentConfig"
    ADD CONSTRAINT "UQ_CompanyPayConfig" UNIQUE ("EmpresaId", "SucursalId", "ProviderId");


ALTER TABLE ONLY pay."PaymentMethods"
    ADD CONSTRAINT "UQ_PayMethod" UNIQUE ("Code", "CountryCode");


ALTER TABLE ONLY pay."ProviderCapabilities"
    ADD CONSTRAINT "UQ_ProvCap" UNIQUE ("ProviderId", "Capability", "PaymentMethod");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "FiscalCorrelative_pkey" PRIMARY KEY ("FiscalCorrelativeId");


ALTER TABLE ONLY pos."SaleTicketLine"
    ADD CONSTRAINT "SaleTicketLine_pkey" PRIMARY KEY ("SaleTicketLineId");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "SaleTicket_pkey" PRIMARY KEY ("SaleTicketId");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "UQ_pos_FiscalCorrelative" UNIQUE ("CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "UQ_pos_SaleTicket" UNIQUE ("CompanyId", "BranchId", "InvoiceNumber");


ALTER TABLE ONLY pos."SaleTicketLine"
    ADD CONSTRAINT "UQ_pos_SaleTicketLine" UNIQUE ("SaleTicketId", "LineNumber");


ALTER TABLE ONLY pos."WaitTicketLine"
    ADD CONSTRAINT "UQ_pos_WaitTicketLine" UNIQUE ("WaitTicketId", "LineNumber");


ALTER TABLE ONLY pos."WaitTicketLine"
    ADD CONSTRAINT "WaitTicketLine_pkey" PRIMARY KEY ("WaitTicketLineId");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "WaitTicket_pkey" PRIMARY KEY ("WaitTicketId");


ALTER TABLE ONLY public."ConciliacionBancaria"
    ADD CONSTRAINT "ConciliacionBancaria_pkey" PRIMARY KEY ("ID");


ALTER TABLE ONLY public."ConciliacionDetalle"
    ADD CONSTRAINT "ConciliacionDetalle_pkey" PRIMARY KEY ("ID");


ALTER TABLE ONLY public."ExtractoBancario"
    ADD CONSTRAINT "ExtractoBancario_pkey" PRIMARY KEY ("ID");


ALTER TABLE ONLY public."Lead"
    ADD CONSTRAINT "Lead_pkey" PRIMARY KEY ("LeadId");


ALTER TABLE ONLY public."PosVentasDetalle"
    ADD CONSTRAINT "PosVentasDetalle_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."PosVentasEnEsperaDetalle"
    ADD CONSTRAINT "PosVentasEnEsperaDetalle_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."PosVentasEnEspera"
    ADD CONSTRAINT "PosVentasEnEspera_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."PosVentas"
    ADD CONSTRAINT "PosVentas_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteAmbientes"
    ADD CONSTRAINT "RestauranteAmbientes_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteCategorias"
    ADD CONSTRAINT "RestauranteCategorias_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteComponenteOpciones"
    ADD CONSTRAINT "RestauranteComponenteOpciones_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteComprasDetalle"
    ADD CONSTRAINT "RestauranteComprasDetalle_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteCompras"
    ADD CONSTRAINT "RestauranteCompras_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteMesas"
    ADD CONSTRAINT "RestauranteMesas_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestaurantePedidoItems"
    ADD CONSTRAINT "RestaurantePedidoItems_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestaurantePedidos"
    ADD CONSTRAINT "RestaurantePedidos_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteProductoComponentes"
    ADD CONSTRAINT "RestauranteProductoComponentes_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteProductos"
    ADD CONSTRAINT "RestauranteProductos_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."RestauranteRecetas"
    ADD CONSTRAINT "RestauranteRecetas_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."SchemaGovernanceDecision"
    ADD CONSTRAINT "SchemaGovernanceDecision_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."SchemaGovernanceSnapshot"
    ADD CONSTRAINT "SchemaGovernanceSnapshot_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."Sys_Mensajes"
    ADD CONSTRAINT "Sys_Mensajes_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."Sys_Notificaciones"
    ADD CONSTRAINT "Sys_Notificaciones_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."Sys_Tareas"
    ADD CONSTRAINT "Sys_Tareas_pkey" PRIMARY KEY ("Id");


ALTER TABLE ONLY public."Lead"
    ADD CONSTRAINT "UQ_Lead_Email" UNIQUE ("Email");


ALTER TABLE ONLY public."PosVentas"
    ADD CONSTRAINT "UQ_PosVentas_NumFact" UNIQUE ("NumFactura");


ALTER TABLE ONLY public."RestauranteCompras"
    ADD CONSTRAINT "UQ_RestCompra_Num" UNIQUE ("NumCompra");


ALTER TABLE ONLY public."RestauranteProductos"
    ADD CONSTRAINT "UQ_RestProd_Codigo" UNIQUE ("Codigo");


ALTER TABLE ONLY public._migrations
    ADD CONSTRAINT _migrations_name_key UNIQUE (name);


ALTER TABLE ONLY public._migrations
    ADD CONSTRAINT _migrations_pkey PRIMARY KEY (id);


ALTER TABLE ONLY public.goose_db_version
    ADD CONSTRAINT goose_db_version_pkey PRIMARY KEY (id);


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "DiningTable_pkey" PRIMARY KEY ("DiningTableId");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "MenuCategory_pkey" PRIMARY KEY ("MenuCategoryId");


ALTER TABLE ONLY rest."MenuComponent"
    ADD CONSTRAINT "MenuComponent_pkey" PRIMARY KEY ("MenuComponentId");


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "MenuEnvironment_pkey" PRIMARY KEY ("MenuEnvironmentId");


ALTER TABLE ONLY rest."MenuOption"
    ADD CONSTRAINT "MenuOption_pkey" PRIMARY KEY ("MenuOptionId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "MenuProduct_pkey" PRIMARY KEY ("MenuProductId");


ALTER TABLE ONLY rest."MenuRecipe"
    ADD CONSTRAINT "MenuRecipe_pkey" PRIMARY KEY ("MenuRecipeId");


ALTER TABLE ONLY rest."OrderTicketLine"
    ADD CONSTRAINT "OrderTicketLine_pkey" PRIMARY KEY ("OrderTicketLineId");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "OrderTicket_pkey" PRIMARY KEY ("OrderTicketId");


ALTER TABLE ONLY rest."PurchaseLine"
    ADD CONSTRAINT "PurchaseLine_pkey" PRIMARY KEY ("PurchaseLineId");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "Purchase_pkey" PRIMARY KEY ("PurchaseId");


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "UQ_rest_DiningTable" UNIQUE ("CompanyId", "BranchId", "TableNumber");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "UQ_rest_MenuCategory" UNIQUE ("CompanyId", "BranchId", "CategoryCode");


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "UQ_rest_MenuEnvironment" UNIQUE ("CompanyId", "BranchId", "EnvironmentCode");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "UQ_rest_MenuProduct" UNIQUE ("CompanyId", "BranchId", "ProductCode");


ALTER TABLE ONLY rest."OrderTicketLine"
    ADD CONSTRAINT "UQ_rest_OrderTicketLine" UNIQUE ("OrderTicketId", "LineNumber");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "UQ_rest_Purchase" UNIQUE ("CompanyId", "BranchId", "PurchaseNumber");


ALTER TABLE ONLY sec."ApprovalAction"
    ADD CONSTRAINT "ApprovalAction_pkey" PRIMARY KEY ("ApprovalActionId");


ALTER TABLE ONLY sec."ApprovalRequest"
    ADD CONSTRAINT "ApprovalRequest_pkey" PRIMARY KEY ("ApprovalRequestId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "ApprovalRule_pkey" PRIMARY KEY ("ApprovalRuleId");


ALTER TABLE ONLY sec."AuthToken"
    ADD CONSTRAINT "AuthToken_pkey" PRIMARY KEY ("TokenId");


ALTER TABLE ONLY sec."AuthIdentity"
    ADD CONSTRAINT "PK_sec_AuthIdentity" PRIMARY KEY ("UserCode");


ALTER TABLE ONLY sec."Permission"
    ADD CONSTRAINT "Permission_pkey" PRIMARY KEY ("PermissionId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "PriceRestriction_pkey" PRIMARY KEY ("PriceRestrictionId");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "RolePermission_pkey" PRIMARY KEY ("RolePermissionId");


ALTER TABLE ONLY sec."Role"
    ADD CONSTRAINT "Role_pkey" PRIMARY KEY ("RoleId");


ALTER TABLE ONLY sec."SupervisorBiometricCredential"
    ADD CONSTRAINT "SupervisorBiometricCredential_pkey" PRIMARY KEY ("BiometricCredentialId");


ALTER TABLE ONLY sec."SupervisorOverride"
    ADD CONSTRAINT "SupervisorOverride_pkey" PRIMARY KEY ("OverrideId");


ALTER TABLE ONLY sec."UserModuleAccess"
    ADD CONSTRAINT "UQ_UserModuleAccess" UNIQUE ("UserCode", "ModuleCode");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "UQ_sec_ApprovalRule_Code" UNIQUE ("CompanyId", "RuleCode");


ALTER TABLE ONLY sec."Permission"
    ADD CONSTRAINT "UQ_sec_Permission_Code" UNIQUE ("PermissionCode");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "UQ_sec_RolePermission" UNIQUE ("RoleId", "PermissionId");


ALTER TABLE ONLY sec."Role"
    ADD CONSTRAINT "UQ_sec_Role_RoleCode" UNIQUE ("RoleCode");


ALTER TABLE ONLY sec."UserCompanyAccess"
    ADD CONSTRAINT "UQ_sec_UserCompanyAccess" UNIQUE ("CodUsuario", "CompanyId", "BranchId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "UQ_sec_UserPermOverride" UNIQUE ("UserId", "PermissionId");


ALTER TABLE ONLY sec."UserRole"
    ADD CONSTRAINT "UQ_sec_UserRole" UNIQUE ("UserId", "RoleId");


ALTER TABLE ONLY sec."User"
    ADD CONSTRAINT "UQ_sec_User_UserCode" UNIQUE ("UserCode");


ALTER TABLE ONLY sec."UserCompanyAccess"
    ADD CONSTRAINT "UserCompanyAccess_pkey" PRIMARY KEY ("AccessId");


ALTER TABLE ONLY sec."UserModuleAccess"
    ADD CONSTRAINT "UserModuleAccess_pkey" PRIMARY KEY ("AccessId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "UserPermissionOverride_pkey" PRIMARY KEY ("UserPermissionOverrideId");


ALTER TABLE ONLY sec."UserRole"
    ADD CONSTRAINT "UserRole_pkey" PRIMARY KEY ("UserRoleId");


ALTER TABLE ONLY sec."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY ("UserId");


ALTER TABLE ONLY store."IndustryTemplateAttribute"
    ADD CONSTRAINT "IndustryTemplateAttribute_pkey" PRIMARY KEY ("TemplateAttributeId");


ALTER TABLE ONLY store."IndustryTemplate"
    ADD CONSTRAINT "IndustryTemplate_pkey" PRIMARY KEY ("IndustryTemplateId");


ALTER TABLE ONLY store."ProductAttribute"
    ADD CONSTRAINT "ProductAttribute_pkey" PRIMARY KEY ("ProductAttributeId");


ALTER TABLE ONLY store."ProductHighlight"
    ADD CONSTRAINT "ProductHighlight_pkey" PRIMARY KEY ("HighlightId");


ALTER TABLE ONLY store."ProductReview"
    ADD CONSTRAINT "ProductReview_pkey" PRIMARY KEY ("ReviewId");


ALTER TABLE ONLY store."ProductSpec"
    ADD CONSTRAINT "ProductSpec_pkey" PRIMARY KEY ("SpecId");


ALTER TABLE ONLY store."ProductVariantGroup"
    ADD CONSTRAINT "ProductVariantGroup_pkey" PRIMARY KEY ("VariantGroupId");


ALTER TABLE ONLY store."ProductVariantOptionValue"
    ADD CONSTRAINT "ProductVariantOptionValue_pkey" PRIMARY KEY ("VariantOptionValueId");


ALTER TABLE ONLY store."ProductVariantOption"
    ADD CONSTRAINT "ProductVariantOption_pkey" PRIMARY KEY ("VariantOptionId");


ALTER TABLE ONLY store."ProductVariant"
    ADD CONSTRAINT "ProductVariant_pkey" PRIMARY KEY ("ProductVariantId");


ALTER TABLE ONLY store."IndustryTemplate"
    ADD CONSTRAINT "UQ_IndustryTemplate_Code" UNIQUE ("CompanyId", "TemplateCode");


ALTER TABLE ONLY store."ProductVariantOptionValue"
    ADD CONSTRAINT "UQ_PVOV" UNIQUE ("ProductVariantId", "VariantOptionId");


ALTER TABLE ONLY store."ProductAttribute"
    ADD CONSTRAINT "UQ_ProductAttribute_Key" UNIQUE ("CompanyId", "ProductCode", "AttributeKey");


ALTER TABLE ONLY store."ProductVariantGroup"
    ADD CONSTRAINT "UQ_ProductVariantGroup_Code" UNIQUE ("CompanyId", "GroupCode");


ALTER TABLE ONLY store."ProductVariant"
    ADD CONSTRAINT "UQ_ProductVariant_Code" UNIQUE ("CompanyId", "ParentProductCode", "VariantProductCode");


ALTER TABLE ONLY store."IndustryTemplateAttribute"
    ADD CONSTRAINT "UQ_TemplateAttribute_Key" UNIQUE ("CompanyId", "TemplateCode", "AttributeKey");


ALTER TABLE ONLY store."ProductVariantOption"
    ADD CONSTRAINT "UQ_VariantOption_Code" UNIQUE ("CompanyId", "VariantGroupId", "OptionCode");


ALTER TABLE ONLY sys."BillingEvent"
    ADD CONSTRAINT "BillingEvent_pkey" PRIMARY KEY ("BillingEventId");


ALTER TABLE ONLY sys."CleanupQueue"
    ADD CONSTRAINT "CleanupQueue_CompanyId_key" UNIQUE ("CompanyId");


ALTER TABLE ONLY sys."CleanupQueue"
    ADD CONSTRAINT "CleanupQueue_pkey" PRIMARY KEY ("QueueId");


ALTER TABLE ONLY sys."License"
    ADD CONSTRAINT "License_LicenseKey_key" UNIQUE ("LicenseKey");


ALTER TABLE ONLY sys."License"
    ADD CONSTRAINT "License_pkey" PRIMARY KEY ("LicenseId");


ALTER TABLE ONLY sys."PushDevice"
    ADD CONSTRAINT "PushDevice_pkey" PRIMARY KEY ("DeviceId");


ALTER TABLE ONLY sys."Subscription"
    ADD CONSTRAINT "Subscription_PaddleSubscriptionId_key" UNIQUE ("PaddleSubscriptionId");


ALTER TABLE ONLY sys."Subscription"
    ADD CONSTRAINT "Subscription_pkey" PRIMARY KEY ("SubscriptionId");


ALTER TABLE ONLY sys."TenantBackup"
    ADD CONSTRAINT "TenantBackup_pkey" PRIMARY KEY ("BackupId");


ALTER TABLE ONLY sys."TenantDatabase"
    ADD CONSTRAINT "TenantDatabase_pkey" PRIMARY KEY ("TenantDbId");


ALTER TABLE ONLY sys."TenantResourceLog"
    ADD CONSTRAINT "TenantResourceLog_pkey" PRIMARY KEY ("LogId");


ALTER TABLE ONLY sys."PushDevice"
    ADD CONSTRAINT "UQ_PushDevice_Token" UNIQUE ("PushToken");


ALTER TABLE ONLY sys."TenantDatabase"
    ADD CONSTRAINT "UQ_sys_TenantDatabase_CompanyId" UNIQUE ("CompanyId");


ALTER TABLE ONLY sys."TenantDatabase"
    ADD CONSTRAINT "UQ_sys_TenantDatabase_DbName" UNIQUE ("DbName");


-- Foreign Key Constraints


ALTER TABLE ONLY acct."FixedAssetDepreciation"
    ADD CONSTRAINT "FK_FAD_Asset" FOREIGN KEY ("AssetId") REFERENCES acct."FixedAsset"("AssetId");


ALTER TABLE ONLY acct."FixedAssetImprovement"
    ADD CONSTRAINT "FK_FAI_Asset" FOREIGN KEY ("AssetId") REFERENCES acct."FixedAsset"("AssetId");


ALTER TABLE ONLY acct."FixedAssetRevaluation"
    ADD CONSTRAINT "FK_FAR_Asset" FOREIGN KEY ("AssetId") REFERENCES acct."FixedAsset"("AssetId");


ALTER TABLE ONLY acct."FixedAsset"
    ADD CONSTRAINT "FK_FA_Category" FOREIGN KEY ("CategoryId") REFERENCES acct."FixedAssetCategory"("CategoryId");


ALTER TABLE ONLY acct."AccountMonetaryClass"
    ADD CONSTRAINT "FK_acct_AMC_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "FK_acct_Account_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "FK_acct_Account_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "FK_acct_Account_Parent" FOREIGN KEY ("ParentAccountId") REFERENCES acct."Account"("AccountId");


ALTER TABLE ONLY acct."Account"
    ADD CONSTRAINT "FK_acct_Account_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY acct."DocumentLink"
    ADD CONSTRAINT "FK_acct_DocLink_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY acct."DocumentLink"
    ADD CONSTRAINT "FK_acct_DocLink_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."DocumentLink"
    ADD CONSTRAINT "FK_acct_DocLink_JE" FOREIGN KEY ("JournalEntryId") REFERENCES acct."JournalEntry"("JournalEntryId");


ALTER TABLE ONLY acct."EquityMovement"
    ADD CONSTRAINT "FK_acct_EM_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."InflationAdjustmentLine"
    ADD CONSTRAINT "FK_acct_IAL_Header" FOREIGN KEY ("InflationAdjustmentId") REFERENCES acct."InflationAdjustment"("InflationAdjustmentId");


ALTER TABLE ONLY acct."InflationAdjustment"
    ADD CONSTRAINT "FK_acct_IA_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."InflationIndex"
    ADD CONSTRAINT "FK_acct_II_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."JournalEntryLine"
    ADD CONSTRAINT "FK_acct_JEL_Account" FOREIGN KEY ("AccountId") REFERENCES acct."Account"("AccountId");


ALTER TABLE ONLY acct."JournalEntryLine"
    ADD CONSTRAINT "FK_acct_JEL_JE" FOREIGN KEY ("JournalEntryId") REFERENCES acct."JournalEntry"("JournalEntryId");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "FK_acct_JE_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "FK_acct_JE_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "FK_acct_JE_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY acct."JournalEntry"
    ADD CONSTRAINT "FK_acct_JE_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY acct."AccountingPolicy"
    ADD CONSTRAINT "FK_acct_Policy_Account" FOREIGN KEY ("AccountId") REFERENCES acct."Account"("AccountId");


ALTER TABLE ONLY acct."AccountingPolicy"
    ADD CONSTRAINT "FK_acct_Policy_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."ReportTemplateVariable"
    ADD CONSTRAINT "FK_acct_RTV_Template" FOREIGN KEY ("ReportTemplateId") REFERENCES acct."ReportTemplate"("ReportTemplateId") ON DELETE CASCADE;


ALTER TABLE ONLY acct."ReportTemplate"
    ADD CONSTRAINT "FK_acct_RT_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."BudgetLine"
    ADD CONSTRAINT fk_acct_bl_budget FOREIGN KEY ("BudgetId") REFERENCES acct."Budget"("BudgetId");


ALTER TABLE ONLY acct."Budget"
    ADD CONSTRAINT fk_acct_bud_company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."CostCenter"
    ADD CONSTRAINT fk_acct_cc_company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."CostCenter"
    ADD CONSTRAINT fk_acct_cc_parent FOREIGN KEY ("ParentCostCenterId") REFERENCES acct."CostCenter"("CostCenterId");


ALTER TABLE ONLY acct."FiscalPeriod"
    ADD CONSTRAINT fk_acct_fp_company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."RecurringEntry"
    ADD CONSTRAINT fk_acct_re_company FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY acct."RecurringEntryLine"
    ADD CONSTRAINT fk_acct_rel_re FOREIGN KEY ("RecurringEntryId") REFERENCES acct."RecurringEntry"("RecurringEntryId");


ALTER TABLE ONLY ap."PayableApplication"
    ADD CONSTRAINT "FK_ap_PayApp_Doc" FOREIGN KEY ("PayableDocumentId") REFERENCES ap."PayableDocument"("PayableDocumentId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "FK_ap_PayDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "FK_ap_PayDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "FK_ap_PayDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "FK_ap_PayDoc_Supplier" FOREIGN KEY ("SupplierId") REFERENCES master."Supplier"("SupplierId");


ALTER TABLE ONLY ap."PayableDocument"
    ADD CONSTRAINT "FK_ap_PayDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY ar."ReceivableApplication"
    ADD CONSTRAINT "FK_ar_RecApp_Doc" FOREIGN KEY ("ReceivableDocumentId") REFERENCES ar."ReceivableDocument"("ReceivableDocumentId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "FK_ar_RecDoc_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "FK_ar_RecDoc_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "FK_ar_RecDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "FK_ar_RecDoc_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY ar."ReceivableDocument"
    ADD CONSTRAINT "FK_ar_RecDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."EntityImage"
    ADD CONSTRAINT "EntityImage_MediaAssetId_fkey" FOREIGN KEY ("MediaAssetId") REFERENCES cfg."MediaAsset"("MediaAssetId");


ALTER TABLE ONLY cfg."CompanyProfile"
    ADD CONSTRAINT "FK_CompanyProfile_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY cfg."Branch"
    ADD CONSTRAINT "FK_cfg_Branch_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY cfg."Branch"
    ADD CONSTRAINT "FK_cfg_Branch_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."Branch"
    ADD CONSTRAINT "FK_cfg_Branch_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."Company"
    ADD CONSTRAINT "FK_cfg_Company_Country" FOREIGN KEY ("FiscalCountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY cfg."Company"
    ADD CONSTRAINT "FK_cfg_Company_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."Company"
    ADD CONSTRAINT "FK_cfg_Company_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."ExchangeRateDaily"
    ADD CONSTRAINT "FK_cfg_ExchangeRateDaily_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY cfg."Lookup"
    ADD CONSTRAINT "Lookup_LookupTypeId_fkey" FOREIGN KEY ("LookupTypeId") REFERENCES cfg."LookupType"("LookupTypeId");


ALTER TABLE ONLY cfg."State"
    ADD CONSTRAINT "State_CountryCode_fkey" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY crm."Agent"
    ADD CONSTRAINT "Agent_CompanyId_fkey" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."Agent"
    ADD CONSTRAINT "Agent_QueueId_fkey" FOREIGN KEY ("QueueId") REFERENCES crm."CallQueue"("QueueId");


ALTER TABLE ONLY crm."Agent"
    ADD CONSTRAINT "Agent_UserId_fkey" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."AutomationLog"
    ADD CONSTRAINT "AutomationLog_LeadId_fkey" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY crm."AutomationLog"
    ADD CONSTRAINT "AutomationLog_RuleId_fkey" FOREIGN KEY ("RuleId") REFERENCES crm."AutomationRule"("RuleId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_AgentId_fkey" FOREIGN KEY ("AgentId") REFERENCES crm."Agent"("AgentId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_BranchId_fkey" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_CompanyId_fkey" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_CustomerId_fkey" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_LeadId_fkey" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY crm."CallLog"
    ADD CONSTRAINT "CallLog_QueueId_fkey" FOREIGN KEY ("QueueId") REFERENCES crm."CallQueue"("QueueId");


ALTER TABLE ONLY crm."CallQueue"
    ADD CONSTRAINT "CallQueue_CompanyId_fkey" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."CallScript"
    ADD CONSTRAINT "CallScript_CompanyId_fkey" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."CampaignContact"
    ADD CONSTRAINT "CampaignContact_AssignedAgentId_fkey" FOREIGN KEY ("AssignedAgentId") REFERENCES crm."Agent"("AgentId");


ALTER TABLE ONLY crm."CampaignContact"
    ADD CONSTRAINT "CampaignContact_CampaignId_fkey" FOREIGN KEY ("CampaignId") REFERENCES crm."Campaign"("CampaignId");


ALTER TABLE ONLY crm."CampaignContact"
    ADD CONSTRAINT "CampaignContact_CustomerId_fkey" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY crm."CampaignContact"
    ADD CONSTRAINT "CampaignContact_LeadId_fkey" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "Campaign_AssignedToUserId_fkey" FOREIGN KEY ("AssignedToUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "Campaign_CompanyId_fkey" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "Campaign_QueueId_fkey" FOREIGN KEY ("QueueId") REFERENCES crm."CallQueue"("QueueId");


ALTER TABLE ONLY crm."Campaign"
    ADD CONSTRAINT "Campaign_ScriptId_fkey" FOREIGN KEY ("ScriptId") REFERENCES crm."CallScript"("ScriptId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_AssignedTo" FOREIGN KEY ("AssignedToUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_Lead" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY crm."Activity"
    ADD CONSTRAINT "FK_crm_Activity_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."LeadHistory"
    ADD CONSTRAINT "FK_crm_LeadHistory_ChangedBy" FOREIGN KEY ("ChangedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."LeadHistory"
    ADD CONSTRAINT "FK_crm_LeadHistory_FromStage" FOREIGN KEY ("FromStageId") REFERENCES crm."PipelineStage"("StageId");


ALTER TABLE ONLY crm."LeadHistory"
    ADD CONSTRAINT "FK_crm_LeadHistory_Lead" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY crm."LeadHistory"
    ADD CONSTRAINT "FK_crm_LeadHistory_ToStage" FOREIGN KEY ("ToStageId") REFERENCES crm."PipelineStage"("StageId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_AssignedTo" FOREIGN KEY ("AssignedToUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_Pipeline" FOREIGN KEY ("PipelineId") REFERENCES crm."Pipeline"("PipelineId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_Stage" FOREIGN KEY ("StageId") REFERENCES crm."PipelineStage"("StageId");


ALTER TABLE ONLY crm."Lead"
    ADD CONSTRAINT "FK_crm_Lead_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."PipelineStage"
    ADD CONSTRAINT "FK_crm_PipelineStage_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."PipelineStage"
    ADD CONSTRAINT "FK_crm_PipelineStage_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."PipelineStage"
    ADD CONSTRAINT "FK_crm_PipelineStage_Pipeline" FOREIGN KEY ("PipelineId") REFERENCES crm."Pipeline"("PipelineId");


ALTER TABLE ONLY crm."PipelineStage"
    ADD CONSTRAINT "FK_crm_PipelineStage_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Pipeline"
    ADD CONSTRAINT "FK_crm_Pipeline_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."Pipeline"
    ADD CONSTRAINT "FK_crm_Pipeline_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Pipeline"
    ADD CONSTRAINT "FK_crm_Pipeline_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."Pipeline"
    ADD CONSTRAINT "FK_crm_Pipeline_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."SavedView"
    ADD CONSTRAINT "FK_crm_SavedView_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY crm."SavedView"
    ADD CONSTRAINT "FK_crm_SavedView_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY crm."LeadScore"
    ADD CONSTRAINT "LeadScore_LeadId_fkey" FOREIGN KEY ("LeadId") REFERENCES crm."Lead"("LeadId");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "FK_fin_BankAccount_Bank" FOREIGN KEY ("BankId") REFERENCES fin."Bank"("BankId");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "FK_fin_BankAccount_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "FK_fin_BankAccount_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "FK_fin_BankAccount_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankAccount"
    ADD CONSTRAINT "FK_fin_BankAccount_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankMovement"
    ADD CONSTRAINT "FK_fin_BankMovement_Account" FOREIGN KEY ("BankAccountId") REFERENCES fin."BankAccount"("BankAccountId");


ALTER TABLE ONLY fin."BankMovement"
    ADD CONSTRAINT "FK_fin_BankMovement_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankMovement"
    ADD CONSTRAINT "FK_fin_BankMovement_JournalEntry" FOREIGN KEY ("JournalEntryId") REFERENCES acct."JournalEntry"("JournalEntryId");


ALTER TABLE ONLY fin."BankMovement"
    ADD CONSTRAINT "FK_fin_BankMovement_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "FK_fin_BankRecMatch_Movement" FOREIGN KEY ("BankMovementId") REFERENCES fin."BankMovement"("BankMovementId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "FK_fin_BankRecMatch_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "FK_fin_BankRecMatch_Statement" FOREIGN KEY ("StatementLineId") REFERENCES fin."BankStatementLine"("StatementLineId");


ALTER TABLE ONLY fin."BankReconciliationMatch"
    ADD CONSTRAINT "FK_fin_BankRecMatch_User" FOREIGN KEY ("MatchedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "FK_fin_BankRec_Account" FOREIGN KEY ("BankAccountId") REFERENCES fin."BankAccount"("BankAccountId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "FK_fin_BankRec_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "FK_fin_BankRec_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "FK_fin_BankRec_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fin."BankReconciliation"
    ADD CONSTRAINT "FK_fin_BankRec_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankStatementLine"
    ADD CONSTRAINT "FK_fin_BankStatementLine_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."BankStatementLine"
    ADD CONSTRAINT "FK_fin_BankStatementLine_Reconciliation" FOREIGN KEY ("ReconciliationId") REFERENCES fin."BankReconciliation"("BankReconciliationId");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "FK_fin_Bank_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "FK_fin_Bank_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."Bank"
    ADD CONSTRAINT "FK_fin_Bank_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fin."PettyCashExpense"
    ADD CONSTRAINT "PettyCashExpense_BoxId_fkey" FOREIGN KEY ("BoxId") REFERENCES fin."PettyCashBox"("Id");


ALTER TABLE ONLY fin."PettyCashExpense"
    ADD CONSTRAINT "PettyCashExpense_SessionId_fkey" FOREIGN KEY ("SessionId") REFERENCES fin."PettyCashSession"("Id");


ALTER TABLE ONLY fin."PettyCashSession"
    ADD CONSTRAINT "PettyCashSession_BoxId_fkey" FOREIGN KEY ("BoxId") REFERENCES fin."PettyCashBox"("Id");


ALTER TABLE ONLY fiscal."TaxBookEntry"
    ADD CONSTRAINT "FK_TaxBookEntry_Declaration" FOREIGN KEY ("DeclarationId") REFERENCES fiscal."TaxDeclaration"("DeclarationId");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "FK_fiscal_CountryCfg_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "FK_fiscal_CountryCfg_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "FK_fiscal_CountryCfg_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "FK_fiscal_CountryCfg_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fiscal."CountryConfig"
    ADD CONSTRAINT "FK_fiscal_CountryCfg_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fiscal."InvoiceType"
    ADD CONSTRAINT "FK_fiscal_InvType_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY fiscal."InvoiceType"
    ADD CONSTRAINT "FK_fiscal_InvType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fiscal."InvoiceType"
    ADD CONSTRAINT "FK_fiscal_InvType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fiscal."Record"
    ADD CONSTRAINT "FK_fiscal_Record_CountryCfg" FOREIGN KEY ("CompanyId", "BranchId", "CountryCode") REFERENCES fiscal."CountryConfig"("CompanyId", "BranchId", "CountryCode");


ALTER TABLE ONLY fiscal."Record"
    ADD CONSTRAINT "FK_fiscal_Record_PrevHash" FOREIGN KEY ("PreviousRecordHash") REFERENCES fiscal."Record"("RecordHash");


ALTER TABLE ONLY fiscal."TaxRate"
    ADD CONSTRAINT "FK_fiscal_TaxRate_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY fiscal."TaxRate"
    ADD CONSTRAINT "FK_fiscal_TaxRate_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fiscal."TaxRate"
    ADD CONSTRAINT "FK_fiscal_TaxRate_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."FuelLog"
    ADD CONSTRAINT "FK_fleet_FuelLog_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId");


ALTER TABLE ONLY fleet."MaintenanceOrderLine"
    ADD CONSTRAINT "FK_fleet_MOLine_Order" FOREIGN KEY ("MaintenanceOrderId") REFERENCES fleet."MaintenanceOrder"("MaintenanceOrderId");


ALTER TABLE ONLY fleet."MaintenanceOrderLine"
    ADD CONSTRAINT "FK_fleet_MOLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_Type" FOREIGN KEY ("MaintenanceTypeId") REFERENCES fleet."MaintenanceType"("MaintenanceTypeId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."MaintenanceOrder"
    ADD CONSTRAINT "FK_fleet_MaintOrder_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "FK_fleet_MaintType_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "FK_fleet_MaintType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "FK_fleet_MaintType_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."MaintenanceType"
    ADD CONSTRAINT "FK_fleet_MaintType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_DeliveryNote" FOREIGN KEY ("DeliveryNoteId") REFERENCES logistics."DeliveryNote"("DeliveryNoteId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_Driver" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Trip"
    ADD CONSTRAINT "FK_fleet_Trip_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId");


ALTER TABLE ONLY fleet."VehicleDocument"
    ADD CONSTRAINT "FK_fleet_VehicleDoc_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."VehicleDocument"
    ADD CONSTRAINT "FK_fleet_VehicleDoc_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."VehicleDocument"
    ADD CONSTRAINT "FK_fleet_VehicleDoc_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."VehicleDocument"
    ADD CONSTRAINT "FK_fleet_VehicleDoc_Vehicle" FOREIGN KEY ("VehicleId") REFERENCES fleet."Vehicle"("VehicleId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_Driver" FOREIGN KEY ("DefaultDriverId") REFERENCES logistics."Driver"("DriverId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY fleet."Vehicle"
    ADD CONSTRAINT "FK_fleet_Vehicle_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY hr."SafetyCommitteeMeeting"
    ADD CONSTRAINT "FK_CommitteeMeeting_Committee" FOREIGN KEY ("SafetyCommitteeId") REFERENCES hr."SafetyCommittee"("SafetyCommitteeId");


ALTER TABLE ONLY hr."SafetyCommitteeMember"
    ADD CONSTRAINT "FK_CommitteeMember_Committee" FOREIGN KEY ("SafetyCommitteeId") REFERENCES hr."SafetyCommittee"("SafetyCommitteeId");


ALTER TABLE ONLY hr."SafetyCommitteeMember"
    ADD CONSTRAINT "FK_CommitteeMember_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."EmployeeObligation"
    ADD CONSTRAINT "FK_EmployeeObligation_Obligation" FOREIGN KEY ("LegalObligationId") REFERENCES hr."LegalObligation"("LegalObligationId");


ALTER TABLE ONLY hr."EmployeeObligation"
    ADD CONSTRAINT "FK_EmployeeObligation_RiskLevel" FOREIGN KEY ("RiskLevelId") REFERENCES hr."ObligationRiskLevel"("ObligationRiskLevelId");


ALTER TABLE ONLY hr."ObligationFilingDetail"
    ADD CONSTRAINT "FK_ObligationFilingDetail_Filing" FOREIGN KEY ("ObligationFilingId") REFERENCES hr."ObligationFiling"("ObligationFilingId");


ALTER TABLE ONLY hr."ObligationFiling"
    ADD CONSTRAINT "FK_ObligationFiling_Obligation" FOREIGN KEY ("LegalObligationId") REFERENCES hr."LegalObligation"("LegalObligationId");


ALTER TABLE ONLY hr."ObligationRiskLevel"
    ADD CONSTRAINT "FK_ObligationRiskLevel_Obligation" FOREIGN KEY ("LegalObligationId") REFERENCES hr."LegalObligation"("LegalObligationId");


ALTER TABLE ONLY hr."ProfitSharingLine"
    ADD CONSTRAINT "FK_ProfitSharingLine_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."ProfitSharingLine"
    ADD CONSTRAINT "FK_ProfitSharingLine_Header" FOREIGN KEY ("ProfitSharingId") REFERENCES hr."ProfitSharing"("ProfitSharingId");


ALTER TABLE ONLY hr."SavingsLoan"
    ADD CONSTRAINT "FK_SavingsLoan_Fund" FOREIGN KEY ("SavingsFundId") REFERENCES hr."SavingsFund"("SavingsFundId");


ALTER TABLE ONLY hr."SavingsFundTransaction"
    ADD CONSTRAINT "FK_SavingsTx_Fund" FOREIGN KEY ("SavingsFundId") REFERENCES hr."SavingsFund"("SavingsFundId");


ALTER TABLE ONLY hr."DocumentTemplate"
    ADD CONSTRAINT "FK_hr_DocumentTemplate_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."MedicalExam"
    ADD CONSTRAINT "FK_hr_MedicalExam_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."MedicalExam"
    ADD CONSTRAINT "FK_hr_MedicalExam_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."MedicalOrder"
    ADD CONSTRAINT "FK_hr_MedicalOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."MedicalOrder"
    ADD CONSTRAINT "FK_hr_MedicalOrder_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."OccupationalHealth"
    ADD CONSTRAINT "FK_hr_OccHealth_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."OccupationalHealth"
    ADD CONSTRAINT "FK_hr_OccHealth_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."PayrollBatchLine"
    ADD CONSTRAINT "FK_hr_PayrollBatchLine_Batch" FOREIGN KEY ("BatchId") REFERENCES hr."PayrollBatch"("BatchId") ON DELETE CASCADE;


ALTER TABLE ONLY hr."PayrollBatch"
    ADD CONSTRAINT "FK_hr_PayrollBatch_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."PayrollConcept"
    ADD CONSTRAINT "FK_hr_PayrollConcept_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollConcept"
    ADD CONSTRAINT "FK_hr_PayrollConcept_PayrollType" FOREIGN KEY ("CompanyId", "PayrollCode") REFERENCES hr."PayrollType"("CompanyId", "PayrollCode");


ALTER TABLE ONLY hr."PayrollConcept"
    ADD CONSTRAINT "FK_hr_PayrollConcept_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollConstant"
    ADD CONSTRAINT "FK_hr_PayrollConstant_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."PayrollConstant"
    ADD CONSTRAINT "FK_hr_PayrollConstant_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollConstant"
    ADD CONSTRAINT "FK_hr_PayrollConstant_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollRunLine"
    ADD CONSTRAINT "FK_hr_PayrollRunLine_Run" FOREIGN KEY ("PayrollRunId") REFERENCES hr."PayrollRun"("PayrollRunId") ON DELETE CASCADE;


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."PayrollRun"
    ADD CONSTRAINT "FK_hr_PayrollRun_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollType"
    ADD CONSTRAINT "FK_hr_PayrollType_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."PayrollType"
    ADD CONSTRAINT "FK_hr_PayrollType_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."PayrollType"
    ADD CONSTRAINT "FK_hr_PayrollType_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."ProfitSharing"
    ADD CONSTRAINT "FK_hr_ProfitSharing_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY hr."ProfitSharing"
    ADD CONSTRAINT "FK_hr_ProfitSharing_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."SafetyCommittee"
    ADD CONSTRAINT "FK_hr_SafetyCommittee_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."SavingsFund"
    ADD CONSTRAINT "FK_hr_SavingsFund_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."SavingsFund"
    ADD CONSTRAINT "FK_hr_SavingsFund_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."SettlementProcessLine"
    ADD CONSTRAINT "FK_hr_SettlementProcessLine_Process" FOREIGN KEY ("SettlementProcessId") REFERENCES hr."SettlementProcess"("SettlementProcessId") ON DELETE CASCADE;


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "FK_hr_SettlementProcess_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "FK_hr_SettlementProcess_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "FK_hr_SettlementProcess_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "FK_hr_SettlementProcess_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."SettlementProcess"
    ADD CONSTRAINT "FK_hr_SettlementProcess_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."TrainingRecord"
    ADD CONSTRAINT "FK_hr_TrainingRecord_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."TrainingRecord"
    ADD CONSTRAINT "FK_hr_TrainingRecord_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."SocialBenefitsTrust"
    ADD CONSTRAINT "FK_hr_Trust_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."SocialBenefitsTrust"
    ADD CONSTRAINT "FK_hr_Trust_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."VacationProcessLine"
    ADD CONSTRAINT "FK_hr_VacationProcessLine_Process" FOREIGN KEY ("VacationProcessId") REFERENCES hr."VacationProcess"("VacationProcessId") ON DELETE CASCADE;


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "FK_hr_VacationProcess_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "FK_hr_VacationProcess_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "FK_hr_VacationProcess_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "FK_hr_VacationProcess_Employee" FOREIGN KEY ("EmployeeId") REFERENCES master."Employee"("EmployeeId");


ALTER TABLE ONLY hr."VacationProcess"
    ADD CONSTRAINT "FK_hr_VacationProcess_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY hr."VacationRequestDay"
    ADD CONSTRAINT "VacationRequestDay_RequestId_fkey" FOREIGN KEY ("RequestId") REFERENCES hr."VacationRequest"("RequestId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductBinStock"
    ADD CONSTRAINT "FK_inv_ProductBinStock_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "FK_inv_ProductLot_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "FK_inv_ProductLot_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "FK_inv_ProductLot_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "FK_inv_ProductLot_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."ProductLot"
    ADD CONSTRAINT "FK_inv_ProductLot_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."ProductSerial"
    ADD CONSTRAINT "FK_inv_ProductSerial_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_FromBin" FOREIGN KEY ("FromBinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_FromWH" FOREIGN KEY ("FromWarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_Serial" FOREIGN KEY ("SerialId") REFERENCES inv."ProductSerial"("SerialId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_ToBin" FOREIGN KEY ("ToBinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY inv."StockMovement"
    ADD CONSTRAINT "FK_inv_StockMovement_ToWH" FOREIGN KEY ("ToWarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY inv."InventoryValuationLayer"
    ADD CONSTRAINT "FK_inv_ValLayer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."InventoryValuationLayer"
    ADD CONSTRAINT "FK_inv_ValLayer_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId");


ALTER TABLE ONLY inv."InventoryValuationLayer"
    ADD CONSTRAINT "FK_inv_ValLayer_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "FK_inv_ValMethod_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "FK_inv_ValMethod_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "FK_inv_ValMethod_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "FK_inv_ValMethod_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY inv."InventoryValuationMethod"
    ADD CONSTRAINT "FK_inv_ValMethod_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseBin"
    ADD CONSTRAINT "FK_inv_WarehouseBin_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseBin"
    ADD CONSTRAINT "FK_inv_WarehouseBin_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseBin"
    ADD CONSTRAINT "FK_inv_WarehouseBin_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseBin"
    ADD CONSTRAINT "FK_inv_WarehouseBin_Zone" FOREIGN KEY ("ZoneId") REFERENCES inv."WarehouseZone"("ZoneId");


ALTER TABLE ONLY inv."WarehouseZone"
    ADD CONSTRAINT "FK_inv_WarehouseZone_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseZone"
    ADD CONSTRAINT "FK_inv_WarehouseZone_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseZone"
    ADD CONSTRAINT "FK_inv_WarehouseZone_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."WarehouseZone"
    ADD CONSTRAINT "FK_inv_WarehouseZone_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "FK_inv_Warehouse_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "FK_inv_Warehouse_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "FK_inv_Warehouse_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "FK_inv_Warehouse_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY inv."Warehouse"
    ADD CONSTRAINT "FK_inv_Warehouse_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY logistics."DeliveryNoteLine"
    ADD CONSTRAINT "DeliveryNoteLine_DeliveryNoteId_fkey" FOREIGN KEY ("DeliveryNoteId") REFERENCES logistics."DeliveryNote"("DeliveryNoteId");


ALTER TABLE ONLY logistics."DeliveryNoteSerial"
    ADD CONSTRAINT "DeliveryNoteSerial_DeliveryNoteLineId_fkey" FOREIGN KEY ("DeliveryNoteLineId") REFERENCES logistics."DeliveryNoteLine"("DeliveryNoteLineId");


ALTER TABLE ONLY logistics."DeliveryNote"
    ADD CONSTRAINT "DeliveryNote_CarrierId_fkey" FOREIGN KEY ("CarrierId") REFERENCES logistics."Carrier"("CarrierId");


ALTER TABLE ONLY logistics."DeliveryNote"
    ADD CONSTRAINT "DeliveryNote_DriverId_fkey" FOREIGN KEY ("DriverId") REFERENCES logistics."Driver"("DriverId");


ALTER TABLE ONLY logistics."Driver"
    ADD CONSTRAINT "Driver_CarrierId_fkey" FOREIGN KEY ("CarrierId") REFERENCES logistics."Carrier"("CarrierId");


ALTER TABLE ONLY logistics."GoodsReceiptLine"
    ADD CONSTRAINT "GoodsReceiptLine_GoodsReceiptId_fkey" FOREIGN KEY ("GoodsReceiptId") REFERENCES logistics."GoodsReceipt"("GoodsReceiptId");


ALTER TABLE ONLY logistics."GoodsReceiptSerial"
    ADD CONSTRAINT "GoodsReceiptSerial_GoodsReceiptLineId_fkey" FOREIGN KEY ("GoodsReceiptLineId") REFERENCES logistics."GoodsReceiptLine"("GoodsReceiptLineId");


ALTER TABLE ONLY logistics."GoodsReturnLine"
    ADD CONSTRAINT "GoodsReturnLine_GoodsReturnId_fkey" FOREIGN KEY ("GoodsReturnId") REFERENCES logistics."GoodsReturn"("GoodsReturnId");


ALTER TABLE ONLY logistics."GoodsReturn"
    ADD CONSTRAINT "GoodsReturn_GoodsReceiptId_fkey" FOREIGN KEY ("GoodsReceiptId") REFERENCES logistics."GoodsReceipt"("GoodsReceiptId");


ALTER TABLE ONLY master."Customer"
    ADD CONSTRAINT "FK_master_Customer_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY master."Customer"
    ADD CONSTRAINT "FK_master_Customer_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Customer"
    ADD CONSTRAINT "FK_master_Customer_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Employee"
    ADD CONSTRAINT "FK_master_Employee_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY master."Employee"
    ADD CONSTRAINT "FK_master_Employee_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Employee"
    ADD CONSTRAINT "FK_master_Employee_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Product"
    ADD CONSTRAINT "FK_master_Product_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY master."Product"
    ADD CONSTRAINT "FK_master_Product_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Product"
    ADD CONSTRAINT "FK_master_Product_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Supplier"
    ADD CONSTRAINT "FK_master_Supplier_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY master."Supplier"
    ADD CONSTRAINT "FK_master_Supplier_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY master."Supplier"
    ADD CONSTRAINT "FK_master_Supplier_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."BOMLine"
    ADD CONSTRAINT "FK_mfg_BOMLine_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId");


ALTER TABLE ONLY mfg."BOMLine"
    ADD CONSTRAINT "FK_mfg_BOMLine_Component" FOREIGN KEY ("ComponentProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "FK_mfg_BOM_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "FK_mfg_BOM_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "FK_mfg_BOM_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "FK_mfg_BOM_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY mfg."BillOfMaterials"
    ADD CONSTRAINT "FK_mfg_BOM_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."Routing"
    ADD CONSTRAINT "FK_mfg_Routing_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId");


ALTER TABLE ONLY mfg."Routing"
    ADD CONSTRAINT "FK_mfg_Routing_WorkCenter" FOREIGN KEY ("WorkCenterId") REFERENCES mfg."WorkCenter"("WorkCenterId");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "FK_mfg_WOMaterial_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "FK_mfg_WOMaterial_Lot" FOREIGN KEY ("LotId") REFERENCES inv."ProductLot"("LotId");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "FK_mfg_WOMaterial_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY mfg."WorkOrderMaterial"
    ADD CONSTRAINT "FK_mfg_WOMaterial_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "FK_mfg_WOOutput_Bin" FOREIGN KEY ("BinId") REFERENCES inv."WarehouseBin"("BinId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "FK_mfg_WOOutput_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "FK_mfg_WOOutput_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "FK_mfg_WOOutput_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY mfg."WorkOrderOutput"
    ADD CONSTRAINT "FK_mfg_WOOutput_WorkOrder" FOREIGN KEY ("WorkOrderId") REFERENCES mfg."WorkOrder"("WorkOrderId");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "FK_mfg_WorkCenter_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "FK_mfg_WorkCenter_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "FK_mfg_WorkCenter_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "FK_mfg_WorkCenter_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkCenter"
    ADD CONSTRAINT "FK_mfg_WorkCenter_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_BOM" FOREIGN KEY ("BOMId") REFERENCES mfg."BillOfMaterials"("BOMId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY mfg."WorkOrder"
    ADD CONSTRAINT "FK_mfg_WorkOrder_Warehouse" FOREIGN KEY ("WarehouseId") REFERENCES inv."Warehouse"("WarehouseId");


ALTER TABLE ONLY pay."AcceptedPaymentMethods"
    ADD CONSTRAINT "AcceptedPaymentMethods_PaymentMethodId_fkey" FOREIGN KEY ("PaymentMethodId") REFERENCES pay."PaymentMethods"("Id");


ALTER TABLE ONLY pay."AcceptedPaymentMethods"
    ADD CONSTRAINT "AcceptedPaymentMethods_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pay."CardReaderDevices"
    ADD CONSTRAINT "CardReaderDevices_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pay."CompanyPaymentConfig"
    ADD CONSTRAINT "CompanyPaymentConfig_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pay."ProviderCapabilities"
    ADD CONSTRAINT "ProviderCapabilities_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pay."ReconciliationBatches"
    ADD CONSTRAINT "ReconciliationBatches_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pay."Transactions"
    ADD CONSTRAINT "Transactions_ProviderId_fkey" FOREIGN KEY ("ProviderId") REFERENCES pay."PaymentProviders"("Id");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "FK_pos_FiscalCorrelative_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "FK_pos_FiscalCorrelative_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "FK_pos_FiscalCorrelative_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY pos."FiscalCorrelative"
    ADD CONSTRAINT "FK_pos_FiscalCorrelative_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY pos."SaleTicketLine"
    ADD CONSTRAINT "FK_pos_SaleTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY pos."SaleTicketLine"
    ADD CONSTRAINT "FK_pos_SaleTicketLine_SaleTicket" FOREIGN KEY ("SaleTicketId") REFERENCES pos."SaleTicket"("SaleTicketId") ON DELETE CASCADE;


ALTER TABLE ONLY pos."SaleTicketLine"
    ADD CONSTRAINT "FK_pos_SaleTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_SoldBy" FOREIGN KEY ("SoldByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY pos."SaleTicket"
    ADD CONSTRAINT "FK_pos_SaleTicket_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId");


ALTER TABLE ONLY pos."WaitTicketLine"
    ADD CONSTRAINT "FK_pos_WaitTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY pos."WaitTicketLine"
    ADD CONSTRAINT "FK_pos_WaitTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode");


ALTER TABLE ONLY pos."WaitTicketLine"
    ADD CONSTRAINT "FK_pos_WaitTicketLine_WaitTicket" FOREIGN KEY ("WaitTicketId") REFERENCES pos."WaitTicket"("WaitTicketId") ON DELETE CASCADE;


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_Customer" FOREIGN KEY ("CustomerId") REFERENCES master."Customer"("CustomerId");


ALTER TABLE ONLY pos."WaitTicket"
    ADD CONSTRAINT "FK_pos_WaitTicket_RecoveredBy" FOREIGN KEY ("RecoveredByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY public."PosVentasEnEsperaDetalle"
    ADD CONSTRAINT "FK_PosEsperaDetalle_Espera" FOREIGN KEY ("VentaEsperaId") REFERENCES public."PosVentasEnEspera"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY public."PosVentasDetalle"
    ADD CONSTRAINT "FK_PosVentaDetalle_Venta" FOREIGN KEY ("VentaId") REFERENCES public."PosVentas"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY public."RestauranteComprasDetalle"
    ADD CONSTRAINT "FK_RestCompDet_Compra" FOREIGN KEY ("CompraId") REFERENCES public."RestauranteCompras"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY public."RestauranteProductoComponentes"
    ADD CONSTRAINT "FK_RestComp_Prod" FOREIGN KEY ("ProductoId") REFERENCES public."RestauranteProductos"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY public."RestaurantePedidoItems"
    ADD CONSTRAINT "FK_RestItem_Pedido" FOREIGN KEY ("PedidoId") REFERENCES public."RestaurantePedidos"("Id");


ALTER TABLE ONLY public."RestauranteComponenteOpciones"
    ADD CONSTRAINT "FK_RestOpc_Comp" FOREIGN KEY ("ComponenteId") REFERENCES public."RestauranteProductoComponentes"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY public."RestaurantePedidos"
    ADD CONSTRAINT "FK_RestPedido_Mesa" FOREIGN KEY ("MesaId") REFERENCES public."RestauranteMesas"("Id");


ALTER TABLE ONLY public."RestauranteProductos"
    ADD CONSTRAINT "FK_RestProd_Cat" FOREIGN KEY ("CategoriaId") REFERENCES public."RestauranteCategorias"("Id");


ALTER TABLE ONLY public."RestauranteRecetas"
    ADD CONSTRAINT "FK_RestReceta_Prod" FOREIGN KEY ("ProductoId") REFERENCES public."RestauranteProductos"("Id") ON DELETE CASCADE;


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "FK_rest_DiningTable_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "FK_rest_DiningTable_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "FK_rest_DiningTable_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."DiningTable"
    ADD CONSTRAINT "FK_rest_DiningTable_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "FK_rest_MenuCategory_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "FK_rest_MenuCategory_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "FK_rest_MenuCategory_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuCategory"
    ADD CONSTRAINT "FK_rest_MenuCategory_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuComponent"
    ADD CONSTRAINT "FK_rest_MenuComponent_Product" FOREIGN KEY ("MenuProductId") REFERENCES rest."MenuProduct"("MenuProductId") ON DELETE CASCADE;


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "FK_rest_MenuEnvironment_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "FK_rest_MenuEnvironment_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "FK_rest_MenuEnvironment_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuEnvironment"
    ADD CONSTRAINT "FK_rest_MenuEnvironment_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuOption"
    ADD CONSTRAINT "FK_rest_MenuOption_Component" FOREIGN KEY ("MenuComponentId") REFERENCES rest."MenuComponent"("MenuComponentId") ON DELETE CASCADE;


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_Category" FOREIGN KEY ("MenuCategoryId") REFERENCES rest."MenuCategory"("MenuCategoryId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_InventoryProduct" FOREIGN KEY ("InventoryProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY rest."MenuProduct"
    ADD CONSTRAINT "FK_rest_MenuProduct_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."MenuRecipe"
    ADD CONSTRAINT "FK_rest_MenuRecipe_Ingredient" FOREIGN KEY ("IngredientProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY rest."MenuRecipe"
    ADD CONSTRAINT "FK_rest_MenuRecipe_MenuProduct" FOREIGN KEY ("MenuProductId") REFERENCES rest."MenuProduct"("MenuProductId") ON DELETE CASCADE;


ALTER TABLE ONLY rest."OrderTicketLine"
    ADD CONSTRAINT "FK_rest_OrderTicketLine_Order" FOREIGN KEY ("OrderTicketId") REFERENCES rest."OrderTicket"("OrderTicketId") ON DELETE CASCADE;


ALTER TABLE ONLY rest."OrderTicketLine"
    ADD CONSTRAINT "FK_rest_OrderTicketLine_Product" FOREIGN KEY ("ProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY rest."OrderTicketLine"
    ADD CONSTRAINT "FK_rest_OrderTicketLine_Tax" FOREIGN KEY ("CountryCode", "TaxCode") REFERENCES fiscal."TaxRate"("CountryCode", "TaxCode");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "FK_rest_OrderTicket_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "FK_rest_OrderTicket_ClosedBy" FOREIGN KEY ("ClosedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "FK_rest_OrderTicket_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "FK_rest_OrderTicket_Country" FOREIGN KEY ("CountryCode") REFERENCES cfg."Country"("CountryCode");


ALTER TABLE ONLY rest."OrderTicket"
    ADD CONSTRAINT "FK_rest_OrderTicket_OpenedBy" FOREIGN KEY ("OpenedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."PurchaseLine"
    ADD CONSTRAINT "FK_rest_PurchaseLine_Ingredient" FOREIGN KEY ("IngredientProductId") REFERENCES master."Product"("ProductId");


ALTER TABLE ONLY rest."PurchaseLine"
    ADD CONSTRAINT "FK_rest_PurchaseLine_Purchase" FOREIGN KEY ("PurchaseId") REFERENCES rest."Purchase"("PurchaseId") ON DELETE CASCADE;


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "FK_rest_Purchase_Branch" FOREIGN KEY ("BranchId") REFERENCES cfg."Branch"("BranchId");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "FK_rest_Purchase_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "FK_rest_Purchase_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "FK_rest_Purchase_Supplier" FOREIGN KEY ("SupplierId") REFERENCES master."Supplier"("SupplierId");


ALTER TABLE ONLY rest."Purchase"
    ADD CONSTRAINT "FK_rest_Purchase_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."SupervisorBiometricCredential"
    ADD CONSTRAINT "FK_SupervisorBiometricCredential_SupervisorUser" FOREIGN KEY ("SupervisorUserCode") REFERENCES sec."User"("UserCode");


ALTER TABLE ONLY sec."ApprovalAction"
    ADD CONSTRAINT "FK_sec_ApprovalAction_ActionBy" FOREIGN KEY ("ActionByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalAction"
    ADD CONSTRAINT "FK_sec_ApprovalAction_Request" FOREIGN KEY ("ApprovalRequestId") REFERENCES sec."ApprovalRequest"("ApprovalRequestId");


ALTER TABLE ONLY sec."ApprovalRequest"
    ADD CONSTRAINT "FK_sec_ApprovalReq_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY sec."ApprovalRequest"
    ADD CONSTRAINT "FK_sec_ApprovalReq_RequestedBy" FOREIGN KEY ("RequestedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalRequest"
    ADD CONSTRAINT "FK_sec_ApprovalReq_Rule" FOREIGN KEY ("ApprovalRuleId") REFERENCES sec."ApprovalRule"("ApprovalRuleId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_ApproverRole" FOREIGN KEY ("ApproverRoleId") REFERENCES sec."Role"("RoleId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_ApproverUser" FOREIGN KEY ("ApproverUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_EscalateTo" FOREIGN KEY ("EscalateToUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."ApprovalRule"
    ADD CONSTRAINT "FK_sec_ApprovalRule_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."AuthIdentity"
    ADD CONSTRAINT "FK_sec_AuthIdentity_User" FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode");


ALTER TABLE ONLY sec."AuthToken"
    ADD CONSTRAINT "FK_sec_AuthToken_User" FOREIGN KEY ("UserCode") REFERENCES sec."User"("UserCode");


ALTER TABLE ONLY sec."Permission"
    ADD CONSTRAINT "FK_sec_Permission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."Permission"
    ADD CONSTRAINT "FK_sec_Permission_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."Permission"
    ADD CONSTRAINT "FK_sec_Permission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_Company" FOREIGN KEY ("CompanyId") REFERENCES cfg."Company"("CompanyId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."PriceRestriction"
    ADD CONSTRAINT "FK_sec_PriceRestr_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "FK_sec_RolePermission_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "FK_sec_RolePermission_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "FK_sec_RolePermission_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId");


ALTER TABLE ONLY sec."RolePermission"
    ADD CONSTRAINT "FK_sec_RolePermission_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "FK_sec_UPOverride_CreatedBy" FOREIGN KEY ("CreatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "FK_sec_UPOverride_DeletedBy" FOREIGN KEY ("DeletedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "FK_sec_UPOverride_Permission" FOREIGN KEY ("PermissionId") REFERENCES sec."Permission"("PermissionId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "FK_sec_UPOverride_UpdatedBy" FOREIGN KEY ("UpdatedByUserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."UserPermissionOverride"
    ADD CONSTRAINT "FK_sec_UPOverride_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY sec."UserRole"
    ADD CONSTRAINT "FK_sec_UserRole_Role" FOREIGN KEY ("RoleId") REFERENCES sec."Role"("RoleId");


ALTER TABLE ONLY sec."UserRole"
    ADD CONSTRAINT "FK_sec_UserRole_User" FOREIGN KEY ("UserId") REFERENCES sec."User"("UserId");


ALTER TABLE ONLY store."ProductVariantOptionValue"
    ADD CONSTRAINT "FK_PVOV_Option" FOREIGN KEY ("VariantOptionId") REFERENCES store."ProductVariantOption"("VariantOptionId");


ALTER TABLE ONLY store."ProductVariantOptionValue"
    ADD CONSTRAINT "FK_PVOV_Variant" FOREIGN KEY ("ProductVariantId") REFERENCES store."ProductVariant"("ProductVariantId");


ALTER TABLE ONLY store."ProductVariantOption"
    ADD CONSTRAINT "FK_VariantOption_Group" FOREIGN KEY ("VariantGroupId") REFERENCES store."ProductVariantGroup"("VariantGroupId");

