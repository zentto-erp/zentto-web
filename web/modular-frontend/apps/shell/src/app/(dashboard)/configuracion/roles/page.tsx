'use client';

import React, { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  Box, Typography, Button, Dialog, DialogTitle,
  DialogContent, DialogActions, TextField, Alert,
  CircularProgress, Checkbox, Chip, Stack, Divider,
} from '@mui/material';
import { useAuth } from '@zentto/shared-auth';
import { useToast, FormGrid, FormField } from '@zentto/shared-ui';
import {
  useRolesList, useCreateRole, useDeleteRole,
  useRolePermissions, useSaveRolePermissions,
} from '@zentto/shared-api';
import type { Role, RolePermission, BulkPermissionInput, CreateRoleInput } from '@zentto/shared-api';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import { useScopedGridId, useGridRegistration } from '@/lib/zentto-grid';

// ─── Main page ──────────────────────────────────────────────
export default function RolesPage() {
  const gridRef = useRef<any>(null);
  const gridId = useScopedGridId('roles-main');
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useGridRegistration(layoutReady);
  const { isAdmin } = useAuth();
  const { showToast } = useToast();
  const { data, isLoading, error } = useRolesList();
  const deleteMutation = useDeleteRole();

  // Dialogs
  const [createOpen, setCreateOpen] = useState(false);
  const [editRole, setEditRole] = useState<Role | null>(null);
  const [permRole, setPermRole] = useState<Role | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<Role | null>(null);

  if (!isAdmin) {
    return (
      <Box><Alert severity="error">Solo los administradores pueden gestionar roles.</Alert></Box>
    );
  }

  const handleDelete = async () => {
    if (!deleteConfirm) return;
    if (deleteConfirm.IsSystem) {
      showToast('No se pueden eliminar roles del sistema', 'error');
      setDeleteConfirm(null);
      return;
    }
    try {
      await deleteMutation.mutateAsync(deleteConfirm.RoleId);
      showToast('Rol eliminado correctamente', 'success');
      setDeleteConfirm(null);
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : 'Error al eliminar rol', 'error');
    }
  };

  const columns: ColumnDef[] = [
    { field: 'RoleCode', header: 'Codigo', width: 140, sortable: true },
    { field: 'RoleName', header: 'Nombre', flex: 1, minWidth: 200, sortable: true },
    {
      field: 'IsSystem', header: 'Sistema', width: 110, sortable: true,
      statusColors: { 'Si': 'primary', 'No': 'default' },
      statusVariant: 'filled',
    },
    {
      field: 'IsActive', header: 'Activo', width: 110, sortable: true,
      statusColors: { 'Si': 'success', 'No': 'error' },
      statusVariant: 'filled',
    },
    { field: 'UserCount', header: 'Usuarios', width: 110, sortable: true },
    {
      field: 'actions', header: 'Acciones', type: 'actions', width: 140, pin: 'right',
      actions: [
        { icon: 'security', label: 'Permisos', action: 'permissions', color: '#388e3c' },
        { icon: 'edit', label: 'Editar', action: 'edit', color: '#1976d2' },
        { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#d32f2f' },
      ],
    },
  ];

  const rows = useMemo(() => {
    const rawRows = data?.rows || [];
    return rawRows.map((row: Role) => ({
      id: row.RoleId,
      RoleId: row.RoleId,
      RoleCode: row.RoleCode,
      RoleName: row.RoleName,
      IsSystem: row.IsSystem ? 'Si' : 'No',
      IsActive: row.IsActive ? 'Si' : 'No',
      UserCount: row.UserCount ?? 0,
    }));
  }, [data?.rows]);

  const rawRows = data?.rows || [];

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const actionHandler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      const role = rawRows.find((r: Role) => r.RoleId === row.RoleId);
      if (action === 'edit' && role) {
        setEditRole(role);
      } else if (action === 'delete' && role) {
        setDeleteConfirm(role);
      } else if (action === 'permissions' && role) {
        setPermRole(role);
      }
    };
    const createHandler = () => setCreateOpen(true);
    el.addEventListener('action-click', actionHandler);
    el.addEventListener('create-click', createHandler);
    return () => {
      el.removeEventListener('action-click', actionHandler);
      el.removeEventListener('create-click', createHandler);
    };
  }, [registered, rawRows]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const row = e.detail?.row;
      if (row) {
        const role = rawRows.find((r: Role) => r.RoleId === row.RoleId);
        if (role) setEditRole(role);
      }
    };
    el.addEventListener('row-click', handler);
    return () => el.removeEventListener('row-click', handler);
  }, [registered, rawRows]);

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {error && <Alert severity="error" sx={{ mb: 2 }}>Error al cargar roles</Alert>}

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
            create-label="Nuevo Rol"
          />
        </Box>
      )}

      {/* Create / Edit Dialog */}
      <RoleFormDialog
        role={createOpen ? undefined : editRole ?? undefined}
        open={createOpen || !!editRole}
        onClose={() => { setCreateOpen(false); setEditRole(null); }}
        onSuccess={(msg) => showToast(msg, 'success')}
      />

      {/* Permissions Dialog */}
      <PermissionsDialog
        role={permRole}
        onClose={() => setPermRole(null)}
        onSuccess={() => showToast('Permisos actualizados correctamente', 'success')}
      />

      {/* Delete Confirmation */}
      <Dialog open={!!deleteConfirm} onClose={() => setDeleteConfirm(null)} maxWidth="xs" fullWidth>
        <DialogTitle>Confirmar Eliminacion</DialogTitle>
        <DialogContent>
          {deleteConfirm?.IsSystem ? (
            <Alert severity="warning">
              El rol <strong>{deleteConfirm.RoleName}</strong> es un rol del sistema y no puede ser eliminado.
            </Alert>
          ) : (
            <>
              <Typography>
                Estas seguro de eliminar el rol <strong>{deleteConfirm?.RoleName}</strong>?
              </Typography>
              {(deleteConfirm?.UserCount ?? 0) > 0 && (
                <Alert severity="warning" sx={{ mt: 1 }}>
                  Este rol tiene {deleteConfirm?.UserCount} usuario(s) asignado(s). Se les removera el rol.
                </Alert>
              )}
              <Typography variant="caption" color="error">Esta accion no se puede deshacer.</Typography>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteConfirm(null)}>Cancelar</Button>
          {!deleteConfirm?.IsSystem && (
            <Button color="error" variant="contained" onClick={handleDelete} disabled={deleteMutation.isPending}>
              {deleteMutation.isPending ? <CircularProgress size={20} /> : 'Eliminar'}
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// ─── Role Form Dialog (Create / Edit) ──────────────────────
function RoleFormDialog({
  role, open, onClose, onSuccess,
}: {
  role?: Role;
  open: boolean;
  onClose: () => void;
  onSuccess: (msg: string) => void;
}) {
  const createMutation = useCreateRole();
  const [form, setForm] = useState<CreateRoleInput>({ roleCode: '', roleName: '' });
  const [err, setErr] = useState<string | null>(null);
  const isEdit = !!role;

  React.useEffect(() => {
    if (role) {
      setForm({ roleCode: role.RoleCode, roleName: role.RoleName });
    } else {
      setForm({ roleCode: '', roleName: '' });
    }
    setErr(null);
  }, [role, open]);

  const handleSubmit = async () => {
    setErr(null);
    if (!form.roleCode || !form.roleName) {
      setErr('Codigo y nombre son obligatorios');
      return;
    }
    try {
      if (isEdit) {
        await createMutation.mutateAsync({ ...form, roleCode: role!.RoleCode });
      } else {
        await createMutation.mutateAsync(form);
      }
      onClose();
      onSuccess(isEdit ? 'Rol actualizado correctamente' : 'Rol creado correctamente');
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al guardar rol');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{isEdit ? `Editar Rol: ${role?.RoleCode}` : 'Crear Rol'}</DialogTitle>
      <DialogContent>
        <FormGrid spacing={2} sx={{ mt: 1 }}>
          {err && <FormField xs={12}><Alert severity="error">{err}</Alert></FormField>}
          <FormField xs={12} sm={6}>
            <TextField
              label="Codigo del Rol"
              required
              fullWidth
              size="small"
              value={form.roleCode}
              onChange={(e) => setForm({ ...form, roleCode: e.target.value.toUpperCase() })}
              inputProps={{ maxLength: 20 }}
              disabled={isEdit}
            />
          </FormField>
          <FormField xs={12} sm={6}>
            <TextField
              label="Nombre del Rol"
              required
              fullWidth
              size="small"
              value={form.roleName}
              onChange={(e) => setForm({ ...form, roleName: e.target.value })}
            />
          </FormField>
        </FormGrid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSubmit} disabled={createMutation.isPending}>
          {createMutation.isPending ? <CircularProgress size={20} /> : isEdit ? 'Guardar' : 'Crear'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Permissions Matrix Dialog ──────────────────────────────
const PERM_COLS = [
  { key: 'CanCreate', label: 'Crear' },
  { key: 'CanRead', label: 'Leer' },
  { key: 'CanUpdate', label: 'Editar' },
  { key: 'CanDelete', label: 'Eliminar' },
  { key: 'CanExport', label: 'Exportar' },
  { key: 'CanApprove', label: 'Aprobar' },
] as const;

type PermKey = typeof PERM_COLS[number]['key'];

function PermissionsDialog({
  role, onClose, onSuccess,
}: {
  role: Role | null;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const { data, isLoading } = useRolePermissions(role?.RoleId ?? null);
  const saveMutation = useSaveRolePermissions(role?.RoleId ?? 0);
  const [perms, setPerms] = useState<Record<number, Record<PermKey, boolean>>>({});
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (data?.rows) {
      const map: Record<number, Record<PermKey, boolean>> = {};
      data.rows.forEach((p: RolePermission) => {
        map[p.PermissionId] = {
          CanCreate: p.CanCreate,
          CanRead: p.CanRead,
          CanUpdate: p.CanUpdate,
          CanDelete: p.CanDelete,
          CanExport: p.CanExport,
          CanApprove: p.CanApprove,
        };
      });
      setPerms(map);
      setErr(null);
    }
  }, [data?.rows]);

  const toggle = (permId: number, col: PermKey) => {
    setPerms((prev) => ({
      ...prev,
      [permId]: {
        ...prev[permId],
        [col]: !prev[permId]?.[col],
      },
    }));
  };

  const toggleAll = (col: PermKey, value: boolean) => {
    setPerms((prev) => {
      const next = { ...prev };
      Object.keys(next).forEach((id) => {
        next[Number(id)] = { ...next[Number(id)], [col]: value };
      });
      return next;
    });
  };

  const handleSave = async () => {
    setErr(null);
    const bulk: BulkPermissionInput[] = Object.entries(perms).map(([id, flags]) => ({
      permissionId: Number(id),
      canCreate: flags.CanCreate,
      canRead: flags.CanRead,
      canUpdate: flags.CanUpdate,
      canDelete: flags.CanDelete,
      canExport: flags.CanExport,
      canApprove: flags.CanApprove,
    }));
    try {
      await saveMutation.mutateAsync(bulk);
      onClose();
      onSuccess();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Error al guardar permisos');
    }
  };

  // Group permissions by module
  const grouped = useMemo(() => {
    const rows = data?.rows || [];
    const map = new Map<string, RolePermission[]>();
    rows.forEach((p: RolePermission) => {
      const mod = p.ModuleName || 'General';
      if (!map.has(mod)) map.set(mod, []);
      map.get(mod)!.push(p);
    });
    return map;
  }, [data?.rows]);

  return (
    <Dialog open={!!role} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>Permisos del Rol: {role?.RoleName}</DialogTitle>
      <DialogContent>
        {isLoading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box>
        ) : (
          <Box sx={{ mt: 1 }}>
            {err && <Alert severity="error" sx={{ mb: 2 }}>{err}</Alert>}

            {/* Header row with toggle all */}
            <Box
              sx={{
                display: 'grid',
                gridTemplateColumns: '1fr repeat(6, 80px)',
                gap: 0.5,
                mb: 1,
                px: 1,
                py: 0.5,
                bgcolor: 'grey.100',
                borderRadius: 1,
                fontWeight: 700,
                fontSize: '0.8rem',
                alignItems: 'center',
              }}
            >
              <Typography variant="subtitle2" fontWeight={700}>Permiso</Typography>
              {PERM_COLS.map((col) => (
                <Box key={col.key} sx={{ textAlign: 'center' }}>
                  <Typography variant="caption" fontWeight={700}>{col.label}</Typography>
                  <Box>
                    <Checkbox
                      size="small"
                      onChange={(_, checked) => toggleAll(col.key, checked)}
                      sx={{ p: 0 }}
                    />
                  </Box>
                </Box>
              ))}
            </Box>

            {/* Permission rows grouped by module */}
            {Array.from(grouped.entries()).map(([moduleName, permissions]) => (
              <Box key={moduleName} sx={{ mb: 2 }}>
                <Typography
                  variant="subtitle2"
                  sx={{ bgcolor: 'primary.main', color: 'white', px: 1, py: 0.5, borderRadius: 0.5, mb: 0.5 }}
                >
                  {moduleName}
                </Typography>
                {permissions.map((p) => (
                  <Box
                    key={p.PermissionId}
                    sx={{
                      display: 'grid',
                      gridTemplateColumns: '1fr repeat(6, 80px)',
                      gap: 0.5,
                      px: 1,
                      py: 0.25,
                      alignItems: 'center',
                      '&:hover': { bgcolor: 'action.hover' },
                    }}
                  >
                    <Typography variant="body2">{p.PermissionName}</Typography>
                    {PERM_COLS.map((col) => (
                      <Box key={col.key} sx={{ textAlign: 'center' }}>
                        <Checkbox
                          size="small"
                          checked={perms[p.PermissionId]?.[col.key] ?? false}
                          onChange={() => toggle(p.PermissionId, col.key)}
                          sx={{ p: 0 }}
                        />
                      </Box>
                    ))}
                  </Box>
                ))}
              </Box>
            ))}

            {grouped.size === 0 && (
              <Alert severity="info">No hay permisos configurados en el sistema.</Alert>
            )}
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancelar</Button>
        <Button variant="contained" onClick={handleSave} disabled={saveMutation.isPending}>
          {saveMutation.isPending ? <CircularProgress size={20} /> : 'Guardar Permisos'}
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
