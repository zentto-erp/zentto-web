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
  const scope = await pool.request().query(`
    SELECT
      c.CompanyId,
      b.BranchId,
      u.UserId AS SystemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] u ON u.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
  `);

  const companyId = Number(scope.recordset?.[0]?.CompanyId ?? 0);
  const systemUserId = Number(scope.recordset?.[0]?.SystemUserId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) {
    return { success: false, message: "No existe cfg.Company DEFAULT para sembrar plan de cuentas" };
  }

  await pool
    .request()
    .input("CompanyId", sql.Int, companyId)
    .input("SystemUserId", sql.Int, Number.isFinite(systemUserId) && systemUserId > 0 ? systemUserId : null)
    .query(`
      DECLARE @Plan TABLE (
        AccountCode NVARCHAR(40) NOT NULL,
        AccountName NVARCHAR(200) NOT NULL,
        AccountType NCHAR(1) NOT NULL,
        AccountLevel INT NOT NULL,
        ParentCode NVARCHAR(40) NULL,
        AllowsPosting BIT NOT NULL
      );

      INSERT INTO @Plan (AccountCode, AccountName, AccountType, AccountLevel, ParentCode, AllowsPosting)
      VALUES
        (N'1', N'ACTIVO', N'A', 1, NULL, 0),
        (N'1.1', N'ACTIVO CORRIENTE', N'A', 2, N'1', 0),
        (N'1.2', N'ACTIVO NO CORRIENTE', N'A', 2, N'1', 0),
        (N'1.1.01', N'CAJA', N'A', 3, N'1.1', 1),
        (N'1.1.02', N'BANCOS', N'A', 3, N'1.1', 1),
        (N'1.1.03', N'INVERSIONES TEMPORALES', N'A', 3, N'1.1', 1),
        (N'1.1.04', N'CLIENTES', N'A', 3, N'1.1', 1),
        (N'1.1.05', N'DOCUMENTOS POR COBRAR', N'A', 3, N'1.1', 1),
        (N'1.1.06', N'INVENTARIOS', N'A', 3, N'1.1', 1),
        (N'1.2.01', N'PROPIEDAD PLANTA Y EQUIPO', N'A', 3, N'1.2', 1),
        (N'1.2.02', N'DEPRECIACION ACUMULADA', N'A', 3, N'1.2', 1),
        (N'2', N'PASIVO', N'P', 1, NULL, 0),
        (N'2.1', N'PASIVO CORRIENTE', N'P', 2, N'2', 0),
        (N'2.2', N'PASIVO NO CORRIENTE', N'P', 2, N'2', 0),
        (N'2.1.01', N'PROVEEDORES', N'P', 3, N'2.1', 1),
        (N'2.1.02', N'DOCUMENTOS POR PAGAR', N'P', 3, N'2.1', 1),
        (N'2.1.03', N'IMPUESTOS POR PAGAR', N'P', 3, N'2.1', 1),
        (N'2.1.04', N'SUELDOS POR PAGAR', N'P', 3, N'2.1', 1),
        (N'3', N'PATRIMONIO', N'C', 1, NULL, 0),
        (N'3.1', N'CAPITAL SOCIAL', N'C', 2, N'3', 0),
        (N'3.1.01', N'CAPITAL SUSCRITO', N'C', 3, N'3.1', 1),
        (N'4', N'INGRESOS', N'I', 1, NULL, 0),
        (N'4.1', N'INGRESOS OPERACIONALES', N'I', 2, N'4', 0),
        (N'4.1.01', N'VENTAS', N'I', 3, N'4.1', 1),
        (N'4.1.02', N'DESCUENTOS EN VENTAS', N'I', 3, N'4.1', 1),
        (N'5', N'COSTOS Y GASTOS', N'G', 1, NULL, 0),
        (N'5.1', N'COSTO DE VENTAS', N'G', 2, N'5', 0),
        (N'5.2', N'GASTOS OPERACIONALES', N'G', 2, N'5', 0),
        (N'5.1.01', N'COSTO DE MERCADERIA', N'G', 3, N'5.1', 1),
        (N'5.2.01', N'SUELDOS Y SALARIOS', N'G', 3, N'5.2', 1),
        (N'5.2.02', N'ALQUILERES', N'G', 3, N'5.2', 1),
        (N'5.2.03', N'DEPRECIACION', N'G', 3, N'5.2', 1);

      DECLARE @Inserted INT = 1;
      WHILE @Inserted > 0
      BEGIN
        INSERT INTO acct.Account (
          CompanyId,
          AccountCode,
          AccountName,
          AccountType,
          AccountLevel,
          ParentAccountId,
          AllowsPosting,
          RequiresAuxiliary,
          IsActive,
          CreatedAt,
          UpdatedAt,
          CreatedByUserId,
          UpdatedByUserId,
          IsDeleted
        )
        SELECT
          @CompanyId,
          p.AccountCode,
          p.AccountName,
          p.AccountType,
          p.AccountLevel,
          parent.AccountId,
          p.AllowsPosting,
          0,
          1,
          SYSUTCDATETIME(),
          SYSUTCDATETIME(),
          @SystemUserId,
          @SystemUserId,
          0
        FROM @Plan p
        LEFT JOIN acct.Account existing
          ON existing.CompanyId = @CompanyId
         AND existing.AccountCode = p.AccountCode
        LEFT JOIN acct.Account parent
          ON parent.CompanyId = @CompanyId
         AND parent.AccountCode = p.ParentCode
        WHERE existing.AccountId IS NULL
          AND (p.ParentCode IS NULL OR parent.AccountId IS NOT NULL);

        SET @Inserted = @@ROWCOUNT;
      END;
    `);

  const userLabel = codUsuario || "API";
  return { success: true, message: `Plan de cuentas canonico listo (${userLabel})` };
}

