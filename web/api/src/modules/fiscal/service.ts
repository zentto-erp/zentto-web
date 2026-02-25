import { execute, query } from "../../db/query.js";
import { getFiscalPlugin } from "./engine.js";
import { fiscalKnowledgeByCountry, getCountryKnowledge, getDefaultFiscalConfig } from "./knowledge-base.js";
import { CountryCode, FiscalConfig, FiscalRecord, FiscalTransactionInput, FiscalTransactionResult } from "./types.js";

const memoryConfigStore = new Map<string, FiscalConfig>();

function buildStoreKey(empresaId: number, sucursalId: number, countryCode: CountryCode) {
  return `${empresaId}:${sucursalId}:${countryCode}`;
}

async function hasFiscalConfigTable(): Promise<boolean> {
  const rows = await query<{ hasTable: number }>(
    `
      SELECT CASE WHEN EXISTS(
          SELECT 1
          FROM sys.tables
          WHERE name = 'FiscalCountryConfig'
      ) THEN 1 ELSE 0 END AS hasTable
    `
  );
  return Number(rows?.[0]?.hasTable ?? 0) === 1;
}

async function hasFiscalRecordsTable(): Promise<boolean> {
  const rows = await query<{ hasTable: number }>(
    `
      SELECT CASE WHEN EXISTS(
          SELECT 1
          FROM sys.tables
          WHERE name = 'FiscalRecords'
      ) THEN 1 ELSE 0 END AS hasTable
    `
  );
  return Number(rows?.[0]?.hasTable ?? 0) === 1;
}

function normalizeCountryCode(countryCode: string | undefined): CountryCode {
  return countryCode?.toUpperCase() === "ES" ? "ES" : "VE";
}

function rowToFiscalConfig(row: Record<string, unknown>, fallbackCountryCode: CountryCode): FiscalConfig {
  return {
    empresaId: Number(row.EmpresaId ?? 1),
    sucursalId: Number(row.SucursalId ?? 0),
    countryCode: normalizeCountryCode(String(row.CountryCode ?? fallbackCountryCode)),
    currency: String(row.Currency ?? (fallbackCountryCode === "ES" ? "EUR" : "VES")),
    taxRegime: String(row.TaxRegime ?? ""),
    defaultTaxCode: String(row.DefaultTaxCode ?? ""),
    defaultTaxRate: Number(row.DefaultTaxRate ?? 0),
    fiscalPrinterEnabled: Number(row.FiscalPrinterEnabled ?? 0) === 1,
    printerBrand: row.PrinterBrand ? String(row.PrinterBrand) : undefined,
    printerPort: row.PrinterPort ? String(row.PrinterPort) : undefined,
    verifactuEnabled: Number(row.VerifactuEnabled ?? 0) === 1,
    verifactuMode: String(row.VerifactuMode ?? "manual") === "auto" ? "auto" : "manual",
    certificatePath: row.CertificatePath ? String(row.CertificatePath) : undefined,
    certificatePassword: row.CertificatePassword ? String(row.CertificatePassword) : undefined,
    aeatEndpoint: row.AEATEndpoint ? String(row.AEATEndpoint) : undefined,
    senderNIF: row.SenderNIF ? String(row.SenderNIF) : undefined,
    senderRIF: row.SenderRIF ? String(row.SenderRIF) : undefined,
    softwareId: row.SoftwareId ? String(row.SoftwareId) : undefined,
    softwareName: row.SoftwareName ? String(row.SoftwareName) : undefined,
    softwareVersion: row.SoftwareVersion ? String(row.SoftwareVersion) : undefined,
    posEnabled: Number(row.PosEnabled ?? 1) === 1,
    restaurantEnabled: Number(row.RestaurantEnabled ?? 1) === 1
  };
}

