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

export interface RecurringLineInput {
  accountCode: string;
  description?: string;
  costCenterCode?: string;
  debit: number;
  credit: number;
}

export async function listRecurrentes(input: {
  isActive?: boolean;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_RecurringEntry_List",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      IsActive: input.isActive ?? null,
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

export async function getRecurrente(id: number) {
  const scope = await getDefaultScope();

  const cabeceraRows = await callSp<any>(
    "dbo.usp_Acct_RecurringEntry_Get",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      RecurringEntryId: id
    }
  );

  const lines = await callSp<any>(
    "dbo.usp_Acct_RecurringEntry_GetLines",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      RecurringEntryId: id
    }
  );

  return {
    cabecera: cabeceraRows[0] || null,
    lines: lines || []
  };
}

export async function insertRecurrente(input: {
  templateName: string;
  frequency: string;
  nextExecutionDate: string;
  tipoAsiento: string;
  concepto: string;
  lines: RecurringLineInput[];
}) {
  const scope = await getDefaultScope();

  const linesJson = JSON.stringify(
    (input.lines || []).map((line) => ({
      accountCode: String(line.accountCode || "").trim(),
      description: line.description || null,
      costCenterCode: line.costCenterCode || null,
      debit: Number(line.debit || 0),
      credit: Number(line.credit || 0)
    }))
  );

  const { output } = await callSpOut(
    "dbo.usp_Acct_RecurringEntry_Insert",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      TemplateName: input.templateName,
      Frequency: input.frequency,
      NextExecutionDate: input.nextExecutionDate,
      EntryType: input.tipoAsiento,
      Concept: input.concepto,
      LinesJson: linesJson
    },
    {
      RecurringEntryId: sql.Int,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const recurringEntryId = Number(output.RecurringEntryId ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Asiento recurrente creado" : "Error al crear asiento recurrente"),
    recurringEntryId: recurringEntryId > 0 ? recurringEntryId : null
  };
}

export async function updateRecurrente(id: number, data: {
  templateName?: string;
  frequency?: string;
  nextExecutionDate?: string;
  tipoAsiento?: string;
  concepto?: string;
  isActive?: boolean;
  lines?: RecurringLineInput[];
}) {
  const scope = await getDefaultScope();

  const linesJson = data.lines
    ? JSON.stringify(
        data.lines.map((line) => ({
          accountCode: String(line.accountCode || "").trim(),
          description: line.description || null,
          costCenterCode: line.costCenterCode || null,
          debit: Number(line.debit || 0),
          credit: Number(line.credit || 0)
        }))
      )
    : null;

  const { output } = await callSpOut(
    "dbo.usp_Acct_RecurringEntry_Update",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      RecurringEntryId: id,
      TemplateName: data.templateName || null,
      Frequency: data.frequency || null,
      NextExecutionDate: data.nextExecutionDate || null,
      EntryType: data.tipoAsiento || null,
      Concept: data.concepto || null,
      IsActive: data.isActive ?? null,
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
    message: mensaje || (resultado === 1 ? "Asiento recurrente actualizado" : "Error al actualizar asiento recurrente")
  };
}

export async function deleteRecurrente(id: number) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_RecurringEntry_Delete",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      RecurringEntryId: id
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
    message: mensaje || (resultado === 1 ? "Asiento recurrente eliminado" : "Error al eliminar asiento recurrente")
  };
}

export async function executeRecurrente(id: number, executionDate: string, userId: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_RecurringEntry_Execute",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId,
      RecurringEntryId: id,
      ExecutionDate: executionDate,
      UserId: userId
    },
    {
      AsientoId: sql.BigInt,
      Resultado: sql.Int,
      Mensaje: sql.NVarChar(500)
    }
  );

  const resultado = Number(output.Resultado ?? 0);
  const asientoId = Number(output.AsientoId ?? 0);
  const mensaje = String(output.Mensaje ?? "");

  return {
    success: resultado === 1,
    message: mensaje || (resultado === 1 ? "Asiento recurrente ejecutado" : "Error al ejecutar asiento recurrente"),
    asientoId: asientoId > 0 ? asientoId : null
  };
}

export async function getDueRecurrentes() {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_RecurringEntry_GetDue",
    {
      CompanyId: scope.companyId,
      BranchId: scope.branchId
    }
  );

  return { rows };
}
