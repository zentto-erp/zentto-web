import { callSp, callSpOut, sql } from "../../db/query.js";
import { getActiveScope } from "../_shared/scope.js";
import { emitBankMovementAccountingEntry } from "./bancos-contabilidad.service.js";
import { crearAsiento, type AsientoDetalleInput } from "../contabilidad/service.js";

async function getCompanyId(): Promise<number> {
  const active = getActiveScope();
  return active?.companyId ?? 1;
}

export async function listCajaChicaBoxes() {
  const companyId = await getCompanyId();
  return callSp<any>("fin.usp_Fin_PettyCash_Box_List", { CompanyId: companyId });
}

export async function createCajaChicaBox(data: {
  name: string;
  accountCode?: string;
  maxAmount: number;
  responsible?: string;
}, codUsuario?: string) {
  const companyId = await getCompanyId();
  const active = getActiveScope();
  const branchId = active?.branchId ?? 1;

  const { output } = await callSpOut(
    "fin.usp_Fin_PettyCash_Box_Create",
    {
      CompanyId: companyId,
      BranchId: branchId,
      Name: data.name,
      AccountCode: data.accountCode || null,
      MaxAmount: Number(data.maxAmount ?? 0),
      Responsible: data.responsible || null,
      CreatedByUserId: null
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    ok: Number(output.Resultado ?? 0) > 0,
    boxId: Number(output.Resultado ?? 0),
    mensaje: String(output.Mensaje ?? "")
  };
}

export async function openSession(boxId: number, openingAmount: number, codUsuario?: string) {
  const { output } = await callSpOut(
    "fin.usp_Fin_PettyCash_Session_Open",
    {
      BoxId: boxId,
      OpeningAmount: Number(openingAmount ?? 0),
      OpenedByUserId: null
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    ok: Number(output.Resultado ?? 0) > 0,
    sessionId: Number(output.Resultado ?? 0),
    mensaje: String(output.Mensaje ?? "")
  };
}

export async function closeSession(boxId: number, notes?: string, codUsuario?: string) {
  const { output } = await callSpOut(
    "fin.usp_Fin_PettyCash_Session_Close",
    {
      BoxId: boxId,
      ClosedByUserId: null,
      Notes: notes || null
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  return {
    ok: Number(output.Resultado ?? 0) > 0,
    mensaje: String(output.Mensaje ?? "")
  };
}

export async function getActiveSession(boxId: number) {
  const rows = await callSp<any>(
    "fin.usp_Fin_PettyCash_Session_GetActive",
    { BoxId: boxId }
  );
  return rows[0] ?? null;
}

export async function addExpense(data: {
  sessionId: number;
  boxId: number;
  category: string;
  description: string;
  amount: number;
  beneficiary?: string;
  receiptNumber?: string;
  accountCode?: string;
}, codUsuario?: string) {
  const { output } = await callSpOut(
    "fin.usp_Fin_PettyCash_Expense_Add",
    {
      SessionId: data.sessionId,
      BoxId: data.boxId,
      Category: data.category,
      Description: data.description,
      Amount: Math.abs(Number(data.amount ?? 0)),
      Beneficiary: data.beneficiary || null,
      ReceiptNumber: data.receiptNumber || null,
      AccountCode: data.accountCode || null,
      CreatedByUserId: null
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const expenseId = Number(output.Resultado ?? 0);
  if (expenseId > 0) {
    // Generate accounting entry for the expense (best effort, never blocks)
    try {
      const gastoCuenta = data.accountCode || "5.1.01";
      const cajaCuenta = "1.1.01"; // Caja
      const amount = Math.abs(Number(data.amount ?? 0));

      const detalle: AsientoDetalleInput[] = [
        {
          codCuenta: gastoCuenta,
          descripcion: `Gasto caja chica: ${data.description}`,
          centroCosto: "ADM",
          documento: data.receiptNumber || `CJ-${expenseId}`,
          debe: amount,
          haber: 0
        },
        {
          codCuenta: cajaCuenta,
          descripcion: `Salida caja chica: ${data.category}`,
          centroCosto: "ADM",
          documento: data.receiptNumber || `CJ-${expenseId}`,
          debe: 0,
          haber: amount
        }
      ];

      await crearAsiento(
        {
          fecha: new Date().toISOString().slice(0, 10),
          tipoAsiento: "DIA",
          referencia: data.receiptNumber || `CJ-${expenseId}`,
          concepto: `Gasto caja chica: ${data.category} - ${data.description}`,
          moneda: "VES",
          tasa: 1,
          origenModulo: "CAJA_CHICA",
          origenDocumento: `CAJACHICA:${expenseId}`,
          detalle
        },
        codUsuario || "API"
      );
    } catch {
      // Never block the expense operation
    }
  }

  return {
    ok: expenseId > 0,
    expenseId,
    mensaje: String(output.Mensaje ?? "")
  };
}

export async function listExpenses(boxId: number, sessionId?: number) {
  return callSp<any>(
    "fin.usp_Fin_PettyCash_Expense_List",
    {
      BoxId: boxId,
      SessionId: sessionId ?? null
    }
  );
}

export async function getCajaChicaSummary(boxId: number) {
  return callSp<any>(
    "fin.usp_Fin_PettyCash_Summary",
    { BoxId: boxId }
  );
}
