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

export async function listEquityMovements(input: { fiscalYear: number }) {
  const scope = await getDefaultScope();
  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_EquityMovement_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FiscalYear: input.fiscalYear,
    },
    { TotalCount: sql.Int }
  );
  return { rows, total: Number(output.TotalCount ?? 0) };
}

export async function insertEquityMovement(input: {
  fiscalYear: number;
  accountCode: string;
  movementType: string;
  movementDate: string;
  amount: number;
  journalEntryId?: number;
  description?: string;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_EquityMovement_Insert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FiscalYear: input.fiscalYear,
      AccountCode: input.accountCode,
      MovementType: input.movementType,
      MovementDate: input.movementDate,
      Amount: input.amount,
      JournalEntryId: input.journalEntryId || null,
      Description: input.description || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function updateEquityMovement(id: number, input: {
  movementType?: string;
  movementDate?: string;
  amount?: number;
  description?: string;
}) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_EquityMovement_Update",
    {
      CompanyId: scope.companyId,
      EquityMovementId: id,
      MovementType: input.movementType || null,
      MovementDate: input.movementDate || null,
      Amount: input.amount ?? null,
      Description: input.description || null,
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function deleteEquityMovement(id: number) {
  const scope = await getDefaultScope();
  const { output } = await callSpOut(
    "dbo.usp_Acct_EquityMovement_Delete",
    { CompanyId: scope.companyId, EquityMovementId: id },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );
  if (Number(output.Resultado) !== 1) throw new Error(String(output.Mensaje));
  return { success: true, message: String(output.Mensaje) };
}

export async function getEquityChangesReport(input: { fiscalYear: number }) {
  const scope = await getDefaultScope();
  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_EquityChanges",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      FiscalYear: input.fiscalYear,
    }
  );
  return { rows };
}
