/**
 * Generador FacturaE 3.2.2 XML — Factura electronica a Administracion Publica.
 * Schema: http://www.facturae.es/Facturae/2014/v3.2.2/Facturae
 *
 * Version v1: estructura completa sin firma XAdES.
 * Para presentacion oficial se requiere firmar con XAdES-EPES (Fase 2).
 *
 * REF: http://www.facturae.es/
 */
import { create } from "xmlbuilder2";

export interface FacturaESeller {
  taxIdentificationNumber: string;
  name: string;
  address: string;
  postalCode: string;
  town: string;
  province: string;
  countryCode?: string;
}

export interface FacturaEBuyer extends FacturaESeller {
  /** Centros administrativos (para Administracion Publica DIR3) */
  centrosAdministrativos?: {
    organoGestor: string;
    unidadTramitadora: string;
    oficinaContable: string;
  };
}

export interface FacturaEItem {
  description: string;
  quantity: number;
  unitPriceWithoutTax: number;
  totalCost: number;
  grossAmount: number;
  taxes: Array<{
    taxTypeCode: "01" | "02" | "03" | "04"; // 01=IVA, 02=IPSI, 03=IGIC, 04=IRPF
    taxRate: number;
    taxableBase: number;
    taxAmount: number;
  }>;
}

export interface FacturaEInput {
  /** Modalidad: individual | lotes */
  modality?: "I" | "B";
  /** Numero serie */
  invoiceSeriesCode?: string;
  /** Numero factura */
  invoiceNumber: string;
  /** Fecha emision (YYYY-MM-DD) */
  issueDate: string;
  /** Fecha inicio/fin periodo */
  issueDateDue?: string;
  seller: FacturaESeller;
  buyer: FacturaEBuyer;
  items: FacturaEItem[];
  /** Totales calculados */
  totalGrossAmount: number;
  totalGeneralDiscounts?: number;
  totalGeneralSurcharges?: number;
  totalGrossAmountBeforeTaxes: number;
  totalTaxOutputs: number;
  totalTaxesWithheld: number;
  invoiceTotal: number;
  totalOutstandingAmount: number;
  totalPaymentsOnAccount?: number;
  amountsWithheld?: number;
  totalExecutableAmount: number;
  currency?: string;
}

