"use client";

import React, { useState } from "react";
import {
  Alert,
  Avatar,
  Box,
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
import BusinessIcon from "@mui/icons-material/Business";
import CloseIcon from "@mui/icons-material/Close";
import EditIcon from "@mui/icons-material/Edit";
import EmailIcon from "@mui/icons-material/Email";
import LanguageIcon from "@mui/icons-material/Language";
import PersonIcon from "@mui/icons-material/Person";
import PhoneIcon from "@mui/icons-material/Phone";
import { formatCurrency } from "@zentto/shared-api";
import { useDrawerQueryParam } from "@zentto/shared-ui";
import { useCompany, type Company } from "../hooks/useCompanies";
import { useContactsList, type Contact } from "../hooks/useContacts";
import { useDealsList, type Deal } from "../hooks/useDeals";

interface CompanyDetailPanelProps {
  companyId: number;
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

export default function CompanyDetailPanel({
  companyId,
  onClose,
  onEdit,
}: CompanyDetailPanelProps) {
  const { data, isLoading } = useCompany(companyId);
  const company = ((data as any)?.data ?? (data as any) ?? null) as Company | null;
  const [tab, setTab] = useState("overview");

  const contactDrawer = useDrawerQueryParam("contact");
  const dealDrawer = useDrawerQueryParam("deal");

  const { data: contactsData } = useContactsList({ crmCompanyId: companyId, limit: 50 });
  const contacts: Contact[] =
    (contactsData as any)?.data ?? (contactsData as any)?.rows ?? contactsData ?? [];

  const { data: dealsData } = useDealsList({ crmCompanyId: companyId, limit: 50 });
  const deals: Deal[] =
    (dealsData as any)?.data ?? (dealsData as any)?.rows ?? dealsData ?? [];

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

  if (!company) return <Alert severity="warning">Empresa no encontrada</Alert>;

  return (
    <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
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
          <Avatar sx={{ width: 56, height: 56, bgcolor: "primary.main" }}>
            <BusinessIcon />
          </Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="h6" fontWeight={700} noWrap>
              {company.Name}
            </Typography>
            {company.LegalName && (
              <Typography variant="body2" color="text.secondary" noWrap>
                {company.LegalName}
              </Typography>
            )}
            <Stack direction="row" spacing={0.5} sx={{ mt: 0.5 }}>
              {company.Industry && <Chip label={company.Industry} size="small" variant="outlined" />}
              {company.Size && <Chip label={company.Size} size="small" variant="outlined" />}
              <Chip
                label={company.IsActive ? "Activa" : "Inactiva"}
                size="small"
                color={company.IsActive ? "success" : "default"}
              />
            </Stack>
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

      <Tabs
        value={tab}
        onChange={(_, v) => setTab(v)}
        variant="scrollable"
        scrollButtons="auto"
        sx={{ borderBottom: "1px solid", borderColor: "divider", px: 2 }}
      >
        <Tab value="overview" label="Overview" />
        <Tab value="contacts" label={`Contactos (${contacts.length})`} />
        <Tab value="deals" label={`Deals (${deals.length})`} />
        <Tab value="notes" label="Notas" />
      </Tabs>

      <Box sx={{ p: 2.5 }}>
        {tab === "overview" && (
          <Stack spacing={2}>
            <Stack direction="row" spacing={1} flexWrap="wrap" sx={{ gap: 1 }}>
              {company.Email && (
                <Chip
                  icon={<EmailIcon />}
                  label={company.Email}
                  component="a"
                  href={`mailto:${company.Email}`}
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
              {company.Phone && (
                <Chip
                  icon={<PhoneIcon />}
                  label={company.Phone}
                  component="a"
                  href={`tel:${company.Phone}`}
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
              {company.Website && (
                <Chip
                  icon={<LanguageIcon />}
                  label={company.Website}
                  component="a"
                  href={
                    company.Website.startsWith("http")
                      ? company.Website
                      : `https://${company.Website}`
                  }
                  target="_blank"
                  rel="noopener noreferrer"
                  clickable
                  size="small"
                  variant="outlined"
                />
              )}
            </Stack>

            <Divider />

            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
                gap: 2,
              }}
            >
              {company.TaxId && (
                <Box>
                  <Typography variant="caption" color="text.secondary">
                    Tax ID
                  </Typography>
                  <Typography variant="body2" fontWeight={500}>
                    {company.TaxId}
                  </Typography>
                </Box>
              )}
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Contactos
                </Typography>
                <Typography variant="h6" fontWeight={700}>
                  {contacts.length}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Deals activos
                </Typography>
                <Typography variant="h6" fontWeight={700}>
                  {deals.filter((d) => d.Status === "OPEN").length}
                </Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">
                  Creada
                </Typography>
                <Typography variant="body2" fontWeight={500}>
                  {formatDate(company.CreatedAt)}
                </Typography>
              </Box>
            </Box>
          </Stack>
        )}

        {tab === "contacts" && (
          <Stack spacing={1.5}>
            {contacts.length === 0 && (
              <Alert severity="info" variant="outlined">
                Esta empresa aún no tiene contactos asociados.
              </Alert>
            )}
            {contacts.map((c) => (
              <Card key={c.ContactId} variant="outlined" sx={{ borderRadius: 2 }}>
                <CardActionArea onClick={() => contactDrawer.openDrawer(c.ContactId)}>
                  <CardContent sx={{ py: 1.5, display: "flex", alignItems: "center", gap: 1.5 }}>
                    <Avatar sx={{ width: 32, height: 32, bgcolor: "primary.light" }}>
                      <PersonIcon fontSize="small" />
                    </Avatar>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                      <Typography variant="body2" fontWeight={600} noWrap>
                        {`${c.FirstName ?? ""} ${c.LastName ?? ""}`.trim()}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" noWrap>
                        {c.Title ?? ""}
                        {c.Title && c.Email ? " · " : ""}
                        {c.Email ?? ""}
                      </Typography>
                    </Box>
                  </CardContent>
                </CardActionArea>
              </Card>
            ))}
          </Stack>
        )}

        {tab === "deals" && (
          <Stack spacing={1.5}>
            {deals.length === 0 && (
              <Alert severity="info" variant="outlined">
                Sin deals asociados a esta empresa.
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

        {tab === "notes" && (
          <Box>
            {company.Notes ? (
              <Typography variant="body2" sx={{ whiteSpace: "pre-wrap" }}>
                {company.Notes}
              </Typography>
            ) : (
              <Alert severity="info" variant="outlined">
                Sin notas registradas para esta empresa.
              </Alert>
            )}
          </Box>
        )}
      </Box>
    </Paper>
  );
}
