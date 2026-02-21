'use client';

import React, { useEffect, useState } from 'react';
import { Box } from '@mui/material';
import { VistaCocina } from '@/components/VistaCocina';
import { useRestaurante, ComandaCocina } from '@/hooks/useRestaurante';

export default function CocinaPage() {
    const { getComandasPendientes, actualizarMesa, ambientes } = useRestaurante();
    const [comandas, setComandas] = useState<ComandaCocina[]>([]);

    // Actualizar comandas cada 5 segundos
    useEffect(() => {
        const interval = setInterval(() => {
            setComandas(getComandasPendientes());
        }, 5000);

        // Carga inicial
        setComandas(getComandasPendientes());

        return () => clearInterval(interval);
    }, [getComandasPendientes, ambientes]);

    const handleMarcarListo = (comandaId: string) => {
        // Encontrar el item y marcarlo como listo
        const [pedidoId, itemId] = comandaId.split('-');
        
        // Actualizar el estado del item
        // En una app real, esto llamaría a la API
        
        // Recargar comandas
        setComandas(getComandasPendientes());
    };

    return (
        <Box sx={{ height: 'calc(100vh - 100px)' }}>
            <VistaCocina 
                comandas={comandas}
                onMarcarListo={handleMarcarListo}
            />
        </Box>
    );
}
