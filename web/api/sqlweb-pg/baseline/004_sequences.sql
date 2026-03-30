-- ============================================
-- Zentto ERP — Sequence definitions
-- Extracted from zentto_dev via pg_dump
-- Date: 2026-03-30
-- ============================================


ALTER TABLE acct."AccountMonetaryClass" ALTER COLUMN "AccountMonetaryClassId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."AccountMonetaryClass_AccountMonetaryClassId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."Account" ALTER COLUMN "AccountId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."Account_AccountId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."AccountingPolicy" ALTER COLUMN "AccountingPolicyId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."AccountingPolicy_AccountingPolicyId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."BankDeposit" ALTER COLUMN "BankDepositId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."BankDeposit_BankDepositId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."BudgetLine" ALTER COLUMN "BudgetLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."BudgetLine_BudgetLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."Budget" ALTER COLUMN "BudgetId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."Budget_BudgetId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."CostCenter" ALTER COLUMN "CostCenterId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."CostCenter_CostCenterId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."DocumentLink" ALTER COLUMN "DocumentLinkId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."DocumentLink_DocumentLinkId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."EquityMovement" ALTER COLUMN "EquityMovementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."EquityMovement_EquityMovementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FiscalPeriod" ALTER COLUMN "FiscalPeriodId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FiscalPeriod_FiscalPeriodId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FixedAssetCategory" ALTER COLUMN "CategoryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FixedAssetCategory_CategoryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FixedAssetDepreciation" ALTER COLUMN "DepreciationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FixedAssetDepreciation_DepreciationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FixedAssetImprovement" ALTER COLUMN "ImprovementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FixedAssetImprovement_ImprovementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FixedAssetRevaluation" ALTER COLUMN "RevaluationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FixedAssetRevaluation_RevaluationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."FixedAsset" ALTER COLUMN "AssetId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."FixedAsset_AssetId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."InflationAdjustmentLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."InflationAdjustmentLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."InflationAdjustment" ALTER COLUMN "InflationAdjustmentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."InflationAdjustment_InflationAdjustmentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."InflationIndex" ALTER COLUMN "InflationIndexId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."InflationIndex_InflationIndexId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."JournalEntryLine" ALTER COLUMN "JournalEntryLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."JournalEntryLine_JournalEntryLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."JournalEntry" ALTER COLUMN "JournalEntryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."JournalEntry_JournalEntryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."RecurringEntryLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."RecurringEntryLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."RecurringEntry" ALTER COLUMN "RecurringEntryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."RecurringEntry_RecurringEntryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."ReportTemplateVariable" ALTER COLUMN "VariableId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."ReportTemplateVariable_VariableId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE acct."ReportTemplate" ALTER COLUMN "ReportTemplateId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME acct."ReportTemplate_ReportTemplateId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ap."PayableApplication" ALTER COLUMN "PayableApplicationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ap."PayableApplication_PayableApplicationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ap."PayableDocument" ALTER COLUMN "PayableDocumentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ap."PayableDocument_PayableDocumentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ap."PurchaseDocumentLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ap."PurchaseDocumentLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ap."PurchaseDocumentPayment" ALTER COLUMN "PaymentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ap."PurchaseDocumentPayment_PaymentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ap."PurchaseDocument" ALTER COLUMN "DocumentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ap."PurchaseDocument_DocumentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ar."ReceivableApplication" ALTER COLUMN "ReceivableApplicationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ar."ReceivableApplication_ReceivableApplicationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ar."ReceivableDocument" ALTER COLUMN "ReceivableDocumentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ar."ReceivableDocument_ReceivableDocumentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ar."SalesDocumentLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ar."SalesDocumentLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ar."SalesDocumentPayment" ALTER COLUMN "PaymentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ar."SalesDocumentPayment_PaymentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE ar."SalesDocument" ALTER COLUMN "DocumentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ar."SalesDocument_DocumentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE audit."AuditLog_AuditLogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cfg."AppSetting" ALTER COLUMN "SettingId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."AppSetting_SettingId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."Branch" ALTER COLUMN "BranchId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."Branch_BranchId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."CompanyProfile" ALTER COLUMN "ProfileId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."CompanyProfile_ProfileId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."Company" ALTER COLUMN "CompanyId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."Company_CompanyId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."Currency" ALTER COLUMN "CurrencyId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."Currency_CurrencyId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."DocumentSequence" ALTER COLUMN "SequenceId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."DocumentSequence_SequenceId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."EntityImage" ALTER COLUMN "EntityImageId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."EntityImage_EntityImageId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."ExchangeRateDaily" ALTER COLUMN "ExchangeRateDailyId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."ExchangeRateDaily_ExchangeRateDailyId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."Holiday" ALTER COLUMN "HolidayId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."Holiday_HolidayId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."LookupType" ALTER COLUMN "LookupTypeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."LookupType_LookupTypeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."Lookup" ALTER COLUMN "LookupId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."Lookup_LookupId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."MediaAsset" ALTER COLUMN "MediaAssetId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."MediaAsset_MediaAssetId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."ReportTemplate" ALTER COLUMN "ReportId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."ReportTemplate_ReportId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."State" ALTER COLUMN "StateId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."State_StateId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE cfg."TaxUnit" ALTER COLUMN "TaxUnitId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cfg."TaxUnit_TaxUnitId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."Activity" ALTER COLUMN "ActivityId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."Activity_ActivityId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."Agent" ALTER COLUMN "AgentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."Agent_AgentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."AutomationLog" ALTER COLUMN "LogId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."AutomationLog_LogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."AutomationRule" ALTER COLUMN "RuleId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."AutomationRule_RuleId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."CallLog" ALTER COLUMN "CallLogId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."CallLog_CallLogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."CallQueue" ALTER COLUMN "QueueId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."CallQueue_QueueId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."CallScript" ALTER COLUMN "ScriptId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."CallScript_ScriptId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."CampaignContact" ALTER COLUMN "CampaignContactId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."CampaignContact_CampaignContactId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."Campaign" ALTER COLUMN "CampaignId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."Campaign_CampaignId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."LeadHistory" ALTER COLUMN "HistoryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."LeadHistory_HistoryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."LeadScore" ALTER COLUMN "LeadScoreId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."LeadScore_LeadScoreId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."Lead" ALTER COLUMN "LeadId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."Lead_LeadId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."PipelineStage" ALTER COLUMN "StageId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."PipelineStage_StageId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE crm."Pipeline" ALTER COLUMN "PipelineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm."Pipeline_PipelineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."BankAccount" ALTER COLUMN "BankAccountId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."BankAccount_BankAccountId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."BankMovement" ALTER COLUMN "BankMovementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."BankMovement_BankMovementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."BankReconciliationMatch" ALTER COLUMN "BankReconciliationMatchId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."BankReconciliationMatch_BankReconciliationMatchId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."BankReconciliation" ALTER COLUMN "BankReconciliationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."BankReconciliation_BankReconciliationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."BankStatementLine" ALTER COLUMN "StatementLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."BankStatementLine_StatementLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fin."Bank" ALTER COLUMN "BankId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fin."Bank_BankId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE fin."PettyCashBox_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE fin."PettyCashExpense_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE fin."PettyCashSession_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fiscal."CountryConfig" ALTER COLUMN "CountryConfigId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."CountryConfig_CountryConfigId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."DeclarationTemplate" ALTER COLUMN "TemplateId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."DeclarationTemplate_TemplateId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."ISLRTariff" ALTER COLUMN "TariffId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."ISLRTariff_TariffId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."InvoiceType" ALTER COLUMN "InvoiceTypeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."InvoiceType_InvoiceTypeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."Record" ALTER COLUMN "FiscalRecordId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."Record_FiscalRecordId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."TaxBookEntry" ALTER COLUMN "EntryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."TaxBookEntry_EntryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."TaxDeclaration" ALTER COLUMN "DeclarationId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."TaxDeclaration_DeclarationId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."TaxRate" ALTER COLUMN "TaxRateId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."TaxRate_TaxRateId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."WithholdingConcept" ALTER COLUMN "ConceptId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."WithholdingConcept_ConceptId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fiscal."WithholdingVoucher" ALTER COLUMN "VoucherId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fiscal."WithholdingVoucher_VoucherId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."FuelLog" ALTER COLUMN "FuelLogId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."FuelLog_FuelLogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."MaintenanceOrderLine" ALTER COLUMN "MaintenanceOrderLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."MaintenanceOrderLine_MaintenanceOrderLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."MaintenanceOrder" ALTER COLUMN "MaintenanceOrderId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."MaintenanceOrder_MaintenanceOrderId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."MaintenanceType" ALTER COLUMN "MaintenanceTypeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."MaintenanceType_MaintenanceTypeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."Trip" ALTER COLUMN "TripId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."Trip_TripId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."VehicleDocument" ALTER COLUMN "VehicleDocumentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."VehicleDocument_VehicleDocumentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE fleet."Vehicle" ALTER COLUMN "VehicleId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME fleet."Vehicle_VehicleId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."DocumentTemplate" ALTER COLUMN "TemplateId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."DocumentTemplate_TemplateId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE hr."EmployeeObligation_EmployeeObligationId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hr."EmployeeTaxProfile" ALTER COLUMN "ProfileId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."EmployeeTaxProfile_ProfileId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE hr."LegalObligation_LegalObligationId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hr."MedicalExam" ALTER COLUMN "MedicalExamId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."MedicalExam_MedicalExamId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."MedicalOrder" ALTER COLUMN "MedicalOrderId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."MedicalOrder_MedicalOrderId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE hr."ObligationFilingDetail_DetailId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE hr."ObligationFiling_ObligationFilingId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE hr."ObligationRiskLevel_ObligationRiskLevelId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hr."OccupationalHealth" ALTER COLUMN "OccupationalHealthId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."OccupationalHealth_OccupationalHealthId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollBatchLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollBatchLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollBatch" ALTER COLUMN "BatchId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollBatch_BatchId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollConcept" ALTER COLUMN "PayrollConceptId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollConcept_PayrollConceptId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollConstant" ALTER COLUMN "PayrollConstantId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollConstant_PayrollConstantId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollRunLine" ALTER COLUMN "PayrollRunLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollRunLine_PayrollRunLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollRun" ALTER COLUMN "PayrollRunId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollRun_PayrollRunId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."PayrollType" ALTER COLUMN "PayrollTypeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."PayrollType_PayrollTypeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."ProfitSharingLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."ProfitSharingLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."ProfitSharing" ALTER COLUMN "ProfitSharingId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."ProfitSharing_ProfitSharingId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SafetyCommitteeMeeting" ALTER COLUMN "MeetingId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SafetyCommitteeMeeting_MeetingId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SafetyCommitteeMember" ALTER COLUMN "MemberId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SafetyCommitteeMember_MemberId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SafetyCommittee" ALTER COLUMN "SafetyCommitteeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SafetyCommittee_SafetyCommitteeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SavingsFundTransaction" ALTER COLUMN "TransactionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SavingsFundTransaction_TransactionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SavingsFund" ALTER COLUMN "SavingsFundId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SavingsFund_SavingsFundId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SavingsLoan" ALTER COLUMN "LoanId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SavingsLoan_LoanId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SettlementProcessLine" ALTER COLUMN "SettlementProcessLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SettlementProcessLine_SettlementProcessLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SettlementProcess" ALTER COLUMN "SettlementProcessId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SettlementProcess_SettlementProcessId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."SocialBenefitsTrust" ALTER COLUMN "TrustId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."SocialBenefitsTrust_TrustId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."TrainingRecord" ALTER COLUMN "TrainingRecordId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."TrainingRecord_TrainingRecordId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."VacationProcessLine" ALTER COLUMN "VacationProcessLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."VacationProcessLine_VacationProcessLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."VacationProcess" ALTER COLUMN "VacationProcessId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."VacationProcess_VacationProcessId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."VacationRequestDay" ALTER COLUMN "DayId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."VacationRequestDay_DayId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE hr."VacationRequest" ALTER COLUMN "RequestId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hr."VacationRequest_RequestId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."InventoryValuationLayer" ALTER COLUMN "LayerId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."InventoryValuationLayer_LayerId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."InventoryValuationMethod" ALTER COLUMN "ValuationMethodId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."InventoryValuationMethod_ValuationMethodId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."ProductBinStock" ALTER COLUMN "ProductBinStockId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."ProductBinStock_ProductBinStockId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."ProductLot" ALTER COLUMN "LotId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."ProductLot_LotId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."ProductSerial" ALTER COLUMN "SerialId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."ProductSerial_SerialId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."StockMovement" ALTER COLUMN "MovementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."StockMovement_MovementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."WarehouseBin" ALTER COLUMN "BinId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."WarehouseBin_BinId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."WarehouseZone" ALTER COLUMN "ZoneId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."WarehouseZone_ZoneId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE inv."Warehouse" ALTER COLUMN "WarehouseId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME inv."Warehouse_WarehouseId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."Carrier" ALTER COLUMN "CarrierId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."Carrier_CarrierId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."DeliveryNoteLine" ALTER COLUMN "DeliveryNoteLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."DeliveryNoteLine_DeliveryNoteLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."DeliveryNoteSerial" ALTER COLUMN "DeliveryNoteSerialId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."DeliveryNoteSerial_DeliveryNoteSerialId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."DeliveryNote" ALTER COLUMN "DeliveryNoteId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."DeliveryNote_DeliveryNoteId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."Driver" ALTER COLUMN "DriverId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."Driver_DriverId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."GoodsReceiptLine" ALTER COLUMN "GoodsReceiptLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."GoodsReceiptLine_GoodsReceiptLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."GoodsReceiptSerial" ALTER COLUMN "GoodsReceiptSerialId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."GoodsReceiptSerial_GoodsReceiptSerialId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."GoodsReceipt" ALTER COLUMN "GoodsReceiptId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."GoodsReceipt_GoodsReceiptId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."GoodsReturnLine" ALTER COLUMN "GoodsReturnLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."GoodsReturnLine_GoodsReturnLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE logistics."GoodsReturn" ALTER COLUMN "GoodsReturnId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistics."GoodsReturn_GoodsReturnId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."AlternateStock" ALTER COLUMN "AlternateStockId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."AlternateStock_AlternateStockId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Brand" ALTER COLUMN "BrandId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Brand_BrandId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Category" ALTER COLUMN "CategoryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Category_CategoryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."CostCenter" ALTER COLUMN "CostCenterId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."CostCenter_CostCenterId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE master."CustomerAddress_AddressId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE master."CustomerPaymentMethod_PaymentMethodId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master."Customer" ALTER COLUMN "CustomerId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Customer_CustomerId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Employee" ALTER COLUMN "EmployeeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Employee_EmployeeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."InventoryMovement" ALTER COLUMN "MovementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."InventoryMovement_MovementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."InventoryPeriodSummary" ALTER COLUMN "SummaryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."InventoryPeriodSummary_SummaryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."ProductClass" ALTER COLUMN "ClassId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."ProductClass_ClassId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."ProductGroup" ALTER COLUMN "GroupId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."ProductGroup_GroupId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."ProductLine" ALTER COLUMN "LineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."ProductLine_LineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."ProductType" ALTER COLUMN "TypeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."ProductType_TypeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Product" ALTER COLUMN "ProductId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Product_ProductId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Seller" ALTER COLUMN "SellerId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Seller_SellerId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."SupplierLine" ALTER COLUMN "SupplierLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."SupplierLine_SupplierLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Supplier" ALTER COLUMN "SupplierId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Supplier_SupplierId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."TaxRetention" ALTER COLUMN "RetentionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."TaxRetention_RetentionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."UnitOfMeasure" ALTER COLUMN "UnitId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."UnitOfMeasure_UnitId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE master."Warehouse" ALTER COLUMN "WarehouseId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME master."Warehouse_WarehouseId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."BOMLine" ALTER COLUMN "BOMLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."BOMLine_BOMLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."BillOfMaterials" ALTER COLUMN "BOMId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."BillOfMaterials_BOMId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."Routing" ALTER COLUMN "RoutingId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."Routing_RoutingId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."WorkCenter" ALTER COLUMN "WorkCenterId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."WorkCenter_WorkCenterId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."WorkOrderMaterial" ALTER COLUMN "WorkOrderMaterialId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."WorkOrderMaterial_WorkOrderMaterialId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."WorkOrderOutput" ALTER COLUMN "WorkOrderOutputId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."WorkOrderOutput_WorkOrderOutputId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE mfg."WorkOrder" ALTER COLUMN "WorkOrderId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME mfg."WorkOrder_WorkOrderId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."AcceptedPaymentMethods" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."AcceptedPaymentMethods_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."CardReaderDevices" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."CardReaderDevices_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."CompanyPaymentConfig" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."CompanyPaymentConfig_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."PaymentMethods" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."PaymentMethods_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."PaymentProviders" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."PaymentProviders_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."ProviderCapabilities" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."ProviderCapabilities_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."ReconciliationBatches" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."ReconciliationBatches_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pay."Transactions" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pay."Transactions_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pos."FiscalCorrelative" ALTER COLUMN "FiscalCorrelativeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos."FiscalCorrelative_FiscalCorrelativeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pos."SaleTicketLine" ALTER COLUMN "SaleTicketLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos."SaleTicketLine_SaleTicketLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pos."SaleTicket" ALTER COLUMN "SaleTicketId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos."SaleTicket_SaleTicketId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pos."WaitTicketLine" ALTER COLUMN "WaitTicketLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos."WaitTicketLine_WaitTicketLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE pos."WaitTicket" ALTER COLUMN "WaitTicketId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos."WaitTicket_WaitTicketId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE public."ConciliacionBancaria_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."ConciliacionDetalle_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."ExtractoBancario_ID_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Lead" ALTER COLUMN "LeadId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Lead_LeadId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE public."PosVentasDetalle_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."PosVentasEnEsperaDetalle_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."PosVentasEnEspera_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."PosVentas_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteAmbientes_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteCategorias_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteComponenteOpciones_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteComprasDetalle_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteCompras_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteMesas_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestaurantePedidoItems_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestaurantePedidos_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteProductoComponentes_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteProductos_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."RestauranteRecetas_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."SchemaGovernanceDecision" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."SchemaGovernanceDecision_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE public."SchemaGovernanceSnapshot" ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."SchemaGovernanceSnapshot_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE public."Sys_Mensajes_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."Sys_Notificaciones_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public."Sys_Tareas_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public._migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE public.goose_db_version_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rest."DiningTable" ALTER COLUMN "DiningTableId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."DiningTable_DiningTableId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuCategory" ALTER COLUMN "MenuCategoryId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuCategory_MenuCategoryId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuComponent" ALTER COLUMN "MenuComponentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuComponent_MenuComponentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuEnvironment" ALTER COLUMN "MenuEnvironmentId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuEnvironment_MenuEnvironmentId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuOption" ALTER COLUMN "MenuOptionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuOption_MenuOptionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuProduct" ALTER COLUMN "MenuProductId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuProduct_MenuProductId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."MenuRecipe" ALTER COLUMN "MenuRecipeId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."MenuRecipe_MenuRecipeId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."OrderTicketLine" ALTER COLUMN "OrderTicketLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."OrderTicketLine_OrderTicketLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."OrderTicket" ALTER COLUMN "OrderTicketId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."OrderTicket_OrderTicketId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."PurchaseLine" ALTER COLUMN "PurchaseLineId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."PurchaseLine_PurchaseLineId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE rest."Purchase" ALTER COLUMN "PurchaseId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rest."Purchase_PurchaseId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."ApprovalAction" ALTER COLUMN "ApprovalActionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."ApprovalAction_ApprovalActionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."ApprovalRequest" ALTER COLUMN "ApprovalRequestId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."ApprovalRequest_ApprovalRequestId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."ApprovalRule" ALTER COLUMN "ApprovalRuleId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."ApprovalRule_ApprovalRuleId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."AuthToken" ALTER COLUMN "TokenId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."AuthToken_TokenId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."Permission" ALTER COLUMN "PermissionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."Permission_PermissionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."PriceRestriction" ALTER COLUMN "PriceRestrictionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."PriceRestriction_PriceRestrictionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."RolePermission" ALTER COLUMN "RolePermissionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."RolePermission_RolePermissionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."Role" ALTER COLUMN "RoleId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."Role_RoleId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."SupervisorBiometricCredential" ALTER COLUMN "BiometricCredentialId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."SupervisorBiometricCredential_BiometricCredentialId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."SupervisorOverride" ALTER COLUMN "OverrideId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."SupervisorOverride_OverrideId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE sec."UserCompanyAccess_AccessId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sec."UserModuleAccess" ALTER COLUMN "AccessId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."UserModuleAccess_AccessId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."UserPermissionOverride" ALTER COLUMN "UserPermissionOverrideId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."UserPermissionOverride_UserPermissionOverrideId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."UserRole" ALTER COLUMN "UserRoleId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."UserRole_UserRoleId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sec."User" ALTER COLUMN "UserId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sec."User_UserId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE store."IndustryTemplateAttribute_TemplateAttributeId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE store."IndustryTemplate_IndustryTemplateId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE store."ProductAttribute_ProductAttributeId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE store."ProductHighlight" ALTER COLUMN "HighlightId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME store."ProductHighlight_HighlightId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE store."ProductReview" ALTER COLUMN "ReviewId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME store."ProductReview_ReviewId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE store."ProductSpec" ALTER COLUMN "SpecId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME store."ProductSpec_SpecId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


