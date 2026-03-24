"use client";

import { Box, Paper, Typography, CircularProgress, Chip } from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import PendingIcon from "@mui/icons-material/Pending";
import { formatCurrency } from "@zentto/shared-api";

interface MovimientosSistemaGridProps {
  movimientos: any[];
  isLoading: boolean;
  hasConciliacion: boolean;
  onSelectionChange?: (id: number | null) => void;
}

const columns: ZenttoColDef[] = [
  { field: "Fecha", headerName: "Fecha", width: 100 },
  { field: "Tipo", headerName: "Tipo", width: 80 },
  { field: "Nro_Ref", headerName: "Referencia", width: 120 },
  { field: "Concepto", headerName: "Concepto", flex: 1, minWidth: 180 },
  {
    field: "Monto",
    headerName: "Monto",
    width: 130,
    type: "number",
    currency: true,
    aggregation: "sum",
    renderCell: (p) => (
      <Typography
        variant="body2"
        fontWeight={500}
        sx={{ color: (p.value ?? 0) >= 0 ? "success.main" : "error.main" }}
      >
        {formatCurrency(p.value ?? 0)}
      </Typography>
    ),
  },
  {
    field: "Estado",
    headerName: "Estado",
    width: 120,
    statusColors: {
      CONCILIADO: "success",
      PENDIENTE: "warning",
    },
    renderCell: (p) => (
      <Chip
        icon={p.value === "CONCILIADO" ? <CheckCircleIcon /> : <PendingIcon />}
        label={p.value === "CONCILIADO" ? "Conciliado" : "Pendiente"}
        size="small"
        color={p.value === "CONCILIADO" ? "success" : "warning"}
      />
    ),
  },
];

export default function MovimientosSistemaGrid({
  movimientos,
  isLoading,
  hasConciliacion,
  onSelectionChange,
}: MovimientosSistemaGridProps) {
  return (
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
          Movimientos del Sistema
        </Typography>
      </Box>

      {!hasConciliacion ? (
        <Box sx={{ p: 4, textAlign: "center" }}>
          <Typography color="text.secondary">
            Seleccione una conciliacion para ver los movimientos
          </Typography>
        </Box>
      ) : isLoading ? (
        <Box sx={{ p: 4, textAlign: "center" }}>
          <CircularProgress />
        </Box>
      ) : (
        <ZenttoDataGrid
          rows={movimientos}
          columns={columns}
          getRowId={(r) => r.ID ?? r.id ?? Math.random()}
          autoHeight
          disableMultipleRowSelection
          onRowSelectionModelChange={(model: any, _details: any) => {
            const ids = Array.isArray(model) ? model : Array.from(model as any);
            onSelectionChange?.(ids[0] as number ?? null);
          }}
          showTotals
          enableClipboard
          sx={{
            border: 0,
            "& .MuiDataGrid-row": { cursor: "pointer" },
            "& .MuiDataGrid-row.Mui-selected": { bgcolor: "primary.light" },
          }}
          initialState={{
            pagination: { paginationModel: { pageSize: 10 } },
          }}
          pageSizeOptions={[10, 25]}
          mobileVisibleFields={['Fecha', 'Monto']}
          smExtraFields={['Concepto', 'Estado']}
        />
      )}
    </Paper>
  );
}
