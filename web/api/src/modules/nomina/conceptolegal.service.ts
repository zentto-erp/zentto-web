/**
 * Servicio de Nómina usando NominaConceptoLegal
 * Integración con la tabla existente del usuario
 */
import { getPool, sql } from "../../db/mssql.js";

// Tipos
export interface ConceptoLegal {
  id?: number;
  convencion: string;
  tipoCalculo: string;
  coConcept: string;
  nbConcepto?: string;
  formula?: string;
  sobre?: string;
  tipo?: "ASIGNACION" | "DEDUCCION" | "BONO";
  bonificable?: string;
  lotttArticulo?: string;
  ccpClausula?: string;
  orden?: number;
  activo?: boolean;
}

export interface NominaResult {
  success: boolean;
  message: string;
  nomina?: string;
  cedula?: string;
  asignaciones?: number;
  deducciones?: number;
  neto?: number;
}

// Listar conceptos legales
export async function listConceptosLegales(params: {
  convencion?: string;
  tipoCalculo?: string;
  tipo?: string;
  activo?: boolean;
}) {
  const pool = await getPool();
  
  try {
    // Intentar usar el SP primero
    const request = new sql.Request(pool);
    request.input("Convencion", sql.NVarChar(50), params.convencion || null);
    request.input("TipoCalculo", sql.NVarChar(50), params.tipoCalculo || null);
    request.input("Tipo", sql.NVarChar(15), params.tipo || null);
    request.input("Activo", sql.Bit, params.activo ?? true);

    const result = await request.execute("sp_Nomina_ConceptosLegales_List");
    return {
      rows: (result.recordset || []) as ConceptoLegal[],
    };
  } catch {
    // Fallback: consulta directa a la tabla
    let query = `
      SELECT 
        ID as id,
        Convencion as convencion,
        TipoCalculo as tipoCalculo,
        CO_CONCEPT as coConcept,
        NB_CONCEPTO as nbConcepto,
        FORMULA as formula,
        SOBRE as sobre,
        TIPO as tipo,
        BONIFICABLE as bonificable,
        LOTTT_Articulo as lotttArticulo,
        CCP_Clausula as ccpClausula,
        Orden as orden,
        Activo as activo
      FROM NominaConceptoLegal
      WHERE 1=1
    `;
    
    const conditions: string[] = [];
    if (params.activo !== false) conditions.push("Activo = 1");
    if (params.convencion) conditions.push("Convencion = @Convencion");
    if (params.tipoCalculo) conditions.push("TipoCalculo = @TipoCalculo");
    if (params.tipo) conditions.push("TIPO = @Tipo");
    
    if (conditions.length > 0) {
      query += " AND " + conditions.join(" AND ");
    }
    
    query += " ORDER BY Convencion, Orden, CO_CONCEPT";
    
    const request2 = new sql.Request(pool);
    request2.input("Convencion", sql.NVarChar(50), params.convencion || null);
    request2.input("TipoCalculo", sql.NVarChar(50), params.tipoCalculo || null);
    request2.input("Tipo", sql.NVarChar(15), params.tipo || null);
    
    const result = await request2.query(query);
    return {
      rows: (result.recordset || []) as ConceptoLegal[],
    };
  }
}

// Procesar nómina usando ConceptoLegal
export async function procesarNominaConceptoLegal(payload: {
  nomina: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  convencion?: string; // LOT, CCT_PETROLERO, etc.
  tipoCalculo?: string; // MENSUAL, SEMANAL, VACACIONES, LIQUIDACION
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.nomina);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaInicio", sql.Date, payload.fechaInicio);
  request.input("FechaHasta", sql.Date, payload.fechaHasta);
  request.input("Convencion", sql.NVarChar(50), payload.convencion || null);
  request.input("TipoCalculo", sql.NVarChar(50), payload.tipoCalculo || "MENSUAL");
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarEmpleadoConceptoLegal");

  const mensaje = (request.parameters.Mensaje?.value as string) || "";
  const exito = (request.parameters.Resultado?.value as number) === 1;

  // Parsear valores del mensaje
  const asignacionesMatch = mensaje.match(/Asignaciones:\s*([\d.,]+)/);
  const deduccionesMatch = mensaje.match(/Deducciones:\s*([\d.,]+)/);

  return {
    success: exito,
    message: mensaje,
    nomina: payload.nomina,
    cedula: payload.cedula,
    asignaciones: asignacionesMatch ? parseFloat(asignacionesMatch[1].replace(/,/g, "")) : undefined,
    deducciones: deduccionesMatch ? parseFloat(deduccionesMatch[1].replace(/,/g, "")) : undefined,
  };
}

