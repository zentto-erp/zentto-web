import { getCountryKnowledge, getDefaultFiscalConfig } from "../knowledge-base.js";
import {
  CountryCode,
  FiscalConfig,
  FiscalRecord,
  IFiscalPlugin,
  TaxRate,
  InvoiceType,
  ValidationResult
} from "../types.js";

export class VenezuelaFiscalPlugin implements IFiscalPlugin {
  countryCode: CountryCode = "VE";

  getTaxRates(): TaxRate[] {
    return getCountryKnowledge("VE").taxes;
  }

  getInvoiceTypes(): InvoiceType[] {
    return getCountryKnowledge("VE").invoiceTypes;
  }

  getDefaultConfig(): Partial<FiscalConfig> {
    return getDefaultFiscalConfig("VE");
  }

  async buildFiscalRecord(invoice: unknown, previousRecord?: FiscalRecord): Promise<FiscalRecord> {
    const hashSeed = JSON.stringify(invoice) + (previousRecord?.hash ?? "");
    const hash = Buffer.from(hashSeed).toString("base64").slice(0, 64);
    return {
      id: `VE-${Date.now()}`,
      invoiceId: Number((invoice as any)?.id ?? 0),
      countryCode: "VE",
      type: String((invoice as any)?.type ?? "FACTURA"),
      hash,
      previousHash: previousRecord?.hash,
      sentToAuthority: false,
      authorityResponse: "pending_fiscal_printer",
      createdAt: new Date()
    };
  }

  validateInvoice(invoice: unknown): ValidationResult {
    const errors: string[] = [];
    const payload = (invoice as Record<string, unknown>) ?? {};
    if (!payload || typeof payload !== "object") {
      errors.push("invoice_invalid_payload");
    }
    if (!payload["type"]) {
      errors.push("invoice_missing_type");
    }
    return { valid: errors.length === 0, errors };
  }

  async buildCancellationRecord(originalRecord: FiscalRecord, reason: string): Promise<FiscalRecord> {
    return {
      id: `VE-CANCEL-${Date.now()}`,
      invoiceId: originalRecord.invoiceId,
      countryCode: "VE",
      type: "NOTA_CREDITO",
      hash: Buffer.from(`${originalRecord.hash}:${reason}`).toString("base64").slice(0, 64),
      previousHash: originalRecord.hash,
      sentToAuthority: false,
      authorityResponse: "pending_fiscal_printer_cancel",
      createdAt: new Date()
    };
  }
}
