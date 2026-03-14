'use client';

import React from 'react';
import {
    Button,
    Box,
    Typography,
} from '@mui/material';
import dynamic from 'next/dynamic';

const NavigateNextIcon = dynamic(() => import('@mui/icons-material/NavigateNext'), { ssr: false });

interface PosPaymentButtonProps {
    total: number;
    onClick: () => void;
    disabled?: boolean;
}

export function PosPaymentButton({ total, onClick, disabled }: PosPaymentButtonProps) {
    return (
        <Button
            onClick={onClick}
            disabled={disabled || total <= 0}
            sx={{
                width: '100%',
                height: '100%',
                borderRadius: 0,
                bgcolor: '#7B5A8B', // Color púrpura/morado tipo Odoo
                color: '#fff',
                display: 'flex',
                flexDirection: 'row',
                alignItems: 'center',
                justifyContent: 'center',
                textTransform: 'none',
                gap: 0.75,
                py: 0.5,
                minHeight: { xs: 42, md: 46 },
                '&:hover': {
                    bgcolor: '#6a4d78',
                },
                '&:disabled': {
                    bgcolor: '#cccccc',
                    color: '#888888',
                },
            }}
        >
            <NavigateNextIcon sx={{ fontSize: { xs: 20, md: 22 }, mb: 0 }} />
            <Typography variant="subtitle1" fontWeight="bold" sx={{ fontSize: { xs: '0.95rem', md: '1rem' }, lineHeight: 1 }}>
                Pago
            </Typography>
        </Button>
    );
}
