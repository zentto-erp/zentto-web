'use client';

import React, { useState } from 'react';
import {
    Box,
    Paper,
    Typography,
    Grid,
    Button,
    IconButton,
    List,
    ListItem,
    ListItemText,
    ListItemSecondaryAction,
    Divider,
    Chip,
    Tabs,
    Tab,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    FormControl,
    InputLabel,
    Select,
    MenuItem,
    TextField,
    Accordion,
    AccordionSummary,
    AccordionDetails,
    InputAdornment,
    useTheme,
    useMediaQuery,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import RemoveIcon from '@mui/icons-material/Remove';
import DeleteIcon from '@mui/icons-material/Delete';
import KitchenIcon from '@mui/icons-material/Kitchen';
import ReceiptIcon from '@mui/icons-material/Receipt';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import SearchIcon from '@mui/icons-material/Search';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ChevronLeftIcon from '@mui/icons-material/ChevronLeft';
import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { Mesa, ProductoMenu, ItemPedido, ComponenteProducto } from '@/hooks/useRestaurante';
import { usePosStore } from '@datqbox/shared-api';

interface PanelPedidoProps {
    mesa: Mesa;
    productos: ProductoMenu[];
    onAgregarItem: (item: Omit<ItemPedido, 'id'>) => void;
    onQuitarItem?: (mesaId: string, itemId: string) => void;
    onEditarItem?: (mesaId: string, itemId: string, cambios: Partial<ItemPedido>) => void;
    onEnviarComanda: () => void;
    onImprimirCuenta?: () => void;
    onCerrarMesa?: () => void;
    onCerrar: () => void;
    syncing?: boolean;
}

export function PanelPedido({
    mesa,
    productos,
    onAgregarItem,
    onQuitarItem,
    onEditarItem,
    onEnviarComanda,
    onImprimirCuenta,
    onCerrarMesa,
    onCerrar,
    syncing = false,
}: PanelPedidoProps) {
    const theme = useTheme();
    const isMobileLandscape = useMediaQuery('(max-height: 500px) and (orientation: landscape)');
    const isMobilePortrait = useMediaQuery(theme.breakpoints.down('md'));
    const isMobileLayout = isMobilePortrait || isMobileLandscape;
    const itemsPerPage = isMobileLayout ? 3 : 6;

    const [categoriaActiva, setCategoriaActiva] = useState<string>('todos');
    const [productoSeleccionado, setProductoSeleccionado] = useState<ProductoMenu | null>(null);
    const [componentesSeleccionados, setComponentesSeleccionados] = useState<Record<string, string>>({});
    const [comentario, setComentario] = useState('');
    const [cantidad, setCantidad] = useState(1);
    const [showMobileMenu, setShowMobileMenu] = useState(false);
    const [busqueda, setBusqueda] = useState('');
    const categorias = ['todos', ...Array.from(new Set(productos.map(p => p.categoria)))];

    const [expandedAccordion, setExpandedAccordion] = useState<string | false>(() => {
        const cat = categorias.find(c => c !== 'todos');
        return cat || false;
    });

    const [categoriaPage, setCategoriaPage] = useState(0);

    const productosFiltradosBusqueda = productos.filter(p =>
        p.nombre.toLowerCase().includes(busqueda.toLowerCase())
    );

    const sugerencias = productos.filter(p => p.esSugerenciaDelDia);

    const handleAgregarProducto = (producto: ProductoMenu) => {
        if (producto.esCompuesto && producto.componentes) {
            setProductoSeleccionado(producto);
            setComponentesSeleccionados({});
            setComentario('');
            setCantidad(1);
        } else {
            onAgregarItem({
                productoId: producto.id,
                nombre: producto.nombre,
                cantidad: 1,
                precioUnitario: producto.precio,
                subtotal: producto.precio,
                estado: 'pendiente',
                esCompuesto: false,
                enviadoACocina: false,
                iva: producto.iva || 16,
                montoIva: Math.round((producto.precio * ((producto.iva || 16) / 100)) * 100) / 100,
            });
            setShowMobileMenu(false);
        }
    };

    const handleConfirmarProductoCompuesto = () => {
        if (!productoSeleccionado) return;

        const componentesTexto = Object.entries(componentesSeleccionados)
            .map(([key, value]) => value)
            .filter(Boolean)
            .join(', ');

        onAgregarItem({
            productoId: productoSeleccionado.id,
            nombre: `${productoSeleccionado.nombre} (${componentesTexto})`,
            cantidad,
            precioUnitario: productoSeleccionado.precio,
            subtotal: productoSeleccionado.precio * cantidad,
            estado: 'pendiente',
            esCompuesto: true,
            componentes: Object.entries(componentesSeleccionados).map(([id, opcion]) => ({
                id,
                nombre: opcion,
                cantidad: 1,
                opcionSeleccionada: opcion,
            })),
            comentarios: comentario,
            enviadoACocina: false,
            iva: productoSeleccionado.iva || 16,
            montoIva: Math.round(((productoSeleccionado.precio * cantidad) * ((productoSeleccionado.iva || 16) / 100)) * 100) / 100,
        });

        setProductoSeleccionado(null);
        setComponentesSeleccionados({});
        setComentario('');
        setCantidad(1);
        setShowMobileMenu(false);
    };

    const pedido = mesa.pedidoActual;
    const itemsPendientes = pedido?.items.filter(i => !i.enviadoACocina) || [];
    const itemsEnviados = pedido?.items.filter(i => i.enviadoACocina) || [];
    const subtotal = pedido?.subtotal || 0;
    const impuestos = pedido?.impuestos || 0;
    const servicio = pedido?.servicio || 0;
    const total = pedido?.total || 0;

    const { localizacion } = usePosStore();
    const symP = localizacion.monedaPrincipal || 'Bs';
    const symR = localizacion.monedaReferencia || '$';
    const tc = localizacion.tasaCambio || 1;
    const safeTc = tc > 0 ? tc : 1;
    const toPrincipal = (value: number) => value * safeTc;

    return (
        <React.Fragment>
            <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: isMobileLayout ? 'column' : 'row', gap: isMobileLayout ? 0 : 2, pb: isMobileLayout && showMobileMenu ? 6 : (isMobileLayout ? 8 : 0), minHeight: 0, overflow: 'hidden' }}>
                {/* Panel izquierdo - Items del pedido */}
                <Paper sx={{
                    width: isMobileLayout ? '100%' : 350,
                    flexShrink: 0,
                    p: isMobileLayout ? 1.5 : 2,
                    display: isMobileLayout ? (showMobileMenu ? 'none' : 'flex') : 'flex',
                    flexDirection: 'column',
                    minHeight: 0,
                    minWidth: 0,
                    borderRadius: isMobileLayout ? 0 : 1,
                    boxShadow: isMobileLayout ? 'none' : undefined,
                    height: '100%'
                }}>
                    <Typography variant="h6" gutterBottom>
                        {mesa.nombre} - Pedido
                    </Typography>

                    {mesa.cliente && (
                        <Chip
                            label={mesa.cliente.nombre}
                            size="small"
                            sx={{ mb: 2, alignSelf: 'flex-start' }}
                        />
                    )}

                    <Box sx={{ flexGrow: 1, overflow: 'auto' }}>
                        {/* Items pendientes */}
                        {itemsPendientes.length > 0 && (
                            <>
                                <Typography variant="caption" color="warning.main" fontWeight="bold">
                                    ⏳ Pendientes de enviar
                                </Typography>
                                <List dense>
                                    {itemsPendientes.map((item) => (
                                        <ListItem key={item.id} sx={{ bgcolor: '#FFF8E1', borderRadius: 1, mb: 0.5 }}>
                                            <ListItemText
                                                primary={item.nombre}
                                                secondary={`${item.cantidad}x ${symP} ${item.precioUnitario.toFixed(2)}${safeTc !== 1 ? ` (Ref ${symR} ${(item.precioUnitario / safeTc).toFixed(2)})` : ''}`}
                                            />
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                {onEditarItem && (
                                                    <>
                                                        <IconButton
                                                            size="small"
                                                            onClick={() => onEditarItem(mesa.id, item.id, { cantidad: Math.max(1, item.cantidad - 1) })}
                                                            disabled={item.cantidad <= 1}
                                                        >
                                                            <RemoveIcon fontSize="small" />
                                                        </IconButton>
                                                        <Typography variant="body2" fontWeight="bold" sx={{ minWidth: 20, textAlign: 'center' }}>
                                                            {item.cantidad}
                                                        </Typography>
                                                        <IconButton
                                                            size="small"
                                                            onClick={() => onEditarItem(mesa.id, item.id, { cantidad: item.cantidad + 1 })}
                                                        >
                                                            <AddIcon fontSize="small" />
                                                        </IconButton>
                                                    </>
                                                )}
                                                <Typography variant="body2" fontWeight="bold" sx={{ mx: 0.5 }}>
                                                    {symP} {item.subtotal.toFixed(2)}
                                                </Typography>
                                                {onQuitarItem && (
                                                    <IconButton
                                                        size="small"
                                                        color="error"
                                                        onClick={() => onQuitarItem(mesa.id, item.id)}
                                                    >
                                                        <DeleteIcon fontSize="small" />
                                                    </IconButton>
                                                )}
                                            </Box>
                                        </ListItem>
                                    ))}
                                </List>
                                <Divider sx={{ my: 1 }} />
                            </>
                        )}

                        {/* Items enviados */}
                        {itemsEnviados.length > 0 && (
                            <>
                                <Typography variant="caption" color="success.main" fontWeight="bold">
                                    Enviados a cocina
                                </Typography>
                                <List dense>
                                    {itemsEnviados.map((item) => (
                                        <ListItem key={item.id}>
                                            <ListItemText
                                                primary={item.nombre}
                                                secondary={`${item.cantidad}x - ${item.estado}`}
                                                sx={{ opacity: 0.7 }}
                                            />
                                            <Typography variant="body2">
                                                {symP} {item.subtotal.toFixed(2)}
                                            </Typography>
                                        </ListItem>
                                    ))}
                                </List>
                            </>
                        )}
                    </Box>

                    <Divider sx={{ my: 2 }} />

                    {/* Totales */}
                    <Box sx={{ mb: 2 }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                            <Typography variant="body1">Subtotal Base:</Typography>
                            <Typography variant="body1">{symP} {subtotal.toFixed(2)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                            <Typography variant="body1">IVA:</Typography>
                            <Typography variant="body1">{symP} {impuestos.toFixed(2)}</Typography>
                        </Box>
                        {servicio > 0 && (
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                <Typography variant="body1">Servicio (10%):</Typography>
                                <Typography variant="body1">{symP} {servicio.toFixed(2)}</Typography>
                            </Box>
                        )}
                        <Divider sx={{ my: 1 }} />
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Typography variant="h6">Total:</Typography>
                            <Box sx={{ textAlign: 'right' }}>
                                <Typography variant="h5" fontWeight="bold" color="primary">
                                    {symP} {total.toFixed(2)}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    Ref {symR} {(total / tc).toFixed(2)} (Tasa: {tc.toFixed(2)})
                                </Typography>
                            </Box>
                        </Box>
                    </Box>

                    {/* Botones de acción */}
                    <Box sx={{ display: 'flex', gap: 1, flexDirection: 'column' }}>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Button
                                variant="contained"
                                startIcon={<KitchenIcon />}
                                onClick={onEnviarComanda}
                                disabled={itemsPendientes.length === 0}
                                sx={{ height: 48, flex: 1 }}
                            >
                                Enviar ({itemsPendientes.length})
                            </Button>
                            <Button
                                variant="outlined"
                                startIcon={<ReceiptIcon />}
                                disabled={itemsEnviados.length === 0}
                                onClick={onImprimirCuenta}
                                sx={{ height: 48, flex: 1 }}
                            >
                                Cuenta
                            </Button>
                        </Box>
                        {onCerrarMesa && mesa.estado === 'cuenta' && (
                            <Button
                                variant="contained"
                                color="error"
                                fullWidth
                                onClick={onCerrarMesa}
                                disabled={syncing}
                                sx={{ height: 48 }}
                            >
                                🔒 Cerrar Mesa
                            </Button>
                        )}
                    </Box>
                </Paper>

                {/* Panel derecho - Menú táctil */}
                <Paper sx={{
                    flexGrow: 1,
                    p: isMobileLayout ? 0 : 2,
                    display: isMobileLayout ? (showMobileMenu ? 'flex' : 'none') : 'flex',
                    flexDirection: 'column',
                    minHeight: 0,
                    minWidth: 0,
                    bgcolor: isMobileLayout ? 'transparent' : 'background.paper',
                    border: 'none',
                    boxShadow: 'none'
                }}>
                    {/* Sugerencias del día */}
                    {sugerencias.length > 0 && (
                        <Box sx={{ mb: 2 }}>
                            <Typography variant="subtitle2" color="primary" gutterBottom>
                                <LocalOfferIcon sx={{ fontSize: 16, mr: 0.5 }} />
                                Sugerencias del día
                            </Typography>
                            <Box sx={{ display: 'flex', gap: 1, flexWrap: 'nowrap', overflowX: 'auto', pb: 1, '::-webkit-scrollbar': { height: 6 }, '::-webkit-scrollbar-thumb': { bgcolor: 'action.hover', borderRadius: 1 } }}>
                                {sugerencias.map(p => (
                                    <Chip
                                        key={p.id}
                                        label={`${p.nombre} - ${symP} ${toPrincipal(p.precio).toFixed(2)}${safeTc !== 1 ? ` (Ref ${symR} ${p.precio.toFixed(2)})` : ''}`}
                                        onClick={() => handleAgregarProducto(p)}
                                        color="primary"
                                        variant="outlined"
                                        sx={{ cursor: 'pointer', flexShrink: 0 }}
                                    />
                                ))}
                            </Box>
                        </Box>
                    )}

                    <Divider sx={{ my: 1 }} />

                    {/* VISTA MINIMALISTA (Estilo Odoo POS) */}
                    <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1, minHeight: 0 }}>

                        {/* Buscador Integrado */}
                        <TextField
                            fullWidth
                            size="small"
                            placeholder="Buscar producto..."
                            value={busqueda}
                            onChange={(e) => setBusqueda(e.target.value)}
                            InputProps={{
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <SearchIcon color="action" />
                                    </InputAdornment>
                                ),
                                sx: { borderRadius: 2, bgcolor: 'background.default', mb: 2 }
                            }}
                        />

                        {/* Paginación de Categorías estilo Tablero Clásico (Odoo) */}
                        <Box sx={{ display: 'flex', alignItems: 'stretch', mb: 2, height: 55 }}>

                            {/* Botón Izquierda */}
                            <Button
                                variant="outlined"
                                disabled={categoriaPage === 0}
                                onClick={() => setCategoriaPage(Math.max(0, categoriaPage - 1))}
                                sx={{ minWidth: 40, width: 40, p: 0, borderRadius: 0, border: '1px solid #e0e0e0', bgcolor: '#ffffff' }}
                            >
                                <ChevronLeftIcon />
                            </Button>

                            {/* Botones de Categorías Visibles (Dinámico) */}
                            <Box sx={{ flexGrow: 1, display: 'flex', overflow: 'hidden' }}>
                                {categorias.slice(categoriaPage * itemsPerPage, (categoriaPage + 1) * itemsPerPage).map((cat, idx) => {
                                    const isActive = categoriaActiva === cat;
                                    const pastelColors = ['#F5F5F5', '#CEEAD6', '#FCE8E6', '#FEF7E0', '#E4F7FB', '#F3E5F5']; // Tonos muy suaves
                                    const colorIndex = categorias.indexOf(cat) % pastelColors.length;
                                    const bgColor = pastelColors[colorIndex];

                                    return (
                                        <Button
                                            key={cat}
                                            disableElevation
                                            variant="contained"
                                            onClick={() => setCategoriaActiva(cat)}
                                            sx={{
                                                flex: 1,
                                                height: '100%',
                                                borderRadius: 0,
                                                fontWeight: isActive ? 'bold' : 'normal',
                                                color: 'text.primary',
                                                bgcolor: isActive ? '#ffffff' : bgColor,
                                                borderTop: '1px solid #e0e0e0',
                                                borderBottom: '1px solid #e0e0e0',
                                                borderRight: '1px solid #e0e0e0',
                                                borderLeft: 0,
                                                textTransform: 'capitalize',
                                                boxShadow: 'none',
                                                px: 1,
                                                '&:hover': { bgcolor: isActive ? '#ffffff' : '#e0e0e0' },
                                                // truncate text si es muy largo
                                                whiteSpace: 'nowrap',
                                                overflow: 'hidden',
                                                textOverflow: 'ellipsis',
                                                display: 'block'
                                            }}
                                        >
                                            {cat}
                                        </Button>
                                    );
                                })}
                            </Box>

                            {/* Botón Derecha */}
                            <Button
                                variant="outlined"
                                disabled={(categoriaPage + 1) * itemsPerPage >= categorias.length}
                                onClick={() => setCategoriaPage(categoriaPage + 1)}
                                sx={{ minWidth: 40, width: 40, p: 0, borderRadius: 0, border: '1px solid #e0e0e0', borderLeft: 0, bgcolor: '#ffffff' }}
                            >
                                <ChevronRightIcon />
                            </Button>

                        </Box>

                        {/* Grid de productos cuadrado y limpio */}
                        <Box sx={{ flexGrow: 1, overflow: 'auto', p: 0.5, pb: 2 }}>
                            <Grid container spacing={1.5}>
                                {productosFiltradosBusqueda.filter(p => categoriaActiva === 'todos' || p.categoria === categoriaActiva).map((producto) => (
                                    <Grid item xs={4} sm={3} md={3} lg={2} key={producto.id}>
                                        <Button
                                            onClick={() => handleAgregarProducto(producto)}
                                            sx={{
                                                width: '100%',
                                                p: 0,
                                                display: 'flex',
                                                flexDirection: 'column',
                                                alignItems: 'stretch',
                                                border: '1px solid',
                                                borderColor: '#e0e0e0',
                                                bgcolor: '#ffffff',
                                                borderRadius: 1, // bordes ligeros
                                                overflow: 'hidden',
                                                textTransform: 'none',
                                                '&:hover': { bgcolor: '#f9f9f9', borderColor: '#bdbdbd' },
                                            }}
                                        >
                                            {/* "Imagen" del Producto */}
                                            <Box sx={{
                                                height: { xs: 80, md: 110 },
                                                bgcolor: '#f5f5f5',
                                                display: 'flex',
                                                alignItems: 'center',
                                                justifyContent: 'center',
                                                borderBottom: '1px solid #f0f0f0'
                                            }}>
                                                <LocalOfferIcon sx={{ color: '#e0e0e0', fontSize: 40 }} />
                                            </Box>

                                            {/* Textos y Precios */}
                                            <Box sx={{ p: 1, display: 'flex', flexDirection: 'column', alignItems: 'flex-start', textAlign: 'left', minHeight: '60px', width: '100%' }}>
                                                <Typography
                                                    variant="caption"
                                                    sx={{
                                                        fontWeight: '500',
                                                        lineHeight: 1.1,
                                                        display: '-webkit-box',
                                                        WebkitLineClamp: 2,
                                                        WebkitBoxOrient: 'vertical',
                                                        overflow: 'hidden',
                                                        mb: 0.5,
                                                        color: '#333'
                                                    }}
                                                >
                                                    {producto.nombre}
                                                </Typography>

                                                {/* Fila Inferior con Precio Alineado Izquierda y Tiempo Derecha */}
                                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', width: '100%', mt: 'auto' }}>
                                                    <Box>
                                                        <Typography variant="body2" sx={{ fontWeight: 'bold', color: '#555', lineHeight: 1.1 }}>
                                                            {symP} {toPrincipal(producto.precio).toFixed(2)}
                                                        </Typography>
                                                        {safeTc !== 1 && (
                                                            <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1.1 }}>
                                                                Ref {symR} {producto.precio.toFixed(2)}
                                                            </Typography>
                                                        )}
                                                    </Box>
                                                    {producto.tiempoPreparacion > 0 && (
                                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: 'text.secondary' }}>
                                                            <KitchenIcon sx={{ fontSize: 12 }} />
                                                            <Typography variant="caption" sx={{ fontSize: '0.65rem' }}>
                                                                {producto.tiempoPreparacion}m
                                                            </Typography>
                                                        </Box>
                                                    )}
                                                </Box>
                                            </Box>
                                        </Button>
                                    </Grid>
                                ))}
                            </Grid>
                        </Box>
                    </Box>
                </Paper>

                {/* Dialog para producto compuesto */}
                <Dialog
                    open={!!productoSeleccionado}
                    onClose={() => setProductoSeleccionado(null)}
                    maxWidth="sm"
                    fullWidth
                >
                    <DialogTitle>
                        {productoSeleccionado?.nombre}
                        <Typography variant="body2" color="text.secondary">
                            Personaliza tu pedido
                        </Typography>
                    </DialogTitle>
                    <DialogContent>
                        {productoSeleccionado?.componentes?.map((componente) => (
                            <FormControl key={componente.id} fullWidth sx={{ mb: 2 }}>
                                <InputLabel>
                                    {componente.nombre}
                                    {componente.obligatorio && ' *'}
                                </InputLabel>
                                <Select
                                    value={componentesSeleccionados[componente.id] || ''}
                                    onChange={(e) => setComponentesSeleccionados({
                                        ...componentesSeleccionados,
                                        [componente.id]: e.target.value
                                    })}
                                    label={`${componente.nombre}${componente.obligatorio ? ' *' : ''}`}
                                >
                                    {componente.opciones.map((opcion) => (
                                        <MenuItem key={opcion} value={opcion}>
                                            {opcion}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                        ))}

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Typography>Cantidad:</Typography>
                            <IconButton onClick={() => setCantidad(Math.max(1, cantidad - 1))}>
                                <RemoveIcon />
                            </IconButton>
                            <Typography fontWeight="bold">{cantidad}</Typography>
                            <IconButton onClick={() => setCantidad(cantidad + 1)}>
                                <AddIcon />
                            </IconButton>
                        </Box>

                        <TextField
                            fullWidth
                            label="Comentarios adicionales"
                            multiline
                            rows={2}
                            value={comentario}
                            onChange={(e) => setComentario(e.target.value)}
                        />
                    </DialogContent>
                    <DialogActions>
                        <Button onClick={() => setProductoSeleccionado(null)}>
                            Cancelar
                        </Button>
                        <Button
                            variant="contained"
                            onClick={handleConfirmarProductoCompuesto}
                            disabled={productoSeleccionado?.componentes?.some(
                                c => c.obligatorio && !componentesSeleccionados[c.id]
                            )}
                        >
                            Agregar - {symP} {(toPrincipal(productoSeleccionado?.precio || 0) * cantidad).toFixed(2)}
                        </Button>
                    </DialogActions>
                </Dialog>
            </Box>

            {/* Odoo Style Mobile Floating Bottom Control Bar */}
            {isMobileLayout && (
                <Paper elevation={8} sx={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 1200, display: 'flex', height: 50, borderRadius: 0 }}>
                    {!showMobileMenu ? (
                        <Button
                            variant="contained"
                            color="secondary"
                            sx={{ flex: 1, borderRadius: 0, fontSize: '1rem', fontWeight: 'bold', textTransform: 'none' }}
                            onClick={() => setShowMobileMenu(true)}
                            startIcon={<AddIcon />}
                        >
                            Ver Menú y Productos
                        </Button>
                    ) : (
                        <Box sx={{ display: 'flex', width: '100%', borderTop: '1px solid #e0e0e0' }}>
                            <Button
                                variant="contained"
                                sx={{ flex: 1, borderRadius: 0, bgcolor: '#6B4C6A', color: 'white', '&:hover': { bgcolor: '#513751' }, display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'center', p: 0 }}
                                onClick={onEnviarComanda}
                                disabled={itemsPendientes.length === 0}
                            >
                                <Typography sx={{ fontSize: '1.15rem', fontWeight: 'bold', mr: 1, textTransform: 'capitalize' }}>Pagar</Typography>
                                <Typography sx={{ fontSize: '1rem', fontWeight: 'normal' }}>{symP} {total.toFixed(2)}</Typography>
                            </Button>
                            <Button
                                sx={{ flex: 0.7, borderRadius: 0, bgcolor: '#f5f5f5', color: 'text.primary', borderLeft: '1px solid #e0e0e0', display: 'flex', flexDirection: 'column', p: 0 }}
                                onClick={() => setShowMobileMenu(false)}
                            >
                                <Typography variant="body2" sx={{ fontWeight: 'bold', textTransform: 'capitalize' }}>Carrito</Typography>
                                <Typography variant="caption" sx={{ fontWeight: '500', fontSize: '0.75rem', lineHeight: 1 }}>{pedido?.items.length || 0} artículos</Typography>
                            </Button>
                        </Box>
                    )}
                </Paper>
            )}
        </React.Fragment>
    );
}
