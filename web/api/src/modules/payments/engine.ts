/**
 * DatqBox Payment Gateway — Engine
 *
 * Orchestrates payment processing: resolves the provider plugin,
 * executes the gateway call, and records the transaction.
 */

import { randomUUID } from "node:crypto";
import { getPool, sql } from "../../db/mssql.js";
import { query } from "../../db/query.js";
import { getPlugin } from "./registry.js";
import type {
  CompanyPaymentConfig,
  GatewayRequest,
  GatewayResponse,
  TransactionStatus,
  SourceType,
  CurrencyCode,
} from "./types.js";

// ── Resolve active config for a company + provider ──────────────

async function resolveConfig(
  empresaId: number,
  sucursalId: number,
  providerCode: string
): Promise<CompanyPaymentConfig | null> {
  const rows = await query<any>(`
    SELECT c.*, p.Code AS ProviderCode
    FROM pay.CompanyPaymentConfig c
    JOIN pay.PaymentProviders p ON p.Id = c.ProviderId
    WHERE c.EmpresaId = @empresaId
      AND c.SucursalId = @sucursalId
      AND p.Code = @providerCode
      AND c.IsActive = 1
  `, { empresaId, sucursalId, providerCode });

  if (!rows.length) return null;
  const r = rows[0];
  return {
    id: r.Id,
    empresaId: r.EmpresaId,
    sucursalId: r.SucursalId,
    countryCode: r.CountryCode,
    providerId: r.ProviderId,
    environment: r.Environment,
    clientId: r.ClientId,
    clientSecret: r.ClientSecret,
    merchantId: r.MerchantId,
    terminalId: r.TerminalId,
    integratorId: r.IntegratorId,
    certificatePath: r.CertificatePath,
    extraConfig: r.ExtraConfig ? JSON.parse(r.ExtraConfig) : null,
    autoCapture: r.AutoCapture,
    allowRefunds: r.AllowRefunds,
    maxRefundDays: r.MaxRefundDays,
    isActive: r.IsActive,
  };
}

// ── Record transaction in DB ────────────────────────────────────

interface RecordTrxParams {
  empresaId: number;
  sucursalId: number;
  sourceType: SourceType;
  sourceId?: number;
  sourceNumber?: string;
  paymentMethodCode: string;
  providerId?: number;
  currency: CurrencyCode;
  amount: number;
  trxType: string;
  status: TransactionStatus;
  gatewayTrxId?: string;
  gatewayAuthCode?: string;
  gatewayResponse?: unknown;
  gatewayMessage?: string;
  cardLastFour?: string;
  cardBrand?: string;
  mobileNumber?: string;
  bankCode?: string;
  paymentRef?: string;
  stationId?: string;
  cashierId?: string;
  ipAddress?: string;
}

