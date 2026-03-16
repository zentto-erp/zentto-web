'use client';

import React, { useMemo, useState } from 'react';
import {
    Box, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions,
    TextField, CircularProgress
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { GridColDef } from '@mui/x-data-grid';
import { EditableDataGrid } from '@zentto/module-admin';
import {
    AmbienteAdmin,
    useAmbientesAdminQuery,
    useUpsertAmbienteAdminMutation,
} from '@/hooks/useRestauranteAdmin';

export default function AdminAmbientesPage() {
    const { data: ambientesData, isLoading } = useAmbientesAdminQuery();
    const upsertAmbienteMutation = useUpsertAmbienteAdminMutation();
    const [open, setOpen] = useState(false);
    const [editing, setEditing] = useState<Partial<AmbienteAdmin>>({});

    const page = 1;
    const pageSize = 100;

    const ambientes = (ambientesData?.rows ?? []) as AmbienteAdmin[];
    const loading = isLoading || upsertAmbienteMutation.isPending;

    const handleSave = async () => {
        try {
            await upsertAmbienteMutation.mutateAsync({
                id: editing.id,
                nombre: editing.nombre,
                color: editing.color || '#4CAF50',
                orden: Number(editing.orden || 1)
            });
            setOpen(false);
            setEditing({});
        } catch (e) {
            alert('Error guardando ambiente');
        }
    };

    const columns = useMemo<GridColDef[]>(() => [
        { field: 'id', headerName: 'ID', minWidth: 90, flex: 0.5 },
        { field: 'nombre', headerName: 'Nombre', minWidth: 220, flex: 1.3, editable: true },
        {
            field: 'color',
            headerName: 'Color / Etiqueta',
            minWidth: 200,
            flex: 1,
            editable: true,
            renderCell: (params) => (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box sx={{ width: 20, height: 20, bgcolor: String(params.value || '#4CAF50'), borderRadius: 1 }} />
                    <Typography variant="body2">{String(params.value || '')}</Typography>
                </Box>
            ),
        },
        { field: 'orden', headerName: 'Orden', minWidth: 120, flex: 0.6, type: 'number', editable: true },
    ], []);

    const handleUpdateRow = async (row: Record<string, unknown>) => {
        await upsertAmbienteMutation.mutateAsync({
            id: Number(row.id),
            nombre: String(row.nombre || '').trim(),
            color: String(row.color || '#4CAF50'),
            orden: Number(row.orden || 1),
        });
    };

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                <Typography variant="h4" fontWeight="bold">Configurar Salones y Mesas</Typography>
                <Button
                    variant="contained"
                    startIcon={<AddIcon />}
                    onClick={() => { setEditing({}); setOpen(true); }}
                >
                    Nuevo Ambiente
                </Button>
            </Box>

            {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
                    <CircularProgress />
                </Box>
            ) : (
                <EditableDataGrid
                    rows={ambientes}
                    columns={columns}
                    loading={loading}
                    page={page}
                    pageSize={pageSize}
                    rowCount={ambientes.length}
                    onPageChange={() => { }}
                    onAddRow={() => { setEditing({}); setOpen(true); }}
                    onUpdateRow={handleUpdateRow}
                    addButtonText="Nuevo Ambiente"
                    getRowId={(row) => Number(row.id)}
                />
            )}

            <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{editing.id ? 'Editar Ambiente' : 'Nuevo Ambiente'}</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        label="Nombre del Salón"
                        value={editing.nombre || ''}
                        onChange={(e) => setEditing({ ...editing, nombre: e.target.value })}
                        sx={{ mt: 2, mb: 2 }}
                    />
                    <TextField
                        fullWidth
                        label="Color (Hexadecimal) Ej: #FF0000"
                        value={editing.color || ''}
                        onChange={(e) => setEditing({ ...editing, color: e.target.value })}
                        sx={{ mb: 2 }}
                    />
                    <TextField
                        fullWidth
                        type="number"
                        label="Orden (ej: 1, 2, 3...)"
                        value={editing.orden || ''}
                        onChange={(e) => setEditing({ ...editing, orden: Number(e.target.value) })}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpen(false)}>Cancelar</Button>
                    <Button variant="contained" onClick={handleSave}>Guardar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
