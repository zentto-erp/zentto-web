/**
 * BlogPagination — Server Component.
 *
 * Paginación numerada con prev/next. Acepta `baseHref` para construir links
 * (ej. "/blog" → "/blog?page=2"). Si la página actual es la única, no renderiza.
 */

import * as React from "react";
import Box from "@mui/material/Box";
import Stack from "@mui/material/Stack";
import type { LandingTokens } from "../tokens";

export interface BlogPaginationProps {
  tokens: LandingTokens;
  currentPage: number;
  totalPages: number;
  /** Base URL para construir href. Se añade `?page=N`. Default: "/blog". */
  baseHref?: string;
  /** Cantidad máxima de números visibles. Default: 5. */
  maxVisible?: number;
}

function buildHref(base: string, page: number): string {
  if (page <= 1) return base;
  const separator = base.includes("?") ? "&" : "?";
  return `${base}${separator}page=${page}`;
}

function computeRange(
  current: number,
  total: number,
  maxVisible: number,
): number[] {
  if (total <= maxVisible) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }
  const half = Math.floor(maxVisible / 2);
  let start = Math.max(1, current - half);
  let end = Math.min(total, start + maxVisible - 1);
  if (end - start + 1 < maxVisible) {
    start = Math.max(1, end - maxVisible + 1);
  }
  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
}

export function BlogPagination({
  tokens,
  currentPage,
  totalPages,
  baseHref = "/blog",
  maxVisible = 5,
}: BlogPaginationProps) {
  if (totalPages <= 1) return null;

  const range = computeRange(currentPage, totalPages, maxVisible);
  const hasPrev = currentPage > 1;
  const hasNext = currentPage < totalPages;

  const btnSx = (active: boolean) => ({
    minWidth: 40,
    height: 40,
    px: 1.5,
    borderRadius: `${tokens.radius.md}px`,
    border: `1px solid ${
      active ? tokens.color.brand : tokens.color.border
    }`,
    bgcolor: active ? tokens.color.brandSoft : "transparent",
    color: active ? tokens.color.brandLight : tokens.color.textSecondary,
    fontSize: tokens.type.body,
    fontWeight: active ? 700 : 500,
    textDecoration: "none",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    transition: `all ${tokens.motion.micro}`,
    "&:hover": {
      borderColor: tokens.color.brand,
      color: tokens.color.textPrimary,
    },
  });

  return (
    <Box
      component="nav"
      aria-label="Paginación del blog"
      sx={{ mt: 5, display: "flex", justifyContent: "center" }}
    >
      <Stack direction="row" spacing={1} flexWrap="wrap" justifyContent="center">
        {hasPrev ? (
          <Box
            component="a"
            href={buildHref(baseHref, currentPage - 1)}
            aria-label="Página anterior"
            sx={btnSx(false)}
          >
            ← Anterior
          </Box>
        ) : null}

        {range[0] > 1 ? (
          <>
            <Box
              component="a"
              href={buildHref(baseHref, 1)}
              sx={btnSx(false)}
            >
              1
            </Box>
            {range[0] > 2 ? (
              <Box
                sx={{
                  color: tokens.color.textFaint,
                  alignSelf: "center",
                  px: 0.5,
                }}
              >
                …
              </Box>
            ) : null}
          </>
        ) : null}

        {range.map((n) => (
          <Box
            key={n}
            component="a"
            href={buildHref(baseHref, n)}
            aria-current={n === currentPage ? "page" : undefined}
            sx={btnSx(n === currentPage)}
          >
            {n}
          </Box>
        ))}

        {range[range.length - 1] < totalPages ? (
          <>
            {range[range.length - 1] < totalPages - 1 ? (
              <Box
                sx={{
                  color: tokens.color.textFaint,
                  alignSelf: "center",
                  px: 0.5,
                }}
              >
                …
              </Box>
            ) : null}
            <Box
              component="a"
              href={buildHref(baseHref, totalPages)}
              sx={btnSx(false)}
            >
              {totalPages}
            </Box>
          </>
        ) : null}

        {hasNext ? (
          <Box
            component="a"
            href={buildHref(baseHref, currentPage + 1)}
            aria-label="Página siguiente"
            sx={btnSx(false)}
          >
            Siguiente →
          </Box>
        ) : null}
      </Stack>
    </Box>
  );
}
