'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
    Box, Grid, Typography, Drawer, IconButton, useMediaQuery, useTheme,
    Select, MenuItem, FormControl, Chip, Alert,
} from '@mui/material';
import FilterListIcon from '@mui/icons-material/FilterList';
import SearchIcon from '@mui/icons-material/Search';
import {
    useProductList,
    useStoreSearch,
    useCategoryList,
    useBrandList,
    ProductGrid,
    CategorySidebar,
    SearchBar,
} from '@zentto/module-ecommerce';

interface SidebarFilters {
    category?: string;
    brand?: string;
    priceMin?: number;
    priceMax?: number;
    minRating?: number;
    inStockOnly?: boolean;
}

export default function ProductosPage() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('md'));

    const [search, setSearch] = useState(searchParams.get('search') ?? '');
    const [sortBy, setSortBy] = useState('name');
    const [page, setPage] = useState(1);
    const [drawerOpen, setDrawerOpen] = useState(false);

    // Filtro por merchant (marketplace) — proviene del query string ?merchant=slug
    const merchantSlug = searchParams.get('merchant') ?? undefined;

    const [filters, setFilters] = useState<SidebarFilters>({
        category: searchParams.get('category') ?? undefined,
        brand: undefined,
        priceMin: undefined,
        priceMax: undefined,
        minRating: undefined,
        inStockOnly: true,
    });

    const handleFiltersChange = (partial: Partial<SidebarFilters>) => {
        setFilters((prev) => ({ ...prev, ...partial }));
        setPage(1);
    };

    const hasFtsQuery = search.trim().length > 0;

    const { data: ftsData, isLoading: ftsLoading } = useStoreSearch({
        query: search,
        category: filters.category,
        brand: filters.brand,
        page,
        limit: 24,
        enabled: hasFtsQuery,
    });

    const { data: products, isLoading: listLoading } = useProductList({
        search: hasFtsQuery ? undefined : search,
        category: filters.category,
        brand: filters.brand,
        priceMin: filters.priceMin,
        priceMax: filters.priceMax,
        minRating: filters.minRating,
        inStockOnly: filters.inStockOnly,
        sortBy,
        page,
        limit: 24,
        merchant: merchantSlug,
    });

    const { data: categories = [], isLoading: loadingCats } = useCategoryList();
    const { data: brands = [] } = useBrandList();

    const handleSearch = (q: string) => {
        setSearch(q);
        setPage(1);
    };

    const ftsProducts = (ftsData?.rows ?? []).map((h) => ({
        id: 0,
        code: h.code,
        name: h.name,
        fullDescription: h.highlight || undefined,
        category: h.category ?? undefined,
        brand: h.brand ?? undefined,
        price: h.price,
        stock: h.stock,
        taxRate: 0,
        imageUrl: h.imageUrl,
        avgRating: h.rank,
        reviewCount: undefined,
    }));

    const displayProducts = hasFtsQuery ? ftsProducts : (products?.rows ?? []);
    const displayTotal = hasFtsQuery ? (ftsData?.total ?? 0) : (products?.total ?? 0);
    const isLoading = hasFtsQuery ? ftsLoading : listLoading;

    const sidebar = (
        <CategorySidebar
            categories={categories}
            brands={brands}
            filters={filters}
            onFiltersChange={handleFiltersChange}
            loading={loadingCats}
        />
    );

    return (
        <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3, flexWrap: 'wrap' }}>
                <Typography variant="h5" sx={{ flexShrink: 0 }}>Productos</Typography>
                <Box sx={{ flex: 1, minWidth: 200 }}>
                    <SearchBar value={search} onSearch={handleSearch} />
                </Box>
                {!hasFtsQuery && (
                    <FormControl size="small" sx={{ minWidth: 180 }}>
                        <Select
                            value={sortBy}
                            onChange={(e) => { setSortBy(e.target.value); setPage(1); }}
                            sx={{
                                fontSize: 13,
                                bgcolor: '#fff',
                                borderRadius: '8px',
                                '& .MuiOutlinedInput-notchedOutline': { borderColor: '#d5d9d9' },
                            }}
                        >
                            <MenuItem value="name">Ordenar: A-Z</MenuItem>
                            <MenuItem value="price_asc">Precio: menor a mayor</MenuItem>
                            <MenuItem value="price_desc">Precio: mayor a menor</MenuItem>
                            <MenuItem value="rating">Mejor calificados</MenuItem>
                            <MenuItem value="newest">Mas recientes</MenuItem>
                            <MenuItem value="bestseller">Mas populares</MenuItem>
                        </Select>
                    </FormControl>
                )}
                {isMobile && (
                    <IconButton onClick={() => setDrawerOpen(true)}>
                        <FilterListIcon />
                    </IconButton>
                )}
            </Box>

            {hasFtsQuery && (
                <Alert
                    severity="info"
                    icon={<SearchIcon />}
                    sx={{ mb: 2 }}
                    action={
                        <Chip
                            label="Limpiar búsqueda"
                            size="small"
                            onClick={() => { setSearch(''); setPage(1); }}
                            sx={{ cursor: 'pointer' }}
                        />
                    }
                >
                    Resultados de búsqueda para: <strong>{search}</strong>
                </Alert>
            )}

            {merchantSlug && (
                <Alert
                    severity="info"
                    sx={{ mb: 2 }}
                    action={
                        <Chip
                            label="Ver todo el catálogo"
                            size="small"
                            onClick={() => { router.push('/productos'); }}
                            sx={{ cursor: 'pointer' }}
                        />
                    }
                >
                    Mostrando solo productos del vendedor: <strong>{merchantSlug}</strong>
                </Alert>
            )}

            <Grid container spacing={3}>
                {!isMobile && (
                    <Grid md={3} lg={2}>
                        {sidebar}
                    </Grid>
                )}
                <Grid xs={12} md={9} lg={10}>
                    <ProductGrid
                        products={displayProducts}
                        total={displayTotal}
                        page={page}
                        limit={24}
                        loading={isLoading}
                        onPageChange={setPage}
                        onViewDetail={(code) => router.push(`/productos/${code}`)}
                    />
                </Grid>
            </Grid>

            {isMobile && (
                <Drawer anchor="left" open={drawerOpen} onClose={() => setDrawerOpen(false)}>
                    <Box sx={{ width: 280, pt: 2, px: 1 }}>{sidebar}</Box>
                </Drawer>
            )}
        </Box>
    );
}