CREATE SEQUENCE store."ProductVariantGroup_VariantGroupId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE store."ProductVariantOptionValue_VariantOptionValueId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE store."ProductVariantOption_VariantOptionId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE SEQUENCE store."ProductVariant_ProductVariantId_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sys."BillingEvent" ALTER COLUMN "BillingEventId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."BillingEvent_BillingEventId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."CleanupQueue" ALTER COLUMN "QueueId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."CleanupQueue_QueueId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."License" ALTER COLUMN "LicenseId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."License_LicenseId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."PushDevice" ALTER COLUMN "DeviceId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."PushDevice_DeviceId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."Subscription" ALTER COLUMN "SubscriptionId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."Subscription_SubscriptionId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."TenantBackup" ALTER COLUMN "BackupId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."TenantBackup_BackupId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."TenantDatabase" ALTER COLUMN "TenantDbId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."TenantDatabase_TenantDbId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


ALTER TABLE sys."TenantResourceLog" ALTER COLUMN "LogId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sys."TenantResourceLog_LogId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


-- Sequence ownership


ALTER SEQUENCE audit."AuditLog_AuditLogId_seq" OWNED BY audit."AuditLog"."AuditLogId";

ALTER SEQUENCE fin."PettyCashBox_Id_seq" OWNED BY fin."PettyCashBox"."Id";

