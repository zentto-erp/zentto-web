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

export async function cashFlowStatement(input: {
  fechaDesde: string;
  fechaHasta: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_CashFlow",
    {
      CompanyId: scope.companyId,
      FechaDesde: input.fechaDesde,
      FechaHasta: input.fechaHasta
    }
  );

  return { rows };
}

export async function balanceCompMultiPeriod(input: {
  periodos: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_BalanceCompMultiPeriod",
    {
      CompanyId: scope.companyId,
      PeriodosJson: input.periodos
    }
  );

  return { rows };
}

export async function pnlMultiPeriod(input: {
  periodos: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_PnLMultiPeriod",
    {
      CompanyId: scope.companyId,
      PeriodosJson: input.periodos
    }
  );

  return { rows };
}

export async function agingCxC(input: {
  fechaCorte: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_AgingCxC",
    {
      CompanyId: scope.companyId,
      FechaCorte: input.fechaCorte
    }
  );

  return { rows };
}

export async function agingCxP(input: {
  fechaCorte: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_AgingCxP",
    {
      CompanyId: scope.companyId,
      FechaCorte: input.fechaCorte
    }
  );

  return { rows };
}

export async function financialRatios(input: {
  fechaCorte: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_FinancialRatios",
    {
      CompanyId: scope.companyId,
      FechaCorte: input.fechaCorte
    }
  );

  return rows[0] || null;
}

export async function taxSummary(input: {
  fechaDesde: string;
  fechaHasta: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_TaxSummary",
    {
      CompanyId: scope.companyId,
      FechaDesde: input.fechaDesde,
      FechaHasta: input.fechaHasta
    }
  );

  return { rows };
}

export async function drillDown(input: {
  accountCode: string;
  fechaDesde: string;
  fechaHasta: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Report_DrillDown",
    {
      CompanyId: scope.companyId,
      AccountCode: input.accountCode,
      FechaDesde: input.fechaDesde,
      FechaHasta: input.fechaHasta,
      Page: page,
      Limit: limit
    },
    {
      TotalCount: sql.Int
    }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit
  };
}
