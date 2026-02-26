import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";

export interface ConciliacionRow {
  ID?: number;
  Nro_Cta?: string;
  Fecha_Desde?: string;
  Fecha_Hasta?: string;
  Saldo_Inicial_Sistema?: number;
  Saldo_Final_Sistema?: number;
  Saldo_Inicial_Banco?: number;
  Saldo_Final_Banco?: number;
  Diferencia?: number;
  Estado?: string;
  Observaciones?: string;
  Banco?: string;
  Pendientes?: number;
  Conciliados?: number;
}

export interface MovimientoBancarioPayload {
  Nro_Cta: string;
  Tipo: string;
  Nro_Ref: string;
  Beneficiario: string;
  Monto: number;
  Concepto: string;
  Categoria?: string;
  Documento_Relacionado?: string;
  Tipo_Doc_Rel?: string;
}

export interface ExtractoPayload {
  Nro_Cta?: string;
  Fecha: string;
  Descripcion?: string;
  Referencia?: string;
  Tipo: "DEBITO" | "CREDITO";
  Monto: number;
  Saldo?: number;
}

export interface AjustePayload {
  Conciliacion_ID: number;
  Tipo_Ajuste: string;
  Monto: number;
  Descripcion: string;
}

export interface ConciliacionResult {
  conciliacionId: number;
  saldoInicial: number;
  saldoFinal: number;
}

type Scope = {
  companyId: number;
  branchId: number;
  systemUserId: number | null;
};

type BankAccountRow = {
  bankAccountId: number;
  nroCta: string;
  bankName: string;
  balance: number;
  availableBalance: number;
};

let scopeCache: Scope | null = null;

async function getScope(): Promise<Scope> {
  if (scopeCache) return scopeCache;

  const rows = await query<{ companyId: number; branchId: number; systemUserId: number | null }>(
    `
    SELECT TOP 1
      c.CompanyId AS companyId,
      b.BranchId AS branchId,
      su.UserId AS systemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
      ON b.CompanyId = c.CompanyId
     AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] su
      ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId
    `
  );

  const row = rows[0];
  scopeCache = {
    companyId: Number(row?.companyId ?? 1),
    branchId: Number(row?.branchId ?? 1),
    systemUserId: row?.systemUserId == null ? null : Number(row.systemUserId),
  };
  return scopeCache;
}

async function resolveUserId(codUsuario?: string): Promise<number | null> {
  const code = String(codUsuario ?? "").trim();
  if (!code) return (await getScope()).systemUserId;

  const rows = await query<{ userId: number }>(
    `
    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@code)
    ORDER BY UserId
    `,
    { code }
  );

  if (rows[0]?.userId != null) return Number(rows[0].userId);
  return (await getScope()).systemUserId;
}

async function getBankAccount(nroCta: string): Promise<BankAccountRow | null> {
  const scope = await getScope();
  const rows = await query<BankAccountRow>(
    `
    SELECT TOP 1
      ba.BankAccountId AS bankAccountId,
      ba.AccountNumber AS nroCta,
      b.BankName AS bankName,
      ba.Balance AS balance,
      ba.AvailableBalance AS availableBalance
    FROM fin.BankAccount ba
    INNER JOIN fin.Bank b
      ON b.BankId = ba.BankId
    WHERE ba.CompanyId = @companyId
      AND ba.AccountNumber = @nroCta
      AND ba.IsActive = 1
      AND b.IsActive = 1
    ORDER BY ba.BankAccountId
    `,
    {
      companyId: scope.companyId,
      nroCta: String(nroCta ?? "").trim(),
    }
  );
  return rows[0] ?? null;
}

function toMovementSign(tipo: string) {
  const normalized = String(tipo ?? "").trim().toUpperCase();
  if (["DEP", "NCR", "IDB", "NOTA_CREDITO", "CREDITO"].includes(normalized)) return 1;
  return -1;
}