// Validar fórmulas de conceptos
export async function validarFormulasConceptos(params: {
  convencion?: string;
  tipoCalculo?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Convencion", sql.NVarChar(50), params.convencion || null);
  request.input("TipoCalculo", sql.NVarChar(50), params.tipoCalculo || null);

  const result = await request.execute("sp_Nomina_ValidarFormulasConceptoLegal");
  const recordsets = result.recordsets as unknown as Array<Array<Record<string, unknown>>>;

  return {
    resumen: recordsets[0]?.[0] || null,
    errores: recordsets[1] || [],
  };
}

// Procesar vacaciones usando ConceptoLegal
export async function procesarVacacionesConceptoLegal(payload: {
  vacacionId: string;
  cedula: string;
  fechaInicio: string;
  fechaHasta: string;
  fechaReintegro?: string;
  convencion?: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.vacacionId);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaInicio", sql.Date, payload.fechaInicio);
  request.input("FechaHasta", sql.Date, payload.fechaHasta);
  request.input("Convencion", sql.NVarChar(50), payload.convencion || null);
  request.input("TipoCalculo", sql.NVarChar(50), "VACACIONES");
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarEmpleadoConceptoLegal");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Procesar liquidación usando ConceptoLegal
export async function procesarLiquidacionConceptoLegal(payload: {
  liquidacionId: string;
  cedula: string;
  fechaRetiro: string;
  causaRetiro?: string;
  convencion?: string;
  codUsuario?: string;
}) {
  const pool = await getPool();
  const request = new sql.Request(pool);

  request.input("Nomina", sql.NVarChar(10), payload.liquidacionId);
  request.input("Cedula", sql.NVarChar(12), payload.cedula);
  request.input("FechaInicio", sql.Date, payload.fechaRetiro); // Usamos fecha retiro como inicio
  request.input("FechaHasta", sql.Date, payload.fechaRetiro);
  request.input("Convencion", sql.NVarChar(50), payload.convencion || null);
  request.input("TipoCalculo", sql.NVarChar(50), "LIQUIDACION");
  request.input("CoUsuario", sql.NVarChar(20), payload.codUsuario || "API");
  request.output("Resultado", sql.Int);
  request.output("Mensaje", sql.NVarChar(500));

  await request.execute("sp_Nomina_ProcesarEmpleadoConceptoLegal");

  return {
    success: (request.parameters.Resultado?.value as number) === 1,
    message: (request.parameters.Mensaje?.value as string) || "OK",
  };
}

// Obtener resumen de convenciones disponibles
export async function getConvencionesDisponibles() {
  const pool = await getPool();
  const result = await pool.request().query(`
    SELECT 
      Convencion,
      COUNT(*) as TotalConceptos,
      COUNT(CASE WHEN TipoCalculo = 'MENSUAL' THEN 1 END) as ConceptosMensual,
      COUNT(CASE WHEN TipoCalculo = 'VACACIONES' THEN 1 END) as ConceptosVacaciones,
      COUNT(CASE WHEN TipoCalculo = 'LIQUIDACION' THEN 1 END) as ConceptosLiquidacion,
      MIN(Orden) as OrdenInicio,
      MAX(Orden) as OrdenFin
    FROM NominaConceptoLegal
    WHERE Activo = 1
    GROUP BY Convencion
    ORDER BY Convencion
  `);

  return result.recordset;
}
