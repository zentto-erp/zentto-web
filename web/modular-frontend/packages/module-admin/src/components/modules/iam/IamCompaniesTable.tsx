"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import { Box, Typography } from "@mui/material";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";
import {
  useIamCompanies,
  useCreateIamCompany,
  type IamCompany,
} from "../../../hooks/useIam";
import IamCompanyFormDialog from "./IamCompanyFormDialog";

const COLUMNS: ColumnDef[] = [
  { field: "Code", header: "Codigo", width: 120, sortable: true },
  { field: "Name", header: "Empresa", flex: 1, minWidth: 220, sortable: true },
  { field: "TaxId", header: "RIF/RFC", width: 140 },
  { field: "CountryCode", header: "Pais", width: 80, groupable: true },
  { field: "Currency", header: "Moneda", width: 90, groupable: true },
  { field: "TimeZone", header: "Zona horaria", width: 180 },
  { field: "Email", header: "Email", width: 220 },
  { field: "Phone", header: "Telefono", width: 140 },
  {
    field: "IsActive",
    header: "Estado",
    width: 100,
    statusColors: { true: "success", false: "default" } as Record<string, string>,
    statusVariant: "outlined",
  },
];

export default function IamCompaniesTable() {
  const { data, isLoading } = useIamCompanies();

  const gridRef = useRef<HTMLElement>(null);
  const gridId = useScopedGridId("iam-companies-main");
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);

  const [createOpen, setCreateOpen] = useState(false);

  const rows = useMemo(
    () =>
      (data?.rows ?? []).map((c: IamCompany) => ({
        id: c.CompanyId,
        ...c,
      })),
    [data?.rows],
  );

  useEffect(() => {
    const el = gridRef.current as unknown as Record<string, unknown> | null;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const onCreate = () => setCreateOpen(true);
    el.addEventListener("create-click", onCreate);
    return () => el.removeEventListener("create-click", onCreate);
  }, [registered]);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Typography variant="h5" fontWeight={600} sx={{ mb: 3 }}>
        Empresas (multi-tenant)
      </Typography>

      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            export-filename="iam-empresas"
            height="100%"
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-create
            create-label="Nueva Empresa"
          ></zentto-grid>
        )}
      </Box>

      <IamCompanyFormDialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
      />
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
