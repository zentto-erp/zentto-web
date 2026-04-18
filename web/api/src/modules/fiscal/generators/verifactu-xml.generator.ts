/**
 * Generador XML Verifactu — Registro de facturacion AEAT.
 *
 * Version v1: estructura XML + hash SHA-256 encadenado + QR data URL.
 * La firma XAdES y el envio SOAP quedan para Fase 2 (requieren certificados X.509).
 *
 * REF oficial AEAT:
 *  - Diseño registro: https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion-verifactu.html
 *  - Endpoint testing: https://prewww1.aeat.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/RegistroFacturacion
 *  - QR validation: https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR
 */
import { createHash } from "node:crypto";
import { create } from "xmlbuilder2";

export interface VerifactuRecord {
  /** NIF emisor */
  emisorNIF: string;
  /** Numero serie + factura */
  numSerieFactura: string;
  /** Fecha expedicion AAAA-MM-DD */
  fechaExpedicion: string;
  /** Tipo factura: F1=completa, F2=simplificada, R1-R5=rectificativa */
  tipoFactura: "F1" | "F2" | "F3" | "R1" | "R2" | "R3" | "R4" | "R5";
  /** Descripcion operacion */
  descripcionOperacion: string;
  /** Base imponible total */
  baseTotal: number;
  /** Cuota IVA total */
  cuotaTotal: number;
  /** Importe total factura */
  importeTotal: number;
  /** NIF destinatario (opcional en facturas simplificadas) */
  destinatarioNIF?: string;
  /** Nombre destinatario */
  destinatarioNombre?: string;
  /** Desglose por tipo IVA */
  desglose: Array<{
    tipoImpositivo: number;  // 0.21, 0.10, 0.04, 0
    baseImponible: number;
    cuota: number;
  }>;
  /** Hash previo (cadena): vacio para primer registro del tenant */
  hashAnterior?: string;
  /** Timestamp registro (ISO 8601) */
  timestampRegistro?: string;
  /** Software emisor info */
  software: {
    id: string;
    nombre: string;
    version: string;
    nif: string;
  };
}

export interface VerifactuOutput {
  xml: string;
  hashActual: string;
  qrData: string;
}

/**
 * Calcula hash SHA-256 del registro concatenando campos en orden canonico AEAT.
 * Orden según especificación: NIFEmisor + NumSerieFactura + FechaExpedicion +
 * TipoFactura + CuotaTotal + ImporteTotal + HashAnterior + Timestamp.
 */
export function calculateVerifactuHash(record: VerifactuRecord, timestamp: string): string {
  const canonical = [
    record.emisorNIF,
    record.numSerieFactura,
    record.fechaExpedicion,
    record.tipoFactura,
    record.cuotaTotal.toFixed(2),
    record.importeTotal.toFixed(2),
    record.hashAnterior ?? "",
    timestamp,
  ].join("|");
  return createHash("sha256").update(canonical, "utf8").digest("hex").toUpperCase();
}

/**
 * Genera URL del código QR para validación AEAT.
 * Formato: https://<validationHost>/wlpl/TIKE-CONT/ValidarQR?nif=X&numserie=Y&fecha=Z&importe=W
 */
export function generateQRUrl(record: VerifactuRecord, environment: "TESTING" | "PRODUCTION" = "PRODUCTION"): string {
  const host = environment === "TESTING"
    ? "prewww2.aeat.es"
    : "www2.agenciatributaria.gob.es";
  const params = new URLSearchParams({
    nif: record.emisorNIF,
    numserie: record.numSerieFactura,
    fecha: record.fechaExpedicion,
    importe: record.importeTotal.toFixed(2),
  });
  return `https://${host}/wlpl/TIKE-CONT/ValidarQR?${params.toString()}`;
}

/**
 * Genera XML del registro de facturacion Verifactu.
 */