async function recordTransaction(p: RecordTrxParams): Promise<string> {
  const uuid = randomUUID();
  const pool = await getPool();
  await pool.request()
    .input("uuid", sql.VarChar(36), uuid)
    .input("empresaId", sql.Int, p.empresaId)
    .input("sucursalId", sql.Int, p.sucursalId)
    .input("sourceType", sql.VarChar(30), p.sourceType)
    .input("sourceId", sql.Int, p.sourceId ?? null)
    .input("sourceNumber", sql.VarChar(50), p.sourceNumber ?? null)
    .input("methodCode", sql.VarChar(30), p.paymentMethodCode)
    .input("providerId", sql.Int, p.providerId ?? null)
    .input("currency", sql.VarChar(3), p.currency)
    .input("amount", sql.Decimal(18, 2), p.amount)
    .input("trxType", sql.VarChar(20), p.trxType)
    .input("status", sql.VarChar(20), p.status)
    .input("gatewayTrxId", sql.VarChar(100), p.gatewayTrxId ?? null)
    .input("gatewayAuthCode", sql.VarChar(50), p.gatewayAuthCode ?? null)
    .input("gatewayResponse", sql.NVarChar(sql.MAX), p.gatewayResponse ? JSON.stringify(p.gatewayResponse) : null)
    .input("gatewayMessage", sql.NVarChar(500), p.gatewayMessage ?? null)
    .input("cardLastFour", sql.VarChar(4), p.cardLastFour ?? null)
    .input("cardBrand", sql.VarChar(20), p.cardBrand ?? null)
    .input("mobileNumber", sql.VarChar(20), p.mobileNumber ?? null)
    .input("bankCode", sql.VarChar(10), p.bankCode ?? null)
    .input("paymentRef", sql.VarChar(50), p.paymentRef ?? null)
    .input("stationId", sql.VarChar(50), p.stationId ?? null)
    .input("cashierId", sql.VarChar(20), p.cashierId ?? null)
    .input("ipAddress", sql.VarChar(45), p.ipAddress ?? null)
    .query(`
      INSERT INTO pay.Transactions (
        TransactionUUID, EmpresaId, SucursalId,
        SourceType, SourceId, SourceNumber,
        PaymentMethodCode, ProviderId,
        Currency, Amount, TrxType, Status,
        GatewayTrxId, GatewayAuthCode, GatewayResponse, GatewayMessage,
        CardLastFour, CardBrand,
        MobileNumber, BankCode, PaymentRef,
        StationId, CashierId, IpAddress
      ) VALUES (
        @uuid, @empresaId, @sucursalId,
        @sourceType, @sourceId, @sourceNumber,
        @methodCode, @providerId,
        @currency, @amount, @trxType, @status,
        @gatewayTrxId, @gatewayAuthCode, @gatewayResponse, @gatewayMessage,
        @cardLastFour, @cardBrand,
        @mobileNumber, @bankCode, @paymentRef,
        @stationId, @cashierId, @ipAddress
      )
    `);
  return uuid;
}

async function updateTransactionStatus(uuid: string, status: TransactionStatus, gatewayFields?: Partial<RecordTrxParams>) {
  const pool = await getPool();
  const req = pool.request()
    .input("uuid", sql.VarChar(36), uuid)
    .input("status", sql.VarChar(20), status)
    .input("gatewayTrxId", sql.VarChar(100), gatewayFields?.gatewayTrxId ?? null)
    .input("gatewayAuthCode", sql.VarChar(50), gatewayFields?.gatewayAuthCode ?? null)
    .input("gatewayResponse", sql.NVarChar(sql.MAX), gatewayFields?.gatewayResponse ? JSON.stringify(gatewayFields.gatewayResponse) : null)
    .input("gatewayMessage", sql.NVarChar(500), gatewayFields?.gatewayMessage ?? null);

  await req.query(`
    UPDATE pay.Transactions
    SET Status = @status,
        GatewayTrxId = COALESCE(@gatewayTrxId, GatewayTrxId),
        GatewayAuthCode = COALESCE(@gatewayAuthCode, GatewayAuthCode),
        GatewayResponse = COALESCE(@gatewayResponse, GatewayResponse),
        GatewayMessage = COALESCE(@gatewayMessage, GatewayMessage),
        UpdatedAt = GETDATE()
    WHERE TransactionUUID = @uuid
  `);
}

// ── Main Engine: processPayment ─────────────────────────────────

export interface ProcessPaymentInput {
  empresaId: number;
  sucursalId: number;
  providerCode: string;
  sourceType: SourceType;
  sourceId?: number;
  sourceNumber?: string;
  stationId?: string;
  cashierId?: string;
  ipAddress?: string;
  request: GatewayRequest;
}

export interface ProcessPaymentResult {
  transactionUUID: string;
  response: GatewayResponse;
}

