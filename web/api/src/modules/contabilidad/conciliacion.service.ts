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

export interface BankStatementLineInput {
  transactionDate: string;
  description: string;
  reference?: string;
  debit: number;
  credit: number;
}

export async function importBankStatement(input: {
  bankAccountCode: string;
  statementDate: string;
  fileName: string;
  lines: BankStatementLineInput[];
}) {
  const scope = await getDefaultScope();

  const linesJson = JSON.stringify(
    (input.lines || []).map((line) => ({
      transactionDate: line.transactionDate,
      description: String(line.description || "").trim(),
      reference: line.reference || null,
      debit: Number(line.debit || 0),
      credit: Number(line.credit || 0)
    }))
  );

  const { output } = await callSpOut(
    "dbo.usp_Acct_BankStatement_Import",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      BankAccountCode: input.bankAccountCode,
      StatementDate: input.statementDate,
      FileName: input.fileName,
      LinesJson: linesJson
    },
    {
      StatementId: sql.Int,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const statementId = Number(output.StatementId ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Extracto importado" : "Error al importar extracto"),
    statementId: statementId > 0 ? statementId : null
  };
}

export async function listStatements(input: {
  bankAccountCode?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_BankStatement_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      BankAccountCode: input.bankAccountCode || null,
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

export async function getStatementLines(statementId: number) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_BankRecon_Lines",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      StatementId: statementId
    }
  );

  return { rows };
}

export async function matchLine(lineId: number, entryId: number, userId: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_BankRecon_Match",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      LineId: lineId,
      EntryId: entryId,
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
    message: mensaje || (resultado === 1 ? "Linea conciliada" : "Error al conciliar linea")
  };
}

export async function unmatchLine(lineId: number) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_BankRecon_Unmatch",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      LineId: lineId
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
    message: mensaje || (resultado === 1 ? "Conciliacion revertida" : "Error al revertir conciliacion")
  };
}

export async function autoMatch(statementId: number) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_BankRecon_AutoMatch",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      StatementId: statementId
    },
    {
      MatchedCount: sql.Int,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const matchedCount = Number(output.MatchedCount ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? `${matchedCount} lineas conciliadas automaticamente` : "Error en conciliacion automatica"),
    matchedCount
  };
}

export async function getReconSummary(statementId: number) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_BankRecon_Summary",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      StatementId: statementId
    }
  );

  return rows[0] || null;
}
