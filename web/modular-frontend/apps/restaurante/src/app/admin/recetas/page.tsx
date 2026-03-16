'use client';

import React, { useMemo, useState } from 'react';
import {
    Box,
    Typography,
    Button,
    Paper,
    CircularProgress,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Grid,
    TextField,
    List,
    ListItem,
    ListItemText,
    IconButton,
    Alert,
    Autocomplete,
} from '@mui/material';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import DeleteIcon from '@mui/icons-material/Delete';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@zentto/module-admin';
import {
    ProductoMenuAdmin,
    RecetaItemAdmin,
    InventarioLookupItem,
    useDeleteRecetaItemMutation,
    useInsumosRestauranteLookupQuery,
    useProductoDetalleAdminQuery,
    useProductosAdminQuery,
    useUpsertRecetaItemMutation,
} from '@/hooks/useRestauranteAdmin';

export default function AdminRecetasPage() {
    const { data: productosData, isLoading } = useProductosAdminQuery();
    const [productoSeleccionado, setProductoSeleccionado] = useState<ProductoMenuAdmin | null>(null);
    const [inventarioId, setInventarioId] = useState('');
    const [insumoSeleccionado, setInsumoSeleccionado] = useState<InventarioLookupItem | null>(null);
    const [inventarioSearchText, setInventarioSearchText] = useState('');
    const [cantidad, setCantidad] = useState<number>(1);
    const [unidad, setUnidad] = useState('UND');
    const [comentario, setComentario] = useState('');
    const [errorMsg, setErrorMsg] = useState<string | null>(null);

    const detalleQuery = useProductoDetalleAdminQuery(productoSeleccionado ? Number(productoSeleccionado.id) : undefined);
    const inventarioLookupQuery = useInsumosRestauranteLookupQuery(
        inventarioSearchText,
        Boolean(productoSeleccionado)
    );
    const upsertRecetaMutation = useUpsertRecetaItemMutation();
    const deleteRecetaMutation = useDeleteRecetaItemMutation();

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
            renderCell: (params) => (
                <Button
                    variant="outlined"
                    startIcon={<ReceiptLongIcon />}
                    size="small"
                    onClick={() => {
                        const row = params.row as ProductoMenuAdmin;
                        setProductoSeleccionado(row);
                        setInventarioId('');
                        setInsumoSeleccionado(null);
                        setInventarioSearchText('');
                        setCantidad(1);
                        setUnidad('UND');
                        setComentario('');
                        setErrorMsg(null);
                    }}
                >
                    Editar Receta
                </Button>
            ),
        },
    ], []);

    const recetaRows = (detalleQuery.data?.receta ?? []) as RecetaItemAdmin[];

    const handleGuardarReceta = async () => {
        if (!productoSeleccionado) return;

        if (!inventarioId.trim()) {
            setErrorMsg('Debe indicar el código de insumo/inventario.');
            return;
        }

        if (!Number.isFinite(cantidad) || cantidad <= 0) {
            setErrorMsg('La cantidad debe ser mayor a cero.');
            return;
        }

        setErrorMsg(null);
        await upsertRecetaMutation.mutateAsync({
            productoId: Number(productoSeleccionado.id),
            inventarioId: inventarioId.trim(),
            cantidad,
            unidad: unidad.trim() || undefined,
            comentario: comentario.trim() || undefined,
        });

        setInventarioId('');
        setInsumoSeleccionado(null);
        setInventarioSearchText('');
        setCantidad(1);
        setUnidad('UND');
        setComentario('');
    };

    const handleEliminarReceta = async (item: RecetaItemAdmin) => {
        if (!productoSeleccionado) return;
        await deleteRecetaMutation.mutateAsync({ id: Number(item.id), productoId: Number(productoSeleccionado.id) });
    };

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

            <Dialog
                open={Boolean(productoSeleccionado)}
                onClose={() => setProductoSeleccionado(null)}
                maxWidth="md"
                fullWidth
            >
                <DialogTitle>
                    Editar Receta: {productoSeleccionado?.nombre}
                </DialogTitle>
                <DialogContent dividers>
                    <Grid container spacing={2} sx={{ mb: 2, '& .MuiInputLabel-root': { fontWeight: 600 }, '& .MuiInputBase-input': { fontWeight: 500, fontSize: '0.98rem' } }}>
                        <Grid item xs={12} md={5}>
                            <Autocomplete
                                options={(inventarioLookupQuery.data?.rows ?? []) as InventarioLookupItem[]}
                                loading={inventarioLookupQuery.isLoading}
                                value={insumoSeleccionado}
                                inputValue={inventarioSearchText}
                                onInputChange={(_e, newValue) => {
                                    setInventarioSearchText(newValue);
                                }}
                                onChange={(_e, option) => {
                                    const selected = option as InventarioLookupItem | null;
                                    setInsumoSeleccionado(selected);
                                    setInventarioId(selected?.codigo ?? '');
                                    if (selected?.unidad) {
                                        setUnidad(selected.unidad);
                                    }
                                    setErrorMsg(null);
                                }}
                                getOptionLabel={(option) => {
                                    const item = option as InventarioLookupItem;
                                    const name = item.descripcion || item.codigo;
                                    return `${item.codigo} — ${name}`;
                                }}
                                isOptionEqualToValue={(option, value) => option.codigo === value.codigo}
                                renderOption={(props, option) => {
                                    const { key, ...rest } = props;
                                    return (
                                        <Box component="li" key={key} {...rest} sx={{ py: 1 }}>
                                            <Box>
                                                <Typography fontWeight={700}>{option.codigo}</Typography>
                                                <Typography variant="body2" color="text.secondary">
                                                    {option.descripcion || 'Sin descripción'}
                                                    {typeof option.existencia === 'number' ? ` • Stock: ${option.existencia}` : ''}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    );
                                }}
                                renderInput={(params) => (
                                    <TextField
                                        {...params}
                                        fullWidth
                                        size="medium"
                                        label="Buscar Insumo"
                                        placeholder="Código o descripción"
                                        InputLabelProps={{ ...params.InputLabelProps, shrink: true, style: { fontWeight: 600 } }}
                                        inputProps={{ ...params.inputProps, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                                        helperText="Seleccione un insumo o producto/plato (puede ser combo)"
                                    />
                                )}
                            />
                        </Grid>
                        <Grid item xs={12} md={2}>
                            <TextField
                                fullWidth
                                size="medium"
                                type="number"
                                label="Cantidad"
                                value={cantidad}
                                onChange={(e) => setCantidad(Number(e.target.value || 0))}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ min: 0.001, step: 0.001, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                        <Grid item xs={12} md={2}>
                            <TextField
                                fullWidth
                                size="medium"
                                label="Unidad"
                                value={unidad}
                                onChange={(e) => setUnidad(e.target.value)}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                        <Grid item xs={12} md={5}>
                            <TextField
                                fullWidth
                                size="medium"
                                label="Comentario"
                                value={comentario}
                                onChange={(e) => setComentario(e.target.value)}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                        </Grid>
                    </Grid>

                    {errorMsg && <Alert severity="warning" sx={{ mb: 2 }}>{errorMsg}</Alert>}

                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                        <Typography variant="subtitle1" fontWeight={700}>Insumos asociados</Typography>
                        <Button
                            variant="contained"
                            onClick={handleGuardarReceta}
                            disabled={upsertRecetaMutation.isPending}
                            sx={{ fontWeight: 700 }}
                        >
                            Agregar insumo
                        </Button>
                    </Box>

                    {detalleQuery.isLoading ? (
                        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
                            <CircularProgress size={24} />
                        </Box>
                    ) : recetaRows.length === 0 ? (
                        <Alert severity="info">Este producto aún no tiene receta cargada.</Alert>
                    ) : (
                        <List dense>
                            {recetaRows.map((item) => (
                                <ListItem
                                    key={item.id}
                                    secondaryAction={
                                        <IconButton
                                            edge="end"
                                            color="error"
                                            onClick={() => handleEliminarReceta(item)}
                                            disabled={deleteRecetaMutation.isPending}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    }
                                >
                                    <ListItemText
                                        primary={<Typography fontWeight={700}>{`${item.inventarioNombre || item.inventarioId} — ${item.cantidad} ${item.unidad || ''}`}</Typography>}
                                        secondary={item.comentario || `Código: ${item.inventarioId}`}
                                    />
                                </ListItem>
                            ))}
                        </List>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setProductoSeleccionado(null)}>Cerrar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