function toSqlDate(value?: string) {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export async function generarMovimientoBancario(
  payload: MovimientoBancarioPayload,
  codUsuario?: string
): Promise<{ ok: boolean; movimientoId?: number; saldoNuevo?: number }> {
  const account = await getBankAccount(payload.Nro_Cta);
  if (!account) return { ok: false };

  const amount = Math.abs(Number(payload.Monto ?? 0));
  if (!(amount > 0)) return { ok: false };

  const movementSign = toMovementSign(payload.Tipo);
  const netAmount = Number((movementSign * amount).toFixed(2));
  const userId = await resolveUserId(codUsuario);

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const accountLock = new sql.Request(tx);
    accountLock.input("bankAccountId", sql.BigInt, account.bankAccountId);
    const lockRs = await accountLock.query<{ balance: number; availableBalance: number }>(
      `
      SELECT TOP 1
        Balance AS balance,
        AvailableBalance AS availableBalance
      FROM fin.BankAccount WITH (UPDLOCK, ROWLOCK)
      WHERE BankAccountId = @bankAccountId
      `
    );

    const currentBalance = Number(lockRs.recordset?.[0]?.balance ?? 0);
    const currentAvailable = Number(lockRs.recordset?.[0]?.availableBalance ?? currentBalance);
    const newBalance = Number((currentBalance + netAmount).toFixed(2));
    const newAvailable = Number((currentAvailable + netAmount).toFixed(2));

    const updateReq = new sql.Request(tx);
    updateReq.input("bankAccountId", sql.BigInt, account.bankAccountId);
    updateReq.input("newBalance", sql.Decimal(18, 2), newBalance);
    updateReq.input("newAvailable", sql.Decimal(18, 2), newAvailable);
    await updateReq.query(
      `
      UPDATE fin.BankAccount
      SET
        Balance = @newBalance,
        AvailableBalance = @newAvailable,
        UpdatedAt = SYSUTCDATETIME()
      WHERE BankAccountId = @bankAccountId
      `
    );

    const insertReq = new sql.Request(tx);
    insertReq.input("bankAccountId", sql.BigInt, account.bankAccountId);
    insertReq.input("movementDate", sql.DateTime2, new Date());
    insertReq.input("movementType", sql.NVarChar(12), String(payload.Tipo ?? "").trim().toUpperCase() || "MOV");
    insertReq.input("movementSign", sql.SmallInt, movementSign);
    insertReq.input("amount", sql.Decimal(18, 2), amount);
    insertReq.input("netAmount", sql.Decimal(18, 2), netAmount);
    insertReq.input("referenceNo", sql.NVarChar(50), String(payload.Nro_Ref ?? "").trim() || null);
    insertReq.input("beneficiary", sql.NVarChar(255), String(payload.Beneficiario ?? "").trim() || null);
    insertReq.input("concept", sql.NVarChar(255), String(payload.Concepto ?? "").trim() || null);
    insertReq.input("categoryCode", sql.NVarChar(50), String(payload.Categoria ?? "").trim() || null);
    insertReq.input("relatedDocumentNo", sql.NVarChar(60), String(payload.Documento_Relacionado ?? "").trim() || null);
    insertReq.input("relatedDocumentType", sql.NVarChar(20), String(payload.Tipo_Doc_Rel ?? "").trim() || null);
    insertReq.input("balanceAfter", sql.Decimal(18, 2), newBalance);
    insertReq.input("createdByUserId", sql.Int, userId ?? null);

    const insertRs = await insertReq.query<{ movementId: number }>(
      `
      INSERT INTO fin.BankMovement (
        BankAccountId,
        MovementDate,
        MovementType,
        MovementSign,
        Amount,
        NetAmount,
        ReferenceNo,
        Beneficiary,
        Concept,
        CategoryCode,
        RelatedDocumentNo,
        RelatedDocumentType,
        BalanceAfter,
        CreatedByUserId
      )
      OUTPUT INSERTED.BankMovementId AS movementId
      VALUES (
        @bankAccountId,
        @movementDate,
        @movementType,
        @movementSign,
        @amount,
        @netAmount,
        @referenceNo,
        @beneficiary,
        @concept,
        @categoryCode,
        @relatedDocumentNo,
        @relatedDocumentType,
        @balanceAfter,
        @createdByUserId
      )
      `
    );

    await tx.commit();

    return {
      ok: true,
      movimientoId: Number(insertRs.recordset?.[0]?.movementId ?? 0) || undefined,
      saldoNuevo: newBalance,
    };
  } catch {
    await tx.rollback();
    return { ok: false };
  }
}

