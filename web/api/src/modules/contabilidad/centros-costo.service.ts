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

export async function listCentrosCosto(input: {
  search?: string;
  page?: number;
  limit?: number;
}) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));

  const { rows, output } = await callSpOut<any>(
    "dbo.usp_Acct_CostCenter_List",
    {
      CompanyId: scope.companyId,
      Search: input.search?.trim() || null,
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

export async function getCentroCosto(code: string) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_CostCenter_Get",
    {
      CompanyId: scope.companyId,
      CostCenterCode: code
    }
  );

  return rows[0] || null;
}

export async function insertCentroCosto(input: {
  code: string;
  name: string;
  parentCode?: string;
}) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_CostCenter_Insert",
    {
      CompanyId: scope.companyId,
      CostCenterCode: input.code,
      CostCenterName: input.name,
      ParentCode: input.parentCode || null
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
    message: mensaje || (resultado === 1 ? "Centro de costo creado" : "Error al crear centro de costo")
  };
}

export async function updateCentroCosto(code: string, input: {
  name?: string;
  parentCode?: string;
}) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_CostCenter_Update",
    {
      CompanyId: scope.companyId,
      CostCenterCode: code,
      CostCenterName: input.name || null,
      ParentCode: input.parentCode || null
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
    message: mensaje || (resultado === 1 ? "Centro de costo actualizado" : "Error al actualizar centro de costo")
  };
}

export async function deleteCentroCosto(code: string) {
  const scope = await getDefaultScope();

  const { output } = await callSpOut(
    "dbo.usp_Acct_CostCenter_Delete",
    {
      CompanyId: scope.companyId,
      CostCenterCode: code
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
    message: mensaje || (resultado === 1 ? "Centro de costo eliminado" : "Error al eliminar centro de costo")
  };
}

export async function pnlByCostCenter(input: {
  fechaDesde: string;
  fechaHasta: string;
}) {
  const scope = await getDefaultScope();

  const rows = await callSp<any>(
    "dbo.usp_Acct_Report_PnLByCostCenter",
    {
      CompanyId: scope.companyId,
      FechaDesde: input.fechaDesde,
      FechaHasta: input.fechaHasta
    }
  );

  return { rows };
}
