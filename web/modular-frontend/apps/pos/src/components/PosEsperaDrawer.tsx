'use client';

import React, { useEffect } from 'react';
import {
    Drawer,
    Box,
    Typography,
    List,
    ListItem,
    ListItemText,
    ListItemSecondaryAction,
    IconButton,
    Button,
    Chip,
    Divider,
    CircularProgress,
    Tooltip,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import RestoreIcon from '@mui/icons-material/Restore';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import PersonIcon from '@mui/icons-material/Person';
import PointOfSaleIcon from '@mui/icons-material/PointOfSale';
import { usePosStore, type VentaEnEspera } from '@zentto/shared-api';
import { useTimezone } from '@zentto/shared-auth';
import { formatDateTime } from '@zentto/shared-api';

interface PosEsperaDrawerProps {
    open: boolean;
    onClose: () => void;
    onRecuperado: (message: string) => void;
    onError: (message: string) => void;
}

export function PosEsperaDrawer({ open, onClose, onRecuperado, onError }: PosEsperaDrawerProps) {
    const { timeZone } = useTimezone();
    const ventasEnEspera = usePosStore(s => s.ventasEnEspera);
    const loadingEspera = usePosStore(s => s.loadingEspera);
    const syncing = usePosStore(s => s.syncing);
    const listarEspera = usePosStore(s => s.listarEspera);
    const recuperarEspera = usePosStore(s => s.recuperarEspera);
    const anularEspera = usePosStore(s => s.anularEspera);

    // Refrescar al abrir
    useEffect(() => {
        if (open) listarEspera();
    }, [open, listarEspera]);

    const handleRecuperar = async (id: number) => {
        const result = await recuperarEspera(id);
        if (result.success) {
            onRecuperado(result.message);
            onClose();
        } else {
            onError(result.message);
        }
    };

    const handleAnular = async (id: number) => {
        const result = await anularEspera(id);
        if (!result.success) onError(result.message);
    };

    const formatTime = (fecha: string) => {
        try {
            return formatDateTime(fecha, { timeZone });
        } catch {
            return fecha;
        }
    };

    return (
        <Drawer
            anchor="right"
            open={open}
            onClose={onClose}
            PaperProps={{
                sx: {
                    width: { xs: '100%', sm: 420 },
                    bgcolor: 'background.default',
                },
            }}
        >
            <Box sx={{ p: 2, display: 'flex', alignItems: 'center', justifyContent: 'space-between', bgcolor: '#1565C0', color: 'white' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AccessTimeIcon />
                    <Typography variant="h6" fontWeight="bold">
                        Ventas en Espera
                    </Typography>
                    {ventasEnEspera.length > 0 && (
                        <Chip label={ventasEnEspera.length} size="small" sx={{ bgcolor: 'rgba(255,255,255,0.3)', color: 'white', fontWeight: 'bold' }} />
                    )}
                </Box>
                <Tooltip title="Cerrar">
                    <IconButton onClick={onClose} sx={{ color: 'white' }}>
                        <CloseIcon />
                    </IconButton>
                </Tooltip>
            </Box>

            <Box sx={{ flexGrow: 1, overflow: 'auto', p: 1 }}>
                {loadingEspera ? (
                    <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                        <CircularProgress />
                    </Box>
                ) : ventasEnEspera.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 8, color: 'text.secondary' }}>
                        <AccessTimeIcon sx={{ fontSize: 64, opacity: 0.3, mb: 2 }} />
                        <Typography variant="h6">No hay ventas en espera</Typography>
                        <Typography variant="body2">Las ventas puestas en espera aparecerán aquí</Typography>
                    </Box>
                ) : (
                    <List disablePadding>
                        {ventasEnEspera.map((venta, idx) => (
                            <React.Fragment key={venta.id}>
                                {idx > 0 && <Divider />}
                                <ListItem
                                    sx={{
                                        bgcolor: 'background.paper',
                                        borderRadius: 2,
                                        mb: 1,
                                        boxShadow: 1,
                                        flexDirection: 'column',
                                        alignItems: 'stretch',
                                        py: 1.5,
                                    }}
                                >
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 0.5 }}>
                                        <Box>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                <PersonIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                                                <Typography variant="body1" fontWeight="bold">
                                                    {venta.clienteNombre || 'Consumidor Final'}
                                                </Typography>
                                            </Box>
                                            {venta.clienteRif && venta.clienteRif !== 'J-00000000-0' && (
                                                <Typography variant="caption" color="text.secondary">
                                                    RIF: {venta.clienteRif}
                                                </Typography>
                                            )}
                                        </Box>
                                        <Typography variant="h6" fontWeight="bold" color="primary">
                                            ${Number(venta.total).toFixed(2)}
                                        </Typography>
                                    </Box>

                                    <Box sx={{ display: 'flex', gap: 0.5, mb: 1, flexWrap: 'wrap' }}>
                                        <Chip
                                            icon={<PointOfSaleIcon />}
                                            label={venta.estacionNombre || `Caja ${venta.cajaId}`}
                                            size="small"
                                            variant="outlined"
                                        />
                                        <Chip
                                            label={`${venta.cantItems} items`}
                                            size="small"
                                            color="info"
                                            variant="outlined"
                                        />
                                        <Chip
                                            icon={<AccessTimeIcon />}
                                            label={formatTime(venta.fechaCreacion)}
                                            size="small"
                                            variant="outlined"
                                        />
                                    </Box>

                                    {venta.motivo && (
                                        <Typography variant="body2" color="text.secondary" sx={{ mb: 1, fontStyle: 'italic' }}>
                                            📝 {venta.motivo}
                                        </Typography>
                                    )}

                                    <Box sx={{ display: 'flex', gap: 1 }}>
                                        <Button
                                            variant="contained"
                                            color="success"
                                            size="small"
                                            fullWidth
                                            startIcon={<RestoreIcon />}
                                            onClick={() => handleRecuperar(venta.id)}
                                            disabled={syncing}
                                        >
                                            Recuperar
                                        </Button>
                                        <Tooltip title="Anular esta venta en espera">
                                            <IconButton
                                                color="error"
                                                size="small"
                                                onClick={() => handleAnular(venta.id)}
                                                disabled={syncing}
                                            >
                                                <DeleteOutlineIcon />
                                            </IconButton>
                                        </Tooltip>
                                    </Box>
                                </ListItem>
                            </React.Fragment>
                        ))}
                    </List>
                )}
            </Box>

            {/* Footer refresh */}
            <Box sx={{ p: 2, borderTop: '1px solid', borderColor: 'divider' }}>
                <Button
                    fullWidth
                    variant="outlined"
                    onClick={() => listarEspera()}
                    disabled={loadingEspera}
                >
                    🔄 Refrescar Lista
                </Button>
            </Box>
        </Drawer>
    );
}
