// components/modules/clientes/ClientesTable.tsx
/**
 * Tabla de Clientes con ZenttoDataGrid
 * Incluye: clipboard, header filters, totales, acciones CRUD
 */

'use client';

import React, { useState, useMemo } from 'react';
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
import {
  ZenttoDataGrid,
  type ZenttoColDef,
  buildCrudActionsColumn,
  DeleteDialog,
} from '@zentto/shared-ui';
import { useCrudGeneric } from '../../../hooks/useCrudGeneric';
import { Cliente } from '@zentto/shared-api/types';

export default function ClientesTable() {
  const router = useRouter();
  const crud = useCrudGeneric<Cliente>('clientes');
  const { data, isLoading } = crud.list();

  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Cliente | null>(null);

  // Mutations
  const { mutate: deleteCliente, isPending: isDeleting } = crud.delete('');

  // Filtrado local
  const filteredData = useMemo(() => {
    const items = data?.items || data?.data || [];
    if (!searchTerm) return items;
    const term = searchTerm.toLowerCase();
    return items.filter(
      (client: Cliente) =>
        client.nombre.toLowerCase().includes(term) ||
        client.rif.includes(searchTerm)
    );
  }, [data, searchTerm]);

  // Columnas ZenttoDataGrid
  const columns = useMemo<ZenttoColDef[]>(
    () => [
      {
        field: 'codigo',
        headerName: 'Codigo',
        width: 100,
        sortable: true,
      },
      {
        field: 'nombre',
        headerName: 'Nombre',
        flex: 1,
        minWidth: 200,
        sortable: true,
      },
      {
        field: 'rif',
        headerName: 'RIF',
        width: 130,
        sortable: true,
        mobileHide: true,
      },
      {
        field: 'email',
        headerName: 'Email',
        width: 200,
        mobileHide: true,
        tabletHide: true,
      },
      {
        field: 'telefono',
        headerName: 'Telefono',
        width: 140,
        mobileHide: true,
        tabletHide: true,
      },
      {
        field: 'saldo',
        headerName: 'Saldo',
        width: 140,
        type: 'number',
        currency: true,
        aggregation: 'sum',
        mobileHide: true,
      },
      {
        field: 'estado',
        headerName: 'Estado',
        width: 110,
        statusColors: {
          Activo: 'success',
          Inactivo: 'error',
          Suspendido: 'warning',
        },
        statusVariant: 'outlined',
      },
      buildCrudActionsColumn({
        onView: (row) => router.push(`/clientes/${row.codigo}`),
        onEdit: (row) => router.push(`/clientes/${row.codigo}/edit`),
        onDelete: (row) => {
          setSelectedClient(row);
          setDeleteOpen(true);
        },
      }),
    ],
    [router]
  );

  // Rows con id
  const rows = useMemo(
    () =>
      filteredData.map((client: Cliente, idx: number) => ({
        id: client.codigo || idx,
        ...client,
      })),
    [filteredData]
  );

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
        <Typography variant="h5" fontWeight={600}>
          Gestion de Clientes
        </Typography>
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
            variant="outlined"
          />
        </Stack>
      </Paper>

      {/* ZenttoDataGrid */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        <ZenttoDataGrid
          columns={columns}
          rows={rows}
          loading={isLoading}
          enableClipboard
          enableHeaderFilters
          showTotals
          density="comfortable"
          exportFilename="clientes"
          gridId="clientes-table"
          toolbarTitle={`${filteredData.length} clientes`}
          pageSizeOptions={[10, 25, 50, 100]}
          sx={{ height: '100%' }}
        />
      </Box>

      {/* Delete Dialog */}
      <DeleteDialog
        open={deleteOpen}
        itemName={selectedClient?.nombre || ''}
        onConfirm={handleDeleteConfirm}
        onClose={() => {
          setDeleteOpen(false);
          setSelectedClient(null);
        }}
        loading={isDeleting}
      />
    </Box>
  );
}
