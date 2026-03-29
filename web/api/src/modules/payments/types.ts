/**
 * DatqBox Payment Gateway — Core Types & Interfaces
 *
 * Multi-country, multi-provider payment abstraction.
 * Applies to POS, Restaurant, Web, and any sales channel.
 */

// ── Country & Currency ──────────────────────────────────────────

export type CountryCode = "VE" | "ES" | "US" | "CO" | "MX" | "AR" | "CL" | "PE";

export type CurrencyCode = "VES" | "EUR" | "USD" | "USDT" | "BTC" | "COP" | "MXN" | "ARS" | "CLP" | "PEN";

// ── Payment Method ──────────────────────────────────────────────

export type PaymentCategory =
  | "CASH"
  | "CARD"
  | "MOBILE"
  | "TRANSFER"
  | "CRYPTO"
  | "DIGITAL_WALLET"
  | "QR"
  | "OTHER";

export interface PaymentMethod {
  id: number;
  code: string;
  name: string;
  category: PaymentCategory;
  countryCode: CountryCode | null;
  iconName: string | null;
  requiresGateway: boolean;
  isActive: boolean;
  sortOrder: number;
}

// ── Provider ────────────────────────────────────────────────────

export type ProviderType =
  | "BANK_API"
  | "CARD_PROCESSOR"
  | "CRYPTO_EXCHANGE"
  | "PAYMENT_GATEWAY"
  | "MANUAL";

export type AuthType = "API_KEY" | "OAUTH2" | "HMAC" | "CERT" | "BASIC" | "NONE";

export interface PaymentProvider {
  id: number;
  code: string;
  name: string;
  countryCode: CountryCode | null;
  providerType: ProviderType;
  baseUrlSandbox: string | null;
  baseUrlProd: string | null;
  authType: AuthType | null;
  docsUrl: string | null;
  logoUrl: string | null;
  isActive: boolean;
}

// ── Provider Capability ─────────────────────────────────────────

export type CapabilityType =
  | "SALE"
  | "REFUND"
  | "VOID"
  | "AUTH"
  | "CAPTURE"
  | "SEARCH"
  | "RECONCILE"
  | "QR_GENERATE"
  | "SCP"          // Solicitud Clave de Pago (Mercantil)
  | "TOKENIZE";

export interface ProviderCapability {
  id: number;
  providerId: number;
  capability: CapabilityType;
  paymentMethod: string | null;
  endpointPath: string | null;
  httpMethod: string;
  isActive: boolean;
}

// ── Company Config ──────────────────────────────────────────────

export type GatewayEnvironment = "sandbox" | "production";

export interface CompanyPaymentConfig {
  id: number;
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
  providerId: number;
  environment: GatewayEnvironment;

  // Credentials (encrypted at rest)
  clientId: string | null;
  clientSecret: string | null;
  merchantId: string | null;
  terminalId: string | null;
  integratorId: string | null;
  certificatePath: string | null;
  extraConfig: Record<string, unknown> | null;

  autoCapture: boolean;
  allowRefunds: boolean;
  maxRefundDays: number;
  isActive: boolean;
}

export interface CompanyPaymentConfigInput {
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
  providerCode: string;
  environment: GatewayEnvironment;
  clientId?: string;
  clientSecret?: string;
  merchantId?: string;
  terminalId?: string;
  integratorId?: string;
  certificatePath?: string;
  extraConfig?: Record<string, unknown>;
  autoCapture?: boolean;
  allowRefunds?: boolean;
  maxRefundDays?: number;
}

// ── Accepted Methods per Company ────────────────────────────────

export interface AcceptedPaymentMethod {
  id: number;
  empresaId: number;
  sucursalId: number;
  paymentMethodId: number;
  providerId: number | null;
  appliesToPOS: boolean;
  appliesToWeb: boolean;
  appliesToRestaurant: boolean;
  minAmount: number | null;
  maxAmount: number | null;
  commissionPct: number | null;
  commissionFixed: number | null;
  isActive: boolean;
  sortOrder: number;

  // Joined fields
  methodCode?: string;
  methodName?: string;
  methodCategory?: PaymentCategory;
  iconName?: string | null;
  providerCode?: string;
  providerName?: string;
}

// ── Transaction ─────────────────────────────────────────────────

export type TransactionType = "SALE" | "REFUND" | "VOID" | "AUTH" | "CAPTURE";

export type TransactionStatus =
  | "PENDING"
  | "PROCESSING"
  | "APPROVED"
  | "DECLINED"
  | "ERROR"
  | "VOIDED"
  | "REFUNDED";

export type SourceType =
  | "FACTURA"
  | "TICKET_POS"
  | "TICKET_REST"
  | "COBRO"
  | "ABONO"
  | "PEDIDO_WEB";

export interface PaymentTransaction {
  id: number;
  transactionUUID: string;
  empresaId: number;
  sucursalId: number;