ALTER SEQUENCE fin."PettyCashExpense_Id_seq" OWNED BY fin."PettyCashExpense"."Id";

ALTER SEQUENCE fin."PettyCashSession_Id_seq" OWNED BY fin."PettyCashSession"."Id";

ALTER SEQUENCE hr."EmployeeObligation_EmployeeObligationId_seq" OWNED BY hr."EmployeeObligation"."EmployeeObligationId";

ALTER SEQUENCE hr."LegalObligation_LegalObligationId_seq" OWNED BY hr."LegalObligation"."LegalObligationId";

ALTER SEQUENCE hr."ObligationFilingDetail_DetailId_seq" OWNED BY hr."ObligationFilingDetail"."DetailId";

ALTER SEQUENCE hr."ObligationFiling_ObligationFilingId_seq" OWNED BY hr."ObligationFiling"."ObligationFilingId";

ALTER SEQUENCE hr."ObligationRiskLevel_ObligationRiskLevelId_seq" OWNED BY hr."ObligationRiskLevel"."ObligationRiskLevelId";

ALTER SEQUENCE master."CustomerAddress_AddressId_seq" OWNED BY master."CustomerAddress"."AddressId";

ALTER SEQUENCE master."CustomerPaymentMethod_PaymentMethodId_seq" OWNED BY master."CustomerPaymentMethod"."PaymentMethodId";

