/**
 * Mercantil Banco — Payment Plugin
 *
 * Endpoints (Banco Mercantil, Venezuela):
 *   C2P:  POST /payment/c2p          (compra, vuelto, anulación)
 *   SCP:  POST /mobile-payment/scp   (solicitud clave de pago)
 *   Search C2P: POST /mobile-payment/search
 *   TDC:  POST /payment/pay          (tarjeta crédito)
 *   TDD:  POST /payment/pay          (tarjeta débito, requiere getauth)
 *   Auth: POST /payment/getauth      (2FA para débito)
 *   Search cards: POST /payment/search
 *   Transfer search: POST /payment/transfer-search
 *
 * Auth: Header X-IBM-Client-ID
 * Sandbox: https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1
 * Prod:    https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1
 *
 * Encrypted fields use RSA-OAEP with Mercantil's public key.
 * See: https://github.com/apimercantil/encrypt-examples
 */

import type {
  IPaymentPlugin,
  CompanyPaymentConfig,
  GatewayRequest,
  GatewayResponse,
  ConfigField,
} from "../types.js";

export class MercantilPlugin implements IPaymentPlugin {
  providerCode = "MERCANTIL";

  private getBaseUrl(config: CompanyPaymentConfig): string {
    return config.environment === "production"
      ? "https://apimbu.mercantilbanco.com/mercantil-banco/produccion/v1"
      : "https://apimbu.mercantilbanco.com/mercantil-banco/sandbox/v1";
  }

  private buildMerchantIdentify(config: CompanyPaymentConfig) {
    return {
      integratorId: Number(config.integratorId) || 0,
      merchantId: Number(config.merchantId) || 0,
      terminalId: config.terminalId || "",
    };
  }

  private buildClientIdentify(req: GatewayRequest) {
    return {
      ipaddress: req.clientInfo?.ipAddress || "127.0.0.1",
      browser_agent: req.clientInfo?.browserAgent || "DatqBox POS",
      mobile: {
        manufacturer: req.clientInfo?.mobile?.manufacturer || "Generic",
      },
    };
  }

  async execute(config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    const baseUrl = this.getBaseUrl(config);

    switch (request.capability) {
      case "SALE":
        if (request.paymentMethodCode === "C2P") {
          return this.c2pTransaction(baseUrl, config, request, "compra");
        }
        // TDC / TDD
        return this.cardTransaction(baseUrl, config, request);

      case "REFUND":
        if (request.paymentMethodCode === "C2P") {
          return this.c2pTransaction(baseUrl, config, request, "vuelto");
        }
        return { success: false, status: "ERROR", message: "Refund not supported for this method via Mercantil" };

      case "VOID":
        if (request.paymentMethodCode === "C2P") {
          return this.c2pTransaction(baseUrl, config, request, "anulacion");
        }
        return { success: false, status: "ERROR", message: "Void not supported for this method via Mercantil" };

      case "SCP":
        return this.solicitarClavePago(baseUrl, config, request);

      case "AUTH":
        return this.getAuth(baseUrl, config, request);

      case "SEARCH":
        return this.searchAsResponse(baseUrl, config, request);

      default:
        return { success: false, status: "ERROR", message: `Unsupported capability: ${request.capability}` };
    }
  }

  // ── C2P (Pago Móvil) ───────────────────────────────────────

  private async c2pTransaction(
    baseUrl: string,
    config: CompanyPaymentConfig,
    request: GatewayRequest,
    trxType: "compra" | "vuelto" | "anulacion"
  ): Promise<GatewayResponse> {
    const body = {
      merchant_identify: this.buildMerchantIdentify(config),
      client_identify: this.buildClientIdentify(request),
      transaction_c2p: {
        amount: request.amount,
        currency: (request.currency || "ves").toLowerCase(),
        destination_bank_id: request.mobile?.destinationBankId || "",
        destination_id: request.mobile?.destinationId || "",
        destination_mobile_number: request.mobile?.destinationNumber || "",
        origin_mobile_number: request.mobile?.originNumber || "",
        payment_reference: request.extra?.paymentReference || "",
        trx_type: trxType,
        payment_method: trxType === "vuelto" ? "p2p" : "c2p",
        invoice_number: request.invoiceNumber || "",
        twofactor_auth: request.mobile?.twoFactorAuth || "",
      },
    };

    return this.doRequest(`${baseUrl}/payment/c2p`, config.clientId!, body);
  }

