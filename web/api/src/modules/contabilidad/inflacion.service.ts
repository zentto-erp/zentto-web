import { callSp, callSpOut, sql } from "../../db/query.js";

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

export async function listInflationIndices(input: {
  countryCode?: string;
  indexName?: string;
  yearFrom?: number;
  yearTo?: number;
}) {
  const scope = await getDefaultScope();
  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_InflationIndex_List",
    {
      CompanyId: scope.companyId,
      CountryCode: input.countryCode || "VE",
      IndexName: input.indexName || "INPC",
      YearFrom: input.yearFrom || null,
      YearTo: input.yearTo || null,
    },
    { TotalCount: sql.Int }
  );
  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function upsertInflationIndex(input: {
  countryCode: string;
  indexName: string;
  periodCode: string;
  indexValue: number;
  sourceReference?: string;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_InflationIndex_Upsert",
    {
      CompanyId: scope.companyId,
      CountryCode: input.countryCode,
      IndexName: input.indexName,
      PeriodCode: input.periodCode,
      IndexValue: input.indexValue,
      SourceReference: input.sourceReference || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function bulkLoadIndices(input: {
  countryCode: string;
  indexName: string;
  xmlData: string;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_InflationIndex_BulkLoad",
    {
      CompanyId: scope.companyId,
      CountryCode: input.countryCode,
      IndexName: input.indexName,
      JsonData: input.xmlData,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function listMonetaryClassifications(input: {
  classification?: string;
  search?: string;
}) {
  const scope = await getDefaultScope();
  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_AccountMonetaryClass_List",
    {
      CompanyId: scope.companyId,
      Classification: input.classification || null,
      Search: input.search || null,
    },
    { TotalCount: sql.Int }
  );
  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function upsertMonetaryClassification(input: {
  accountId: number;
  classification: string;
  subClassification?: string;
  reexpressionAccountId?: number;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_AccountMonetaryClass_Upsert",
    {
      CompanyId: scope.companyId,
      AccountId: input.accountId,
      Classification: input.classification,
      SubClassification: input.subClassification || null,
      ReexpressionAccountId: input.reexpressionAccountId || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function autoClassifyAccounts() {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_AccountMonetaryClass_AutoClassify",
    { CompanyId: scope.companyId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function calculateInflationAdjustment(input: {
  periodCode: string;
  fiscalYear: number;
  userId?: number;
}) {
  const scope = await getDefaultScope();
  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Inflation_Calculate",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: input.periodCode,
      FiscalYear: input.fiscalYear,
      UserId: input.userId || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje), data: rows[0] || null };
}

export async function postInflationAdjustment(adjustmentId: number) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_Inflation_Post",
    {
      CompanyId: scope.companyId,
      AdjustmentId: adjustmentId,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function voidInflationAdjustment(adjustmentId: number, motivo?: string) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_Inflation_Void",
    {
      CompanyId: scope.companyId,
      AdjustmentId: adjustmentId,
      Motivo: motivo || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function getBalanceReexpresado(fechaCorte: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_BalanceReexpresado",
    { CompanyId: scope.companyId, BranchId: scope.branchId, FechaCorte: fechaCorte }
  );
  return { rows };
}

export async function getREME(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_REME",
    { CompanyId: scope.companyId, BranchId: scope.branchId, FechaDesde: fechaDesde, FechaHasta: fechaHasta }
  );
  return { rows };
}
