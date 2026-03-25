'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, CircularProgress
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import type { ColumnDef } from '@zentto/datagrid-core';
import {
    AmbienteAdmin,
    useAmbientesAdminQuery,
    useUpsertAmbienteAdminMutation,
} from '@/hooks/useRestauranteAdmin';

const SVG_EDIT = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>';
const SVG_DELETE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>';

export default function AdminAmbientesPage() {
    const gridRef = useRef<any>(null);
    const [registered, setRegistered] = useState(false);
    const { data: ambientesData, isLoading } = useAmbientesAdminQuery();
    const upsertAmbienteMutation = useUpsertAmbienteAdminMutation();
    const [open, setOpen] = useState(false);
    const [editing, setEditing] = useState<Partial<AmbienteAdmin>>({});

    const ambientes = (ambientesData?.rows ?? []) as AmbienteAdmin[];
    const loading = isLoading || upsertAmbienteMutation.isPending;

    useEffect(() => {
        import('@zentto/datagrid').then(() => setRegistered(true));
    }, []);

    const columns = useMemo<ColumnDef[]>(() => [
        { field: 'id', header: 'ID', width: 90, sortable: true },
        { field: 'nombre', header: 'Nombre', flex: 1, minWidth: 220, sortable: true },
        { field: 'color', header: 'Color / Etiqueta', width: 200, sortable: true },
        { field: 'orden', header: 'Orden', width: 120, type: 'number', sortable: true },
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
        el.actionButtons = [
            { icon: SVG_EDIT, label: "Editar", action: "edit", color: "#1976d2" },
            { icon: SVG_DELETE, label: "Eliminar", action: "delete", color: "#d32f2f" },
        ];
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

    if (!registered) {
        return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
    }

    return (
        <Box sx={{ p: 3, display: 'flex', flexDirection: 'column', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h4" fontWeight="bold">Configurar Salones y Mesas</Typography>
                <Button
                    variant="contained"
                    startIcon={<AddIcon />}
                    onClick={() => { setEditing({}); setOpen(true); }}
                >
                    Nuevo Ambiente
                </Button>
            </Box>

            {loading && !rows.length ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                    <CircularProgress />
                </Box>
            ) : (
                <zentto-grid
                    ref={gridRef}
                    height="calc(100vh - 240px)"
                    enable-toolbar
                    enable-header-menu
                    enable-header-filters
                    enable-clipboard
                    enable-quick-search
                    enable-context-menu
                    enable-status-bar
                    enable-configurator
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
