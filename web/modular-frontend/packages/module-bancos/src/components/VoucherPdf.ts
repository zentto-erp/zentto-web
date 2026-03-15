import jsPDF from "jspdf";

export interface VoucherData {
  id: number | string;
  bancoNombre: string;
  nroCta: string;
  tipo: string;
  tipoLabel: string;
  nroRef: string;
  beneficiario: string;
  monto: number;
  concepto: string;
  fecha: string;
  categoria?: string;
  saldoActual?: number;
}

const TIPOS_LABEL: Record<string, string> = {
  DEP: "Depósito",
  PCH: "Pago con Cheque",
  NCR: "Nota de Crédito",
  NDB: "Nota de Débito",
  IDB: "Ingreso a Débito",
};

function formatMoney(value: number): string {
  return new Intl.NumberFormat("es-VE", { style: "currency", currency: "VES", minimumFractionDigits: 2 }).format(value);
}

export function generateVoucherPdf(data: VoucherData): Blob {
  const doc = new jsPDF({ orientation: "portrait", unit: "mm", format: "letter" });
  const w = doc.internal.pageSize.getWidth();
  const marginL = 20;
  const marginR = w - 20;
  let y = 25;

  // Header
  doc.setFontSize(16);
  doc.setFont("helvetica", "bold");
  doc.text("COMPROBANTE DE PAGO", w / 2, y, { align: "center" });
  y += 8;

  doc.setFontSize(10);
  doc.setFont("helvetica", "normal");
  doc.text(`No. ${data.id}`, w / 2, y, { align: "center" });
  y += 10;

  // Line
  doc.setDrawColor(0);
  doc.setLineWidth(0.5);
  doc.line(marginL, y, marginR, y);
  y += 8;

  // Bank info
  const labelX = marginL;
  const valueX = marginL + 45;

  const rows: [string, string][] = [
    ["Banco:", data.bancoNombre || "—"],
    ["Cuenta:", data.nroCta || "—"],
    ["Tipo:", `${data.tipo} - ${data.tipoLabel || TIPOS_LABEL[data.tipo] || data.tipo}`],
    ["Fecha:", data.fecha || new Date().toLocaleDateString("es-VE")],
    ["Referencia:", data.nroRef || "—"],
    ["Beneficiario:", data.beneficiario || "—"],
    ["Concepto:", data.concepto || "—"],
  ];

  if (data.categoria) {
    rows.push(["Categoría:", data.categoria]);
  }

  doc.setFontSize(11);
  for (const [label, value] of rows) {
    doc.setFont("helvetica", "bold");
    doc.text(label, labelX, y);
    doc.setFont("helvetica", "normal");
    doc.text(value, valueX, y);
    y += 7;
  }

  y += 5;

  // Amount box
  doc.setDrawColor(0);
  doc.setFillColor(240, 240, 240);
  doc.roundedRect(marginL, y, marginR - marginL, 18, 3, 3, "FD");

  doc.setFontSize(12);
  doc.setFont("helvetica", "bold");
  doc.text("MONTO:", marginL + 5, y + 7);

  doc.setFontSize(16);
  doc.text(formatMoney(data.monto), marginR - 5, y + 12, { align: "right" });
  y += 28;

  // Separator
  doc.setLineWidth(0.3);
  doc.line(marginL, y, marginR, y);
  y += 15;

  // Signature lines
  const sigW = 60;
  const sig1X = marginL + 10;
  const sig2X = marginR - sigW - 10;

  doc.setLineWidth(0.3);
  doc.line(sig1X, y, sig1X + sigW, y);
  doc.line(sig2X, y, sig2X + sigW, y);
  y += 5;

  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.text("Elaborado por", sig1X + sigW / 2, y, { align: "center" });
  doc.text("Autorizado por", sig2X + sigW / 2, y, { align: "center" });

  y += 20;

  // Footer
  doc.setFontSize(8);
  doc.setTextColor(150);
  doc.text(`Generado el ${new Date().toLocaleString("es-VE")} — DatqBox Web`, w / 2, y, { align: "center" });

  return doc.output("blob");
}
