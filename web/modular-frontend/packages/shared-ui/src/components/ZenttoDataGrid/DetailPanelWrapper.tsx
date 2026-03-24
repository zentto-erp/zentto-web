'use client';

import React, { useEffect, useRef } from 'react';
import { Box } from '@mui/material';

interface DetailPanelWrapperProps {
  children: React.ReactNode;
  apiRef: React.MutableRefObject<any>;
  height?: number | 'auto';
}

/**
 * Wraps master-detail panel content with a ResizeObserver that notifies
 * the DataGrid to recalculate row heights when the content's actual size changes.
 *
 * This replaces the unreliable setTimeout + requestAnimationFrame + resetRowHeights
 * hack that caused:
 *   - height=0 on first expand
 *   - panel not showing unless 2 rows expanded
 *   - panel lost at the bottom of large tables
 *
 * How it works:
 *   1. ResizeObserver watches the wrapper div
 *   2. When content renders and has real height → observer fires
 *   3. We call apiRef.current.resetRowHeights() so the grid recalculates
 *   4. Only fires when height actually changes (>1px delta) to avoid loops
 */
export function DetailPanelWrapper({ children, apiRef, height }: DetailPanelWrapperProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const lastHeightRef = useRef(0);
  const resetCount = useRef(0);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const newHeight = entry.contentRect.height;
        // Only reset if height actually changed by more than 1px (avoids infinite loops)
        if (Math.abs(newHeight - lastHeightRef.current) > 1) {
          lastHeightRef.current = newHeight;
          // Cap resets to prevent infinite loops in edge cases
          if (resetCount.current < 10) {
            resetCount.current++;
            try {
              apiRef.current?.resetRowHeights?.();
            } catch { /* noop - grid may be unmounting */ }
          }
        }
      }
    });

    observer.observe(el);

    // Initial measurement trigger — ensures the grid recalculates after the
    // detail content first mounts (even before ResizeObserver fires)
    requestAnimationFrame(() => {
      try {
        apiRef.current?.resetRowHeights?.();
      } catch { /* noop */ }
    });

    return () => {
      observer.disconnect();
      resetCount.current = 0;
    };
  }, [apiRef]);

  return (
    <Box
      ref={containerRef}
      sx={{
        width: '100%',
        minHeight: typeof height === 'number' ? height : 48,
        display: 'flex',
        flexDirection: 'column',
        bgcolor: 'background.paper',
        // Smooth entrance animation
        animation: 'zenttoDetailSlideIn 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
        '@keyframes zenttoDetailSlideIn': {
          from: { opacity: 0, transform: 'translateY(-6px)' },
          to: { opacity: 1, transform: 'translateY(0)' },
        },
        pl: 2,
        pr: 2,
        py: 1.5,
      }}
    >
      {children}
    </Box>
  );
}
