"use client";

import React, {
  useState,
  useMemo,
  useCallback,
  useEffect,
  useRef,
} from "react";
import {
  DndContext,
  DragOverlay,
  closestCorners,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragStartEvent,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  verticalListSortingStrategy,
  useSortable,
} from "@dnd-kit/sortable";
import { useDroppable } from "@dnd-kit/core";
import { CSS } from "@dnd-kit/utilities";
import {
  Box,
  Paper,
  Typography,
  Card,
  CardContent,
  Chip,
  Button,
  IconButton,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Skeleton,
  Alert,
  Stack,
  Tooltip,
  Badge,
  Avatar,
  alpha,
  LinearProgress,
  useTheme,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EmojiEventsIcon from "@mui/icons-material/EmojiEvents";
import ThumbDownIcon from "@mui/icons-material/ThumbDown";
import DragIndicatorIcon from "@mui/icons-material/DragIndicator";
import AlarmIcon from "@mui/icons-material/Alarm";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { formatCurrency } from "@zentto/shared-api";
import {
  FormDialog,
  ZenttoFilterPanel,
  useDrawerQueryParam,
  RightDetailDrawer,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import {
  usePipelinesList,
  usePipelineStages,
  useLeadsList,
  useCreateLead,
  useMoveLeadStage,
  useWinLead,
  useLoseLead,
  type Lead,
  type PipelineStage,
  type LeadFilter,
} from "../hooks/useCRM";
import {
  PRIORITY_COLORS,
  PRIORITY_LABELS,
  PRIORITY_VALUES,
  type Priority,
} from "../types";
import LeadDetailPanel from "./LeadDetailPanel";

// ─── Constants ──────────────────────────────────────────────────────────────

/**
 * Umbral por defecto (días) para marcar un lead como "rotten".
 * CRM-107: idealmente se lee de `stage.RottenThreshold` cuando backend lo exponga.
 */
const DEFAULT_ROTTEN_THRESHOLD_DAYS = 14;

const LOCAL_STORAGE_COLLAPSED_KEY = (pipelineId: number | undefined) =>
  `crm:pipeline:columnsCollapsed:${pipelineId ?? "none"}:v1`;

// ─── Priority config ────────────────────────────────────────────────────────

const PRIORITY: Record<
  Priority,
  { color: "error" | "warning" | "info" | "default"; label: string; order: number }
> = PRIORITY_VALUES.reduce(
  (acc, value, index) => {
    acc[value] = {
      color: PRIORITY_COLORS[value],
      label: PRIORITY_LABELS[value],
      order: index,
    };
    return acc;
  },
  {} as Record<
    Priority,
    { color: "error" | "warning" | "info" | "default"; label: string; order: number }
  >,
);

const SOURCE_ICONS: Record<string, string> = {
  WEB: "🌐",
  REFERRAL: "🤝",
  COLD_CALL: "📞",
  EVENT: "🎪",
  SOCIAL: "📱",
};

const SOURCE_OPTIONS = [
  { value: "WEB", label: "Web" },
  { value: "REFERRAL", label: "Referido" },
  { value: "COLD_CALL", label: "Llamada en frío" },
  { value: "EVENT", label: "Evento" },
  { value: "SOCIAL", label: "Redes sociales" },
  { value: "OTHER", label: "Otro" },
];

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Aproxima días "in stage" desde `CreatedAt` del lead hasta hoy.
 * Cuando backend exponga `StageChangedAt` o `DaysInStage`, sustituir aquí.
 */
function getDaysInStage(lead: Lead): number {
  if (!lead.CreatedAt) return 0;
  const created = new Date(lead.CreatedAt).getTime();
  if (Number.isNaN(created)) return 0;
  const diffMs = Date.now() - created;
  return Math.max(0, Math.floor(diffMs / (1000 * 60 * 60 * 24)));
}

function getRottenThreshold(stage: PipelineStage | undefined): number {
  if (!stage) return DEFAULT_ROTTEN_THRESHOLD_DAYS;
  const raw = (stage as unknown as { RottenThreshold?: number }).RottenThreshold;
  return typeof raw === "number" && raw > 0 ? raw : DEFAULT_ROTTEN_THRESHOLD_DAYS;
}

function computeWeightedValue(leads: Lead[], stage: PipelineStage | undefined) {
  const probability = stage?.Probability ?? 0;
  return leads.reduce((sum, l) => {
    const val = l.EstimatedValue ?? 0;
    return sum + (val * probability) / 100;
  }, 0);
}

// ─── Draggable Lead Card ────────────────────────────────────────────────────

interface LeadCardProps {
  lead: Lead;
  stage?: PipelineStage;
  onWin: (lead: Lead) => void;
  onLose: (lead: Lead) => void;
  onOpen?: (lead: Lead) => void;
  onFocus?: () => void;
  onKeyDown?: (e: React.KeyboardEvent<HTMLDivElement>) => void;
  cardRef?: (el: HTMLDivElement | null) => void;
  ariaIndex?: number;
  ariaTotal?: number;
}

function SortableLeadCard(props: LeadCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({
    id: `lead-${props.lead.LeadId}`,
    data: { type: "lead", lead: props.lead },
  });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.4 : 1,
  };

  return (
    <div ref={setNodeRef} style={style} {...attributes}>
      <LeadCardContent {...props} dragListeners={listeners} grabbed={isDragging} />
    </div>
  );
}

function LeadCardContent({
  lead,
  stage,
  onWin,
  onLose,
  onOpen,
  dragListeners,
  overlay,
  onFocus,
  onKeyDown,
  cardRef,
  grabbed,
  ariaIndex,
  ariaTotal,
}: LeadCardProps & {
  dragListeners?: any;
  overlay?: boolean;
  grabbed?: boolean;
}) {
  const theme = useTheme();
  const priority = PRIORITY[lead.Priority] ?? PRIORITY.MEDIUM;
  const sourceIcon = SOURCE_ICONS[lead.Source] ?? "📋";

  const daysInStage = getDaysInStage(lead);
  const rottenThreshold = getRottenThreshold(stage);
  const isRotten = daysInStage > rottenThreshold;

  const ariaLabel = useMemo(() => {
    const parts = [
      `Lead ${lead.LeadCode ?? lead.LeadId}`,
      lead.ContactName,
      stage?.Name ? `etapa ${stage.Name}` : null,
      `prioridad ${priority.label}`,
      isRotten ? `sin movimiento ${daysInStage} días` : null,
      ariaIndex != null && ariaTotal != null
        ? `${ariaIndex + 1} de ${ariaTotal}`
        : null,
    ].filter(Boolean);
    return parts.join(", ");
  }, [
    lead.LeadCode,
    lead.LeadId,
    lead.ContactName,
    stage?.Name,
    priority.label,
    isRotten,
    daysInStage,
    ariaIndex,
    ariaTotal,
  ]);

  return (
    <Box
      ref={cardRef}
      role="listitem"
      tabIndex={overlay ? -1 : 0}
      aria-label={ariaLabel}
      aria-grabbed={grabbed ? true : undefined}
      onFocus={onFocus}
      onKeyDown={onKeyDown}
      onClick={(e) => {
        const target = e.target as HTMLElement;
        if (target.closest("button") || target.closest("[data-drag-handle]")) return;
        onOpen?.(lead);
      }}
      sx={{
        outline: "none",
        borderRadius: 2,
        "&:focus-visible": {
          boxShadow: (t) => `0 0 0 2px ${t.palette.primary.main}`,
        },
      }}
    >
      <Card
        sx={{
          mb: 1,
          borderRadius: 2,
          borderLeft: `3px solid ${(theme.palette as any)[priority.color]?.main ?? theme.palette.grey[400]}`,
          boxShadow: overlay ? "0 8px 24px rgba(0,0,0,0.2)" : "0 1px 3px rgba(0,0,0,0.08)",
          "&:hover": { boxShadow: "0 3px 12px rgba(0,0,0,0.12)" },
          transition: "box-shadow 0.2s, transform 0.15s",
          transform: overlay ? "rotate(2deg) scale(1.02)" : "none",
          cursor: "pointer",
          bgcolor: "background.paper",
          position: "relative",
        }}
      >
        <CardContent sx={{ p: 1.5, pb: "10px !important" }}>
          {/* Drag handle + Lead Code + Rotten + Priority */}
          <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, mb: 0.75 }}>
            <Box
              data-drag-handle
              {...dragListeners}
              sx={{ cursor: "grab", color: "text.disabled", display: "flex" }}
              aria-label="Arrastrar lead"
            >
              <DragIndicatorIcon sx={{ fontSize: 16 }} />
            </Box>
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ fontWeight: 700, fontFamily: "monospace", fontSize: "0.7rem" }}
            >
              {lead.LeadCode}
            </Typography>
            <Box sx={{ flex: 1 }} />
            {isRotten && (
              <Tooltip title={`Este lead lleva ${daysInStage} días sin moverse`}>
                <Chip
                  icon={<AlarmIcon sx={{ fontSize: 14 }} />}
                  label="Rotten"
                  size="small"
                  color="warning"
                  sx={{ height: 18, fontSize: "0.6rem", fontWeight: 700, mr: 0.5 }}
                />
              </Tooltip>
            )}
            <Chip
              label={priority.label}
              size="small"
              color={priority.color}
              sx={{ height: 18, fontSize: "0.65rem", fontWeight: 700 }}
            />
          </Box>

          {/* Contact name */}
          <Box sx={{ display: "flex", alignItems: "center", gap: 0.75, mb: 0.5 }}>
            <Avatar sx={{ width: 24, height: 24, fontSize: "0.7rem", bgcolor: "primary.main" }}>
              {lead.ContactName?.charAt(0)?.toUpperCase() ?? "?"}
            </Avatar>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Typography variant="body2" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: "0.8125rem" }} noWrap>
                {lead.ContactName}
              </Typography>
              {lead.CompanyName && (
                <Typography variant="caption" color="text.secondary" sx={{ fontSize: "0.7rem", lineHeight: 1.1 }} noWrap>
                  {lead.CompanyName}
                </Typography>
              )}
            </Box>
          </Box>

          {/* Value + Source */}
          <Box sx={{ display: "flex", alignItems: "center", justifyContent: "space-between", mt: 0.75 }}>
            {lead.EstimatedValue > 0 ? (
              <Typography variant="body2" sx={{ fontWeight: 800, color: "success.main", fontSize: "0.85rem" }}>
                {formatCurrency(lead.EstimatedValue)}
              </Typography>
            ) : (
              <Typography variant="caption" color="text.disabled">Sin valor</Typography>
            )}
            <Box sx={{ display: "flex", gap: 0.5, alignItems: "center" }}>
              {lead.Source && (
                <Tooltip title={lead.Source}>
                  <Typography sx={{ fontSize: "0.85rem", lineHeight: 1 }}>{sourceIcon}</Typography>
                </Tooltip>
              )}
            </Box>
          </Box>

          {/* Quick actions */}
          <Box sx={{ display: "flex", justifyContent: "flex-end", gap: 0.25, mt: 0.75, pt: 0.5, borderTop: "1px solid", borderColor: "divider" }}>
            <Tooltip title="Ganado">
              <IconButton
                size="small"
                color="success"
                onClick={(e) => {
                  e.stopPropagation();
                  onWin(lead);
                }}
                aria-label={`Marcar lead ${lead.LeadCode ?? lead.LeadId} como ganado`}
                sx={{ width: 26, height: 26 }}
              >
                <EmojiEventsIcon sx={{ fontSize: 15 }} />
              </IconButton>
            </Tooltip>
            <Tooltip title="Perdido">
              <IconButton
                size="small"
                color="error"
                onClick={(e) => {
                  e.stopPropagation();
                  onLose(lead);
                }}
                aria-label={`Marcar lead ${lead.LeadCode ?? lead.LeadId} como perdido`}
                sx={{ width: 26, height: 26 }}
              >
                <ThumbDownIcon sx={{ fontSize: 15 }} />
              </IconButton>
            </Tooltip>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
}

