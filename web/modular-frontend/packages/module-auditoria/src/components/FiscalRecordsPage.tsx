"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  TextField,
  Stack,
  Chip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { ContextActionHeader, ZenttoDataGrid, DatePicker } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { formatDateTime } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useFiscalRecords, type FiscalRecordFilter } from "../hooks/useAuditoria";

export default function FiscalRecordsPage() {
  const { timeZone } = useTimezone();
  const [filter, setFilter] = useState<FiscalRecordFilter>({ page: 1, limit: 25 });
  const { data, isLoading } = useFiscalRecords(filter);

  const rows = data?.data ?? [];
  const total = data?.total ?? 0;

  const columns: GridColDef[] = [
    { field: "FiscalRecordId", headerName: "ID", width: 70 },
    {
      field: "CreatedAt",
      headerName: "Fecha",
      width: 160,
      renderCell: (p) => (p.value ? formatDateTime(p.value as string, { timeZone }) : "-"),
    },
    { field: "InvoiceNumber", headerName: "N° Factura", width: 140 },
    { field: "InvoiceType", headerName: "Tipo", width: 100 },
    { field: "CountryCode", headerName: "País", width: 70 },
    {
      field: "RecordHash",
      headerName: "Hash",
      width: 180,
      renderCell: (p) => (
        <span style={{ fontFamily: "monospace", fontSize: "0.75rem" }}>
          {p.value ? String(p.value).substring(0, 20) + "..." : "-"}
        </span>
      ),
    },
    {
      field: "SentToAuthority",
      headerName: "Enviado",
      width: 100,
      renderCell: (p) => (
        <Chip
          label={p.value ? "Sí" : "No"}
          size="small"
          color={p.value ? "success" : "default"}
          variant="outlined"
        />
      ),
    },
    {
      field: "AuthorityStatus",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value ?? "N/A"}
          size="small"
          color={p.value === "ACCEPTED" ? "success" : p.value === "REJECTED" ? "error" : "default"}
          variant="outlined"
        />
      ),
    },
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader title="Registros Fiscales" />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Stack direction="row" spacing={2} mb={2}>
          <DatePicker
            label="Desde"
            value={filter.fechaDesde ? dayjs(filter.fechaDesde) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaDesde: v ? v.format('YYYY-MM-DD') : undefined, page: 1 }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
          <DatePicker
            label="Hasta"
            value={filter.fechaHasta ? dayjs(filter.fechaHasta) : null}
            onChange={(v) => setFilter((f) => ({ ...f, fechaHasta: v ? v.format('YYYY-MM-DD') : undefined, page: 1 }))}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Stack>

        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={rows}
            columns={columns}
            loading={isLoading}
            rowCount={total}
            pageSizeOptions={[25, 50]}
            paginationMode="server"
            paginationModel={{ page: (filter.page ?? 1) - 1, pageSize: filter.limit ?? 25 }}
            onPaginationModelChange={(m) =>
              setFilter((f) => ({ ...f, page: m.page + 1, limit: m.pageSize }))
            }
            disableRowSelectionOnClick
            getRowId={(row) => row.FiscalRecordId}
            sx={{ border: "none" }}
            mobileVisibleFields={['CreatedAt', 'InvoiceNumber']}
            smExtraFields={['InvoiceType', 'AuthorityStatus']}
          />
        </Paper>
      </Box>
    </Box>
  );
}
