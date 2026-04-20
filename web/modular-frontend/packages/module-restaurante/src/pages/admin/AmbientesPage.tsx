'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, CircularProgress
} from '@mui/material';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import {
    AmbienteAdmin,
    useAmbientesAdminQuery,
    useUpsertAmbienteAdminMutation,
} from '../../hooks/useRestauranteAdmin';
import { useScopedGridId, useGridRegistration } from '../../lib/zentto-grid';


export function AmbientesPage() {
    const gridRef = useRef<any>(null);
    const gridId = useScopedGridId('ambientes-main');
    const { ready: layoutReady } = useGridLayoutSync(gridId);
    const { registered } = useGridRegistration(layoutReady);
    const { data: ambientesData, isLoading } = useAmbientesAdminQuery();
    const upsertAmbienteMutation = useUpsertAmbienteAdminMutation();
    const [open, setOpen] = useState(false);
    const [editing, setEditing] = useState<Partial<AmbienteAdmin>>({});

    const ambientes = (ambientesData?.rows ?? []) as AmbienteAdmin[];
    const loading = isLoading || upsertAmbienteMutation.isPending;

    const columns = useMemo<ColumnDef[]>(() => [
        { field: 'id', header: 'ID', width: 90, sortable: true },
        { field: 'nombre', header: 'Nombre', flex: 1, minWidth: 220, sortable: true },
        { field: 'color', header: 'Color / Etiqueta', width: 200, sortable: true },
        { field: 'orden', header: 'Orden', width: 120, type: 'number', sortable: true },
        {
            field: 'actions', header: 'Acciones', type: 'actions', width: 100, pin: 'right',
            actions: [
                { icon: 'edit', label: 'Editar', action: 'edit', color: '#1976d2' },
                { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#d32f2f' },
            ],
        },
    ], []);

    const rows = useMemo(() =>
        ambientes.map((a) => ({
            id: Number(a.id),
            nombre: a.nombre,
            color: a.color || '#4CAF50',
            orden: a.orden,
        })),
        [ambientes]
    );

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        el.columns = columns;
        el.rows = rows;
        el.loading = loading;
    }, [rows, loading, registered, columns]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const handler = (e: CustomEvent) => {
            const { action, row } = e.detail;
            if (action === "edit") {
                const amb = ambientes.find((a) => Number(a.id) === row.id);
                if (amb) { setEditing(amb); setOpen(true); }
            } else if (action === "delete") {
                console.log("Eliminar ambiente:", row);
            }
        };
        el.addEventListener("action-click", handler);
        return () => el.removeEventListener("action-click", handler);
    }, [registered, ambientes]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const handler = () => { setEditing({}); setOpen(true); };
        el.addEventListener("create-click", handler);
        return () => el.removeEventListener("create-click", handler);
    }, [registered]);

    const handleSave = async () => {
        try {
            await upsertAmbienteMutation.mutateAsync({
                id: editing.id,
                nombre: editing.nombre,
                color: editing.color || '#4CAF50',
                orden: Number(editing.orden || 1)
            });
            setOpen(false);
            setEditing({});
        } catch (e) {
            alert('Error guardando ambiente');
        }
    };

    if (!layoutReady || !registered) {
        return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
    }

    return (
        <Box sx={{ p: 3, display: 'flex', flexDirection: 'column', height: '100%' }}>
            {loading && !rows.length ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                    <CircularProgress />
                </Box>
            ) : (
                <zentto-grid
                    ref={gridRef}
                    grid-id={gridId}
                    height="calc(100vh - 240px)"
                    enable-toolbar
                    enable-header-menu
                    enable-header-filters
                    enable-clipboard
                    enable-quick-search
                    enable-context-menu
                    enable-status-bar
                    enable-configurator
                    enable-create
                    create-label="Nuevo Ambiente"
                />
            )}

            <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{editing.id ? 'Editar Ambiente' : 'Nuevo Ambiente'}</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        label="Nombre del Salon"
                        value={editing.nombre || ''}
                        onChange={(e) => setEditing({ ...editing, nombre: e.target.value })}
                        sx={{ mt: 2, mb: 2 }}
                    />
                    <TextField
                        fullWidth
                        label="Color (Hexadecimal) Ej: #FF0000"
                        value={editing.color || ''}
                        onChange={(e) => setEditing({ ...editing, color: e.target.value })}
                        sx={{ mb: 2 }}
                    />
                    <TextField
                        fullWidth
                        type="number"
                        label="Orden (ej: 1, 2, 3...)"
                        value={editing.orden || ''}
                        onChange={(e) => setEditing({ ...editing, orden: Number(e.target.value) })}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpen(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleSave}>Guardar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}

declare global {
    namespace JSX {
        interface IntrinsicElements {
            'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
        }
    }
}
