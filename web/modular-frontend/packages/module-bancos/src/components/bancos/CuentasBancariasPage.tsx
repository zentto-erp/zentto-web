"use client";
import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Box, Button, Chip, Paper, Stack, Typography } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import Grid from "@mui/material/Grid2";
import dayjs from "dayjs";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { ContextActionHeader, ZenttoDataGrid, ZenttoFilterPanel, type ZenttoColDef, type FilterFieldDef } from "@zentto/shared-ui";
import { useCuentasBancarias, useMovimientosCuenta } from "../../hooks/useBancosAuxiliares";

const MOVIMIENTOS_FILTERS: FilterFieldDef[] = [
  {
    field: "tipo",
    label: "Tipo",
    type: "select",
    options: [
      { value: "DEP", label: "Depósito" },
      { value: "PCH", label: "Cheque" },
      { value: "NCR", label: "Nota Crédito" },
      { value: "NDB", label: "Nota Débito" },
      { value: "IDB", label: "Int. Débito" },
    ],
  },
  { field: "from", label: "Fecha desde", type: "date" },
  { field: "to", label: "Fecha hasta", type: "date" },
];

const tipoColors: Record<string, "success" | "error" | "info" | "warning" | "default"> = {
  DEP: "success",
  PCH: "error",
  NCR: "info",
  NDB: "warning",
  IDB: "default",
};

const colsCuentas: ZenttoColDef[] = [
  { field: "Nro_Cta", headerName: "Nro Cuenta", width: 150 },
  {
    field: "BancoNombre",
    headerName: "Banco",
    flex: 1,
    valueGetter: (value, row) => row.BancoNombre ?? row.Banco ?? "",
  },
  {
    field: "Saldo",
    headerName: "Saldo",
    width: 140,
    align: "right",
    headerAlign: "right",
    currency: true,
    aggregation: "sum",
    renderCell: (p) => {
      const val = Number(p.value ?? 0);
      return (
        <Chip
          size="small"
          label={formatCurrency(val)}
          color={val >= 0 ? "success" : "error"}
          variant="outlined"
        />
      );
    },
  },
];

