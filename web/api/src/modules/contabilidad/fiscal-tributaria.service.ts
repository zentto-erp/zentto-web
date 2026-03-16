import { callSp, callSpOut, sql } from "../../db/query.js";

// ─── Scope helper ────────────────────────────────────────────────────
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

export interface TaxBookFilter {
  bookType: string;   // PURCHASE | SALES
  periodCode: string; // YYYY-MM
  countryCode: string;
  page?: number;
  limit?: number;
}

export interface DeclarationFilter {
  declarationType?: string;
  year?: number;
  status?: string;
  page?: number;
  limit?: number;
}

export interface CalculateDeclarationInput {
  declarationType: string;
  periodCode: string;
  countryCode: string;
}

export interface WithholdingGenerateInput {
  documentId: number;
  withholdingType: string; // IVA, ISLR, IRPF
  countryCode: string;
}

export interface WithholdingFilter {
  withholdingType?: string;
  periodCode?: string;
  countryCode?: string;
  page?: number;
  limit?: number;
}

// ─── Tax Books ───────────────────────────────────────────────────────

export async function populateTaxBook(bookType: string, periodCode: string, countryCode: string, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_TaxBook_Populate",
    {
      CompanyId: scope.companyId,
      BookType: bookType,
      PeriodCode: periodCode,
      CountryCode: countryCode,
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

export async function listTaxBook(filter: TaxBookFilter) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_TaxBook_List",
    {
      CompanyId: scope.companyId,
      BookType: filter.bookType,
      PeriodCode: filter.periodCode,
      CountryCode: filter.countryCode,
      Page: filter.page ?? 1,
      Limit: filter.limit ?? 100,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

export async function taxBookSummary(bookType: string, periodCode: string, countryCode: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Fiscal_TaxBook_Summary",
    {
      CompanyId: scope.companyId,
      BookType: bookType,
      PeriodCode: periodCode,
      CountryCode: countryCode,
    }
  );
}

// ─── Declarations ────────────────────────────────────────────────────

export async function calculateDeclaration(data: CalculateDeclarationInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Declaration_Calculate",
    {
      CompanyId: scope.companyId,
      DeclarationType: data.declarationType,
      PeriodCode: data.periodCode,
      CountryCode: data.countryCode,
      CodUsuario: codUsuario,
    },
    { DeclarationId: sql.BigInt, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    declarationId: result.output.DeclarationId,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

export async function listDeclarations(filter: DeclarationFilter = {}) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Declaration_List",
    {
      CompanyId: scope.companyId,
      DeclarationType: filter.declarationType || null,
      Year: filter.year || null,
      Status: filter.status || null,
      Page: filter.page ?? 1,
      Limit: filter.limit ?? 50,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

export async function getDeclaration(declarationId: number) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Fiscal_Declaration_Get",
    { CompanyId: scope.companyId, DeclarationId: declarationId }
  );
  return rows[0] || null;
}

export async function submitDeclaration(declarationId: number, filePath: string | null, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Declaration_Submit",
    {
      CompanyId: scope.companyId,
      DeclarationId: declarationId,
      FilePath: filePath || null,
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

export async function amendDeclaration(declarationId: number, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Declaration_Amend",
    {
      CompanyId: scope.companyId,
      DeclarationId: declarationId,
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

// ─── Withholdings ────────────────────────────────────────────────────

export async function generateWithholding(data: WithholdingGenerateInput, codUsuario: string) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Withholding_Generate",
    {
      CompanyId: scope.companyId,
      DocumentId: data.documentId,
      WithholdingType: data.withholdingType,
      CountryCode: data.countryCode,
      CodUsuario: codUsuario,
    },
    { VoucherId: sql.BigInt, Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  return {
    ok: result.output.Resultado === 1,
    voucherId: result.output.VoucherId,
    resultado: result.output.Resultado,
    mensaje: result.output.Mensaje,
  };
}

export async function listWithholdings(filter: WithholdingFilter = {}) {
  const scope = await getDefaultScope();
  const result = await callSpOut<any>(
    "dbo.usp_Fiscal_Withholding_List",
    {
      CompanyId: scope.companyId,
      WithholdingType: filter.withholdingType || null,
      PeriodCode: filter.periodCode || null,
      CountryCode: filter.countryCode || null,
      Page: filter.page ?? 1,
      Limit: filter.limit ?? 50,
    },
    { TotalCount: sql.Int }
  );
  return { rows: result.rows, total: result.output.TotalCount };
}

export async function getWithholding(voucherId: number) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Fiscal_Withholding_Get",
    { CompanyId: scope.companyId, VoucherId: voucherId }
  );
  return rows[0] || null;
}

// ─── Export (data for file generation) ───────────────────────────────

export async function exportTaxBook(bookType: string, periodCode: string, countryCode: string) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Fiscal_Export_TaxBook",
    {
      CompanyId: scope.companyId,
      BookType: bookType,
      PeriodCode: periodCode,
      CountryCode: countryCode,
    }
  );
}

export async function exportDeclaration(declarationId: number) {
  const scope = await getDefaultScope();
  return callSp<any>(
    "dbo.usp_Fiscal_Export_Declaration",
    { CompanyId: scope.companyId, DeclarationId: declarationId }
  );
}
