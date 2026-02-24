'use client';

import React, { useMemo, useState } from 'react';
import {
    Box, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, IconButton, CircularProgress, Chip, Switch, FormControlLabel, Select, MenuItem, InputLabel, FormControl
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@datqbox/module-admin';
import {
    CategoriaMenu,
    ProductoMenuAdmin,
    useCategoriasAdminQuery,
    useDeleteProductoAdminMutation,
    useProductosAdminQuery,
    useUpsertProductoAdminMutation,
} from '@/hooks/useRestauranteAdmin';

export default function AdminProductosPage() {
    const { data: productosData, isLoading: isLoadingProductos } = useProductosAdminQuery();
    const { data: categoriasData, isLoading: isLoadingCategorias } = useCategoriasAdminQuery();
    const upsertProductoMutation = useUpsertProductoAdminMutation();
    const deleteProductoMutation = useDeleteProductoAdminMutation();
    const [open, setOpen] = useState(false);
    const [editing, setEditing] = useState<Partial<ProductoMenuAdmin>>({});

    const page = 1;
    const pageSize = 100;

    const productos = (productosData?.rows ?? []) as ProductoMenuAdmin[];
    const categorias = (categoriasData?.rows ?? []) as CategoriaMenu[];
    const loading = isLoadingProductos || isLoadingCategorias;

    const handleSave = async () => {
        try {
            await upsertProductoMutation.mutateAsync({
                id: editing.id,
                codigo: editing.codigo || `PRD-${Date.now().toString().slice(-4)}`,
                nombre: editing.nombre,
                descripcion: editing.descripcion || '',
                precio: Number(editing.precio || 0),
                iva: Number(editing.iva || 16),
                categoriaId: editing.categoriaId,
                disponible: editing.disponible !== false
            });
            setOpen(false);
            setEditing({});
        } catch (e) {
            alert('Error guardando producto');
        }
    };

    const columns = useMemo<GridColDef[]>(() => [
        { field: 'codigo', headerName: 'Código', minWidth: 130, flex: 0.8, editable: true },
        {
            field: 'nombre',
            headerName: 'Nombre',
            minWidth: 320,
            flex: 2,
            editable: true,
            renderCell: (params) => (
                <Box sx={{ py: 0.75 }}>
                    <Typography variant="body1" fontWeight="medium">{params.row.nombre}</Typography>
                    <Typography variant="body2" color="text.secondary">{params.row.descripcion || ''}</Typography>
                </Box>
            ),
        },
        {
            field: 'categoriaId',
            headerName: 'Categoría',
            minWidth: 170,
            flex: 1,
            type: 'singleSelect',
            editable: true,
            valueOptions: categorias.map((cat) => ({ value: cat.id, label: cat.nombre })),
            valueFormatter: (value) => categorias.find((cat) => cat.id === Number(value))?.nombre || 'Sin categoría',
        },
        {
            field: 'precio',
            headerName: 'Precio',
            minWidth: 120,
            flex: 0.8,
            type: 'number',
            editable: true,
            valueFormatter: (value) => `$${Number(value ?? 0).toFixed(2)}`,
        },
        {
            field: 'disponible',
            headerName: 'Estado',
            minWidth: 130,
            flex: 0.8,
            type: 'boolean',
            editable: true,
            renderCell: (params) => (
                <Chip
                    label={params.value ? 'Activo' : 'Inactivo'}
                    color={params.value ? 'success' : 'default'}
                    size="small"
                />
            ),
        },
    ], [categorias]);

    const handleUpdateRow = async (row: Record<string, unknown>) => {
        await upsertProductoMutation.mutateAsync({
            id: Number(row.id),
            codigo: String(row.codigo || '').trim(),
            nombre: String(row.nombre || '').trim(),
            descripcion: String(row.descripcion || ''),
            precio: Number(row.precio || 0),
            iva: Number(row.iva || 16),
            categoriaId: row.categoriaId ? Number(row.categoriaId) : undefined,
            disponible: row.disponible !== false,
        });
    };

    const handleDeleteRow = async (row: Record<string, unknown>) => {
        await deleteProductoMutation.mutateAsync(Number(row.id));
    };

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h4" fontWeight="bold">Platos y Bebidas</Typography>
                <Button
                    variant="contained"
                    startIcon={<AddIcon />}
                    onClick={() => { setEditing({ disponible: true }); setOpen(true); }}
                >
                    Nuevo Producto
                </Button>
            </Box>

            {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                    <CircularProgress />
                </Box>
            ) : (
                <EditableDataGrid
                    rows={productos}
                    columns={columns}
                    loading={loading}
                    page={page}
                    pageSize={pageSize}
                    rowCount={productos.length}
                    onPageChange={() => { }}
                    onAddRow={() => { setEditing({ disponible: true }); setOpen(true); }}
                    onUpdateRow={handleUpdateRow}
                    onDeleteRow={handleDeleteRow}
                    addButtonText="Nuevo Producto"
                    getRowId={(row) => Number(row.id)}
                />
            )}

            <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{editing.id ? 'Editar Producto' : 'Nuevo Producto'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'grid', gap: 2, mt: 2 }}>
                        <TextField
                            fullWidth
                            label="Nombre del Plato o Bebida"
                            value={editing.nombre || ''}
                            onChange={(e) => setEditing({ ...editing, nombre: e.target.value })}
                        />
                        <TextField
                            fullWidth
                            label="Código (SKU)"
                            value={editing.codigo || ''}
                            onChange={(e) => setEditing({ ...editing, codigo: e.target.value })}
                        />
                        <FormControl fullWidth>
                            <InputLabel>Categoría</InputLabel>
                            <Select
                                value={editing.categoriaId || ''}
                                label="Categoría"
                                onChange={(e) => setEditing({ ...editing, categoriaId: Number(e.target.value) })}
                            >
                                {categorias.map(cat => (
                                    <MenuItem value={cat.id} key={cat.id}>{cat.nombre}</MenuItem>
                                ))}
                            </Select>
                        </FormControl>
                        <TextField
                            fullWidth
                            type="number"
                            label="Precio Público"
                            value={editing.precio || ''}
                            onChange={(e) => setEditing({ ...editing, precio: Number(e.target.value) })}
                        />
                        <TextField
                            fullWidth
                            type="number"
                            label="% IVA (Ej: 16)"
                            value={editing.iva === undefined ? '' : editing.iva}
                            onChange={(e) => setEditing({ ...editing, iva: Number(e.target.value) })}
                        />
                        <FormControlLabel
                            control={
                                <Switch
                                    checked={editing.disponible !== false}
                                    onChange={(e) => setEditing({ ...editing, disponible: e.target.checked })}
                                />
                            }
                            label="Disponible en Menú"
                        />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpen(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleSave}>Guardar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
