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
  const { isAdmin, modulos, isCookieReady } = useAuth();

  const navigationContainer = React.useMemo(() => {
    return buildNavigation(isAdmin, modulos, pathname);
  }, [isAdmin, modulos, pathname]);

  React.useEffect(() => {
    if (status === 'unauthenticated') {
      window.location.href = `${window.location.origin}/authentication/login`;
    }
  }, [status, router]);

  // Esperar a que la cookie zentto_token esté lista antes de renderizar.
  // Sin esto, los componentes del dashboard hacen llamadas API sin cookie
  // → 401 → signOut() → bucle de login.
  if (status === 'loading' || (status === 'authenticated' && !isCookieReady)) {
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

