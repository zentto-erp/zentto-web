"use client";

import React, { useState, useCallback, useRef, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Card,
  CardContent,
  Chip,
  TextField,
  MenuItem,
  CircularProgress,
  Divider,
  IconButton,
  Tooltip,
  Skeleton,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef, type GridRowSelectionModel } from "@mui/x-data-grid";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import LinkIcon from "@mui/icons-material/Link";
import LinkOffIcon from "@mui/icons-material/LinkOff";
import AutoFixHighIcon from "@mui/icons-material/AutoFixHigh";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import PendingIcon from "@mui/icons-material/Pending";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import { formatCurrency } from "@datqbox/shared-api";
import {
  useBankStatementsList,
  useBankStatementLines,
  useImportBankStatement,
  useMatchBankLine,
  useUnmatchBankLine,
  useAutoMatch,
  useBankReconSummary,
  type BankStatement,
  type BankStatementLine,
  type BankReconSummary,
} from "../hooks/useContabilidadAdvanced";
import { useAsientosList } from "../hooks/useContabilidad";

// ─── Summary Cards ───────────────────────────────────────────

function SummaryCards({
  summary,
  isLoading,
}: {
  summary: BankReconSummary | null;
  isLoading: boolean;
}) {
  const cards = [
    {
      title: "Total Lineas",
      value: summary?.totalLines ?? 0,
      color: "#1565c0",
      isCurrency: false,
    },
    {
      title: "Conciliadas",
      value: summary?.matched ?? 0,
      color: "#2e7d32",
      isCurrency: false,
    },
    {
      title: "Pendientes",
      value: summary?.unmatched ?? 0,
      color: "#e65100",
      isCurrency: false,
    },
    {
      title: "Monto Pendiente",
      value: summary?.pendingAmount ?? 0,
      color: "#c62828",
      isCurrency: true,
    },
  ];

  return (
    <Grid container spacing={2} sx={{ mb: 3 }}>
      {cards.map((card, idx) => (
        <Grid size={{ xs: 6, md: 3 }} key={idx}>
          <Card sx={{ borderRadius: 2, borderTop: `3px solid ${card.color}` }}>
            <CardContent sx={{ py: 1.5 }}>
              {isLoading ? (
                <Skeleton width={80} height={36} />
              ) : (
                <Typography variant="h5" fontWeight={700} sx={{ color: card.color }}>
                  {card.isCurrency ? formatCurrency(card.value) : card.value}
                </Typography>
              )}
              <Typography variant="body2" color="text.secondary">
                {card.title}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
}

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
    // Try to map common CSV fields
    rows.push({
      date: row.date || row.Date || row.fecha || row.Fecha || "",
      description:
        row.description || row.Description || row.descripcion || row.Descripcion || row.concepto || "",
      amount: parseFloat(row.amount || row.Amount || row.monto || row.Monto || "0") || 0,
    });
  }

  return rows;
}

// ─── Main Component ──────────────────────────────────────────

export default function ConciliacionBancariaPage() {
  const [selectedAccountCode, setSelectedAccountCode] = useState<string>("");
  const [selectedStatementId, setSelectedStatementId] = useState<number | null>(null);
  const [selectedBankLineId, setSelectedBankLineId] = useState<number | null>(null);
  const [selectedEntryId, setSelectedEntryId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Data hooks
  const { data: statementsData, isLoading: statementsLoading } =
    useBankStatementsList(selectedAccountCode || undefined);
  const { data: linesData, isLoading: linesLoading } =
    useBankStatementLines(selectedStatementId);
  const { data: summaryData, isLoading: summaryLoading } =
    useBankReconSummary(selectedStatementId);
  const { data: asientosData } = useAsientosList({ page: 1, limit: 100 });

  // Mutations
  const importMutation = useImportBankStatement();
  const matchMutation = useMatchBankLine();
  const unmatchMutation = useUnmatchBankLine();
  const autoMatchMutation = useAutoMatch();

  const statements: BankStatement[] = statementsData?.data ?? statementsData?.rows ?? [];
  const bankLines: BankStatementLine[] = linesData?.data ?? linesData?.rows ?? [];
  const summary: BankReconSummary | null = summaryData?.data ?? summaryData ?? null;
  const asientos = asientosData?.data ?? asientosData?.rows ?? [];

  // Unique bank account codes from statements
  const bankAccounts = useMemo(() => {
    const codes = new Set(statements.map((s) => s.bankAccountCode));
    return Array.from(codes);
  }, [statements]);

  // Bank statement lines columns
  const bankLineCols: GridColDef[] = [
    { field: "date", headerName: "Fecha", width: 100 },
    { field: "description", headerName: "Descripcion", flex: 1, minWidth: 200 },
    {
      field: "amount",
      headerName: "Monto",
      width: 130,
      type: "number",
      renderCell: (p) => (
        <Typography
          variant="body2"
          fontWeight={500}
          sx={{ color: p.value >= 0 ? "success.main" : "error.main" }}
        >
          {formatCurrency(p.value)}
        </Typography>
      ),
    },
    {
      field: "status",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          icon={p.value === "MATCHED" ? <CheckCircleIcon /> : <PendingIcon />}
          label={p.value === "MATCHED" ? "Conciliada" : "Pendiente"}
          size="small"
          color={p.value === "MATCHED" ? "success" : "warning"}
        />
      ),
    },
    {
      field: "matchedEntryRef",
      headerName: "Ref. Asiento",
      width: 130,
      renderCell: (p) =>
        p.value ? (
          <Typography variant="body2" fontFamily="monospace">
            {p.value}
          </Typography>
        ) : (
          <Typography variant="body2" color="text.secondary">
            --
          </Typography>
        ),
    },
  ];

  // Accounting entries columns
  const entryCols: GridColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 100 },
    { field: "id", headerName: "N Asiento", width: 100 },
    { field: "concepto", headerName: "Concepto", flex: 1, minWidth: 180 },
    {
      field: "totalDebe",
      headerName: "Debe",
      width: 120,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
    {
      field: "totalHaber",
      headerName: "Haber",
      width: 120,
      type: "number",
      renderCell: (p) => formatCurrency(p.value ?? 0),
    },
  ];

  // File import handler
  const handleImportCSV = useCallback(
    async (event: React.ChangeEvent<HTMLInputElement>) => {
      const file = event.target.files?.[0];
      if (!file) return;

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
          bankAccountCode: selectedAccountCode || "MAIN",
          lines,
        });

        setSuccessMsg(`${lines.length} lineas importadas correctamente`);
      } catch (err: any) {
        setError(err.message || "Error al importar el archivo");
      }

      // Reset file input
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    },
    [selectedAccountCode, importMutation]
  );

  // Match handler
  const handleMatch = async () => {
    if (selectedBankLineId == null || selectedEntryId == null) {
      setError("Seleccione una linea bancaria y un asiento para conciliar");
      return;
    }
    setError(null);
    try {
      await matchMutation.mutateAsync({
        lineId: selectedBankLineId,
        entryId: selectedEntryId,
      });
      setSuccessMsg("Linea conciliada correctamente");
      setSelectedBankLineId(null);
      setSelectedEntryId(null);
    } catch (err: any) {
      setError(err.message || "Error al conciliar");
    }
  };

  // Unmatch handler
  const handleUnmatch = async () => {
    if (selectedBankLineId == null) {
      setError("Seleccione una linea bancaria para desconciliar");
      return;
    }
    setError(null);
    try {
      await unmatchMutation.mutateAsync(selectedBankLineId);
      setSuccessMsg("Linea desconciliada correctamente");
      setSelectedBankLineId(null);
    } catch (err: any) {
      setError(err.message || "Error al desconciliar");
    }
  };

  // Auto match handler
  const handleAutoMatch = async () => {
    if (selectedStatementId == null) {
      setError("Seleccione un extracto bancario primero");
      return;
    }
    setError(null);
    try {
      const result = await autoMatchMutation.mutateAsync(selectedStatementId);
      const count = (result as any)?.matchedCount ?? 0;
      setSuccessMsg(`Auto-conciliacion completada. ${count} lineas conciliadas.`);
    } catch (err: any) {
      setError(err.message || "Error en auto-conciliacion");
    }
  };

  return (
    <Box>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 3 }}>
        Conciliacion Bancaria
      </Typography>

      {/* Top Section */}
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <TextField
          select
          label="Cuenta Bancaria"
          value={selectedAccountCode}
          onChange={(e) => {
            setSelectedAccountCode(e.target.value);
            setSelectedStatementId(null);
          }}
          size="small"
          sx={{ minWidth: 200 }}
        >
          <MenuItem value="">Todas</MenuItem>
          {bankAccounts.map((code) => (
            <MenuItem key={code} value={code}>
              {code}
            </MenuItem>
          ))}
        </TextField>

        {statements.length > 0 && (
          <TextField
            select
            label="Extracto"
            value={selectedStatementId ?? ""}
            onChange={(e) => setSelectedStatementId(Number(e.target.value) || null)}
            size="small"
            sx={{ minWidth: 200 }}
          >
            {statements.map((s) => (
              <MenuItem key={s.id} value={s.id}>
                {s.statementDate} - {s.bankAccountName || s.bankAccountCode}
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
          disabled={importMutation.isPending}
        >
          {importMutation.isPending ? "Importando..." : "Importar CSV"}
        </Button>

        <Button
          variant="contained"
          startIcon={autoMatchMutation.isPending ? <CircularProgress size={18} /> : <AutoFixHighIcon />}
          onClick={handleAutoMatch}
          disabled={!selectedStatementId || autoMatchMutation.isPending}
        >
          Auto-Conciliar
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
      {selectedStatementId && (
        <SummaryCards summary={summary} isLoading={summaryLoading} />
      )}

      {/* Main Split View */}
      <Grid container spacing={2}>
        {/* Left: Bank Statement Lines */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box
              sx={{
                p: 2,
                borderBottom: "1px solid",
                borderColor: "divider",
                display: "flex",
                alignItems: "center",
                gap: 1,
              }}
            >
              <AccountBalanceIcon color="primary" />
              <Typography variant="h6" fontWeight={600}>
                Extracto Bancario
              </Typography>
            </Box>

            {!selectedStatementId ? (
              <Box sx={{ p: 4, textAlign: "center" }}>
                <Typography color="text.secondary">
                  Seleccione un extracto bancario para ver las lineas
                </Typography>
              </Box>
            ) : linesLoading ? (
              <Box sx={{ p: 4, textAlign: "center" }}>
                <CircularProgress />
              </Box>
            ) : (
              <DataGrid
                rows={bankLines}
                columns={bankLineCols}
                getRowId={(r) => r.id}
                autoHeight
                disableMultipleRowSelection
                onRowSelectionModelChange={(model: GridRowSelectionModel) => {
                  const id = model[0] as number;
                  setSelectedBankLineId(id ?? null);
                }}
                sx={{
                  border: 0,
                  "& .MuiDataGrid-row": {
                    cursor: "pointer",
                  },
                  "& .MuiDataGrid-row.Mui-selected": {
                    bgcolor: "primary.light",
                  },
                }}
                initialState={{
                  pagination: { paginationModel: { pageSize: 10 } },
                }}
                pageSizeOptions={[10, 25]}
                getRowClassName={(params) =>
                  params.row.status === "MATCHED" ? "matched-row" : ""
                }
              />
            )}
          </Paper>
        </Grid>

        {/* Right: Accounting Entries */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box
              sx={{
                p: 2,
                borderBottom: "1px solid",
                borderColor: "divider",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <Typography variant="h6" fontWeight={600}>
                Asientos Contables
              </Typography>
              <Stack direction="row" spacing={1}>
                <Tooltip title="Conciliar seleccion">
                  <span>
                    <IconButton
                      color="success"
                      disabled={
                        selectedBankLineId == null ||
                        selectedEntryId == null ||
                        matchMutation.isPending
                      }
                      onClick={handleMatch}
                    >
                      <LinkIcon />
                    </IconButton>
                  </span>
                </Tooltip>
                <Tooltip title="Desconciliar">
                  <span>
                    <IconButton
                      color="error"
                      disabled={selectedBankLineId == null || unmatchMutation.isPending}
                      onClick={handleUnmatch}
                    >
                      <LinkOffIcon />
                    </IconButton>
                  </span>
                </Tooltip>
              </Stack>
            </Box>

            <DataGrid
              rows={asientos}
              columns={entryCols}
              getRowId={(r) => r.id ?? r.asientoId}
              autoHeight
              disableMultipleRowSelection
              onRowSelectionModelChange={(model: GridRowSelectionModel) => {
                const id = model[0] as number;
                setSelectedEntryId(id ?? null);
              }}
              sx={{
                border: 0,
                "& .MuiDataGrid-row": { cursor: "pointer" },
              }}
              initialState={{
                pagination: { paginationModel: { pageSize: 10 } },
              }}
              pageSizeOptions={[10, 25]}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Bottom: Reconciliation Status */}
      {selectedStatementId && summary && (
        <Paper sx={{ mt: 3, p: 3, borderRadius: 2 }}>
          <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
            Resumen de Conciliacion
          </Typography>
          <Grid container spacing={3}>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="success.main">
                  {summary.totalLines > 0
                    ? ((summary.matched / summary.totalLines) * 100).toFixed(1)
                    : 0}
                  %
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Porcentaje Conciliado
                </Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="primary.main">
                  {formatCurrency(summary.matchedAmount ?? 0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Monto Conciliado
                </Typography>
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 4 }}>
              <Box sx={{ textAlign: "center" }}>
                <Typography variant="h4" fontWeight={700} color="error.main">
                  {formatCurrency(summary.pendingAmount ?? 0)}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Monto Pendiente
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </Paper>
      )}
    </Box>
  );
}
