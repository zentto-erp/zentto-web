'use client';

import React, { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  Box, Typography, Button, IconButton, Chip, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, FormControlLabel, Switch,
  Alert, CircularProgress, Tooltip, MenuItem, Card, CardContent,
  Checkbox, FormGroup, Divider, InputAdornment, Stack,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import LockResetIcon from '@mui/icons-material/LockReset';
import SecurityIcon from '@mui/icons-material/Security';
import SearchIcon from '@mui/icons-material/Search';
import { useAuth } from '@zentto/shared-auth';
import { SYSTEM_MODULES } from '@zentto/shared-auth';
import { useToast, FormGrid, FormField } from '@zentto/shared-ui';
import {
  useUsuariosList, useCreateUsuario, useUpdateUsuario, useDeleteUsuario,
  useResetPassword, useUsuarioModulos, useSetUsuarioModulos, useSystemModules,
} from '@zentto/shared-api';
import { useGridLayoutSync } from '@zentto/shared-api';
import type { Usuario, CreateUsuarioInput, UpdateUsuarioInput } from '@zentto/shared-api';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useScopedGridId } from '@/lib/zentto-grid';


// ─── Module labels ──────────────────────────────────────────
const MODULE_LABELS: Record<string, string> = {
  dashboard: 'Dashboard',
  facturas: 'Facturas',
  compras: 'Compras',
  clientes: 'Clientes',
  proveedores: 'Proveedores',
  inventario: 'Inventario',
  articulos: 'Articulos',
  pagos: 'Pagos',
  abonos: 'Abonos',
  'cuentas-por-pagar': 'Cuentas x Pagar',
  cxc: 'CxC',
  cxp: 'CxP',
  bancos: 'Bancos',
  contabilidad: 'Contabilidad',
  nomina: 'Nomina',
  configuracion: 'Configuracion',
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
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const gridId = useScopedGridId('usuarios-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
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

  useEffect(() => {
    if (!layoutReady) return;
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, [layoutReady]);

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

  const columns: ColumnDef[] = [
    { field: 'Cod_Usuario', header: 'Codigo', width: 120, sortable: true },
    { field: 'Nombre', header: 'Nombre', flex: 1, minWidth: 200, sortable: true },
    {
      field: 'Tipo',
      header: 'Tipo',
      width: 130,
      sortable: true,
      groupable: true,
      statusColors: { ADMIN: 'primary', SUP: 'primary', USER: 'default' },
      statusVariant: 'filled',
    },
    { field: 'permisosLabel', header: 'Permisos', width: 300, sortable: false },
    {
      field: 'actions', header: 'Acciones', type: 'actions', width: 100, pin: 'right',
      actions: [
        { icon: 'edit', label: 'Editar', action: 'edit', color: '#1976d2' },
        { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#d32f2f' },
      ],
    },
  ];

  const rows = useMemo(() => {
    const rawRows = data?.rows || [];
    return rawRows.map((row: Usuario) => {
      const flags = [
        row.Updates && 'Editar',
        row.Addnews && 'Crear',
        row.Deletes && 'Eliminar',
        row.PrecioMinimo && 'Precio',
        row.Credito && 'Credito',
      ].filter(Boolean);
      return {
        id: row.Cod_Usuario,
        Cod_Usuario: row.Cod_Usuario,
        Nombre: row.Nombre,
        Tipo: row.Tipo || 'USER',
        permisosLabel: flags.length > 0 ? flags.join(', ') : 'Sin permisos',
      };
    });
  }, [data?.rows]);

  // Store raw rows for dialog lookups
  const rawRows = data?.rows || [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  // Handle action-click for edit/delete and create-click
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      const usuario = rawRows.find((u: Usuario) => u.Cod_Usuario === row.Cod_Usuario);
      if (action === "edit" && usuario) {
        setEditUser(usuario);
      } else if (action === "delete") {
        setDeleteConfirm(row.Cod_Usuario);
      }
    };
    const createHandler = () => setCreateOpen(true);
    el.addEventListener("action-click", actionHandler);
    el.addEventListener("create-click", createHandler);
    return () => {
      el.removeEventListener("action-click", actionHandler);
      el.removeEventListener("create-click", createHandler);
    };
  }, [registered, rawRows]);

  // Handle row click for actions
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const row = e.detail?.row;
      if (row) {
        const usuario = rawRows.find((u: Usuario) => u.Cod_Usuario === row.Cod_Usuario);
        if (usuario) setEditUser(usuario);
      }
    };
    el.addEventListener('row-click', handler);
    return () => el.removeEventListener('row-click', handler);
  }, [registered, rawRows]);

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      <Card sx={{ mb: 2 }}>
        <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
          <TextField
            size="small" placeholder="Buscar por codigo o nombre..." fullWidth
            value={search} onChange={(e) => setSearch(e.target.value)}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
          />
        </CardContent>
      </Card>

      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar usuarios</Alert>}

      {!layoutReady || !registered ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}><CircularProgress /></Box>
      ) : (
        <Box sx={{ flex: 1, minHeight: 0, width: '100%' }}>
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            height="calc(100vh - 280px)"
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-create
            create-label="Nuevo Usuario"
          />
        </Box>
      )}

      {/* Create Dialog */}
      <CreateUsuarioDialog open={createOpen} onClose={() => setCreateOpen(false)} onSuccess={() => showToast('Usuario creado correctamente', 'success')} />

      {/* Edit Dialog */}
      <EditUsuarioDialog user={editUser} onClose={() => setEditUser(null)} onSuccess={() => showToast('Usuario actualizado correctamente', 'success')} />

      {/* Module Access Dialog */}
      <ModulosDialog codigo={modulosUser} onClose={() => setModulosUser(null)} onSuccess={() => showToast('Modulos actualizados correctamente', 'success')} />

      {/* Reset Password Dialog */}
      <ResetPasswordDialog codigo={resetPwdUser} onClose={() => setResetPwdUser(null)} onSuccess={() => showToast('Contrasena reseteada correctamente', 'success')} />

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent>
          <Typography>Estas seguro de eliminar al usuario <strong>{deleteConfirm}</strong>?</Typography>
          <Typography variant="caption" color="error">Esta accion no se puede deshacer.</Typography>
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
      setErr('Codigo y contrasena son obligatorios');
      return;
    }
    if (form.Password.length < 6) {
      setErr('La contrasena debe tener al menos 6 caracteres');
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
        <FormGrid spacing={2} sx={{ mt: 1 }}>
          {err && <FormField xs={12}><Alert severity="error">{err}</Alert></FormField>}
          <FormField xs={12} sm={6}>
            <TextField label="Codigo de Usuario" required fullWidth size="small"
              value={form.Cod_Usuario} onChange={(e) => setForm({ ...form, Cod_Usuario: e.target.value.toUpperCase() })}
              inputProps={{ maxLength: 10 }} />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField label="Nombre" fullWidth size="small"
              value={form.Nombre} onChange={(e) => setForm({ ...form, Nombre: e.target.value })} />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField label="Contrasena" required type="password" fullWidth size="small"
              value={form.Password} onChange={(e) => setForm({ ...form, Password: e.target.value })}
              helperText="Minimo 6 caracteres, 1 mayuscula, 1 numero" />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField label="Tipo" select fullWidth size="small"
              value={form.Tipo} onChange={(e) => setForm({ ...form, Tipo: e.target.value })}>
              {USER_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
            </TextField>
          </FormField>
          <FormField xs={12}>
            <Divider />
          </FormField>
          <FormField xs={12}>
            <Typography variant="subtitle2">Permisos de Campo</Typography>
          </FormField>
          <FormField xs={12}>
            <FormGroup row>
              <FormControlLabel control={<Switch checked={form.Updates} onChange={(_, c) => setForm({ ...form, Updates: c })} />} label="Editar" />
              <FormControlLabel control={<Switch checked={form.Addnews} onChange={(_, c) => setForm({ ...form, Addnews: c })} />} label="Crear" />
              <FormControlLabel control={<Switch checked={form.Deletes} onChange={(_, c) => setForm({ ...form, Deletes: c })} />} label="Eliminar" />
              <FormControlLabel control={<Switch checked={form.PrecioMinimo} onChange={(_, c) => setForm({ ...form, PrecioMinimo: c })} />} label="Precio Min." />
              <FormControlLabel control={<Switch checked={form.Credito} onChange={(_, c) => setForm({ ...form, Credito: c })} />} label="Credito" />
              <FormControlLabel control={<Switch checked={form.Cambiar} onChange={(_, c) => setForm({ ...form, Cambiar: c })} />} label="Cambiar Pwd" />
            </FormGroup>
          </FormField>
        </FormGrid>
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
        <FormGrid spacing={2} sx={{ mt: 1 }}>
          {err && <FormField xs={12}><Alert severity="error">{err}</Alert></FormField>}
          <FormField xs={12} sm={6}>
            <TextField label="Nombre" fullWidth size="small"
              value={form.Nombre || ''} onChange={(e) => setForm({ ...form, Nombre: e.target.value })} />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField label="Tipo" select fullWidth size="small"
              value={form.Tipo || ''} onChange={(e) => setForm({ ...form, Tipo: e.target.value })}>
              {USER_TYPES.map((t) => <MenuItem key={t.value} value={t.value}>{t.label}</MenuItem>)}
            </TextField>
          </FormField>
          <FormField xs={12}>
            <TextField label="Nueva Contrasena (dejar vacio para no cambiar)" type="password" fullWidth size="small"
              value={form.Password || ''} onChange={(e) => setForm({ ...form, Password: e.target.value })}
              helperText="Dejar vacio para mantener la contrasena actual" />
          </FormField>
          <FormField xs={12}>
            <Divider />
          </FormField>
          <FormField xs={12}>
            <Typography variant="subtitle2">Permisos de Campo</Typography>
          </FormField>
          <FormField xs={12}>
            <FormGroup row>
              <FormControlLabel control={<Switch checked={form.Updates ?? false} onChange={(_, c) => setForm({ ...form, Updates: c })} />} label="Editar" />
              <FormControlLabel control={<Switch checked={form.Addnews ?? false} onChange={(_, c) => setForm({ ...form, Addnews: c })} />} label="Crear" />
              <FormControlLabel control={<Switch checked={form.Deletes ?? false} onChange={(_, c) => setForm({ ...form, Deletes: c })} />} label="Eliminar" />
              <FormControlLabel control={<Switch checked={form.PrecioMinimo ?? false} onChange={(_, c) => setForm({ ...form, PrecioMinimo: c })} />} label="Precio Min." />
              <FormControlLabel control={<Switch checked={form.Credito ?? false} onChange={(_, c) => setForm({ ...form, Credito: c })} />} label="Credito" />
              <FormControlLabel control={<Switch checked={form.Cambiar ?? false} onChange={(_, c) => setForm({ ...form, Cambiar: c })} />} label="Cambiar Pwd" />
            </FormGroup>
          </FormField>
        </FormGrid>
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
      setErr(e instanceof Error ? e.message : 'Error al guardar modulos');
    }
  };

  return (
    <Dialog open={!!codigo} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Acceso a Modulos: {codigo}</DialogTitle>
      <DialogContent>
        {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box>
        ) : (
          <FormGrid spacing={1} sx={{ mt: 1 }}>
            {err && <FormField xs={12}><Alert severity="error">{err}</Alert></FormField>}
            <FormField xs={12}>
              <Stack direction="row" spacing={1}>
                <Button size="small" onClick={handleSelectAll}>Seleccionar Todos</Button>
                <Button size="small" onClick={handleClearAll}>Quitar Todos</Button>
              </Stack>
            </FormField>
            <FormField xs={12}>
              <FormGroup>
                {SYSTEM_MODULES.map((mod) => (
                  <FormControlLabel
                    key={mod}
                    control={<Checkbox checked={selected[mod] ?? false} onChange={() => handleToggle(mod)} />}
                    label={MODULE_LABELS[mod] || mod}
                  />
                ))}
              </FormGroup>
            </FormField>
          </FormGrid>
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
    if (newPwd.length < 6) { setErr('La contrasena debe tener al menos 6 caracteres'); return; }
    try {
      await resetMutation.mutateAsync({ codUsuario: codigo!, newPassword: newPwd });
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al resetear contrasena');
    }
  };

  return (
    <Dialog open={!!codigo} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle>Resetear Contrasena: {codigo}</DialogTitle>
      <DialogContent>
        <FormGrid spacing={2} sx={{ mt: 1 }}>
          {err && <FormField xs={12}><Alert severity="error">{err}</Alert></FormField>}
          <FormField xs={12}>
            <TextField
              label="Nueva Contrasena" type="password" fullWidth size="small"
              value={newPwd} onChange={(e) => setNewPwd(e.target.value)}
              helperText="Minimo 6 caracteres"
            />
          </FormField>
        </FormGrid>
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
