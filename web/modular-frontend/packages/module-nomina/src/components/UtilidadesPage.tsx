"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
import { formatCurrency } from "@zentto/shared-api";
import {
  useProfitSharingList,
  useGenerateProfitSharing,
  useProfitSharingSummary,
  useApproveProfitSharing,
  type ProfitSharingFilter,
} from "../hooks/useRRHH";

const COLUMNS: ColumnDef[] = [
  { field: "fiscalYear", header: "Año Fiscal", width: 120, sortable: true },
  { field: "daysGranted", header: "Días Otorgados", width: 140, type: "number" },
  { field: "totalEmployees", header: "Total Empleados", width: 140, type: "number" },
  { field: "totalAmount", header: "Monto Total", width: 150, type: "number", aggregation: "sum" },
  {
    field: "status", header: "Estado", width: 120,
    statusColors: { APROBADO: "success", PROCESADO: "info", PENDIENTE: "warning" },
  },
];

const SUMMARY_COLUMNS: ColumnDef[] = [
  { field: "employeeCode", header: "Código", width: 100 },
  { field: "employeeName", header: "Empleado", flex: 1, minWidth: 200 },
  { field: "daysWorked", header: "Días Trabajados", width: 140, type: "number" },
  { field: "salary", header: "Salario", width: 130, type: "number" },
  { field: "amount", header: "Utilidades", width: 130, type: "number" },
];


const SVG_VIEW = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
const SVG_APPROVE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>';

export default function UtilidadesPage() {
  const gridRef = useRef<any>(null);
  const summaryGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [filter, setFilter] = useState<ProfitSharingFilter>({ page: 1, limit: 25 });
  const [generateOpen, setGenerateOpen] = useState(false);
  const [summaryId, setSummaryId] = useState<number | null>(null);
  const [generateForm, setGenerateForm] = useState({ fiscalYear: new Date().getFullYear(), daysGranted: 15 });

  const { data, isLoading } = useProfitSharingList(filter);
  const generateMutation = useGenerateProfitSharing();
  const approveMutation = useApproveProfitSharing();
  const summary = useProfitSharingSummary(summaryId);

  const rows = data?.data ?? data?.rows ?? [];
  const summaryRows = summary.data?.employees ?? summary.data?.data ?? [];

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
    el.getRowId = (r: any) => r.id ?? r.fiscalYear;
    el.actionButtons = [
      { icon: SVG_VIEW, label: "Ver resumen", action: "view" },
      { icon: SVG_APPROVE, label: "Aprobar", action: "approve", color: "#2e7d32" },
    ];
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "view") setSummaryId(row.id);
      if (action === "approve" && row.status !== "APROBADO" && row.status !== "PROCESADO") {
        approveMutation.mutate({ id: row.id });
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, rows]);

  // Summary dialog grid
  useEffect(() => {
    const el = summaryGridRef.current;
    if (!el || !registered || summaryId == null) return;
    el.columns = SUMMARY_COLUMNS;
    el.rows = (Array.isArray(summaryRows) ? summaryRows : []).map((r: Record<string, unknown>, i: number) => ({ ...r, _id: i }));
    el.loading = summary.isLoading;
    el.getRowId = (r: any) => r._id;
  }, [summaryRows, summary.isLoading, registered, summaryId]);

  const handleGenerate = async () => {
    await generateMutation.mutateAsync(generateForm);
    setGenerateOpen(false);
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Utilidades (Reparto de Beneficios)</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setGenerateOpen(true)}>
          Generar Utilidades
        </Button>
      </Stack>

      <Box sx={{ flex: 1, minHeight: 0 }}>
        <zentto-grid
          ref={gridRef}
          height="calc(100vh - 200px)"
          show-totals
          enable-toolbar
          enable-header-menu
          enable-header-filters
          enable-clipboard
          enable-quick-search
          enable-context-menu
          enable-status-bar
          enable-configurator
          enable-grouping
          enable-pivot
        />
      </Box>

      {/* Generate Dialog */}
      <Dialog open={generateOpen} onClose={() => setGenerateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Generar Utilidades</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Año Fiscal"
              type="number"
              fullWidth
              value={generateForm.fiscalYear}
              onChange={(e) => setGenerateForm((f) => ({ ...f, fiscalYear: Number(e.target.value) }))}
            />
            <TextField
              label="Días Otorgados"
              type="number"
              fullWidth
              value={generateForm.daysGranted}
              onChange={(e) => setGenerateForm((f) => ({ ...f, daysGranted: Number(e.target.value) }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setGenerateOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleGenerate} disabled={generateMutation.isPending}>
            Generar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Summary Dialog */}
      <Dialog open={summaryId != null} onClose={() => setSummaryId(null)} maxWidth="md" fullWidth>
        <DialogTitle>Resumen de Utilidades</DialogTitle>
        <DialogContent>
          {summary.isLoading ? (
            <CircularProgress />
          ) : (
            <Box>
              <Stack direction="row" spacing={3} mb={2}>
                <Typography variant="body2">
                  <strong>Año:</strong> {summary.data?.fiscalYear}
                </Typography>
                <Typography variant="body2">
                  <strong>Total:</strong> {formatCurrency(summary.data?.totalAmount ?? 0)}
                </Typography>
                <Typography variant="body2">
                  <strong>Empleados:</strong> {summary.data?.totalEmployees ?? summaryRows.length}
                </Typography>
              </Stack>
              <Box sx={{ height: 400 }}>
                <zentto-grid
                  ref={summaryGridRef}
                  height="100%"
                  enable-toolbar
                  enable-header-menu
                  enable-header-filters
                  enable-clipboard
                  enable-quick-search
                  enable-context-menu
                  enable-status-bar
                  enable-configurator
                  enable-grouping
                  enable-pivot
                />
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSummaryId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
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
