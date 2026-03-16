export type CountryCode = string;

export interface AuthorityResponse {
  accepted: boolean;
  code?: string;
  message?: string;
  payload?: unknown;
}

export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings?: string[];
}

export interface FiscalConfig {
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
  currency: string;
  taxRegime: string;
  defaultTaxCode: string;
  defaultTaxRate: number;
  fiscalPrinterEnabled: boolean;
  printerBrand?: string;
  printerPort?: string;
  verifactuEnabled: boolean;
  verifactuMode: "auto" | "manual";
  certificatePath?: string;
  certificatePassword?: string;
  aeatEndpoint?: string;
  senderNIF?: string;
  senderRIF?: string;
  softwareId?: string;
  softwareName?: string;
  softwareVersion?: string;
  posEnabled: boolean;
  restaurantEnabled: boolean;
}

export interface TaxRate {
  code: string;
  name: string;
  rate: number;
  countryCode: CountryCode;
  appliesToPOS: boolean;
  appliesToRestaurant: boolean;
  isDefault: boolean;
  surchargeRate?: number;
}

export interface InvoiceType {
  code: string;
  name: string;
  countryCode: CountryCode;
  isRectificative: boolean;
  maxAmount?: number | null;
  requiresRecipientNIF: boolean;
  requiresFiscalPrinter?: boolean;
}

export interface FiscalRecord {
  id: string;
  invoiceId: number;
  countryCode: CountryCode;
  type: string;
  xmlContent?: string;
  hash: string;
  previousHash?: string;
  signature?: string;
  qrCode?: string;
  sentToAuthority: boolean;
  authorityResponse?: string;
  createdAt: Date;
}

export interface FiscalTransactionInput {
  empresaId?: number;
  sucursalId?: number;
  countryCode?: CountryCode;
  sourceModule: "POS" | "RESTAURANTE" | "VENTAS";
  invoiceId: number;
  invoiceNumber: string;
  invoiceDate?: string | Date;
  invoiceTypeHint?: string;
  recipientId?: string;
  totalAmount: number;
  payload?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
}

export interface FiscalTransactionResult {
  ok: boolean;
  skipped?: boolean;
  reason?: string;
  countryCode?: CountryCode;
  recordId?: string;
  hash?: string;
  authorityStatus?: string;
  sentToAuthority?: boolean;
}

export interface IFiscalPlugin {
  countryCode: CountryCode;
  getTaxRates(): TaxRate[];
  getInvoiceTypes(): InvoiceType[];
  getDefaultConfig(): Partial<FiscalConfig>;
  buildFiscalRecord(invoice: unknown, previousRecord?: FiscalRecord): Promise<FiscalRecord>;
  submitToAuthority?(record: FiscalRecord): Promise<AuthorityResponse>;
  validateInvoice(invoice: unknown): ValidationResult;
  generateQRData?(record: FiscalRecord): string;
  buildCancellationRecord(originalRecord: FiscalRecord, reason: string): Promise<FiscalRecord>;
}

export interface RegulatoryMilestone {
  key: string;
  date: string;
  description: string;
  sourceUrl: string;
}

export interface RegulatorySource {
  id: string;
  title: string;
  authority: string;
  type: string;
  url: string;
  publishedDate?: string;
  notes?: string;
}

export interface CountryProfile {
  code: CountryCode;
  name: string;
  currency: string;
  currencySymbol: string;
  taxAuthority: string;
  taxAuthorityFullName: string;
  fiscalIdName: string;
  fiscalIdFormat: string;
  fiscalIdExample: string;
}

export interface FiscalRegulations {
  maxSimplifiedInvoiceAmountGeneral?: number | null;
  maxSimplifiedInvoiceAmountPosRestaurant?: number | null;
  requiresChainedRecords: boolean;
  requiresDigitalSignature: boolean;
  requiresQRCode: boolean;
  requiresElectronicSubmission: boolean;
  producerDeclarationRequired?: boolean;
}

export interface CountryKnowledge {
  country: CountryProfile;
  taxes: TaxRate[];
  invoiceTypes: InvoiceType[];
  regulations: FiscalRegulations;
  milestones: RegulatoryMilestone[];
  sources: RegulatorySource[];
  verifactu?: {
    enabled: boolean;
    modes: Array<"auto" | "manual">;
    hashAlgorithm: string;
    signatureType: string;
    certificateType: string;
    productionEndpoint: string;
    testingEndpoint: string;
    qrBaseUrlProduction: string;
    qrBaseUrlTesting: string;
  };
}