ALTER SEQUENCE public."ConciliacionBancaria_ID_seq" OWNED BY public."ConciliacionBancaria"."ID";

ALTER SEQUENCE public."ConciliacionDetalle_ID_seq" OWNED BY public."ConciliacionDetalle"."ID";

ALTER SEQUENCE public."ExtractoBancario_ID_seq" OWNED BY public."ExtractoBancario"."ID";

ALTER SEQUENCE public."PosVentasDetalle_Id_seq" OWNED BY public."PosVentasDetalle"."Id";

ALTER SEQUENCE public."PosVentasEnEsperaDetalle_Id_seq" OWNED BY public."PosVentasEnEsperaDetalle"."Id";

ALTER SEQUENCE public."PosVentasEnEspera_Id_seq" OWNED BY public."PosVentasEnEspera"."Id";

ALTER SEQUENCE public."PosVentas_Id_seq" OWNED BY public."PosVentas"."Id";

ALTER SEQUENCE public."RestauranteAmbientes_Id_seq" OWNED BY public."RestauranteAmbientes"."Id";

ALTER SEQUENCE public."RestauranteCategorias_Id_seq" OWNED BY public."RestauranteCategorias"."Id";

ALTER SEQUENCE public."RestauranteComponenteOpciones_Id_seq" OWNED BY public."RestauranteComponenteOpciones"."Id";

