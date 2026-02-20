'use client';
import React from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import InputAdornment from '@mui/material/InputAdornment';
import SearchIcon from '@mui/icons-material/Search';
import Divider from '@mui/material/Divider';

interface ActionProps {
    label: string;
    onClick: () => void;
    disabled?: boolean;
}

interface ContextActionHeaderProps {
    title: string;
    primaryAction?: ActionProps;
    secondaryActions?: ActionProps[];
    onSearch?: (term: string) => void;
    searchPlaceholder?: string;
    breadcrumbs?: React.ReactNode;
}

export default function ContextActionHeader({
    title,
    primaryAction,
    secondaryActions,
    onSearch,
    searchPlaceholder = 'Buscar...',
    breadcrumbs,
}: ContextActionHeaderProps) {
    return (
        <Box sx={{
            width: '100%',
            backgroundColor: '#fff',
            borderBottom: '1px solid #E5E7EB',
            position: 'sticky',
            top: 0,
            zIndex: 10,
        }}>
            {/* Top row: Title and Breadcrumbs */}
            <Box sx={{ px: 3, pt: 2, pb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                {breadcrumbs ? breadcrumbs : (
                    <Typography variant="h6" color="primary.main">
                        {title}
                    </Typography>
                )}
            </Box>

            {/* Bottom row: Actions & Search */}
            <Box sx={{
                px: 3,
                pb: 1.5,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 2
            }}>
                <Box sx={{ display: 'flex', gap: 1 }}>
                    {primaryAction && (
                        <Button
                            variant="contained"
                            color="primary"
                            onClick={primaryAction.onClick}
                            disabled={primaryAction.disabled}
                            disableElevation
                        >
                            {primaryAction.label}
                        </Button>
                    )}
                    {secondaryActions?.map((act, index) => (
                        <Button
                            key={index}
                            variant="contained"
                            color="secondary"
                            onClick={act.onClick}
                            disabled={act.disabled}
                            disableElevation
                            sx={{ color: '#111827', backgroundColor: '#E7E9ED', '&:hover': { backgroundColor: '#D1D5DB' } }}
                        >
                            {act.label}
                        </Button>
                    ))}
                </Box>

                {onSearch && (
                    <Box sx={{ minWidth: 300 }}>
                        <TextField
                            size="small"
                            placeholder={searchPlaceholder}
                            fullWidth
                            onChange={(e) => onSearch(e.target.value)}
                            InputProps={{
                                startAdornment: (
                                    <InputAdornment position="start">
                                        <SearchIcon fontSize="small" />
                                    </InputAdornment>
                                ),
                            }}
                            sx={{
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: 12,
                                    backgroundColor: '#F3F4F6'
                                }
                            }}
                        />
                    </Box>
                )}
            </Box>
        </Box>
    );
}
