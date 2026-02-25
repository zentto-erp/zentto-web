'use client';

import React, { useMemo, useState } from 'react';
import {
    Box, Paper, TextField, Typography,
    Button, Dialog, DialogTitle, DialogContent, DialogActions, Grid, Alert
} from '@mui/material';
import { useUpsertProductoAdminMutation } from '@/hooks/useRestauranteAdmin';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@datqbox/module-admin';
import { useInsumosAdminQuery, useProductosAdminQuery } from '@/hooks/useRestauranteAdmin';

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

    const [search, setSearch] = useState('');
    const { data, isLoading } = useInsumosAdminQuery(search);
    const { data: productosData } = useProductosAdminQuery();
    const [modalOpen, setModalOpen] = useState(false);
    const [form, setForm] = useState({ codigo: '', nombre: '', unidad: '', descripcion: '' });
    const [errorMsg, setErrorMsg] = useState<string | null>(null);
    const upsertMutation = useUpsertProductoAdminMutation();

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
                id: matched ? Number(matched.id ?? 0) || undefined : undefined,
                descripcion: descripcionProducto || row.descripcion,
            } satisfies InsumoRow;
        });
    }, [data?.rows, productoByCodigo]);
    const page = 1;
    const pageSize = 100;

    const columns = useMemo<GridColDef[]>(() => [
        { field: 'codigo', headerName: 'Código', minWidth: 160, flex: 0.8 },
        { field: 'descripcion', headerName: 'Descripción', minWidth: 340, flex: 1.8, editable: true },
        { field: 'unidad', headerName: 'Unidad', minWidth: 120, flex: 0.6 },
        {
            field: 'existencia',
            headerName: 'Existencia',
            minWidth: 140,
            flex: 0.7,
            valueFormatter: (value) => Number(value ?? 0).toFixed(3),
        },
    ], []);

    const handleUpdateRow = async (row: Record<string, unknown>) => {
        const codigoInsumo = String(row.codigo ?? '').trim();
        const descripcion = String(row.descripcion ?? '').trim();

        if (!codigoInsumo || !descripcion) {
            throw new Error('Código y descripción son obligatorios para guardar.');
        }

        const matched = productoByCodigo.get(codigoInsumo);
        const matchedId = Number(matched?.id ?? row.id ?? 0) || undefined;
        const productoCodigo = String(matched?.codigo ?? codigoInsumo).trim();
        const articuloInventarioId = String(matched?.articuloInventarioId ?? codigoInsumo).trim();

        await upsertMutation.mutateAsync({
            id: matchedId,
            codigo: productoCodigo,
            nombre: descripcion,
            descripcion,
            precio: Number(matched?.precio ?? 0),
            iva: Number(matched?.iva ?? 16),
            categoriaId: matched?.categoriaId ? Number(matched.categoriaId) : undefined,
            disponible: matched?.disponible !== false,
            articuloInventarioId: articuloInventarioId || undefined,
            esCompuesto: matched?.esCompuesto === true,
        });

        return {
            ...row,
            id: matchedId,
            descripcion,
        };
    };

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
            setErrorMsg('Código y nombre son obligatorios');
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
        } catch (e: any) {
            setErrorMsg(e?.message || 'Error al crear insumo');
        }
    };

    return (
        <Box sx={{ p: 3 }}>
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
                    placeholder="Código o descripción"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                    inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                />
            </Paper>

            <EditableDataGrid
                rows={rows}
                columns={columns}
                loading={isLoading}
                page={page}
                pageSize={pageSize}
                rowCount={rows.length}
                onPageChange={() => { }}
                onUpdateRow={handleUpdateRow}
                getRowId={(row) => String((row as InsumoRow).codigo)}
            />

            <Dialog open={modalOpen} onClose={handleCloseModal} maxWidth="xs" fullWidth>
                <DialogTitle>Nuevo Insumo</DialogTitle>
                <DialogContent dividers>
                    <Grid container spacing={2} sx={{ mt: 1 }}>
                        <Grid item xs={12}>
                            <TextField
                                name="codigo"
                                label="Código"
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
                                label="Descripción"
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
