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
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                textTransform: 'none',
                py: 3,
                '&:hover': {
                    bgcolor: '#6a4d78',
                },
                '&:disabled': {
                    bgcolor: '#cccccc',
                    color: '#888888',
                },
            }}
        >
            <NavigateNextIcon sx={{ fontSize: 32, mb: 0.5 }} />
            <Typography variant="h6" fontWeight="bold">
                Pago
            </Typography>
        </Button>
    );
}
