// components/modules/clientes/ClientesTable.tsx
/**
 * EJEMPLO PRÁCTICO #1 - TABLA DE CLIENTES
 * Template reutilizable para cualquier módulo de listado
 * 
 * Este archivo muestra cómo:
 * 1. Usar el hook genérico useCrudGeneric
 * 2. Adaptar el componente DataGrid
 * 3. Implementar actions (Ver, Editar, Eliminar)
 * 4. Manejar filtros y búsqueda
 */

'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Box,
  Button,
  TextField,
  Stack,
  Paper,
  Typography,
} from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import DataGrid, { Column, Action } from '../../common/DataGrid';
import { DeleteDialog, ConfirmDialog } from '../../common/Dialogs';
import { useCrudGeneric } from '../../../hooks/useCrudGeneric';
import { Cliente } from '@datqbox/shared-api/types';

export default function ClientesTable() {
  const router = useRouter();
  const crud = useCrudGeneric<Cliente>('clientes');
  const { data, isLoading } = crud.list({ status: 'active' });

  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Cliente | null>(null);

  // Mutations
  const { mutate: deleteCliente, isPending: isDeleting } = crud.delete('');

  // Filtrado local
  const filteredData = (data?.items || []).filter(
    (client: Cliente) =>
      client.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.rif.includes(searchTerm)
  );

  // Columnas
  const columns: Column<Cliente>[] = [
    { accessor: 'codigo', header: 'Código', sortable: true, width: '80px' },
    { accessor: 'nombre', header: 'Nombre', sortable: true },
    { accessor: 'rif', header: 'RIF', sortable: true, width: '100px' },
    { accessor: 'email', header: 'Email', type: 'text' },
    {
      accessor: 'saldo',
      header: 'Saldo',
      type: 'currency',
      width: '120px',
    },
    {
      accessor: 'estado',
      header: 'Estado',
      type: 'status',
      width: '100px',
    },
  ];

  // Actions
  const actions: Action<Cliente>[] = [
    {
      id: 'view',
      label: 'Ver',
      onClick: (row) => router.push(`/clientes/${row.codigo}`),
    },
    {
      id: 'edit',
      label: 'Editar',
      onClick: (row) => router.push(`/clientes/${row.codigo}/edit`),
    },
    {
      id: 'delete',
      label: 'Eliminar',
      color: 'error',
      onClick: (row) => {
        setSelectedClient(row);
        setDeleteOpen(true);
      },
    },
  ];

  const handleDeleteConfirm = () => {
    if (selectedClient) {
      deleteCliente(selectedClient.codigo, {
        onSuccess: () => {
          setDeleteOpen(false);
          setSelectedClient(null);
        },
      });
    }
  };

  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
      {/* Header */}
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={600}>Gestión de Clientes</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push('/clientes/new')}
        >
          Nuevo Cliente
        </Button>
      </Box>

      {/* Search Bar */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Stack spacing={2}>
          <TextField
            placeholder="Buscar por nombre o RIF..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            fullWidth
            size="small"
            variant="outlined"
          />
        </Stack>
      </Paper>

      {/* Data Grid */}
      <DataGrid<Cliente>
        columns={columns}
        data={filteredData}
        totalRecords={data?.total || 0}
        isLoading={isLoading}
        actions={actions}
        title={`${filteredData.length} clientes`}
        emptyText="No hay clientes registrados"
      />

      {/* Delete Dialog */}
      <DeleteDialog
        open={deleteOpen}
        itemName={selectedClient?.nombre || ''}
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setDeleteOpen(false);
          setSelectedClient(null);
        }}
        isLoading={isDeleting}
      />
    </Box>
  );
}

