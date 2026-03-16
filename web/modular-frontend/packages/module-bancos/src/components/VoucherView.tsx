"use client";

import React from "react";
import {
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Divider,
  Paper,
  Skeleton,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
  Typography,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import PrintIcon from "@mui/icons-material/Print";
import DownloadIcon from "@mui/icons-material/Download";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { useMovimientoDetalle } from "../hooks/useBancosAuxiliares";
import { generateVoucherPdf, type VoucherData } from "./VoucherPdf";

const TIPOS_LABEL: Record<string, string> = {
  DEP: "Depósito",
  PCH: "Pago con Cheque",
  NCR: "Nota de Crédito",
  NDB: "Nota de Débito",
  IDB: "Ingreso a Débito",
};

const TIPOS_COLOR: Record<string, "success" | "error" | "info" | "warning" | "default"> = {
  DEP: "success",
  PCH: "error",
  NCR: "info",
  NDB: "warning",
  IDB: "default",
};

function toDateStr(val: any): string {
  if (!val) return "—";
  const d = new Date(val);
  if (isNaN(d.getTime())) return String(val);
  return d.toLocaleDateString("es-VE", { year: "numeric", month: "2-digit", day: "2-digit" });
}

export default function VoucherView({ movimientoId }: { movimientoId: string }) {
  const router = useRouter();
  const { data, isLoading } = useMovimientoDetalle(movimientoId);

  const handlePrint = () => window.print();

  const handleDownload = () => {
    if (!data) return;
    const tipo = String(data.Tipo ?? "").trim().toUpperCase();
    const vd: VoucherData = {
      id: data.id ?? data.ID ?? movimientoId,
      bancoNombre: data.BancoNombre ?? data.Banco ?? "",
      nroCta: data.Nro_Cta ?? "",
      tipo,
      tipoLabel: TIPOS_LABEL[tipo] ?? tipo,
      nroRef: data.Nro_Ref ?? "",
      beneficiario: data.Beneficiario ?? "",
      monto: Number(data.Gastos ?? 0) + Number(data.Ingresos ?? 0),
      concepto: data.Concepto ?? "",
      fecha: toDateStr(data.Fecha),
      categoria: data.Categoria ?? undefined,
      saldoActual: data.SaldoActual != null ? Number(data.SaldoActual) : undefined,
    };
    const blob = generateVoucherPdf(vd);
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `voucher-${vd.id}.pdf`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (isLoading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={400} />
      </Box>
    );
  }

  if (!data) {
    return (
      <Box sx={{ p: 3 }}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.back()}>Volver</Button>
        <Typography sx={{ mt: 2 }}>Movimiento no encontrado</Typography>
      </Box>
    );
  }

  const tipo = String(data.Tipo ?? "").trim().toUpperCase();
  const monto = Number(data.Gastos ?? 0) + Number(data.Ingresos ?? 0);

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
      {/* Actions (hidden on print) */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" className="no-print">
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.back()}>
          Volver
        </Button>
        <Stack direction="row" spacing={2}>
          <Button variant="outlined" startIcon={<PrintIcon />} onClick={handlePrint}>
            Imprimir
          </Button>
          <Button variant="contained" startIcon={<DownloadIcon />} onClick={handleDownload}>
            Descargar PDF
          </Button>
        </Stack>
      </Stack>

      {/* Voucher Card */}
      <Card sx={{ maxWidth: 700, mx: "auto", width: "100%" }} id="voucher-content">
        <CardContent sx={{ p: 4 }}>
          {/* Header */}
          <Stack alignItems="center" spacing={1} sx={{ mb: 3 }}>
            <ReceiptLongIcon sx={{ fontSize: 48, color: "primary.main" }} />
            <Typography variant="h5" fontWeight={700}>
              COMPROBANTE DE PAGO
            </Typography>
            <Typography variant="body2" color="text.secondary">
              No. {data.id ?? data.ID ?? movimientoId}
            </Typography>
          </Stack>

          <Divider sx={{ mb: 3 }} />

          {/* Details Table */}
          <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
            <Table>
              <TableBody>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600, width: 180 }}>Banco</TableCell>
                  <TableCell>{data.BancoNombre ?? data.Banco ?? "—"}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Cuenta</TableCell>
                  <TableCell>{data.Nro_Cta ?? "—"}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Tipo</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={`${tipo} - ${TIPOS_LABEL[tipo] ?? tipo}`}
                      color={TIPOS_COLOR[tipo] ?? "default"}
                    />
                  </TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Fecha</TableCell>
                  <TableCell>{toDateStr(data.Fecha)}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Referencia</TableCell>
                  <TableCell>{data.Nro_Ref ?? "—"}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Beneficiario</TableCell>
                  <TableCell sx={{ fontWeight: 500 }}>{data.Beneficiario ?? "—"}</TableCell>
                </TableRow>
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Concepto</TableCell>
                  <TableCell>{data.Concepto ?? "—"}</TableCell>
                </TableRow>
                {data.Categoria && (
                  <TableRow>
                    <TableCell sx={{ fontWeight: 600 }}>Categoría</TableCell>
                    <TableCell>{data.Categoria}</TableCell>
                  </TableRow>
                )}
                <TableRow>
                  <TableCell sx={{ fontWeight: 600 }}>Monto</TableCell>
                  <TableCell>
                    <Typography variant="h5" color="primary" fontWeight={700}>
                      {formatCurrency(monto)}
                    </Typography>
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </TableContainer>

          <Divider sx={{ my: 3 }} />

          {/* Signature lines */}
          <Stack direction="row" justifyContent="space-around" sx={{ mt: 6, mb: 2 }}>
            <Box sx={{ textAlign: "center" }}>
              <Box sx={{ borderBottom: "1px solid #333", width: 180, mb: 0.5 }} />
              <Typography variant="caption" color="text.secondary">
                Elaborado por
              </Typography>
            </Box>
            <Box sx={{ textAlign: "center" }}>
              <Box sx={{ borderBottom: "1px solid #333", width: 180, mb: 0.5 }} />
              <Typography variant="caption" color="text.secondary">
                Autorizado por
              </Typography>
            </Box>
          </Stack>

          {/* Footer */}
          <Typography variant="caption" color="text.disabled" sx={{ display: "block", textAlign: "center", mt: 4 }}>
            Generado por Zentto — {new Date().toLocaleString("es-VE")}
          </Typography>
        </CardContent>
      </Card>

      {/* Print styles */}
      <style>{`
        @media print {
          .no-print { display: none !important; }
          body { background: white !important; }
          #voucher-content { box-shadow: none !important; border: none !important; }
        }
      `}</style>
    </Box>
  );
}