ALTER SEQUENCE public."RestauranteComprasDetalle_Id_seq" OWNED BY public."RestauranteComprasDetalle"."Id";

ALTER SEQUENCE public."RestauranteCompras_Id_seq" OWNED BY public."RestauranteCompras"."Id";

ALTER SEQUENCE public."RestauranteMesas_Id_seq" OWNED BY public."RestauranteMesas"."Id";

ALTER SEQUENCE public."RestaurantePedidoItems_Id_seq" OWNED BY public."RestaurantePedidoItems"."Id";

ALTER SEQUENCE public."RestaurantePedidos_Id_seq" OWNED BY public."RestaurantePedidos"."Id";

ALTER SEQUENCE public."RestauranteProductoComponentes_Id_seq" OWNED BY public."RestauranteProductoComponentes"."Id";

ALTER SEQUENCE public."RestauranteProductos_Id_seq" OWNED BY public."RestauranteProductos"."Id";

ALTER SEQUENCE public."RestauranteRecetas_Id_seq" OWNED BY public."RestauranteRecetas"."Id";

ALTER SEQUENCE public."Sys_Mensajes_Id_seq" OWNED BY public."Sys_Mensajes"."Id";

ALTER SEQUENCE public."Sys_Notificaciones_Id_seq" OWNED BY public."Sys_Notificaciones"."Id";