  // ── Solicitud Clave de Pago ─────────────────────────────────

  private async solicitarClavePago(
    baseUrl: string,
    config: CompanyPaymentConfig,
    request: GatewayRequest
  ): Promise<GatewayResponse> {
    const body = {
      merchant_identify: this.buildMerchantIdentify(config),
      client_identify: this.buildClientIdentify(request),
      transaction_scpInfo: {
        destination_id: request.mobile?.destinationId || "",
        destination_mobile_number: request.mobile?.destinationNumber || "",
      },
    };

    const result = await this.doRequest(`${baseUrl}/mobile-payment/scp`, config.clientId!, body);
    return { ...result, keySent: result.success };
  }

  // ── Card Payment (TDC/TDD) ─────────────────────────────────

  private async cardTransaction(
    baseUrl: string,
    config: CompanyPaymentConfig,
    request: GatewayRequest
  ): Promise<GatewayResponse> {
    const method = request.paymentMethodCode === "TDD" ? "tdc" : "tdc"; // Mercantil uses "tdc" for payment_method in body
    const body = {
      merchant_identify: this.buildMerchantIdentify(config),
      client_identify: this.buildClientIdentify(request),
      transaction: {
        trx_type: "compra",
        payment_method: request.paymentMethodCode.toLowerCase(),
        customer_id: request.mobile?.destinationId || "",
        card_number: request.card?.number || "",
        expiration_date: request.card?.expirationDate || "",
        cvv: request.card?.cvv || "",
        ...(request.paymentMethodCode === "TDD" ? {
          twofactor_auth: request.mobile?.twoFactorAuth || "",
          account_type: request.extra?.accountType || "cc",
        } : {}),
        invoice_number: request.invoiceNumber || "",
        currency: (request.currency || "ves").toLowerCase(),
        amount: request.amount,
      },
    };

    return this.doRequest(`${baseUrl}/payment/pay`, config.clientId!, body);
  }

  // ── Get Auth (2FA for TDD) ─────────────────────────────────

  private async getAuth(
    baseUrl: string,
    config: CompanyPaymentConfig,
    request: GatewayRequest
  ): Promise<GatewayResponse> {
    const body = {
      merchant_identify: this.buildMerchantIdentify(config),
      client_identify: this.buildClientIdentify(request),
      transaction_authInfo: {
        trx_type: "solaut",
        payment_method: "tdd",
        customer_id: request.mobile?.destinationId || "",
        card_number: request.card?.number || "",
      },
    };

    const result = await this.doRequest(`${baseUrl}/payment/getauth`, config.clientId!, body);
    return { ...result, keySent: result.success };
  }

  // ── Search ─────────────────────────────────────────────────

