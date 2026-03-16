'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
    Box, Grid, Typography, Drawer, IconButton, useMediaQuery, useTheme,
    Select, MenuItem, FormControl,
} from '@mui/material';
import FilterListIcon from '@mui/icons-material/FilterList';
import {
    useProductList,
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

    const { data: products, isLoading } = useProductList({
        search,
        category: filters.category,
        brand: filters.brand,
        priceMin: filters.priceMin,
        priceMax: filters.priceMax,
        minRating: filters.minRating,
        inStockOnly: filters.inStockOnly,
        sortBy,
        page,
        limit: 24,
    });
    const { data: categories = [], isLoading: loadingCats } = useCategoryList();
    const { data: brands = [] } = useBrandList();

    const handleSearch = (q: string) => {
        setSearch(q);
        setPage(1);
    };

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
                {isMobile && (
                    <IconButton onClick={() => setDrawerOpen(true)}>
                        <FilterListIcon />
                    </IconButton>
                )}
            </Box>

            <Grid container spacing={3}>
                {!isMobile && (
                    <Grid md={3} lg={2}>
                        {sidebar}
                    </Grid>
                )}
                <Grid xs={12} md={9} lg={10}>
                    <ProductGrid
                        products={products?.rows ?? []}
                        total={products?.total ?? 0}
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
