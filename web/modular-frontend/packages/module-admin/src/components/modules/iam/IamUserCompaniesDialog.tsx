"use client";

import React, { useEffect, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Stack,
  Box,
  Typography,
  CircularProgress,
  Alert,
  Checkbox,
  Radio,
  FormControlLabel,
  Paper,
} from "@mui/material";
import {
  useIamCompanies,
  useIamUserCompanies,
  useSetIamUserCompanies,
  type IamUser,
} from "../../../hooks/useIam";

interface Props {
  user: IamUser | null;
  onClose: () => void;
}

interface AccessRow {
  companyId: number;
  branchId: number | null;
  enabled: boolean;
  isDefault: boolean;
}

export default function IamUserCompaniesDialog({ user, onClose }: Props) {
  const open = !!user;
  const { data: companiesData, isLoading: loadingCompanies } = useIamCompanies();
  const { data: userCompaniesData, isLoading: loadingUser } = useIamUserCompanies(user?.UserId);
  const setMutation = useSetIamUserCompanies();

  const [accesses, setAccesses] = useState<AccessRow[]>([]);
  const [error, setError] = useState<string | null>(null);

  // Inicializar la matriz de accesos cuando llegan los datos
  useEffect(() => {
    if (!companiesData?.rows || !userCompaniesData?.rows) return;
    const userMap = new Map(
      userCompaniesData.rows.map((a) => [`${a.companyId}:${a.branchId ?? "null"}`, a]),
    );
    // Por ahora una row por empresa (sin sucursal). Sucursales se agregaran despues.
    const rows: AccessRow[] = companiesData.rows.map((c) => {
      const key = `${c.CompanyId}:null`;
      const existing = userMap.get(key);
      return {
        companyId: c.CompanyId,
        branchId: null,
        enabled: !!existing,
        isDefault: existing?.isDefault ?? false,
      };
    });
    setAccesses(rows);
  }, [companiesData?.rows, userCompaniesData?.rows]);

  const toggle = (companyId: number) => {
    setAccesses((prev) =>
      prev.map((a) =>
        a.companyId === companyId ? { ...a, enabled: !a.enabled } : a,
      ),
    );
  };

  const setDefault = (companyId: number) => {
    setAccesses((prev) =>
      prev.map((a) => ({
        ...a,
        isDefault: a.companyId === companyId,
      })),
    );
  };

  const handleSave = async () => {
    if (!user) return;
    setError(null);
    try {
      await setMutation.mutateAsync({
        userId: user.UserId,
        accesses: accesses
          .filter((a) => a.enabled)
          .map((a) => ({
            companyId: a.companyId,
            branchId: a.branchId ?? null,
            isDefault: a.isDefault,
          })),
      });
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al guardar");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        Empresas de {user?.DisplayName ?? user?.Username}
      </DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        {(loadingCompanies || loadingUser) ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Stack spacing={1.5}>
            <Typography variant="body2" color="text.secondary">
              Marca las empresas a las que el usuario tiene acceso. Selecciona una como default.
            </Typography>
            {companiesData?.rows.map((c) => {
              const access = accesses.find((a) => a.companyId === c.CompanyId);
              return (
                <Paper
                  key={c.CompanyId}
                  variant="outlined"
                  sx={{
                    p: 1.5,
                    display: "flex",
                    alignItems: "center",
                    gap: 1.5,
                  }}
                >
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={access?.enabled ?? false}
                        onChange={() => toggle(c.CompanyId)}
                      />
                    }
                    label={
                      <Box>
                        <Typography variant="subtitle2">{c.Name}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {c.Code} · {c.CountryCode} · {c.Currency}
                        </Typography>
                      </Box>
                    }
                    sx={{ flex: 1, m: 0 }}
                  />
                  <FormControlLabel
                    control={
                      <Radio
                        checked={access?.isDefault ?? false}
                        disabled={!access?.enabled}
                        onChange={() => setDefault(c.CompanyId)}
                      />
                    }
                    label="Default"
                    labelPlacement="start"
                  />
                </Paper>
              );
            })}
          </Stack>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={setMutation.isPending}>
          Cancelar
        </Button>
        <Button
          variant="contained"
          onClick={handleSave}
          disabled={setMutation.isPending || loadingCompanies || loadingUser}
        >
          Guardar
        </Button>
      </DialogActions>
    </Dialog>
  );
}
