"use client";

import React, { useState, useCallback, useRef } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  TextField,
  MenuItem,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import { formatCurrency } from "@zentto/shared-api";
import {
  useConciliaciones,
  useCuentasBank,
  useConciliacionDetalle,
  useImportarExtracto,
  useConciliarMovimiento,
  useAsientosVinculados,
  CuentaBancariaSelector,
  MovimientosSistemaGrid,
  ExtractoPendienteGrid,
  ConciliacionSummaryCards,
  ConciliacionResumen,
  type ConciliacionFilter,
} from "@zentto/module-bancos";

// ─── CSV Import ──────────────────────────────────────────────

function parseCSVLines(csvText: string): any[] {
  const lines = csvText.trim().split("\n");
  if (lines.length < 2) return [];

  const headers = lines[0].split(",").map((h) => h.trim().replace(/"/g, ""));
  const rows: any[] = [];

  for (let i = 1; i < lines.length; i++) {
    const values = lines[i].split(",").map((v) => v.trim().replace(/"/g, ""));
    const row: any = {};
    headers.forEach((h, idx) => {
      row[h] = values[idx] || "";
    });
    rows.push({
      date: row.date || row.Date || row.fecha || row.Fecha || "",
      description:
        row.description || row.Description || row.descripcion || row.Descripcion || row.concepto || "",
      amount: parseFloat(row.amount || row.Amount || row.monto || row.Monto || "0") || 0,
    });
  }

  return rows;
}

// ─── Accounting entries columns ──────────────────────────────

const entryCols: GridColDef[] = [
  { field: "EntryDate", headerName: "Fecha", width: 100, valueGetter: (v: any) => v?.slice?.(0, 10) ?? v },
  { field: "EntryNumber", headerName: "N Asiento", width: 120 },
  { field: "Concept", headerName: "Concepto", flex: 1, minWidth: 180 },
  {
    field: "TotalDebit",
    headerName: "Debe",
    width: 120,
    type: "number",
    renderCell: (p) => formatCurrency(p.value ?? 0),
  },
  {
    field: "TotalCredit",
    headerName: "Haber",
    width: 120,
    type: "number",
    renderCell: (p) => formatCurrency(p.value ?? 0),
  },
];

// ─── Main Component ──────────────────────────────────────────

export default function ConciliacionBancariaPage() {
  const [selectedNroCta, setSelectedNroCta] = useState<string>("");
  const [selectedConciliacionId, setSelectedConciliacionId] = useState<number | null>(null);
  const [selectedMovSistemaId, setSelectedMovSistemaId] = useState<number | null>(null);
  const [selectedExtractoId, setSelectedExtractoId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Data hooks
  const conciliacionFilter: ConciliacionFilter = {
    ...(selectedNroCta && { Nro_Cta: selectedNroCta }),
  };
  const { data: conciliacionesData } = useConciliaciones(conciliacionFilter);
  const { data: cuentasData } = useCuentasBank();
  const { data: detalleData, isLoading: detalleLoading } =
    useConciliacionDetalle(selectedConciliacionId ?? undefined);
  const { data: asientosData } = useAsientosVinculados(selectedConciliacionId ?? undefined);

  // Mutations
  const importMutation = useImportarExtracto();
  const conciliarMutation = useConciliarMovimiento();

  const conciliaciones: any[] = conciliacionesData?.rows ?? conciliacionesData?.data ?? [];
  const cuentas: any[] = cuentasData?.rows ?? cuentasData?.data ?? [];
  const detalle = detalleData?.data ?? detalleData ?? null;
  const movimientosSistema: any[] = detalle?.movimientosSistema ?? [];
  const extractoPendiente: any[] = detalle?.extractoPendiente ?? [];
  const asientos: any[] = asientosData?.rows ?? asientosData?.data ?? [];

  // File import handler
  const handleImportCSV = useCallback(
    async (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0];
      if (!file || !selectedConciliacionId) return;
      setError(null);
      setSuccessMsg(null);

      try {
        const text = await file.text();
        const lines = parseCSVLines(text);
        if (lines.length === 0) {
          setError("El archivo CSV no contiene datos validos");
          return;
        }
        await importMutation.mutateAsync({
          conciliacionId: selectedConciliacionId,
          extracto: lines.map((l) => ({
            Fecha: l.date,
            Descripcion: l.description,
            Tipo: (l.amount ?? 0) >= 0 ? "CREDITO" : "DEBITO",
            Monto: Math.abs(l.amount ?? 0),
          })),
        });
        setSuccessMsg(`${lines.length} lineas importadas correctamente`);
      } catch (err: any) {
        setError(err.message || "Error al importar el archivo");
      }

      if (fileInputRef.current) fileInputRef.current.value = "";
    },
    [selectedConciliacionId, importMutation]
  );

  const handleConciliar = async () => {
    if (selectedMovSistemaId == null || selectedConciliacionId == null) {
      setError("Seleccione un movimiento del sistema para conciliar");
      return;
    }
    setError(null);
    try {
      await conciliarMutation.mutateAsync({
        Conciliacion_ID: selectedConciliacionId,
        MovimientoSistema_ID: selectedMovSistemaId,
        Extracto_ID: selectedExtractoId ?? undefined,
      });
      setSuccessMsg("Movimiento conciliado correctamente");
      setSelectedMovSistemaId(null);
      setSelectedExtractoId(null);
    } catch (err: any) {
      setError(err.message || "Error al conciliar");
    }
  };

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 3 }}>
        Conciliacion bancaria
      </Typography>

      {/* Top Section */}
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <CuentaBancariaSelector
          cuentas={cuentas}
          selectedNroCta={selectedNroCta}
          onNroCtaChange={(v) => { setSelectedNroCta(v); setSelectedConciliacionId(null); }}
        />

        {conciliaciones.length > 0 && (
          <TextField
            select
            label="Conciliacion"
            value={selectedConciliacionId ?? ""}
            onChange={(e) => setSelectedConciliacionId(Number(e.target.value) || null)}
            sx={{ minWidth: 250 }}
          >
            {conciliaciones.map((c: any) => (
              <MenuItem key={c.ID} value={c.ID}>
                #{c.ID} - {c.Fecha_Desde} a {c.Fecha_Hasta} ({c.Estado})
              </MenuItem>
            ))}
          </TextField>
        )}

        <Box sx={{ flex: 1 }} />

        <input
          type="file"
          accept=".csv"
          ref={fileInputRef}
          style={{ display: "none" }}
          onChange={handleImportCSV}
        />
        <Button
          variant="outlined"
          startIcon={<CloudUploadIcon />}
          onClick={() => fileInputRef.current?.click()}
          disabled={importMutation.isPending || !selectedConciliacionId}
        >
          {importMutation.isPending ? "Importando..." : "Importar CSV"}
        </Button>
      </Stack>

      {/* Messages */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}
      {successMsg && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMsg(null)}>
          {successMsg}
        </Alert>
      )}

      {/* Summary Cards */}
      {selectedConciliacionId && (
        <ConciliacionSummaryCards detalle={detalle} isLoading={detalleLoading} />
      )}

      {/* Main Split View */}
      <Grid container spacing={2}>
        {/* Left: Movimientos del Sistema */}
        <Grid size={{ xs: 12, md: 6 }}>
          <MovimientosSistemaGrid
            movimientos={movimientosSistema}
            isLoading={detalleLoading}
            hasConciliacion={!!selectedConciliacionId}
            onSelectionChange={setSelectedMovSistemaId}
          />
        </Grid>

        {/* Right: Extracto + Asientos */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Box sx={{ mb: 2 }}>
            <ExtractoPendienteGrid
              extracto={extractoPendiente}
              hasConciliacion={!!selectedConciliacionId}
              onSelectionChange={setSelectedExtractoId}
              onConciliar={handleConciliar}
              canConciliar={selectedMovSistemaId != null && selectedConciliacionId != null}
              isConciliando={conciliarMutation.isPending}
            />
          </Box>

          {/* Asientos contables vinculados — siempre visible en contabilidad */}
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid", borderColor: "divider" }}>
              <Typography variant="h6" fontWeight={600}>
                Asientos contables
              </Typography>
            </Box>
            <ZenttoDataGrid
              rows={asientos}
              columns={entryCols}
              getRowId={(r) => r.JournalEntryId ?? r.id ?? Math.random()}
              autoHeight
              disableMultipleRowSelection
              sx={{ border: 0, "& .MuiDataGrid-row": { cursor: "pointer" } }}
              initialState={{
                pagination: { paginationModel: { pageSize: 5 } },
              }}
              pageSizeOptions={[5, 10]}
              mobileVisibleFields={['EntryDate', 'Concept']}
              smExtraFields={['TotalDebit', 'TotalCredit']}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Bottom: Resumen */}
      {selectedConciliacionId && detalle?.cabecera && (
        <ConciliacionResumen cabecera={detalle.cabecera} />
      )}
    </Box>
  );
}
