'use client';

import React, { useState, useMemo, useCallback } from 'react';
import {
  Box, Typography, Button, IconButton, Chip, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, FormControlLabel, Switch,
  Alert, CircularProgress, Stack, Tooltip, MenuItem, Card, CardContent,
  Checkbox, FormGroup, Divider, InputAdornment,
} from '@mui/material';
import { DataGrid, GridColDef, GridRenderCellParams } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import LockResetIcon from '@mui/icons-material/LockReset';
import SecurityIcon from '@mui/icons-material/Security';
import SearchIcon from '@mui/icons-material/Search';
import { useAuth } from '@datqbox/shared-auth';
import { SYSTEM_MODULES } from '@datqbox/shared-auth';
import { useToast } from '@datqbox/shared-ui';
import {
  useUsuariosList, useCreateUsuario, useUpdateUsuario, useDeleteUsuario,
  useResetPassword, useUsuarioModulos, useSetUsuarioModulos, useSystemModules,
} from '@datqbox/shared-api';
import type { Usuario, CreateUsuarioInput, UpdateUsuarioInput } from '@datqbox/shared-api';

// ─── Module labels ──────────────────────────────────────────
const MODULE_LABELS: Record<string, string> = {
  dashboard: 'Dashboard',
  facturas: 'Facturas',
  compras: 'Compras',
  clientes: 'Clientes',
  proveedores: 'Proveedores',
  inventario: 'Inventario',
  articulos: 'Artículos',
  pagos: 'Pagos',
  abonos: 'Abonos',
  'cuentas-por-pagar': 'Cuentas x Pagar',
  cxc: 'CxC',
  cxp: 'CxP',
  bancos: 'Bancos',
  contabilidad: 'Contabilidad',
  nomina: 'Nómina',
  configuracion: 'Configuración',
  reportes: 'Reportes',
  usuarios: 'Usuarios',
};

const USER_TYPES = [
  { value: 'SUP', label: 'Super Admin (SUP)' },
  { value: 'ADMIN', label: 'Administrador' },
  { value: 'USER', label: 'Usuario' },
];