  sourceType: SourceType;
  sourceId: number | null;
  sourceNumber: string | null;

  paymentMethodCode: string;
  providerId: number | null;

  currency: CurrencyCode;
  amount: number;
  commissionAmount: number | null;
  netAmount: number | null;
  exchangeRate: number | null;
  amountInBase: number | null;

  trxType: TransactionType;
  status: TransactionStatus;

  gatewayTrxId: string | null;
  gatewayAuthCode: string | null;
  gatewayResponse: Record<string, unknown> | null;
  gatewayMessage: string | null;

  cardLastFour: string | null;
  cardBrand: string | null;

  mobileNumber: string | null;
  bankCode: string | null;
  paymentRef: string | null;

  isReconciled: boolean;
  reconciledAt: string | null;

  stationId: string | null;
  cashierId: string | null;
  ipAddress: string | null;
  notes: string | null;

  createdAt: string;
  updatedAt: string;
}

// ── Gateway Request / Response ──────────────────────────────────

export interface GatewayRequest {
  /** Which capability to invoke */
  capability: CapabilityType;

  /** Payment method to use */
  paymentMethodCode: string;

  /** Amount */
  amount: number;
  currency: CurrencyCode;

  /** Invoice / ticket reference */
  invoiceNumber?: string;

  /** Card data (if card payment via reader or manual) */
  card?: {
    number: string;       // Encrypted or tokenized
    expirationDate: string;
    cvv: string;          // Encrypted
    holderName?: string;
  };

  /** Mobile payment data (C2P, Bizum) */
  mobile?: {
    originNumber: string;
    destinationNumber?: string;  // Encrypted
    destinationId?: string;      // Encrypted (cédula)
    destinationBankId?: string;
    twoFactorAuth?: string;      // Encrypted (clave temporal)
  };

  /** Transfer search data */
  transfer?: {
    account?: string;
    issuerCustomerId?: string;
    issuerBankId?: string;
    transactionType?: number;
    paymentReference?: string;
    trxDate?: string;
  };

  /** Crypto payment data */
  crypto?: {
    walletAddress?: string;
    network?: string;           // 'TRC20','ERC20','BEP20'
    txHash?: string;
  };

  /** Client identification */
  clientInfo?: {
    ipAddress: string;
    browserAgent: string;
    mobile?: {
      manufacturer?: string;
      model?: string;
      osVersion?: string;
      location?: { lat: number; lng: number };
    };
  };

  /** Extra provider-specific fields */
  extra?: Record<string, unknown>;
}

export interface GatewayResponse {
  success: boolean;
  transactionId?: string;
  authCode?: string;
  status: TransactionStatus;
  message: string;
  providerRawResponse?: unknown;

  /** For QR payments — the QR data/image to display */
  qrData?: string;

  /** For SCP — whether the key was sent */
  keySent?: boolean;
}

// ── Plugin Interface (Strategy Pattern) ─────────────────────────

export interface IPaymentPlugin {
  providerCode: string;

  /** Process a payment/auth/refund/void through the provider */
  execute(
    config: CompanyPaymentConfig,
    request: GatewayRequest
  ): Promise<GatewayResponse>;

  /** Search transactions in the provider's system */
  search(
    config: CompanyPaymentConfig,
    criteria: Record<string, unknown>
  ): Promise<unknown[]>;

  /** Validate that the config has all required fields */
  validateConfig(config: CompanyPaymentConfig): string[];

  /** Return required config fields for the UI */
  getConfigFields(): ConfigField[];
}

export interface ConfigField {
  key: string;
  label: string;
  type: "text" | "password" | "select" | "number" | "boolean" | "json";
  required: boolean;
  placeholder?: string;
  helpText?: string;
  options?: { value: string; label: string }[];
}

// ── Card Reader ─────────────────────────────────────────────────

export type DeviceType = "PINPAD" | "CONTACTLESS" | "CHIP" | "MAGSTRIPE" | "ALL";

export type ConnectionType = "USB" | "SERIAL" | "BLUETOOTH" | "NETWORK" | "INTEGRATED";

export interface CardReaderDevice {
  id: number;
  empresaId: number;
  sucursalId: number;
  stationId: string;
  deviceName: string;
  deviceType: DeviceType;
  connectionType: ConnectionType;
  connectionConfig: Record<string, unknown> | null;
  providerId: number | null;
  isActive: boolean;
  lastSeenAt: string | null;
}

// ── Reconciliation ──────────────────────────────────────────────

export interface ReconciliationBatch {
  id: number;
  empresaId: number;
  providerId: number;
  dateFrom: string;
  dateTo: string;
  totalTransactions: number;
  totalAmount: number;
  matchedCount: number;
  unmatchedCount: number;
  status: "PENDING" | "IN_PROGRESS" | "COMPLETED" | "FAILED";
  resultJson: unknown | null;
  createdAt: string;
  completedAt: string | null;
  userId: string | null;
}