export async function crearConciliacion(
  Nro_Cta: string,
  Fecha_Desde: string,
  Fecha_Hasta: string,
  codUsuario?: string
): Promise<ConciliacionResult> {
  const scope = await getScope();
  const account = await getBankAccount(Nro_Cta);
  if (!account) throw new Error("Cuenta bancaria no encontrada");

  const from = toSqlDate(Fecha_Desde);
  const to = toSqlDate(Fecha_Hasta);
  if (!from || !to) throw new Error("Fechas invalidas");

  const netRows = await query<{ netTotal: number }>(
    `
    SELECT COALESCE(SUM(NetAmount), 0) AS netTotal
    FROM fin.BankMovement
    WHERE BankAccountId = @bankAccountId
      AND CAST(MovementDate AS DATE) BETWEEN @fromDate AND @toDate
    `,
    {
      bankAccountId: account.bankAccountId,
      fromDate: from,
      toDate: to,
    }
  );

  const opening = Number(account.balance ?? 0);
  const closing = Number((opening + Number(netRows[0]?.netTotal ?? 0)).toFixed(2));
  const userId = await resolveUserId(codUsuario);

  const rows = await query<{ conciliacionId: number }>(
    `
    INSERT INTO fin.BankReconciliation (
      CompanyId,
      BranchId,
      BankAccountId,
      DateFrom,
      DateTo,
      OpeningSystemBalance,
      ClosingSystemBalance,
      OpeningBankBalance,
      CreatedByUserId
    )
    OUTPUT INSERTED.BankReconciliationId AS conciliacionId
    VALUES (
      @companyId,
      @branchId,
      @bankAccountId,
      @fromDate,
      @toDate,
      @opening,
      @closing,
      @opening,
      @createdByUserId
    )
    `,
    {
      companyId: scope.companyId,
      branchId: scope.branchId,
      bankAccountId: account.bankAccountId,
      fromDate: from,
      toDate: to,
      opening,
      closing,
      createdByUserId: userId,
    }
  );

  return {
    conciliacionId: Number(rows[0]?.conciliacionId ?? 0),
    saldoInicial: opening,
    saldoFinal: closing,
  };
}