// ─── Main page ──────────────────────────────────────────────
export default function UsuariosPage() {
  const { isAdmin } = useAuth();
  const { showToast } = useToast();
  const [search, setSearch] = useState('');
  const { data, isLoading, error } = useUsuariosList(search || undefined);
  const deleteMutation = useDeleteUsuario();

  // Dialogs
  const [createOpen, setCreateOpen] = useState(false);
  const [editUser, setEditUser] = useState<Usuario | null>(null);
  const [resetPwdUser, setResetPwdUser] = useState<string | null>(null);
  const [modulosUser, setModulosUser] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  if (!isAdmin) {
    return (
      <Box><Alert severity="error">Solo los administradores pueden gestionar usuarios.</Alert></Box>
    );
  }

  const handleDelete = async () => {
    if (!deleteConfirm) return;
    try {
      await deleteMutation.mutateAsync(deleteConfirm);
      showToast('Usuario eliminado correctamente', 'success');
      setDeleteConfirm(null);
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : 'Error al eliminar usuario', 'error');
    }
  };

  const columns: GridColDef[] = [
    { field: 'Cod_Usuario', headerName: 'Código', width: 120, flex: 0.5 },
    { field: 'Nombre', headerName: 'Nombre', width: 200, flex: 1 },
    {
      field: 'Tipo', headerName: 'Tipo', width: 130,
      renderCell: (params: GridRenderCellParams) => {
        const v = params.value as string;
        const isAdm = v === 'ADMIN' || v === 'SUP';
        return <Chip label={v || 'USER'} color={isAdm ? 'primary' : 'default'} size="small" />;
      },
    },
    {
      field: 'permisos', headerName: 'Permisos', width: 300, sortable: false,
      renderCell: (params: GridRenderCellParams) => {
        const row = params.row as Usuario;
        const flags = [
          row.Updates && 'Editar',
          row.Addnews && 'Crear',
          row.Deletes && 'Eliminar',
          row.PrecioMinimo && 'Precio',
          row.Credito && 'Crédito',
        ].filter(Boolean);
        return (
          <Stack direction="row" spacing={0.5} sx={{ flexWrap: 'wrap' }}>
            {flags.map((f) => <Chip key={f as string} label={f} size="small" variant="outlined" />)}
            {flags.length === 0 && <Typography variant="caption" color="text.secondary">Sin permisos</Typography>}
          </Stack>
        );
      },
    },
    {
      field: 'actions', headerName: 'Acciones', width: 200, sortable: false,
      renderCell: (params: GridRenderCellParams) => {
        const row = params.row as Usuario;
        return (
          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Editar"><IconButton size="small" onClick={() => setEditUser(row)}><EditIcon fontSize="small" /></IconButton></Tooltip>
            <Tooltip title="Módulos"><IconButton size="small" onClick={() => setModulosUser(row.Cod_Usuario)}><SecurityIcon fontSize="small" /></IconButton></Tooltip>
            <Tooltip title="Resetear contraseña"><IconButton size="small" onClick={() => setResetPwdUser(row.Cod_Usuario)}><LockResetIcon fontSize="small" /></IconButton></Tooltip>
            <Tooltip title="Eliminar"><IconButton size="small" color="error" onClick={() => setDeleteConfirm(row.Cod_Usuario)}><DeleteIcon fontSize="small" /></IconButton></Tooltip>
          </Stack>
        );
      },
    },
  ];

  const rows = data?.rows || [];

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <Box sx={{ mb: 2, display: 'flex', justifyContent: 'flex-end' }}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
          Nuevo Usuario
        </Button>
      </Box>

      <Card sx={{ mb: 2 }}>
        <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
          <TextField
            size="small" placeholder="Buscar por código o nombre..." fullWidth
            value={search} onChange={(e) => setSearch(e.target.value)}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
          />
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar usuarios</Alert>}

      <Box sx={{ flex: 1, minHeight: 0, width: '100%' }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          getRowId={(row) => row.Cod_Usuario}
          pageSizeOptions={[10, 25, 50]}
          initialState={{ pagination: { paginationModel: { pageSize: 10 } } }}
          disableRowSelectionOnClick
          sx={{ bgcolor: 'background.paper', borderRadius: 2 }}
        />
      </Box>

      {/* Create Dialog */}
      <CreateUsuarioDialog open={createOpen} onClose={() => setCreateOpen(false)} onSuccess={() => showToast('Usuario creado correctamente', 'success')} />

      {/* Edit Dialog */}
      <EditUsuarioDialog user={editUser} onClose={() => setEditUser(null)} onSuccess={() => showToast('Usuario actualizado correctamente', 'success')} />

      {/* Module Access Dialog */}
      <ModulosDialog codigo={modulosUser} onClose={() => setModulosUser(null)} onSuccess={() => showToast('Módulos actualizados correctamente', 'success')} />

      {/* Reset Password Dialog */}
      <ResetPasswordDialog codigo={resetPwdUser} onClose={() => setResetPwdUser(null)} onSuccess={() => showToast('Contraseña reseteada correctamente', 'success')} />

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Confirmar Eliminación</DialogTitle>
        <DialogContent>
          <Typography>¿Estás seguro de eliminar al usuario <strong>{deleteConfirm}</strong>?</Typography>
          <Typography variant="caption" color="error">Esta acción no se puede deshacer.</Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          <Button color="error" variant="contained" onClick={handleDelete} disabled={deleteMutation.isPending}>
            {deleteMutation.isPending ? <CircularProgress size={20} /> : 'Eliminar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// ─── Create User Dialog ─────────────────────────────────────
function CreateUsuarioDialog({ open, onClose, onSuccess }: { open: boolean; onClose: () => void; onSuccess: () => void }) {
  const createMutation = useCreateUsuario();
  const [form, setForm] = useState<CreateUsuarioInput>({
    Cod_Usuario: '', Password: '', Nombre: '', Tipo: 'USER',
    Updates: false, Addnews: false, Deletes: false,
    Creador: false, Cambiar: true, PrecioMinimo: false, Credito: false,
  });
  const [err, setErr] = useState<string | null>(null);

  const handleSubmit = async () => {
    setErr(null);
    if (!form.Cod_Usuario || !form.Password) {
      setErr('Código y contraseña son obligatorios');
      return;
    }
    if (form.Password.length < 6) {
      setErr('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    try {
      await createMutation.mutateAsync(form);
      setForm({ Cod_Usuario: '', Password: '', Nombre: '', Tipo: 'USER', Updates: false, Addnews: false, Deletes: false, Creador: false, Cambiar: true, PrecioMinimo: false, Credito: false });
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al crear usuario');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Crear Usuario</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          {err && <Alert severity="error">{err}</Alert>}
          <TextField label="Código de Usuario" required fullWidth size="small"
            value={form.Cod_Usuario} onChange={(e) => setForm({ ...form, Cod_Usuario: e.target.value.toUpperCase() })}
            inputProps={{ maxLength: 10 }} />
          <TextField label="Nombre" fullWidth size="small"
            value={form.Nombre} onChange={(e) => setForm({ ...form, Nombre: e.target.value })} />
          <TextField label="Contraseña" required type="password" fullWidth size="small"
            value={form.Password} onChange={(e) => setForm({ ...form, Password: e.target.value })}
            helperText="Mínimo 6 caracteres, 1 mayúscula, 1 número" />
          <TextField label="Tipo" select fullWidth size="small"
            value={form.Tipo} onChange={(e) => setForm({ ...form, Tipo: e.target.value })}>
            {USER_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
          </TextField>
          <Divider />
          <Typography variant="subtitle2">Permisos de Campo</Typography>
          <FormGroup row>
            <FormControlLabel control={<Switch checked={form.Updates} onChange={(_, c) => setForm({ ...form, Updates: c })} />} label="Editar" />
            <FormControlLabel control={<Switch checked={form.Addnews} onChange={(_, c) => setForm({ ...form, Addnews: c })} />} label="Crear" />
            <FormControlLabel control={<Switch checked={form.Deletes} onChange={(_, c) => setForm({ ...form, Deletes: c })} />} label="Eliminar" />
            <FormControlLabel control={<Switch checked={form.PrecioMinimo} onChange={(_, c) => setForm({ ...form, PrecioMinimo: c })} />} label="Precio Mín." />
            <FormControlLabel control={<Switch checked={form.Credito} onChange={(_, c) => setForm({ ...form, Credito: c })} />} label="Crédito" />
            <FormControlLabel control={<Switch checked={form.Cambiar} onChange={(_, c) => setForm({ ...form, Cambiar: c })} />} label="Cambiar Pwd" />
          </FormGroup>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={createMutation.isPending}>
          {createMutation.isPending ? <CircularProgress size={20} /> : 'Crear'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Edit User Dialog ───────────────────────────────────────
function EditUsuarioDialog({ user, onClose, onSuccess }: { user: Usuario | null; onClose: () => void; onSuccess: () => void }) {
  const updateMutation = useUpdateUsuario(user?.Cod_Usuario || '');
  const [form, setForm] = useState<UpdateUsuarioInput>({});
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (user) {
      setForm({
        Nombre: user.Nombre, Tipo: user.Tipo,
        Updates: user.Updates, Addnews: user.Addnews, Deletes: user.Deletes,
        Creador: user.Creador, Cambiar: user.Cambiar,
        PrecioMinimo: user.PrecioMinimo, Credito: user.Credito,
      });
      setErr(null);
    }
  }, [user]);

  const handleSubmit = async () => {
    setErr(null);
    try {
      await updateMutation.mutateAsync(form);
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al actualizar');
    }
  };

  return (
    <Dialog open={!!user} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Editar Usuario: {user?.Cod_Usuario}</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          {err && <Alert severity="error">{err}</Alert>}
          <TextField label="Nombre" fullWidth size="small"
            value={form.Nombre || ''} onChange={(e) => setForm({ ...form, Nombre: e.target.value })} />
          <TextField label="Nueva Contraseña (dejar vacío para no cambiar)" type="password" fullWidth size="small"
            value={form.Password || ''} onChange={(e) => setForm({ ...form, Password: e.target.value })}
            helperText="Dejar vacío para mantener la contraseña actual" />
          <TextField label="Tipo" select fullWidth size="small"
            value={form.Tipo || ''} onChange={(e) => setForm({ ...form, Tipo: e.target.value })}>
            {USER_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
          </TextField>
          <Divider />
          <Typography variant="subtitle2">Permisos de Campo</Typography>
          <FormGroup row>
            <FormControlLabel control={<Switch checked={form.Updates ?? false} onChange={(_, c) => setForm({ ...form, Updates: c })} />} label="Editar" />
            <FormControlLabel control={<Switch checked={form.Addnews ?? false} onChange={(_, c) => setForm({ ...form, Addnews: c })} />} label="Crear" />
            <FormControlLabel control={<Switch checked={form.Deletes ?? false} onChange={(_, c) => setForm({ ...form, Deletes: c })} />} label="Eliminar" />
            <FormControlLabel control={<Switch checked={form.PrecioMinimo ?? false} onChange={(_, c) => setForm({ ...form, PrecioMinimo: c })} />} label="Precio Mín." />
            <FormControlLabel control={<Switch checked={form.Credito ?? false} onChange={(_, c) => setForm({ ...form, Credito: c })} />} label="Crédito" />
            <FormControlLabel control={<Switch checked={form.Cambiar ?? false} onChange={(_, c) => setForm({ ...form, Cambiar: c })} />} label="Cambiar Pwd" />
          </FormGroup>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={updateMutation.isPending}>
          {updateMutation.isPending ? <CircularProgress size={20} /> : 'Guardar'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Module Access Dialog ───────────────────────────────────
function ModulosDialog({ codigo, onClose, onSuccess }: { codigo: string | null; onClose: () => void; onSuccess: () => void }) {
  const { data: modulosData, isLoading } = useUsuarioModulos(codigo);
  const setModulosMutation = useSetUsuarioModulos(codigo || '');
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (modulosData) {
      const map: Record<string, boolean> = {};
      modulosData.forEach((m) => { map[m.Modulo] = m.Permitido; });
      setSelected(map);
      setErr(null);
    }
  }, [modulosData]);

  const handleToggle = (mod: string) => {
    setSelected((prev) => ({ ...prev, [mod]: !prev[mod] }));
  };

  const handleSelectAll = () => {
    const all: Record<string, boolean> = {};
    SYSTEM_MODULES.forEach((m) => { all[m] = true; });
    setSelected(all);
  };

  const handleClearAll = () => {
    const all: Record<string, boolean> = {};
    SYSTEM_MODULES.forEach((m) => { all[m] = false; });
    setSelected(all);
  };

  const handleSave = async () => {
    setErr(null);
    const modulos = SYSTEM_MODULES.map((m) => ({
      modulo: m,
      permitido: selected[m] ?? false,
    }));
    try {
      await setModulosMutation.mutateAsync(modulos);
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al guardar módulos');
    }
  };

  return (
    <Dialog open={!!codigo} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Acceso a Módulos: {codigo}</DialogTitle>
      <DialogContent>
        {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box>
        ) : (
          <Stack spacing={1} sx={{ mt: 1 }}>
            {err && <Alert severity="error">{err}</Alert>}
            <Stack direction="row" spacing={1} sx={{ mb: 1 }}>
              <Button size="small" onClick={handleSelectAll}>Seleccionar Todos</Button>
              <Button size="small" onClick={handleClearAll}>Quitar Todos</Button>
            </Stack>
            <FormGroup>
              {SYSTEM_MODULES.map((mod) => (
                <FormControlLabel
                  key={mod}
                  control={<Checkbox checked={selected[mod] ?? false} onChange={() => handleToggle(mod)} />}
                  label={MODULE_LABELS[mod] || mod}
                />
              ))}
            </FormGroup>
          </Stack>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSave} disabled={setModulosMutation.isPending}>
          {setModulosMutation.isPending ? <CircularProgress size={20} /> : 'Guardar'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Reset Password Dialog ──────────────────────────────────
function ResetPasswordDialog({ codigo, onClose, onSuccess }: { codigo: string | null; onClose: () => void; onSuccess: () => void }) {
  const resetMutation = useResetPassword();
  const [newPwd, setNewPwd] = useState('');
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (codigo) { setNewPwd(''); setErr(null); }
  }, [codigo]);

  const handleSubmit = async () => {
    setErr(null);
    if (newPwd.length < 6) { setErr('La contraseña debe tener al menos 6 caracteres'); return; }
    try {
      await resetMutation.mutateAsync({ codUsuario: codigo!, newPassword: newPwd });
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al resetear contraseña');
    }
  };

  return (
    <Dialog open={!!codigo} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>Resetear Contraseña: {codigo}</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          {err && <Alert severity="error">{err}</Alert>}
          <TextField
            label="Nueva Contraseña" type="password" fullWidth size="small"
            value={newPwd} onChange={(e) => setNewPwd(e.target.value)}
            helperText="Mínimo 6 caracteres"
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={resetMutation.isPending}>
          {resetMutation.isPending ? <CircularProgress size={20} /> : 'Resetear'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
