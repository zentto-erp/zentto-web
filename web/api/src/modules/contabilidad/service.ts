import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

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

async function getDefaultScope() {
  const rows = await query<{ CompanyId: number; BranchId: number }>(
    `SELECT TOP 1 c.CompanyId, b.BranchId
       FROM cfg.Company c
       INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId
      WHERE c.IsDeleted = 0
        AND b.IsDeleted = 0
      ORDER BY CASE WHEN c.CompanyCode = 'DEFAULT' THEN 0 ELSE 1 END, c.CompanyId,
               CASE WHEN b.BranchCode = 'MAIN' THEN 0 ELSE 1 END, b.BranchId`
  );

  const companyId = Number(rows[0]?.CompanyId ?? 0);
  const branchId = Number(rows[0]?.BranchId ?? 0);
  if (!Number.isFinite(companyId) || companyId <= 0) throw new Error("company_not_found");
  if (!Number.isFinite(branchId) || branchId <= 0) throw new Error("branch_not_found");
  return { companyId, branchId };
}

function toPeriodCode(fecha: Date) {
  const yyyy = fecha.getUTCFullYear();
  const mm = String(fecha.getUTCMonth() + 1).padStart(2, "0");
  return `${yyyy}${mm}`;
}

function generateEntryNumber(tipoAsiento: string) {
  const stamp = new Date().toISOString().replace(/\D/g, "").slice(0, 14);
  const pref = String(tipoAsiento || "ASI").trim().toUpperCase().slice(0, 6) || "ASI";
  return `${pref}-${stamp}`;
}

function normalizeAsientoEstado(estado?: string | null) {
  const value = String(estado ?? "").trim().toUpperCase();
  if (!value) return null;
  if (["ACTIVO", "A", "POSTED", "APROBADO", "APPROVED"].includes(value)) return "APPROVED";
  if (["ANULADO", "VOID", "VOIDED"].includes(value)) return "VOIDED";
  if (["BORRADOR", "DRAFT"].includes(value)) return "DRAFT";
  return value;
}