export function generateVerifactuXML(record: VerifactuRecord, environment: "TESTING" | "PRODUCTION" = "PRODUCTION"): VerifactuOutput {
  const timestamp = record.timestampRegistro ?? new Date().toISOString();
  const hashActual = calculateVerifactuHash(record, timestamp);
  const qrData = generateQRUrl(record, environment);

  const doc = create({ version: "1.0", encoding: "UTF-8" })
    .ele("sum:RegistroFactura", {
      "xmlns:sum": "https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroInformacion.xsd",
      "xmlns:sum1": "https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/tike/cont/ws/SuministroLR.xsd",
    });

  // Cabecera
  const cabecera = doc.ele("sum1:Cabecera");
  cabecera.ele("sum1:ObligadoEmision")
    .ele("sum1:NombreRazon").txt(record.descripcionOperacion.substring(0, 120)).up()
    .ele("sum1:NIF").txt(record.emisorNIF).up().up();
  cabecera.ele("sum1:TipoComunicacion").txt("A0").up(); // A0 = Alta

  // Registro Alta
  const registroAlta = doc.ele("sum1:RegistroAlta");
  const idFactura = registroAlta.ele("sum1:IDFactura");
  idFactura.ele("sum1:IDEmisorFactura").txt(record.emisorNIF).up();
  idFactura.ele("sum1:NumSerieFactura").txt(record.numSerieFactura).up();
  idFactura.ele("sum1:FechaExpedicionFactura").txt(record.fechaExpedicion).up();

  registroAlta.ele("sum1:NombreRazonEmisor").txt(record.descripcionOperacion.substring(0, 120)).up();
  registroAlta.ele("sum1:TipoFactura").txt(record.tipoFactura).up();
  registroAlta.ele("sum1:DescripcionOperacion").txt(record.descripcionOperacion).up();

  // Destinatarios (opcional para F2)
  if (record.destinatarioNIF && record.destinatarioNombre) {
    const destinatarios = registroAlta.ele("sum1:Destinatarios");
    destinatarios.ele("sum1:IDDestinatario")
      .ele("sum1:NombreRazon").txt(record.destinatarioNombre).up()
      .ele("sum1:NIF").txt(record.destinatarioNIF).up().up();
  }

  // Desglose IVA
  const desglose = registroAlta.ele("sum1:Desglose");
  for (const d of record.desglose) {
    const item = desglose.ele("sum1:DetalleDesglose");
    item.ele("sum1:ClaveRegimen").txt("01").up(); // 01 = Operacion de regimen general
    item.ele("sum1:CalificacionOperacion").txt("S1").up(); // S1 = Sujeta y no exenta
    item.ele("sum1:TipoImpositivo").txt((d.tipoImpositivo * 100).toFixed(2)).up();
    item.ele("sum1:BaseImponibleOImporteNoSujeto").txt(d.baseImponible.toFixed(2)).up();
    item.ele("sum1:CuotaRepercutida").txt(d.cuota.toFixed(2)).up();
  }

  registroAlta.ele("sum1:CuotaTotal").txt(record.cuotaTotal.toFixed(2)).up();
  registroAlta.ele("sum1:ImporteTotal").txt(record.importeTotal.toFixed(2)).up();

  // Encadenamiento hash
  const encadenamiento = registroAlta.ele("sum1:Encadenamiento");
  if (record.hashAnterior) {
    encadenamiento.ele("sum1:RegistroAnterior")
      .ele("sum1:IDEmisorFactura").txt(record.emisorNIF).up()
      .ele("sum1:Huella").txt(record.hashAnterior).up().up();
  } else {
    encadenamiento.ele("sum1:PrimerRegistro").txt("S").up();
  }

  // Sistema informatico
  const sistema = registroAlta.ele("sum1:SistemaInformatico");
  sistema.ele("sum1:NombreRazon").txt(record.software.nombre).up();
  sistema.ele("sum1:NIF").txt(record.software.nif).up();
  sistema.ele("sum1:IdSistemaInformatico").txt(record.software.id).up();
  sistema.ele("sum1:NombreSistemaInformatico").txt(record.software.nombre).up();
  sistema.ele("sum1:Version").txt(record.software.version).up();
  sistema.ele("sum1:NumeroInstalacion").txt("0001").up();

  registroAlta.ele("sum1:FechaHoraHusoGenRegistro").txt(timestamp).up();
  registroAlta.ele("sum1:TipoHuella").txt("01").up(); // 01 = SHA-256
  registroAlta.ele("sum1:Huella").txt(hashActual).up();

  return {
    xml: doc.end({ prettyPrint: true }),
    hashActual,
    qrData,
  };
}
