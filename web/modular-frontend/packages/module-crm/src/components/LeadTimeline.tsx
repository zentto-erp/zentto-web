"use client";

import React, { useMemo } from "react";
import {
  Box,
  Typography,
  Chip,
  Tooltip,
  Alert,
  alpha,
  useTheme,
  useMediaQuery,
} from "@mui/material";
import { formatCurrency } from "@zentto/shared-api";
import { LeadScoreBadge } from "./LeadScoreBadge";
import type { TimelineLead } from "../hooks/useCRMScoring";

interface LeadTimelineProps {
  leads: TimelineLead[];
}

/* ─── Helpers ──────────────────────────────────────────────── */

const statusColor: Record<string, string> = {
  OPEN: "#2196f3",
  WON: "#4caf50",
  LOST: "#ef5350",
  ARCHIVED: "#9e9e9e",
};

const statusLabel: Record<string, string> = {
  OPEN: "Abierto",
  WON: "Ganado",
  LOST: "Perdido",
  ARCHIVED: "Archivado",
};

function monthsBetween(start: Date, end: Date): number {
  return (end.getFullYear() - start.getFullYear()) * 12 + (end.getMonth() - start.getMonth());
}

function formatMonth(d: Date): string {
  return d.toLocaleDateString("es", { month: "short", year: "2-digit" });
}

function addMonths(d: Date, n: number): Date {
  const r = new Date(d);
  r.setMonth(r.getMonth() + n);
  return r;
}

function startOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

/* ─── Mobile List View ─────────────────────────────────────── */

function MobileLeadList({ leads }: { leads: TimelineLead[] }) {
  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 1.5 }}>
      {leads.map((lead) => (
        <Box
          key={lead.LeadId}
          sx={{
            p: 1.5,
            borderRadius: 1.5,
            border: "1px solid",
            borderColor: "divider",
            bgcolor: "background.paper",
          }}
        >
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 0.5 }}>
            <Typography variant="body2" fontWeight={600} noWrap sx={{ flex: 1 }}>
              {lead.ContactName}
            </Typography>
            <LeadScoreBadge score={lead.Score ?? 0} size="small" />
          </Box>
          {lead.CompanyName && (
            <Typography variant="caption" color="text.secondary" display="block">
              {lead.CompanyName}
            </Typography>
          )}
          <Box sx={{ display: "flex", gap: 0.5, mt: 0.5, flexWrap: "wrap" }}>
            <Chip
              label={statusLabel[lead.Status] ?? lead.Status}
              size="small"
              sx={{
                bgcolor: alpha(statusColor[lead.Status] ?? "#9e9e9e", 0.12),
                color: statusColor[lead.Status] ?? "#9e9e9e",
                fontWeight: 600,
                height: 22,
              }}
            />
            <Chip label={lead.StageName} size="small" variant="outlined" sx={{ height: 22 }} />
            <Typography variant="caption" fontWeight={600} color="success.main" sx={{ ml: "auto" }}>
              {formatCurrency(lead.EstimatedValue)}
            </Typography>
          </Box>
        </Box>
      ))}
    </Box>
  );
}

/* ─── Main Component ───────────────────────────────────────── */