function mergeDefaults(partial: Partial<FiscalConfig> & { countryCode: CountryCode }): FiscalConfig {
  const defaults = getDefaultFiscalConfig(partial.countryCode);
  return {
    ...defaults,
    ...partial,
    countryCode: partial.countryCode,
    empresaId: Number(partial.empresaId ?? defaults.empresaId),
    sucursalId: Number(partial.sucursalId ?? defaults.sucursalId),
    defaultTaxRate: Number(partial.defaultTaxRate ?? defaults.defaultTaxRate),
    fiscalPrinterEnabled: Boolean(partial.fiscalPrinterEnabled ?? defaults.fiscalPrinterEnabled),
    verifactuEnabled: Boolean(partial.verifactuEnabled ?? defaults.verifactuEnabled),
    verifactuMode: partial.verifactuMode === "auto" ? "auto" : "manual",
    posEnabled: Boolean(partial.posEnabled ?? defaults.posEnabled),
    restaurantEnabled: Boolean(partial.restaurantEnabled ?? defaults.restaurantEnabled)
  };
}

function parseDateInput(value: string | Date | undefined): Date {
  if (!value) return new Date();
  const parsed = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(parsed.getTime())) return new Date();
  return parsed;
}

function normalizeInvoiceTypeByCountry(params: {
  countryCode: CountryCode;
  sourceModule: FiscalTransactionInput["sourceModule"];
  totalAmount: number;
  invoiceTypeHint?: string;
  recipientId?: string;
}) {
  const { countryCode, sourceModule, totalAmount, invoiceTypeHint, recipientId } = params;
  const hint = String(invoiceTypeHint ?? "").trim().toUpperCase();
  if (hint) return hint;

  if (countryCode === "VE") {
    return "FACTURA";
  }

  const knowledge = getCountryKnowledge("ES");
  const maxPosRest =
    Number(knowledge.regulations.maxSimplifiedInvoiceAmountPosRestaurant ?? 3000);
  const hasRecipient = String(recipientId ?? "").trim().length > 0;

  if ((sourceModule === "POS" || sourceModule === "RESTAURANTE") && totalAmount <= maxPosRest && !hasRecipient) {
    return "F2";
  }

  return "F1";
}

async function getLatestFiscalRecord(params: {
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
}): Promise<FiscalRecord | null> {
  if (!(await hasFiscalRecordsTable())) return null;

  const rows = await query<Record<string, unknown>>(
    `
      SELECT TOP 1
        Id,
        InvoiceId,
        CountryCode,
        InvoiceType,
        XmlContent,
        RecordHash,
        PreviousRecordHash,
        DigitalSignature,
        QRCodeData,
        SentToAuthority,
        AuthorityResponse,
        CreatedAt
      FROM FiscalRecords
      WHERE EmpresaId = @empresaId
        AND SucursalId = @sucursalId
        AND CountryCode = @countryCode
      ORDER BY Id DESC
    `,
    {
      empresaId: params.empresaId,
      sucursalId: params.sucursalId,
      countryCode: params.countryCode
    }
  );

  const row = rows[0];
  if (!row) return null;

  return {
    id: String(row.Id ?? ""),
    invoiceId: Number(row.InvoiceId ?? 0),
    countryCode: normalizeCountryCode(String(row.CountryCode ?? params.countryCode)),
    type: String(row.InvoiceType ?? ""),
    xmlContent: row.XmlContent ? String(row.XmlContent) : undefined,
    hash: String(row.RecordHash ?? ""),
    previousHash: row.PreviousRecordHash ? String(row.PreviousRecordHash) : undefined,
    signature: row.DigitalSignature ? String(row.DigitalSignature) : undefined,
    qrCode: row.QRCodeData ? String(row.QRCodeData) : undefined,
    sentToAuthority: Number(row.SentToAuthority ?? 0) === 1,
    authorityResponse: row.AuthorityResponse ? String(row.AuthorityResponse) : undefined,
    createdAt: new Date(String(row.CreatedAt ?? new Date().toISOString()))
  };
}

async function inferCountryCodeFromConfig(empresaId: number, sucursalId: number): Promise<CountryCode> {
  if (!(await hasFiscalConfigTable())) return "VE";
  const rows = await query<{ CountryCode: string }>(
    `
      SELECT TOP 1 CountryCode
      FROM FiscalCountryConfig
      WHERE EmpresaId = @empresaId
        AND SucursalId = @sucursalId
        AND IsActive = 1
      ORDER BY UpdatedAt DESC, Id DESC
    `,
    { empresaId, sucursalId }
  );
  return normalizeCountryCode(rows[0]?.CountryCode);
}

