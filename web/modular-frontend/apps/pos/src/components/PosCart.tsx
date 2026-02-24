'use client';

import React from 'react';
import {
    Box,
    Typography,
    Paper,
    IconButton,
    Divider,
    Button,
} from '@mui/material';
import dynamic from 'next/dynamic';
import { usePosStore } from '@datqbox/shared-api';

// Iconos dinámicos
const CloseIcon = dynamic(() => import('@mui/icons-material/Close'), { ssr: false });
const UndoIcon = dynamic(() => import('@mui/icons-material/Undo'), { ssr: false });
const ReceiptIcon = dynamic(() => import('@mui/icons-material/Receipt'), { ssr: false });
const BarcodeIcon = dynamic(() => import('@mui/icons-material/QrCode'), { ssr: false });
const LoyaltyIcon = dynamic(() => import('@mui/icons-material/Star'), { ssr: false });
const NavigateNextIcon = dynamic(() => import('@mui/icons-material/NavigateNext'), { ssr: false });

export interface CartItem {
    id: string;
    nombre: string;
    cantidad: number;
    precioUnitario: number;
    total: number;
    imagen?: string;
}

interface PosCartProps {
    items: CartItem[];
    onRemoveItem: (id: string) => void;
    onUpdateQuantity: (id: string, quantity: number) => void;
    subtotal: number;
    impuestos: number;
    total: number;
    cliente: string;
    puntosGanados?: number;
    puntosTotales?: number;
    selectedItemId?: string | null;
    onSelectItem?: (id: string) => void;
}

export function PosCart({
    items,
    onRemoveItem,
    subtotal,
    impuestos,
    total,
    cliente,
    puntosGanados = 0,
    puntosTotales = 0,
    selectedItemId,
    onSelectItem,
}: PosCartProps) {
    const localizacion = usePosStore((s) => s.localizacion);
    const symP = localizacion.monedaPrincipal || 'Bs';
    const symR = localizacion.monedaReferencia || '$';
    const tc = Number(localizacion.tasaCambio || 1);
    const toRef = (value: number) => (tc > 0 ? value / tc : value);

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%', bgcolor: 'background.paper' }}>
            {/* Lista de Items del Carrito */}
            <Box sx={{ flexGrow: 1, overflow: 'auto', p: 2 }}>
                {items.length === 0 ? (
                    <Box sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        height: '100%',
                        color: 'text.secondary'
                    }}>
                        <ReceiptIcon sx={{ fontSize: 48, mb: 2, opacity: 0.3 }} />
                        <Typography variant="body1">
                            Agregue productos para comenzar
                        </Typography>
                    </Box>
                ) : (
                    items.map((item, index) => (
                        <Box
                            key={item.id}
                            onClick={() => onSelectItem?.(item.id)}
                            sx={{
                                display: 'flex',
                                justifyContent: 'space-between',
                                alignItems: 'flex-start',
                                p: 1.5,
                                mb: 0.5,
                                borderRadius: 1,
                                cursor: 'pointer',
                                bgcolor: selectedItemId === item.id ? 'action.selected' : index % 2 === 0 ? 'action.hover' : 'transparent',
                                '&:hover': {
                                    bgcolor: selectedItemId === item.id ? 'action.selected' : 'action.hover',
                                },
                            }}
                        >
                            <Box sx={{ flexGrow: 1, pr: 1, minWidth: 0 }}>
                                <Typography
                                    variant="body2"
                                    fontWeight="medium"
                                    sx={{
                                        whiteSpace: 'normal',
                                        wordBreak: 'break-word',
                                        overflowWrap: 'anywhere',
                                        lineHeight: 1.2,
                                    }}
                                >
                                    {item.nombre}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                    {item.cantidad.toFixed(2)} Und x {symP} {item.precioUnitario.toFixed(2)} / Und · Ref {symR} {toRef(item.precioUnitario).toFixed(2)}
                                </Typography>
                            </Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Typography variant="body2" fontWeight="medium">
                                    {symP} {item.total.toFixed(2)}
                                </Typography>
                                <IconButton
                                    size="small"
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        onRemoveItem(item.id);
                                    }}
                                    sx={{
                                        p: 0.5,
                                        opacity: 0,
                                        '&:hover': { opacity: 1 },
                                        '.MuiBox-root:hover &': { opacity: 1 }
                                    }}
                                >
                                    <CloseIcon fontSize="small" />
                                </IconButton>
                            </Box>
                        </Box>
                    ))
                )}
            </Box>

            {/* Sección de Totales */}
            <Box sx={{ p: 2, borderTop: '1px solid', borderColor: 'divider', bgcolor: 'background.default' }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                    <Typography variant="body2">Subtotal:</Typography>
                    <Typography variant="body2">{symP} {subtotal.toFixed(2)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">Impuestos:</Typography>
                    <Typography variant="body2">{symP} {impuestos.toFixed(2)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <Typography variant="h6" fontWeight="bold">Total:</Typography>
                    <Typography variant="h5" fontWeight="bold" color="primary">
                        {symP} {total.toFixed(2)}
                    </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
                    <Typography variant="caption" color="text.secondary">Total Referencia:</Typography>
                    <Typography variant="caption" color="text.secondary">
                        {symR} {toRef(total).toFixed(2)} (Tasa {tc.toFixed(2)})
                    </Typography>
                </Box>
            </Box>

            {/* Puntos de Fidelidad (Eliminado a petición del usuario) */}

            {/* Botones de Acción */}
            <Box sx={{ display: 'flex', borderTop: '1px solid', borderColor: 'divider' }}>
                <Button
                    startIcon={<UndoIcon />}
                    sx={{
                        flex: 1,
                        py: 1.5,
                        borderRadius: 0,
                        color: 'text.primary',
                        '&:hover': { bgcolor: 'action.hover' }
                    }}
                >
                    Reembolso
                </Button>
                <Divider orientation="vertical" flexItem />
                <Button
                    startIcon={<ReceiptIcon />}
                    sx={{
                        flex: 1,
                        py: 1.5,
                        borderRadius: 0,
                        color: 'text.primary',
                        '&:hover': { bgcolor: 'action.hover' }
                    }}
                >
                    Nota Cliente
                </Button>
                <Divider orientation="vertical" flexItem />
                <Button
                    startIcon={<BarcodeIcon />}
                    sx={{
                        flex: 1,
                        py: 1.5,
                        borderRadius: 0,
                        color: 'text.primary',
                        '&:hover': { bgcolor: 'action.hover' }
                    }}
                >
                    Código
                </Button>
            </Box>
        </Box>
    );
}
