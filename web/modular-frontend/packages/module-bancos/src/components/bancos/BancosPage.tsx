"use client";
import { useMemo, useState } from "react";
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Stack,
  TextField,
  Typography,
  Paper,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import { useToast, ZenttoDataGrid } from "@zentto/shared-ui";
import {
  useBancosList,
  useCreateBanco,
  useUpdateBanco,
  useDeleteBanco,
} from "../../hooks/useBancosAuxiliares";

const EMPTY_FORM = {
  Nombre: "",
  Contacto: "",
  Direccion: "",
  Telefonos: "",
  Co_Usuario: "SUP",
};

export default function BancosPage() {
  /* ── state ── */
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [formOpen, setFormOpen] = useState(false);
  const [editNombre, setEditNombre] = useState<string | null>(null);
  const [form, setForm] = useState({ ...EMPTY_FORM });
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);

  /* ── queries & mutations ── */
  const { data, isLoading } = useBancosList({ search, page, limit });
  const crear = useCreateBanco();
  const actualizar = useUpdateBanco();
  const eliminar = useDeleteBanco();
  const { showToast } = useToast();

  const saving = crear.isPending || actualizar.isPending;

  const rows = (data?.rows ?? data?.items ?? []) as Record<string, any>[];

  /* ── columns ── */
  const columns = useMemo<GridColDef[]>(
    () => [
      { field: "Nombre", headerName: "Nombre", flex: 1, minWidth: 180 },
      { field: "Contacto", headerName: "Contacto", width: 160 },
      { field: "Direccion", headerName: "Dirección", flex: 1, minWidth: 200 },
      { field: "Telefonos", headerName: "Teléfonos", width: 150 },
      {
        field: "acciones",
        headerName: "Acciones",
        width: 110,
        sortable: false,
        renderCell: (params) => (
          <Stack direction="row" spacing={0.5}>
            <IconButton size="small" onClick={() => handleEdit(params.row)}>
              <EditIcon fontSize="small" />
            </IconButton>
            <IconButton
              size="small"
              color="error"
              onClick={() => setDeleteTarget(params.row.Nombre)}
            >
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Stack>
        ),
      },
    ],
    [],
  );

  /* ── handlers ── */
  const handleNew = () => {
    setForm({ ...EMPTY_FORM });
    setEditNombre(null);
    setFormOpen(true);
  };

  const handleEdit = (row: Record<string, any>) => {
    setForm({
      Nombre: row.Nombre ?? "",
      Contacto: row.Contacto ?? "",
      Direccion: row.Direccion ?? "",
      Telefonos: row.Telefonos ?? "",
      Co_Usuario: "SUP",
    });
    setEditNombre(row.Nombre);
    setFormOpen(true);
  };

  const handleSave = async () => {
    try {
      if (editNombre) {
        await actualizar.mutateAsync({ nombre: editNombre, data: form });
        showToast("Banco actualizado correctamente", "success");
      } else {
        await crear.mutateAsync(form);
        showToast("Banco creado correctamente", "success");
      }
      setFormOpen(false);
    } catch (err: any) {
      showToast(err?.message ?? "Error al guardar", "error");
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      await eliminar.mutateAsync(deleteTarget);
      showToast("Banco eliminado correctamente", "success");
      setDeleteTarget(null);
    } catch (err: any) {
      showToast(err?.message ?? "Error al eliminar", "error");
    }
  };

  /* ── render ── */
  return (
    <Box>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Bancos</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={handleNew}>
          Nuevo Banco
        </Button>
      </Stack>

      {/* Filters */}
      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar"
          size="small"
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          sx={{ minWidth: 300 }}
        />
      </Stack>

      {/* Grid */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        loading={isLoading}
        rowCount={data?.total ?? rows.length}
        pageSizeOptions={[25, 50, 100]}
        paginationModel={{ page: page - 1, pageSize: limit }}
        onPaginationModelChange={(m) => {
          setPage(m.page + 1);
          setLimit(m.pageSize);
        }}
        paginationMode="server"
        disableRowSelectionOnClick
        getRowId={(r) => r.Nombre ?? r.NOMBRE ?? Math.random()}
        sx={{ minHeight: 400 }}
        mobileVisibleFields={['Nombre', 'Telefonos']}
        smExtraFields={['Contacto']}
      />

      {/* Create / Edit Dialog */}
      <Dialog open={formOpen} onClose={() => setFormOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{editNombre ? "Editar Banco" : "Nuevo Banco"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Nombre"
              fullWidth
              value={form.Nombre}
              disabled={!!editNombre}
              onChange={(e) => setForm((f) => ({ ...f, Nombre: e.target.value }))}
            />
            <TextField
              label="Contacto"
              fullWidth
              value={form.Contacto}
              onChange={(e) => setForm((f) => ({ ...f, Contacto: e.target.value }))}
            />
            <TextField
              label="Dirección"
              fullWidth
              value={form.Direccion}
              onChange={(e) => setForm((f) => ({ ...f, Direccion: e.target.value }))}
            />
            <TextField
              label="Teléfonos"
              fullWidth
              value={form.Telefonos}
              onChange={(e) => setForm((f) => ({ ...f, Telefonos: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setFormOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSave} disabled={saving}>
            {editNombre ? "Actualizar" : "Guardar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteTarget != null} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Confirmar Eliminación</DialogTitle>
        <DialogContent>
          <Typography>
            ¿Está seguro de eliminar el banco &quot;{deleteTarget}&quot;?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDelete}
            disabled={eliminar.isPending}
          >
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
