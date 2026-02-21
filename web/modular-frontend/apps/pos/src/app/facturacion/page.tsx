'use client';

import React, { useState, useMemo } from 'react';
import {
    Box,
    Paper,
    Typography,
    Chip,
    IconButton,
    Tooltip,
} from '@mui/material';
import dynamic from 'next/dynamic';
import {
    PosCart,
    PosNumpad,
    PosPaymentButton,
    PosProductGrid,
    PosHeader,
    PosPaymentModal,
    PosCustomerSearch,
    type Customer,
} from '@/components';
import { useCart, useBuscarProductos } from '@/hooks';

// Iconos dinámicos
const PersonIcon = dynamic(() => import('@mui/icons-material/Person'), { ssr: false });
const DeleteSweepIcon = dynamic(() => import('@mui/icons-material/DeleteSweep'), { ssr: false });

// Categorías de ejemplo
const CATEGORIES = [
    { id: 'escritorios', nombre: 'Escritorios' },
    { id: 'sillas', nombre: 'Sillas' },
    { id: 'accesorios', nombre: 'Accesorios' },
    { id: 'tecnologia', nombre: 'Tecnología' },
    { id: 'papeleria', nombre: 'Papelería' },
];

export default function PosFacturacionPage() {
    // Estados
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
    const [selectedItemId, setSelectedItemId] = useState<string | null>(null);
    const [numpadValue, setNumpadValue] = useState('');
    const [numpadMode, setNumpadMode] = useState<'qty' | 'discount' | 'price'>('qty');
    const [customer, setCustomer] = useState<Customer>({
        id: '1',
        codigo: 'CF',
        nombre: 'Consumidor Final',
        rif: 'J-00000000-0',
        tipoPrecio: 'Detal',
        credito: 0,
    });
    
    // Modales
    const [paymentModalOpen, setPaymentModalOpen] = useState(false);
    const [customerModalOpen, setCustomerModalOpen] = useState(false);

    // Hooks
    const { items, addItem, updateItem, removeItem, clearCart, subtotal, total } = useCart();
    const { data: productos = [], isLoading } = useBuscarProductos(searchTerm);

    // Filtrar productos por categoría
    const filteredProducts = useMemo(() => {
        return productos.filter(p => 
            !selectedCategory || p.categoria === selectedCategory
        );
    }, [productos, selectedCategory]);

    // Calcular impuestos (16% IVA)
    const impuestos = total * 0.16;
    const totalConImpuesto = total + impuestos;

    // Agregar producto al carrito
    const handleAddProduct = (product: { id: string; nombre: string; precio: number; categoria?: string }) => {
        // Convertir al formato Producto esperado por el hook
        const producto = {
            id: product.id,
            codigo: product.id,
            nombre: product.nombre,
            precioDetal: product.precio,
            precioMayor: product.precio * 0.9,
            precioDistribuidor: product.precio * 0.8,
            existencia: 100,
            categoria: product.categoria || '',
            iva: 16,
        };
        addItem(producto, 1, customer.tipoPrecio);
    };

    // Manejar teclado numérico
    const handleNumberPress = (num: string) => {
        if (num === '+/-') {
            setNumpadValue(prev => prev.startsWith('-') ? prev.slice(1) : '-' + prev);
            return;
        }
        
        const newValue = numpadValue + num;
        setNumpadValue(newValue);
        
        // Aplicar directamente si hay item seleccionado
        if (selectedItemId) {
            const numVal = parseFloat(newValue);
            if (!isNaN(numVal)) {
                switch (numpadMode) {
                    case 'qty':
                        updateItem(selectedItemId, { cantidad: numVal });
                        break;
                    case 'price':
                        updateItem(selectedItemId, { precio: numVal });
                        break;
                    case 'discount':
                        updateItem(selectedItemId, { descuento: numVal });
                        break;
                }
            }
        }
    };

    const handleBackspace = () => {
        setNumpadValue(prev => prev.slice(0, -1));
    };

    const handleClear = () => {
        setNumpadValue('');
    };

    // Completar pago
    const handlePaymentComplete = (payments: Array<{ metodo: string; monto: number; referencia?: string }>) => {
        console.log('Pago completado:', { items, customer, payments, total: totalConImpuesto });
        clearCart();
        setCustomer({
            id: '1',
            codigo: 'CF',
            nombre: 'Consumidor Final',
            rif: 'J-00000000-0',
            tipoPrecio: 'Detal',
            credito: 0,
        });
    };

    // Cambiar cliente
    const handleCustomerChange = (newCustomer: Customer) => {
        setCustomer(newCustomer);
        // Actualizar precios de items existentes según el tipo de cliente
        items.forEach(item => {
            // Aquí se podría recalcular precios según el tipo de cliente
        });
    };

    return (
        <Box sx={{ 
            height: 'calc(100vh - 64px)',
            display: 'flex',
            overflow: 'hidden',
            bgcolor: '#f5f5f5',
        }}>
            {/* Panel Izquierdo - Carrito y Controles */}
            <Box sx={{ 
                width: { xs: '100%', md: 440 }, 
                minWidth: 400,
                display: 'flex', 
                flexDirection: 'column',
                borderRight: '1px solid #e0e0e0',
                bgcolor: '#fff',
            }}>
                {/* Header del Carrito con Cliente */}
                <Paper sx={{ p: 2, borderRadius: 0, borderBottom: '1px solid #e0e0e0' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PersonIcon color="action" />
                            <Box>
                                <Typography variant="body2" color="text.secondary">
                                    Cliente
                                </Typography>
                                <Typography variant="body1" fontWeight="medium">
                                    {customer.nombre}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    {customer.rif}
                                </Typography>
                            </Box>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Tooltip title="Cambiar Cliente">
                                <IconButton 
                                    size="small" 
                                    onClick={() => setCustomerModalOpen(true)}
                                    color="primary"
                                >
                                    <PersonIcon />
                                </IconButton>
                            </Tooltip>
                            {items.length > 0 && (
                                <Tooltip title="Limpiar Carrito">
                                    <IconButton 
                                        size="small" 
                                        onClick={clearCart}
                                        color="error"
                                    >
                                        <DeleteSweepIcon />
                                    </IconButton>
                                </Tooltip>
                            )}
                        </Box>
                    </Box>
                    {customer.tipoPrecio !== 'Detal' && (
                        <Chip
                            label={`Precio: ${customer.tipoPrecio}`}
                            color="primary"
                            size="small"
                            sx={{ mt: 1 }}
                        />
                    )}
                </Paper>

                {/* Carrito */}
                <Box sx={{ flexGrow: 1, overflow: 'hidden' }}>
                    <PosCart
                        items={items.map(item => ({
                            id: item.id,
                            nombre: item.nombre,
                            cantidad: item.cantidad,
                            precioUnitario: item.precio,
                            total: item.total,
                        }))}
                        onRemoveItem={removeItem}
                        onUpdateQuantity={() => {}}
                        subtotal={subtotal}
                        impuestos={impuestos}
                        total={totalConImpuesto}
                        cliente={customer.nombre}
                        puntosGanados={Math.floor(totalConImpuesto / 10)}
                        puntosTotales={1250}
                        selectedItemId={selectedItemId}
                        onSelectItem={setSelectedItemId}
                    />
                </Box>

                {/* Numpad */}
                <Box sx={{ height: 280, borderTop: '1px solid #e0e0e0' }}>
                    <PosNumpad
                        onNumberPress={handleNumberPress}
                        onBackspace={handleBackspace}
                        onClear={handleClear}
                        onQuantity={() => setNumpadMode('qty')}
                        onDiscount={() => setNumpadMode('discount')}
                        onPrice={() => setNumpadMode('price')}
                        activeMode={numpadMode}
                    />
                </Box>

                {/* Botón de Pago */}
                <Box sx={{ height: 100 }}>
                    <PosPaymentButton
                        total={totalConImpuesto}
                        onClick={() => setPaymentModalOpen(true)}
                        disabled={items.length === 0}
                    />
                </Box>
            </Box>

            {/* Panel Derecho - Productos */}
            <Box sx={{ 
                flexGrow: 1, 
                display: 'flex', 
                flexDirection: 'column',
                overflow: 'hidden',
            }}>
                {/* Header con búsqueda y categorías */}
                <PosHeader
                    searchTerm={searchTerm}
                    onSearchChange={setSearchTerm}
                    categories={CATEGORIES}
                    selectedCategory={selectedCategory}
                    onCategorySelect={setSelectedCategory}
                    cajaName="Caja Principal"
                    userName="Ana García"
                />

                {/* Grid de Productos */}
                <Box sx={{ flexGrow: 1, overflow: 'hidden' }}>
                    <PosProductGrid
                        products={filteredProducts.map(p => ({
                            id: p.id,
                            nombre: p.nombre,
                            precio: customer.tipoPrecio === 'Mayor' 
                                ? p.precioMayor 
                                : customer.tipoPrecio === 'Distribuidor' 
                                    ? p.precioDistribuidor 
                                    : p.precioDetal,
                            imagen: p.imagen,
                            categoria: p.categoria,
                        }))}
                        onProductClick={handleAddProduct}
                        selectedCategory={selectedCategory || undefined}
                    />
                </Box>
            </Box>

            {/* Modal de Pago */}
            <PosPaymentModal
                open={paymentModalOpen}
                onClose={() => setPaymentModalOpen(false)}
                total={totalConImpuesto}
                items={items.map(item => ({
                    nombre: item.nombre,
                    cantidad: item.cantidad,
                    precio: item.precio,
                    total: item.total,
                }))}
                cliente={customer.nombre}
                onPaymentComplete={handlePaymentComplete}
            />

            {/* Modal de Búsqueda de Cliente */}
            <PosCustomerSearch
                open={customerModalOpen}
                onClose={() => setCustomerModalOpen(false)}
                onSelectCustomer={handleCustomerChange}
                selectedCustomerId={customer.id}
            />
        </Box>
    );
}