ALTER SEQUENCE public."Sys_Tareas_Id_seq" OWNED BY public."Sys_Tareas"."Id";

ALTER SEQUENCE public._migrations_id_seq OWNED BY public._migrations.id;

ALTER SEQUENCE public.goose_db_version_id_seq OWNED BY public.goose_db_version.id;

ALTER SEQUENCE sec."UserCompanyAccess_AccessId_seq" OWNED BY sec."UserCompanyAccess"."AccessId";

ALTER SEQUENCE store."IndustryTemplateAttribute_TemplateAttributeId_seq" OWNED BY store."IndustryTemplateAttribute"."TemplateAttributeId";

ALTER SEQUENCE store."IndustryTemplate_IndustryTemplateId_seq" OWNED BY store."IndustryTemplate"."IndustryTemplateId";

ALTER SEQUENCE store."ProductAttribute_ProductAttributeId_seq" OWNED BY store."ProductAttribute"."ProductAttributeId";

ALTER SEQUENCE store."ProductVariantGroup_VariantGroupId_seq" OWNED BY store."ProductVariantGroup"."VariantGroupId";

ALTER SEQUENCE store."ProductVariantOptionValue_VariantOptionValueId_seq" OWNED BY store."ProductVariantOptionValue"."VariantOptionValueId";

