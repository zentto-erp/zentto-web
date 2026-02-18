'use client';
import * as React from 'react';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import IconButton from '@mui/material/IconButton';
import TextField from '@mui/material/TextField';
import SearchIcon from '@mui/icons-material/Search';
import Tooltip from '@mui/material/Tooltip';
import { useAuth } from '@/app/authentication/AuthContext';

function ToolbarActionsSearch() {
  return (
    <Stack direction="row" alignItems="center" spacing={1}>
      <Tooltip title="Search" enterDelay={1000}>
        <div>
          <IconButton
            type="button"
            aria-label="search"
            sx={{
              display: { xs: 'inline', md: 'none' },
              ml: { xs: 1, sm: 0 },
            }}
          >
            <SearchIcon />
          </IconButton>
        </div>
      </Tooltip>
      <TextField
        label="Search"
        variant="outlined"
        size="small"
        slotProps={{
          input: {
            endAdornment: (
              <IconButton type="button" aria-label="search" size="small">
                <SearchIcon />
              </IconButton>
            ),
            sx: { pr: 0.5 },
          },
        }}
        sx={{
          display: { xs: 'none', md: 'inline-block' },
          width: { md: '180px', lg: '200px', xl: '250px' },
        }}
      />
    </Stack>
  );
}

export default function AppBarWrapper({ children }: { children: React.ReactNode }) {
  const { isAdmin } = useAuth();

  return (
    <Box sx={{ width: '100%', height: '100%', position: 'relative' }}>
      <Box
        sx={{
          position: 'absolute',
          top: { xs: '4px', sm: 0 },
          right: { xs: '48px', sm: '64px', md: '80px' },
          zIndex: 9999,
          py: { xs: 0.5, sm: 1 },
          px: { xs: 1, sm: 2 },
          display: 'flex',
          justifyContent: 'flex-end',
          alignItems: 'center',
          width: 'auto',
          background: 'transparent',
          gap: 1,
        }}
      >
        <ToolbarActionsSearch />
      </Box>
      {children}
    </Box>
  );
}
