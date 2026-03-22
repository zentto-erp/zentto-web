"use client";

import { Box, Paper, Typography, IconButton, Tooltip, Stack } from "@mui/material";
import { DataGrid, type GridColDef, type GridRowSelectionModel } from "@mui/x-data-grid";
import LinkIcon from "@mui/icons-material/Link";
import { formatCurrency } from "@zentto/shared-api";

interface ExtractoPendienteGridProps {
  extracto: any[];
  hasConciliacion: boolean;
  onSelectionChange?: (id: number | null) => void;
  onConciliar?: () => void;
  canConciliar?: boolean;
  isConciliando?: boolean;
}

const columns: GridColDef[] = [
  { field: "Fecha", headerName: "Fecha", width: 100 },
  { field: "Descripcion", headerName: "Descripcion", flex: 1, minWidth: 180 },
  { field: "Referencia", headerName: "Referencia", width: 120 },
  {
    field: "Monto",
    headerName: "Monto",
    width: 130,
    type: "number",
    renderCell: (p) => formatCurrency(p.value ?? 0),
  },
  { field: "Tipo", headerName: "Tipo", width: 100 },
];

export default function ExtractoPendienteGrid({
  extracto,
  hasConciliacion,
  onSelectionChange,
  onConciliar,
  canConciliar = false,
  isConciliando = false,
}: ExtractoPendienteGridProps) {
  return (
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
          Extracto pendiente
        </Typography>
        {onConciliar && (
          <Stack direction="row" spacing={1}>
            <Tooltip title="Conciliar seleccion">
              <span>
                <IconButton
                  color="success"
                  disabled={!canConciliar || isConciliando}
                  onClick={onConciliar}
                >
                  <LinkIcon />
                </IconButton>
              </span>
            </Tooltip>
          </Stack>
        )}
      </Box>

      {hasConciliacion && extracto.length > 0 ? (
        <DataGrid
          rows={extracto}
          columns={columns}
          getRowId={(r) => r.ID ?? r.id ?? Math.random()}
          autoHeight
          disableMultipleRowSelection
          onRowSelectionModelChange={(model: GridRowSelectionModel) => {
            const ids = Array.isArray(model) ? model : Array.from(model as any);
            onSelectionChange?.(ids[0] as number ?? null);
          }}
          sx={{
            border: 0,
            "& .MuiDataGrid-row": { cursor: "pointer" },
          }}
          initialState={{
            pagination: { paginationModel: { pageSize: 5 } },
          }}
          pageSizeOptions={[5, 10]}
        />
      ) : (
        <Box sx={{ p: 3, textAlign: "center" }}>
          <Typography color="text.secondary">
            {hasConciliacion ? "Sin extractos pendientes" : "Seleccione una conciliacion"}
          </Typography>
        </Box>
      )}
    </Paper>
  );
}
