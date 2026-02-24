'use client';

import React, { useMemo } from 'react';
import {
    Box, Typography, Button, Paper, CircularProgress
} from '@mui/material';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@datqbox/module-admin';
import { ProductoMenuAdmin, useProductosAdminQuery } from '@/hooks/useRestauranteAdmin';

export default function AdminRecetasPage() {
    const { data: productosData, isLoading } = useProductosAdminQuery();

    const page = 1;
    const pageSize = 100;

    const productos = (productosData?.rows ?? []) as ProductoMenuAdmin[];
    const loading = isLoading;

    const columns = useMemo<GridColDef[]>(() => [
        { field: 'nombre', headerName: 'Plato o Bebida', minWidth: 280, flex: 1.3 },
        {
            field: 'recetaEstado',
            headerName: 'Ingredientes / Insumos Asociados',
            minWidth: 260,
            flex: 1,
            valueGetter: () => 'Asignación de Inventario requerida',
        },
        {
            field: 'actions',
            headerName: 'Configurar Receta',
            minWidth: 200,
            flex: 0.9,
            sortable: false,
            filterable: false,
            renderCell: () => (
                <Button
                    variant="outlined"
                    startIcon={<ReceiptLongIcon />}
                    size="small"
                >
                    Editar Receta
                </Button>
            ),
        },
    ], []);

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h4" fontWeight="bold">Configurar Recetas e Insumos</Typography>
            </Box>

            <Paper sx={{ mb: 3, p: 2, bgcolor: '#e3f2fd' }}>
                <Typography variant="body1" color="primary" fontWeight="medium">
                    Gestor de Porciones.
                </Typography>
                <Typography variant="body2" color="textSecondary">
                    Lista de platos. Seleccione uno para asociarle componentes de inventario (ingredientes, salsas, etc).
                </Typography>
            </Paper>

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
                    getRowId={(row) => Number(row.id)}
                />
            )}
        </Box>
    );
}
