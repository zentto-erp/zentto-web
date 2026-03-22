"use client";

import React, { useMemo } from "react";
import {
  Box,
  Card,
  CardContent,
  Typography,
  Skeleton,
  Alert,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import PeopleIcon from "@mui/icons-material/People";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import AssignmentIcon from "@mui/icons-material/Assignment";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import ViewKanbanIcon from "@mui/icons-material/ViewKanban";
import FormatListBulletedIcon from "@mui/icons-material/FormatListBulleted";
import EventNoteIcon from "@mui/icons-material/EventNote";
import DashboardIcon from "@mui/icons-material/Dashboard";
import PhoneIcon from "@mui/icons-material/Phone";
import EmailIcon from "@mui/icons-material/Email";
import PeopleOutlineIcon from "@mui/icons-material/PeopleOutline";
import NoteIcon from "@mui/icons-material/Note";
import TaskIcon from "@mui/icons-material/Task";
import { formatCurrency } from "@zentto/shared-api";
import { brandColors } from "@zentto/shared-ui";
import { useRouter } from "next/navigation";
import {
  useLeadsList,
  useActivitiesList,
  usePipelinesList,
  usePipelineStages,
  type Lead,
  type Activity,
} from "../hooks/useCRM";

const shortcuts = [
  {
    title: "Pipeline",
    description: "Tablero Kanban",
    icon: <ViewKanbanIcon sx={{ fontSize: 32 }} />,
    href: "/crm/pipeline",
    bg: brandColors.shortcutDark,
  },
  {
    title: "Leads",
    description: "Lista completa",
    icon: <FormatListBulletedIcon sx={{ fontSize: 32 }} />,
    href: "/crm/leads",
    bg: brandColors.shortcutTeal,
  },
  {
    title: "Actividades",
    description: "Tareas y seguimiento",
    icon: <EventNoteIcon sx={{ fontSize: 32 }} />,
    href: "/crm/actividades",
    bg: brandColors.shortcutSlate,
  },
  {
    title: "Dashboard",
    description: "Métricas CRM",
    icon: <DashboardIcon sx={{ fontSize: 32 }} />,
    href: "/crm",
    bg: brandColors.success,
  },
];

const activityTypeIcon: Record<string, React.ReactNode> = {
  CALL: <PhoneIcon sx={{ fontSize: 14 }} />,
  EMAIL: <EmailIcon sx={{ fontSize: 14 }} />,
  MEETING: <PeopleOutlineIcon sx={{ fontSize: 14 }} />,
  NOTE: <NoteIcon sx={{ fontSize: 14 }} />,
  TASK: <TaskIcon sx={{ fontSize: 14 }} />,
};

const activityTypeLabel: Record<string, string> = {
  CALL: "Llamada",
  EMAIL: "Correo",
  MEETING: "Reunión",
  NOTE: "Nota",
  TASK: "Tarea",
};

export default function CRMHome() {
  const router = useRouter();

  // Leads abiertos
  const { data: leadsData, isLoading: loadingLeads, error: errorLeads } = useLeadsList({ status: "OPEN", limit: 500 });
  const allLeads: Lead[] = leadsData?.data ?? leadsData?.rows ?? [];

  // Últimos 5 leads
  const { data: recentLeadsData } = useLeadsList({ page: 1, limit: 5 });
  const recentLeads: Lead[] = recentLeadsData?.data ?? recentLeadsData?.rows ?? [];

  // Actividades pendientes
  const { data: activitiesData, isLoading: loadingActivities } = useActivitiesList({ isCompleted: false, limit: 500 });
  const pendingActivities: Activity[] = activitiesData?.data ?? activitiesData?.rows ?? [];

  // Próximas 5 actividades
  const nextActivities = useMemo(() => {
    return [...pendingActivities]
      .sort((a, b) => (a.DueDate ?? "").localeCompare(b.DueDate ?? ""))
      .slice(0, 5);
  }, [pendingActivities]);

  // Leads ganados para tasa de conversión
  const { data: wonData } = useLeadsList({ status: "WON", limit: 500 });
  const wonLeads: Lead[] = wonData?.data ?? wonData?.rows ?? [];

  const { data: lostData } = useLeadsList({ status: "LOST", limit: 500 });
  const lostLeads: Lead[] = lostData?.data ?? lostData?.rows ?? [];

  // Pipeline para funnel
  const { data: pipelinesData } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];
  const defaultPipelineId = pipelines.length > 0 ? pipelines[0]?.PipelineId : undefined;

  const { data: stagesData } = usePipelineStages(defaultPipelineId);
  const stages = stagesData?.data ?? stagesData?.rows ?? stagesData ?? [];

  // ─── Cálculos ─────────────────────────────────────────────
  const openLeadsCount = allLeads.length;
  const totalEstimatedValue = allLeads.reduce((sum, l) => sum + (l.EstimatedValue ?? 0), 0);
  const pendingActivitiesCount = pendingActivities.length;

  const totalClosed = wonLeads.length + lostLeads.length;
  const conversionRate = totalClosed > 0 ? (wonLeads.length / totalClosed) * 100 : 0;

  // Funnel: leads por etapa con su valor
  const funnelData = useMemo(() => {
    const stageMap: Record<number, { name: string; color: string; count: number; value: number; sortOrder: number }> = {};
    for (const s of stages) {
      stageMap[s.StageId] = { name: s.Name, color: s.Color || brandColors.statBlue, count: 0, value: 0, sortOrder: s.SortOrder };
    }
    for (const l of allLeads) {
      if (stageMap[l.StageId]) {
        stageMap[l.StageId].count++;
        stageMap[l.StageId].value += l.EstimatedValue ?? 0;
      }
    }
    return Object.values(stageMap).sort((a, b) => a.sortOrder - b.sortOrder);
  }, [stages, allLeads]);

  const maxFunnelValue = Math.max(...funnelData.map((f) => f.value), 1);

  const isLoading = loadingLeads || loadingActivities;

  const statsCards = [
    {
      title: "Leads abiertos",
      value: openLeadsCount,
      color: brandColors.statBlue,
      icon: <PeopleIcon />,
    },
    {
      title: "Valor estimado",
      value: totalEstimatedValue,
      isCurrency: true,
      color: brandColors.statTeal,
      icon: <AttachMoneyIcon />,
    },
    {
      title: "Actividades pendientes",
      value: pendingActivitiesCount,
      color: brandColors.statOrange,
      icon: <AssignmentIcon />,
    },
    {
      title: "Tasa de conversión",
      value: conversionRate,
      isPercent: true,
      color: brandColors.statRed,
      icon: <TrendingUpIcon />,
    },
  ];

  return (
    <Box>
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 700, color: "text.primary" }}>
        Dashboard CRM
      </Typography>

      {errorLeads && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se pudieron cargar los datos del CRM. Verifique la conexión con el servidor.
        </Alert>
      )}

      {/* ─── STATS CARDS ─────────────────────────────────────── */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((s, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                height: "100%",
                bgcolor: s.color,
                color: "white",
                borderRadius: 2,
                boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
              }}
            >
              <CardContent sx={{ pb: "16px !important" }}>
                <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <Box>
                    {isLoading ? (
                      <Skeleton variant="text" width={120} height={40} sx={{ bgcolor: "rgba(255,255,255,0.3)" }} />
                    ) : (
                      <Typography variant="h4" sx={{ fontWeight: 700, lineHeight: 1 }}>
                        {(s as any).isPercent
                          ? `${Number(s.value).toFixed(1)}%`
                          : (s as any).isCurrency
                            ? formatCurrency(s.value)
                            : s.value}
                      </Typography>
                    )}
                    <Typography variant="body1" sx={{ mt: 1, opacity: 0.9, fontWeight: 500 }}>
                      {s.title}
                    </Typography>
                  </Box>
                  <Box sx={{ opacity: 0.6 }}>{s.icon}</Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ─── SHORTCUTS ───────────────────────────────────────── */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {shortcuts.map((sc, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3 }} key={idx}>
            <Card
              sx={{
                borderRadius: 2,
                overflow: "hidden",
                boxShadow: "0 2px 4px rgba(0,0,0,0.05)",
                cursor: "pointer",
                transition: "transform 0.2s, box-shadow 0.2s",
                "&:hover": { transform: "translateY(-2px)", boxShadow: "0 4px 12px rgba(0,0,0,0.15)" },
              }}
              onClick={() => router.push(sc.href)}
            >
              <Box sx={{ bgcolor: sc.bg, color: "white", display: "flex", justifyContent: "center", py: 3 }}>
                {sc.icon}
              </Box>
              <CardContent sx={{ textAlign: "center", py: 2 }}>
                <Typography variant="h6" sx={{ fontWeight: 700, color: "text.primary", mb: 0 }}>
                  {sc.title}
                </Typography>
                <Typography
                  variant="body2"
                  color="text.secondary"
                  sx={{ textTransform: "uppercase", fontWeight: 600, fontSize: "0.75rem", letterSpacing: 1 }}
                >
                  {sc.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* ─── BOTTOM SECTION ──────────────────────────────────── */}
      <Grid container spacing={3}>
        {/* Funnel */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Embudo de ventas
              </Typography>
            </Box>
            <Box sx={{ p: 2 }}>
              {funnelData.length === 0 ? (
                <Typography variant="body2" color="text.secondary" textAlign="center" py={3}>
                  No hay datos del embudo
                </Typography>
              ) : (
                funnelData.map((stage, idx) => (
                  <Box key={idx} sx={{ mb: 1.5 }}>
                    <Box sx={{ display: "flex", justifyContent: "space-between", mb: 0.5 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {stage.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {stage.count} leads - {formatCurrency(stage.value)}
                      </Typography>
                    </Box>
                    <Box
                      sx={{
                        height: 24,
                        bgcolor: "grey.100",
                        borderRadius: 1,
                        overflow: "hidden",
                      }}
                    >
                      <Box
                        sx={{
                          height: "100%",
                          width: `${Math.max((stage.value / maxFunnelValue) * 100, 2)}%`,
                          bgcolor: stage.color,
                          borderRadius: 1,
                          transition: "width 0.5s ease",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        {stage.value > 0 && (
                          <Typography variant="caption" sx={{ color: "white", fontWeight: 600, fontSize: "0.65rem" }}>
                            {formatCurrency(stage.value)}
                          </Typography>
                        )}
                      </Box>
                    </Box>
                  </Box>
                ))
              )}
            </Box>
          </Paper>
        </Grid>

        {/* Últimos leads */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Últimos leads
              </Typography>
            </Box>
            {recentLeads.length > 0 ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Código</TableCell>
                    <TableCell>Contacto</TableCell>
                    <TableCell>Empresa</TableCell>
                    <TableCell align="right">Valor</TableCell>
                    <TableCell>Prioridad</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {recentLeads.map((l, idx) => (
                    <TableRow
                      key={l.LeadId ?? idx}
                      hover
                      sx={{ cursor: "pointer" }}
                      onClick={() => router.push("/crm/leads")}
                    >
                      <TableCell>
                        <Typography variant="caption" sx={{ fontWeight: 600 }}>
                          {l.LeadCode}
                        </Typography>
                      </TableCell>
                      <TableCell>{l.ContactName}</TableCell>
                      <TableCell>{l.CompanyName}</TableCell>
                      <TableCell align="right">{formatCurrency(l.EstimatedValue ?? 0)}</TableCell>
                      <TableCell>
                        <Chip
                          label={l.Priority === "HIGH" ? "Alta" : l.Priority === "MEDIUM" ? "Media" : "Baja"}
                          size="small"
                          color={l.Priority === "HIGH" ? "error" : l.Priority === "MEDIUM" ? "warning" : "info"}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Box p={3} textAlign="center">
                <Typography variant="body2" color="text.secondary">
                  No hay leads registrados
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Próximas actividades */}
        <Grid size={{ xs: 12 }}>
          <Paper sx={{ borderRadius: 2, overflow: "hidden" }}>
            <Box sx={{ p: 2, borderBottom: "1px solid #eee" }}>
              <Typography variant="h6" fontWeight={600}>
                Próximas actividades pendientes
              </Typography>
            </Box>
            {nextActivities.length > 0 ? (
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Tipo</TableCell>
                    <TableCell>Asunto</TableCell>
                    <TableCell>Lead</TableCell>
                    <TableCell>Fecha límite</TableCell>
                    <TableCell>Asignado a</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {nextActivities.map((a, idx) => (
                    <TableRow
                      key={a.ActivityId ?? idx}
                      hover
                      sx={{ cursor: "pointer" }}
                      onClick={() => router.push("/crm/actividades")}
                    >
                      <TableCell>
                        <Chip
                          icon={activityTypeIcon[a.ActivityType] as React.ReactElement}
                          label={activityTypeLabel[a.ActivityType] ?? a.ActivityType}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell>{a.Subject}</TableCell>
                      <TableCell>{a.LeadCode}</TableCell>
                      <TableCell>{a.DueDate}</TableCell>
                      <TableCell>{a.AssignedToName}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <Box p={3} textAlign="center">
                <Typography variant="body2" color="text.secondary">
                  No hay actividades pendientes
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}