export function listCountries() {
  return Object.values(fiscalKnowledgeByCountry).map((country) => ({
    code: country.country.code,
    name: country.country.name,
    currency: country.country.currency,
    authority: country.country.taxAuthority,
    requiresFiscalPrinter: country.country.code === "VE",
    supportsVerifactu: country.country.code === "ES"
  }));
}

export function getCountryProfile(countryCode: CountryCode) {
  return getCountryKnowledge(countryCode);
}

export function getCountryTaxRates(countryCode: CountryCode) {
  return getCountryKnowledge(countryCode).taxes;
}

export function getCountryInvoiceTypes(countryCode: CountryCode) {
  return getCountryKnowledge(countryCode).invoiceTypes;
}

export function getCountryMilestones(countryCode: CountryCode) {
  return getCountryKnowledge(countryCode).milestones;
}

export function getCountrySources(countryCode: CountryCode) {
  return getCountryKnowledge(countryCode).sources;
}

export async function getFiscalConfig(params: {
  empresaId: number;
  sucursalId: number;
  countryCode: CountryCode;
}) {
  const { empresaId, sucursalId, countryCode } = params;
  const defaultConfig = getDefaultFiscalConfig(countryCode);

  if (!(await hasFiscalConfigTable())) {
    const key = buildStoreKey(empresaId, sucursalId, countryCode);
    const memoryConfig = memoryConfigStore.get(key);
    return memoryConfig ? mergeDefaults(memoryConfig) : { ...defaultConfig, empresaId, sucursalId };
  }

  const rows = await query<Record<string, unknown>>(
    `
      SELECT TOP 1
        EmpresaId,
        SucursalId,
        CountryCode,
        Currency,
        TaxRegime,
        DefaultTaxCode,
        DefaultTaxRate,
        FiscalPrinterEnabled,
        PrinterBrand,
        PrinterPort,
        VerifactuEnabled,
        VerifactuMode,
        CertificatePath,
        CertificatePassword,
        AEATEndpoint,
        SenderNIF,
        SenderRIF,
        SoftwareId,
        SoftwareName,
        SoftwareVersion,
        PosEnabled,
        RestaurantEnabled
      FROM FiscalCountryConfig
      WHERE EmpresaId = @empresaId
        AND SucursalId = @sucursalId
        AND CountryCode = @countryCode
    `,
    { empresaId, sucursalId, countryCode }
  );

  if (!rows.length) {
    return { ...defaultConfig, empresaId, sucursalId };
  }

  return mergeDefaults(rowToFiscalConfig(rows[0], countryCode));
}

