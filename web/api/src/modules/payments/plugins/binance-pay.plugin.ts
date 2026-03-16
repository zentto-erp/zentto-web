/**
 * Binance Pay — Payment Plugin
 *
 * Binance Pay API for crypto payments (USDT, BTC, BNB, etc.)
 * Works globally — no country restriction.
 *
 * Endpoints:
 *   Create Order:  POST /binancepay/openapi/v2/order
 *   Query Order:   POST /binancepay/openapi/v2/order/query
 *   Close Order:   POST /binancepay/openapi/v2/order/close
 *   Refund:        POST /binancepay/openapi/v3/order/refund
 *
 * Auth: HMAC-SHA512 signature
 *   Header: BinancePay-Timestamp, BinancePay-Nonce, BinancePay-Certificate-SN, BinancePay-Signature
 *
 * Docs: https://developers.binance.com/docs/binance-pay
 */

import { createHmac, randomBytes } from "node:crypto";
import type {
  IPaymentPlugin,
  CompanyPaymentConfig,
  GatewayRequest,
  GatewayResponse,
  ConfigField,
} from "../types.js";

export class BinancePayPlugin implements IPaymentPlugin {
  providerCode = "BINANCE";

  private readonly BASE_URL = "https://bpay.binanceapi.com";

  async execute(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    switch (request.capability) {
      case "SALE":
        return this.createOrder(config, request);
      case "VOID":
        return this.closeOrder(config, request);
      case "REFUND":
        return this.refundOrder(config, request);
      case "SEARCH":
        return this.queryOrder(config, request);
      default:
        return { success: false, status: "ERROR", message: `Unsupported: ${request.capability}` };
    }
  }

  private async createOrder(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    // Map currency to Binance Pay currency
    const currency = request.currency === "USDT" ? "USDT"
      : request.currency === "BTC" ? "BTC"
      : "USDT"; // Default to USDT for fiat

    const body = {
      env: {
        terminalType: "WEB",
      },
      merchantTradeNo: `DQB-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      orderAmount: request.amount,
      currency,
      goods: {
        goodsType: "02", // Virtual goods
        goodsCategory: "Z000", // Others
        referenceGoodsId: request.invoiceNumber || "N/A",
        goodsName: `DatqBox Payment - ${request.invoiceNumber || "Order"}`,
      },
    };

    const data = await this.doRequest(config, "/binancepay/openapi/v2/order", body);

    if (data?.status === "SUCCESS" && data?.data) {
      return {
        success: true,
        transactionId: data.data.prepayId || data.data.merchantTradeNo,
        status: "PROCESSING", // User needs to complete payment in Binance
        message: "Order created — awaiting payment",
        qrData: data.data.qrcodeLink || data.data.universalUrl,
        providerRawResponse: data,
      };
    }

    return {
      success: false,
      status: "ERROR",
      message: data?.errorMessage || "Binance Pay order creation failed",
      providerRawResponse: data,
    };
  }

  private async queryOrder(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    const body = {
      merchantTradeNo: request.extra?.merchantTradeNo || "",
      prepayId: request.extra?.prepayId || "",
    };

    const data = await this.doRequest(config, "/binancepay/openapi/v2/order/query", body);

    const orderStatus = data?.data?.status;
    const statusMap: Record<string, any> = {
      INITIAL: "PENDING",
      PENDING: "PROCESSING",
      PAID: "APPROVED",
      CANCELED: "VOIDED",
      ERROR: "ERROR",
      REFUNDING: "PROCESSING",
      REFUNDED: "REFUNDED",
      EXPIRED: "DECLINED",
    };

    return {
      success: orderStatus === "PAID",
      transactionId: data?.data?.prepayId,
      status: statusMap[orderStatus] || "PENDING",
      message: `Order status: ${orderStatus}`,
      providerRawResponse: data,
    };
  }

  private async closeOrder(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    const body = {
      merchantTradeNo: request.extra?.merchantTradeNo || "",
      prepayId: request.extra?.prepayId || "",
    };

    const data = await this.doRequest(config, "/binancepay/openapi/v2/order/close", body);

    return {
      success: data?.status === "SUCCESS",
      status: data?.status === "SUCCESS" ? "VOIDED" : "ERROR",
      message: data?.errorMessage || "Order closed",
      providerRawResponse: data,
    };
  }

  private async refundOrder(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    const body = {
      refundRequestId: `REF-${Date.now()}`,
      prepayId: request.extra?.prepayId || "",
      refundAmount: request.amount,
      refundReason: request.extra?.reason || "Customer refund",
    };

    const data = await this.doRequest(config, "/binancepay/openapi/v3/order/refund", body);

    return {
      success: data?.status === "SUCCESS",
      status: data?.status === "SUCCESS" ? "REFUNDED" : "ERROR",
      message: data?.errorMessage || "Refund processed",
      providerRawResponse: data,
    };
  }

  // ── HMAC-SHA512 signing ────────────────────────────────────

  private async doRequest(config: CompanyPaymentConfig, path: string, body: unknown): Promise<any> {
    const timestamp = Date.now().toString();
    const nonce = randomBytes(16).toString("hex");
    const bodyStr = JSON.stringify(body);

    // Payload = timestamp + \n + nonce + \n + body
    const payload = `${timestamp}\n${nonce}\n${bodyStr}\n`;
    const signature = createHmac("sha512", config.clientSecret!)
      .update(payload)
      .digest("hex")
      .toUpperCase();

    const response = await fetch(`${this.BASE_URL}${path}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "BinancePay-Timestamp": timestamp,
        "BinancePay-Nonce": nonce,
        "BinancePay-Certificate-SN": config.clientId!, // API Key
        "BinancePay-Signature": signature,
      },
      body: bodyStr,
      signal: AbortSignal.timeout(30_000),
    });

    return response.json();
  }

  async search(config: CompanyPaymentConfig, criteria: Record<string, unknown>): Promise<unknown[]> {
    const data = await this.doRequest(config, "/binancepay/openapi/v2/order/query", criteria);
    return data?.data ? [data.data] : [];
  }

  validateConfig(config: CompanyPaymentConfig): string[] {
    const errors: string[] = [];
    if (!config.clientId) errors.push("clientId (Binance Pay API Key) is required");
    if (!config.clientSecret) errors.push("clientSecret (Binance Pay Secret Key) is required");
    if (!config.merchantId) errors.push("merchantId (Binance Pay Merchant ID) is required");
    return errors;
  }

  getConfigFields(): ConfigField[] {
    return [
      { key: "clientId", label: "API Key", type: "password", required: true, helpText: "Binance Pay API Key (Certificate SN)" },
      { key: "clientSecret", label: "Secret Key", type: "password", required: true, helpText: "Binance Pay Secret Key for HMAC" },
      { key: "merchantId", label: "Merchant ID", type: "text", required: true, helpText: "Binance Pay Merchant ID" },
      {
        key: "extraConfig.defaultCrypto", label: "Crypto por defecto", type: "select", required: false,
        options: [
          { value: "USDT", label: "USDT (Tether)" },
          { value: "BTC", label: "Bitcoin" },
          { value: "BNB", label: "BNB" },
          { value: "BUSD", label: "BUSD" },
        ],
      },
    ];
  }
}
