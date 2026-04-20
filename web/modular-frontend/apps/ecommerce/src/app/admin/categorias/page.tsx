'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Stack, Typography, Button, TextField, Dialog,
    DialogTitle, DialogContent, DialogActions, CircularProgress,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import { FormGrid, FormField } from '@zentto/shared-ui';
import {
    useAdminCategories,
    useUpsertCategory,
    useDeleteCategory,
    buildEcommerceGridId,
    useEcommerceGridId,
    useEcommerceGridRegistration,
} from '@zentto/module-ecommerce';

const COLUMNS: ColumnDef[] = [
    { field: 'code', header: 'Código', width: 120, sortable: true },
    { field: 'name', header: 'Nombre', flex: 1, minWidth: 180, sortable: true },
    { field: 'productCount', header: 'Productos', width: 110, type: 'number' },
    {
        field: 'actions',
        header: 'Acciones',
        type: 'actions',
        width: 120,
        pin: 'right',
        actions: [
            { icon: 'edit', label: 'Editar', action: 'edit' },
            { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#ef4444' },
        ],
    },
];

const GRID_ID = buildEcommerceGridId('admin-categorias', 'main');

export default function AdminCategoriasPage() {
    const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
    useEcommerceGridId(gridRef, GRID_ID);
    const { registered } = useEcommerceGridRegistration(gridLayoutReady);

    const { data, isLoading } = useAdminCategories();
    const upsertMut = useUpsertCategory();
    const deleteMut = useDeleteCategory();

    const [open, setOpen] = useState(false);
    const [form, setForm] = useState<{ code: string; name: string; description?: string; isUpdate?: boolean }>({
        code: '', name: '', description: '',
    });

    const rows = useMemo(
        () => (data?.rows ?? []).map((r: any) => ({ ...r, id: r.code })),
        [data]
    );

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        el.columns = COLUMNS;
        el.rows = rows;
        el.loading = isLoading;
    }, [rows, isLoading, registered]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const onAction = (e: any) => {
            const { action, row } = e.detail ?? {};
            if (!row) return;
            if (action === 'edit') {
                setForm({ code: row.code, name: row.name, description: row.description ?? '', isUpdate: true });
                setOpen(true);
            } else if (action === 'delete') {
                if (window.confirm(`¿Eliminar categoría "${row.name}"?`)) {
                    deleteMut.mutate(row.code);
                }
            }
        };
        const onCreate = () => {
            setForm({ code: '', name: '', description: '' });
            setOpen(true);
        };
        el.addEventListener('action-click', onAction);
        el.addEventListener('create-click', onCreate);
        return () => {
            el.removeEventListener('action-click', onAction);
            el.removeEventListener('create-click', onCreate);
        };
    }, [registered, deleteMut]);

    const handleSave = async () => {
        try {
            await upsertMut.mutateAsync(form);
            setOpen(false);
        } catch {
            /* handled by mutation */
        }
    };

    if (!registered) return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;

    return (
        <Box>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h5" fontWeight={700}>Categorías</Typography>
                <Button
                    variant="contained" startIcon={<AddIcon />}
                    onClick={() => { setForm({ code: '', name: '', description: '' }); setOpen(true); }}
                    sx={{ bgcolor: '#ff9900', '&:hover': { bgcolor: '#e68a00' } }}
                >
                    Nueva categoría
                </Button>
            </Stack>

            <zentto-grid
                ref={gridRef}
                export-filename="admin-categorias"
                height="calc(100vh - 240px)"
                enable-create create-label="Nueva categoría"
                enable-toolbar enable-header-menu enable-header-filters enable-clipboard
                enable-quick-search enable-context-menu enable-status-bar enable-configurator
            ></zentto-grid>

            <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{form.isUpdate ? 'Editar categoría' : 'Nueva categoría'}</DialogTitle>
                <DialogContent>
                    <FormGrid spacing={2} sx={{ mt: 1 }}>
                        <FormField xs={12} sm={4}>
                            <TextField label="Código" fullWidth required disabled={form.isUpdate}
                                value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })}
                                inputProps={{ maxLength: 20 }}
                            />
                        </FormField>
                        <FormField xs={12} sm={8}>
                            <TextField label="Nombre" fullWidth required value={form.name}
                                onChange={(e) => setForm({ ...form, name: e.target.value })}
                                inputProps={{ maxLength: 100 }}
                            />
                        </FormField>
                        <FormField xs={12}>
                            <TextField label="Descripción" fullWidth multiline minRows={2}
                                value={form.description ?? ''}
                                onChange={(e) => setForm({ ...form, description: e.target.value })}
                                inputProps={{ maxLength: 500 }}
                            />
                        </FormField>
                    </FormGrid>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpen(false)}>Cancelar</Button>
                    <Button
                        variant="contained"
                        onClick={handleSave}
                        disabled={upsertMut.isPending || !form.code || !form.name}
                    >
                        {upsertMut.isPending ? 'Guardando…' : 'Guardar'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}

declare global {
    namespace JSX {
        interface IntrinsicElements {
            'zentto-grid': React.DetailedHTMLProps<
                React.HTMLAttributes<HTMLElement> & Record<string, any>,
                HTMLElement
            >;
        }
    }
}
