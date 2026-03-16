import { callSp, callSpOut, sql } from "../../db/query.js";

// ─── Scope helper (same pattern as service.ts) ──────────────────────
async function getDefaultScope() {
  const rows = await callSp<{ CompanyId: number; BranchId: number }>(
    "dbo.usp_Acct_Scope_GetDefault"
  );
  const companyId = Number(rows[0]?.CompanyId ?? 0);
  const branchId = Number(rows[0]?.BranchId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");
  return { companyId, branchId };
}

// ─── Types ───────────────────────────────────────────────────────────

export interface CategoryInput {
  categoryCode: string;
  categoryName: string;
  defaultUsefulLifeMonths: number;
  defaultDepreciationMethod?: string;
  defaultResidualPercent?: number;
  defaultAssetAccountCode?: string;
  defaultDeprecAccountCode?: string;
  defaultExpenseAccountCode?: string;
  countryCode?: string;
}

export interface AssetInput {
  assetCode: string;
  description: string;
  categoryId: number;
  acquisitionDate: string;
  acquisitionCost: number;
  residualValue?: number;
  usefulLifeMonths: number;
  depreciationMethod?: string;
  assetAccountCode: string;
  deprecAccountCode: string;
  expenseAccountCode: string;
  costCenterCode?: string;
  location?: string;
  serialNumber?: string;
  unitsCapacity?: number;
  currencyCode?: string;
}

export interface AssetUpdateInput {
  description?: string;
  location?: string;
  serialNumber?: string;
  costCenterCode?: string;
  currencyCode?: string;
}

export interface DisposeInput {
  disposalDate: string;
  disposalAmount?: number;
  disposalReason?: string;
}

export interface ImprovementInput {
  improvementDate: string;
  description: string;
  amount: number;
  additionalLifeMonths?: number;
}

export interface RevalueInput {
  revaluationDate: string;
  indexFactor: number;
  countryCode: string;
}

export interface AssetFilter {
  categoryCode?: string;
  status?: string;
  costCenterCode?: string;
  search?: string;
  page?: number;
  limit?: number;
}

// ─── Categories ──────────────────────────────────────────────────────

export async function listCategories(search?: string, page = 1, limit = 50) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAssetCategory_List",
    {
      CompanyId: scope.companyId,
      Search: search || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

export async function getCategory(categoryCode: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_FixedAssetCategory_Get",
    { CompanyId: scope.companyId, CategoryCode: categoryCode }
  );
  return rows[0] || null;
}

export async function upsertCategory(data: CategoryInput) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAssetCategory_Upsert",
    {
      CompanyId: scope.companyId,
      CategoryCode: data.categoryCode,
      CategoryName: data.categoryName,
      DefaultUsefulLifeMonths: data.defaultUsefulLifeMonths,
      DefaultDepreciationMethod: data.defaultDepreciationMethod || "STRAIGHT_LINE",
      DefaultResidualPercent: data.defaultResidualPercent ?? 0,
      DefaultAssetAccountCode: data.defaultAssetAccountCode || null,
      DefaultDeprecAccountCode: data.defaultDeprecAccountCode || null,
      DefaultExpenseAccountCode: data.defaultExpenseAccountCode || null,
      CountryCode: data.countryCode || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

// ─── Assets CRUD ─────────────────────────────────────────────────────

export async function listAssets(filter: AssetFilter = {}) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      CategoryCode: filter.categoryCode || null,
      Status: filter.status || null,
      CostCenterCode: filter.costCenterCode || null,
      Search: filter.search || null,
      Page: filter.page ?? 1,
      Limit: filter.limit ?? 50,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

export async function getAsset(assetId: number) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_FixedAsset_Get",
    { CompanyId: scope.companyId, AssetId: assetId }
  );
  return rows[0] || null;
}

export async function insertAsset(data: AssetInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_Insert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      AssetCode: data.assetCode,
      Description: data.description,
      CategoryId: data.categoryId,
      AcquisitionDate: data.acquisitionDate,
      AcquisitionCost: data.acquisitionCost,
      ResidualValue: data.residualValue ?? 0,
      UsefulLifeMonths: data.usefulLifeMonths,
      DepreciationMethod: data.depreciationMethod || "STRAIGHT_LINE",
      AssetAccountCode: data.assetAccountCode,
      DeprecAccountCode: data.deprecAccountCode,
      ExpenseAccountCode: data.expenseAccountCode,
      CostCenterCode: data.costCenterCode || null,
      Location: data.location || null,
      SerialNumber: data.serialNumber || null,
      UnitsCapacity: data.unitsCapacity || null,
      CurrencyCode: data.currencyCode || "VES",
      CodUsuario: codUsuario,
    },
    { AssetId: sql.BigInt, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    assetId: result.output.AssetId,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

export async function updateAsset(assetId: number, data: AssetUpdateInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_Update",
    {
      CompanyId: scope.companyId,
      AssetId: assetId,
      Description: data.description || null,
      Location: data.location || null,
      SerialNumber: data.serialNumber || null,
      CostCenterCode: data.costCenterCode || null,
      CurrencyCode: data.currencyCode || null,
      CodUsuario: codUsuario,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

export async function disposeAsset(assetId: number, data: DisposeInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_Dispose",
    {
      CompanyId: scope.companyId,
      AssetId: assetId,
      DisposalDate: data.disposalDate,
      DisposalAmount: data.disposalAmount ?? 0,
      DisposalReason: data.disposalReason || null,
      CodUsuario: codUsuario,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

// ─── Depreciation ────────────────────────────────────────────────────

export async function calculateDepreciation(periodo: string, preview: boolean, costCenterCode?: string, codUsuario?: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_CalculateDepreciation",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: periodo,
      CostCenterCode: costCenterCode || null,
      Preview: preview ? 1 : 0,
      CodUsuario: codUsuario || "API",
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500), EntriesGenerated: sql.Int }
  );
  return {
    ok: result.output.Resultado === 1,
    rows: result.rows,
    entriesGenerated: result.output.EntriesGenerated,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

export async function depreciationHistory(assetId: number, page = 1, limit = 50) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_DepreciationHistory",
    {
      CompanyId: scope.companyId,
      AssetId: assetId,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

// ─── Improvements ────────────────────────────────────────────────────

export async function addImprovement(assetId: number, data: ImprovementInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_AddImprovement",
    {
      CompanyId: scope.companyId,
      AssetId: assetId,
      ImprovementDate: data.improvementDate,
      Description: data.description,
      Amount: data.amount,
      AdditionalLifeMonths: data.additionalLifeMonths ?? 0,
      CodUsuario: codUsuario,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

// ─── Revaluation ─────────────────────────────────────────────────────

export async function revalueAsset(assetId: number, data: RevalueInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Acct_FixedAsset_Revalue",
    {
      CompanyId: scope.companyId,
      AssetId: assetId,
      RevaluationDate: data.revaluationDate,
      IndexFactor: data.indexFactor,
      CountryCode: data.countryCode,
      CodUsuario: codUsuario,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

// ─── Reports ─────────────────────────────────────────────────────────

export async function reportAssetBook(fechaCorte: string, categoryCode?: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_FixedAsset_Report_Book",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaCorte: fechaCorte,
      CategoryCode: categoryCode || null,
    }
  );
}

export async function reportDepreciationSchedule(assetId: number) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_FixedAsset_Report_DepreciationSchedule",
    { CompanyId: scope.companyId, AssetId: assetId }
  );
}

export async function reportByCategory(fechaCorte: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Acct_FixedAsset_Report_ByCategory",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FechaCorte: fechaCorte,
    }
  );
}