// ─── Droppable Stage Column ─────────────────────────────────────────────────

interface StageColumnProps {
  stage: PipelineStage;
  leads: Lead[];
  totalValue: number;
  weightedValue: number;
  collapsed: boolean;
  onToggleCollapse: () => void;
  onWin: (lead: Lead) => void;
  onLose: (lead: Lead) => void;
  onOpen: (lead: Lead) => void;
  focusedLeadId: number | null;
  onFocusLead: (leadId: number) => void;
  onCardKeyDown: (
    e: React.KeyboardEvent<HTMLDivElement>,
    lead: Lead,
    index: number,
  ) => void;
  registerCardRef: (leadId: number, el: HTMLDivElement | null) => void;
}

function StageColumn({
  stage,
  leads,
  totalValue,
  weightedValue,
  collapsed,
  onToggleCollapse,
  onWin,
  onLose,
  onOpen,
  focusedLeadId,
  onFocusLead,
  onCardKeyDown,
  registerCardRef,
}: StageColumnProps) {
  const theme = useTheme();
  const { setNodeRef, isOver } = useDroppable({
    id: `stage-${stage.StageId}`,
    data: { type: "stage", stage },
  });

  const sortableIds = leads.map((l) => `lead-${l.LeadId}`);

  return (
    <Paper
      ref={setNodeRef}
      role="region"
      aria-label={`Etapa ${stage.Name}, ${leads.length} leads`}
      sx={{
        minWidth: collapsed ? 72 : 290,
        maxWidth: collapsed ? 72 : 330,
        width: collapsed ? 72 : 290,
        flexShrink: 0,
        borderRadius: 3,
        borderTop: `4px solid ${stage.Color || theme.palette.primary.main}`,
        bgcolor: isOver
          ? alpha(stage.Color || theme.palette.primary.main, 0.06)
          : stage.IsClosed
          ? alpha(theme.palette.grey[500], 0.04)
          : "background.paper",
        display: "flex",
        flexDirection: "column",
        transition: "background-color 0.2s, width 0.2s, min-width 0.2s",
        overflow: "hidden",
      }}
    >
      {/* Column Header — clic colapsa/expande */}
      <Box
        role="button"
        tabIndex={0}
        aria-expanded={!collapsed}
        aria-controls={`stage-cards-${stage.StageId}`}
        onClick={onToggleCollapse}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            onToggleCollapse();
          }
        }}
        sx={{
          p: collapsed ? 1 : 1.75,
          borderBottom: "1px solid",
          borderColor: "divider",
          cursor: "pointer",
          userSelect: "none",
          minHeight: collapsed ? 180 : undefined,
          display: "flex",
          flexDirection: "column",
          alignItems: "stretch",
          gap: collapsed ? 1 : 0,
          "&:hover": { bgcolor: alpha(theme.palette.primary.main, 0.04) },
          "&:focus-visible": {
            outline: `2px solid ${theme.palette.primary.main}`,
            outlineOffset: -2,
          },
        }}
      >
        {collapsed ? (
          <Stack alignItems="center" spacing={1}>
            <ChevronRightIcon fontSize="small" />
            <Typography
              variant="subtitle2"
              sx={{
                fontWeight: 800,
                fontSize: "0.8rem",
                writingMode: "vertical-rl",
                transform: "rotate(180deg)",
              }}
              noWrap
            >
              {stage.Name}
            </Typography>
            <Badge
              badgeContent={leads.length}
              color="primary"
              sx={{ mt: 1, "& .MuiBadge-badge": { fontSize: "0.65rem", height: 18, minWidth: 18 } }}
            />
            {weightedValue > 0 && (
              <Tooltip title="Valor ponderado">
                <Typography
                  variant="caption"
                  color="success.main"
                  sx={{
                    fontWeight: 700,
                    fontSize: "0.65rem",
                    writingMode: "vertical-rl",
                    transform: "rotate(180deg)",
                  }}
                >
                  {formatCurrency(weightedValue)}
                </Typography>
              </Tooltip>
            )}
          </Stack>
        ) : (
          <>
            <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
                <ExpandMoreIcon fontSize="small" />
                <Typography variant="subtitle2" sx={{ fontWeight: 800, fontSize: "0.85rem" }}>
                  {stage.Name}
                </Typography>
              </Box>
              <Badge
                badgeContent={leads.length}
                color="primary"
                sx={{ "& .MuiBadge-badge": { fontSize: "0.7rem", height: 18, minWidth: 18 } }}
              />
            </Box>
            <Box sx={{ display: "flex", gap: 1, mt: 0.5, alignItems: "center", flexWrap: "wrap" }}>
              {totalValue > 0 && (
                <Typography variant="caption" color="text.secondary" sx={{ fontSize: "0.72rem" }}>
                  <strong>{formatCurrency(totalValue)}</strong> total
                </Typography>
              )}
              {weightedValue > 0 && (
                <Tooltip title="Valor ponderado = Σ valor × probabilidad">
                  <Typography variant="caption" color="success.main" fontWeight={700} sx={{ fontSize: "0.72rem" }}>
                    {formatCurrency(weightedValue)} ponderado
                  </Typography>
                </Tooltip>
              )}
              {stage.Probability > 0 && (
                <Chip
                  label={`${stage.Probability}%`}
                  size="small"
                  variant="outlined"
                  sx={{ height: 18, fontSize: "0.6rem", fontWeight: 700 }}
                />
              )}
            </Box>
            {stage.Probability > 0 && (
              <LinearProgress
                variant="determinate"
                value={stage.Probability}
                sx={{ mt: 1, height: 3, borderRadius: 2, bgcolor: "grey.200" }}
              />
            )}
          </>
        )}
      </Box>

      {/* Cards area — oculta cuando colapsada */}
      {!collapsed && (
        <Box
          id={`stage-cards-${stage.StageId}`}
          role="list"
          aria-label={`Leads en etapa ${stage.Name}`}
          data-stage-id={stage.StageId}
          sx={{
            p: 1,
            flex: 1,
            overflowY: "auto",
            minHeight: 100,
            maxHeight: "calc(100vh - 320px)",
            "&::-webkit-scrollbar": { width: 4 },
            "&::-webkit-scrollbar-thumb": { bgcolor: "grey.300", borderRadius: 2 },
          }}
        >
          <SortableContext items={sortableIds} strategy={verticalListSortingStrategy}>
            {leads.length === 0 ? (
              <Box
                sx={{
                  p: 3,
                  textAlign: "center",
                  border: "2px dashed",
                  borderColor: isOver ? "primary.main" : "grey.200",
                  borderRadius: 2,
                  transition: "border-color 0.2s",
                }}
              >
                <Typography variant="caption" color={isOver ? "primary.main" : "text.disabled"}>
                  {isOver ? "Soltar aquí" : "Arrastra leads aquí"}
                </Typography>
              </Box>
            ) : (
              leads.map((lead, index) => (
                <SortableLeadCard
                  key={lead.LeadId}
                  lead={lead}
                  stage={stage}
                  onWin={onWin}
                  onLose={onLose}
                  onOpen={onOpen}
                  onFocus={() => onFocusLead(lead.LeadId)}
                  onKeyDown={(e) => onCardKeyDown(e, lead, index)}
                  cardRef={(el) => registerCardRef(lead.LeadId, el)}
                  ariaIndex={index}
                  ariaTotal={leads.length}
                />
              ))
            )}
          </SortableContext>
        </Box>
      )}
    </Paper>
  );
}

