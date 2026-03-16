'use client';

import React, { useMemo, useState } from 'react';
import {
    Alert,
    Autocomplete,
    Box,
    Button,
    Chip,
    Divider,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    Paper,
    TextField,
    Tooltip,
    Typography,
} from '@mui/material';
import AddBusinessIcon from '@mui/icons-material/AddBusiness';
import Inventory2OutlinedIcon from '@mui/icons-material/Inventory2Outlined';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import VisibilityOutlinedIcon from '@mui/icons-material/VisibilityOutlined';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@zentto/module-admin';
import { useTimezone } from '@zentto/shared-auth';
import { formatDateTime } from '@zentto/shared-api';
import {
    CompraRestauranteAdmin,
    CompraDetalleRowAdmin,
    CompraDetalleInput,
    InventarioLookupItem,
    ProveedorLookupItem,
    useCompraDetalleQuery,
    useCreateInventarioMutation,
    useCreateProveedorMutation,
    useComprasAdminQuery,
    useCreateCompraMutation,
    useDeleteCompraDetalleMutation,
    useInsumosRestauranteLookupQuery,
    useProveedoresLookupQuery,
    useUpsertCompraDetalleMutation,
    useUpsertProductoAdminMutation,
    useUpdateCompraMutation,
} from '@/hooks/useRestauranteAdmin';

type CompraDetalleRow = CompraDetalleInput & { rowId: string };
type ApiRow = Record<string, unknown>;