export async function upsertFiscalConfig(input: Partial<FiscalConfig> & {
  empresaId: number;
  sucursalId?: number;
  countryCode: CountryCode;
}) {
  const normalized = mergeDefaults({
    ...input,
    empresaId: Number(input.empresaId),
    sucursalId: Number(input.sucursalId ?? 0),
    countryCode: input.countryCode
  });

  if (!(await hasFiscalConfigTable())) {
    const key = buildStoreKey(normalized.empresaId, normalized.sucursalId, normalized.countryCode);
    memoryConfigStore.set(key, normalized);
    return normalized;
  }

  await execute(
    `
      MERGE FiscalCountryConfig AS target
      USING (
        SELECT
          @empresaId AS EmpresaId,
          @sucursalId AS SucursalId,
          @countryCode AS CountryCode
      ) AS src
      ON target.EmpresaId = src.EmpresaId
         AND target.SucursalId = src.SucursalId
         AND target.CountryCode = src.CountryCode
      WHEN MATCHED THEN
        UPDATE SET
          Currency = @currency,
          TaxRegime = @taxRegime,
          DefaultTaxCode = @defaultTaxCode,
          DefaultTaxRate = @defaultTaxRate,
          FiscalPrinterEnabled = @fiscalPrinterEnabled,
          PrinterBrand = @printerBrand,
          PrinterPort = @printerPort,
          VerifactuEnabled = @verifactuEnabled,
          VerifactuMode = @verifactuMode,
          CertificatePath = @certificatePath,
          CertificatePassword = @certificatePassword,
          AEATEndpoint = @aeatEndpoint,
          SenderNIF = @senderNIF,
          SenderRIF = @senderRIF,
          SoftwareId = @softwareId,
          SoftwareName = @softwareName,
          SoftwareVersion = @softwareVersion,
          PosEnabled = @posEnabled,
          RestaurantEnabled = @restaurantEnabled,
          UpdatedAt = GETDATE()
      WHEN NOT MATCHED THEN
        INSERT (
          EmpresaId,
          SucursalId,
          CountryCode,
          Currency,
          TaxRegime,
          DefaultTaxCode,
          DefaultTaxRate,
          FiscalPrinterEnabled,
          PrinterBrand,
          PrinterPort,
          VerifactuEnabled,
          VerifactuMode,
          CertificatePath,
          CertificatePassword,
          AEATEndpoint,
          SenderNIF,
          SenderRIF,
          SoftwareId,
          SoftwareName,
          SoftwareVersion,
          PosEnabled,
          RestaurantEnabled,
          CreatedAt,
          UpdatedAt
        )
        VALUES (
          @empresaId,
          @sucursalId,
          @countryCode,
          @currency,
          @taxRegime,
          @defaultTaxCode,
          @defaultTaxRate,
          @fiscalPrinterEnabled,
          @printerBrand,
          @printerPort,
          @verifactuEnabled,
          @verifactuMode,
          @certificatePath,
          @certificatePassword,
          @aeatEndpoint,
          @senderNIF,
          @senderRIF,
          @softwareId,
          @softwareName,
          @softwareVersion,
          @posEnabled,
          @restaurantEnabled,
          GETDATE(),
          GETDATE()
        );
    `,
    {
      empresaId: normalized.empresaId,
      sucursalId: normalized.sucursalId,
      countryCode: normalized.countryCode,
      currency: normalized.currency,
      taxRegime: normalized.taxRegime,
      defaultTaxCode: normalized.defaultTaxCode,
      defaultTaxRate: normalized.defaultTaxRate,
      fiscalPrinterEnabled: normalized.fiscalPrinterEnabled ? 1 : 0,
      printerBrand: normalized.printerBrand ?? null,
      printerPort: normalized.printerPort ?? null,
      verifactuEnabled: normalized.verifactuEnabled ? 1 : 0,
      verifactuMode: normalized.verifactuMode,
      certificatePath: normalized.certificatePath ?? null,
      certificatePassword: normalized.certificatePassword ?? null,
      aeatEndpoint: normalized.aeatEndpoint ?? null,
      senderNIF: normalized.senderNIF ?? null,
      senderRIF: normalized.senderRIF ?? null,
      softwareId: normalized.softwareId ?? null,
      softwareName: normalized.softwareName ?? null,
      softwareVersion: normalized.softwareVersion ?? null,
      posEnabled: normalized.posEnabled ? 1 : 0,
      restaurantEnabled: normalized.restaurantEnabled ? 1 : 0
    }
  );

  return normalized;
}

