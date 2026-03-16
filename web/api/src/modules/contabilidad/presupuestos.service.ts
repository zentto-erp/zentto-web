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

export interface BudgetLineInput {
  accountCode: string;
  periodCode: string;
  amount: number;
  notes?: string;
}

export async function listPresupuestos(input: {
  fiscalYear?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Budget_List",
    {
      CompanyId: scope.companyId,
      FiscalYear: input.fiscalYear || null,
      Status: input.status || null,
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

export async function getPresupuesto(id: number) {
  const scope = await getDefaultScope();

  const cabeceraRows = await callSp<any>(
    "dbo.usp_Acct_Budget_Get",
    {
      CompanyId: scope.companyId,
      BudgetId: id
    }
  );

  const lines = await callSp<any>(
    "dbo.usp_Acct_Budget_GetLines",
    {
      CompanyId: scope.companyId,
      BudgetId: id
    }
  );

  return {
    cabecera: cabeceraRows[0] || null,
    lines: lines || []
  };
}

export async function insertPresupuesto(input: {
  name: string;
  fiscalYear: number;
  costCenterCode?: string;
  lines: BudgetLineInput[];
}) {
  const scope = await getDefaultScope();

  const linesJson = JSON.stringify(
    (input.lines || []).map((line) => ({
      accountCode: String(line.accountCode || "").trim(),
      periodCode: String(line.periodCode || "").trim(),
      amount: Number(line.amount || 0),
      notes: line.notes || null
    }))
  );

  const { output } = await callSpOut(
    "dbo.usp_Acct_Budget_Insert",
    {
      CompanyId: scope.companyId,
      BudgetName: input.name,
      FiscalYear: input.fiscalYear,
      CostCenterCode: input.costCenterCode || null,
      LinesJson: linesJson
    },
    {
      BudgetId: sql.Int,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const budgetId = Number(output.BudgetId ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Presupuesto creado" : "Error al crear presupuesto"),
    budgetId: budgetId > 0 ? budgetId : null
  };
}

export async function updatePresupuesto(id: number, input: {
  name?: string;
  lines?: BudgetLineInput[];
}) {
  const scope = await getDefaultScope();

  const linesJson = input.lines
    ? JSON.stringify(
        input.lines.map((line) => ({
          accountCode: String(line.accountCode || "").trim(),
          periodCode: String(line.periodCode || "").trim(),
          amount: Number(line.amount || 0),
          notes: line.notes || null
        }))
      )
    : null;

  const { output } = await callSpOut(
    "dbo.usp_Acct_Budget_Update",
    {
      CompanyId: scope.companyId,
      BudgetId: id,
      BudgetName: input.name || null,
      LinesJson: linesJson
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Presupuesto actualizado" : "Error al actualizar presupuesto")
  };
}

export async function deletePresupuesto(id: number) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Budget_Delete",
    {
      CompanyId: scope.companyId,
      BudgetId: id
    },
    {
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Presupuesto eliminado" : "Error al eliminar presupuesto")
  };
}

export async function getVarianza(input: {
  budgetId: number;
  fechaDesde: string;
  fechaHasta: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Budget_Variance",
    {
      CompanyId: scope.companyId,
      BudgetId: input.budgetId,
      FechaDesde: input.fechaDesde,
      FechaHasta: input.fechaHasta
    }
  );

  return { rows };
}
