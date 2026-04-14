"use client";

import React, { useState, useCallback, useRef, useEffect } from "react";
import {
  Box, Paper, Typography, Button, Stack, Alert, TextField, MenuItem,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import {
  useConciliaciones, useCuentasBank, useConciliacionDetalle, useImportarExtracto,
  useConciliarMovimiento, useAsientosVinculados, CuentaBancariaSelector,
  MovimientosSistemaGrid, ExtractoPendienteGrid, ConciliacionSummaryCards,
  ConciliacionResumen, type ConciliacionFilter,
} from "@zentto/module-bancos";
import { CircularProgress } from "@mui/material";

function parseCSVLines(csvText: string): any[] {
  const lines = csvText.trim().split("\n");
  if (lines.length < 2) return [];
  const headers = lines[0].split(",").map((h) => h.trim().replace(/"/g, ""));
  const rows: any[] = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(",").map((v) => v.trim().replace(/"/g, ""));
    const row: any = {};
    headers.forEach((h, idx) => { row[h] = values[idx] || ""; });
    rows.push({
      date: row.date || row.Date || row.fecha || row.Fecha || "",
      description: row.description || row.Description || row.descripcion || row.Descripcion || row.concepto || "",
      amount: parseFloat(row.amount || row.Amount || row.monto || row.Monto || "0") || 0,
    });
  }
  return rows;
}

import { buildContabilidadGridId, useContabilidadGridId, useContabilidadGridRegistration } from "./zenttoGridPersistence";
const ENTRY_COLUMNS: ColumnDef[] = [
  { field: "EntryDate", header: "Fecha", width: 100, type: "date" },
  { field: "EntryNumber", header: "N Asiento", width: 120 },
  { field: "Concept", header: "Concepto", flex: 1, minWidth: 180, sortable: true },
  { field: "TotalDebit", header: "Debe", width: 120, type: "number", currency: "VES" },
  { field: "TotalCredit", header: "Haber", width: 120, type: "number", currency: "VES" },
];

const GRID_IDS = {
  gridRef: buildContabilidadGridId("conciliacion-bancaria", "main"),
} as const;

export default function ConciliacionBancariaPage() {
  const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_IDS.gridRef);
  useContabilidadGridId(gridRef, GRID_IDS.gridRef);
  const layoutReady = gridLayoutReady;
  const { registered } = useContabilidadGridRegistration(layoutReady);
  const [selectedNroCta, setSelectedNroCta] = useState<string>("");
  const [selectedConciliacionId, setSelectedConciliacionId] = useState<number | null>(null);
  const [selectedMovSistemaId, setSelectedMovSistemaId] = useState<number | null>(null);
  const [selectedExtractoId, setSelectedExtractoId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const conciliacionFilter: ConciliacionFilter = { ...(selectedNroCta && { Nro_Cta: selectedNroCta }) };
  const { data: conciliacionesData } = useConciliaciones(conciliacionFilter);
  const { data: cuentasData } = useCuentasBank();
  const { data: detalleData, isLoading: detalleLoading } = useConciliacionDetalle(selectedConciliacionId ?? undefined);
  const { data: asientosData } = useAsientosVinculados(selectedConciliacionId ?? undefined);

  const importMutation = useImportarExtracto();
  const conciliarMutation = useConciliarMovimiento();

  const conciliaciones: any[] = conciliacionesData?.rows ?? conciliacionesData?.data ?? [];
  const cuentas: any[] = cuentasData?.rows ?? cuentasData?.data ?? [];
  const detalle = detalleData?.data ?? detalleData ?? null;
  const movimientosSistema: any[] = detalle?.movimientosSistema ?? [];
  const extractoPendiente: any[] = detalle?.extractoPendiente ?? [];
  const asientos: any[] = asientosData?.rows ?? asientosData?.data ?? [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = ENTRY_COLUMNS;
    el.rows = asientos.map((r: any) => ({ ...r, id: r.JournalEntryId ?? r.id ?? Math.random(), EntryDate: r.EntryDate?.slice?.(0, 10) ?? r.EntryDate }));
    // No actionButtons needed — read-only view of linked journal entries
  }, [asientos, registered]);

  const handleImportCSV = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file || !selectedConciliacionId) return;
    setError(null); setSuccessMsg(null);
    try {
      const text = await file.text();
      const lines = parseCSVLines(text);
      if (lines.length === 0) { setError("El archivo CSV no contiene datos validos"); return; }
      await importMutation.mutateAsync({
        conciliacionId: selectedConciliacionId,
        extracto: lines.map((l) => ({ Fecha: l.date, Descripcion: l.description, Tipo: (l.amount ?? 0) >= 0 ? "CREDITO" : "DEBITO", Monto: Math.abs(l.amount ?? 0) })),
      });
      setSuccessMsg(`${lines.length} lineas importadas correctamente`);
    } catch (err: any) { setError(err.message || "Error al importar el archivo"); }
    if (fileInputRef.current) fileInputRef.current.value = "";
  }, [selectedConciliacionId, importMutation]);

  const handleConciliar = async () => {
    if (selectedMovSistemaId == null || selectedConciliacionId == null) { setError("Seleccione un movimiento del sistema para conciliar"); return; }
    setError(null);
    try {
      await conciliarMutation.mutateAsync({ Conciliacion_ID: selectedConciliacionId, MovimientoSistema_ID: selectedMovSistemaId, Extracto_ID: selectedExtractoId ?? undefined });
      setSuccessMsg("Movimiento conciliado correctamente");
      setSelectedMovSistemaId(null); setSelectedExtractoId(null);
    } catch (err: any) { setError(err.message || "Error al conciliar"); }
  };

  return (
    <Box>
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <CuentaBancariaSelector cuentas={cuentas} selectedNroCta={selectedNroCta}
          onNroCtaChange={(v) => { setSelectedNroCta(v); setSelectedConciliacionId(null); }} />
        {conciliaciones.length > 0 && (
          <TextField select label="Conciliacion" value={selectedConciliacionId ?? ""} onChange={(e) => setSelectedConciliacionId(Number(e.target.value) || null)} sx={{ minWidth: 250 }}>
            {conciliaciones.map((c: any) => (<MenuItem key={c.ID} value={c.ID}>#{c.ID} - {c.Fecha_Desde} a {c.Fecha_Hasta} ({c.Estado})</MenuItem>))}
          </TextField>
        )}
        <Box sx={{ flex: 1 }} />
        <input type="file" accept=".csv" ref={fileInputRef} style={{ display: "none" }} onChange={handleImportCSV} />
        <Button variant="outlined" startIcon={<CloudUploadIcon />} onClick={() => fileInputRef.current?.click()} disabled={importMutation.isPending || !selectedConciliacionId}>
          {importMutation.isPending ? "Importando..." : "Importar CSV"}
        </Button>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>}
      {successMsg && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMsg(null)}>{successMsg}</Alert>}

      {selectedConciliacionId && <ConciliacionSummaryCards detalle={detalle} isLoading={detalleLoading} />}

      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 6 }}>
          <MovimientosSistemaGrid movimientos={movimientosSistema} isLoading={detalleLoading} hasConciliacion={!!selectedConciliacionId} onSelectionChange={setSelectedMovSistemaId} />
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Box sx={{ mb: 2 }}>
            <ExtractoPendienteGrid extracto={extractoPendiente} hasConciliacion={!!selectedConciliacionId} onSelectionChange={setSelectedExtractoId}
              onConciliar={handleConciliar} canConciliar={selectedMovSistemaId != null && selectedConciliacionId != null} isConciliando={conciliarMutation.isPending} />
          </Box>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid", borderColor: "divider" }}>
              <Typography variant="h6" fontWeight={600}>Asientos contables</Typography>
            </Box>
            {registered ? (
              <Box sx={{ height: 250 }}>
                <zentto-grid
                  ref={gridRef}
                  default-currency="VES"
                  height="100%"
                  enable-toolbar
                  enable-header-menu
                  enable-header-filters
                  enable-clipboard
                  enable-quick-search
                  enable-context-menu
                  enable-status-bar
                  enable-configurator
                ></zentto-grid>
              </Box>
            ) : (
              <Box sx={{ display: "flex", justifyContent: "center", p: 3 }}><CircularProgress /></Box>
            )}
          </Paper>
        </Grid>
      </Grid>

      {selectedConciliacionId && detalle?.cabecera && <ConciliacionResumen cabecera={detalle.cabecera} />}
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
