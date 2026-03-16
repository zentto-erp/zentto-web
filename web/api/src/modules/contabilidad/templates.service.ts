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

export async function listTemplates(input: {
  countryCode?: string;
  reportCode?: string;
}) {
  const scope = await getDefaultScope();
  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_ReportTemplate_List",
    {
      CompanyId: scope.companyId,
      CountryCode: input.countryCode || null,
      ReportCode: input.reportCode || null,
    },
    { TotalCount: sql.Int }
  );
  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function getTemplate(templateId: number) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_ReportTemplate_Get",
    { CompanyId: scope.companyId, ReportTemplateId: templateId }
  );
  return rows[0] || null;
}

export async function upsertTemplate(input: {
  reportTemplateId?: number;
  countryCode?: string;
  reportCode?: string;
  reportName?: string;
  legalFramework?: string;
  legalReference?: string;
  templateContent?: string;
  headerJson?: string;
  footerJson?: string;
  userId?: number;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_ReportTemplate_Upsert",
    {
      CompanyId: scope.companyId,
      ReportTemplateId: input.reportTemplateId || null,
      CountryCode: input.countryCode || null,
      ReportCode: input.reportCode || null,
      ReportName: input.reportName || null,
      LegalFramework: input.legalFramework || null,
      LegalReference: input.legalReference || null,
      TemplateContent: input.templateContent || null,
      HeaderJson: input.headerJson || null,
      FooterJson: input.footerJson || null,
      UserId: input.userId || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function deleteTemplate(templateId: number) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_ReportTemplate_Delete",
    { CompanyId: scope.companyId, ReportTemplateId: templateId },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function renderTemplate(templateId: number, params: {
  fechaDesde?: string;
  fechaHasta?: string;
  fechaCorte?: string;
}) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_ReportTemplate_Render",
    {
      CompanyId: scope.companyId,
      ReportTemplateId: templateId,
      FechaDesde: params.fechaDesde || null,
      FechaHasta: params.fechaHasta || null,
      FechaCorte: params.fechaCorte || null,
    }
  );
  return rows[0] || null;
}
