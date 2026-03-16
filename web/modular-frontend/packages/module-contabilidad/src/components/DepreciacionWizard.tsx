"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Alert,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
} from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { CustomStepper, type StepDef } from "@zentto/shared-ui";
import { formatCurrency } from "@zentto/shared-api";
import {
  usePreviewDepreciacion,
  useCalcularDepreciacion,
} from "../hooks/useActivosFijos";

const steps: StepDef[] = [
  { label: "Seleccionar Periodo" },
  { label: "Vista Previa" },
  { label: "Confirmar" },
];

export default function DepreciacionWizard() {
  const [activeStep, setActiveStep] = useState(0);
  const [periodo, setPeriodo] = useState("");
  const [costCenterCode, setCostCenterCode] = useState("");
  const [result, setResult] = useState<any>(null);

  const previewMutation = usePreviewDepreciacion();
  const calcularMutation = useCalcularDepreciacion();

  const previewRows = previewMutation.data?.rows ?? [];

  const handlePreview = async () => {
    await previewMutation.mutateAsync({
      periodo,
      costCenterCode: costCenterCode || undefined,
    });
    setActiveStep(1);
  };

  const handleCalcular = async () => {
    const res = await calcularMutation.mutateAsync({
      periodo,
      costCenterCode: costCenterCode || undefined,
    });
    setResult(res);
    setActiveStep(2);
  };

  const handleReset = () => {
    setActiveStep(0);
    setPeriodo("");
    setCostCenterCode("");
    setResult(null);
    previewMutation.reset();
    calcularMutation.reset();
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 } }}>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700 }}>
        Calculo de Depreciacion
      </Typography>

      <CustomStepper steps={steps} activeStep={activeStep} />

      <Paper sx={{ mt: 3, p: 3 }}>
        {/* Paso 1: Seleccionar Periodo */}
        {activeStep === 0 && (
          <Stack spacing={3} sx={{ maxWidth: 400 }}>
            <Typography variant="h6">Seleccione el periodo a depreciar</Typography>
            <TextField
              label="Periodo (YYYY-MM)"
              size="small"
              placeholder="2026-03"
              value={periodo}
              onChange={(e) => setPeriodo(e.target.value)}
              inputProps={{ maxLength: 7 }}
            />
            <TextField
              label="Centro de Costo (opcional)"
              size="small"
              value={costCenterCode}
              onChange={(e) => setCostCenterCode(e.target.value)}
            />
            <Box>
              <Button
                variant="contained"
                onClick={handlePreview}
                disabled={!periodo || previewMutation.isPending}
                startIcon={previewMutation.isPending ? <CircularProgress size={16} /> : undefined}
              >
                Vista Previa
              </Button>
            </Box>
          </Stack>
        )}

        {/* Paso 2: Preview */}
        {activeStep === 1 && (
          <Box>
            <Typography variant="h6" mb={2}>
              Vista Previa - {previewRows.length} activo(s) a depreciar
            </Typography>

            {previewRows.length === 0 ? (
              <Alert severity="info">
                No hay activos pendientes de depreciacion para el periodo seleccionado.
              </Alert>
            ) : (
              <>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Codigo</TableCell>
                      <TableCell>Descripcion</TableCell>
                      <TableCell align="right">Monto Dep.</TableCell>
                      <TableCell align="right">Dep. Acumulada</TableCell>
                      <TableCell align="right">Valor en Libros</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {previewRows.map((row: any, idx: number) => (
                      <TableRow key={row.AssetId ?? idx}>
                        <TableCell>{row.AssetCode ?? row.AssetId}</TableCell>
                        <TableCell>{row.Description ?? "-"}</TableCell>
                        <TableCell align="right">{formatCurrency(row.Amount)}</TableCell>
                        <TableCell align="right">{formatCurrency(row.AccumulatedDepreciation)}</TableCell>
                        <TableCell align="right">{formatCurrency(row.BookValue)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>

                <Stack direction="row" spacing={2} mt={3}>
                  <Button variant="outlined" onClick={() => setActiveStep(0)}>
                    Atras
                  </Button>
                  <Button
                    variant="contained"
                    onClick={handleCalcular}
                    disabled={calcularMutation.isPending}
                    startIcon={calcularMutation.isPending ? <CircularProgress size={16} /> : undefined}
                  >
                    Generar Depreciacion
                  </Button>
                </Stack>
              </>
            )}
          </Box>
        )}

        {/* Paso 3: Confirmacion */}
        {activeStep === 2 && (
          <Box textAlign="center" py={4}>
            <CheckCircleIcon sx={{ fontSize: 64, color: "success.main", mb: 2 }} />
            <Typography variant="h6" gutterBottom>
              Depreciacion generada exitosamente
            </Typography>
            <Typography variant="body1" color="text.secondary" mb={1}>
              Periodo: <strong>{periodo}</strong>
            </Typography>
            {result?.entriesGenerated != null && (
              <Typography variant="body1" color="text.secondary" mb={3}>
                Asientos generados: <strong>{result.entriesGenerated}</strong>
              </Typography>
            )}
            <Button variant="contained" onClick={handleReset}>
              Nuevo Calculo
            </Button>
          </Box>
        )}
      </Paper>
    </Box>
  );
}
