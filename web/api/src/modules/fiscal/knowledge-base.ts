import { CountryCode, CountryKnowledge, FiscalConfig } from "./types.js";

const SOURCE_AEAT_VERIFACTU =
  "https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion.html";
const SOURCE_BOE_RD1007 = "https://www.boe.es/buscar/act.php?id=BOE-A-2023-24840";
const SOURCE_BOE_RD1619 = "https://www.boe.es/buscar/act.php?id=BOE-A-2012-14696";
const SOURCE_BOE_HAC1177 = "https://www.boe.es/diario_boe/txt.php?id=BOE-A-2024-22138";
const SOURCE_AEAT_FAQ_SIF =
  "https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion/preguntas-frecuentes/productores-comercializadores-sistemas-informaticos-facturacion.html";

export const fiscalKnowledgeByCountry: Record<CountryCode, CountryKnowledge> = {
  VE: {
    country: {
      code: "VE",
      name: "Venezuela",
      currency: "VES",
      currencySymbol: "Bs.",
      taxAuthority: "SENIAT",
      taxAuthorityFullName: "Servicio Nacional Integrado de Administracion Aduanera y Tributaria",
      fiscalIdName: "RIF",
      fiscalIdFormat: "^[VJGEPR]-\\d{8}-\\d$",
      fiscalIdExample: "J-12345678-9"
    },
    taxes: [
      {
        code: "IVA_GENERAL",
        name: "IVA General",
        rate: 0.16,
        countryCode: "VE",
        appliesToPOS: true,
        appliesToRestaurant: true,
        isDefault: true
      },
      {
        code: "IVA_REDUCIDO",
        name: "IVA Reducido",
        rate: 0.08,
        countryCode: "VE",
        appliesToPOS: true,
        appliesToRestaurant: true,
        isDefault: false
      },
      {
        code: "IVA_ADICIONAL",
        name: "IVA Adicional",
        rate: 0.31,
        countryCode: "VE",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: false
      },
      {
        code: "EXENTO",
        name: "Exento de IVA",
        rate: 0,
        countryCode: "VE",
        appliesToPOS: true,
        appliesToRestaurant: true,
        isDefault: false
      }
    ],
    invoiceTypes: [
      {
        code: "FACTURA",
        name: "Factura Fiscal",
        countryCode: "VE",
        isRectificative: false,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: true
      },
      {
        code: "NOTA_CREDITO",
        name: "Nota de Credito Fiscal",
        countryCode: "VE",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: true
      },
      {
        code: "NOTA_DEBITO",
        name: "Nota de Debito Fiscal",
        countryCode: "VE",
        isRectificative: false,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: true
      },
      {
        code: "NOTA_ENTREGA",
        name: "Nota de Entrega",
        countryCode: "VE",
        isRectificative: false,
        maxAmount: null,
        requiresRecipientNIF: false,
        requiresFiscalPrinter: false
      }
    ],
    regulations: {
      maxSimplifiedInvoiceAmountGeneral: null,
      maxSimplifiedInvoiceAmountPosRestaurant: null,
      requiresChainedRecords: false,
      requiresDigitalSignature: false,
      requiresQRCode: false,
      requiresElectronicSubmission: false,
      producerDeclarationRequired: false
    },
    milestones: [
      {
        key: "VE_FISCAL_PRINTER",
        date: "vigente",
        description: "Control fiscal basado en impresora fiscal homologada y reportes Z.",
        sourceUrl: "https://declaraciones.seniat.gob.ve/portal/page/portal/MANEJADOR_CONTENIDO_SENIAT/05MENU_HORIZONTAL/5.2INFORMACION_TRIBUTARIA"
      }
    ],
    sources: [
      {
        id: "VE_SENIAT_INFO",
        title: "Informacion Tributaria SENIAT",
        authority: "SENIAT",
        type: "portal",
        url: "https://declaraciones.seniat.gob.ve/portal/page/portal/MANEJADOR_CONTENIDO_SENIAT/05MENU_HORIZONTAL/5.2INFORMACION_TRIBUTARIA",
        notes: "Referencia base para operaciones fiscales VE."
      }
    ]
  },
  ES: {
    country: {
      code: "ES",
      name: "Espana",
      currency: "EUR",
      currencySymbol: "EUR",
      taxAuthority: "AEAT",
      taxAuthorityFullName: "Agencia Estatal de Administracion Tributaria",
      fiscalIdName: "NIF",
      fiscalIdFormat: "^[A-Z]\\d{7}[A-Z0-9]$|^\\d{8}[A-Z]$",
      fiscalIdExample: "B12345678 o 12345678Z"
    },
    taxes: [
      {
        code: "IVA_GENERAL",
        name: "IVA General",
        rate: 0.21,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: true
      },
      {
        code: "IVA_REDUCIDO",
        name: "IVA Reducido",
        rate: 0.1,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: true,
        isDefault: false
      },
      {
        code: "IVA_SUPERREDUCIDO",
        name: "IVA Superreducido",
        rate: 0.04,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: false
      },
      {
        code: "EXENTO",
        name: "Exento",
        rate: 0,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: true,
        isDefault: false
      },
      {
        code: "RE_GENERAL",
        name: "Recargo Equivalencia General",
        rate: 0.052,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: false,
        surchargeRate: 0.052
      },
      {
        code: "RE_REDUCIDO",
        name: "Recargo Equivalencia Reducido",
        rate: 0.014,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: false,
        surchargeRate: 0.014
      },
      {
        code: "RE_SUPERREDUCIDO",
        name: "Recargo Equivalencia Superreducido",
        rate: 0.005,
        countryCode: "ES",
        appliesToPOS: true,
        appliesToRestaurant: false,
        isDefault: false,
        surchargeRate: 0.005
      }
    ],
    invoiceTypes: [
      {
        code: "F1",
        name: "Factura Completa",
        countryCode: "ES",
        isRectificative: false,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "F2",
        name: "Factura Simplificada",
        countryCode: "ES",
        isRectificative: false,
        maxAmount: 3000,
        requiresRecipientNIF: false,
        requiresFiscalPrinter: false
      },
      {
        code: "F3",
        name: "Factura en sustitucion de simplificada",
        countryCode: "ES",
        isRectificative: false,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "R1",
        name: "Factura Rectificativa R1",
        countryCode: "ES",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "R2",
        name: "Factura Rectificativa R2",
        countryCode: "ES",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "R3",
        name: "Factura Rectificativa R3",
        countryCode: "ES",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "R4",
        name: "Factura Rectificativa R4",
        countryCode: "ES",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: true,
        requiresFiscalPrinter: false
      },
      {
        code: "R5",
        name: "Factura Rectificativa R5",
        countryCode: "ES",
        isRectificative: true,
        maxAmount: null,
        requiresRecipientNIF: false,
        requiresFiscalPrinter: false
      }
    ],
    regulations: {
      maxSimplifiedInvoiceAmountGeneral: 400,
      maxSimplifiedInvoiceAmountPosRestaurant: 3000,
      requiresChainedRecords: true,
      requiresDigitalSignature: true,
      requiresQRCode: true,
      requiresElectronicSubmission: true,
      producerDeclarationRequired: true
    },
    milestones: [
      {
        key: "ES_SOFTWARE_NO_SANCTION_UNTIL",
        date: "2026-07-29",
        description: "No se sanciona a productores/comercializadores antes de esta fecha.",
        sourceUrl: SOURCE_BOE_RD1007
      },
      {
        key: "ES_OBLIGATORIO_IS",
        date: "2027-01-01",
        description: "Obligatorio para contribuyentes del Impuesto sobre Sociedades.",
        sourceUrl: SOURCE_BOE_RD1007
      },
      {
        key: "ES_OBLIGATORIO_RESTO",
        date: "2027-07-01",
        description: "Obligatorio para el resto de obligados (incluye personas fisicas).",
        sourceUrl: SOURCE_BOE_RD1007
      }
    ],
    sources: [
      {
        id: "ES_RD1007_2023",
        title: "Real Decreto 1007/2023 (texto consolidado)",
        authority: "BOE",
        type: "real_decreto",
        url: SOURCE_BOE_RD1007,
        publishedDate: "2023-11-28"
      },
      {
        id: "ES_ORDEN_HAC_1177_2024",
        title: "Orden HAC/1177/2024",
        authority: "BOE",
        type: "orden",
        url: SOURCE_BOE_HAC1177,
        publishedDate: "2024-10-28"
      },
      {
        id: "ES_AEAT_SIF",
        title: "AEAT - Sistemas Informaticos de Facturacion",
        authority: "AEAT",
        type: "portal",
        url: SOURCE_AEAT_VERIFACTU
      },
      {
        id: "ES_AEAT_FAQ_PRODUCTORES",
        title: "AEAT - FAQ Productores y comercializadores SIF",
        authority: "AEAT",
        type: "faq",
        url: SOURCE_AEAT_FAQ_SIF
      },
      {
        id: "ES_RD1619_2012",
        title: "Reglamento de facturacion RD 1619/2012",
        authority: "BOE",
        type: "real_decreto",
        url: SOURCE_BOE_RD1619,
        publishedDate: "2012-11-30",
        notes: "Incluye limite general 400 EUR y limite 3000 EUR para sectores como hosteleria/restauracion."
      }
    ],
    verifactu: {
      enabled: true,
      modes: ["auto", "manual"],
      hashAlgorithm: "SHA-256",
      signatureType: "XAdES",
      certificateType: "X.509",
      productionEndpoint:
        "https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/RegistroFacturacion",
      testingEndpoint:
        "https://prewww1.aeat.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/RegistroFacturacion",
      qrBaseUrlProduction: "https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR",
      qrBaseUrlTesting: "https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR"
    }
  }
};

