import { getPool, sql } from "../../db/mssql.js";

export interface AsientoDetalleInput {
  codCuenta: string;
  descripcion?: string;
  centroCosto?: string;
  auxiliarTipo?: string;
  auxiliarCodigo?: string;
  documento?: string;
  debe: number;
  haber: number;
}

export interface CrearAsientoInput {
  fecha: string;
  tipoAsiento: string;
  referencia?: string;
  concepto: string;
  moneda?: string;
  tasa?: number;
  origenModulo?: string;
  origenDocumento?: string;
  detalle: AsientoDetalleInput[];
}

export interface ListAsientosInput {
  fechaDesde?: string;
  fechaHasta?: string;
  tipoAsiento?: string;
  estado?: string;
  origenModulo?: string;
  origenDocumento?: string;
  page?: number;
  limit?: number;
}

function esc(value: unknown): string {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function detalleToXml(detalle: AsientoDetalleInput[]): string {
  const rows = detalle.map((d) => {
    const attrs = [
      `codCuenta="${esc(d.codCuenta)}"`,
      d.descripcion !== undefined ? `descripcion="${esc(d.descripcion)}"` : "",
      d.centroCosto !== undefined ? `centroCosto="${esc(d.centroCosto)}"` : "",
      d.auxiliarTipo !== undefined ? `auxiliarTipo="${esc(d.auxiliarTipo)}"` : "",
      d.auxiliarCodigo !== undefined ? `auxiliarCodigo="${esc(d.auxiliarCodigo)}"` : "",
      d.documento !== undefined ? `documento="${esc(d.documento)}"` : "",
      `debe="${esc(d.debe ?? 0)}"`,
      `haber="${esc(d.haber ?? 0)}"`
    ]
      .filter(Boolean)
      .join(" ");
    return `<row ${attrs} />`;
  });
  return `<rows>${rows.join("")}</rows>`;
}

export async function listAsientos(input: ListAsientosInput) {
  const pool = await getPool();
  const req = new sql.Request(pool);

  req.input("FechaDesde", sql.Date, input.fechaDesde || null);
  req.input("FechaHasta", sql.Date, input.fechaHasta || null);
  req.input("TipoAsiento", sql.NVarChar(20), input.tipoAsiento || null);
  req.input("Estado", sql.NVarChar(20), input.estado || null);
  req.input("OrigenModulo", sql.NVarChar(40), input.origenModulo || null);
  req.input("OrigenDocumento", sql.NVarChar(120), input.origenDocumento || null);
  req.input("Page", sql.Int, Math.max(1, input.page || 1));
  req.input("Limit", sql.Int, Math.min(500, Math.max(1, input.limit || 50)));
  req.output("TotalCount", sql.Int);

  const rs = await req.execute("usp_Contabilidad_Asientos_List");
  return {
    rows: rs.recordset || [],
    total: Number(rs.output.TotalCount || 0),
    page: Math.max(1, input.page || 1),
    limit: Math.min(500, Math.max(1, input.limit || 50))
  };
}

export async function getAsiento(asientoId: number) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("AsientoId", sql.BigInt, asientoId);
  const rs = await req.execute("usp_Contabilidad_Asiento_Get");
  const recordsets = rs.recordsets as unknown as Array<Array<Record<string, unknown>>>;
  return {
    cabecera: recordsets?.[0]?.[0] || null,
    detalle: recordsets?.[1] || []
  };
}

