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
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import RemoveIcon from '@mui/icons-material/Remove';
import DeleteIcon from '@mui/icons-material/Delete';
import KitchenIcon from '@mui/icons-material/Kitchen';
import ReceiptIcon from '@mui/icons-material/Receipt';
import LocalOfferIcon from '@mui/icons-material/LocalOffer';
import { Mesa, ProductoMenu, ItemPedido, ComponenteProducto } from '@/hooks/useRestaurante';

interface PanelPedidoProps {
    mesa: Mesa;
    productos: ProductoMenu[];
    onAgregarItem: (item: Omit<ItemPedido, 'id'>) => void;
    onEnviarComanda: () => void;
    onCerrar: () => void;
}

export function PanelPedido({
    mesa,
    productos,
    onAgregarItem,
    onEnviarComanda,
    onCerrar,
}: PanelPedidoProps) {
    const [categoriaActiva, setCategoriaActiva] = useState<string>('todos');
    const [productoSeleccionado, setProductoSeleccionado] = useState<ProductoMenu | null>(null);
    const [componentesSeleccionados, setComponentesSeleccionados] = useState<Record<string, string>>({});
    const [comentario, setComentario] = useState('');
    const [cantidad, setCantidad] = useState(1);

    const categorias = ['todos', ...Array.from(new Set(productos.map(p => p.categoria)))];

    const productosFiltrados = categoriaActiva === 'todos'
        ? productos
        : productos.filter(p => p.categoria === categoriaActivo);

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
            });
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
        });

        setProductoSeleccionado(null);
        setComponentesSeleccionados({});
        setComentario('');
        setCantidad(1);
    };

    const pedido = mesa.pedidoActual;
    const itemsPendientes = pedido?.items.filter(i => !i.enviadoACocina) || [];
    const itemsEnviados = pedido?.items.filter(i => i.enviadoACocina) || [];
    const total = pedido?.total || 0;

    return (
        <Box sx={{ height: '100%', display: 'flex', gap: 2 }}>
            {/* Panel izquierdo - Items del pedido */}
            <Paper sx={{ width: 350, p: 2, display: 'flex', flexDirection: 'column' }}>
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
                                Pendientes de enviar
                            </Typography>
                            <List dense>
                                {itemsPendientes.map((item) => (
                                    <ListItem key={item.id}>
                                        <ListItemText
                                            primary={item.nombre}
                                            secondary={`${item.cantidad}x $${item.precioUnitario.toFixed(2)}`}
                                        />
                                        <Typography variant="body2" fontWeight="bold">
                                            ${item.subtotal.toFixed(2)}
                                        </Typography>
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
                                            ${item.subtotal.toFixed(2)}
                                        </Typography>
                                    </ListItem>
                                ))}
                            </List>
                        </>
                    )}
                </Box>

                <Divider sx={{ my: 2 }} />

                {/* Total */}
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                    <Typography variant="h6">Total:</Typography>
                    <Typography variant="h5" fontWeight="bold" color="primary">
                        ${total.toFixed(2)}
                    </Typography>
                </Box>

                {/* Botones de acción */}
                <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                        variant="contained"
                        startIcon={<KitchenIcon />}
                        onClick={onEnviarComanda}
                        disabled={itemsPendientes.length === 0}
                        fullWidth
                    >
                        Enviar ({itemsPendientes.length})
                    </Button>
                    <Button
                        variant="outlined"
                        startIcon={<ReceiptIcon />}
                        disabled={itemsEnviados.length === 0}
                    >
                        Cuenta
                    </Button>
                </Box>
            </Paper>

            {/* Panel derecho - Menú táctil */}
            <Paper sx={{ flexGrow: 1, p: 2, display: 'flex', flexDirection: 'column' }}>
                {/* Sugerencias del día */}
                {sugerencias.length > 0 && (
                    <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="primary" gutterBottom>
                            <LocalOfferIcon sx={{ fontSize: 16, mr: 0.5 }} />
                            Sugerencias del día
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            {sugerencias.map(p => (
                                <Chip
                                    key={p.id}
                                    label={`${p.nombre} - $${p.precio}`}
                                    onClick={() => handleAgregarProducto(p)}
                                    color="primary"
                                    variant="outlined"
                                    sx={{ cursor: 'pointer' }}
                                />
                            ))}
                        </Box>
                    </Box>
                )}

                <Divider sx={{ my: 1 }} />

                {/* Categorías */}
                <Tabs
                    value={categoriaActiva}
                    onChange={(_, v) => setCategoriaActiva(v)}
                    variant="scrollable"
                    scrollButtons="auto"
                    sx={{ mb: 2 }}
                >
                    {categorias.map(cat => (
                        <Tab 
                            key={cat} 
                            value={cat} 
                            label={cat.charAt(0).toUpperCase() + cat.slice(1)}
                        />
                    ))}
                </Tabs>

                {/* Grid de productos */}
                <Box sx={{ flexGrow: 1, overflow: 'auto' }}>
                    <Grid container spacing={1.5}>
                        {productosFiltrados.map((producto) => (
                            <Grid item xs={6} sm={4} md={3} key={producto.id}>
                                <Button
                                    onClick={() => handleAgregarProducto(producto)}
                                    sx={{
                                        width: '100%',
                                        height: 100,
                                        p: 1.5,
                                        justifyContent: 'flex-start',
                                        alignItems: 'flex-start',
                                        flexDirection: 'column',
                                        border: '1px solid',
                                        borderColor: 'divider',
                                        borderRadius: 2,
                                        bgcolor: producto.esCompuesto ? 'action.hover' : 'background.paper',
                                        '&:hover': {
                                            bgcolor: 'action.selected',
                                            transform: 'translateY(-2px)',
                                        },
                                        transition: 'all 0.2s',
                                    }}
                                >
                                    <Typography 
                                        variant="body2" 
                                        fontWeight="medium"
                                        align="left"
                                        sx={{ 
                                            flexGrow: 1,
                                            display: '-webkit-box',
                                            WebkitLineClamp: 2,
                                            WebkitBoxOrient: 'vertical',
                                            overflow: 'hidden',
                                            width: '100%'
                                        }}
                                    >
                                        {producto.nombre}
                                    </Typography>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                        <Typography variant="body2" fontWeight="bold" color="primary">
                                            ${producto.precio}
                                        </Typography>
                                        {producto.esCompuesto && (
                                            <Chip label="Compuesto" size="small" sx={{ height: 16, fontSize: '0.6rem' }} />
                                        )}
                                    </Box>
                                    {producto.tiempoPreparacion > 0 && (
                                        <Typography variant="caption" color="text.secondary">
                                            ⏱️ {producto.tiempoPreparacion}min
                                        </Typography>
                                    )}
                                </Button>
                            </Grid>
                        ))}
                    </Grid>
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
                        Agregar - ${((productoSeleccionado?.precio || 0) * cantidad).toFixed(2)}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