export function getCountryKnowledge(countryCode: CountryCode): CountryKnowledge {
  return fiscalKnowledgeByCountry[countryCode];
}

export function getDefaultFiscalConfig(countryCode: CountryCode): FiscalConfig {
  const country = fiscalKnowledgeByCountry[countryCode];
  const defaultTax = country.taxes.find((item) => item.isDefault) ?? country.taxes[0];

  if (countryCode === "ES") {
    return {
      empresaId: 1,
      sucursalId: 0,
      countryCode: "ES",
      currency: "EUR",
      taxRegime: "ES_REGIMEN_GENERAL",
      defaultTaxCode: defaultTax?.code ?? "IVA_GENERAL",
      defaultTaxRate: defaultTax?.rate ?? 0.21,
      fiscalPrinterEnabled: false,
      verifactuEnabled: true,
      verifactuMode: "manual",
      aeatEndpoint: country.verifactu?.testingEndpoint,
      posEnabled: true,
      restaurantEnabled: true
    };
  }

  return {
    empresaId: 1,
    sucursalId: 0,
    countryCode: "VE",
    currency: "VES",
    taxRegime: "VE_IVA_GENERAL",
    defaultTaxCode: defaultTax?.code ?? "IVA_GENERAL",
    defaultTaxRate: defaultTax?.rate ?? 0.16,
    fiscalPrinterEnabled: true,
    printerBrand: "HKA",
    verifactuEnabled: false,
    verifactuMode: "manual",
    posEnabled: true,
    restaurantEnabled: true
  };
}
