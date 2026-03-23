"use client";

import React, { useState, useCallback, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Stack,
  Alert,
  AlertTitle,
  Divider,
  IconButton,
  Tooltip,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
} from "@mui/material";
import {
  GridColDef,
  GridRowModel,
  GridRenderCellParams,
} from "@mui/x-data-grid";
import { ZenttoDataGrid, FormGrid, FormField, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/DeleteOutlined";
import SaveIcon from "@mui/icons-material/Save";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import ArticleIcon from "@mui/icons-material/Article";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useRouter } from "next/navigation";
import { useCreateAsiento, usePlanCuentas } from "../hooks/useContabilidad";
import { useCentrosCostoList } from "../hooks/useContabilidadAdvanced";

// ─── Tipos ─────────────────────────────────────────────────────

interface DetalleLinea {
  id: string;
  codCuenta: string;
  descripcion: string;
  centroCosto?: string;
  documento?: string;
  debe: number;
  haber: number;
}

// ─── Componente Principal ──────────────────────────────────────

export default function NuevoAsientoPage() {
  const router = useRouter();
  const { timeZone } = useTimezone();
  const createMutation = useCreateAsiento();
  const { data: cuentasData } = usePlanCuentas();
  const { data: centrosCostoData } = useCentrosCostoList();

  // Form state
  const [fecha, setFecha] = useState(toDateOnly(new Date(), timeZone));
  const [tipoAsiento, setTipoAsiento] = useState("DIARIO");
  const [concepto, setConcepto] = useState("");
  const [referencia, setReferencia] = useState("");
  const [error, setError] = useState<string | null>(null);

  // Detalle lines
  const [lineas, setLineas] = useState<DetalleLinea[]>([
    { id: "1", codCuenta: "", descripcion: "", debe: 0, haber: 0 },
    { id: "2", codCuenta: "", descripcion: "", debe: 0, haber: 0 },
  ]);

  // Cuentas para el autocomplete
  const cuentas = useMemo(() => {
    return (cuentasData?.data || [])
      .filter((c: any) => c.aceptaDetalle !== false)
      .map((c: any) => ({
        codCuenta: c.codCuenta || c.Cod_Cuenta,
        descripcion: c.descripcion || c.Desc_Cta,
      }))
      .sort((a: any, b: any) => a.codCuenta.localeCompare(b.codCuenta));
  }, [cuentasData]);

  // Centros de costo para singleSelect
  const centrosCosto = useMemo(() => {
    return (centrosCostoData?.data ?? centrosCostoData?.rows ?? []).map(
      (c: any) => c.CostCenterCode ?? c.costCenterCode ?? c.codigo ?? c.code ?? ""
    );
  }, [centrosCostoData]);

  // Totales
  const { totalDebe, totalHaber, diferencia } = useMemo(() => {
    const td = lineas.reduce((sum, l) => sum + (Number(l.debe) || 0), 0);
    const th = lineas.reduce((sum, l) => sum + (Number(l.haber) || 0), 0);
    return {
      totalDebe: td,
      totalHaber: th,
      diferencia: td - th,
    };
  }, [lineas]);

  const isBalanced = Math.abs(diferencia) < 0.01;

  // Handlers
  const handleAddLinea = () => {
    const newId = Math.max(...lineas.map((l) => Number(l.id)), 0) + 1;
    setLineas([...lineas, { id: String(newId), codCuenta: "", descripcion: "", debe: 0, haber: 0 }]);
  };

  const handleDeleteLinea = (id: string) => {
    if (lineas.length <= 2) {
      setError("El asiento debe tener al menos 2 líneas");
      return;
    }
    setLineas(lineas.filter((l) => l.id !== id));
    setError(null);
  };

  const handleLineaChange = (id: string, field: keyof DetalleLinea, value: any) => {
    setLineas((prev) =>
      prev.map((l) => {
        if (l.id !== id) return l;
        
        if (field === "codCuenta") {
          const cuenta = cuentas.find((c: any) => c.codCuenta === value);
          return {
            ...l,
            codCuenta: value,
            descripcion: cuenta?.descripcion || "",
          };
        }
        
        if (field === "debe" && Number(value) > 0) {
          return { ...l, [field]: Number(value), haber: 0 };
        }
        if (field === "haber" && Number(value) > 0) {
          return { ...l, [field]: Number(value), debe: 0 };
        }
        
        return { ...l, [field]: value };
      })
    );
  };

  const handleProcessRowUpdate = useCallback(
    (newRow: GridRowModel) => {
      const updated = { ...newRow } as DetalleLinea;
      setLineas((prev) =>
        prev.map((l) => (l.id === updated.id ? updated : l))
      );
      return updated;
    },
    []
  );

  const handleSubmit = async () => {
    setError(null);

    // Validaciones
    if (!concepto.trim()) {
      setError("El concepto es obligatorio");
      return;
    }
    if (!isBalanced) {
      setError(`El asiento no está cuadrado. Diferencia: ${formatCurrency(Math.abs(diferencia))}`);
      return;
    }
    if (totalDebe === 0) {
      setError("El asiento no puede estar vacío");
      return;
    }

    const lineasValidas = lineas.filter((l) => l.codCuenta && (l.debe > 0 || l.haber > 0));
    if (lineasValidas.length < 2) {
      setError("El asiento debe tener al menos 2 líneas con valores");
      return;
    }

    try {
      await createMutation.mutateAsync({
        fecha,
        tipoAsiento,
        concepto,
        referencia,
        detalle: lineasValidas.map((l) => ({
          codCuenta: l.codCuenta,
          descripcion: l.descripcion,
          centroCosto: l.centroCosto,
          documento: l.documento,
          debe: l.debe,
          haber: l.haber,
        })),
      });
      
      router.push("/contabilidad/asientos");
    } catch (err: any) {
      setError(err.message || "Error al crear el asiento");
    }
  };

  // Columnas del grid de detalle
  const columns: GridColDef[] = [
    {
      field: "codCuenta",
      headerName: "Cuenta",
      width: 140,
      editable: true,
      type: "singleSelect",
      valueOptions: cuentas.map((c: any) => c.codCuenta),
      renderCell: (params: GridRenderCellParams) => (
        <Box sx={{ fontFamily: "monospace", fontWeight: 500 }}>
          {params.value}
        </Box>
      ),
    },
    {
      field: "descripcion",
      headerName: "Descripción",
      flex: 1,
      minWidth: 200,
      editable: true,
    },
    {
      field: "centroCosto",
      headerName: "C. Costo",
      width: 120,
      editable: true,
      type: "singleSelect",
      valueOptions: centrosCosto,
    },
    {
      field: "documento",
      headerName: "Documento",
      width: 120,
      editable: true,
    },
    {
      field: "debe",
      headerName: "Debe",
      width: 130,
      type: "number",
      editable: true,
      renderCell: (p) => p.value > 0 ? formatCurrency(p.value) : "",
      renderEditCell: (params) => (
        <TextField
          type="number"
          value={params.value || ""}
          onChange={(e) => params.api.setEditCellValue({ id: params.id, field: params.field, value: Number(e.target.value) })}
          inputProps={{ step: 0.01, min: 0 }}
        />
      ),
    },
    {
      field: "haber",
      headerName: "Haber",
      width: 130,
      type: "number",
      editable: true,
      renderCell: (p) => p.value > 0 ? formatCurrency(p.value) : "",
      renderEditCell: (params) => (
        <TextField
          type="number"
          value={params.value || ""}
          onChange={(e) => params.api.setEditCellValue({ id: params.id, field: params.field, value: Number(e.target.value) })}
          inputProps={{ step: 0.01, min: 0 }}
        />
      ),
    },
    {
      field: "actions",
      type: "actions",
      headerName: "",
      width: 50,
      getActions: (params) => [
        <Tooltip key="delete" title="Eliminar línea">
          <IconButton
            size="small"
            color="error"
            onClick={() => handleDeleteLinea(params.id as string)}
          >
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Tooltip>,
      ],
    },
  ];

  return (
    <Box>
      {/* Header */}
      <Stack direction="row" alignItems="center" spacing={2} mb={3}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => router.push("/contabilidad/asientos")}
        >
          Volver
        </Button>
      </Stack>

      {/* Alertas */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          <AlertTitle>Error</AlertTitle>
          {error}
        </Alert>
      )}

      {!isBalanced && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          <AlertTitle>Asiento descuadrado</AlertTitle>
          Diferencia: {formatCurrency(diferencia)} (Debe: {formatCurrency(totalDebe)} - Haber: {formatCurrency(totalHaber)})
        </Alert>
      )}

      {/* Datos del Asiento */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <ArticleIcon />
            Datos del Asiento
          </Typography>
          
          <FormGrid spacing={2}>
            <FormField xs={12} md={3}>
              <DatePicker
                label="Fecha"
                value={fecha ? dayjs(fecha) : null}
                onChange={(v) => setFecha(v ? v.format('YYYY-MM-DD') : '')}
                slotProps={{ textField: { size: 'small', fullWidth: true } }}
              />
            </FormField>
            <FormField xs={12} md={3}>
              <FormControl>
                <InputLabel>Tipo de Asiento</InputLabel>
                <Select
                  value={tipoAsiento}
                  label="Tipo de Asiento"
                  onChange={(e) => setTipoAsiento(e.target.value)}
                >
                  <MenuItem value="DIARIO">Diario</MenuItem>
                  <MenuItem value="APERTURA">Apertura</MenuItem>
                  <MenuItem value="CIERRE">Cierre</MenuItem>
                  <MenuItem value="AJUSTE">Ajuste</MenuItem>
                  <MenuItem value="COMPRA">Compra</MenuItem>
                  <MenuItem value="VENTA">Venta</MenuItem>
                  <MenuItem value="NOMINA">Nómina</MenuItem>
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} md={3}>
              <TextField
                label="Referencia"
                value={referencia}
                onChange={(e) => setReferencia(e.target.value)}
                placeholder="Ej: FAC-001"
              />
            </FormField>
            <FormField xs={12} md={3}>
              <Box sx={{ display: "flex", gap: 1, alignItems: "center", height: "100%" }}>
                <Chip
                  label={isBalanced ? "✓ Cuadrado" : "⚠ Descuadrado"}
                  color={isBalanced ? "success" : "warning"}
                  sx={{ fontWeight: 600 }}
                />
              </Box>
            </FormField>
            <FormField xs={12}>
              <TextField
                label="Concepto"
                value={concepto}
                onChange={(e) => setConcepto(e.target.value)}
                required
                placeholder="Describa el motivo del asiento..."
              />
            </FormField>
          </FormGrid>
        </CardContent>
      </Card>

      {/* Detalle del Asiento */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">
              Detalle del Asiento
            </Typography>
            <Button
              variant="outlined"
              startIcon={<AddIcon />}
              onClick={handleAddLinea}
            >
              Agregar línea
            </Button>
          </Stack>

          <Box sx={{ height: 300, mb: 2 }}>
            <ZenttoDataGrid
              rows={lineas}
              columns={columns}
              editMode="cell"
              processRowUpdate={handleProcessRowUpdate}
              onProcessRowUpdateError={(error) => console.error(error)}
              hideFooter
              disableRowSelectionOnClick
              getRowId={(r) => r.id}
              hideToolbar
              mobileDetailDrawer={false}
              mobileVisibleFields={["codCuenta", "descripcion"]}
            />
          </Box>

          {/* Totales */}
          <Divider sx={{ my: 2 }} />
          <FormGrid spacing={2} justifyContent="flex-end">
            <FormField xs={12} md={4}>
              <Paper sx={{ p: 2, bgcolor: "success.light", color: "success.contrastText" }}>
                <Typography variant="body2">Total debe</Typography>
                <Typography variant="h5" fontWeight={700}>
                  {formatCurrency(totalDebe)}
                </Typography>
              </Paper>
            </FormField>
            <FormField xs={12} md={4}>
              <Paper sx={{ p: 2, bgcolor: "info.light", color: "info.contrastText" }}>
                <Typography variant="body2">Total haber</Typography>
                <Typography variant="h5" fontWeight={700}>
                  {formatCurrency(totalHaber)}
                </Typography>
              </Paper>
            </FormField>
            <FormField xs={12} md={4}>
              <Paper
                sx={{
                  p: 2,
                  bgcolor: isBalanced ? "success.main" : "warning.main",
                  color: "white",
                }}
              >
                <Typography variant="body2">Diferencia</Typography>
                <Typography variant="h5" fontWeight={700}>
                  {formatCurrency(diferencia)}
                </Typography>
              </Paper>
            </FormField>
          </FormGrid>
        </CardContent>
      </Card>

      {/* Botones de Acción */}
      <Stack direction="row" spacing={2} justifyContent="flex-end">
        <Button
          variant="outlined"
          onClick={() => router.push("/contabilidad/asientos")}
        >
          Cancelar
        </Button>
        <Button
          variant="contained"
          startIcon={<SaveIcon />}
          onClick={handleSubmit}
          disabled={createMutation.isPending || !isBalanced}
          size="large"
        >
          {createMutation.isPending ? "Guardando..." : "Guardar asiento"}
        </Button>
      </Stack>
    </Box>
  );
}
