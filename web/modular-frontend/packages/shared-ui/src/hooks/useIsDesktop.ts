'use client';

import { useEffect, useState } from 'react';

declare global {
  interface Window {
    zenttoDesktop?: { isDesktop?: boolean };
  }
}

export function useIsDesktop(): boolean {
  const [isDesktop, setIsDesktop] = useState(false);

  useEffect(() => {
    setIsDesktop(!!window.zenttoDesktop?.isDesktop);
  }, []);

  return isDesktop;
}
