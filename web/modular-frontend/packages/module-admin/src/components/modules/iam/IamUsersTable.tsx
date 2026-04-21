"use client";

import React, { useState, useMemo, useEffect, useRef } from "react";
import { Box, Typography, Button } from "@mui/material";
import { DeleteDialog } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useScopedGridId, useAdminGridRegistration } from "../../../lib/zentto-grid";
import {
  useIamUsers,
  useDeleteIamUser,
  type IamUser,
} from "../../../hooks/useIam";
import IamUserFormDialog from "./IamUserFormDialog";
import IamUserModulesDialog from "./IamUserModulesDialog";
import IamUserCompaniesDialog from "./IamUserCompaniesDialog";

const COLUMNS: ColumnDef[] = [
  { field: "Username", header: "Usuario", width: 180, sortable: true },
  { field: "DisplayName", header: "Nombre", flex: 1, minWidth: 200, sortable: true },
  { field: "Email", header: "Email", width: 240, sortable: true },
  { field: "UserType", header: "Tipo", width: 110, sortable: true, groupable: true },
  {
    field: "IsAdmin",
    header: "Admin",
    width: 90,
    type: "boolean",
  },
  {
    field: "IsActive",
    header: "Estado",
    width: 110,
    statusColors: { true: "success", false: "default" } as Record<string, string>,
    statusVariant: "outlined",
  },
  {
    field: "LastLoginAt",
    header: "Ultimo login",
    width: 160,
    type: "date",
    sortable: true,
  },
  {
    field: "actions",
    header: "Acciones",
    type: "actions" as ColumnDef["type"],
    width: 200,
    pin: "right",
    actions: [
      { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
      { icon: "settings", label: "Modulos", action: "modules", color: "#3b82f6" },
      { icon: "business", label: "Empresas", action: "companies", color: "#8b5cf6" },
      { icon: "delete", label: "Desactivar", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

export default function IamUsersTable() {
  const { data, isLoading } = useIamUsers({ limit: 200 });
  const deleteUser = useDeleteIamUser();

  const gridRef = useRef<HTMLElement>(null);
  const gridId = useScopedGridId("iam-users-main");
  const { ready: layoutReady } = useGridLayoutSync(gridId);
  const { registered } = useAdminGridRegistration(layoutReady);

  const [createOpen, setCreateOpen] = useState(false);
  const [editUser, setEditUser] = useState<IamUser | null>(null);
  const [modulesUser, setModulesUser] = useState<IamUser | null>(null);
  const [companiesUser, setCompaniesUser] = useState<IamUser | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<IamUser | null>(null);

  const rows = useMemo(
    () =>
      (data?.rows ?? []).map((u) => ({
        id: u.UserId,
        ...u,
      })),
    [data?.rows],
  );

  // Bind data al web component
  useEffect(() => {
    const el = gridRef.current as unknown as Record<string, unknown> | null;
    if (!el || !registered) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading, registered]);

  // Listen for action-click + create-click
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const onAction = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action: string; row: IamUser & { id: string } };
      if (!detail?.row) return;
      const user = (data?.rows ?? []).find((u) => u.UserId === detail.row.UserId) ?? null;
      if (!user) return;
      switch (detail.action) {
        case "edit":
          setEditUser(user);
          break;
        case "modules":
          setModulesUser(user);
          break;
        case "companies":
          setCompaniesUser(user);
          break;
        case "delete":
          setDeleteTarget(user);
          break;
      }
    };
    const onCreate = () => setCreateOpen(true);

    el.addEventListener("action-click", onAction);
    el.addEventListener("create-click", onCreate);
    return () => {
      el.removeEventListener("action-click", onAction);
      el.removeEventListener("create-click", onCreate);
    };
  }, [registered, data?.rows]);

  const handleDeleteConfirm = () => {
    if (!deleteTarget) return;
    deleteUser.mutate(deleteTarget.UserId, {
      onSuccess: () => setDeleteTarget(null),
    });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            grid-id={gridId}
            export-filename="iam-usuarios"
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
            create-label="Nuevo Usuario"
          ></zentto-grid>
        )}
      </Box>

      <IamUserFormDialog
        open={createOpen || !!editUser}
        user={editUser}
        onClose={() => {
          setCreateOpen(false);
          setEditUser(null);
        }}
      />

      <IamUserModulesDialog
        user={modulesUser}
        onClose={() => setModulesUser(null)}
      />

      <IamUserCompaniesDialog
        user={companiesUser}
        onClose={() => setCompaniesUser(null)}
      />

      <DeleteDialog
        open={!!deleteTarget}
        itemName={deleteTarget?.DisplayName ?? deleteTarget?.Username ?? ""}
        onConfirm={handleDeleteConfirm}
        onClose={() => setDeleteTarget(null)}
        loading={deleteUser.isPending}
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