// ─── Main Pipeline Kanban ───────────────────────────────────────────────────

export default function PipelineKanban() {
  const [selectedPipelineId, setSelectedPipelineId] = useState<number | undefined>();
  const [filterValues, setFilterValues] = useState<Record<string, string>>({});
  const [newLeadOpen, setNewLeadOpen] = useState(false);
  const [loseDialog, setLoseDialog] = useState<Lead | null>(null);
  const [loseReason, setLoseReason] = useState("");
  const [activeDragLead, setActiveDragLead] = useState<Lead | null>(null);

  /* ─── Drawer de detalle — deep-link ?lead=<id> ─── */
  const leadDrawer = useDrawerQueryParam("lead");
  const drawerLeadId = leadDrawer.id ? Number(leadDrawer.id) : null;

  // Form state for new lead
  const [newLead, setNewLead] = useState({
    contactName: "",
    companyName: "",
    email: "",
    phone: "",
    estimatedValue: "",
    priority: "MEDIUM",
    source: "WEB",
    notes: "",
  });

  // ─── Queries ──────────────────────────────────────────────
  const { data: pipelinesData, isLoading: loadingPipelines } = usePipelinesList();
  const pipelines = pipelinesData?.data ?? pipelinesData?.rows ?? pipelinesData ?? [];

  const activePipelineId =
    selectedPipelineId ?? (pipelines.length > 0 ? pipelines[0]?.PipelineId : undefined);

  const { data: stagesData, isLoading: loadingStages } = usePipelineStages(activePipelineId);
  const stages: PipelineStage[] = (stagesData?.data ?? stagesData?.rows ?? stagesData ?? []).sort(
    (a: PipelineStage, b: PipelineStage) => a.SortOrder - b.SortOrder,
  );

  const filter: LeadFilter = {
    pipelineId: activePipelineId,
    ...(filterValues.priority ? { priority: filterValues.priority as Priority } : {}),
    ...(filterValues.status ? { status: filterValues.status } : {}),
    ...(filterValues.assignedTo
      ? { assignedTo: Number(filterValues.assignedTo) }
      : {}),
    limit: 500,
  };
  const { data: leadsData, isLoading: loadingLeads } = useLeadsList(
    activePipelineId ? filter : undefined,
  );
  const leadsRaw: Lead[] = leadsData?.data ?? leadsData?.rows ?? leadsData ?? [];

  // Source filter (cliente — backend aún no lo expone en LeadFilter)
  const leads = useMemo(() => {
    let out = leadsRaw;
    if (filterValues.source) {
      out = out.filter((l) => l.Source === filterValues.source);
    }
    return out;
  }, [leadsRaw, filterValues.source]);

  // ─── Mutations ────────────────────────────────────────────
  const createLead = useCreateLead();
  const moveStage = useMoveLeadStage();
  const winLead = useWinLead();
  const loseLead = useLoseLead();

  // ─── Leads grouped by stage ───────────────────────────────
  const leadsByStage = useMemo(() => {
    const map: Record<number, Lead[]> = {};
    for (const s of stages) map[s.StageId] = [];
    for (const l of leads) {
      if (!map[l.StageId]) map[l.StageId] = [];
      map[l.StageId].push(l);
    }
    return map;
  }, [leads, stages]);

  // ─── Collapsed columns state (persistido en localStorage) ─
  const storageKey = LOCAL_STORAGE_COLLAPSED_KEY(activePipelineId);
  const [collapsedStages, setCollapsedStages] = useState<Record<number, boolean>>({});

  useEffect(() => {
    if (!activePipelineId) return;
    try {
      const raw = typeof window !== "undefined" ? window.localStorage.getItem(storageKey) : null;
      if (raw) setCollapsedStages(JSON.parse(raw));
      else setCollapsedStages({});
    } catch {
      setCollapsedStages({});
    }
  }, [storageKey, activePipelineId]);

  const toggleCollapse = useCallback(
    (stageId: number) => {
      setCollapsedStages((prev) => {
        const next = { ...prev, [stageId]: !prev[stageId] };
        try {
          if (typeof window !== "undefined" && activePipelineId) {
            window.localStorage.setItem(storageKey, JSON.stringify(next));
          }
        } catch {
          /* ignore quota errors */
        }
        return next;
      });
    },
    [storageKey, activePipelineId],
  );

  // ─── DnD sensors ──────────────────────────────────────────
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor),
  );

  // ─── aria-live region para anunciar movimientos ───────────
  const [liveMessage, setLiveMessage] = useState("");
  const announce = useCallback((msg: string) => {
    setLiveMessage(msg);
    setTimeout(() => setLiveMessage(""), 1000);
  }, []);

  // ─── Focus management (keyboard nav) ──────────────────────
  const [focusedLeadId, setFocusedLeadId] = useState<number | null>(null);
  const cardRefs = useRef<Map<number, HTMLDivElement>>(new Map());

  const registerCardRef = useCallback((leadId: number, el: HTMLDivElement | null) => {
    if (el) cardRefs.current.set(leadId, el);
    else cardRefs.current.delete(leadId);
  }, []);

  const moveLeadToStage = useCallback(
    (lead: Lead, newStageId: number, newStageName?: string) => {
      moveStage.mutate(
        { leadId: lead.LeadId, newStageId },
        {
          onSuccess: () => {
            announce(
              `Lead ${lead.LeadCode ?? lead.LeadId} movido a ${newStageName ?? "nueva etapa"}`,
            );
          },
        },
      );
    },
    [moveStage, announce],
  );

  // Keyboard nav callback por card
  const handleCardKeyDown = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>, lead: Lead, index: number) => {
      const stageIndex = stages.findIndex((s) => s.StageId === lead.StageId);
      if (stageIndex < 0) return;

      if (e.key === "Enter") {
        e.preventDefault();
        leadDrawer.openDrawer(lead.LeadId);
        return;
      }

      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault();
        const colLeads = leadsByStage[lead.StageId] ?? [];
        const nextIndex =
          e.key === "ArrowDown"
            ? Math.min(index + 1, colLeads.length - 1)
            : Math.max(index - 1, 0);
        const target = colLeads[nextIndex];
        if (target) {
          setFocusedLeadId(target.LeadId);
          cardRefs.current.get(target.LeadId)?.focus();
        }
        return;
      }

      if (e.key === "ArrowLeft" || e.key === "ArrowRight") {
        e.preventDefault();
        const dir = e.key === "ArrowRight" ? 1 : -1;
        const targetStage = stages[stageIndex + dir];
        if (!targetStage) return;
        moveLeadToStage(lead, targetStage.StageId, targetStage.Name);
      }
    },
    [leadsByStage, stages, leadDrawer, moveLeadToStage],
  );

  // ─── DnD handlers ─────────────────────────────────────────
  const handleDragStart = useCallback((event: DragStartEvent) => {
    const { active } = event;
    const lead = active.data.current?.lead as Lead | undefined;
    if (lead) setActiveDragLead(lead);
  }, []);

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      setActiveDragLead(null);
      const { active, over } = event;
      if (!over) return;

      const activeLead = active.data.current?.lead as Lead | undefined;
      if (!activeLead) return;

      let targetStageId: number | null = null;
      if (over.data.current?.type === "stage") {
        targetStageId = over.data.current.stage.StageId;
      } else if (over.data.current?.type === "lead") {
        targetStageId = over.data.current.lead.StageId;
      }

      if (targetStageId && targetStageId !== activeLead.StageId) {
        const targetStage = stages.find((s) => s.StageId === targetStageId);
        moveLeadToStage(activeLead, targetStageId, targetStage?.Name);
      }
    },
    [moveLeadToStage, stages],
  );

  // ─── CRUD handlers ────────────────────────────────────────
  const handleCreateLead = () => {
    if (!activePipelineId || !stages.length) return;
    createLead.mutate(
      {
        pipelineId: activePipelineId,
        stageId: stages[0]?.StageId,
        ...newLead,
        estimatedValue: Number(newLead.estimatedValue) || 0,
      },
      {
        onSuccess: () => {
          setNewLeadOpen(false);
          setNewLead({
            contactName: "",
            companyName: "",
            email: "",
            phone: "",
            estimatedValue: "",
            priority: "MEDIUM",
            source: "WEB",
            notes: "",
          });
        },
      },
    );
  };

  const handleWin = (lead: Lead) => winLead.mutate({ id: lead.LeadId });
  const handleLose = () => {
    if (!loseDialog) return;
    loseLead.mutate({ id: loseDialog.LeadId, reason: loseReason });
    setLoseDialog(null);
    setLoseReason("");
  };
  const handleOpen = useCallback(
    (lead: Lead) => {
      leadDrawer.openDrawer(lead.LeadId);
    },
    [leadDrawer],
  );

  const isLoading = loadingPipelines || loadingStages || loadingLeads;

  // ─── Summary stats ────────────────────────────────────────
  const openLeads = useMemo(() => leads.filter((l) => l.Status === "OPEN"), [leads]);
  const totalLeads = openLeads.length;
  const totalValue = openLeads.reduce((s, l) => s + (l.EstimatedValue ?? 0), 0);
  const totalWeighted = useMemo(
    () =>
      openLeads.reduce((sum, l) => {
        const stage = stages.find((s) => s.StageId === l.StageId);
        const prob = stage?.Probability ?? 0;
        return sum + ((l.EstimatedValue ?? 0) * prob) / 100;
      }, 0),
    [openLeads, stages],
  );

  // ─── Filter panel definitions ─────────────────────────────
  const filterFields: FilterFieldDef[] = useMemo(() => {
    const ownerOptions = Array.from(
      leadsRaw.reduce((acc, l) => {
        if (l.AssignedTo && l.AssignedToName) {
          acc.set(String(l.AssignedTo), l.AssignedToName);
        }
        return acc;
      }, new Map<string, string>()),
    ).map(([value, label]) => ({ value, label }));

    const pipelineOptions = (pipelines as Array<{ PipelineId: number; Name: string }>).map(
      (p) => ({
        value: String(p.PipelineId),
        label: p.Name,
      }),
    );

    const fields: FilterFieldDef[] = [
      {
        field: "priority",
        label: "Prioridad",
        type: "select",
        options: PRIORITY_VALUES.map((p) => ({ value: p, label: PRIORITY_LABELS[p] })),
      },
      {
        field: "status",
        label: "Estado",
        type: "select",
        options: [
          { value: "OPEN", label: "Abierto" },
          { value: "WON", label: "Ganado" },
          { value: "LOST", label: "Perdido" },
        ],
      },
      {
        field: "assignedTo",
        label: "Responsable",
        type: "select",
        options: ownerOptions,
      },
      {
        field: "source",
        label: "Origen",
        type: "select",
        options: SOURCE_OPTIONS,
      },
    ];

    if (pipelineOptions.length > 1) {
      fields.push({
        field: "pipelineId",
        label: "Pipeline",
        type: "select",
        options: pipelineOptions,
      });
    }

    return fields;
  }, [leadsRaw, pipelines]);

  const handleFiltersChange = useCallback((values: Record<string, string>) => {
    setFilterValues(values);
    if (values.pipelineId) {
      const n = Number(values.pipelineId);
      if (!Number.isNaN(n)) setSelectedPipelineId(n);
    }
  }, []);

  return (
    <Box>
      {/* ─── aria-live region ────────────────────────────────── */}
      <Box
        aria-live="polite"
        aria-atomic="true"
        sx={{
          position: "absolute",
          width: 1,
          height: 1,
          overflow: "hidden",
          clip: "rect(0 0 0 0)",
          whiteSpace: "nowrap",
        }}
      >
        {liveMessage}
      </Box>

      {/* ─── Header ──────────────────────────────────────────── */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 2,
          flexWrap: "wrap",
          gap: 1.5,
        }}
      >
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 800 }}>
            Pipeline
          </Typography>
          {!isLoading && (
            <Typography variant="caption" color="text.secondary">
              {totalLeads} leads abiertos · {formatCurrency(totalValue)} total ·{" "}
              <strong>{formatCurrency(totalWeighted)}</strong> ponderado
            </Typography>
          )}
        </Box>
        <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
          {pipelines.length > 1 && (
            <FormControl size="small" sx={{ minWidth: 160 }}>
              <InputLabel>Pipeline</InputLabel>
              <Select
                value={activePipelineId ?? ""}
                label="Pipeline"
                onChange={(e) => setSelectedPipelineId(Number(e.target.value))}
              >
                {pipelines.map((p: any) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>
                    {p.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          )}
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setNewLeadOpen(true)}
            size="small"
          >
            Nuevo Lead
          </Button>
        </Box>
      </Box>

      {/* ─── FilterPanel unificado ───────────────────────────── */}
      <ZenttoFilterPanel
        filters={filterFields}
        values={filterValues}
        onChange={handleFiltersChange}
      />

      {/* ─── Kanban Board with DnD ───────────────────────────── */}
      {isLoading ? (
        <Box sx={{ display: "flex", gap: 2, overflow: "hidden" }}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton
              key={i}
              variant="rectangular"
              width={290}
              height={450}
              sx={{ borderRadius: 3, flexShrink: 0 }}
            />
          ))}
        </Box>
      ) : stages.length === 0 ? (
        <Alert severity="info" sx={{ borderRadius: 2 }}>
          No hay etapas configuradas para este pipeline. Configure las etapas desde la
          administración de CRM.
        </Alert>
      ) : (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCorners}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          <Box
            sx={{
              display: "flex",
              gap: 2,
              overflowX: "auto",
              pb: 2,
              minHeight: 450,
              "&::-webkit-scrollbar": { height: 6 },
              "&::-webkit-scrollbar-thumb": { bgcolor: "grey.300", borderRadius: 3 },
            }}
          >
            {stages.map((stage) => {
              const stageLeads = leadsByStage[stage.StageId] ?? [];
              const stageTotal = stageLeads.reduce((sum, l) => sum + (l.EstimatedValue ?? 0), 0);
              const weighted = computeWeightedValue(stageLeads, stage);
              return (
                <StageColumn
                  key={stage.StageId}
                  stage={stage}
                  leads={stageLeads}
                  totalValue={stageTotal}
                  weightedValue={weighted}
                  collapsed={!!collapsedStages[stage.StageId]}
                  onToggleCollapse={() => toggleCollapse(stage.StageId)}
                  onWin={handleWin}
                  onLose={(l) => setLoseDialog(l)}
                  onOpen={handleOpen}
                  focusedLeadId={focusedLeadId}
                  onFocusLead={setFocusedLeadId}
                  onCardKeyDown={handleCardKeyDown}
                  registerCardRef={registerCardRef}
                />
              );
            })}
          </Box>

          {/* Drag overlay */}
          <DragOverlay>
            {activeDragLead ? (
              <Box sx={{ width: 280 }}>
                <LeadCardContent
                  lead={activeDragLead}
                  stage={stages.find((s) => s.StageId === activeDragLead.StageId)}
                  onWin={() => {}}
                  onLose={() => {}}
                  overlay
                />
              </Box>
            ) : null}
          </DragOverlay>
        </DndContext>
      )}

      {/* ─── Drawer de detalle (lateral derecho) ─── */}
      <RightDetailDrawer
        open={leadDrawer.open && drawerLeadId !== null}
        onClose={leadDrawer.closeDrawer}
        title="Detalle del lead"
        subtitle={drawerLeadId ? `#${drawerLeadId}` : undefined}
      >
        {drawerLeadId && (
          <LeadDetailPanel leadId={drawerLeadId} onClose={leadDrawer.closeDrawer} />
        )}
      </RightDetailDrawer>

      {/* ─── Lose Dialog ─────────────────────────────────────── */}
      <FormDialog
        open={!!loseDialog}
        onClose={() => {
          setLoseDialog(null);
          setLoseReason("");
        }}
        onSave={handleLose}
        title="Marcar lead como perdido"
        subtitle={loseDialog ? `${loseDialog.LeadCode} - ${loseDialog.ContactName}` : ""}
        mode="edit"
        saveLabel="Confirmar pérdida"
        disableSave={!loseReason.trim()}
        loading={loseLead.isPending}
      >
        <TextField
          label="Motivo de la pérdida"
          fullWidth
          multiline
          rows={3}
          value={loseReason}
          onChange={(e) => setLoseReason(e.target.value)}
          placeholder="Precio, competencia, timing, no responde..."
        />
      </FormDialog>

      {/* ─── New Lead Dialog ─────────────────────────────────── */}
      <FormDialog
        open={newLeadOpen}
        onClose={() => setNewLeadOpen(false)}
        onSave={handleCreateLead}
        title="Nuevo Lead"
        subtitle="Agregar prospecto al pipeline"
        mode="create"
        saveLabel="Crear Lead"
        disableSave={!newLead.contactName.trim()}
        loading={createLead.isPending}
      >
        <Stack spacing={2}>
          <TextField
            label="Nombre de contacto"
            fullWidth
            required
            value={newLead.contactName}
            onChange={(e) => setNewLead({ ...newLead, contactName: e.target.value })}
          />
          <TextField
            label="Empresa"
            fullWidth
            value={newLead.companyName}
            onChange={(e) => setNewLead({ ...newLead, companyName: e.target.value })}
          />
          <Stack direction="row" spacing={2}>
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={newLead.email}
              onChange={(e) => setNewLead({ ...newLead, email: e.target.value })}
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={newLead.phone}
              onChange={(e) => setNewLead({ ...newLead, phone: e.target.value })}
            />
          </Stack>
          <Stack direction="row" spacing={2}>
            <TextField
              label="Valor estimado"
              fullWidth
              type="number"
              value={newLead.estimatedValue}
              onChange={(e) => setNewLead({ ...newLead, estimatedValue: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Prioridad</InputLabel>
              <Select
                value={newLead.priority}
                label="Prioridad"
                onChange={(e) => setNewLead({ ...newLead, priority: e.target.value })}
              >
                {PRIORITY_VALUES.map((p) => (
                  <MenuItem key={p} value={p}>
                    {PRIORITY_LABELS[p]}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
          <FormControl fullWidth>
            <InputLabel>Origen</InputLabel>
            <Select
              value={newLead.source}
              label="Origen"
              onChange={(e) => setNewLead({ ...newLead, source: e.target.value })}
            >
              {SOURCE_OPTIONS.map((s) => (
                <MenuItem key={s.value} value={s.value}>
                  {s.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            label="Notas"
            fullWidth
            multiline
            rows={2}
            value={newLead.notes}
            onChange={(e) => setNewLead({ ...newLead, notes: e.target.value })}
          />
        </Stack>
      </FormDialog>
    </Box>
  );
}