  private async searchAsResponse(
    baseUrl: string,
    config: CompanyPaymentConfig,
    request: GatewayRequest
  ): Promise<GatewayResponse> {
    let endpoint: string;
    let body: Record<string, unknown>;

    if (request.paymentMethodCode === "C2P") {
      endpoint = `${baseUrl}/mobile-payment/search`;
      body = {
        merchant_identify: this.buildMerchantIdentify(config),
        client_identify: this.buildClientIdentify(request),
        search_by: {
          amount: request.amount,
          currency: (request.currency || "ves").toLowerCase(),
          destinantion_mobile_number: request.mobile?.destinationNumber || "",
          origin_mobile_number: request.mobile?.originNumber || "",
          payment_reference: request.extra?.paymentReference || "",
          trx_date: request.extra?.trxDate || "",
        },
      };
    } else if (request.paymentMethodCode === "TRANSFER") {
      endpoint = `${baseUrl}/payment/transfer-search`;
      body = {
        merchantIdentify: this.buildMerchantIdentify(config),
        clientIdentify: {
          ipAddress: request.clientInfo?.ipAddress || "127.0.0.1",
          browserAgent: request.clientInfo?.browserAgent || "DatqBox POS",
          mobile: { manufacturer: "Generic" },
        },
        transferSearchBy: {
          account: request.transfer?.account || "",
          issuerCustomerId: request.transfer?.issuerCustomerId || "",
          trxDate: request.transfer?.trxDate || "",
          issuerBankId: request.transfer?.issuerBankId || "",
          transactionType: request.transfer?.transactionType || 1,
          paymentReference: request.transfer?.paymentReference || "",
          amount: request.amount,
        },
      };
    } else {
      endpoint = `${baseUrl}/payment/search`;
      body = {
        merchant_identify: this.buildMerchantIdentify(config),
        client_identify: this.buildClientIdentify(request),
        search_by: {
          search_criteria: "unique",
          procesing_date: request.extra?.trxDate || "",
          invoice_number: request.invoiceNumber || "",
          payment_reference: request.extra?.paymentReference || "",
        },
      };
    }

    return this.doRequest(endpoint, config.clientId!, body);
  }

  // ── HTTP helper ────────────────────────────────────────────

  private async doRequest(url: string, clientId: string, body: unknown): Promise<GatewayResponse> {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-IBM-Client-ID": clientId,
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(30_000),
    });

    const text = await response.text();
    let data: any;
    try {
      data = JSON.parse(text);
    } catch {
      data = { raw: text };
    }

    const isSuccess = response.ok && (data?.status === "approved" || data?.status === "0" || data?.resultCode === "00");

    return {
      success: isSuccess,
      transactionId: data?.transactionId || data?.id || data?.payment_reference || undefined,
      authCode: data?.authorizationCode || data?.auth_code || undefined,
      status: isSuccess ? "APPROVED" : response.ok ? "DECLINED" : "ERROR",
      message: data?.message || data?.description || `HTTP ${response.status}`,
      providerRawResponse: data,
    };
  }

  // ── Search (for reconciliation) ────────────────────────────

  async search(config: CompanyPaymentConfig, criteria: Record<string, unknown>): Promise<unknown[]> {
    // Delegate to searchAsResponse and return raw
    const baseUrl = this.getBaseUrl(config);
    const endpoint = criteria.type === "c2p"
      ? `${baseUrl}/mobile-payment/search`
      : criteria.type === "transfer"
        ? `${baseUrl}/payment/transfer-search`
        : `${baseUrl}/payment/search`;

    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-IBM-Client-ID": config.clientId!,
      },
      body: JSON.stringify(criteria.body),
      signal: AbortSignal.timeout(30_000),
    });

    const data = await response.json() as any;
    return Array.isArray(data) ? data : data?.transactions || data?.results || [data];
  }

  // ── Config validation ──────────────────────────────────────

  validateConfig(config: CompanyPaymentConfig): string[] {
    const errors: string[] = [];
    if (!config.clientId) errors.push("clientId (X-IBM-Client-ID) is required");
    if (!config.merchantId) errors.push("merchantId is required");
    if (!config.terminalId) errors.push("terminalId is required");
    if (!config.integratorId) errors.push("integratorId is required");
    return errors;
  }

  getConfigFields(): ConfigField[] {
    return [
      { key: "clientId", label: "X-IBM-Client-ID", type: "password", required: true, helpText: "API Key from Mercantil developer portal" },
      { key: "integratorId", label: "Integrator ID", type: "text", required: true, helpText: "Assigned by Mercantil" },
      { key: "merchantId", label: "Merchant ID", type: "text", required: true, helpText: "Commerce identifier" },
      { key: "terminalId", label: "Terminal ID", type: "text", required: true, helpText: "Terminal identifier (POS station)" },
      {
        key: "environment", label: "Entorno", type: "select", required: true,
        options: [
          { value: "sandbox", label: "Sandbox (Pruebas)" },
          { value: "production", label: "Producción" },
        ],
      },
    ];
  }
}
