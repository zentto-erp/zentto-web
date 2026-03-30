"use client";

import React, { useState, useCallback, useMemo, useEffect, useRef } from "react";
import {
  Box, Paper, Typography, TextField, Button, Stack, Alert, AlertTitle, Divider,
  IconButton, Tooltip, Card, CardContent, FormControl, InputLabel, Select, MenuItem, Chip,
} from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { FormGrid, FormField, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/DeleteOutlined";
import SaveIcon from "@mui/icons-material/Save";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ArticleIcon from "@mui/icons-material/Article";
import { useGridLayoutSync, formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useRouter } from "next/navigation";
import { useCreateAsiento, usePlanCuentas } from "../hooks/useContabilidad";
import { useCentrosCostoList } from "../hooks/useContabilidadAdvanced";
import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
import { CircularProgress } from "@mui/material";


interface DetalleLinea {
  id: string; codCuenta: string; descripcion: string; centroCosto?: string; documento?: string; debe: number; haber: number;
}

const COLUMNS: ColumnDef[] = [
  { field: "codCuenta", header: "Cuenta", width: 140, sortable: true },
  { field: "descripcion", header: "Descripcion", flex: 1, minWidth: 200 },
  { field: "centroCosto", header: "C. Costo", width: 120 },
  { field: "documento", header: "Documento", width: 120 },
  { field: "debe", header: "Debe", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  { field: "haber", header: "Haber", width: 130, type: "number", currency: "VES", aggregation: "sum" },
  {
    field: "actions",
    header: "Acciones",
    type: "actions",
    width: 100,
    pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#d32f2f" },
    ],
  },
];

const GRID_IDS = {
  gridRef: buildContabilidadGridId("nuevo-asiento", "main"),
} as const;

export default function NuevoAsientoPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const router = useRouter();
  const { timeZone } = useTimezone();
  const createMutation = useCreateAsiento();
  const { data: cuentasData } = usePlanCuentas();
  const { data: centrosCostoData } = useCentrosCostoList();

  const [fecha, setFecha] = useState(toDateOnly(new Date(), timeZone));
  const [tipoAsiento, setTipoAsiento] = useState("DIARIO");
  const [concepto, setConcepto] = useState("");
  const [referencia, setReferencia] = useState("");
  const [error, setError] = useState<string | null>(null);

  const [lineas, setLineas] = useState<DetalleLinea[]>([
    { id: "1", codCuenta: "", descripcion: "", debe: 0, haber: 0 },
    { id: "2", codCuenta: "", descripcion: "", debe: 0, haber: 0 },
  ]);

  const { totalDebe, totalHaber, diferencia } = useMemo(() => {
    const td = lineas.reduce((sum, l) => sum + (Number(l.debe) || 0), 0);
    const th = lineas.reduce((sum, l) => sum + (Number(l.haber) || 0), 0);
    return { totalDebe: td, totalHaber: th, diferencia: td - th };
  }, [lineas]);

  const isBalanced = Math.abs(diferencia) < 0.01;

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = lineas;
  }, [lineas, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "edit") {
        console.log("Editar linea asiento:", row);
      } else if (action === "delete") {
        setLineas((prev) => prev.filter((l) => l.id !== row.id));
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered]);

  const handleAddLinea = () => {
    const newId = Math.max(...lineas.map((l) => Number(l.id)), 0) + 1;
    setLineas([...lineas, { id: String(newId), codCuenta: "", descripcion: "", debe: 0, haber: 0 }]);
  };

  const handleSubmit = async () => {
    setError(null);
    if (!concepto.trim()) { setError("El concepto es obligatorio"); return; }
    if (!isBalanced) { setError(`El asiento no esta cuadrado. Diferencia: ${formatCurrency(Math.abs(diferencia))}`); return; }
    if (totalDebe === 0) { setError("El asiento no puede estar vacio"); return; }
    const lineasValidas = lineas.filter((l) => l.codCuenta && (l.debe > 0 || l.haber > 0));
    if (lineasValidas.length < 2) { setError("El asiento debe tener al menos 2 lineas con valores"); return; }
    try {
      await createMutation.mutateAsync({
        fecha, tipoAsiento, concepto, referencia,
        detalle: lineasValidas.map((l) => ({ codCuenta: l.codCuenta, descripcion: l.descripcion, centroCosto: l.centroCosto, documento: l.documento, debe: l.debe, haber: l.haber })),
      });
      router.push("/asientos");
    } catch (err: any) { setError(err.message || "Error al crear el asiento"); }
  };

  return (
    <Box>
      <Stack direction="row" alignItems="center" spacing={2} mb={3}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/asientos")}>Volver</Button>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}><AlertTitle>Error</AlertTitle>{error}</Alert>}
      {!isBalanced && (
        <Alert severity="warning" sx={{ mb: 2 }}><AlertTitle>Asiento descuadrado</AlertTitle>
          Diferencia: {formatCurrency(diferencia)} (Debe: {formatCurrency(totalDebe)} - Haber: {formatCurrency(totalHaber)})
        </Alert>
      )}

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom sx={{ display: "flex", alignItems: "center", gap: 1 }}><ArticleIcon />Datos del Asiento</Typography>
          <FormGrid spacing={2}>
            <FormField xs={12} md={3}>
              <DatePicker label="Fecha" value={fecha ? dayjs(fecha) : null} onChange={(v) => setFecha(v ? v.format('YYYY-MM-DD') : '')} slotProps={{ textField: { size: 'small', fullWidth: true } }} />
            </FormField>
            <FormField xs={12} md={3}>
              <FormControl><InputLabel>Tipo de Asiento</InputLabel>
                <Select value={tipoAsiento} label="Tipo de Asiento" onChange={(e) => setTipoAsiento(e.target.value)}>
                  <MenuItem value="DIARIO">Diario</MenuItem><MenuItem value="APERTURA">Apertura</MenuItem>
                  <MenuItem value="CIERRE">Cierre</MenuItem><MenuItem value="AJUSTE">Ajuste</MenuItem>
                  <MenuItem value="COMPRA">Compra</MenuItem><MenuItem value="VENTA">Venta</MenuItem>
                  <MenuItem value="NOMINA">Nomina</MenuItem>
                </Select>
              </FormControl>
            </FormField>
            <FormField xs={12} md={3}>
              <TextField label="Referencia" value={referencia} onChange={(e) => setReferencia(e.target.value)} placeholder="Ej: FAC-001" />
            </FormField>
            <FormField xs={12} md={3}>
              <Box sx={{ display: "flex", gap: 1, alignItems: "center", height: "100%" }}>
                <Chip label={isBalanced ? "Cuadrado" : "Descuadrado"} color={isBalanced ? "success" : "warning"} sx={{ fontWeight: 600 }} />
              </Box>
            </FormField>
            <FormField xs={12}>
              <TextField label="Concepto" value={concepto} onChange={(e) => setConcepto(e.target.value)} required placeholder="Describa el motivo del asiento..." />
            </FormField>
          </FormGrid>
        </CardContent>
      </Card>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
            <Typography variant="h6">Detalle del Asiento</Typography>
            <Button variant="outlined" startIcon={<AddIcon />} onClick={handleAddLinea}>Agregar linea</Button>
          </Stack>
          <Box sx={{ height: 300, mb: 2 }}>
            {registered ? (
              <zentto-grid
                ref={gridRef}
                default-currency="VES"
                height="100%"
                show-totals
                enable-editing
                enable-toolbar
                enable-header-menu
                enable-header-filters
                enable-clipboard
                enable-quick-search
                enable-context-menu
                enable-status-bar
                enable-configurator
              ></zentto-grid>
            ) : (
              <Box sx={{ display: "flex", justifyContent: "center", p: 4 }}><CircularProgress /></Box>
            )}
          </Box>

          <Divider sx={{ my: 2 }} />
          <FormGrid spacing={2} justifyContent="flex-end">
            <FormField xs={12} md={4}>
              <Paper sx={{ p: 2, bgcolor: "success.light", color: "success.contrastText" }}>
                <Typography variant="body2">Total debe</Typography>
                <Typography variant="h5" fontWeight={700}>{formatCurrency(totalDebe)}</Typography>
              </Paper>
            </FormField>
            <FormField xs={12} md={4}>
              <Paper sx={{ p: 2, bgcolor: "info.light", color: "info.contrastText" }}>
                <Typography variant="body2">Total haber</Typography>
                <Typography variant="h5" fontWeight={700}>{formatCurrency(totalHaber)}</Typography>
              </Paper>
            </FormField>
            <FormField xs={12} md={4}>
              <Paper sx={{ p: 2, bgcolor: isBalanced ? "success.main" : "warning.main", color: "white" }}>
                <Typography variant="body2">Diferencia</Typography>
                <Typography variant="h5" fontWeight={700}>{formatCurrency(diferencia)}</Typography>
              </Paper>
            </FormField>
          </FormGrid>
        </CardContent>
      </Card>

      <Stack direction="row" spacing={2} justifyContent="flex-end">
        <Button variant="outlined" onClick={() => router.push("/asientos")}>Cancelar</Button>
        <Button variant="contained" startIcon={<SaveIcon />} onClick={handleSubmit} disabled={createMutation.isPending || !isBalanced} size="large">
          {createMutation.isPending ? "Guardando..." : "Guardar asiento"}
        </Button>
      </Stack>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