export function LeadTimeline({ leads }: LeadTimelineProps) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));

  const { months, globalStart, monthWidth } = useMemo(() => {
    if (!leads.length) return { months: [] as Date[], globalStart: new Date(), monthWidth: 0 };

    let minDate = new Date();
    let maxDate = new Date();

    leads.forEach((l) => {
      const created = new Date(l.CreatedAt);
      const close = l.ExpectedCloseDate ? new Date(l.ExpectedCloseDate) : created;
      const won = l.WonAt ? new Date(l.WonAt) : null;
      const lost = l.LostAt ? new Date(l.LostAt) : null;
      const end = new Date(Math.max(close.getTime(), won?.getTime() ?? 0, lost?.getTime() ?? 0));

      if (created < minDate) minDate = created;
      if (end > maxDate) maxDate = end;
    });

    const gs = startOfMonth(minDate);
    const ge = startOfMonth(addMonths(maxDate, 1));
    const count = monthsBetween(gs, ge) + 1;
    const mw = 120; // px per month
    const ms: Date[] = [];
    for (let i = 0; i < count; i++) ms.push(addMonths(gs, i));

    return { months: ms, globalStart: gs, monthWidth: mw };
  }, [leads]);

  if (!leads.length) {
    return <Alert severity="info">Sin datos de timeline</Alert>;
  }

  if (isMobile) {
    return <MobileLeadList leads={leads} />;
  }

  const totalWidth = months.length * monthWidth;

  function getBarLeft(dateStr: string): number {
    const d = new Date(dateStr);
    const diffMs = d.getTime() - globalStart.getTime();
    const totalMs = months.length * 30 * 24 * 60 * 60 * 1000; // approx
    return Math.max(0, (diffMs / totalMs) * totalWidth);
  }

  function getBarWidth(startStr: string, endStr: string): number {
    const w = getBarLeft(endStr) - getBarLeft(startStr);
    return Math.max(24, w);
  }

  return (
    <Box sx={{ overflowX: "auto", pb: 2 }}>
      <Box sx={{ minWidth: totalWidth + 200, position: "relative" }}>
        {/* Month headers */}
        <Box sx={{ display: "flex", borderBottom: `1px solid ${theme.palette.divider}`, mb: 1 }}>
          <Box sx={{ width: 180, flexShrink: 0, p: 1 }}>
            <Typography variant="caption" fontWeight={600}>Lead</Typography>
          </Box>
          {months.map((m, i) => (
            <Box
              key={i}
              sx={{
                width: monthWidth,
                flexShrink: 0,
                textAlign: "center",
                borderLeft: `1px solid ${alpha(theme.palette.divider, 0.5)}`,
                p: 0.5,
              }}
            >
              <Typography variant="caption" color="text.secondary" fontWeight={500}>
                {formatMonth(m)}
              </Typography>
            </Box>
          ))}
        </Box>

        {/* Lead rows */}
        {leads.map((lead) => {
          const barColor = statusColor[lead.Status] ?? "#9e9e9e";
          const startDate = lead.CreatedAt;
          const endDate = lead.WonAt ?? lead.LostAt ?? lead.ExpectedCloseDate ?? lead.CreatedAt;
          const left = getBarLeft(startDate);
          const width = getBarWidth(startDate, endDate);

          return (
            <Box
              key={lead.LeadId}
              sx={{
                display: "flex",
                alignItems: "center",
                minHeight: 40,
                "&:hover": { bgcolor: alpha(theme.palette.primary.main, 0.03) },
              }}
            >
              {/* Label column */}
              <Box sx={{ width: 180, flexShrink: 0, px: 1, overflow: "hidden" }}>
                <Typography variant="body2" fontWeight={500} noWrap>
                  {lead.ContactName}
                </Typography>
                <Typography variant="caption" color="text.secondary" noWrap>
                  {lead.CompanyName}
                </Typography>
              </Box>

              {/* Bar area */}
              <Box sx={{ position: "relative", flex: 1, height: 32 }}>
                <Tooltip
                  arrow
                  title={
                    <Box>
                      <Typography variant="body2" fontWeight={600}>{lead.ContactName}</Typography>
                      {lead.CompanyName && <Typography variant="caption" display="block">{lead.CompanyName}</Typography>}
                      <Typography variant="caption" display="block">
                        Etapa: {lead.StageName} | {statusLabel[lead.Status] ?? lead.Status}
                      </Typography>
                      <Typography variant="caption" display="block">
                        Valor: {formatCurrency(lead.EstimatedValue)}
                      </Typography>
                      <Typography variant="caption" display="block">
                        Score: {lead.Score ?? "N/A"}
                      </Typography>
                      <Typography variant="caption" display="block">
                        Desde: {new Date(lead.CreatedAt).toLocaleDateString("es")}
                      </Typography>
                      {lead.ExpectedCloseDate && (
                        <Typography variant="caption" display="block">
                          Cierre est.: {new Date(lead.ExpectedCloseDate).toLocaleDateString("es")}
                        </Typography>
                      )}
                    </Box>
                  }
                >
                  <Box
                    sx={{
                      position: "absolute",
                      left,
                      top: 4,
                      width,
                      height: 24,
                      borderRadius: 3,
                      bgcolor: alpha(barColor, 0.2),
                      border: `1.5px solid ${barColor}`,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      px: 0.5,
                      cursor: "pointer",
                      transition: "box-shadow 0.15s",
                      "&:hover": { boxShadow: `0 0 0 2px ${alpha(barColor, 0.3)}` },
                    }}
                  >
                    <Typography
                      variant="caption"
                      sx={{ fontWeight: 600, fontSize: "0.65rem", color: barColor, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}
                    >
                      {lead.LeadCode}
                    </Typography>
                    {lead.Score != null && <LeadScoreBadge score={lead.Score} size="small" />}
                  </Box>
                </Tooltip>
              </Box>
            </Box>
          );
        })}
      </Box>
    </Box>
  );
}

export default LeadTimeline;