export async function listConciliaciones(params: {
  Nro_Cta?: string;
  Estado?: string;
  page?: number;
  limit?: number;
}): Promise<{ rows: ConciliacionRow[]; total: number; page: number; limit: number }> {
  const scope = await getScope();
  const page = Math.max(1, params.page || 1);
  const limit = Math.min(Math.max(1, params.limit || 50), 500);
  const offset = (page - 1) * limit;

  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    offset,
    limit,
  };

  const where: string[] = ["r.CompanyId = @companyId"];
  if (params.Nro_Cta?.trim()) {
    where.push("ba.AccountNumber = @nroCta");
    sqlParams.nroCta = params.Nro_Cta.trim();
  }
  if (params.Estado?.trim()) {
    where.push("r.Status = @estado");
    sqlParams.estado = params.Estado.trim().toUpperCase();
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const rows = await query<ConciliacionRow>(
    `
    SELECT
      CAST(r.BankReconciliationId AS INT) AS ID,
      ba.AccountNumber AS Nro_Cta,
      CONVERT(VARCHAR(10), r.DateFrom, 23) AS Fecha_Desde,
      CONVERT(VARCHAR(10), r.DateTo, 23) AS Fecha_Hasta,
      r.OpeningSystemBalance AS Saldo_Inicial_Sistema,
      r.ClosingSystemBalance AS Saldo_Final_Sistema,
      r.OpeningBankBalance AS Saldo_Inicial_Banco,
      r.ClosingBankBalance AS Saldo_Final_Banco,
      r.DifferenceAmount AS Diferencia,
      r.Status AS Estado,
      r.Notes AS Observaciones,
      b.BankName AS Banco,
      (
        SELECT COUNT(1)
        FROM fin.BankStatementLine s
        WHERE s.ReconciliationId = r.BankReconciliationId
          AND s.IsMatched = 0
      ) AS Pendientes,
      (
        SELECT COUNT(1)
        FROM fin.BankStatementLine s
        WHERE s.ReconciliationId = r.BankReconciliationId
          AND s.IsMatched = 1
      ) AS Conciliados
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    INNER JOIN fin.Bank b ON b.BankId = ba.BankId
    ${clause}
    ORDER BY r.BankReconciliationId DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    ${clause}
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
    page,
    limit,
  };
}

export async function getConciliacion(
  Conciliacion_ID: number
): Promise<{
  cabecera: ConciliacionRow | null;
  movimientosSistema: any[];
  extractoPendiente: any[];
}> {
  const scope = await getScope();
  const cabeceraRows = await query<ConciliacionRow>(
    `
    SELECT TOP 1
      CAST(r.BankReconciliationId AS INT) AS ID,
      ba.AccountNumber AS Nro_Cta,
      CONVERT(VARCHAR(10), r.DateFrom, 23) AS Fecha_Desde,
      CONVERT(VARCHAR(10), r.DateTo, 23) AS Fecha_Hasta,
      r.OpeningSystemBalance AS Saldo_Inicial_Sistema,
      r.ClosingSystemBalance AS Saldo_Final_Sistema,
      r.OpeningBankBalance AS Saldo_Inicial_Banco,
      r.ClosingBankBalance AS Saldo_Final_Banco,
      r.DifferenceAmount AS Diferencia,
      r.Status AS Estado,
      r.Notes AS Observaciones,
      b.BankName AS Banco
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    INNER JOIN fin.Bank b ON b.BankId = ba.BankId
    WHERE r.CompanyId = @companyId
      AND r.BankReconciliationId = @id
    `,
    {
      companyId: scope.companyId,
      id: Conciliacion_ID,
    }
  );
  const cabecera = cabeceraRows[0] ?? null;
  if (!cabecera) {
    return { cabecera: null, movimientosSistema: [], extractoPendiente: [] };
  }

  const movimientosSistema = await query<any>(
    `
    SELECT
      m.BankMovementId AS id,
      m.MovementDate AS Fecha,
      m.MovementType AS Tipo,
      m.ReferenceNo AS Nro_Ref,
      m.Beneficiary AS Beneficiario,
      m.Concept AS Concepto,
      m.Amount AS Monto,
      m.NetAmount AS MontoNeto,
      m.BalanceAfter AS SaldoPosterior,
      m.IsReconciled AS Conciliado
    FROM fin.BankMovement m
    INNER JOIN fin.BankReconciliation r ON r.BankAccountId = m.BankAccountId
    WHERE r.BankReconciliationId = @id
      AND CAST(m.MovementDate AS DATE) BETWEEN r.DateFrom AND r.DateTo
    ORDER BY m.MovementDate DESC, m.BankMovementId DESC
    `,
    { id: Conciliacion_ID }
  );

  const extractoPendiente = await query<any>(
    `
    SELECT
      StatementLineId AS id,
      StatementDate AS Fecha,
      DescriptionText AS Descripcion,
      ReferenceNo AS Referencia,
      EntryType AS Tipo,
      Amount AS Monto,
      Balance AS Saldo
    FROM fin.BankStatementLine
    WHERE ReconciliationId = @id
      AND IsMatched = 0
    ORDER BY StatementDate DESC, StatementLineId DESC
    `,
    { id: Conciliacion_ID }
  );

  return {
    cabecera,
    movimientosSistema,
    extractoPendiente,
  };
}

export async function importarExtracto(
  Nro_Cta: string,
  extractoRows: ExtractoPayload[],
  codUsuario?: string
): Promise<{ ok: boolean; registrosImportados?: number }> {
  const scope = await getScope();
  const account = await getBankAccount(Nro_Cta);
  if (!account) return { ok: false };

  const userId = await resolveUserId(codUsuario);
  const validRows = extractoRows.filter((row) => Number(row.Monto ?? 0) > 0);
  if (validRows.length === 0) return { ok: true, registrosImportados: 0 };

  const openRec = await query<{ id: number }>(
    `
    SELECT TOP 1 BankReconciliationId AS id
    FROM fin.BankReconciliation
    WHERE CompanyId = @companyId
      AND BankAccountId = @bankAccountId
      AND Status = N'OPEN'
    ORDER BY BankReconciliationId DESC
    `,
    {
      companyId: scope.companyId,
      bankAccountId: account.bankAccountId,
    }
  );

  let reconciliationId = Number(openRec[0]?.id ?? 0);
  if (!reconciliationId) {
    const dates = validRows
      .map((row) => toSqlDate(row.Fecha))
      .filter((value): value is Date => value instanceof Date)
      .sort((a, b) => a.getTime() - b.getTime());

    const fromDate = dates[0] ?? new Date();
    const toDate = dates[dates.length - 1] ?? new Date();
    const created = await query<{ id: number }>(
      `
      INSERT INTO fin.BankReconciliation (
        CompanyId,
        BranchId,
        BankAccountId,
        DateFrom,
        DateTo,
        OpeningSystemBalance,
        ClosingSystemBalance,
        OpeningBankBalance,
        CreatedByUserId
      )
      OUTPUT INSERTED.BankReconciliationId AS id
      VALUES (
        @companyId,
        @branchId,
        @bankAccountId,
        @fromDate,
        @toDate,
        @opening,
        @opening,
        @opening,
        @userId
      )
      `,
      {
        companyId: scope.companyId,
        branchId: scope.branchId,
        bankAccountId: account.bankAccountId,
        fromDate,
        toDate,
        opening: account.balance,
        userId,
      }
    );
    reconciliationId = Number(created[0]?.id ?? 0);
  }

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    for (const row of validRows) {
      const req = new sql.Request(tx);
      req.input("reconciliationId", sql.BigInt, reconciliationId);
      req.input("statementDate", sql.DateTime2, toSqlDate(row.Fecha) ?? new Date());
      req.input("descriptionText", sql.NVarChar(255), String(row.Descripcion ?? "").trim() || null);
      req.input("referenceNo", sql.NVarChar(50), String(row.Referencia ?? "").trim() || null);
      req.input("entryType", sql.NVarChar(12), row.Tipo === "CREDITO" ? "CREDITO" : "DEBITO");
      req.input("amount", sql.Decimal(18, 2), Math.abs(Number(row.Monto ?? 0)));
      req.input("balance", sql.Decimal(18, 2), row.Saldo == null ? null : Number(row.Saldo));
      req.input("createdByUserId", sql.Int, userId ?? null);
      await req.query(
        `
        INSERT INTO fin.BankStatementLine (
          ReconciliationId,
          StatementDate,
          DescriptionText,
          ReferenceNo,
          EntryType,
          Amount,
          Balance,
          CreatedByUserId
        )
        VALUES (
          @reconciliationId,
          @statementDate,
          @descriptionText,
          @referenceNo,
          @entryType,
          @amount,
          @balance,
          @createdByUserId
        )
        `
      );
    }

    await tx.commit();
    return { ok: true, registrosImportados: validRows.length };
  } catch {
    await tx.rollback();
    return { ok: false };
  }
}

export async function conciliarMovimientos(
  Conciliacion_ID: number,
  MovimientoSistema_ID: number,
  Extracto_ID?: number,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const userId = await resolveUserId(codUsuario);
  const recRows = await query<{ accountId: number }>(
    `
    SELECT TOP 1 BankAccountId AS accountId
    FROM fin.BankReconciliation
    WHERE BankReconciliationId = @id
    `,
    { id: Conciliacion_ID }
  );
  const accountId = Number(recRows[0]?.accountId ?? 0);
  if (!accountId) return { ok: false, mensaje: "Conciliacion no encontrada" };

  const moveRows = await query<{ movementId: number; amount: number; sign: number }>(
    `
    SELECT TOP 1
      BankMovementId AS movementId,
      Amount AS amount,
      MovementSign AS sign
    FROM fin.BankMovement
    WHERE BankMovementId = @movementId
      AND BankAccountId = @accountId
    `,
    {
      movementId: MovimientoSistema_ID,
      accountId,
    }
  );
  const movement = moveRows[0];
  if (!movement) return { ok: false, mensaje: "Movimiento no encontrado" };

  let statementId = Number(Extracto_ID ?? 0);
  if (!statementId) {
    const expectedType = Number(movement.sign) < 0 ? "DEBITO" : "CREDITO";
    const statement = await query<{ id: number }>(
      `
      SELECT TOP 1 StatementLineId AS id
      FROM fin.BankStatementLine
      WHERE ReconciliationId = @reconciliationId
        AND IsMatched = 0
        AND EntryType = @entryType
        AND ABS(Amount - @amount) <= 0.01
      ORDER BY StatementDate, StatementLineId
      `,
      {
        reconciliationId: Conciliacion_ID,
        entryType: expectedType,
        amount: Number(movement.amount ?? 0),
      }
    );
    statementId = Number(statement[0]?.id ?? 0);
  }

  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();

  try {
    const req1 = new sql.Request(tx);
    req1.input("reconciliationId", sql.BigInt, Conciliacion_ID);
    req1.input("movementId", sql.BigInt, MovimientoSistema_ID);
    req1.input("statementId", sql.BigInt, statementId > 0 ? statementId : null);
    req1.input("matchedByUserId", sql.Int, userId ?? null);
    await req1.query(
      `
      IF NOT EXISTS (
        SELECT 1
        FROM fin.BankReconciliationMatch
        WHERE ReconciliationId = @reconciliationId
          AND BankMovementId = @movementId
      )
      BEGIN
        INSERT INTO fin.BankReconciliationMatch (
          ReconciliationId,
          BankMovementId,
          StatementLineId,
          MatchedByUserId
        )
        VALUES (
          @reconciliationId,
          @movementId,
          @statementId,
          @matchedByUserId
        );
      END
      `
    );

    const req2 = new sql.Request(tx);
    req2.input("movementId", sql.BigInt, MovimientoSistema_ID);
    req2.input("reconciliationId", sql.BigInt, Conciliacion_ID);
    await req2.query(
      `
      UPDATE fin.BankMovement
      SET
        IsReconciled = 1,
        ReconciledAt = SYSUTCDATETIME(),
        ReconciliationId = @reconciliationId
      WHERE BankMovementId = @movementId
      `
    );

    if (statementId > 0) {
      const req3 = new sql.Request(tx);
      req3.input("statementId", sql.BigInt, statementId);
      await req3.query(
        `
        UPDATE fin.BankStatementLine
        SET
          IsMatched = 1,
          MatchedAt = SYSUTCDATETIME()
        WHERE StatementLineId = @statementId
        `
      );
    }

    await tx.commit();
    return { ok: true, mensaje: "Movimiento conciliado" };
  } catch {
    await tx.rollback();
    return { ok: false, mensaje: "No se pudo conciliar" };
  }
}

export async function generarAjusteBancario(
  payload: AjustePayload,
  codUsuario?: string
): Promise<{ ok: boolean; mensaje?: string }> {
  const rec = await query<{ accountNo: string }>(
    `
    SELECT TOP 1 ba.AccountNumber AS accountNo
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    WHERE r.BankReconciliationId = @id
    `,
    { id: payload.Conciliacion_ID }
  );
  const accountNo = String(rec[0]?.accountNo ?? "").trim();
  if (!accountNo) return { ok: false, mensaje: "Conciliacion no encontrada" };

  const tipo = String(payload.Tipo_Ajuste ?? "").trim().toUpperCase() === "NOTA_CREDITO" ? "NCR" : "NDB";
  const result = await generarMovimientoBancario(
    {
      Nro_Cta: accountNo,
      Tipo: tipo,
      Nro_Ref: `AJ-${payload.Conciliacion_ID}-${Date.now()}`,
      Beneficiario: "AJUSTE",
      Monto: Math.abs(Number(payload.Monto ?? 0)),
      Concepto: payload.Descripcion,
      Categoria: "AJUSTE_CONCILIACION",
      Documento_Relacionado: String(payload.Conciliacion_ID),
      Tipo_Doc_Rel: "CONCILIACION",
    },
    codUsuario
  );

  if (!result.ok || !result.movimientoId) {
    return { ok: false, mensaje: "No se pudo generar el ajuste" };
  }

  await conciliarMovimientos(payload.Conciliacion_ID, result.movimientoId, undefined, codUsuario);
  return { ok: true, mensaje: "Ajuste generado" };
}

export async function cerrarConciliacion(
  Conciliacion_ID: number,
  Saldo_Final_Banco: number,
  Observaciones?: string,
  codUsuario?: string
): Promise<{ ok: boolean; diferencia?: number; estado?: string }> {
  const userId = await resolveUserId(codUsuario);
  const recRows = await query<{ bankAccountId: number }>(
    `
    SELECT TOP 1 BankAccountId AS bankAccountId
    FROM fin.BankReconciliation
    WHERE BankReconciliationId = @id
    `,
    { id: Conciliacion_ID }
  );
  const bankAccountId = Number(recRows[0]?.bankAccountId ?? 0);
  if (!bankAccountId) return { ok: false };

  const accountRows = await query<{ balance: number }>(
    `
    SELECT TOP 1 Balance AS balance
    FROM fin.BankAccount
    WHERE BankAccountId = @bankAccountId
    `,
    { bankAccountId }
  );
  const systemClosing = Number(accountRows[0]?.balance ?? 0);
  const bankClosing = Number(Saldo_Final_Banco ?? 0);
  const difference = Number((bankClosing - systemClosing).toFixed(2));
  const status = Math.abs(difference) <= 0.01 ? "CLOSED" : "CLOSED_WITH_DIFF";

  await query(
    `
    UPDATE fin.BankReconciliation
    SET
      ClosingSystemBalance = @systemClosing,
      ClosingBankBalance = @bankClosing,
      DifferenceAmount = @difference,
      Status = @status,
      Notes = COALESCE(@notes, Notes),
      ClosedAt = SYSUTCDATETIME(),
      ClosedByUserId = @closedByUserId,
      UpdatedAt = SYSUTCDATETIME()
    WHERE BankReconciliationId = @id
    `,
    {
      id: Conciliacion_ID,
      systemClosing,
      bankClosing,
      difference,
      status,
      notes: String(Observaciones ?? "").trim() || null,
      closedByUserId: userId,
    }
  );

  return { ok: true, diferencia: difference, estado: status };
}

export async function getCuentasBancarias(): Promise<any[]> {
  const scope = await getScope();
  const rows = await query<any>(
    `
    SELECT
      ba.AccountNumber AS Nro_Cta,
      b.BankName AS Banco,
      ba.AccountName AS Descripcion,
      ba.CurrencyCode AS Moneda,
      ba.Balance AS Saldo,
      ba.AvailableBalance AS Saldo_Disponible,
      b.BankName AS BancoNombre
    FROM fin.BankAccount ba
    INNER JOIN fin.Bank b
      ON b.BankId = ba.BankId
    WHERE ba.CompanyId = @companyId
      AND ba.IsActive = 1
      AND b.IsActive = 1
    ORDER BY b.BankName, ba.AccountNumber
    `,
    { companyId: scope.companyId }
  );
  return rows;
}

export async function getMovimientosCuenta(
  Nro_Cta: string,
  desde?: string,
  hasta?: string,
  page: number = 1,
  limit: number = 50
): Promise<{ rows: any[]; total: number }> {
  const scope = await getScope();
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.min(Math.max(1, Number(limit) || 50), 500);
  const offset = (safePage - 1) * safeLimit;

  const sqlParams: Record<string, unknown> = {
    companyId: scope.companyId,
    nroCta: String(Nro_Cta ?? "").trim(),
    offset,
    limit: safeLimit,
  };

  const where: string[] = ["ba.CompanyId = @companyId", "ba.AccountNumber = @nroCta"];
  if (desde) {
    const from = toSqlDate(desde);
    if (from) {
      where.push("m.MovementDate >= @fromDate");
      sqlParams.fromDate = from;
    }
  }
  if (hasta) {
    const to = toSqlDate(hasta);
    if (to) {
      where.push("m.MovementDate <= @toDate");
      sqlParams.toDate = to;
    }
  }

  const clause = `WHERE ${where.join(" AND ")}`;
  const totalRows = await query<{ total: number }>(
    `
    SELECT COUNT(1) AS total
    FROM fin.BankMovement m
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = m.BankAccountId
    ${clause}
    `,
    sqlParams
  );

  const rows = await query<any>(
    `
    SELECT
      m.BankMovementId AS id,
      ba.AccountNumber AS Nro_Cta,
      m.MovementDate AS Fecha,
      m.MovementType AS Tipo,
      m.ReferenceNo AS Nro_Ref,
      m.Beneficiary AS Beneficiario,
      m.Amount AS Monto,
      m.NetAmount AS MontoNeto,
      m.Concept AS Concepto,
      m.CategoryCode AS Categoria,
      m.RelatedDocumentNo AS Documento_Relacionado,
      m.RelatedDocumentType AS Tipo_Doc_Rel,
      m.BalanceAfter AS SaldoPosterior,
      m.IsReconciled AS Conciliado
    FROM fin.BankMovement m
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = m.BankAccountId
    ${clause}
    ORDER BY m.MovementDate DESC, m.BankMovementId DESC
    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `,
    sqlParams
  );

  return {
    rows,
    total: Number(totalRows[0]?.total ?? 0),
  };
}
