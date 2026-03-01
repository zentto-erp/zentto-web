'use client';

import * as React from 'react';
import { DashboardLayout } from '@toolpad/core/DashboardLayout';
import { PageContainer } from '@toolpad/core/PageContainer';
import { Box, Chip, Stack } from '@mui/material';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import Copyright from '@/app/components/Copyright';
import SidebarFooterAccount, { ToolbarAccountOverride } from '@/app/(dashboard)/SidebarFooterAccount';

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

  // @ts-ignore extended session fields from auth.ts callbacks
  const activeCompany = session?.company as
    | { companyCode?: string; companyName?: string; branchCode?: string; branchName?: string }
    | undefined;
  const companyLabel = activeCompany
    ? `${activeCompany.companyCode ?? ''}/${activeCompany.branchCode ?? ''} - ${activeCompany.companyName ?? ''}`
    : 'Sin empresa activa';
  const dbName = process.env.NEXT_PUBLIC_DB_NAME || 'DatqBoxWeb';

  return (
    <DashboardLayout
      defaultSidebarCollapsed
      slots={{
        toolbarAccount: ToolbarAccountOverride,
        sidebarFooter: SidebarFooterAccount,
      }}
    >
      <PageContainer
        sx={{
          height: '100vh',
          width: '100%',
          maxWidth: '100% !important',
          p: 1,
          overflow: 'auto',
          display: 'flex',
          flexDirection: 'column',
          '& > *': { width: '100%' },
        }}
      >
        <Box
          sx={{
            mb: 1,
            px: 1,
            py: 0.5,
            borderRadius: 1,
            border: '1px solid',
            borderColor: 'divider',
            bgcolor: 'background.paper',
          }}
        >
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1}>
            <Chip size="small" color="primary" variant="outlined" label={`Empresa: ${companyLabel}`} />
            <Chip size="small" variant="outlined" label={`BD: ${dbName}`} />
          </Stack>
        </Box>
        {children}
        <Copyright sx={{ mt: 2 }} />
      </PageContainer>
    </DashboardLayout>
  );
}
