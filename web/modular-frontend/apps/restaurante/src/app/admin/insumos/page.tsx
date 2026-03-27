'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Paper, TextField, Typography,
    Button, Dialog, DialogTitle, DialogContent, DialogActions, Grid, Alert, CircularProgress
} from '@mui/material';
import { useGridLayoutSync } from '@zentto/shared-api';
import { useUpsertProductoAdminMutation } from '@/hooks/useRestauranteAdmin';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useInsumosAdminQuery, useProductosAdminQuery } from '@/hooks/useRestauranteAdmin';
import { useScopedGridId } from '@/lib/zentto-grid';


type InsumoRow = {
    id?: number;
    codigo: string;
    descripcion: string;
    unidad?: string;
    existencia?: number;
};

type ProductoAdminRow = {
    id: number;
    codigo: string;
    nombre: string;
    descripcion?: string;
    precio?: number;
    iva?: number;
    categoriaId?: number;
    disponible?: boolean;
    articuloInventarioId?: string;
    esCompuesto?: boolean;
};

export default function AdminInsumosPage() {
    const gridRef = useRef<any>(null);
    const [registered, setRegistered] = useState(false);
    const gridId = useScopedGridId('insumos-main');
    const { ready: layoutReady } = useGridLayoutSync(gridId);
    const [search, setSearch] = useState('');
    const { data, isLoading } = useInsumosAdminQuery(search);
    const { data: productosData } = useProductosAdminQuery();
    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState({ codigo: '', nombre: '', unidad: '', descripcion: '' });
    const [errorMsg, setErrorMsg] = useState<string | null>(null);
    const upsertMutation = useUpsertProductoAdminMutation();

    useEffect(() => {
        if (!layoutReady) return;
        import('@zentto/datagrid').then(() => setRegistered(true));
    }, [layoutReady]);

    const productos = (productosData?.rows ?? []) as unknown as ProductoAdminRow[];
    const productoByCodigo = useMemo(() => {
        const map = new Map<string, ProductoAdminRow>();
        for (const producto of productos) {
            const codigoProducto = String(producto.codigo ?? '').trim();
            const articuloInventarioId = String(producto.articuloInventarioId ?? '').trim();
            if (codigoProducto) {
                map.set(codigoProducto, producto);
            }
            if (articuloInventarioId) {
                map.set(articuloInventarioId, producto);
            }
        }
        return map;
    }, [productos]);

    const rows = useMemo(() => {
        const baseRows = (data?.rows ?? []) as InsumoRow[];
        return baseRows.map((row) => {
            const codigo = String(row.codigo ?? '').trim();
            const matched = productoByCodigo.get(codigo);
            const descripcionProducto = String(matched?.nombre ?? matched?.descripcion ?? '').trim();
            return {
                ...row,
                id: String((row as InsumoRow).codigo),
                descripcion: descripcionProducto || row.descripcion,
                existencia: Number(row.existencia ?? 0),
            };
        });
    }, [data?.rows, productoByCodigo]);

    const columns = useMemo<ColumnDef[]>(() => [
        { field: 'codigo', header: 'Codigo', width: 160, sortable: true },
        { field: 'descripcion', header: 'Descripcion', flex: 1, minWidth: 340, sortable: true },
        { field: 'unidad', header: 'Unidad', width: 120, sortable: true },
        { field: 'existencia', header: 'Existencia', width: 140, type: 'number', sortable: true },
        {
            field: 'actions', header: 'Acciones', type: 'actions', width: 100, pin: 'right',
            actions: [
                { icon: 'edit', label: 'Editar', action: 'edit', color: '#1976d2' },
                { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#d32f2f' },
            ],
        },
    ], []);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        el.columns = columns;
        el.rows = rows;
        el.loading = isLoading;
    }, [rows, isLoading, registered, columns]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const handler = (e: CustomEvent) => {
            const { action, row } = e.detail;
            if (action === "edit") {
                setForm({ codigo: row.codigo ?? '', nombre: row.descripcion ?? '', unidad: row.unidad ?? '', descripcion: '' });
                setErrorMsg(null);
                setModalOpen(true);
            } else if (action === "delete") {
                console.log("Eliminar insumo:", row);
            }
        };
        el.addEventListener("action-click", handler);
        return () => el.removeEventListener("action-click", handler);
    }, [registered]);

    const handleOpenModal = () => {
        setForm({ codigo: '', nombre: '', unidad: '', descripcion: '' });
        setErrorMsg(null);
        setModalOpen(true);
    };

    const handleCloseModal = () => {
        setModalOpen(false);
    };

    const handleFormChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));
    };

    const handleSubmit = async () => {
        if (!form.codigo.trim() || !form.nombre.trim()) {
            setErrorMsg('Codigo y nombre son obligatorios');
            return;
        }
        setErrorMsg(null);
        try {
            await upsertMutation.mutateAsync({
                codigo: form.codigo.trim(),
                nombre: form.nombre.trim(),
                descripcion: form.descripcion.trim() || undefined,
                unidad: form.unidad.trim() || undefined,
                disponible: true,
                precio: 0,
                esCompuesto: false,
            });
            setModalOpen(false);
        } catch (e: unknown) {
            setErrorMsg(e instanceof Error ? e.message : 'Error al crear insumo');
        }
    };

    if (!layoutReady || !registered) {
        return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;
    }

    return (
        <Box sx={{ p: 3, display: 'flex', flexDirection: 'column', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h4" fontWeight="bold">
                    Insumos Restaurante
                </Typography>
                <Button variant="contained" color="primary" sx={{ fontWeight: 700 }} onClick={handleOpenModal}>
                    Nuevo Insumo
                </Button>
            </Box>

            <Paper sx={{ p: 2, mb: 2 }}>
                <TextField
                    fullWidth
                    size="medium"
                    label="Buscar Insumo"
                    placeholder="Codigo o descripcion"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                    inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                />
            </Paper>

            <zentto-grid
                ref={gridRef}
                grid-id={gridId}
                height="calc(100vh - 300px)"
                enable-toolbar
                enable-header-menu
                enable-header-filters
                enable-clipboard
                enable-quick-search
                enable-context-menu
                enable-status-bar
                enable-configurator
            />

            <Dialog open={modalOpen} onClose={handleCloseModal} maxWidth="xs" fullWidth>
                <DialogTitle>Nuevo Insumo</DialogTitle>
                <DialogContent dividers>
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                        <Grid item xs={12}>
                            <TextField
                                name="codigo"
                                label="Codigo"
                                value={form.codigo}
                                onChange={handleFormChange}
                                fullWidth
                                required
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                        <Grid item xs={12}>
                            <TextField
                                name="nombre"
                                label="Nombre"
                                value={form.nombre}
                                onChange={handleFormChange}
                                fullWidth
                                required
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                        <Grid item xs={12}>
                            <TextField
                                name="unidad"
                                label="Unidad"
                                value={form.unidad}
                                onChange={handleFormChange}
                                fullWidth
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                        <Grid item xs={12}>
                            <TextField
                                name="descripcion"
                                label="Descripcion"
                                value={form.descripcion}
                                onChange={handleFormChange}
                                fullWidth
                                multiline
                                minRows={2}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                    </Grid>
                    {errorMsg && <Alert severity="warning" sx={{ mt: 2 }}>{errorMsg}</Alert>}
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleCloseModal}>Cancelar</Button>
                    <Button onClick={handleSubmit} variant="contained" disabled={upsertMutation.isPending}>Crear</Button>
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
