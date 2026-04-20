'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, CircularProgress, Switch, FormControlLabel, Select, MenuItem, InputLabel, FormControl
} from '@mui/material';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import {
    CategoriaMenu,
    ProductoMenuAdmin,
    useCategoriasAdminQuery,
    useProductosAdminQuery,
    useUpsertProductoAdminMutation,
} from '../../hooks/useRestauranteAdmin';
import { useScopedGridId, useGridRegistration } from '../../lib/zentto-grid';


export function ProductosPage() {
    const gridRef = useRef<any>(null);
    const gridId = useScopedGridId('productos-main');
    const { ready: layoutReady } = useGridLayoutSync(gridId);
    const { registered } = useGridRegistration(layoutReady);
    const { data: productosData, isLoading: isLoadingProductos } = useProductosAdminQuery();
    const { data: categoriasData, isLoading: isLoadingCategorias } = useCategoriasAdminQuery();
    const upsertProductoMutation = useUpsertProductoAdminMutation();
    const [open, setOpen] = useState(false);
    const [editing, setEditing] = useState<Partial<ProductoMenuAdmin>>({});

    const productos = (productosData?.rows ?? []) as ProductoMenuAdmin[];
    const categorias = (categoriasData?.rows ?? []) as CategoriaMenu[];
    const loading = isLoadingProductos || isLoadingCategorias;

    const columns = useMemo<ColumnDef[]>(() => [
        { field: 'codigo', header: 'Codigo', width: 130, sortable: true },
        { field: 'nombre', header: 'Nombre', flex: 1, minWidth: 320, sortable: true },
        { field: 'categoriaNombre', header: 'Categoria', width: 170, sortable: true, groupable: true },
        { field: 'precio', header: 'Precio', width: 120, type: 'number', sortable: true },
        {
            field: 'estadoLabel',
            header: 'Estado',
            width: 130,
            sortable: true,
            groupable: true,
            statusColors: { Activo: 'success', Inactivo: 'default' },
            statusVariant: 'filled',
        },
        {
            field: 'actions', header: 'Acciones', type: 'actions', width: 100, pin: 'right',
            actions: [
                { icon: 'edit', label: 'Editar', action: 'edit', color: '#1976d2' },
                { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#d32f2f' },
            ],
        },
    ], []);

    const rows = useMemo(() =>
        productos.map((p) => ({
            id: Number(p.id),
            codigo: p.codigo,
            nombre: p.nombre,
            categoriaNombre: categorias.find((c) => c.id === Number(p.categoriaId))?.nombre || 'Sin categoria',
            precio: Number(p.precio ?? 0).toFixed(2),
            estadoLabel: p.disponible !== false ? 'Activo' : 'Inactivo',
        })),
        [productos, categorias]
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
                const prod = productos.find((p) => Number(p.id) === row.id);
                if (prod) { setEditing(prod); setOpen(true); }
            } else if (action === "delete") {
                console.log("Eliminar producto:", row);
            }
        };
        el.addEventListener("action-click", handler);
        return () => el.removeEventListener("action-click", handler);
    }, [registered, productos]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const handler = () => { setEditing({ disponible: true }); setOpen(true); };
        el.addEventListener("create-click", handler);
        return () => el.removeEventListener("create-click", handler);
    }, [registered]);

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
                    create-label="Nuevo Producto"
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
                            label="Codigo (SKU)"
                            value={editing.codigo || ''}
                            onChange={(e) => setEditing({ ...editing, codigo: e.target.value })}
                        />
                        <FormControl fullWidth>
                            <InputLabel>Categoria</InputLabel>
                            <Select
                                value={editing.categoriaId || ''}
                                label="Categoria"
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
                            label="Precio Publico"
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
                            label="Disponible en Menu"
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

declare global {
    namespace JSX {
        interface IntrinsicElements {
            'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
        }
    }
}
