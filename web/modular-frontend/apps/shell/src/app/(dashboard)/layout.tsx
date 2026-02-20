'use client';

import * as React from 'react';
import { useSession } from 'next-auth/react';
import { useRouter, usePathname } from 'next/navigation';
import { OdooLayout } from '@datqbox/shared-ui';
import { useAuth } from '@datqbox/shared-auth';
import { buildNavigation } from '../layout';

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
    <OdooLayout navigationFields={navigationContainer}>
      {children}
    </OdooLayout>
  );
}