export default function AdminComprasPage() {
    const { timeZone } = useTimezone();
    const [estado, setEstado] = useState('');
    const [from, setFrom] = useState('');
    const [to, setTo] = useState('');
    const [open, setOpen] = useState(false);
    const [errorMsg, setErrorMsg] = useState<string | null>(null);
    const [openProveedorDialog, setOpenProveedorDialog] = useState(false);
    const [openProductoDialog, setOpenProductoDialog] = useState(false);
    const [openDetalleDialog, setOpenDetalleDialog] = useState(false);
    const [compraDetalleId, setCompraDetalleId] = useState<number | null>(null);
    const [detalleInsumoSearch, setDetalleInsumoSearch] = useState('');
    const [detalleInsumo, setDetalleInsumo] = useState<InventarioLookupItem | null>(null);
    const [detalleCantidad, setDetalleCantidad] = useState<number>(1);
    const [detallePrecio, setDetallePrecio] = useState<number>(0);
    const [detalleIva, setDetalleIva] = useState<number>(16);

    const [proveedorSearch, setProveedorSearch] = useState('');
    const [proveedor, setProveedor] = useState<ProveedorLookupItem | null>(null);
    const [observaciones, setObservaciones] = useState('');

    const [insumoSearch, setInsumoSearch] = useState('');
    const [insumoSeleccionado, setInsumoSeleccionado] = useState<InventarioLookupItem | null>(null);
    const [cantidad, setCantidad] = useState<number>(1);
    const [precioUnit, setPrecioUnit] = useState<number>(0);
    const [iva, setIva] = useState<number>(16);
    const [lineErrors, setLineErrors] = useState({ insumo: false, cantidad: false, precioUnit: false, iva: false });
    const [detalleRows, setDetalleRows] = useState<CompraDetalleRow[]>([]);

    const [proveedorForm, setProveedorForm] = useState({ codigo: '', nombre: '', rif: '', telefono: '', direccion: '' });
    const [productoForm, setProductoForm] = useState({ codigo: '', nombre: '', descripcion: '' });
    const [proveedorError, setProveedorError] = useState<string | null>(null);
    const [productoError, setProductoError] = useState<string | null>(null);

    const { data, isLoading } = useComprasAdminQuery({
        estado: estado || undefined,
        from: from || undefined,
        to: to || undefined,
    });
    const createCompraMutation = useCreateCompraMutation();
    const updateCompraMutation = useUpdateCompraMutation();
    const createProveedorMutation = useCreateProveedorMutation();
    const createInventarioMutation = useCreateInventarioMutation();
    const upsertProductoMutation = useUpsertProductoAdminMutation();
    const upsertCompraDetalleMutation = useUpsertCompraDetalleMutation();
    const deleteCompraDetalleMutation = useDeleteCompraDetalleMutation();
    const proveedoresQuery = useProveedoresLookupQuery(proveedorSearch, open);
    const insumosQuery = useInsumosRestauranteLookupQuery(insumoSearch, open);
    const insumosDetalleQuery = useInsumosRestauranteLookupQuery(detalleInsumoSearch, openDetalleDialog);
    const compraDetalleQuery = useCompraDetalleQuery(compraDetalleId ?? undefined);

    const rows = (data?.rows ?? []) as CompraRestauranteAdmin[];
    const page = 1;
    const pageSize = 100;

    const columns = useMemo<GridColDef[]>(() => [
        {
            field: 'numCompra',
            headerName: 'N° Compra',
            minWidth: 180,
            flex: 1,
            renderCell: (params) => {
                const rowId = Number((params.row as CompraRestauranteAdmin).id ?? 0);
                return (
                    <Button
                        size="small"
                        variant="text"
                        startIcon={<VisibilityOutlinedIcon fontSize="small" />}
                        onClick={() => {
                            if (!rowId) return;
                            setCompraDetalleId(rowId);
                            setOpenDetalleDialog(true);
                        }}
                        sx={{ px: 0.5, minWidth: 'unset', textTransform: 'none', fontWeight: 700 }}
                    >
                        {String(params.value ?? '')}
                    </Button>
                );
            },
        },
        {
            field: 'proveedorId',
            headerName: 'Proveedor',
            minWidth: 240,
            flex: 1.2,
            editable: true,
            valueGetter: (_value, row) => {
                const r = row as ApiRow;
                const proveedorId = String(r.proveedorId ?? r.ProveedorId ?? '').trim();
                const proveedorNombre = String(r.proveedorNombre ?? r.ProveedorNombre ?? '').trim();
                if (proveedorId && proveedorNombre) return `${proveedorId} — ${proveedorNombre}`;
                return proveedorId || proveedorNombre || '';
            },
        },
        {
            field: 'fechaCompra',
            headerName: 'Fecha',
            minWidth: 170,
            flex: 1,
            valueFormatter: (value) => {
                if (!value) return '';
                const d = new Date(String(value));
                return Number.isNaN(d.getTime()) ? String(value) : formatDateTime(String(value), { timeZone });
            },
        },
        {
            field: 'estado',
            headerName: 'Estado',
            minWidth: 150,
            flex: 0.8,
            editable: true,
            type: 'singleSelect',
            valueOptions: ['PENDIENTE', 'APROBADA', 'ANULADA'],
        },
        {
            field: 'total',
            headerName: 'Total',
            minWidth: 140,
            flex: 0.8,
            valueFormatter: (value) => Number(value ?? 0).toFixed(2),
        },
    ], []);

    const detalleCompraColumns = useMemo<GridColDef[]>(() => [
        { field: 'inventarioId', headerName: 'Artículo', minWidth: 180, flex: 1 },
        { field: 'descripcion', headerName: 'Descripción', minWidth: 260, flex: 1.6, editable: true },
        {
            field: 'cantidad',
            headerName: 'Cantidad',
            minWidth: 120,
            flex: 0.7,
            type: 'number',
            editable: true,
            valueFormatter: (value) => Number(value ?? 0).toFixed(3),
        },
        {
            field: 'precioUnit',
            headerName: 'Precio Unit.',
            minWidth: 120,
            flex: 0.8,
            type: 'number',
            editable: true,
            valueFormatter: (value) => Number(value ?? 0).toFixed(2),
        },
        {
            field: 'subtotal',
            headerName: 'Subtotal',
            minWidth: 120,
            flex: 0.8,
            valueFormatter: (value) => Number(value ?? 0).toFixed(2),
        },
        {
            field: 'iva',
            headerName: 'IVA %',
            minWidth: 100,
            flex: 0.6,
            type: 'number',
            editable: true,
            valueFormatter: (value) => Number(value ?? 0).toFixed(2),
        },
    ], []);

    const detalleCompraRows = useMemo(() => {
        const base = (compraDetalleQuery.data?.detalle ?? []) as CompraDetalleRowAdmin[];
        return base.map((row, index) => {
            const rowId = row.id != null
                ? String(row.id)
                : `det-${compraDetalleId ?? 'x'}-${row.compraId ?? ''}-${row.inventarioId ?? ''}-${index}`;

            return {
                ...row,
                __rowKey: rowId,
            };
        });
    }, [compraDetalleId, compraDetalleQuery.data?.detalle]);

    const detalleColumns = useMemo<GridColDef[]>(() => [
        { field: 'inventarioId', headerName: 'Artículo', minWidth: 180, flex: 1 },
        { field: 'descripcion', headerName: 'Descripción', minWidth: 260, flex: 1.5, editable: true },
        { field: 'cantidad', headerName: 'Cantidad', minWidth: 120, flex: 0.7, type: 'number', editable: true },
        { field: 'precioUnit', headerName: 'Precio Unit.', minWidth: 130, flex: 0.8, type: 'number', editable: true },
        { field: 'iva', headerName: 'IVA %', minWidth: 100, flex: 0.6, type: 'number', editable: true },
    ], []);

    const resumenCompra = useMemo(() => {
        const subtotal = detalleRows.reduce((acc, item) => acc + (Number(item.cantidad || 0) * Number(item.precioUnit || 0)), 0);
        const ivaTotal = detalleRows.reduce((acc, item) => {
            const base = Number(item.cantidad || 0) * Number(item.precioUnit || 0);
            const ivaPct = Number(item.iva ?? 0);
            return acc + (base * ivaPct / 100);
        }, 0);
        const total = subtotal + ivaTotal;
        return { subtotal, ivaTotal, total };
    }, [detalleRows]);

    const limpiarDialogo = () => {
        setProveedorSearch('');
        setProveedor(null);
        setObservaciones('');
        setInsumoSearch('');
        setInsumoSeleccionado(null);
        setCantidad(1);
        setPrecioUnit(0);
        setIva(16);
        setLineErrors({ insumo: false, cantidad: false, precioUnit: false, iva: false });
        setDetalleRows([]);
        setErrorMsg(null);
        setProveedorError(null);
        setProductoError(null);
    };

    const openNuevoProveedor = () => {
        const seed = proveedorSearch.trim();
        setProveedorForm({ codigo: seed.toUpperCase().replace(/\s+/g, '').slice(0, 12), nombre: seed, rif: '', telefono: '', direccion: '' });
        setProveedorError(null);
        setOpenProveedorDialog(true);
    };

    const openNuevoProducto = () => {
        const seed = (insumoSearch || '').trim();
        setProductoForm({ codigo: seed.toUpperCase().replace(/\s+/g, '').slice(0, 20), nombre: seed, descripcion: seed });
        setProductoError(null);
        setOpenProductoDialog(true);
    };

    const handleCrearProveedor = async () => {
        const codigo = proveedorForm.codigo.trim();
        const nombre = proveedorForm.nombre.trim();
        if (!codigo || !nombre) {
            setProveedorError('Código y nombre son obligatorios.');
            return;
        }

        try {
            await createProveedorMutation.mutateAsync({
                codigo,
                nombre,
                rif: proveedorForm.rif.trim() || undefined,
                telefono: proveedorForm.telefono.trim() || undefined,
                direccion: proveedorForm.direccion.trim() || undefined,
            });

            const nuevo: ProveedorLookupItem = {
                id: codigo,
                codigo,
                nombre,
                rif: proveedorForm.rif.trim() || undefined,
            };
            setProveedor(nuevo);
            setProveedorSearch(`${codigo} ${nombre}`);
            setOpenProveedorDialog(false);
        } catch (error: unknown) {
            setProveedorError(error instanceof Error ? error.message : 'No se pudo crear el proveedor.');
        }
    };

    const handleCrearProducto = async () => {
        const codigo = productoForm.codigo.trim();
        const nombre = productoForm.nombre.trim();
        if (!codigo || !nombre) {
            setProductoError('Código y nombre son obligatorios.');
            return;
        }

        try {
            try {
                await createInventarioMutation.mutateAsync({
                    codigo,
                    descripcion: productoForm.descripcion.trim() || nombre,
                    unidad: 'UND',
                });
            } catch (inventoryError: unknown) {
                const msg = String(inventoryError instanceof Error ? inventoryError.message : '').toLowerCase();
                const duplicate = msg.includes('duplicate') || msg.includes('ya existe') || msg.includes('primary key');
                if (!duplicate) {
                    throw inventoryError;
                }
            }

            await upsertProductoMutation.mutateAsync({
                codigo,
                nombre,
                descripcion: productoForm.descripcion.trim() || undefined,
                precio: 0,
                iva: 16,
                disponible: true,
                articuloInventarioId: codigo,
                esCompuesto: false,
            });

            const nuevo: InventarioLookupItem = {
                codigo,
                descripcion: nombre,
            };
            setInsumoSeleccionado(nuevo);
            setInsumoSearch(`${codigo} ${nombre}`);
            setOpenProductoDialog(false);
        } catch (error: unknown) {
            setProductoError(error instanceof Error ? error.message : 'No se pudo crear el producto/insumo.');
        }
    };

    const handleAddDetalle = () => {
        const nextErrors = {
            insumo: !insumoSeleccionado?.codigo,
            cantidad: !Number.isFinite(cantidad) || cantidad <= 0,
            precioUnit: !Number.isFinite(precioUnit) || precioUnit < 0,
            iva: !Number.isFinite(iva) || iva < 0,
        };

        setLineErrors(nextErrors);
        if (nextErrors.insumo || nextErrors.cantidad || nextErrors.precioUnit || nextErrors.iva) {
            setErrorMsg('Revise los campos marcados para agregar la línea.');
            return;
        }

        const selected = insumoSeleccionado as InventarioLookupItem;

        setDetalleRows((prev) => [
            ...prev,
            {
                rowId: crypto.randomUUID(),
                inventarioId: selected.codigo,
                descripcion: selected.descripcion || selected.codigo,
                cantidad,
                precioUnit,
                iva,
            },
        ]);

        setInsumoSeleccionado(null);
        setInsumoSearch('');
        setCantidad(1);
        setPrecioUnit(0);
        setIva(16);
        setLineErrors({ insumo: false, cantidad: false, precioUnit: false, iva: false });
        setErrorMsg(null);
    };

    const handleLineaKeyDown = (event: React.KeyboardEvent) => {
        if (event.key === 'Enter') {
            event.preventDefault();
            handleAddDetalle();
        }
    };

    const handleUpdateDetalle = async (row: Record<string, unknown>) => {
        const rowId = String(row.rowId ?? '');
        const updated: CompraDetalleRow = {
            rowId,
            inventarioId: String(row.inventarioId ?? '').trim() || undefined,
            descripcion: String(row.descripcion ?? '').trim(),
            cantidad: Number(row.cantidad ?? 0),
            precioUnit: Number(row.precioUnit ?? 0),
            iva: Number(row.iva ?? 16),
        };

        if (!updated.descripcion || updated.cantidad <= 0 || updated.precioUnit < 0) {
            throw new Error('Revise descripción, cantidad y precio unitario de la línea.');
        }

        setDetalleRows((prev) => prev.map((item) => (item.rowId === rowId ? updated : item)));
        return updated as unknown as Record<string, unknown>;
    };

    const handleDeleteDetalle = async (row: Record<string, unknown>) => {
        const rowId = String(row.rowId ?? '');
        setDetalleRows((prev) => prev.filter((item) => item.rowId !== rowId));
    };

    const handleCreateCompra = async () => {
        if (detalleRows.length === 0) {
            setErrorMsg('Debe agregar al menos un artículo al detalle.');
            return;
        }

        try {
            setErrorMsg(null);
            await createCompraMutation.mutateAsync({
                proveedorId: proveedor?.id || undefined,
                observaciones: observaciones.trim() || undefined,
                detalle: detalleRows.map(({ rowId, ...rest }) => rest),
            });
            setOpen(false);
            limpiarDialogo();
        } catch (error: unknown) {
            setErrorMsg(error instanceof Error ? error.message : 'No se pudo crear la compra.');
        }
    };

    const handleUpdateCompra = async (row: Record<string, unknown>) => {
        const id = Number(row.id ?? 0);
        if (!id) return row;

        await updateCompraMutation.mutateAsync({
            id,
            proveedorId: String(row.proveedorId ?? '').trim() || undefined,
            estado: String(row.estado ?? '').trim() || undefined,
        });

        return row;
    };

    const handleAddDetalleCompra = async () => {
        if (!compraDetalleId) return;
        if (!detalleInsumo?.codigo) {
            setErrorMsg('Seleccione un artículo para agregar al detalle.');
            return;
        }
        if (!Number.isFinite(detalleCantidad) || detalleCantidad <= 0) {
            setErrorMsg('La cantidad debe ser mayor a cero.');
            return;
        }
        if (!Number.isFinite(detallePrecio) || detallePrecio < 0) {
            setErrorMsg('El precio unitario no puede ser negativo.');
            return;
        }

        await upsertCompraDetalleMutation.mutateAsync({
            compraId: compraDetalleId,
            inventarioId: detalleInsumo.codigo,
            descripcion: detalleInsumo.descripcion || detalleInsumo.codigo,
            cantidad: detalleCantidad,
            precioUnit: detallePrecio,
            iva: detalleIva,
        });

        setDetalleInsumo(null);
        setDetalleInsumoSearch('');
        setDetalleCantidad(1);
        setDetallePrecio(0);
        setDetalleIva(16);
        setErrorMsg(null);
    };

    const handleUpdateDetalleCompra = async (row: Record<string, unknown>) => {
        if (!compraDetalleId) return row;
        const detalleId = Number(row.id ?? 0);
        if (!detalleId) return row;

        await upsertCompraDetalleMutation.mutateAsync({
            compraId: compraDetalleId,
            id: detalleId,
            inventarioId: String(row.inventarioId ?? '').trim() || undefined,
            descripcion: String(row.descripcion ?? '').trim(),
            cantidad: Number(row.cantidad ?? 0),
            precioUnit: Number(row.precioUnit ?? 0),
            iva: Number(row.iva ?? 16),
        });

        return row;
    };

    const handleDeleteDetalleCompra = async (row: Record<string, unknown>) => {
        if (!compraDetalleId) return;
        const detalleId = Number(row.id ?? 0);
        if (!detalleId) return;
        await deleteCompraDetalleMutation.mutateAsync({ compraId: compraDetalleId, detalleId });
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h4" fontWeight="bold" sx={{ mb: 2 }}>
                Compras Restaurante
            </Typography>

            <Paper sx={{ p: 2, mb: 2, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 2 }}>
                <TextField
                    label="Estado"
                    placeholder="pendiente, aprobada..."
                    size="medium"
                    value={estado}
                    onChange={(e) => setEstado(e.target.value)}
                    InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                    inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                />
                <TextField
                    label="Desde"
                    type="date"
                    size="medium"
                    value={from}
                    onChange={(e) => setFrom(e.target.value)}
                    InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                    inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                />
                <TextField
                    label="Hasta"
                    type="date"
                    size="medium"
                    value={to}
                    onChange={(e) => setTo(e.target.value)}
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
                onAddRow={() => {
                    limpiarDialogo();
                    setOpen(true);
                }}
                addButtonText="Nueva Compra"
                onUpdateRow={handleUpdateCompra}
                getRowId={(row: ApiRow) => Number(row.id)}
            />

            <Dialog open={open} onClose={() => setOpen(false)} maxWidth="lg" fullWidth>
                <DialogTitle>Nueva Compra Restaurante</DialogTitle>
                <DialogContent dividers>
                    <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>
                            Encabezado de compra
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 2 }}>
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr auto' }, gap: 1, alignItems: 'start' }}>
                            <Autocomplete
                                options={(proveedoresQuery.data?.rows ?? []) as ProveedorLookupItem[]}
                                value={proveedor}
                                inputValue={proveedorSearch}
                                onInputChange={(_e, value) => setProveedorSearch(value)}
                                onChange={(_e, value) => setProveedor(value as ProveedorLookupItem | null)}
                                loading={proveedoresQuery.isLoading}
                                getOptionLabel={(option) => `${option.codigo} — ${option.nombre}`}
                                isOptionEqualToValue={(option, value) => option.id === value.id}
                                renderInput={(params) => (
                                    <TextField
                                        {...params}
                                        label="Proveedor"
                                        placeholder="Buscar por código, nombre o RIF"
                                        helperText="Seleccione proveedor o cree uno nuevo"
                                        InputLabelProps={{ ...params.InputLabelProps, shrink: true, style: { fontWeight: 600 } }}
                                        inputProps={{ ...params.inputProps, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                                    />
                                )}
                            />
                            <Tooltip title="Crear proveedor nuevo">
                                <IconButton
                                    onClick={openNuevoProveedor}
                                    sx={{
                                        mt: 0.5,
                                        width: 44,
                                        height: 44,
                                        border: (theme) => `1px solid ${theme.palette.divider}`,
                                        borderRadius: 1,
                                    }}
                                >
                                    <AddBusinessIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                        </Box>

                        <TextField
                            fullWidth
                            label="Observaciones"
                            value={observaciones}
                            onChange={(e) => setObservaciones(e.target.value)}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        </Box>
                        <Box sx={{ mt: 1.5, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            <Chip
                                size="small"
                                label={proveedor ? `Proveedor: ${proveedor.codigo} — ${proveedor.nombre}` : 'Proveedor no seleccionado'}
                                color={proveedor ? 'success' : 'default'}
                                variant={proveedor ? 'filled' : 'outlined'}
                            />
                        </Box>
                    </Paper>

                    <Divider sx={{ mb: 2 }} />

                    <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>
                            Agregar artículo al detalle
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '2fr 1fr 1fr 1fr auto' }, gap: 1 }}>
                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr auto' }, gap: 1, alignItems: 'start' }}>
                                <Autocomplete
                                    options={(insumosQuery.data?.rows ?? []) as InventarioLookupItem[]}
                                    value={insumoSeleccionado}
                                    inputValue={insumoSearch}
                                    onInputChange={(_e, value) => setInsumoSearch(value)}
                                    onChange={(_e, value) => {
                                        setInsumoSeleccionado(value as InventarioLookupItem | null);
                                        setLineErrors((prev) => ({ ...prev, insumo: false }));
                                    }}
                                    loading={insumosQuery.isLoading}
                                    getOptionLabel={(option) => `${option.codigo} — ${option.descripcion || ''}`}
                                    isOptionEqualToValue={(option, value) => option.codigo === value.codigo}
                                    renderInput={(params) => (
                                        <TextField
                                            {...params}
                                            label="Artículo / Insumo"
                                            placeholder="Buscar por código o descripción"
                                            error={lineErrors.insumo}
                                            helperText={lineErrors.insumo ? 'Debe seleccionar un artículo/insumo.' : 'Seleccione artículo/insumo o créelo rápido'}
                                            InputLabelProps={{ ...params.InputLabelProps, shrink: true, style: { fontWeight: 600 } }}
                                            inputProps={{ ...params.inputProps, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                                        />
                                    )}
                                />
                                <Tooltip title="Crear artículo/insumo nuevo">
                                    <IconButton
                                        onClick={openNuevoProducto}
                                        sx={{
                                            mt: 0.5,
                                            width: 44,
                                            height: 44,
                                            border: (theme) => `1px solid ${theme.palette.divider}`,
                                            borderRadius: 1,
                                        }}
                                    >
                                        <Inventory2OutlinedIcon fontSize="small" />
                                    </IconButton>
                                </Tooltip>
                            </Box>
                            <TextField
                                label="Cantidad"
                                type="number"
                                value={cantidad}
                                onChange={(e) => {
                                    setCantidad(Number(e.target.value || 0));
                                    setLineErrors((prev) => ({ ...prev, cantidad: false }));
                                }}
                                onKeyDown={handleLineaKeyDown}
                                error={lineErrors.cantidad}
                                helperText={lineErrors.cantidad ? 'Cantidad > 0 requerida.' : ' '}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ min: 0.001, step: 0.001, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                            <TextField
                                label="Precio Unit."
                                type="number"
                                value={precioUnit}
                                onChange={(e) => {
                                    setPrecioUnit(Number(e.target.value || 0));
                                    setLineErrors((prev) => ({ ...prev, precioUnit: false }));
                                }}
                                onKeyDown={handleLineaKeyDown}
                                error={lineErrors.precioUnit}
                                helperText={lineErrors.precioUnit ? 'Precio unitario inválido.' : ' '}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ min: 0, step: 0.01, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                            <TextField
                                label="IVA %"
                                type="number"
                                value={iva}
                                onChange={(e) => {
                                    setIva(Number(e.target.value || 0));
                                    setLineErrors((prev) => ({ ...prev, iva: false }));
                                }}
                                onKeyDown={handleLineaKeyDown}
                                error={lineErrors.iva}
                                helperText={lineErrors.iva ? 'IVA no puede ser negativo.' : ' '}
                                InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                                inputProps={{ min: 0, step: 0.01, style: { fontWeight: 500, fontSize: '0.98rem' } }}
                            />
                            <Tooltip title="Agregar línea al detalle">
                                <IconButton
                                    onClick={handleAddDetalle}
                                    color="primary"
                                    sx={{
                                        mt: 0.5,
                                        width: 44,
                                        height: 44,
                                        borderRadius: 1,
                                        border: (theme) => `1px solid ${theme.palette.primary.main}`,
                                    }}
                                >
                                    <AddCircleOutlineIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                        </Box>

                        <Box sx={{ mt: 1.5, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            <Chip
                                size="small"
                                label={insumoSeleccionado ? `Artículo: ${insumoSeleccionado.codigo}` : 'Artículo no seleccionado'}
                                color={insumoSeleccionado ? 'success' : 'default'}
                                variant={insumoSeleccionado ? 'filled' : 'outlined'}
                            />
                            <Chip size="small" label={`Líneas: ${detalleRows.length}`} variant="outlined" />
                        </Box>
                    </Paper>

                    <EditableDataGrid
                        rows={detalleRows}
                        columns={detalleColumns}
                        loading={false}
                        page={1}
                        pageSize={100}
                        rowCount={detalleRows.length}
                        onPageChange={() => { }}
                        onUpdateRow={handleUpdateDetalle}
                        onDeleteRow={handleDeleteDetalle}
                        getRowId={(row: ApiRow) => String(row.rowId)}
                    />

                    <Paper
                        variant="outlined"
                        sx={{
                            mt: 2,
                            p: 2,
                            position: 'sticky',
                            bottom: 0,
                            zIndex: 3,
                            bgcolor: 'background.paper',
                            borderColor: 'divider',
                        }}
                    >
                        <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>
                            Resumen de compra
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr 1fr' }, gap: 1 }}>
                            <Typography>Subtotal: <strong>{resumenCompra.subtotal.toFixed(2)}</strong></Typography>
                            <Typography>IVA: <strong>{resumenCompra.ivaTotal.toFixed(2)}</strong></Typography>
                            <Typography>Total: <strong>{resumenCompra.total.toFixed(2)}</strong></Typography>
                        </Box>
                    </Paper>

                    {errorMsg && <Alert severity="warning" sx={{ mt: 2 }}>{errorMsg}</Alert>}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpen(false)}>Cancelar</Button>
                    <Button
                        variant="contained"
                        onClick={handleCreateCompra}
                        disabled={createCompraMutation.isPending}
                    >
                        Guardar Compra
                    </Button>
                </DialogActions>
            </Dialog>

            <Dialog open={openDetalleDialog} onClose={() => setOpenDetalleDialog(false)} maxWidth="lg" fullWidth>
                <DialogTitle>Detalle de Compra</DialogTitle>
                <DialogContent dividers>
                    {compraDetalleQuery.isLoading ? (
                        <Typography>Cargando detalle...</Typography>
                    ) : !compraDetalleQuery.data?.compra ? (
                        <Alert severity="info">No se encontró la compra seleccionada.</Alert>
                    ) : (
                        <>
                            {(() => {
                                const compra = compraDetalleQuery.data?.compra as ApiRow;
                                return (
                            <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
                                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(4, 1fr)' }, gap: 1 }}>
                                    <Typography><strong>N° Compra:</strong> {String(compra.numCompra ?? '')}</Typography>
                                    <Typography>
                                        <strong>Proveedor:</strong>{' '}
                                        {String(compra.proveedorId ?? '')}
                                        {String(compra.proveedorNombre ?? '').trim()
                                            ? ` — ${String(compra.proveedorNombre)}`
                                            : ''}
                                    </Typography>
                                    <Typography><strong>Estado:</strong> {String(compra.estado ?? '')}</Typography>
                                    <Typography><strong>Fecha:</strong> {String(compra.fechaCompra ?? '')}</Typography>
                                </Box>
                                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(3, 1fr)' }, gap: 1, mt: 1.5 }}>
                                    <Typography><strong>Subtotal:</strong> {Number(compra.subtotal ?? 0).toFixed(2)}</Typography>
                                    <Typography><strong>IVA:</strong> {Number(compra.iva ?? 0).toFixed(2)}</Typography>
                                    <Typography><strong>Total:</strong> {Number(compra.total ?? 0).toFixed(2)}</Typography>
                                </Box>
                            </Paper>
                                );
                            })()}

                            <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
                                <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>
                                    Agregar línea al detalle
                                </Typography>
                                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '2fr 1fr 1fr 1fr auto' }, gap: 1 }}>
                                    <Autocomplete
                                        options={(insumosDetalleQuery.data?.rows ?? []) as InventarioLookupItem[]}
                                        value={detalleInsumo}
                                        inputValue={detalleInsumoSearch}
                                        onInputChange={(_e, value) => setDetalleInsumoSearch(value)}
                                        onChange={(_e, value) => setDetalleInsumo(value as InventarioLookupItem | null)}
                                        loading={insumosDetalleQuery.isLoading}
                                        getOptionLabel={(option) => `${option.codigo} — ${option.descripcion || ''}`}
                                        isOptionEqualToValue={(option, value) => option.codigo === value.codigo}
                                        renderInput={(params) => (
                                            <TextField
                                                {...params}
                                                label="Artículo / Insumo"
                                                placeholder="Buscar por código o descripción"
                                                InputLabelProps={{ ...params.InputLabelProps, shrink: true }}
                                            />
                                        )}
                                    />
                                    <TextField
                                        label="Cantidad"
                                        type="number"
                                        value={detalleCantidad}
                                        onChange={(e) => setDetalleCantidad(Number(e.target.value || 0))}
                                        InputLabelProps={{ shrink: true }}
                                        inputProps={{ min: 0.001, step: 0.001 }}
                                    />
                                    <TextField
                                        label="Precio Unit."
                                        type="number"
                                        value={detallePrecio}
                                        onChange={(e) => setDetallePrecio(Number(e.target.value || 0))}
                                        InputLabelProps={{ shrink: true }}
                                        inputProps={{ min: 0, step: 0.01 }}
                                    />
                                    <TextField
                                        label="IVA %"
                                        type="number"
                                        value={detalleIva}
                                        onChange={(e) => setDetalleIva(Number(e.target.value || 0))}
                                        InputLabelProps={{ shrink: true }}
                                        inputProps={{ min: 0, step: 0.01 }}
                                    />
                                    <Button variant="contained" onClick={handleAddDetalleCompra} disabled={upsertCompraDetalleMutation.isPending}>
                                        Agregar
                                    </Button>
                                </Box>
                            </Paper>

                            <EditableDataGrid
                                rows={detalleCompraRows}
                                columns={detalleCompraColumns}
                                loading={compraDetalleQuery.isLoading || upsertCompraDetalleMutation.isPending || deleteCompraDetalleMutation.isPending}
                                page={1}
                                pageSize={100}
                                rowCount={detalleCompraRows.length}
                                onPageChange={() => { }}
                                onUpdateRow={handleUpdateDetalleCompra}
                                onDeleteRow={handleDeleteDetalleCompra}
                                getRowId={(row: ApiRow) => String(row.__rowKey ?? row.id ?? crypto.randomUUID())}
                            />
                        </>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenDetalleDialog(false)}>Cerrar</Button>
                </DialogActions>
            </Dialog>

            <Dialog open={openProveedorDialog} onClose={() => setOpenProveedorDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Nuevo Proveedor</DialogTitle>
                <DialogContent dividers>
                    <Box sx={{ display: 'grid', gap: 2, mt: 1 }}>
                        <TextField
                            label="Código"
                            value={proveedorForm.codigo}
                            onChange={(e) => setProveedorForm((prev) => ({ ...prev, codigo: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="Nombre"
                            value={proveedorForm.nombre}
                            onChange={(e) => setProveedorForm((prev) => ({ ...prev, nombre: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="RIF"
                            value={proveedorForm.rif}
                            onChange={(e) => setProveedorForm((prev) => ({ ...prev, rif: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="Teléfono"
                            value={proveedorForm.telefono}
                            onChange={(e) => setProveedorForm((prev) => ({ ...prev, telefono: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="Dirección"
                            value={proveedorForm.direccion}
                            onChange={(e) => setProveedorForm((prev) => ({ ...prev, direccion: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                    </Box>
                    {proveedorError && <Alert severity="warning" sx={{ mt: 2 }}>{proveedorError}</Alert>}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenProveedorDialog(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleCrearProveedor} disabled={createProveedorMutation.isPending}>Crear</Button>
                </DialogActions>
            </Dialog>

            <Dialog open={openProductoDialog} onClose={() => setOpenProductoDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Nuevo Producto / Insumo</DialogTitle>
                <DialogContent dividers>
                    <Box sx={{ display: 'grid', gap: 2, mt: 1 }}>
                        <TextField
                            label="Código"
                            value={productoForm.codigo}
                            onChange={(e) => setProductoForm((prev) => ({ ...prev, codigo: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="Nombre"
                            value={productoForm.nombre}
                            onChange={(e) => setProductoForm((prev) => ({ ...prev, nombre: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                        <TextField
                            label="Descripción"
                            value={productoForm.descripcion}
                            onChange={(e) => setProductoForm((prev) => ({ ...prev, descripcion: e.target.value }))}
                            InputLabelProps={{ shrink: true, style: { fontWeight: 600 } }}
                            inputProps={{ style: { fontWeight: 500, fontSize: '0.98rem' } }}
                        />
                    </Box>
                    {productoError && <Alert severity="warning" sx={{ mt: 2 }}>{productoError}</Alert>}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenProductoDialog(false)}>Cancelar</Button>
                    <Button
                        variant="contained"
                        onClick={handleCrearProducto}
                        disabled={upsertProductoMutation.isPending || createInventarioMutation.isPending}
                    >
                        Crear
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