function round2(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export async function listAsientos(input: ListAsientosInput) {
  const scope = await getDefaultScope();
  const page = Math.max(1, Number(input.page || 1));
  const limit = Math.min(500, Math.max(1, Number(input.limit || 50)));
  const offset = (page - 1) * limit;

  const estado = normalizeAsientoEstado(input.estado);

  const params: Record<string, unknown> = {
    companyId: scope.companyId,
    branchId: scope.branchId,
    fechaDesde: input.fechaDesde || null,
    fechaHasta: input.fechaHasta || null,
    tipoAsiento: input.tipoAsiento || null,
    estado,
    origenModulo: input.origenModulo || null,
    origenDocumento: input.origenDocumento || null,
  };

  const where = `
    WHERE je.CompanyId = @companyId
      AND je.BranchId = @branchId
      AND je.IsDeleted = 0
      AND (@fechaDesde IS NULL OR je.EntryDate >= @fechaDesde)
      AND (@fechaHasta IS NULL OR je.EntryDate <= @fechaHasta)
      AND (@tipoAsiento IS NULL OR je.EntryType = @tipoAsiento)
      AND (@estado IS NULL OR je.Status = @estado)
      AND (@origenModulo IS NULL OR je.SourceModule = @origenModulo)
      AND (@origenDocumento IS NULL OR je.SourceDocumentNo = @origenDocumento)
  `;

  const totalRows = await query<{ total: number }>(
    `SELECT COUNT(1) AS total
       FROM acct.JournalEntry je
      ${where}`,
    params
  );

  const rows = await query<any>(
    `SELECT
        je.JournalEntryId AS asientoId,
        je.EntryNumber AS numeroAsiento,
        je.EntryDate AS fecha,
        je.EntryType AS tipoAsiento,
        je.ReferenceNumber AS referencia,
        je.Concept AS concepto,
        je.CurrencyCode AS moneda,
        je.ExchangeRate AS tasa,
        je.TotalDebit AS totalDebe,
        je.TotalCredit AS totalHaber,
        je.Status AS estado,
        je.SourceModule AS origenModulo,
        je.SourceDocumentNo AS origenDocumento,
        je.CreatedAt
       FROM acct.JournalEntry je
      ${where}
      ORDER BY je.EntryDate DESC, je.JournalEntryId DESC
      OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY`,
    params
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit
  };
}

export async function getAsiento(asientoId: number) {
  const scope = await getDefaultScope();

  const cabeceraRows = await query<any>(
    `SELECT TOP 1
        je.JournalEntryId AS asientoId,
        je.EntryNumber AS numeroAsiento,
        je.EntryDate AS fecha,
        je.EntryType AS tipoAsiento,
        je.ReferenceNumber AS referencia,
        je.Concept AS concepto,
        je.CurrencyCode AS moneda,
        je.ExchangeRate AS tasa,
        je.TotalDebit AS totalDebe,
        je.TotalCredit AS totalHaber,
        je.Status AS estado,
        je.SourceModule AS origenModulo,
        je.SourceDocumentNo AS origenDocumento,
        je.CreatedAt
       FROM acct.JournalEntry je
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.JournalEntryId = @asientoId
        AND je.IsDeleted = 0`,
    { companyId: scope.companyId, branchId: scope.branchId, asientoId }
  );

  const detalle = await query<any>(
    `SELECT
        l.JournalEntryLineId AS detalleId,
        l.LineNumber AS renglon,
        l.AccountCodeSnapshot AS codCuenta,
        a.AccountName AS nombreCuenta,
        l.Description AS descripcion,
        l.CostCenterCode AS centroCosto,
        l.AuxiliaryType AS auxiliarTipo,
        l.AuxiliaryCode AS auxiliarCodigo,
        l.SourceDocumentNo AS documento,
        l.DebitAmount AS debe,
        l.CreditAmount AS haber
       FROM acct.JournalEntryLine l
       INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
       LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.JournalEntryId = @asientoId
      ORDER BY l.LineNumber, l.JournalEntryLineId`,
    { companyId: scope.companyId, branchId: scope.branchId, asientoId }
  );

  return {
    cabecera: cabeceraRows[0] || null,
    detalle: detalle || []
  };
}

export async function crearAsiento(input: CrearAsientoInput, _codUsuario?: string) {
  const scope = await getDefaultScope();
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const fecha = input.fecha ? new Date(input.fecha) : new Date();
    const entryNumber = generateEntryNumber(input.tipoAsiento);
    const periodCode = toPeriodCode(fecha);

    const detalle = Array.isArray(input.detalle) ? input.detalle : [];
    if (detalle.length === 0) {
      await tx.rollback();
      return { ok: false, resultado: 0, mensaje: "Detalle de asiento requerido", asientoId: null, numeroAsiento: null };
    }

    const totalDebe = round2(detalle.reduce((acc, item) => acc + Number(item.debe || 0), 0));
    const totalHaber = round2(detalle.reduce((acc, item) => acc + Number(item.haber || 0), 0));
    if (totalDebe <= 0 || totalHaber <= 0 || round2(totalDebe - totalHaber) !== 0) {
      await tx.rollback();
      return { ok: false, resultado: 0, mensaje: "Asiento desbalanceado", asientoId: null, numeroAsiento: null };
    }

    const codes = [...new Set(detalle.map((d) => String(d.codCuenta || "").trim()).filter(Boolean))];
    if (!codes.length) {
      await tx.rollback();
      return { ok: false, resultado: 0, mensaje: "Cuentas contables requeridas", asientoId: null, numeroAsiento: null };
    }

    const reqAccounts = new sql.Request(tx);
    reqAccounts.input("companyId", sql.Int, scope.companyId);
    const placeholders: string[] = [];
    codes.forEach((code, i) => {
      const p = `code${i}`;
      placeholders.push(`@${p}`);
      reqAccounts.input(p, sql.NVarChar(40), code);
    });

    const accRs = await reqAccounts.query(`
      SELECT AccountId, AccountCode
      FROM acct.Account
      WHERE CompanyId = @companyId
        AND IsDeleted = 0
        AND AccountCode IN (${placeholders.join(",")})
    `);

    const accountMap = new Map<string, number>();
    for (const row of accRs.recordset ?? []) {
      accountMap.set(String(row.AccountCode).trim(), Number(row.AccountId));
    }

    const missing = codes.filter((c) => !accountMap.has(c));
    if (missing.length > 0) {
      await tx.rollback();
      return {
        ok: false,
        resultado: 0,
        mensaje: `Cuentas no encontradas: ${missing.join(", ")}`,
        asientoId: null,
        numeroAsiento: null
      };
    }

    const insertHead = new sql.Request(tx);
    insertHead.input("companyId", sql.Int, scope.companyId);
    insertHead.input("branchId", sql.Int, scope.branchId);
    insertHead.input("entryNumber", sql.NVarChar(40), entryNumber);
    insertHead.input("entryDate", sql.Date, fecha);
    insertHead.input("periodCode", sql.NVarChar(10), periodCode);
    insertHead.input("entryType", sql.NVarChar(20), input.tipoAsiento || "DIA");
    insertHead.input("referenceNumber", sql.NVarChar(120), input.referencia || null);
    insertHead.input("concept", sql.NVarChar(400), input.concepto || "Asiento");
    insertHead.input("currencyCode", sql.Char(3), (input.moneda || "VES").toUpperCase().slice(0, 3));
    insertHead.input("exchangeRate", sql.Decimal(18, 6), Number(input.tasa ?? 1));
    insertHead.input("totalDebit", sql.Decimal(18, 2), totalDebe);
    insertHead.input("totalCredit", sql.Decimal(18, 2), totalHaber);
    insertHead.input("status", sql.NVarChar(20), "APPROVED");
    insertHead.input("sourceModule", sql.NVarChar(40), input.origenModulo || null);
    insertHead.input("sourceDocumentType", sql.NVarChar(40), input.origenModulo || null);
    insertHead.input("sourceDocumentNo", sql.NVarChar(120), input.origenDocumento || null);

    const headRs = await insertHead.query(`
      INSERT INTO acct.JournalEntry (
        CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType,
        ReferenceNumber, Concept, CurrencyCode, ExchangeRate,
        TotalDebit, TotalCredit, Status,
        SourceModule, SourceDocumentType, SourceDocumentNo,
        CreatedAt, UpdatedAt, IsDeleted
      )
      VALUES (
        @companyId, @branchId, @entryNumber, @entryDate, @periodCode, @entryType,
        @referenceNumber, @concept, @currencyCode, @exchangeRate,
        @totalDebit, @totalCredit, @status,
        @sourceModule, @sourceDocumentType, @sourceDocumentNo,
        SYSUTCDATETIME(), SYSUTCDATETIME(), 0
      );
      SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS journalEntryId;
    `);

    const journalEntryId = Number(headRs.recordset?.[0]?.journalEntryId ?? 0);
    if (!Number.isFinite(journalEntryId) || journalEntryId <= 0) {
      await tx.rollback();
      return { ok: false, resultado: 0, mensaje: "No se pudo crear asiento", asientoId: null, numeroAsiento: null };
    }

    for (let i = 0; i < detalle.length; i++) {
      const item = detalle[i];
      const code = String(item.codCuenta || "").trim();
      const accountId = Number(accountMap.get(code));

      const reqLine = new sql.Request(tx);
      reqLine.input("journalEntryId", sql.BigInt, journalEntryId);
      reqLine.input("lineNumber", sql.Int, i + 1);
      reqLine.input("accountId", sql.BigInt, accountId);
      reqLine.input("accountCodeSnapshot", sql.NVarChar(40), code);
      reqLine.input("description", sql.NVarChar(300), item.descripcion || null);
      reqLine.input("debitAmount", sql.Decimal(18, 2), Number(item.debe || 0));
      reqLine.input("creditAmount", sql.Decimal(18, 2), Number(item.haber || 0));
      reqLine.input("auxiliaryType", sql.NVarChar(30), item.auxiliarTipo || null);
      reqLine.input("auxiliaryCode", sql.NVarChar(60), item.auxiliarCodigo || null);
      reqLine.input("costCenterCode", sql.NVarChar(20), item.centroCosto || null);
      reqLine.input("sourceDocumentNo", sql.NVarChar(120), item.documento || input.origenDocumento || null);

      await reqLine.query(`
        INSERT INTO acct.JournalEntryLine (
          JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot,
          Description, DebitAmount, CreditAmount,
          AuxiliaryType, AuxiliaryCode, CostCenterCode, SourceDocumentNo,
          CreatedAt, UpdatedAt
        )
        VALUES (
          @journalEntryId, @lineNumber, @accountId, @accountCodeSnapshot,
          @description, @debitAmount, @creditAmount,
          @auxiliaryType, @auxiliaryCode, @costCenterCode, @sourceDocumentNo,
          SYSUTCDATETIME(), SYSUTCDATETIME()
        )
      `);
    }

    await tx.commit();

    return {
      ok: true,
      resultado: 1,
      mensaje: "Asiento creado en modelo canonico",
      asientoId: journalEntryId,
      numeroAsiento: entryNumber
    };
  } catch (error: any) {
    try { await tx.rollback(); } catch {}
    return {
      ok: false,
      resultado: 0,
      mensaje: `Error creando asiento canonico: ${String(error?.message ?? error)}`,
      asientoId: null,
      numeroAsiento: null
    };
  }
}

