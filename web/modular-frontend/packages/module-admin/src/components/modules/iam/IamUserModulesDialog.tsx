"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Stack,
  Tabs,
  Tab,
  Box,
  Checkbox,
  FormControlLabel,
  Typography,
  CircularProgress,
  Alert,
} from "@mui/material";
import {
  useIamApps,
  useIamAppModules,
  useIamUserModules,
  useSetIamUserModules,
  type IamUser,
  type IamModule,
} from "../../../hooks/useIam";

interface Props {
  user: IamUser | null;
  onClose: () => void;
}

export default function IamUserModulesDialog({ user, onClose }: Props) {
  const open = !!user;
  const { data: appsData } = useIamApps();
  const apps = appsData?.rows ?? [];

  const [activeApp, setActiveApp] = useState<string>("");
  useEffect(() => {
    if (open && apps.length > 0 && !activeApp) {
      // primer app que sea zentto-erp si existe, sino la primera
      const erp = apps.find((a) => a.ClientId === "zentto-erp");
      setActiveApp(erp?.ClientId ?? apps[0].ClientId);
    }
    if (!open) {
      setActiveApp("");
    }
  }, [open, apps, activeApp]);

  const { data: appModulesData, isLoading: loadingApp } = useIamAppModules(activeApp || undefined);
  const { data: userModulesData, isLoading: loadingUser } = useIamUserModules(
    user?.UserId,
    activeApp || undefined,
  );

  const setMutation = useSetIamUserModules();

  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);

  // Cargar la seleccion inicial cuando llegan los datos del user
  useEffect(() => {
    if (!userModulesData?.rows) return;
    setSelected(new Set(userModulesData.rows.map((m) => m.Code)));
  }, [userModulesData?.rows, activeApp]);

  const allModules = appModulesData?.rows ?? [];
  const grouped = useMemo(() => {
    const map = new Map<string, IamModule[]>();
    for (const m of allModules) {
      const cat = m.Category || "Otros";
      if (!map.has(cat)) map.set(cat, []);
      map.get(cat)!.push(m);
    }
    return Array.from(map.entries());
  }, [allModules]);

  const toggle = (code: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(code)) next.delete(code);
      else next.add(code);
      return next;
    });
  };

  const toggleAll = (modules: IamModule[]) => {
    const allSelected = modules.every((m) => selected.has(m.Code));
    setSelected((prev) => {
      const next = new Set(prev);
      for (const m of modules) {
        if (allSelected) next.delete(m.Code);
        else next.add(m.Code);
      }
      return next;
    });
  };

  const handleSave = async () => {
    if (!user || !activeApp) return;
    setError(null);
    try {
      await setMutation.mutateAsync({
        userId: user.UserId,
        appId: activeApp,
        moduleCodes: Array.from(selected),
      });
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error al guardar");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        Modulos de {user?.DisplayName ?? user?.Username}
      </DialogTitle>
      <DialogContent>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Tabs
          value={activeApp}
          onChange={(_, v) => setActiveApp(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ borderBottom: 1, borderColor: "divider", mb: 2 }}
        >
          {apps.map((a) => (
            <Tab key={a.ClientId} label={a.Name} value={a.ClientId} />
          ))}
        </Tabs>

        {(loadingApp || loadingUser) ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <Stack spacing={3}>
            {grouped.map(([category, mods]) => {
              const allSelected = mods.every((m) => selected.has(m.Code));
              const someSelected = mods.some((m) => selected.has(m.Code));
              return (
                <Box key={category}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        checked={allSelected}
                        indeterminate={!allSelected && someSelected}
                        onChange={() => toggleAll(mods)}
                      />
                    }
                    label={
                      <Typography variant="subtitle2" fontWeight={600} sx={{ textTransform: "uppercase" }}>
                        {category}
                      </Typography>
                    }
                  />
                  <Box sx={{ pl: 4, display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 0.5 }}>
                    {mods.map((m) => (
                      <FormControlLabel
                        key={m.ModuleId}
                        control={
                          <Checkbox
                            size="small"
                            checked={selected.has(m.Code)}
                            onChange={() => toggle(m.Code)}
                          />
                        }
                        label={m.Name}
                      />
                    ))}
                  </Box>
                </Box>
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
          disabled={setMutation.isPending || loadingApp || loadingUser}
        >
          Guardar
        </Button>
      </DialogActions>
    </Dialog>
  );
}
