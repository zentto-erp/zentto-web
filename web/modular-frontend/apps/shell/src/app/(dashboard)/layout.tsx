'use client';

import * as React from 'react';
import { useSession } from 'next-auth/react';
import { useRouter, usePathname } from 'next/navigation';
import { OdooLayout } from '@zentto/shared-ui';
import { useAuth } from '@zentto/shared-auth';
import { buildNavigation } from '../../lib/navigation';

export default function Layout({ children }: { children: React.ReactNode }) {
  const { data: session, status } = useSession();
  const router = useRouter();
  const pathname = usePathname();
  const { isAdmin, modulos } = useAuth();

  const navigationContainer = React.useMemo(() => {
    return buildNavigation(isAdmin, modulos, pathname);
  }, [isAdmin, modulos, pathname]);

  React.useEffect(() => {
    if (status === 'unauthenticated') {
      window.location.href = `${window.location.origin}/authentication/login`;
    }
  }, [status, router]);

  if (status === 'loading') {
    return null;
  }

  if (!session) {
    return null;
  }

  return (
    <OdooLayout navigationFields={navigationContainer}>
      {children}
    </OdooLayout>
  );
}

