"use client";

import React, { useState, useMemo, useEffect } from "react";
import {
  Box,
  Button,
  Typography,
  Paper,
  Stack,
  Alert,
  Card,
  CardContent,
  Chip,
  Divider,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  InputAdornment,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableRow,
} from "@mui/material";

import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import ReceiptIcon from "@mui/icons-material/Receipt";
import DescriptionIcon from "@mui/icons-material/Description";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import SaveIcon from "@mui/icons-material/Save";

import { useRouter, useSearchParams } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { CustomStepper, useToast } from "@zentto/shared-ui";
import type { StepDef } from "@zentto/shared-ui";

import { useCuentasBancarias, useGenerarMovimientoBancario } from "../hooks/useBancosAuxiliares";

// ─── Definición de pasos ───────────────────────────────────────

const STEPS: StepDef[] = [
  { label: "Seleccionar Cuenta", icon: <AccountBalanceIcon /> },
  { label: "Datos del Movimiento", icon: <ReceiptIcon /> },
  { label: "Documento Relacionado", icon: <DescriptionIcon /> },
  { label: "Confirmación", icon: <CheckCircleIcon /> },
];

// ─── Tipos de movimiento ───────────────────────────────────────

const TIPOS_MOVIMIENTO = [
  { value: "DEP", label: "Depósito", color: "success" as const },
  { value: "PCH", label: "Pago Cheque", color: "error" as const },
  { value: "NCR", label: "Nota de Crédito", color: "info" as const },
  { value: "NDB", label: "Nota de Débito", color: "warning" as const },
  { value: "IDB", label: "Ingreso a Débito", color: "default" as const },
];

const TIPOS_DOC_REL = [
  { value: "", label: "Ninguno" },
  { value: "FACTURA", label: "Factura" },
  { value: "ORDEN", label: "Orden de Compra" },
  { value: "NOTA", label: "Nota" },
  { value: "OTRO", label: "Otro" },
];

type CuentaRow = Record<string, any>;

// ─── Componente Principal ──────────────────────────────────────

