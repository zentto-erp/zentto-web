'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
    Box, Stack, Typography, Button, TextField, MenuItem, Chip,
    Paper, CircularProgress, Switch, FormControlLabel, IconButton,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import SearchIcon from '@mui/icons-material/Search';
import type { ColumnDef } from '@zentto/datagrid-core';
import { useGridLayoutSync } from '@zentto/shared-api';
import {
    useAdminProducts,
    useDeleteAdminProduct,
    usePublishToggleAdminProduct,
    useAdminCategories,
    useAdminBrands,
    buildEcommerceGridId,
    useEcommerceGridId,
    useEcommerceGridRegistration,
} from '@zentto/module-ecommerce';

const COLUMNS: ColumnDef[] = [
    {
        field: 'imageUrl',
        header: '',
        width: 60,
        renderCell: (params: any) => {
            const value = params?.value;
            return value
                ? `<img src="${value}" alt="thumb" style="width:40px;height:40px;object-fit:cover;border-radius:4px;" />`
                : `<div style="width:40px;height:40px;background:#eee;border-radius:4px;"></div>`;
        },
    },
    { field: 'code', header: 'Código', width: 120, sortable: true },
    { field: 'name', header: 'Nombre', flex: 1, minWidth: 200, sortable: true },
    { field: 'categoryName', header: 'Categoría', width: 140, sortable: true, groupable: true },
    { field: 'brandName', header: 'Marca', width: 120, sortable: true, groupable: true },
    { field: 'price', header: 'Precio', width: 110, type: 'number', currency: 'USD' },
    { field: 'stock', header: 'Stock', width: 90, type: 'number' },
    {
        field: 'isPublished',
        header: 'Publicado',
        width: 110,
        sortable: true,
        groupable: true,
        statusColors: { true: 'success', false: 'default' },
        statusVariant: 'outlined',
    },
    {
        field: 'actions',
        header: 'Acciones',
        type: 'actions',
        width: 140,
        pin: 'right',
        actions: [
            { icon: 'edit', label: 'Editar', action: 'edit', color: '#6b7280' },
            { icon: 'publish', label: 'Publicar/ocultar', action: 'toggle', color: '#10b981' },
            { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#ef4444' },
        ],
    },
];

const GRID_ID = buildEcommerceGridId('admin-productos', 'main');

export default function AdminProductosPage() {
    const router = useRouter();
    const gridRef = useRef<any>(null);
    const { ready: gridLayoutReady } = useGridLayoutSync(GRID_ID);
    useEcommerceGridId(gridRef, GRID_ID);
    const { registered } = useEcommerceGridRegistration(gridLayoutReady);

    const [search, setSearch] = useState('');
    const [category, setCategory] = useState('');
    const [brand, setBrand] = useState('');
    const [published, setPublished] = useState<'' | 'published' | 'draft'>('');
    const [lowStockOnly, setLowStockOnly] = useState(false);

    const { data: catData } = useAdminCategories();
    const { data: brandData } = useAdminBrands();

    const { data, isLoading } = useAdminProducts({
        search: search || undefined,
        category: category || undefined,
        brand: brand || undefined,
        published: published || undefined,
        lowStockOnly,
        limit: 50,
    });

    const rows = useMemo(
        () => (data?.rows ?? []).map((r) => ({ ...r, id: r.code })),
        [data]
    );

    const deleteMut = useDeleteAdminProduct();
    const publishMut = usePublishToggleAdminProduct();

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
            if (action === 'edit') {
                router.push(`/admin/productos/${encodeURIComponent(row.code)}/editar`);
            } else if (action === 'toggle') {
                publishMut.mutate({ code: row.code });
            } else if (action === 'delete') {
                if (window.confirm(`¿Eliminar producto "${row.name}"? Esta acción es reversible (soft delete).`)) {
                    deleteMut.mutate(row.code);
                }
            }
        };
        const onCreate = () => router.push('/admin/productos/nuevo');

        el.addEventListener('action-click', onAction);
        el.addEventListener('create-click', onCreate);
        return () => {
            el.removeEventListener('action-click', onAction);
            el.removeEventListener('create-click', onCreate);
        };
    }, [registered, router, publishMut, deleteMut]);

    if (!registered) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
                <Typography variant="h5" fontWeight={700}>
                    Productos
                </Typography>
                <Button
                    variant="contained"
                    startIcon={<AddIcon />}
                    onClick={() => router.push('/admin/productos/nuevo')}
                    sx={{ bgcolor: '#ff9900', '&:hover': { bgcolor: '#e68a00' } }}
                >
                    Nuevo producto
                </Button>
            </Stack>

            <Paper sx={{ p: 2, mb: 2 }}>
                <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems="center">
                    <TextField
                        size="small"
                        placeholder="Buscar por código, nombre…"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        InputProps={{ startAdornment: <SearchIcon fontSize="small" sx={{ mr: 1, color: '#999' }} /> }}
                        sx={{ flex: 1, minWidth: 220 }}
                    />
                    <TextField
                        size="small"
                        select
                        label="Categoría"
                        value={category}
                        onChange={(e) => setCategory(e.target.value)}
                        sx={{ minWidth: 170 }}
                    >
                        <MenuItem value="">(Todas)</MenuItem>
                        {(catData?.rows ?? []).map((c: any) => (
                            <MenuItem key={c.code} value={c.code}>{c.name}</MenuItem>
                        ))}
                    </TextField>
                    <TextField
                        size="small"
                        select
                        label="Marca"
                        value={brand}
                        onChange={(e) => setBrand(e.target.value)}
                        sx={{ minWidth: 170 }}
                    >
                        <MenuItem value="">(Todas)</MenuItem>
                        {(brandData?.rows ?? []).map((b: any) => (
                            <MenuItem key={b.code} value={b.code}>{b.name}</MenuItem>
                        ))}
                    </TextField>
                    <TextField
                        size="small"
                        select
                        label="Estado"
                        value={published}
                        onChange={(e) => setPublished(e.target.value as any)}
                        sx={{ minWidth: 160 }}
                    >
                        <MenuItem value="">Todos</MenuItem>
                        <MenuItem value="published">Publicados</MenuItem>
                        <MenuItem value="draft">Borradores</MenuItem>
                    </TextField>
                    <FormControlLabel
                        control={<Switch checked={lowStockOnly} onChange={(e) => setLowStockOnly(e.target.checked)} />}
                        label="Stock bajo"
                    />
                </Stack>
            </Paper>

            <zentto-grid
                ref={gridRef}
                export-filename="admin-productos"
                height="calc(100vh - 280px)"
                enable-create
                create-label="Nuevo producto"
                enable-toolbar
                enable-header-menu
                enable-header-filters
                enable-clipboard
                enable-quick-search
                enable-context-menu
                enable-status-bar
                enable-configurator
            ></zentto-grid>

            <Stack direction="row" spacing={1} sx={{ mt: 1 }}>
                <Chip label={`Total: ${data?.total ?? 0}`} size="small" />
                {publishMut.isPending && <Chip label="Actualizando…" size="small" color="warning" />}
                {deleteMut.isPending && <Chip label="Eliminando…" size="small" color="error" />}
            </Stack>
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
