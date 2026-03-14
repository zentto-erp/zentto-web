/**
 * DatqBox Payment Gateway -- Engine
 *
 * Orchestrates payment processing: resolves the provider plugin,
 * executes the gateway call, and records the transaction.
 */

import { randomUUID } from "node:crypto";
import { callSp } from "../../db/query.js";
import { getPlugin } from "./registry.js";
import type {
  CompanyPaymentConfig,
  GatewayRequest,
  GatewayResponse,
  TransactionStatus,
  SourceType,
  CurrencyCode,
} from "./types.js";

// -- Resolve active config for a company + provider --

async function resolveConfig(
  empresaId: number,
  sucursalId: number,
  providerCode: string
): Promise<CompanyPaymentConfig | null> {
  const rows = await callSp<any>('usp_Pay_Transaction_ResolveConfig', {
    EmpresaId: empresaId,
    SucursalId: sucursalId,
    ProviderCode: providerCode
  });

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

// -- Record transaction in DB --

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

  await callSp('usp_Pay_Transaction_Insert', {
    TransactionUUID: uuid,
    EmpresaId: p.empresaId,
    SucursalId: p.sucursalId,
    SourceType: p.sourceType,
    SourceId: p.sourceId ?? null,
    SourceNumber: p.sourceNumber ?? null,
    PaymentMethodCode: p.paymentMethodCode,
    ProviderId: p.providerId ?? null,
    Currency: p.currency,
    Amount: p.amount,
    TrxType: p.trxType,
    Status: p.status,
    GatewayTrxId: p.gatewayTrxId ?? null,
    GatewayAuthCode: p.gatewayAuthCode ?? null,
    GatewayResponse: p.gatewayResponse ? JSON.stringify(p.gatewayResponse) : null,
    GatewayMessage: p.gatewayMessage ?? null,
    CardLastFour: p.cardLastFour ?? null,
    CardBrand: p.cardBrand ?? null,
    MobileNumber: p.mobileNumber ?? null,
    BankCode: p.bankCode ?? null,
    PaymentRef: p.paymentRef ?? null,
    StationId: p.stationId ?? null,
    CashierId: p.cashierId ?? null,
    IpAddress: p.ipAddress ?? null,
  });

  return uuid;
}

async function updateTransactionStatus(uuid: string, status: TransactionStatus, gatewayFields?: Partial<RecordTrxParams>) {
  await callSp('usp_Pay_Transaction_UpdateStatus', {
    TransactionUUID: uuid,
    Status: status,
    GatewayTrxId: gatewayFields?.gatewayTrxId ?? null,
    GatewayAuthCode: gatewayFields?.gatewayAuthCode ?? null,
    GatewayResponse: gatewayFields?.gatewayResponse ? JSON.stringify(gatewayFields.gatewayResponse) : null,
    GatewayMessage: gatewayFields?.gatewayMessage ?? null,
  });
}

// -- Main Engine: processPayment --

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

// -- Search transactions --

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
  const page = input.page ?? 1;
  const limit = Math.min(input.limit ?? 50, 200);
  const offset = (page - 1) * limit;

  const spParams = {
    EmpresaId: input.empresaId,
    SucursalId: input.sucursalId ?? null,
    ProviderCode: input.providerCode ?? null,
    SourceType: input.sourceType ?? null,
    SourceNumber: input.sourceNumber ?? null,
    Status: input.status ?? null,
    DateFrom: input.dateFrom ?? null,
    DateTo: input.dateTo ?? null,
    Offset: offset,
    Limit: limit,
  };

  const rows = await callSp<any>('usp_Pay_Transaction_Search', spParams);
  const countResult = await callSp<{ total: number }>('usp_Pay_Transaction_SearchCount', {
    EmpresaId: input.empresaId,
    SucursalId: input.sucursalId ?? null,
    ProviderCode: input.providerCode ?? null,
    SourceType: input.sourceType ?? null,
    SourceNumber: input.sourceNumber ?? null,
    Status: input.status ?? null,
    DateFrom: input.dateFrom ?? null,
    DateTo: input.dateTo ?? null,
  });

  return {
    rows,
    total: countResult[0]?.total ?? 0,
    page,
    limit,
  };
}
