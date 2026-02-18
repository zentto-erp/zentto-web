'use client';

import * as React from 'react';
import { DashboardLayout } from '@toolpad/core/DashboardLayout';
import { PageContainer } from '@toolpad/core/PageContainer';
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
        {children}
        <Copyright sx={{ mt: 2 }} />
      </PageContainer>
    </DashboardLayout>
  );
}