ALTER SEQUENCE store."ProductVariantOption_VariantOptionId_seq" OWNED BY store."ProductVariantOption"."VariantOptionId";

ALTER SEQUENCE store."ProductVariant_ProductVariantId_seq" OWNED BY store."ProductVariant"."ProductVariantId";


-- Column defaults (link sequences to columns)


ALTER TABLE ONLY audit."AuditLog" ALTER COLUMN "AuditLogId" SET DEFAULT nextval('audit."AuditLog_AuditLogId_seq"'::regclass);

ALTER TABLE ONLY fin."PettyCashBox" ALTER COLUMN "Id" SET DEFAULT nextval('fin."PettyCashBox_Id_seq"'::regclass);

ALTER TABLE ONLY fin."PettyCashExpense" ALTER COLUMN "Id" SET DEFAULT nextval('fin."PettyCashExpense_Id_seq"'::regclass);

ALTER TABLE ONLY fin."PettyCashSession" ALTER COLUMN "Id" SET DEFAULT nextval('fin."PettyCashSession_Id_seq"'::regclass);

ALTER TABLE ONLY hr."EmployeeObligation" ALTER COLUMN "EmployeeObligationId" SET DEFAULT nextval('hr."EmployeeObligation_EmployeeObligationId_seq"'::regclass);

ALTER TABLE ONLY hr."LegalObligation" ALTER COLUMN "LegalObligationId" SET DEFAULT nextval('hr."LegalObligation_LegalObligationId_seq"'::regclass);

ALTER TABLE ONLY hr."ObligationFiling" ALTER COLUMN "ObligationFilingId" SET DEFAULT nextval('hr."ObligationFiling_ObligationFilingId_seq"'::regclass);

ALTER TABLE ONLY hr."ObligationFilingDetail" ALTER COLUMN "DetailId" SET DEFAULT nextval('hr."ObligationFilingDetail_DetailId_seq"'::regclass);

ALTER TABLE ONLY hr."ObligationRiskLevel" ALTER COLUMN "ObligationRiskLevelId" SET DEFAULT nextval('hr."ObligationRiskLevel_ObligationRiskLevelId_seq"'::regclass);

ALTER TABLE ONLY master."CustomerAddress" ALTER COLUMN "AddressId" SET DEFAULT nextval('master."CustomerAddress_AddressId_seq"'::regclass);

ALTER TABLE ONLY master."CustomerPaymentMethod" ALTER COLUMN "PaymentMethodId" SET DEFAULT nextval('master."CustomerPaymentMethod_PaymentMethodId_seq"'::regclass);

