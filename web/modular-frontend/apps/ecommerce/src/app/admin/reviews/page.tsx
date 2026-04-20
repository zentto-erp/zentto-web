'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box, Stack, Typography, TextField, MenuItem, CircularProgress,
    Dialog, DialogTitle, DialogContent, DialogActions, Button, Paper,
} from '@mui/material';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import {
    useAdminReviewsList,
    useModerateReview,
    buildEcommerceGridId,
    useEcommerceGridId,
    useEcommerceGridRegistration,
} from '@zentto/module-ecommerce';

const COLUMNS: ColumnDef[] = [
    { field: 'reviewId', header: 'ID', width: 70, sortable: true },
    { field: 'productCode', header: 'Producto', width: 120, sortable: true },
    { field: 'productName', header: 'Nombre', flex: 1, minWidth: 180 },
    { field: 'rating', header: '★', width: 70, type: 'number', sortable: true },
    { field: 'title', header: 'Título', width: 180 },
    { field: 'reviewerName', header: 'Autor', width: 140 },
    {
        field: 'status',
        header: 'Estado',
        width: 110,
        sortable: true,
        groupable: true,
        statusColors: { pending: 'warning', approved: 'success', rejected: 'error' },
        statusVariant: 'outlined',
    },
    { field: 'createdAt', header: 'Fecha', width: 150, type: 'date' },
    {
        field: 'actions',
        header: 'Acciones',
        type: 'actions',
        width: 140,
        pin: 'right',
        actions: [
            { icon: 'check', label: 'Aprobar', action: 'approve', color: '#10b981' },
            { icon: 'close', label: 'Rechazar', action: 'reject', color: '#ef4444' },
            { icon: 'view', label: 'Ver detalle', action: 'view' },
        ],
    },
];

const GRID_ID = buildEcommerceGridId('admin-reviews', 'main');

export default function AdminReviewsPage() {
    const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
    useEcommerceGridId(gridRef, GRID_ID);
    const { registered } = useEcommerceGridRegistration(gridLayoutReady);

    const [status, setStatus] = useState<'pending' | 'approved' | 'rejected' | ''>('pending');
    const [detailReview, setDetailReview] = useState<any>(null);

    const { data, isLoading } = useAdminReviewsList({
        status: status || undefined,
        limit: 50,
    });
    const moderateMut = useModerateReview();

    const rows = useMemo(
        () => (data?.rows ?? []).map((r) => ({ ...r, id: r.reviewId })),
        [data]
    );

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        el.columns = COLUMNS;
        el.rows = rows;
        el.loading = isLoading;
    }, [rows, isLoading, registered]);

    useEffect(() => {
        const el = gridRef.current;
        if (!el || !registered) return;
        const onAction = (e: any) => {
            const { action, row } = e.detail ?? {};
            if (!row) return;
            if (action === 'approve') {
                moderateMut.mutate({ reviewId: row.reviewId, status: 'approved' });
            } else if (action === 'reject') {
                moderateMut.mutate({ reviewId: row.reviewId, status: 'rejected' });
            } else if (action === 'view') {
                setDetailReview(row);
            }
        };
        el.addEventListener('action-click', onAction);
        return () => el.removeEventListener('action-click', onAction);
    }, [registered, moderateMut]);

    if (!registered) return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;

    return (
        <Box>
            <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Reseñas</Typography>

            <Paper sx={{ p: 2, mb: 2 }}>
                <TextField
                    size="small"
                    select
                    label="Filtrar por estado"
                    value={status}
                    onChange={(e) => setStatus(e.target.value as any)}
                    sx={{ minWidth: 200 }}
                >
                    <MenuItem value="">Todas</MenuItem>
                    <MenuItem value="pending">Pendientes</MenuItem>
                    <MenuItem value="approved">Aprobadas</MenuItem>
                    <MenuItem value="rejected">Rechazadas</MenuItem>
                </TextField>
            </Paper>

            <zentto-grid
                ref={gridRef}
                export-filename="admin-reviews"
                height="calc(100vh - 280px)"
                enable-toolbar enable-header-menu enable-header-filters enable-clipboard
                enable-quick-search enable-context-menu enable-status-bar enable-configurator
            ></zentto-grid>

            <Dialog open={Boolean(detailReview)} onClose={() => setDetailReview(null)} maxWidth="sm" fullWidth>
                <DialogTitle>Detalle de reseña</DialogTitle>
                <DialogContent>
                    {detailReview && (
                        <Stack spacing={1} sx={{ mt: 1 }}>
                            <Typography><b>Producto:</b> {detailReview.productName} ({detailReview.productCode})</Typography>
                            <Typography><b>Autor:</b> {detailReview.reviewerName} {detailReview.reviewerEmail ? `(${detailReview.reviewerEmail})` : ''}</Typography>
                            <Typography><b>Rating:</b> {'★'.repeat(detailReview.rating)}</Typography>
                            <Typography><b>Título:</b> {detailReview.title || '(sin título)'}</Typography>
                            <Typography><b>Comentario:</b></Typography>
                            <Typography sx={{ whiteSpace: 'pre-wrap', bgcolor: '#f5f5f5', p: 1, borderRadius: 1 }}>
                                {detailReview.comment}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                                Estado: {detailReview.status} · Creada: {detailReview.createdAt}
                                {detailReview.moderatedAt && ` · Moderada: ${detailReview.moderatedAt} por ${detailReview.moderatorUser ?? '—'}`}
                            </Typography>
                        </Stack>
                    )}
                </DialogContent>
                <DialogActions>
                    {detailReview && detailReview.status !== 'approved' && (
                        <Button
                            color="success"
                            variant="contained"
                            onClick={() => {
                                moderateMut.mutate({ reviewId: detailReview.reviewId, status: 'approved' });
                                setDetailReview(null);
                            }}
                        >
                            Aprobar
                        </Button>
                    )}
                    {detailReview && detailReview.status !== 'rejected' && (
                        <Button
                            color="error"
                            variant="contained"
                            onClick={() => {
                                moderateMut.mutate({ reviewId: detailReview.reviewId, status: 'rejected' });
                                setDetailReview(null);
                            }}
                        >
                            Rechazar
                        </Button>
                    )}
                    <Button onClick={() => setDetailReview(null)}>Cerrar</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}

declare global {
    namespace JSX {
        interface IntrinsicElements {
            'zentto-grid': React.DetailedHTMLProps<
                React.HTMLAttributes<HTMLElement> & Record<string, any>,
                HTMLElement
            >;
        }
    }
}
