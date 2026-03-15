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

export async function listPeriodos(input: {
  year?: number;
  status?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_Period_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Year: input.year || null,
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

export async function ensureYear(year: number) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Period_EnsureYear",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      Year: year
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
    message: mensaje || (resultado === 1 ? "Periodos creados" : "Error al crear periodos")
  };
}

export async function closePeriod(periodoCode: string, userId: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Period_Close",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: periodoCode,
      UserId: userId
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
    message: mensaje || (resultado === 1 ? "Periodo cerrado" : "No se pudo cerrar el periodo")
  };
}

export async function reopenPeriod(periodoCode: string, userId: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Period_Reopen",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: periodoCode,
      UserId: userId
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
    message: mensaje || (resultado === 1 ? "Periodo reabierto" : "No se pudo reabrir el periodo")
  };
}

export async function generateClosingEntries(periodoCode: string, userId: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_Period_GenerateClosingEntries",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: periodoCode,
      UserId: userId
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
    message: mensaje || (resultado === 1 ? "Asientos de cierre generados" : "Error al generar asientos de cierre")
  };
}

export async function getChecklist(periodoCode: string) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Period_Checklist",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      PeriodCode: periodoCode
    }
  );

  return { items: rows };
}