export async function crearAsiento(input: CrearAsientoInput, codUsuario?: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);

  req.input("Fecha", sql.Date, input.fecha);
  req.input("TipoAsiento", sql.NVarChar(20), input.tipoAsiento);
  req.input("Referencia", sql.NVarChar(120), input.referencia || null);
  req.input("Concepto", sql.NVarChar(400), input.concepto);
  req.input("Moneda", sql.NVarChar(10), input.moneda || "VES");
  req.input("Tasa", sql.Decimal(18, 6), input.tasa ?? 1);
  req.input("OrigenModulo", sql.NVarChar(40), input.origenModulo || null);
  req.input("OrigenDocumento", sql.NVarChar(120), input.origenDocumento || null);
  req.input("CodUsuario", sql.NVarChar(40), codUsuario || "API");
  req.input("DetalleXml", sql.NVarChar(sql.MAX), detalleToXml(input.detalle));
  req.output("AsientoId", sql.BigInt);
  req.output("NumeroAsiento", sql.NVarChar(40));
  req.output("Resultado", sql.Int);
  req.output("Mensaje", sql.NVarChar(500));

  const rs = await req.execute("usp_Contabilidad_Asiento_Crear");
  const output = rs.output as Record<string, unknown>;
  const resultado = Number(output.Resultado || 0);
  return {
    ok: resultado === 1,
    resultado,
    mensaje: String(output.Mensaje || ""),
    asientoId: output.AsientoId ? Number(output.AsientoId) : null,
    numeroAsiento: output.NumeroAsiento ? String(output.NumeroAsiento) : null
  };
}

export async function anularAsiento(asientoId: number, motivo: string, codUsuario?: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("AsientoId", sql.BigInt, asientoId);
  req.input("Motivo", sql.NVarChar(400), motivo);
  req.input("CodUsuario", sql.NVarChar(40), codUsuario || "API");
  req.output("Resultado", sql.Int);
  req.output("Mensaje", sql.NVarChar(500));
  const rs = await req.execute("usp_Contabilidad_Asiento_Anular");
  const output = rs.output as Record<string, unknown>;

  const resultado = Number(output.Resultado || 0);
  return {
    ok: resultado === 1,
    resultado,
    mensaje: String(output.Mensaje || "")
  };
}

export async function crearAjuste(
  input: {
    fecha: string;
    tipoAjuste: string;
    referencia?: string;
    motivo: string;
    detalle: AsientoDetalleInput[];
  },
  codUsuario?: string
) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("Fecha", sql.Date, input.fecha);
  req.input("TipoAjuste", sql.NVarChar(40), input.tipoAjuste);
  req.input("Referencia", sql.NVarChar(120), input.referencia || null);
  req.input("Motivo", sql.NVarChar(500), input.motivo);
  req.input("CodUsuario", sql.NVarChar(40), codUsuario || "API");
  req.input("DetalleXml", sql.NVarChar(sql.MAX), detalleToXml(input.detalle));
  req.output("AsientoId", sql.BigInt);
  req.output("Resultado", sql.Int);
  req.output("Mensaje", sql.NVarChar(500));
  const rs = await req.execute("usp_Contabilidad_Ajuste_Crear");
  const output = rs.output as Record<string, unknown>;

  const resultado = Number(output.Resultado || 0);
  return {
    ok: resultado === 1,
    resultado,
    mensaje: String(output.Mensaje || ""),
    asientoId: output.AsientoId ? Number(output.AsientoId) : null
  };
}

export async function generarDepreciacion(periodo: string, centroCosto?: string, codUsuario?: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("Periodo", sql.NVarChar(7), periodo);
  req.input("CodUsuario", sql.NVarChar(40), codUsuario || "API");
  req.input("CentroCosto", sql.NVarChar(20), centroCosto || null);
  req.output("Resultado", sql.Int);
  req.output("Mensaje", sql.NVarChar(500));
  const rs = await req.execute("usp_Contabilidad_Depreciacion_Generar");
  const output = rs.output as Record<string, unknown>;

  const resultado = Number(output.Resultado || 0);
  return {
    ok: resultado === 1,
    resultado,
    mensaje: String(output.Mensaje || "")
  };
}

export async function libroMayor(fechaDesde: string, fechaHasta: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("FechaDesde", sql.Date, fechaDesde);
  req.input("FechaHasta", sql.Date, fechaHasta);
  const rs = await req.execute("usp_Contabilidad_Libro_Mayor");
  return rs.recordset || [];
}

