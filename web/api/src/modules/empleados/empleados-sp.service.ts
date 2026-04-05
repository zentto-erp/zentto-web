import { callSp, callSpOut, sql } from "../../db/query.js";
import { objectToXml } from "../../utils/xml.js";
import { getActiveScope } from "../_shared/scope.js";

export interface EmpleadoRow {
  CEDULA?: string;
  GRUPO?: string;
  NOMBRE?: string;
  DIRECCION?: string;
  TELEFONO?: string;
  NACIMIENTO?: Date;
  CARGO?: string;
  NOMINA?: string;
  SUELDO?: number;
  INGRESO?: Date;
  RETIRO?: Date;
  STATUS?: string;
  COMISION?: number;
  UTILIDAD?: number;
  CO_Usuario?: string;
  SEXO?: string;
  NACIONALIDAD?: string;
  Autoriza?: boolean;
  Apodo?: string;
  [key: string]: unknown;
}

export interface ListEmpleadosParams {
  search?: string;
  grupo?: string;
  status?: string;
  page?: number;
  limit?: number;
}

export interface ListEmpleadosResult {
  rows: EmpleadoRow[];
  total: number;
  page: number;
  limit: number;
}

export interface SpResult {
  success: boolean;
  message: string;
}

/**
 * Lista empleados desde dbo.Empleados via usp_Empleados_List.
 */
export async function listEmpleadosSP(params: ListEmpleadosParams = {}): Promise<ListEmpleadosResult> {
  const page = Math.max(1, Number(params.page || 1));
  const limit = Math.min(Math.max(1, Number(params.limit || 50)), 500);

  const { rows, output } = await callSpOut<EmpleadoRow>(
    "usp_Empleados_List",
    {
      Search: params.search?.trim() || null,
      Grupo: params.grupo?.trim() || null,
      Status: params.status?.trim().toUpperCase() || null,
      Page: page,
      Limit: limit,
    },
    { TotalCount: sql.Int }
  );

  return {
    rows,
    total: Number(output.TotalCount ?? 0),
    page,
    limit,
  };
}

/**
 * Obtener empleado por cédula desde dbo.Empleados.
 */
export async function getEmpleadoByCedulaSP(cedula: string): Promise<EmpleadoRow | null> {
  const rows = await callSp<EmpleadoRow>("usp_Empleados_GetByCedula", {
    Cedula: cedula.trim(),
  });
  return rows[0] ?? null;
}

/**
 * Insertar empleado en dbo.Empleados via XML.
 */
export async function insertEmpleadoSP(row: EmpleadoRow): Promise<SpResult> {
  const cedula = String(row.CEDULA ?? "").trim();
  const nombre = String(row.NOMBRE ?? "").trim();
  if (!cedula) return { success: false, message: "CEDULA requerida" };
  if (!nombre) return { success: false, message: "NOMBRE requerido" };

  const xmlData: Record<string, unknown> = {
    CEDULA: cedula,
    NOMBRE: nombre,
  };

  // Agregar campos opcionales solo si tienen valor
  if (row.GRUPO) xmlData.GRUPO = row.GRUPO;
  if (row.DIRECCION) xmlData.DIRECCION = row.DIRECCION;
  if (row.TELEFONO) xmlData.TELEFONO = row.TELEFONO;
  if (row.NACIMIENTO) xmlData.NACIMIENTO = row.NACIMIENTO instanceof Date ? row.NACIMIENTO.toISOString().split("T")[0].replace(/-/g, "") : String(row.NACIMIENTO);
  if (row.CARGO) xmlData.CARGO = row.CARGO;
  if (row.NOMINA) xmlData.NOMINA = row.NOMINA;
  if (row.SUELDO != null) xmlData.SUELDO = row.SUELDO;
  if (row.INGRESO) xmlData.INGRESO = row.INGRESO instanceof Date ? row.INGRESO.toISOString().split("T")[0].replace(/-/g, "") : String(row.INGRESO);
  if (row.RETIRO) xmlData.RETIRO = row.RETIRO instanceof Date ? row.RETIRO.toISOString().split("T")[0].replace(/-/g, "") : String(row.RETIRO);
  if (row.STATUS) xmlData.STATUS = row.STATUS;
  if (row.COMISION != null) xmlData.COMISION = row.COMISION;
  if (row.UTILIDAD != null) xmlData.UTILIDAD = row.UTILIDAD;
  if (row.CO_Usuario) xmlData.CO_Usuario = row.CO_Usuario;
  if (row.SEXO) xmlData.SEXO = row.SEXO;
  if (row.NACIONALIDAD) xmlData.NACIONALIDAD = row.NACIONALIDAD;
  if (row.Autoriza != null) xmlData.Autoriza = row.Autoriza ? 1 : 0;
  if (row.Apodo) xmlData.Apodo = row.Apodo;

  const { output } = await callSpOut(
    "usp_Empleados_Insert",
    { CompanyId: getActiveScope()?.companyId ?? 1, RowXml: objectToXml(xmlData) },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? -99);
  return {
    success: resultado > 0,
    message: String(output.Mensaje ?? (resultado > 0 ? "Empleado creado" : "Error al crear empleado")),
  };
}

/**
 * Actualizar empleado en dbo.Empleados via XML.
 */
export async function updateEmpleadoSP(cedula: string, row: Partial<EmpleadoRow>): Promise<SpResult> {
  const xmlData: Record<string, unknown> = {};

  if (row.NOMBRE != null) xmlData.NOMBRE = row.NOMBRE;
  if (row.GRUPO != null) xmlData.GRUPO = row.GRUPO;
  if (row.DIRECCION != null) xmlData.DIRECCION = row.DIRECCION;
  if (row.TELEFONO != null) xmlData.TELEFONO = row.TELEFONO;
  if (row.CARGO != null) xmlData.CARGO = row.CARGO;
  if (row.NOMINA != null) xmlData.NOMINA = row.NOMINA;
  if (row.SUELDO != null) xmlData.SUELDO = row.SUELDO;
  if (row.STATUS != null) xmlData.STATUS = row.STATUS;
  if (row.COMISION != null) xmlData.COMISION = row.COMISION;
  if (row.SEXO != null) xmlData.SEXO = row.SEXO;
  if (row.NACIONALIDAD != null) xmlData.NACIONALIDAD = row.NACIONALIDAD;
  if (row.Autoriza != null) xmlData.Autoriza = row.Autoriza ? 1 : 0;

  const { output } = await callSpOut(
    "usp_Empleados_Update",
    {
      CompanyId: getActiveScope()?.companyId ?? 1,
      Cedula: cedula.trim(),
      RowXml: objectToXml(xmlData),
    },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? -99);
  return {
    success: resultado > 0,
    message: String(output.Mensaje ?? (resultado > 0 ? "Empleado actualizado" : "Error al actualizar")),
  };
}

/**
 * Eliminar empleado de dbo.Empleados.
 */
export async function deleteEmpleadoSP(cedula: string): Promise<SpResult> {
  const { output } = await callSpOut(
    "usp_Empleados_Delete",
    { CompanyId: getActiveScope()?.companyId ?? 1, Cedula: cedula.trim() },
    { Resultado: sql.Int, Mensaje: sql.NVarChar(500) }
  );

  const resultado = Number(output.Resultado ?? -99);
  return {
    success: resultado > 0,
    message: String(output.Mensaje ?? (resultado > 0 ? "Empleado eliminado" : "Error al eliminar")),
  };
}
