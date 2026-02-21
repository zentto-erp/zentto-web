'use client';

import React, { useState, useEffect } from 'react';
import {
    Box,
    Dialog,
    DialogTitle,
    DialogContent,
    TextField,
    List,
    ListItem,
    ListItemText,
    ListItemButton,
    IconButton,
    Typography,
    Button,
    Divider,
    Avatar,
    Chip,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import SearchIcon from '@mui/icons-material/Search';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import HistoryIcon from '@mui/icons-material/History';

export interface Customer {
    id: string;
    codigo: string;
    nombre: string;
    rif: string;
    telefono?: string;
    email?: string;
    direccion?: string;
    tipoPrecio?: string;
    credito?: number;
}

interface PosCustomerSearchProps {
    open: boolean;
    onClose: () => void;
    onSelectCustomer: (customer: Customer) => void;
    selectedCustomerId?: string;
}

// Datos de ejemplo
const SAMPLE_CUSTOMERS: Customer[] = [
    { id: '1', codigo: 'CF', nombre: 'Consumidor Final', rif: 'J-00000000-0', tipoPrecio: 'Detal' },
    { id: '2', codigo: 'C001', nombre: 'Juan Pérez', rif: 'V-12345678-9', telefono: '0414-1234567', tipoPrecio: 'Detal', credito: 500 },
    { id: '3', codigo: 'C002', nombre: 'María García', rif: 'V-87654321-0', telefono: '0412-7654321', email: 'maria@email.com', tipoPrecio: 'Mayor', credito: 2000 },
    { id: '4', codigo: 'C003', nombre: 'Distribuidora ABC C.A.', rif: 'J-12345678-9', telefono: '0212-1234567', direccion: 'Av. Principal, Caracas', tipoPrecio: 'Distribuidor', credito: 10000 },
    { id: '5', codigo: 'C004', nombre: 'Pedro Rodríguez', rif: 'V-11223344-5', telefono: '0416-9876543', tipoPrecio: 'Detal' },
];

const RECENT_CUSTOMERS = ['C001', 'C003'];

export function PosCustomerSearch({
    open,
    onClose,
    onSelectCustomer,
    selectedCustomerId,
}: PosCustomerSearchProps) {
    const [searchTerm, setSearchTerm] = useState('');
    const [customers, setCustomers] = useState<Customer[]>(SAMPLE_CUSTOMERS);
    const [showNewCustomerForm, setShowNewCustomerForm] = useState(false);

    useEffect(() => {
        if (open) {
            setSearchTerm('');
            setShowNewCustomerForm(false);
        }
    }, [open]);

    const filteredCustomers = customers.filter(c =>
        c.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.codigo.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.rif.toLowerCase().includes(searchTerm.toLowerCase()) ||
        c.telefono?.includes(searchTerm)
    );

    const recentCustomers = customers.filter(c => RECENT_CUSTOMERS.includes(c.codigo));

    const handleSelect = (customer: Customer) => {
        onSelectCustomer(customer);
        onClose();
    };

    return (
        <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
            <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h6">Buscar Cliente</Typography>
                <IconButton onClick={onClose}>
                    <CloseIcon />
                </IconButton>
            </DialogTitle>

            <DialogContent>
                {/* Búsqueda */}
                <TextField
                    fullWidth
                    autoFocus
                    placeholder="Buscar por nombre, código, RIF o teléfono..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                    }}
                    sx={{ mb: 2 }}
                />

                {/* Clientes Recientes */}
                {!searchTerm && recentCustomers.length > 0 && (
                    <Box sx={{ mb: 3 }}>
                        <Typography variant="subtitle2" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1, color: 'text.secondary' }}>
                            <HistoryIcon fontSize="small" />
                            Clientes Recientes
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                            {recentCustomers.map(customer => (
                                <Chip
                                    key={customer.id}
                                    avatar={<Avatar>{customer.nombre.charAt(0)}</Avatar>}
                                    label={customer.nombre}
                                    onClick={() => handleSelect(customer)}
                                    sx={{ cursor: 'pointer' }}
                                />
                            ))}
                        </Box>
                    </Box>
                )}

                <Divider sx={{ my: 2 }} />

                {/* Lista de Clientes */}
                <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
                    {searchTerm ? 'Resultados de búsqueda' : 'Todos los clientes'}
                </Typography>

                <List sx={{ maxHeight: 300, overflow: 'auto' }}>
                    {filteredCustomers.length === 0 ? (
                        <Box sx={{ textAlign: 'center', py: 4 }}>
                            <Typography color="text.secondary">
                                No se encontraron clientes
                            </Typography>
                            <Button
                                startIcon={<PersonAddIcon />}
                                sx={{ mt: 1 }}
                                onClick={() => setShowNewCustomerForm(true)}
                            >
                                Crear nuevo cliente
                            </Button>
                        </Box>
                    ) : (
                        filteredCustomers.map((customer) => (
                            <ListItem
                                key={customer.id}
                                disablePadding
                                secondaryAction={
                                    selectedCustomerId === customer.id && (
                                        <Chip label="Seleccionado" color="primary" size="small" />
                                    )
                                }
                            >
                                <ListItemButton
                                    onClick={() => handleSelect(customer)}
                                    selected={selectedCustomerId === customer.id}
                                >
                                    <Avatar sx={{ mr: 2, bgcolor: 'primary.main' }}>
                                        {customer.nombre.charAt(0)}
                                    </Avatar>
                                    <ListItemText
                                        primary={
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                                <Typography fontWeight="medium">
                                                    {customer.nombre}
                                                </Typography>
                                                <Chip
                                                    label={customer.tipoPrecio}
                                                    size="small"
                                                    variant="outlined"
                                                    sx={{ height: 20, fontSize: '0.7rem' }}
                                                />
                                            </Box>
                                        }
                                        secondary={
                                            <Box>
                                                <Typography variant="caption" display="block">
                                                    {customer.rif}
                                                </Typography>
                                                {customer.telefono && (
                                                    <Typography variant="caption" display="block" color="text.secondary">
                                                        📞 {customer.telefono}
                                                    </Typography>
                                                )}
                                                {customer.credito !== undefined && customer.credito > 0 && (
                                                    <Typography variant="caption" display="block" color="success.main">
                                                        💳 Crédito: ${customer.credito?.toFixed(2)}
                                                    </Typography>
                                                )}
                                            </Box>
                                        }
                                    />
                                </ListItemButton>
                            </ListItem>
                        ))
                    )}
                </List>

                {/* Botón de nuevo cliente */}
                <Button
                    fullWidth
                    variant="outlined"
                    startIcon={<PersonAddIcon />}
                    onClick={() => setShowNewCustomerForm(true)}
                    sx={{ mt: 2 }}
                >
                    Nuevo Cliente
                </Button>
            </DialogContent>
        </Dialog>
    );
}
