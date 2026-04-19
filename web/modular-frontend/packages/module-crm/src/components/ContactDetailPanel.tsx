"use client";

import React, { useState } from "react";
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardActionArea,
  CardContent,
  Chip,
  Divider,
  IconButton,
  Paper,
  Skeleton,
  Stack,
  Tab,
  Tabs,
  Typography,
  alpha,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import EmailIcon from "@mui/icons-material/Email";
import PhoneIcon from "@mui/icons-material/Phone";
import SmartphoneIcon from "@mui/icons-material/Smartphone";
import LinkIcon from "@mui/icons-material/Link";
import BusinessIcon from "@mui/icons-material/Business";
import StarIcon from "@mui/icons-material/Star";
import { formatCurrency } from "@zentto/shared-api";
import { useDrawerQueryParam, useToast } from "@zentto/shared-ui";
import { useContact, usePromoteToCustomer, type Contact } from "../hooks/useContacts";
import { useDealsList, type Deal } from "../hooks/useDeals";

interface ContactDetailPanelProps {
  contactId: number;
  onClose?: () => void;
  onEdit?: () => void;
}

function formatDate(d: string | null | undefined): string {
  if (!d) return "—";
  try {
    return new Date(d).toLocaleDateString("es", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return d;
  }
}

export default function ContactDetailPanel({
  contactId,
  onClose,
  onEdit,
}: ContactDetailPanelProps) {
  const { data, isLoading } = useContact(contactId);
  const contact = (data as any)?.data ?? (data as any) ?? null;
  const { showToast } = useToast();
  const [tab, setTab] = useState("overview");
  const promote = usePromoteToCustomer();

  const companyDrawer = useDrawerQueryParam("company");
  const dealDrawer = useDrawerQueryParam("deal");

  // Deals relacionados (contactId filter)
  const { data: dealsData } = useDealsList({ contactId, limit: 50 });
  const deals: Deal[] =
    (dealsData as any)?.data ?? (dealsData as any)?.rows ?? dealsData ?? [];

  const contactRow = contact as Contact | null;

  const handlePromote = () => {
    if (!contactRow) return;
    promote.mutate(
      { id: contactRow.ContactId },
      {
        onSuccess: () => showToast("Contacto promovido a cliente", "success"),
        onError: (err) => showToast(String((err as Error).message), "error"),
      },
    );
  };

  if (isLoading) {
    return (
      <Paper sx={{ p: 3, borderRadius: 2 }}>
        <Stack spacing={2}>
          <Skeleton variant="circular" width={56} height={56} />
          <Skeleton variant="text" width="60%" height={32} />
          <Skeleton variant="rectangular" height={120} />
          <Skeleton variant="rectangular" height={200} />
        </Stack>
      </Paper>
    );
  }

  if (!contactRow) return <Alert severity="warning">Contacto no encontrado</Alert>;

  const initial = (contactRow.FirstName ?? "?")[0].toUpperCase();
  const fullName = `${contactRow.FirstName ?? ""} ${contactRow.LastName ?? ""}`.trim();

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
      {/* Header */}
      <Box
        sx={{
          p: 2.5,
          background: (t) =>
            `linear-gradient(135deg, ${alpha(t.palette.primary.main, 0.08)}, ${alpha(
              t.palette.primary.main,
              0.02,
            )})`,
          borderBottom: "1px solid",
          borderColor: "divider",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
          <Avatar
            sx={{
              width: 56,
              height: 56,
              bgcolor: "primary.main",
              fontSize: "1.4rem",
              fontWeight: 700,
            }}
          >
            {initial}
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="h6" fontWeight={700} noWrap>
              {fullName || "(sin nombre)"}
            </Typography>
            {contactRow.Title && (
              <Typography variant="body2" color="text.secondary">
                {contactRow.Title}
                {contactRow.Department ? ` — ${contactRow.Department}` : ""}
              </Typography>
            )}
            {contactRow.CompanyName && (
              <Typography variant="caption" color="text.secondary" sx={{ display: "block" }}>
                {contactRow.CompanyName}
              </Typography>
            )}
          </Box>
          <Stack direction="row" spacing={0.5}>
            {onEdit && (
              <IconButton size="small" onClick={onEdit} aria-label="editar">
                <EditIcon />
              </IconButton>
            )}
            {onClose && (
              <IconButton size="small" onClick={onClose} aria-label="cerrar">
                <CloseIcon />
              </IconButton>
            )}
          </Stack>
        </Box>
      </Box>

      {/* Tabs */}
      <Tabs
        value={tab}
        onChange={(_, v) => setTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{ borderBottom: "1px solid", borderColor: "divider", px: 2 }}
      >
        <Tab value="overview" label="Overview" />
        <Tab value="deals" label={`Deals (${deals.length})`} />
        <Tab value="activity" label="Actividad" />
        <Tab value="notes" label="Notas" />
      </Tabs>

      <Box sx={{ p: 2.5 }}>
        {tab === "overview" && (
          <Stack spacing={2}>
            <Stack direction="row" spacing={1} flexWrap="wrap" sx={{ gap: 1 }}>
              {contactRow.Email && (
                <Chip
                  icon={<EmailIcon />}
                  label={contactRow.Email}
                  component="a"
                  href={`mailto:${contactRow.Email}`}
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
              {contactRow.Phone && (
                <Chip
                  icon={<PhoneIcon />}
                  label={contactRow.Phone}
                  component="a"
                  href={`tel:${contactRow.Phone}`}
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
              {contactRow.Mobile && (
                <Chip
                  icon={<SmartphoneIcon />}
                  label={contactRow.Mobile}
                  component="a"
                  href={`tel:${contactRow.Mobile}`}
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
              {contactRow.LinkedIn && (
                <Chip
                  icon={<LinkIcon />}
                  label="LinkedIn"
                  component="a"
                  href={contactRow.LinkedIn}
                  target="_blank"
                  rel="noopener noreferrer"
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
            </Stack>

            <Divider />

            {contactRow.CrmCompanyId && contactRow.CompanyName && (
              <Card
                variant="outlined"
                sx={{ borderRadius: 2 }}
                role="button"
                aria-label={`Abrir empresa ${contactRow.CompanyName}`}
              >
                <CardActionArea
                  onClick={() => companyDrawer.openDrawer(contactRow.CrmCompanyId!)}
                >
                  <CardContent
                    sx={{ display: "flex", alignItems: "center", gap: 1.5, py: 1.5 }}
                  >
                    <BusinessIcon color="primary" />
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="body2" fontWeight={600} noWrap>
                        {contactRow.CompanyName}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        Ver empresa asociada
                      </Typography>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            )}

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
                gap: 2,
              }}
            >
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Estado
                </Typography>
                <Box sx={{ mt: 0.3 }}>
                  <Chip
                    label={contactRow.IsActive ? "Activo" : "Inactivo"}
                    size="small"
                    color={contactRow.IsActive ? "success" : "default"}
                  />
                </Box>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Creado
                </Typography>
                <Typography variant="body2" fontWeight={500}>
                  {formatDate(contactRow.CreatedAt)}
                </Typography>
              </Box>
            </Box>

            <Divider />

            <Stack direction="row" spacing={1} flexWrap="wrap">
              <Button
                variant="outlined"
                size="small"
                startIcon={<StarIcon />}
                onClick={handlePromote}
                disabled={promote.isPending}
              >
                Promover a cliente
              </Button>
            </Stack>
          </Stack>
        )}

        {tab === "deals" && (
          <Stack spacing={1.5}>
            {deals.length === 0 && (
              <Alert severity="info" variant="outlined">
                Este contacto no tiene deals asociados.
              </Alert>
            )}
            {deals.map((d) => (
              <Card key={d.DealId} variant="outlined" sx={{ borderRadius: 2 }}>
                <CardActionArea onClick={() => dealDrawer.openDrawer(d.DealId)}>
                  <CardContent sx={{ py: 1.5 }}>
                    <Box sx={{ display: "flex", justifyContent: "space-between", gap: 1 }}>
                      <Typography variant="body2" fontWeight={600} noWrap>
                        {d.Name}
                      </Typography>
                      <Typography
                        variant="body2"
                        fontWeight={700}
                        color={
                          d.Status === "WON"
                            ? "success.main"
                            : d.Status === "LOST"
                              ? "error.main"
                              : "text.primary"
                        }
                      >
                        {formatCurrency(d.Value)}
                      </Typography>
                    </Box>
                    <Stack direction="row" spacing={1} sx={{ mt: 0.5 }}>
                      <Chip label={d.StageName ?? "—"} size="small" variant="outlined" />
                      <Chip label={d.Status} size="small" />
                    </Stack>
                  </CardContent>
                </CardActionArea>
              </Card>
            ))}
          </Stack>
        )}

        {tab === "activity" && (
          <Alert severity="info" variant="outlined">
            Timeline unificado de actividades del contacto — próximamente (follow-up
            backend `usp_crm_Contact_Timeline`).
          </Alert>
        )}

        {tab === "notes" && (
          <Box>
            {contactRow.Notes ? (
              <Typography variant="body2" sx={{ whiteSpace: "pre-wrap" }}>
                {contactRow.Notes}
              </Typography>
            ) : (
              <Alert severity="info" variant="outlined">
                Sin notas registradas para este contacto.
              </Alert>
            )}
          </Box>
        )}
      </Box>
    </Paper>
  );
}