export async function mayorAnalitico(codCuenta: string, fechaDesde: string, fechaHasta: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("CodCuenta", sql.NVarChar(40), codCuenta);
  req.input("FechaDesde", sql.Date, fechaDesde);
  req.input("FechaHasta", sql.Date, fechaHasta);
  const rs = await req.execute("usp_Contabilidad_Mayor_Analitico");
  return rs.recordset || [];
}

export async function balanceComprobacion(fechaDesde: string, fechaHasta: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("FechaDesde", sql.Date, fechaDesde);
  req.input("FechaHasta", sql.Date, fechaHasta);
  const rs = await req.execute("usp_Contabilidad_Balance_Comprobacion");
  return rs.recordset || [];
}

export async function estadoResultados(fechaDesde: string, fechaHasta: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("FechaDesde", sql.Date, fechaDesde);
  req.input("FechaHasta", sql.Date, fechaHasta);
  const rs = await req.execute("usp_Contabilidad_Estado_Resultados");
  const recordsets = rs.recordsets as unknown as Array<Array<Record<string, unknown>>>;
  return {
    detalle: recordsets?.[0] || [],
    resumen: recordsets?.[1]?.[0] || null
  };
}

export async function balanceGeneral(fechaCorte: string) {
  const pool = await getPool();
  const req = new sql.Request(pool);
  req.input("FechaCorte", sql.Date, fechaCorte);
  const rs = await req.execute("usp_Contabilidad_Balance_General");
  const recordsets = rs.recordsets as unknown as Array<Array<Record<string, unknown>>>;
  return {
    detalle: recordsets?.[0] || [],
    resumen: recordsets?.[1]?.[0] || null
  };
}

