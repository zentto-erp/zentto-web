'use client';

import React from 'react';
import {
    Box,
    Paper,
    Typography,
    Chip,
    Badge,
} from '@mui/material';
import { useDraggable, useDroppable } from '@dnd-kit/core';
import { Mesa } from '@/hooks/useRestaurante';

interface MesaCardProps {
    mesa: Mesa;
    onClick: () => void;
    isDraggable?: boolean;
}

const estadoConfig = {
    libre: { color: '#4CAF50', label: 'Libre', bgColor: '#E8F5E9' },
    ocupada: { color: '#F44336', label: 'Ocupada', bgColor: '#FFEBEE' },
    reservada: { color: '#FF9800', label: 'Reservada', bgColor: '#FFF3E0' },
    cuenta: { color: '#9C27B0', label: 'Por Cobrar', bgColor: '#F3E5F5' },
};

export function MesaCard({ mesa, onClick, isDraggable = false }: MesaCardProps) {
    const canDragToTransfer = !isDraggable && mesa.estado !== 'libre';
    const isActuallyDraggable = isDraggable || canDragToTransfer;

    const { attributes, listeners, setNodeRef: setDraggableRef, transform, isDragging } = useDraggable({
        id: mesa.id,
        disabled: !isActuallyDraggable,
    });

    const { setNodeRef: setDroppableRef, isOver } = useDroppable({
        id: mesa.id,
    });

    const setCombinedRef = (node: HTMLElement | null) => {
        setDraggableRef(node);
        setDroppableRef(node);
    };

    const config = estadoConfig[mesa.estado];

    const style = transform ? {
        transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`,
        zIndex: isDragging ? 1000 : 1,
    } : undefined;

    return (
        <Box
            ref={setCombinedRef}
            {...(isActuallyDraggable ? { ...listeners, ...attributes } : {})}
            style={style}
            sx={{
                position: { xs: 'relative', md: 'absolute' },
                left: { xs: 'auto', md: mesa.posicionX },
                top: { xs: 'auto', md: mesa.posicionY },
                cursor: isDraggable ? 'move' : 'pointer',
                transition: isDragging ? 'none' : 'transform 0.2s',
                '&:hover': {
                    transform: isDraggable ? undefined : 'translateY(-4px)',
                }
            }}
        >
            <Badge
                badgeContent={mesa.pedidoActual?.items.length || 0}
                color="primary"
                invisible={!mesa.pedidoActual || mesa.pedidoActual.items.length === 0}
            >
                <Paper
                    onClick={!isDraggable ? onClick : undefined}
                    elevation={isDragging ? 8 : (isOver ? 12 : 2)}
                    sx={{
                        width: 140,
                        height: 140,
                        p: 1.5,
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        bgcolor: isOver ? '#e3f2fd' : config.bgColor,
                        border: `2px solid ${isOver ? '#2196f3' : config.color}`,
                        borderRadius: 2,
                        position: 'relative',
                        transition: isDragging ? 'none' : 'all 0.2s',
                        '&:hover': {
                            boxShadow: 4,
                            borderWidth: 3,
                        }
                    }}
                >
                    {/* Número de mesa */}
                    <Typography
                        variant="h4"
                        fontWeight="bold"
                        color={config.color}
                        sx={{ mb: 0.5 }}
                    >
                        {mesa.numero}
                    </Typography>

                    {/* Nombre */}
                    <Typography
                        variant="caption"
                        fontWeight="medium"
                        color="text.secondary"
                        sx={{ mb: 1 }}
                    >
                        {mesa.nombre}
                    </Typography>

                    {/* Capacidad */}
                    <Chip
                        label={`${mesa.capacidad} pax`}
                        size="small"
                        sx={{
                            height: 20,
                            fontSize: '0.7rem',
                            bgcolor: 'rgba(255,255,255,0.7)'
                        }}
                    />

                    {/* Info de cliente y total si está ocupada */}
                    {mesa.estado === 'ocupada' && mesa.pedidoActual && (
                        <Box sx={{
                            mt: 1,
                            textAlign: 'center',
                            width: '100%',
                            overflow: 'hidden'
                        }}>
                            {mesa.cliente && (
                                <Typography
                                    variant="caption"
                                    display="block"
                                    noWrap
                                    fontWeight="medium"
                                >
                                    {mesa.cliente.nombre}
                                </Typography>
                            )}
                            <Typography
                                variant="body2"
                                fontWeight="bold"
                                color={config.color}
                            >
                                ${mesa.pedidoActual.total.toFixed(2)}
                            </Typography>
                        </Box>
                    )}

                    {/* Estado badge */}
                    <Box
                        sx={{
                            position: 'absolute',
                            top: 4,
                            right: 4,
                            width: 12,
                            height: 12,
                            borderRadius: '50%',
                            bgcolor: config.color,
                        }}
                    />
                </Paper>
            </Badge>
        </Box>
    );
}
