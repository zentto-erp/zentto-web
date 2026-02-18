'use client';

import * as React from 'react';
import Box from '@mui/material/Box';
import { DashboardLayout } from '@toolpad/core/DashboardLayout';
import { PageContainer } from '@toolpad/core/PageContainer';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { Copyright, SidebarFooterAccount, ToolbarAccountOverride } from '@datqbox/shared-ui';

export default function Layout({ children }: { children: React.ReactNode }) {
  const { data: session, status } = useSession();
  const router = useRouter();

  React.useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/authentication/login');
    }
  }, [status, router]);

  if (status === 'loading') {
    return null;
  }

  if (!session) {
    return null;
  }

  return (
    <DashboardLayout
      defaultSidebarCollapsed
      slots={{
        toolbarAccount: ToolbarAccountOverride,
        sidebarFooter: SidebarFooterAccount,
      }}
    >
      <PageContainer
        maxWidth={false}
        sx={{
          width: '100%',
          maxWidth: '100% !important',
          px: { xs: 1, sm: 2, md: 3 },
          py: 1,
          display: 'flex',
          flexDirection: 'column',
          // Usar calc para garantizar que el contenedor llene toda la ventana
          // 64px = toolbar Toolpad
          height: 'calc(100vh - 64px)',
          minHeight: 0,
          overflow: 'auto',
          '& .MuiContainer-root': {
            maxWidth: '100% !important',
            px: '0 !important',
          },
        }}
      >
        <Box sx={{
          flex: 1,
          minHeight: 0,
          display: 'flex',
          flexDirection: 'column',
          width: '100%',
        }}>
          {children}
        </Box>
        <Copyright sx={{ pt: 0.5, pb: 0.5, flexShrink: 0 }} />
      </PageContainer>
    </DashboardLayout>
  );
}