export async function emitFiscalRecordFromTransaction(input: FiscalTransactionInput): Promise<FiscalTransactionResult> {
  const empresaId = Number(input.empresaId ?? 1);
  const sucursalId = Number(input.sucursalId ?? 0);
  const countryCode = input.countryCode ?? (await inferCountryCodeFromConfig(empresaId, sucursalId));
  const totalAmount = Number(input.totalAmount ?? 0);

  if (!Number.isFinite(totalAmount) || totalAmount < 0) {
    return { ok: false, reason: "invalid_total_amount" };
  }

  if (!(await hasFiscalRecordsTable())) {
    return { ok: true, skipped: true, reason: "fiscal_records_table_missing", countryCode };
  }

  const config = await getFiscalConfig({ empresaId, sucursalId, countryCode });
  const plugin = getFiscalPlugin(countryCode);
  const previousRecord = await getLatestFiscalRecord({ empresaId, sucursalId, countryCode });
  const invoiceType = normalizeInvoiceTypeByCountry({
    countryCode,
    sourceModule: input.sourceModule,
    totalAmount,
    invoiceTypeHint: input.invoiceTypeHint,
    recipientId: input.recipientId
  });
  const invoiceDate = parseDateInput(input.invoiceDate);

  const payload = {
    id: input.invoiceId,
    invoiceId: input.invoiceId,
    number: input.invoiceNumber,
    invoiceNumber: input.invoiceNumber,
    date: invoiceDate.toISOString(),
    type: invoiceType,
    total: totalAmount,
    totalAmount,
    recipientId: input.recipientId ?? null,
    sourceModule: input.sourceModule,
    metadata: input.metadata ?? {},
    payload: input.payload ?? {}
  };

  const validation = plugin.validateInvoice(payload);
  if (!validation.valid) {
    return {
      ok: false,
      reason: `invoice_validation_failed:${validation.errors.join(",")}`,
      countryCode
    };
  }

  const builtRecord = await plugin.buildFiscalRecord(payload, previousRecord ?? undefined);

  let sentToAuthority = false;
  let authorityStatus = "PENDING";
  let authorityResponse = builtRecord.authorityResponse ?? "";

  if (countryCode === "ES" && config.verifactuEnabled && config.verifactuMode === "auto" && plugin.submitToAuthority) {
    const authority = await plugin.submitToAuthority(builtRecord);
    sentToAuthority = Boolean(authority.accepted);
    authorityStatus = authority.accepted ? "ACCEPTED" : "REJECTED";
    authorityResponse = JSON.stringify(authority);
  } else if (countryCode === "VE") {
    authorityStatus = config.fiscalPrinterEnabled ? "PENDING_PRINTER" : "PENDING";
  } else {
    authorityStatus = "PENDING_LOCAL";
  }

  const metadata = input.metadata ?? {};
  const fiscalPrinterSerial = metadata["fiscalPrinterSerial"] ? String(metadata["fiscalPrinterSerial"]) : null;
  const fiscalControlNumber = metadata["fiscalControlNumber"] ? String(metadata["fiscalControlNumber"]) : null;
  const zReportNumberRaw = metadata["zReportNumber"];
  const zReportNumber = Number.isFinite(Number(zReportNumberRaw)) ? Number(zReportNumberRaw) : null;

  await execute(
    `
      INSERT INTO FiscalRecords (
        EmpresaId,
        SucursalId,
        CountryCode,
        InvoiceId,
        InvoiceType,
        InvoiceNumber,
        InvoiceDate,
        RecipientId,
        TotalAmount,
        RecordHash,
        PreviousRecordHash,
        XmlContent,
        DigitalSignature,
        QRCodeData,
        SentToAuthority,
        SentAt,
        AuthorityResponse,
        AuthorityStatus,
        FiscalPrinterSerial,
        FiscalControlNumber,
        ZReportNumber,
        CreatedAt
      ) VALUES (
        @empresaId,
        @sucursalId,
        @countryCode,
        @invoiceId,
        @invoiceType,
        @invoiceNumber,
        @invoiceDate,
        @recipientId,
        @totalAmount,
        @recordHash,
        @previousRecordHash,
        @xmlContent,
        @digitalSignature,
        @qrCodeData,
        @sentToAuthority,
        @sentAt,
        @authorityResponse,
        @authorityStatus,
        @fiscalPrinterSerial,
        @fiscalControlNumber,
        @zReportNumber,
        GETDATE()
      )
    `,
    {
      empresaId,
      sucursalId,
      countryCode,
      invoiceId: input.invoiceId,
      invoiceType,
      invoiceNumber: input.invoiceNumber,
      invoiceDate,
      recipientId: input.recipientId ?? null,
      totalAmount,
      recordHash: builtRecord.hash,
      previousRecordHash: builtRecord.previousHash ?? null,
      xmlContent: builtRecord.xmlContent ?? null,
      digitalSignature: builtRecord.signature ?? null,
      qrCodeData: builtRecord.qrCode ?? null,
      sentToAuthority: sentToAuthority ? 1 : 0,
      sentAt: sentToAuthority ? new Date() : null,
      authorityResponse: authorityResponse || null,
      authorityStatus,
      fiscalPrinterSerial,
      fiscalControlNumber,
      zReportNumber
    }
  );

  return {
    ok: true,
    countryCode,
    recordId: builtRecord.id,
    hash: builtRecord.hash,
    authorityStatus,
    sentToAuthority
  };
}
