/**
 * Manual Payment Plugin — for offline / non-gateway payment methods.
 *
 * Handles: Cash, manual transfers, cheques, credit/fiado, Zelle (manual verification).
 * These don't talk to an external API — they just record the transaction as APPROVED.
 */

import type {
  IPaymentPlugin,
  CompanyPaymentConfig,
  GatewayRequest,
  GatewayResponse,
  ConfigField,
} from "../types.js";

export class ManualPlugin implements IPaymentPlugin {
  providerCode = "MANUAL";

  async execute(_config: CompanyPaymentConfig, request: GatewayRequest): Promise<GatewayResponse> {
    // Manual payments are always approved immediately (operator confirms)
    return {
      success: true,
      transactionId: `MAN-${Date.now()}`,
      status: "APPROVED",
      message: `Pago ${request.paymentMethodCode} registrado manualmente`,
    };
  }

  async search(): Promise<unknown[]> {
    return []; // No external search for manual payments
  }

  validateConfig(): string[] {
    return []; // No config needed
  }

  getConfigFields(): ConfigField[] {
    return []; // No fields needed
  }
}