export default function MovimientoBancarioWizard() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { showToast } = useToast();
  const initialCuenta = searchParams.get("cuenta") ?? "";
  const [activeStep, setActiveStep] = useState(initialCuenta ? 1 : 0);
  const [error, setError] = useState<string | null>(null);

  // Paso 1 — Cuenta
  const [nroCtaSeleccionada, setNroCtaSeleccionada] = useState(initialCuenta);

  // Paso 2 — Datos del movimiento
  const [tipo, setTipo] = useState("DEP");
  const [nroRef, setNroRef] = useState("");
  const [beneficiario, setBeneficiario] = useState("");
  const [monto, setMonto] = useState("");
  const [concepto, setConcepto] = useState("");
  const [categoria, setCategoria] = useState("");

  // Paso 3 — Documento relacionado
  const [docRelacionado, setDocRelacionado] = useState("");
  const [tipoDocRel, setTipoDocRel] = useState("");

  // ─── Queries ──────────────────────────────────────────────────

  const cuentasQuery = useCuentasBancarias();
  const cuentas: CuentaRow[] = useMemo(
    () => (Array.isArray(cuentasQuery.data) ? cuentasQuery.data : cuentasQuery.data?.rows ?? []),
    [cuentasQuery.data]
  );

  // ─── Mutations ────────────────────────────────────────────────

  const generarMut = useGenerarMovimientoBancario();

  // ─── Cuenta seleccionada ──────────────────────────────────────

  const cuentaObj = useMemo(
    () => cuentas.find((c) => String(c.Nro_Cta ?? c.nroCta ?? c.id) === nroCtaSeleccionada),
    [cuentas, nroCtaSeleccionada]
  );

  const cuentaKey = (c: CuentaRow) => String(c.Nro_Cta ?? c.nroCta ?? c.id);
  const cuentaLabel = (c: CuentaRow) =>
    `${c.BancoNombre ?? c.Banco ?? c.banco ?? ""} - ${c.Nro_Cta ?? c.nroCta ?? ""}`;

  const tipoInfo = TIPOS_MOVIMIENTO.find((t) => t.value === tipo);

  // ─── Navegación ───────────────────────────────────────────────

  const handleNext = () => {
    setError(null);

    if (activeStep === 0) {
      if (!nroCtaSeleccionada) {
        setError("Debe seleccionar una cuenta bancaria");
        return;
      }
    }

    if (activeStep === 1) {
      if (!tipo) {
        setError("Debe seleccionar el tipo de movimiento");
        return;
      }
      if (!nroRef.trim()) {
        setError("Debe ingresar un número de referencia");
        return;
      }
      if (!beneficiario.trim()) {
        setError("Debe ingresar el beneficiario");
        return;
      }
      if (!monto || Number(monto) <= 0) {
        setError("El monto debe ser mayor a cero");
        return;
      }
      if (!concepto.trim()) {
        setError("Debe ingresar el concepto");
        return;
      }
    }

    // Paso 3 es opcional, no necesita validación
    setActiveStep((prev) => prev + 1);
  };

  const handleBack = () => {
    setError(null);
    setActiveStep((prev) => prev - 1);
  };

  const handleGenerar = async () => {
    setError(null);
    try {
      const payload = {
        Nro_Cta: nroCtaSeleccionada,
        Tipo: tipo,
        Nro_Ref: nroRef,
        Beneficiario: beneficiario,
        Monto: Number(monto),
        Concepto: concepto,
        Categoria: categoria || undefined,
        Documento_Relacionado: docRelacionado || undefined,
        Tipo_Doc_Rel: tipoDocRel || undefined,
      };
      const result = await generarMut.mutateAsync(payload as any) as any;
      showToast("Movimiento bancario generado exitosamente");
      const movId = result?.movimientoId ?? result?.data?.movimientoId;
      if (movId) {
        router.push(`/voucher/${movId}`);
      } else {
        router.back();
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al generar el movimiento");
    }
  };

  // ─── Render paso a paso ──────────────────────────────────────

  const renderStep = () => {
    switch (activeStep) {
      // ── Paso 1: Seleccionar Cuenta ──
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Seleccione la cuenta bancaria
              </Typography>

              <FormControl fullWidth sx={{ mb: 3 }}>
                <InputLabel>Cuenta Bancaria</InputLabel>
                <Select
                  value={nroCtaSeleccionada}
                  label="Cuenta Bancaria"
                  onChange={(e) => setNroCtaSeleccionada(e.target.value)}
                >
                  {cuentas.map((c) => (
                    <MenuItem key={cuentaKey(c)} value={cuentaKey(c)}>
                      <Stack direction="row" alignItems="center" spacing={1}>
                        <AccountBalanceIcon fontSize="small" />
                        <span>{cuentaLabel(c)}</span>
                        {c.Saldo != null && (
                          <Chip size="small" label={formatCurrency(Number(c.Saldo ?? c.saldo ?? 0))} color="success" />
                        )}
                      </Stack>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {cuentaObj && (
                <Alert severity="info">
                  <Typography variant="body2">
                    <strong>Cuenta:</strong> {cuentaLabel(cuentaObj)}
                  </Typography>
                  {cuentaObj.Saldo != null && (
                    <Typography variant="body2">
                      <strong>Saldo actual:</strong> {formatCurrency(Number(cuentaObj.Saldo ?? cuentaObj.saldo ?? 0))}
                    </Typography>
                  )}
                </Alert>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 2: Datos del Movimiento ──
      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Ingrese los datos del movimiento bancario
              </Typography>

              <Stack spacing={3}>
                <FormControl fullWidth>
                  <InputLabel>Tipo de Movimiento</InputLabel>
                  <Select value={tipo} label="Tipo de Movimiento" onChange={(e) => setTipo(e.target.value)}>
                    {TIPOS_MOVIMIENTO.map((t) => (
                      <MenuItem key={t.value} value={t.value}>
                        <Stack direction="row" alignItems="center" spacing={1}>
                          <Chip size="small" label={t.value} color={t.color} />
                          <span>{t.label}</span>
                        </Stack>
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>

                <Stack direction="row" spacing={2}>
                  <TextField
                    fullWidth
                    label="Número de Referencia"
                    value={nroRef}
                    onChange={(e) => setNroRef(e.target.value)}
                  />
                  <TextField
                    fullWidth
                    label="Monto"
                    type="number"
                    value={monto}
                    onChange={(e) => setMonto(e.target.value)}
                    InputProps={{
                      startAdornment: <InputAdornment position="start">$</InputAdornment>,
                    }}
                  />
                </Stack>

                <TextField
                  fullWidth
                  label="Beneficiario"
                  value={beneficiario}
                  onChange={(e) => setBeneficiario(e.target.value)}
                />

                <TextField
                  fullWidth
                  label="Concepto"
                  value={concepto}
                  onChange={(e) => setConcepto(e.target.value)}
                  multiline
                  rows={2}
                />

                <TextField
                  fullWidth
                  label="Categoría (opcional)"
                  value={categoria}
                  onChange={(e) => setCategoria(e.target.value)}
                />
              </Stack>
            </CardContent>
          </Card>
        );

      // ── Paso 3: Documento Relacionado ──
      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Documento relacionado (opcional)
              </Typography>

              <Alert severity="info" sx={{ mb: 3 }}>
                Si este movimiento está asociado a un documento (factura, orden de compra, etc.),
                puede relacionarlo aquí. Este paso es opcional.
              </Alert>

              <Stack spacing={3}>
                <TextField
                  fullWidth
                  label="Número de Documento"
                  value={docRelacionado}
                  onChange={(e) => setDocRelacionado(e.target.value)}
                  placeholder="Ej: FAC-001, OC-2024-015"
                />

                <FormControl fullWidth>
                  <InputLabel>Tipo de Documento</InputLabel>
                  <Select value={tipoDocRel} label="Tipo de Documento" onChange={(e) => setTipoDocRel(e.target.value)}>
                    {TIPOS_DOC_REL.map((t) => (
                      <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Stack>
            </CardContent>
          </Card>
        );

      // ── Paso 4: Confirmación ──
      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Confirme los datos del movimiento
              </Typography>

              <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
                <Table>
                  <TableBody>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600, width: 200 }}>Cuenta</TableCell>
                      <TableCell>{cuentaObj ? cuentaLabel(cuentaObj) : nroCtaSeleccionada}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Tipo</TableCell>
                      <TableCell>
                        <Chip size="small" label={`${tipo} - ${tipoInfo?.label ?? ""}`} color={tipoInfo?.color ?? "default"} />
                      </TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Referencia</TableCell>
                      <TableCell>{nroRef}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Beneficiario</TableCell>
                      <TableCell>{beneficiario}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Monto</TableCell>
                      <TableCell>
                        <Typography variant="h6" color="primary" fontWeight={700}>
                          {formatCurrency(Number(monto))}
                        </Typography>
                      </TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Concepto</TableCell>
                      <TableCell>{concepto}</TableCell>
                    </TableRow>
                    {categoria && (
                      <TableRow>
                        <TableCell sx={{ fontWeight: 600 }}>Categoría</TableCell>
                        <TableCell>{categoria}</TableCell>
                      </TableRow>
                    )}
                    {docRelacionado && (
                      <TableRow>
                        <TableCell sx={{ fontWeight: 600 }}>Doc. Relacionado</TableCell>
                        <TableCell>{docRelacionado} ({tipoDocRel || "Sin tipo"})</TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>

              <Divider sx={{ my: 2 }} />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button variant="outlined" color="error" onClick={() => router.back()}>
                  Cancelar
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={<SaveIcon />}
                  onClick={handleGenerar}
                  disabled={generarMut.isPending}
                >
                  {generarMut.isPending ? "Generando..." : "Generar Movimiento"}
                </Button>
              </Stack>
            </CardContent>
          </Card>
        );

      default:
        return null;
    }
  };

  // ─── Render Principal ─────────────────────────────────────────

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
      {/* Header */}
      <Typography variant="h5" fontWeight={600}>
        Generar movimiento bancario
      </Typography>

      {/* Error */}
      {error && (
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Stepper */}
      <Paper sx={{ p: 3 }}>
        <CustomStepper
          activeStep={activeStep}
          steps={STEPS}
          onStepClick={(step) => {
            if (step < activeStep) setActiveStep(step);
          }}
        />
      </Paper>

      {/* Contenido del paso */}
      {renderStep()}

      {/* Botones de navegación */}
      {activeStep < 3 && (
        <Paper sx={{ p: 2 }}>
          <Stack direction="row" justifyContent="space-between">
            <Button
              variant="outlined"
              onClick={handleBack}
              disabled={activeStep === 0}
              startIcon={<ArrowBackIcon />}
            >
              Anterior
            </Button>
            <Button
              variant="contained"
              onClick={handleNext}
              endIcon={<ArrowForwardIcon />}
            >
              Siguiente
            </Button>
          </Stack>
        </Paper>
      )}
    </Box>
  );
}
