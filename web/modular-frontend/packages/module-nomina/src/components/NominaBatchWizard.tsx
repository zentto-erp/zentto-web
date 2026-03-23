"use client";

import React, { useState, useCallback } from "react";
import {
  Box, Paper, Typography, Button, TextField, Stepper, Step, StepLabel,
  Select, MenuItem, FormControl, InputLabel, Switch, FormControlLabel,
  CircularProgress, Alert, Stack, Chip, Divider, LinearProgress,
  Dialog, DialogTitle, DialogContent, DialogActions,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import PlayArrowIcon from "@mui/icons-material/PlayArrow";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import DraftsIcon from "@mui/icons-material/Drafts";
import GroupsIcon from "@mui/icons-material/Groups";
import FactCheckIcon from "@mui/icons-material/FactCheck";
import ThumbUpAltIcon from "@mui/icons-material/ThumbUpAlt";
import RocketLaunchIcon from "@mui/icons-material/RocketLaunch";
import DescriptionIcon from "@mui/icons-material/Description";
import dynamic from "next/dynamic";
const DocumentViewerModal = dynamic(() => import("./DocumentViewerModal"), { ssr: false });
import { brandColors, FormGrid, FormField, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatCurrency, useLookup } from "@zentto/shared-api";
import {
  useGenerateDraft,
  useBatchSummary,
  useBatchGrid,
  useApproveDraft,
  useProcessBatch,
  type BatchGridRow,
} from "../hooks/useNominaBatch";
import PayrollBatchGrid from "./PayrollBatchGrid";
import PayrollPreview from "./PayrollPreview";

const STEPS = [
  { label: "Configurar Lote", icon: <DraftsIcon /> },
  { label: "Editar Nómina", icon: <GroupsIcon /> },
  { label: "Pre-Nómina", icon: <FactCheckIcon /> },
  { label: "Aprobar", icon: <ThumbUpAltIcon /> },
  { label: "Procesar", icon: <RocketLaunchIcon /> },
];

interface Props {
  onBack?: () => void;
}

export default function NominaBatchWizard({ onBack }: Props) {
  const [activeStep, setActiveStep] = useState(0);
  const [batchId, setBatchId] = useState<number | null>(null);
  const [docEmployee, setDocEmployee] = useState<string | null>(null);
  const [config, setConfig] = useState({
    nomina: "QUINCENAL",
    fechaInicio: "",
    fechaHasta: "",
    departamento: "",
    soloActivos: true,
  });

  const { data: frequencies = [] } = useLookup('PAYROLL_FREQUENCY');
  const generateDraft = useGenerateDraft();
  const summary = useBatchSummary(batchId);
  const batchGrid = useBatchGrid(docEmployee === "__batch__" ? batchId : null);
  const approveDraft = useApproveDraft();
  const processBatch = useProcessBatch();

  const batchEmployees: BatchGridRow[] = Array.isArray((batchGrid.data as any)?.data)
    ? (batchGrid.data as any).data
    : Array.isArray(batchGrid.data) ? batchGrid.data : [];

  const summaryData = summary.data?.data ?? summary.data ?? null;

  const handleGenerateDraft = useCallback(async () => {
    const result = await generateDraft.mutateAsync({
      nomina: config.nomina,
      fechaInicio: config.fechaInicio,
      fechaHasta: config.fechaHasta,
      departamento: config.departamento || undefined,
    });
    if (result?.batchId) {
      setBatchId(result.batchId);
      setActiveStep(1);
    }
  }, [config, generateDraft]);

  const handleApprove = useCallback(async () => {
    if (!batchId) return;
    await approveDraft.mutateAsync(batchId);
    setActiveStep(4);
  }, [batchId, approveDraft]);

  const handleProcess = useCallback(async () => {
    if (!batchId) return;
    await processBatch.mutateAsync(batchId);
  }, [batchId, processBatch]);

  const canGoNext = () => {
    if (activeStep === 0) return config.nomina && config.fechaInicio && config.fechaHasta;
    if (activeStep === 1) return !!batchId;
    if (activeStep === 2) return !!batchId;
    return true;
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Header */}
      <Box sx={{ px: 3, py: 2, display: "flex", alignItems: "center", gap: 2 }}>
        {onBack && (
          <Button startIcon={<ArrowBackIcon />} onClick={onBack} color="secondary" size="small">
            Volver
          </Button>
        )}
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          Procesar Nómina Masiva
        </Typography>
        {batchId && (
          <Chip label={`Lote #${batchId}`} color="primary" size="small" />
        )}
      </Box>

      {/* Stepper */}
      <Paper sx={{ mx: 3, mb: 2, p: 2, borderRadius: 2 }}>
        <Stepper activeStep={activeStep} alternativeLabel>
          {STEPS.map((step, idx) => (
            <Step key={step.label} completed={activeStep > idx}>
              <StepLabel
                StepIconComponent={() => (
                  <Box
                    sx={{
                      width: 40,
                      height: 40,
                      borderRadius: "50%",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      bgcolor: activeStep > idx
                        ? brandColors.success
                        : activeStep === idx
                          ? brandColors.accent
                          : "grey.300",
                      color: activeStep >= idx ? "#fff" : "text.secondary",
                      transition: "all 0.3s",
                    }}
                  >
                    {activeStep > idx ? <CheckCircleIcon fontSize="small" /> : step.icon}
                  </Box>
                )}
              >
                <Typography
                  variant="caption"
                  sx={{
                    fontWeight: activeStep === idx ? 700 : 400,
                    color: activeStep === idx ? "text.primary" : "text.secondary",
                  }}
                >
                  {step.label}
                </Typography>
              </StepLabel>
            </Step>
          ))}
        </Stepper>
      </Paper>

      {/* Step Content */}
      <Box sx={{ flex: 1, mx: 3, mb: 2, display: "flex", flexDirection: "column", minHeight: 0, overflow: "auto" }}>
        {/* Step 0: Config */}
        {activeStep === 0 && (
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="h6" sx={{ mb: 3, fontWeight: 600 }}>
              Configurar Lote de Nómina
            </Typography>
            <FormGrid spacing={3}>
              <FormField xs={12} md={4}>
                <FormControl size="small">
                  <InputLabel>Tipo de Nómina</InputLabel>
                  <Select
                    value={config.nomina}
                    label="Tipo de Nómina"
                    onChange={(e) => setConfig((c) => ({ ...c, nomina: e.target.value }))}
                  >
                    {frequencies.map(f => <MenuItem key={f.Code} value={f.Code}>{f.Label}</MenuItem>)}
                  </Select>
                </FormControl>
              </FormField>
              <FormField xs={12} md={4}>
                <DatePicker
                  label="Fecha Inicio"
                  value={config.fechaInicio ? dayjs(config.fechaInicio) : null}
                  onChange={(v) => setConfig((c) => ({ ...c, fechaInicio: v ? v.format('YYYY-MM-DD') : '' }))}
                  slotProps={{ textField: { size: 'small', fullWidth: true } }}
                />
              </FormField>
              <FormField xs={12} md={4}>
                <DatePicker
                  label="Fecha Hasta"
                  value={config.fechaHasta ? dayjs(config.fechaHasta) : null}
                  onChange={(v) => setConfig((c) => ({ ...c, fechaHasta: v ? v.format('YYYY-MM-DD') : '' }))}
                  slotProps={{ textField: { size: 'small', fullWidth: true } }}
                />
              </FormField>
              <FormField xs={12} md={4}>
                <TextField
                  label="Departamento (opcional)"
                  size="small"
                  value={config.departamento}
                  onChange={(e) => setConfig((c) => ({ ...c, departamento: e.target.value }))}
                  helperText="Dejar vacío para incluir todos"
                />
              </FormField>
              <FormField xs={12} md={4}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={config.soloActivos}
                      onChange={(e) => setConfig((c) => ({ ...c, soloActivos: e.target.checked }))}
                    />
                  }
                  label="Solo empleados activos"
                />
              </FormField>
            </FormGrid>

            <Divider sx={{ my: 3 }} />

            <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
              <Button
                variant="contained"
                size="large"
                startIcon={generateDraft.isPending ? <CircularProgress size={18} /> : <PlayArrowIcon />}
                onClick={handleGenerateDraft}
                disabled={!canGoNext() || generateDraft.isPending}
              >
                Generar Borrador
              </Button>
            </Box>

            {generateDraft.isError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {String((generateDraft.error as Error)?.message || "Error al generar borrador")}
              </Alert>
            )}
          </Paper>
        )}

        {/* Step 1: Grid Editable */}
        {activeStep === 1 && batchId && (
          <PayrollBatchGrid batchId={batchId} />
        )}

        {/* Step 2: Pre-Nómina / Preview */}
        {activeStep === 2 && batchId && (
          <PayrollPreview batchId={batchId} />
        )}

        {/* Step 3: Approve */}
        {activeStep === 3 && batchId && (
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
              Aprobar Nómina
            </Typography>
            {summaryData && (
              <Box sx={{ mb: 3 }}>
                <FormGrid spacing={2}>
                  <FormField xs={12} md={3}>
                    <Paper sx={{ p: 2, textAlign: "center", bgcolor: brandColors.success, color: "#fff", borderRadius: 2 }}>
                      <Typography variant="h4" sx={{ fontWeight: 700 }}>{summaryData.totalEmployees ?? 0}</Typography>
                      <Typography variant="body2">Empleados</Typography>
                    </Paper>
                  </FormField>
                  <FormField xs={12} md={3}>
                    <Paper sx={{ p: 2, textAlign: "center", bgcolor: brandColors.statBlue, color: "#fff", borderRadius: 2 }}>
                      <Typography variant="h5" sx={{ fontWeight: 700 }}>{formatCurrency(summaryData.totalGross ?? 0)}</Typography>
                      <Typography variant="body2">Total Bruto</Typography>
                    </Paper>
                  </FormField>
                  <FormField xs={12} md={3}>
                    <Paper sx={{ p: 2, textAlign: "center", bgcolor: brandColors.statRed, color: "#fff", borderRadius: 2 }}>
                      <Typography variant="h5" sx={{ fontWeight: 700 }}>{formatCurrency(summaryData.totalDeductions ?? 0)}</Typography>
                      <Typography variant="body2">Deducciones</Typography>
                    </Paper>
                  </FormField>
                  <FormField xs={12} md={3}>
                    <Paper sx={{ p: 2, textAlign: "center", bgcolor: brandColors.accent, color: brandColors.dark, borderRadius: 2 }}>
                      <Typography variant="h5" sx={{ fontWeight: 700 }}>{formatCurrency(summaryData.totalNet ?? 0)}</Typography>
                      <Typography variant="body2">Neto a Pagar</Typography>
                    </Paper>
                  </FormField>
                </FormGrid>
              </Box>
            )}

            <Alert severity="info" sx={{ mb: 3 }}>
              Al aprobar, la nómina quedará bloqueada para edición. Solo podrá revertirse creando un nuevo lote.
            </Alert>

            <Box sx={{ display: "flex", justifyContent: "flex-end" }}>
              <Button
                variant="contained"
                color="success"
                size="large"
                startIcon={approveDraft.isPending ? <CircularProgress size={18} /> : <ThumbUpAltIcon />}
                onClick={handleApprove}
                disabled={approveDraft.isPending}
              >
                Aprobar Nómina
              </Button>
            </Box>
          </Paper>
        )}

        {/* Step 4: Process */}
        {activeStep === 4 && batchId && (
          <Paper sx={{ p: 3, borderRadius: 2 }}>
            <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
              Procesar Nómina
            </Typography>

            {processBatch.isIdle && (
              <Box sx={{ textAlign: "center", py: 4 }}>
                <RocketLaunchIcon sx={{ fontSize: 64, color: brandColors.accent, mb: 2 }} />
                <Typography variant="h6" sx={{ mb: 1 }}>
                  Nómina aprobada y lista para procesar
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                  Se generarán los recibos de pago para todos los empleados del lote.
                </Typography>
                <Button
                  variant="contained"
                  size="large"
                  startIcon={<PlayArrowIcon />}
                  onClick={handleProcess}
                >
                  Procesar Ahora
                </Button>
              </Box>
            )}

            {processBatch.isPending && (
              <Box sx={{ textAlign: "center", py: 4 }}>
                <CircularProgress size={64} sx={{ mb: 2 }} />
                <Typography variant="h6">Procesando nómina...</Typography>
                <Typography variant="body2" color="text.secondary">
                  Generando recibos para cada empleado. No cierre esta ventana.
                </Typography>
                <LinearProgress sx={{ mt: 3, maxWidth: 400, mx: "auto" }} />
              </Box>
            )}

            {processBatch.isSuccess && (
              <Box sx={{ textAlign: "center", py: 4 }}>
                <CheckCircleIcon sx={{ fontSize: 64, color: brandColors.success, mb: 2 }} />
                <Typography variant="h5" sx={{ fontWeight: 700, mb: 1 }}>
                  Nómina Procesada Exitosamente
                </Typography>
                <Stack direction="row" spacing={3} justifyContent="center" sx={{ mb: 3 }}>
                  <Box>
                    <Typography variant="h4" sx={{ fontWeight: 700, color: brandColors.success }}>
                      {(processBatch.data as any)?.procesados ?? 0}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">Procesados</Typography>
                  </Box>
                  {Number((processBatch.data as any)?.errores ?? 0) > 0 && (
                    <Box>
                      <Typography variant="h4" sx={{ fontWeight: 700, color: brandColors.danger }}>
                        {(processBatch.data as any)?.errores ?? 0}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">Errores</Typography>
                    </Box>
                  )}
                </Stack>
                <Stack direction="row" spacing={2} justifyContent="center">
                  <Button
                    variant="contained"
                    startIcon={<DescriptionIcon />}
                    onClick={() => setDocEmployee("__batch__")}
                  >
                    Generar Recibos de Pago
                  </Button>
                  {onBack && (
                    <Button variant="outlined" onClick={onBack}>
                      Volver a Nóminas
                    </Button>
                  )}
                </Stack>
              </Box>
            )}

            {processBatch.isError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {String((processBatch.error as Error)?.message || "Error al procesar")}
              </Alert>
            )}
          </Paper>
        )}
      </Box>

      {/* Batch Documents Dialog — lista de empleados para generar recibos */}
      <Dialog
        open={docEmployee === "__batch__"}
        onClose={() => setDocEmployee(null)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <DescriptionIcon color="primary" />
            <Typography fontWeight={700}>Generar Recibos de Pago</Typography>
            {batchId && <Chip label={`Lote #${batchId}`} size="small" color="primary" variant="outlined" />}
          </Box>
        </DialogTitle>
        <DialogContent dividers>
          {batchGrid.isLoading && <Box textAlign="center" py={3}><CircularProgress /></Box>}
          {!batchGrid.isLoading && batchEmployees.length === 0 && (
            <Alert severity="info">No hay empleados en este lote.</Alert>
          )}
          <Stack spacing={1}>
            {batchEmployees.map((emp) => (
              <Paper key={emp.employeeCode} variant="outlined" sx={{ p: 1.5, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <Box>
                  <Typography variant="body2" fontWeight={600}>{emp.employeeName}</Typography>
                  <Typography variant="caption" color="text.secondary">{emp.employeeCode}</Typography>
                </Box>
                <Stack direction="row" spacing={1} alignItems="center">
                  <Typography variant="body2" color="success.main" fontWeight={600}>
                    {formatCurrency(emp.totalNeto)}
                  </Typography>
                  <Button
                    size="small"
                    variant="outlined"
                    startIcon={<DescriptionIcon />}
                    onClick={() => setDocEmployee(emp.employeeCode)}
                  >
                    Recibo
                  </Button>
                </Stack>
              </Paper>
            ))}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDocEmployee(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Individual document viewer */}
      {docEmployee && docEmployee !== "__batch__" && batchId && (
        <DocumentViewerModal
          open={!!docEmployee && docEmployee !== "__batch__"}
          onClose={() => setDocEmployee("__batch__")}
          batchId={batchId}
          employeeCode={docEmployee}
          documentType="payroll"
        />
      )}

      {/* Navigation Buttons */}
      {activeStep > 0 && activeStep < 4 && (
        <Paper sx={{ mx: 3, mb: 2, p: 2, display: "flex", justifyContent: "space-between", borderRadius: 2 }}>
          <Button
            startIcon={<ArrowBackIcon />}
            onClick={() => setActiveStep((s) => s - 1)}
            disabled={activeStep === 0}
          >
            Anterior
          </Button>
          <Button
            variant="contained"
            endIcon={<ArrowForwardIcon />}
            onClick={() => setActiveStep((s) => s + 1)}
            disabled={!canGoNext()}
          >
            {activeStep === 2 ? "Ir a Aprobación" : "Siguiente"}
          </Button>
        </Paper>
      )}
    </Box>
  );
}