export default function CuentasBancariasPage() {
  const router = useRouter();
  const { timeZone } = useTimezone();

  const colsMovimientos: ZenttoColDef[] = [
    {
      field: "Fecha",
      headerName: "Fecha",
      width: 140,
      renderCell: (p) => toDateOnly(p.value as string, timeZone),
    },
    {
      field: "Tipo",
      headerName: "Tipo",
      width: 90,
      renderCell: (p) => (
        <Chip
          size="small"
          label={String(p.value)}
          color={tipoColors[String(p.value)] ?? "default"}
        />
      ),
    },
    { field: "Nro_Ref", headerName: "Referencia", width: 130 },
    { field: "Beneficiario", headerName: "Beneficiario", flex: 1, minWidth: 180 },
    {
      field: "Monto",
      headerName: "Monto",
      width: 140,
      align: "right",
      headerAlign: "right",
      currency: true,
      aggregation: "sum",
      renderCell: (p) => formatCurrency(Number(p.value ?? 0)),
    },
  ];
  const [nroCta, setNroCta] = useState<string>("");
  const [movSearch, setMovSearch] = useState("");
  const [movFilterValues, setMovFilterValues] = useState<Record<string, string>>({
    from: dayjs().tz(timeZone).startOf("month").format("YYYY-MM-DD"),
    to: dayjs().tz(timeZone).format("YYYY-MM-DD"),
  });
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(50);

  const fechaDesde = movFilterValues.from ? dayjs(movFilterValues.from) : null;
  const fechaHasta = movFilterValues.to ? dayjs(movFilterValues.to) : null;

  const { data: cuentasData, isLoading: loadingCtas } = useCuentasBancarias();

  const input = useMemo(
    () => ({
      nroCta: nroCta || undefined,
      desde: fechaDesde?.format("YYYY-MM-DD"),
      hasta: fechaHasta?.format("YYYY-MM-DD"),
      page,
      limit,
    }),
    [nroCta, fechaDesde, fechaHasta, page, limit],
  );

  const { data: movsData, isLoading: loadingMovs } = useMovimientosCuenta(input);

  const cuentas = (cuentasData?.rows ?? []) as Record<string, any>[];
  const movs = (movsData?.rows ?? []) as Record<string, any>[];

  return (
    <Box>
      <ContextActionHeader
        title="Cuentas Bancarias"
        secondaryActions={[
          {
            label: "Imprimir",
            onClick: () => window.print(),
          },
          {
            label: "Nueva Conciliación",
            onClick: () => {
              window.location.href = "/conciliacion/wizard";
            },
          },
        ]}
      />

      {/* Print header (hidden on screen, visible on print) */}
      <Box className="print-only" sx={{ display: "none", mb: 2 }}>
        <Typography variant="h5" fontWeight={700}>Estado de Cuenta Bancaria</Typography>
        {nroCta && <Typography variant="subtitle1">Cuenta: {nroCta}</Typography>}
        <Typography variant="body2" color="text.secondary">
          Período: {fechaDesde?.format("DD/MM/YYYY") ?? "—"} al {fechaHasta?.format("DD/MM/YYYY") ?? "—"}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Generado: {new Date().toLocaleString("es-VE")}
        </Typography>
      </Box>

      <Grid container spacing={2}>
        {/* Panel izquierdo: Cuentas */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold" mb={1}>
              Cuentas
            </Typography>
            <ZenttoDataGrid
            gridId="bancos-cuentas-list"
              rows={cuentas}
              columns={colsCuentas}
              loading={loadingCtas}
              onRowClick={(params) => setNroCta(String(params.row.Nro_Cta))}
              getRowId={(r) => r.Nro_Cta ?? r.nroCta ?? Math.random()}
              density="compact"
              hideFooter
              disableRowSelectionOnClick
              showTotals
              enableClipboard
              sx={{
                minHeight: 400,
                "& .MuiDataGrid-row.Mui-selected": { bgcolor: "action.selected" },
              }}
              mobileVisibleFields={['Nro_Cta', 'Saldo']}
              smExtraFields={['BancoNombre']}
            />
          </Paper>
        </Grid>

        {/* Panel derecho: Movimientos */}
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ p: 2 }}>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1}>
              <Typography variant="subtitle1" fontWeight="bold">
                Movimientos
              </Typography>
              <Button
                variant="contained"
                size="small"
                startIcon={<AddIcon />}
                disabled={!nroCta}
                onClick={() => router.push(`/bancos/movimientos/generar?cuenta=${nroCta}`)}
              >
                Agregar Movimiento
              </Button>
            </Stack>

            <ZenttoFilterPanel
              filters={MOVIMIENTOS_FILTERS}
              values={movFilterValues}
              onChange={(v) => { setMovFilterValues(v); setPage(1); }}
              searchPlaceholder="Buscar movimiento..."
              searchValue={movSearch}
              onSearchChange={(v) => { setMovSearch(v); setPage(1); }}
            />
            {nroCta && (
              <Chip
                label={`Cuenta: ${nroCta}`}
                onDelete={() => setNroCta("")}
                color="primary"
                sx={{ mb: 1 }}
              />
            )}

            <ZenttoDataGrid
            gridId="bancos-cuentas-movimientos"
              rows={movs}
              columns={colsMovimientos}
              loading={loadingMovs}
              enableHeaderFilters
              rowCount={movsData?.total ?? movs.length}
              pageSizeOptions={[25, 50, 100]}
              paginationModel={{ page: page - 1, pageSize: limit }}
              onPaginationModelChange={(m) => setPage(m.page + 1)}
              paginationMode="server"
              disableRowSelectionOnClick
              getRowId={(r) => r.id ?? r.ID ?? Math.random()}
              density="compact"
              showTotals
              enableClipboard
              sx={{ minHeight: 400 }}
              mobileVisibleFields={['Fecha', 'Monto']}
              smExtraFields={['Tipo', 'Beneficiario']}
            />
          </Paper>
        </Grid>
      </Grid>

      {/* Print styles */}
      <style>{`
        @media print {
          .print-only { display: block !important; }
          body { background: white !important; }
          nav, header, .MuiAppBar-root, .MuiDrawer-root { display: none !important; }
        }
      `}</style>
    </Box>
  );
}