export function generateFacturaE(input: FacturaEInput): string {
  const doc = create({ version: "1.0", encoding: "UTF-8" })
    .ele("fe:Facturae", {
      "xmlns:fe": "http://www.facturae.es/Facturae/2014/v3.2.2/Facturae",
      "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
    });

  // FileHeader
  const header = doc.ele("FileHeader");
  header.ele("SchemaVersion").txt("3.2.2").up();
  header.ele("Modality").txt(input.modality ?? "I").up();
  header.ele("InvoiceIssuerType").txt("EM").up();
  const batch = header.ele("Batch");
  batch.ele("BatchIdentifier").txt(input.invoiceNumber).up();
  batch.ele("InvoicesCount").txt("1").up();
  const totalInvoicesAmount = batch.ele("TotalInvoicesAmount");
  totalInvoicesAmount.ele("TotalAmount").txt(input.invoiceTotal.toFixed(2)).up();
  batch.ele("TotalOutstandingAmount").ele("TotalAmount").txt(input.totalOutstandingAmount.toFixed(2)).up().up();
  batch.ele("TotalExecutableAmount").ele("TotalAmount").txt(input.totalExecutableAmount.toFixed(2)).up().up();
  batch.ele("InvoiceCurrencyCode").txt(input.currency ?? "EUR").up();

  // Parties
  const parties = doc.ele("Parties");

  // SellerParty
  const sellerParty = parties.ele("SellerParty");
  sellerParty.ele("TaxIdentification")
    .ele("PersonTypeCode").txt("J").up()
    .ele("ResidenceTypeCode").txt("R").up()
    .ele("TaxIdentificationNumber").txt(input.seller.taxIdentificationNumber).up().up();
  const sellerLegal = sellerParty.ele("LegalEntity");
  sellerLegal.ele("CorporateName").txt(input.seller.name).up();
  sellerLegal.ele("AddressInSpain")
    .ele("Address").txt(input.seller.address).up()
    .ele("PostCode").txt(input.seller.postalCode).up()
    .ele("Town").txt(input.seller.town).up()
    .ele("Province").txt(input.seller.province).up()
    .ele("CountryCode").txt(input.seller.countryCode ?? "ESP").up().up();

  // BuyerParty
  const buyerParty = parties.ele("BuyerParty");
  buyerParty.ele("TaxIdentification")
    .ele("PersonTypeCode").txt("J").up()
    .ele("ResidenceTypeCode").txt("R").up()
    .ele("TaxIdentificationNumber").txt(input.buyer.taxIdentificationNumber).up().up();

  // Centros administrativos (DIR3) — obligatorio para facturacion a Admin Pub
  if (input.buyer.centrosAdministrativos) {
    const admin = buyerParty.ele("AdministrativeCentres");
    const { organoGestor, unidadTramitadora, oficinaContable } = input.buyer.centrosAdministrativos;
    for (const { code, role } of [
      { code: organoGestor, role: "02" },          // Organo Gestor
      { code: unidadTramitadora, role: "03" },     // Unidad Tramitadora
      { code: oficinaContable, role: "01" },       // Oficina Contable
    ]) {
      admin.ele("AdministrativeCentre")
        .ele("CentreCode").txt(code).up()
        .ele("RoleTypeCode").txt(role).up().up();
    }
  }

  const buyerLegal = buyerParty.ele("LegalEntity");
  buyerLegal.ele("CorporateName").txt(input.buyer.name).up();
  buyerLegal.ele("AddressInSpain")
    .ele("Address").txt(input.buyer.address).up()
    .ele("PostCode").txt(input.buyer.postalCode).up()
    .ele("Town").txt(input.buyer.town).up()
    .ele("Province").txt(input.buyer.province).up()
    .ele("CountryCode").txt(input.buyer.countryCode ?? "ESP").up().up();

  // Invoices
  const invoices = doc.ele("Invoices");
  const invoice = invoices.ele("Invoice");

  invoice.ele("InvoiceHeader")
    .ele("InvoiceNumber").txt(input.invoiceNumber).up()
    .ele("InvoiceSeriesCode").txt(input.invoiceSeriesCode ?? "").up()
    .ele("InvoiceDocumentType").txt("FC").up()
    .ele("InvoiceClass").txt("OO").up().up();

  invoice.ele("InvoiceIssueData")
    .ele("IssueDate").txt(input.issueDate).up()
    .ele("InvoiceCurrencyCode").txt(input.currency ?? "EUR").up()
    .ele("TaxCurrencyCode").txt(input.currency ?? "EUR").up()
    .ele("LanguageName").txt("es").up().up();

  // Taxes Outputs (IVA repercutido)
  const taxesOutputs = invoice.ele("TaxesOutputs");
  const taxMap = new Map<string, { base: number; rate: number; amount: number; code: string }>();
  for (const item of input.items) {
    for (const t of item.taxes) {
      const key = `${t.taxTypeCode}-${t.taxRate}`;
      const existing = taxMap.get(key);
      if (existing) {
        existing.base += t.taxableBase;
        existing.amount += t.taxAmount;
      } else {
        taxMap.set(key, { base: t.taxableBase, rate: t.taxRate, amount: t.taxAmount, code: t.taxTypeCode });
      }
    }
  }
  for (const [, tax] of taxMap) {
    taxesOutputs.ele("Tax")
      .ele("TaxTypeCode").txt(tax.code).up()
      .ele("TaxRate").txt(tax.rate.toFixed(2)).up()
      .ele("TaxableBase").ele("TotalAmount").txt(tax.base.toFixed(2)).up().up()
      .ele("TaxAmount").ele("TotalAmount").txt(tax.amount.toFixed(2)).up().up().up();
  }

  // Items
  const itemsEl = invoice.ele("Items");
  for (const it of input.items) {
    const line = itemsEl.ele("InvoiceLine");
    line.ele("ItemDescription").txt(it.description).up();
    line.ele("Quantity").txt(it.quantity.toFixed(6)).up();
    line.ele("UnitPriceWithoutTax").txt(it.unitPriceWithoutTax.toFixed(6)).up();
    line.ele("TotalCost").txt(it.totalCost.toFixed(6)).up();
    line.ele("GrossAmount").txt(it.grossAmount.toFixed(6)).up();
    const taxesLine = line.ele("TaxesOutputs");
    for (const t of it.taxes) {
      taxesLine.ele("Tax")
        .ele("TaxTypeCode").txt(t.taxTypeCode).up()
        .ele("TaxRate").txt(t.taxRate.toFixed(2)).up()
        .ele("TaxableBase").ele("TotalAmount").txt(t.taxableBase.toFixed(2)).up().up()
        .ele("TaxAmount").ele("TotalAmount").txt(t.taxAmount.toFixed(2)).up().up();
    }
  }

  // Totals
  invoice.ele("InvoiceTotals")
    .ele("TotalGrossAmount").txt(input.totalGrossAmount.toFixed(2)).up()
    .ele("TotalGeneralDiscounts").txt((input.totalGeneralDiscounts ?? 0).toFixed(2)).up()
    .ele("TotalGeneralSurcharges").txt((input.totalGeneralSurcharges ?? 0).toFixed(2)).up()
    .ele("TotalGrossAmountBeforeTaxes").txt(input.totalGrossAmountBeforeTaxes.toFixed(2)).up()
    .ele("TotalTaxOutputs").txt(input.totalTaxOutputs.toFixed(2)).up()
    .ele("TotalTaxesWithheld").txt(input.totalTaxesWithheld.toFixed(2)).up()
    .ele("InvoiceTotal").txt(input.invoiceTotal.toFixed(2)).up()
    .ele("TotalOutstandingAmount").txt(input.totalOutstandingAmount.toFixed(2)).up()
    .ele("TotalExecutableAmount").txt(input.totalExecutableAmount.toFixed(2)).up().up();

  return doc.end({ prettyPrint: true });
}