export async function processPayment(input: ProcessPaymentInput): Promise<ProcessPaymentResult> {
  const plugin = getPlugin(input.providerCode);
  if (!plugin) {
    throw new Error(`Payment provider plugin not found: ${input.providerCode}`);
  }

  const config = await resolveConfig(input.empresaId, input.sucursalId, input.providerCode);
  if (!config) {
    throw new Error(`No active payment config for empresa=${input.empresaId}, sucursal=${input.sucursalId}, provider=${input.providerCode}`);
  }

  // Validate config
  const configErrors = plugin.validateConfig(config);
  if (configErrors.length > 0) {
    throw new Error(`Payment config incomplete: ${configErrors.join(", ")}`);
  }

  // Record PENDING transaction
  const uuid = await recordTransaction({
    empresaId: input.empresaId,
    sucursalId: input.sucursalId,
    sourceType: input.sourceType,
    sourceId: input.sourceId,
    sourceNumber: input.sourceNumber,
    paymentMethodCode: input.request.paymentMethodCode,
    providerId: config.providerId,
    currency: input.request.currency,
    amount: input.request.amount,
    trxType: input.request.capability === "REFUND" ? "REFUND"
           : input.request.capability === "VOID" ? "VOID"
           : input.request.capability === "AUTH" ? "AUTH"
           : input.request.capability === "CAPTURE" ? "CAPTURE"
           : "SALE",
    status: "PENDING",
    stationId: input.stationId,
    cashierId: input.cashierId,
    ipAddress: input.ipAddress,
    mobileNumber: input.request.mobile?.originNumber,
    bankCode: input.request.mobile?.destinationBankId,
  });

  // Execute through plugin
  let response: GatewayResponse;
  try {
    response = await plugin.execute(config, input.request);
  } catch (err: any) {
    await updateTransactionStatus(uuid, "ERROR", {
      gatewayMessage: err.message?.substring(0, 500),
    });
    return {
      transactionUUID: uuid,
      response: {
        success: false,
        status: "ERROR",
        message: `Gateway error: ${err.message}`,
      },
    };
  }

  // Update transaction with response
  await updateTransactionStatus(uuid, response.status, {
    gatewayTrxId: response.transactionId,
    gatewayAuthCode: response.authCode,
    gatewayResponse: response.providerRawResponse,
    gatewayMessage: response.message?.substring(0, 500),
  });

  return { transactionUUID: uuid, response };
}

// ── Search transactions ─────────────────────────────────────────

export interface SearchTransactionsInput {
  empresaId: number;
  sucursalId?: number;
  providerCode?: string;
  sourceType?: string;
  sourceNumber?: string;
  status?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  limit?: number;
}

export async function searchTransactions(input: SearchTransactionsInput) {
  const conditions: string[] = ["t.EmpresaId = @empresaId"];
  const params: Record<string, unknown> = { empresaId: input.empresaId };

  if (input.sucursalId != null) {
    conditions.push("t.SucursalId = @sucursalId");
    params.sucursalId = input.sucursalId;
  }
  if (input.providerCode) {
    conditions.push("p.Code = @providerCode");
    params.providerCode = input.providerCode;
  }
  if (input.sourceType) {
    conditions.push("t.SourceType = @sourceType");
    params.sourceType = input.sourceType;
  }
  if (input.sourceNumber) {
    conditions.push("t.SourceNumber = @sourceNumber");
    params.sourceNumber = input.sourceNumber;
  }
  if (input.status) {
    conditions.push("t.Status = @status");
    params.status = input.status;
  }
  if (input.dateFrom) {
    conditions.push("t.CreatedAt >= @dateFrom");
    params.dateFrom = input.dateFrom;
  }
  if (input.dateTo) {
    conditions.push("t.CreatedAt <= @dateTo");
    params.dateTo = input.dateTo;
  }

  const where = conditions.join(" AND ");
  const page = input.page ?? 1;
  const limit = Math.min(input.limit ?? 50, 200);
  const offset = (page - 1) * limit;

  const rows = await query<any>(`
    SELECT t.*, p.Code AS ProviderCode, p.Name AS ProviderName
    FROM pay.Transactions t
    LEFT JOIN pay.PaymentProviders p ON p.Id = t.ProviderId
    WHERE ${where}
    ORDER BY t.CreatedAt DESC
    OFFSET ${offset} ROWS FETCH NEXT ${limit} ROWS ONLY
  `, params);

  const countResult = await query<{ total: number }>(`
    SELECT COUNT(1) AS total
    FROM pay.Transactions t
    LEFT JOIN pay.PaymentProviders p ON p.Id = t.ProviderId
    WHERE ${where}
  `, params);

  return {
    rows,
    total: countResult[0]?.total ?? 0,
    page,
    limit,
  };
}