export async function seedPlanCuentas(codUsuario?: string) {
  const pool = await getPool();
  
  // Crear plan de cuentas completo
  const cuentasSql = `
    -- PLan de cuentas básico
    IF NOT EXISTS (SELECT 1 FROM Cuentas WHERE Cod_Cuenta = '1')
    BEGIN
      -- NIVEL 1 - ACTIVO
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Activo, Accepta_Detalle)
      VALUES ('1', 'ACTIVO', 'A', 1, 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('1.1', 'ACTIVO CORRIENTE', 'A', 2, '1', 1, 0),
        ('1.2', 'ACTIVO NO CORRIENTE', 'A', 2, '1', 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('1.1.01', 'CAJA', 'A', 3, '1.1', 1, 1),
        ('1.1.02', 'BANCOS', 'A', 3, '1.1', 1, 1),
        ('1.1.03', 'INVERSIONES TEMPORALES', 'A', 3, '1.1', 1, 1),
        ('1.1.04', 'CLIENTES', 'A', 3, '1.1', 1, 1),
        ('1.1.05', 'DOCUMENTOS POR COBRAR', 'A', 3, '1.1', 1, 1),
        ('1.1.06', 'INVENTARIOS', 'A', 3, '1.1', 1, 1);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('1.2.01', 'PROPIEDAD PLANTA Y EQUIPO', 'A', 3, '1.2', 1, 1),
        ('1.2.02', 'DEPRECIACION ACUMULADA', 'A', 3, '1.2', 1, 1);
      
      -- NIVEL 1 - PASIVO
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Activo, Accepta_Detalle)
      VALUES ('2', 'PASIVO', 'P', 1, 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('2.1', 'PASIVO CORRIENTE', 'P', 2, '2', 1, 0),
        ('2.2', 'PASIVO NO CORRIENTE', 'P', 2, '2', 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('2.1.01', 'PROVEEDORES', 'P', 3, '2.1', 1, 1),
        ('2.1.02', 'DOCUMENTOS POR PAGAR', 'P', 3, '2.1', 1, 1),
        ('2.1.03', 'IMPUESTOS POR PAGAR', 'P', 3, '2.1', 1, 1),
        ('2.1.04', 'SUELDOS POR PAGAR', 'P', 3, '2.1', 1, 1);
      
      -- NIVEL 1 - PATRIMONIO
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Activo, Accepta_Detalle)
      VALUES ('3', 'PATRIMONIO', 'C', 1, 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES ('3.1', 'CAPITAL SOCIAL', 'C', 2, '3', 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES ('3.1.01', 'CAPITAL SUSCRITO', 'C', 3, '3.1', 1, 1);
      
      -- NIVEL 1 - INGRESOS
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Activo, Accepta_Detalle)
      VALUES ('4', 'INGRESOS', 'I', 1, 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES ('4.1', 'INGRESOS OPERACIONALES', 'I', 2, '4', 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('4.1.01', 'VENTAS', 'I', 3, '4.1', 1, 1),
        ('4.1.02', 'DESCUENTOS EN VENTAS', 'I', 3, '4.1', 1, 1);
      
      -- NIVEL 1 - COSTOS Y GASTOS
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Activo, Accepta_Detalle)
      VALUES ('5', 'COSTOS Y GASTOS', 'G', 1, 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('5.1', 'COSTO DE VENTAS', 'G', 2, '5', 1, 0),
        ('5.2', 'GASTOS OPERACIONALES', 'G', 2, '5', 1, 0);
      
      INSERT INTO Cuentas (Cod_Cuenta, Desc_Cta, Tipo, Nivel, Cod_CtaPadre, Activo, Accepta_Detalle)
      VALUES 
        ('5.1.01', 'COSTO DE MERCADERIA', 'G', 3, '5.1', 1, 1),
        ('5.2.01', 'SUELDOS Y SALARIOS', 'G', 3, '5.2', 1, 1),
        ('5.2.02', 'ALQUILERES', 'G', 3, '5.2', 1, 1),
        ('5.2.03', 'DEPRECIACION', 'G', 3, '5.2', 1, 1);
    END
  `;

  await pool.request().query(cuentasSql);

  // Crear asientos de ejemplo
  const asientosSql = `
    IF NOT EXISTS (SELECT 1 FROM Asientos WHERE Id > 0)
    BEGIN
      DECLARE @FechaIni DATE = GETDATE();
      
      -- ASIENTO 1: Ventas al contado
      INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
      VALUES (@FechaIni, 'DIARIO', 'Registro de ventas al contado', 'VTA-001', 'APROBADO', 1000.00, 1000.00, 'VTA', '${codUsuario || "API"}');
      
      DECLARE @Asiento1 INT = SCOPE_IDENTITY();
      INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
      VALUES 
        (@Asiento1, '1.1.02', 'BANCOS', 1000.00, 0),
        (@Asiento1, '4.1.01', 'VENTAS', 0, 1000.00);
      
      -- ASIENTO 2: Compra de mercadería
      INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
      VALUES (@FechaIni, 'COMPRA', 'Compra de mercadería', 'CMP-001', 'APROBADO', 500.00, 500.00, 'CMP', '${codUsuario || "API"}');
      
      DECLARE @Asiento2 INT = SCOPE_IDENTITY();
      INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
      VALUES 
        (@Asiento2, '1.1.06', 'INVENTARIOS', 500.00, 0),
        (@Asiento2, '2.1.01', 'PROVEEDORES', 0, 500.00);
      
      -- ASIENTO 3: Pago de sueldos
      INSERT INTO Asientos (Fecha, Tipo_Asiento, Concepto, Referencia, Estado, Total_Debe, Total_Haber, Origen_Modulo, Cod_Usuario)
      VALUES (@FechaIni, 'NOMINA', 'Pago de sueldos', 'NOM-001', 'APROBADO', 3000.00, 3000.00, 'NOM', '${codUsuario || "API"}');
      
      DECLARE @Asiento3 INT = SCOPE_IDENTITY();
      INSERT INTO Asientos_Detalle (Id_Asiento, Cod_Cuenta, Descripcion, Debe, Haber)
      VALUES 
        (@Asiento3, '5.2.01', 'SUELDOS Y SALARIOS', 3000.00, 0),
        (@Asiento3, '1.1.02', 'BANCOS', 0, 3000.00);
    END
  `;

  await pool.request().query(asientosSql);

  return { success: true, message: "Datos de contabilidad creados" };
}