ALTER TABLE ONLY public."ConciliacionBancaria" ALTER COLUMN "ID" SET DEFAULT nextval('public."ConciliacionBancaria_ID_seq"'::regclass);

ALTER TABLE ONLY public."ConciliacionDetalle" ALTER COLUMN "ID" SET DEFAULT nextval('public."ConciliacionDetalle_ID_seq"'::regclass);

ALTER TABLE ONLY public."ExtractoBancario" ALTER COLUMN "ID" SET DEFAULT nextval('public."ExtractoBancario_ID_seq"'::regclass);

ALTER TABLE ONLY public."PosVentas" ALTER COLUMN "Id" SET DEFAULT nextval('public."PosVentas_Id_seq"'::regclass);

ALTER TABLE ONLY public."PosVentasDetalle" ALTER COLUMN "Id" SET DEFAULT nextval('public."PosVentasDetalle_Id_seq"'::regclass);

ALTER TABLE ONLY public."PosVentasEnEspera" ALTER COLUMN "Id" SET DEFAULT nextval('public."PosVentasEnEspera_Id_seq"'::regclass);

ALTER TABLE ONLY public."PosVentasEnEsperaDetalle" ALTER COLUMN "Id" SET DEFAULT nextval('public."PosVentasEnEsperaDetalle_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteAmbientes" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteAmbientes_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteCategorias" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteCategorias_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteComponenteOpciones" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteComponenteOpciones_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteCompras" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteCompras_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteComprasDetalle" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteComprasDetalle_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteMesas" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteMesas_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestaurantePedidoItems" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestaurantePedidoItems_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestaurantePedidos" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestaurantePedidos_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteProductoComponentes" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteProductoComponentes_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteProductos" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteProductos_Id_seq"'::regclass);

ALTER TABLE ONLY public."RestauranteRecetas" ALTER COLUMN "Id" SET DEFAULT nextval('public."RestauranteRecetas_Id_seq"'::regclass);

ALTER TABLE ONLY public."Sys_Mensajes" ALTER COLUMN "Id" SET DEFAULT nextval('public."Sys_Mensajes_Id_seq"'::regclass);

ALTER TABLE ONLY public."Sys_Notificaciones" ALTER COLUMN "Id" SET DEFAULT nextval('public."Sys_Notificaciones_Id_seq"'::regclass);

ALTER TABLE ONLY public."Sys_Tareas" ALTER COLUMN "Id" SET DEFAULT nextval('public."Sys_Tareas_Id_seq"'::regclass);

ALTER TABLE ONLY public._migrations ALTER COLUMN id SET DEFAULT nextval('public._migrations_id_seq'::regclass);

ALTER TABLE ONLY public.goose_db_version ALTER COLUMN id SET DEFAULT nextval('public.goose_db_version_id_seq'::regclass);

ALTER TABLE ONLY sec."UserCompanyAccess" ALTER COLUMN "AccessId" SET DEFAULT nextval('sec."UserCompanyAccess_AccessId_seq"'::regclass);

ALTER TABLE ONLY store."IndustryTemplate" ALTER COLUMN "IndustryTemplateId" SET DEFAULT nextval('store."IndustryTemplate_IndustryTemplateId_seq"'::regclass);

ALTER TABLE ONLY store."IndustryTemplateAttribute" ALTER COLUMN "TemplateAttributeId" SET DEFAULT nextval('store."IndustryTemplateAttribute_TemplateAttributeId_seq"'::regclass);

ALTER TABLE ONLY store."ProductAttribute" ALTER COLUMN "ProductAttributeId" SET DEFAULT nextval('store."ProductAttribute_ProductAttributeId_seq"'::regclass);

ALTER TABLE ONLY store."ProductVariant" ALTER COLUMN "ProductVariantId" SET DEFAULT nextval('store."ProductVariant_ProductVariantId_seq"'::regclass);

ALTER TABLE ONLY store."ProductVariantGroup" ALTER COLUMN "VariantGroupId" SET DEFAULT nextval('store."ProductVariantGroup_VariantGroupId_seq"'::regclass);

ALTER TABLE ONLY store."ProductVariantOption" ALTER COLUMN "VariantOptionId" SET DEFAULT nextval('store."ProductVariantOption_VariantOptionId_seq"'::regclass);

ALTER TABLE ONLY store."ProductVariantOptionValue" ALTER COLUMN "VariantOptionValueId" SET DEFAULT nextval('store."ProductVariantOptionValue_VariantOptionValueId_seq"'::regclass);

