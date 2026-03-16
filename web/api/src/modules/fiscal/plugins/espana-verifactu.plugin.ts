import { createHash } from "node:crypto";
import { getCountryKnowledge, getDefaultFiscalConfig } from "../knowledge-base.js";
import {
  CountryCode,
  FiscalConfig,
  FiscalRecord,
  IFiscalPlugin,
  TaxRate,
  InvoiceType,
  ValidationResult,
  AuthorityResponse
} from "../types.js";

export class EspanaVerifactuPlugin implements IFiscalPlugin {
  countryCode: CountryCode = "ES";

  getTaxRates(): TaxRate[] {
    return getCountryKnowledge("ES").taxes;
  }

  getInvoiceTypes(): InvoiceType[] {
    return getCountryKnowledge("ES").invoiceTypes;
  }

  getDefaultConfig(): Partial<FiscalConfig> {
    return getDefaultFiscalConfig("ES");
  }

  async buildFiscalRecord(invoice: unknown, previousRecord?: FiscalRecord): Promise<FiscalRecord> {
    const payload = (invoice as Record<string, unknown>) ?? {};
    const detailedPayload = (payload["payload"] as Record<string, unknown>) ?? {};
    const metadata = (payload["metadata"] as Record<string, unknown>) ?? {};
    const normalizedPayload = JSON.stringify({
      invoiceId: payload["id"] ?? payload["invoiceId"] ?? 0,
      number: payload["number"] ?? payload["invoiceNumber"] ?? "",
      type: payload["type"] ?? "F1",
      total: payload["total"] ?? payload["totalAmount"] ?? 0,
      breakdown: detailedPayload["fiscalBreakdown"] ?? null,
      metadata,
      previousHash: previousRecord?.hash ?? null
    });
    const hash = createHash("sha256").update(normalizedPayload).digest("hex");
    return {
      id: `ES-${Date.now()}`,
      invoiceId: Number(payload["id"] ?? payload["invoiceId"] ?? 0),
      countryCode: "ES",
      type: String(payload["type"] ?? "F1"),
      hash,
      previousHash: previousRecord?.hash,
      qrCode: this.generateQRData({
        id: "tmp",
        invoiceId: Number(payload["id"] ?? payload["invoiceId"] ?? 0),
        countryCode: "ES",
        type: String(payload["type"] ?? "F1"),
        hash,
        previousHash: previousRecord?.hash,
        sentToAuthority: false,
        createdAt: new Date()
      }),
      sentToAuthority: false,
      authorityResponse: "pending",
      createdAt: new Date()
    };
  }

  async submitToAuthority(record: FiscalRecord): Promise<AuthorityResponse> {
    return {
      accepted: false,
      code: "NOT_IMPLEMENTED",
      message: "Verifactu SOAP integration pending implementation",
      payload: { recordId: record.id }
    };
  }

  validateInvoice(invoice: unknown): ValidationResult {
    const payload = (invoice as Record<string, unknown>) ?? {};
    const errors: string[] = [];

    if (!payload || typeof payload !== "object") {
      errors.push("invoice_invalid_payload");
    }
    if (!payload["type"]) {
      errors.push("invoice_missing_type");
    }
    if (!payload["total"] && !payload["totalAmount"]) {
      errors.push("invoice_missing_total");
    }

    return { valid: errors.length === 0, errors };
  }

  generateQRData(record: FiscalRecord): string {
    const baseUrl = getCountryKnowledge("ES").verifactu?.qrBaseUrlTesting ??
      "https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR";
    const params = new URLSearchParams({
      numserie: String(record.invoiceId),
      ref: record.id,
      hash: record.hash
    });
    return `${baseUrl}?${params.toString()}`;
  }

  async buildCancellationRecord(originalRecord: FiscalRecord, reason: string): Promise<FiscalRecord> {
    const hash = createHash("sha256")
      .update(`${originalRecord.hash}:${reason}:${Date.now()}`)
      .digest("hex");
    return {
      id: `ES-CANCEL-${Date.now()}`,
      invoiceId: originalRecord.invoiceId,
      countryCode: "ES",
      type: "R1",
      hash,
      previousHash: originalRecord.hash,
      sentToAuthority: false,
      authorityResponse: "pending_cancel",
      createdAt: new Date()
    };
  }
}
