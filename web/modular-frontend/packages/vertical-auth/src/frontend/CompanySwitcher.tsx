"use client";

import React, { useState } from "react";
import {
  Box,
  Chip,
  Menu,
  MenuItem,
  Typography,
  type SxProps,
  type Theme,
} from "@mui/material";
import { useActiveCompany } from "./useActiveCompany";

export interface CompanySwitcherProps {
  sx?: SxProps<Theme>;
  /** Label de fallback cuando no hay empresa activa. Default: "Sin empresa". */
  emptyLabel?: string;
}

export function CompanySwitcher({ sx, emptyLabel = "Sin empresa" }: CompanySwitcherProps) {
  const { activeCompany, companyAccesses, switchCompany } = useActiveCompany();
  const [anchor, setAnchor] = useState<HTMLElement | null>(null);

  if (!companyAccesses || companyAccesses.length <= 1) return null;

  const label = activeCompany?.companyCode
    ? activeCompany.branchCode
      ? `${activeCompany.companyCode}/${activeCompany.branchCode}`
      : activeCompany.companyCode
    : emptyLabel;

  return (
    <>
      <Chip
        size="small"
        label={label}
        onClick={(e) => setAnchor(e.currentTarget)}
        sx={{
          cursor: "pointer",
          fontWeight: 600,
          fontSize: "0.75rem",
          ...sx,
        }}
      />
      <Menu
        anchorEl={anchor}
        open={Boolean(anchor)}
        onClose={() => setAnchor(null)}
        slotProps={{ paper: { sx: { minWidth: 280 } } }}
      >
        {companyAccesses.map((access, idx) => {
          const selected =
            access.companyId === activeCompany?.companyId &&
            (access.branchId ?? null) === (activeCompany?.branchId ?? null);
          return (
            <MenuItem
              key={`${access.companyId}:${access.branchId ?? "null"}:${idx}`}
              selected={selected}
              onClick={() => {
                setAnchor(null);
                switchCompany(access.companyId, access.branchId);
              }}
            >
              <Box>
                <Typography variant="body2" fontWeight={600}>
                  {access.companyCode}
                  {access.branchCode ? `/${access.branchCode}` : ""} —{" "}
                  {access.companyName}
                </Typography>
                {access.branchName && (
                  <Typography variant="caption" color="text.secondary">
                    {access.branchName}
                  </Typography>
                )}
              </Box>
            </MenuItem>
          );
        })}
      </Menu>
    </>
  );
}