export async function anularAsiento(asientoId: number, motivo: string, _codUsuario?: string) {
  const scope = await getDefaultScope();
  const rs = await query<any>(
    `UPDATE acct.JournalEntry
        SET Status = 'VOIDED',
            Concept = CONCAT(ISNULL(Concept, ''), CASE WHEN ISNULL(Concept,'') = '' THEN '' ELSE ' | ' END, 'ANULADO: ', @motivo),
            UpdatedAt = SYSUTCDATETIME()
      WHERE CompanyId = @companyId
        AND BranchId = @branchId
        AND JournalEntryId = @asientoId
        AND IsDeleted = 0;
     SELECT @@ROWCOUNT AS affected;`,
    { companyId: scope.companyId, branchId: scope.branchId, asientoId, motivo: motivo || "sin_motivo" }
  );

  const affected = Number(rs[0]?.affected ?? 0);
  return {
    ok: affected > 0,
    resultado: affected > 0 ? 1 : 0,
    mensaje: affected > 0 ? "Asiento anulado" : "Asiento no encontrado"
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
  return crearAsiento(
    {
      fecha: input.fecha,
      tipoAsiento: input.tipoAjuste || "AJUSTE",
      referencia: input.referencia,
      concepto: input.motivo,
      moneda: "VES",
      tasa: 1,
      origenModulo: "CONTABILIDAD",
      origenDocumento: input.referencia || undefined,
      detalle: input.detalle,
    },
    codUsuario
  );
}

export async function generarDepreciacion(periodo: string, _centroCosto?: string, _codUsuario?: string) {
  return {
    ok: true,
    resultado: 1,
    mensaje: `Depreciacion automatica no implementada en modelo canonico (${periodo})`
  };
}

export async function libroMayor(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return query<any>(
    `SELECT
        je.EntryDate AS fecha,
        je.EntryNumber AS numeroAsiento,
        l.AccountCodeSnapshot AS codCuenta,
        a.AccountName AS cuenta,
        l.Description AS descripcion,
        l.DebitAmount AS debe,
        l.CreditAmount AS haber,
        SUM(l.DebitAmount - l.CreditAmount) OVER (
          PARTITION BY l.AccountCodeSnapshot
          ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS saldo
       FROM acct.JournalEntryLine l
       INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
       LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.IsDeleted = 0
        AND je.Status <> 'VOIDED'
        AND je.EntryDate >= @fechaDesde
        AND je.EntryDate <= @fechaHasta
      ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber`,
    { companyId: scope.companyId, branchId: scope.branchId, fechaDesde, fechaHasta }
  );
}

export async function mayorAnalitico(codCuenta: string, fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return query<any>(
    `SELECT
        je.EntryDate AS fecha,
        je.EntryNumber AS numeroAsiento,
        l.LineNumber AS renglon,
        l.Description AS descripcion,
        l.DebitAmount AS debe,
        l.CreditAmount AS haber,
        SUM(l.DebitAmount - l.CreditAmount) OVER (
          ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS saldo
      FROM acct.JournalEntryLine l
      INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.IsDeleted = 0
        AND je.Status <> 'VOIDED'
        AND l.AccountCodeSnapshot = @codCuenta
        AND je.EntryDate >= @fechaDesde
        AND je.EntryDate <= @fechaHasta
      ORDER BY je.EntryDate, je.JournalEntryId, l.LineNumber`,
    { companyId: scope.companyId, branchId: scope.branchId, codCuenta, fechaDesde, fechaHasta }
  );
}

export async function balanceComprobacion(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  return query<any>(
    `SELECT
        l.AccountCodeSnapshot AS codCuenta,
        MAX(a.AccountName) AS cuenta,
        SUM(l.DebitAmount) AS totalDebe,
        SUM(l.CreditAmount) AS totalHaber,
        SUM(l.DebitAmount - l.CreditAmount) AS saldo
      FROM acct.JournalEntryLine l
      INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
      LEFT JOIN acct.Account a ON a.AccountId = l.AccountId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.IsDeleted = 0
        AND je.Status <> 'VOIDED'
        AND je.EntryDate >= @fechaDesde
        AND je.EntryDate <= @fechaHasta
      GROUP BY l.AccountCodeSnapshot
      ORDER BY l.AccountCodeSnapshot`,
    { companyId: scope.companyId, branchId: scope.branchId, fechaDesde, fechaHasta }
  );
}

export async function estadoResultados(fechaDesde: string, fechaHasta: string) {
  const scope = await getDefaultScope();
  const detalle = await query<any>(
    `SELECT
        l.AccountCodeSnapshot AS codCuenta,
        MAX(a.AccountName) AS cuenta,
        MAX(a.AccountType) AS tipo,
        SUM(l.DebitAmount) AS totalDebe,
        SUM(l.CreditAmount) AS totalHaber,
        CASE
          WHEN MAX(a.AccountType) = 'I' THEN SUM(l.CreditAmount - l.DebitAmount)
          WHEN MAX(a.AccountType) = 'G' THEN SUM(l.DebitAmount - l.CreditAmount)
          ELSE 0
        END AS monto
      FROM acct.JournalEntryLine l
      INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
      INNER JOIN acct.Account a ON a.AccountId = l.AccountId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.IsDeleted = 0
        AND je.Status <> 'VOIDED'
        AND a.AccountType IN ('I', 'G')
        AND je.EntryDate >= @fechaDesde
        AND je.EntryDate <= @fechaHasta
      GROUP BY l.AccountCodeSnapshot
      ORDER BY l.AccountCodeSnapshot`,
    { companyId: scope.companyId, branchId: scope.branchId, fechaDesde, fechaHasta }
  );

  const ingresos = round2(detalle.filter((r) => r.tipo === "I").reduce((acc, r) => acc + Number(r.monto ?? 0), 0));
  const gastos = round2(detalle.filter((r) => r.tipo === "G").reduce((acc, r) => acc + Number(r.monto ?? 0), 0));
  const resultado = round2(ingresos - gastos);

  return {
    detalle,
    resumen: {
      ingresos,
      gastos,
      resultado
    }
  };
}

export async function balanceGeneral(fechaCorte: string) {
  const scope = await getDefaultScope();
  const detalle = await query<any>(
    `SELECT
        l.AccountCodeSnapshot AS codCuenta,
        MAX(a.AccountName) AS cuenta,
        MAX(a.AccountType) AS tipo,
        SUM(l.DebitAmount) AS totalDebe,
        SUM(l.CreditAmount) AS totalHaber,
        CASE
          WHEN MAX(a.AccountType) = 'A' THEN SUM(l.DebitAmount - l.CreditAmount)
          WHEN MAX(a.AccountType) IN ('P','C') THEN SUM(l.CreditAmount - l.DebitAmount)
          ELSE 0
        END AS saldo
      FROM acct.JournalEntryLine l
      INNER JOIN acct.JournalEntry je ON je.JournalEntryId = l.JournalEntryId
      INNER JOIN acct.Account a ON a.AccountId = l.AccountId
      WHERE je.CompanyId = @companyId
        AND je.BranchId = @branchId
        AND je.IsDeleted = 0
        AND je.Status <> 'VOIDED'
        AND a.AccountType IN ('A', 'P', 'C')
        AND je.EntryDate <= @fechaCorte
      GROUP BY l.AccountCodeSnapshot
      ORDER BY l.AccountCodeSnapshot`,
    { companyId: scope.companyId, branchId: scope.branchId, fechaCorte }
  );

  const totalActivo = round2(detalle.filter((r) => r.tipo === "A").reduce((acc, r) => acc + Number(r.saldo ?? 0), 0));
  const totalPasivo = round2(detalle.filter((r) => r.tipo === "P").reduce((acc, r) => acc + Number(r.saldo ?? 0), 0));
  const totalPatrimonio = round2(detalle.filter((r) => r.tipo === "C").reduce((acc, r) => acc + Number(r.saldo ?? 0), 0));

  return {
    detalle,
    resumen: {
      totalActivo,
      totalPasivo,
      totalPatrimonio,
      totalPasivoPatrimonio: round2(totalPasivo + totalPatrimonio)
    }
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
