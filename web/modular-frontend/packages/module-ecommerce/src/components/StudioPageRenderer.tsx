"use client";

import React from "react";
import {
  Box,
  Button,
  Container,
  Grid,
  Paper,
  Typography,
  Divider,
  Stack,
} from "@mui/material";
import StorefrontOutlined from "@mui/icons-material/StorefrontOutlined";
import SupportAgentOutlined from "@mui/icons-material/SupportAgentOutlined";
import CampaignOutlined from "@mui/icons-material/CampaignOutlined";
import HandshakeOutlined from "@mui/icons-material/HandshakeOutlined";
import EmailOutlined from "@mui/icons-material/EmailOutlined";
import CheckCircleOutline from "@mui/icons-material/CheckCircleOutline";
import QuestionAnswerOutlined from "@mui/icons-material/QuestionAnswerOutlined";
import GroupOutlined from "@mui/icons-material/GroupOutlined";
import TimelineOutlined from "@mui/icons-material/TimelineOutlined";
import WorkOutline from "@mui/icons-material/WorkOutline";
import PlaceOutlined from "@mui/icons-material/PlaceOutlined";
import AssignmentReturnOutlined from "@mui/icons-material/AssignmentReturnOutlined";
import Avatar from "@mui/material/Avatar";
import Chip from "@mui/material/Chip";

/**
 * LandingConfig — schema JSON compatible con @zentto/studio-core.
 * Hacemos un renderer MUI propio (Opción B) en lugar de importar @zentto/studio-react
 * porque el studio original usa web components (Lit) que chocan con Next.js SSR.
 */

export type LandingSection =
  | HeroSection
  | ContentSection
  | FeaturesSection
  | FaqSection
  | CtaSection
  | ContactSection
  | StatsSection
  | TeamSection
  | TimelineSection
  | JobsSection
  | ReturnStepsSection;

interface HeroSection {
  type: "hero";
  title: string;
  subtitle?: string;
  ctaLabel?: string;
  ctaHref?: string;
}

interface ContentSection {
  type: "content";
  markdown: string;
}

interface FeaturesSection {
  type: "features";
  items: Array<{ title: string; description: string; icon?: string }>;
}

interface FaqSection {
  type: "faq";
  items: Array<{ question: string; answer: string }>;
}

interface CtaSection {
  type: "cta";
  title: string;
  subtitle?: string;
  ctaLabel?: string;
  ctaHref?: string;
}

interface ContactSection {
  type: "contact";
  title?: string;
  email?: string;
  showForm?: boolean;
}

interface StatsSection {
  type: "stats";
  items: Array<{ value: string; label: string }>;
}

interface TeamSection {
  type: "team";
  title?: string;
  members: Array<{ name: string; role?: string; photo?: string; bio?: string }>;
}

interface TimelineSection {
  type: "timeline";
  title?: string;
  events: Array<{ year: string; title: string; description?: string }>;
}

interface JobsSection {
  type: "jobs";
  title?: string;
  jobs: Array<{ title: string; location?: string; type?: string; href?: string }>;
  emptyLabel?: string;
}

interface ReturnStepsSection {
  type: "return-steps";
  title?: string;
  steps: Array<{ step: number | string; title: string; description?: string }>;
}

export interface LandingConfig {
  sections: LandingSection[];
}

const ICONS: Record<string, React.ReactNode> = {
  store: <StorefrontOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
  support: <SupportAgentOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
  press: <CampaignOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
  partners: <HandshakeOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
  email: <EmailOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
  check: <CheckCircleOutline sx={{ fontSize: 40, color: "#ff9900" }} />,
  faq: <QuestionAnswerOutlined sx={{ fontSize: 40, color: "#ff9900" }} />,
};

// ─── Markdown mínimo ───────────────────────────────────
// Soporta # / ## / ###, listas -, párrafos, **bold**.
export function renderMarkdown(md: string): React.ReactNode {
  const lines = md.split(/\r?\n/);
  const nodes: React.ReactNode[] = [];
  let listBuf: string[] = [];
  let paraBuf: string[] = [];

  const flushList = () => {
    if (!listBuf.length) return;
    nodes.push(
      <Box component="ul" key={`ul-${nodes.length}`} sx={{ pl: 3, my: 1.5 }}>
        {listBuf.map((li, i) => (
          <li key={i} style={{ marginBottom: 6, lineHeight: 1.7 }}>
            {inline(li)}
          </li>
        ))}
      </Box>
    );
    listBuf = [];
  };

  const flushPara = () => {
    if (!paraBuf.length) return;
    nodes.push(
      <Typography key={`p-${nodes.length}`} variant="body1" paragraph sx={{ color: "#333", lineHeight: 1.75 }}>
        {inline(paraBuf.join(" "))}
      </Typography>
    );
    paraBuf = [];
  };

  for (const raw of lines) {
    const line = raw.trim();
    if (!line) {
      flushList();
      flushPara();
      continue;
    }
    if (line.startsWith("### ")) {
      flushList();
      flushPara();
      nodes.push(
        <Typography key={`h3-${nodes.length}`} variant="h6" fontWeight={700} sx={{ mt: 2, color: "#131921" }}>
          {line.slice(4)}
        </Typography>
      );
    } else if (line.startsWith("## ")) {
      flushList();
      flushPara();
      nodes.push(
        <Typography key={`h2-${nodes.length}`} variant="h5" fontWeight={700} sx={{ mt: 3, color: "#131921" }}>
          {line.slice(3)}
        </Typography>
      );
    } else if (line.startsWith("# ")) {
      flushList();
      flushPara();
      nodes.push(
        <Typography key={`h1-${nodes.length}`} variant="h4" fontWeight={800} sx={{ mt: 3, color: "#131921" }}>
          {line.slice(2)}
        </Typography>
      );
    } else if (line.startsWith("- ")) {
      flushPara();
      listBuf.push(line.slice(2));
    } else if (line === "---") {
      flushList();
      flushPara();
      nodes.push(<Divider key={`hr-${nodes.length}`} sx={{ my: 3 }} />);
    } else {
      flushList();
      paraBuf.push(line);
    }
  }
  flushList();
  flushPara();
  return <>{nodes}</>;
}

function inline(text: string): React.ReactNode {
  // **bold**
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return parts.map((p, i) => {
    if (p.startsWith("**") && p.endsWith("**")) {
      return (
        <strong key={i} style={{ color: "#131921" }}>
          {p.slice(2, -2)}
        </strong>
      );
    }
    return <React.Fragment key={i}>{p}</React.Fragment>;
  });
}

// ─── Secciones ─────────────────────────────────────────

function HeroBlock({ section }: { section: HeroSection }) {
  return (
    <Box
      sx={{
        background: "linear-gradient(135deg, #131921 0%, #232f3e 100%)",
        color: "#fff",
        py: { xs: 6, md: 10 },
        textAlign: "center",
      }}
    >
      <Container maxWidth="md">
        <Typography variant="h3" fontWeight={700} gutterBottom>
          {section.title}
        </Typography>
        {section.subtitle && (
          <Typography variant="h6" sx={{ color: "#ccc", maxWidth: 600, mx: "auto", lineHeight: 1.6 }}>
            {section.subtitle}
          </Typography>
        )}
        {section.ctaLabel && section.ctaHref && (
          <Button
            variant="contained"
            href={section.ctaHref}
            size="large"
            sx={{
              mt: 4,
              bgcolor: "#ff9900",
              color: "#131921",
              fontWeight: 700,
              textTransform: "none",
              px: 4,
              py: 1.5,
              "&:hover": { bgcolor: "#e88a00" },
            }}
          >
            {section.ctaLabel}
          </Button>
        )}
      </Container>
    </Box>
  );
}

function ContentBlock({ section }: { section: ContentSection }) {
  return (
    <Box sx={{ bgcolor: "#fff", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="md">{renderMarkdown(section.markdown)}</Container>
    </Box>
  );
}

function FeaturesBlock({ section }: { section: FeaturesSection }) {
  return (
    <Box sx={{ bgcolor: "#eaeded", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="lg">
        <Grid container spacing={3}>
          {section.items.map((item, i) => (
            <Grid item xs={12} sm={6} md={Math.min(4, Math.ceil(12 / section.items.length))} key={i}>
              <Paper elevation={1} sx={{ p: 3, borderRadius: 3, height: "100%", textAlign: "center" }}>
                <Box sx={{ mb: 1.5 }}>{ICONS[item.icon || ""] || ICONS.check}</Box>
                <Typography variant="h6" fontWeight={700} sx={{ color: "#131921", mb: 1 }}>
                  {item.title}
                </Typography>
                <Typography variant="body2" sx={{ color: "#555", lineHeight: 1.7 }}>
                  {item.description}
                </Typography>
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  );
}

function FaqBlock({ section }: { section: FaqSection }) {
  return (
    <Box sx={{ bgcolor: "#fff", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="md">
        <Typography variant="h4" fontWeight={700} sx={{ color: "#131921", mb: 3, textAlign: "center" }}>
          Preguntas frecuentes
        </Typography>
        <Stack spacing={2}>
          {section.items.map((item, i) => (
            <Paper
              key={i}
              elevation={0}
              sx={{ p: 3, borderRadius: 2, border: "1px solid #e0e0e0" }}
            >
              <Typography variant="subtitle1" fontWeight={700} sx={{ color: "#131921", mb: 1 }}>
                {item.question}
              </Typography>
              <Typography variant="body2" sx={{ color: "#555", lineHeight: 1.7 }}>
                {item.answer}
              </Typography>
            </Paper>
          ))}
        </Stack>
      </Container>
    </Box>
  );
}

function CtaBlock({ section }: { section: CtaSection }) {
  return (
    <Box sx={{ bgcolor: "#232f3e", color: "#fff", py: { xs: 5, md: 7 }, textAlign: "center" }}>
      <Container maxWidth="sm">
        <Typography variant="h4" fontWeight={700} gutterBottom>
          {section.title}
        </Typography>
        {section.subtitle && (
          <Typography variant="body1" sx={{ color: "#ccc", mb: 3 }}>
            {section.subtitle}
          </Typography>
        )}
        {section.ctaLabel && section.ctaHref && (
          <Button
            variant="contained"
            href={section.ctaHref}
            sx={{
              bgcolor: "#ff9900",
              color: "#131921",
              fontWeight: 700,
              textTransform: "none",
              px: 4,
              py: 1.5,
              "&:hover": { bgcolor: "#e88a00" },
            }}
          >
            {section.ctaLabel}
          </Button>
        )}
      </Container>
    </Box>
  );
}

function StatsBlock({ section }: { section: StatsSection }) {
  return (
    <Box sx={{ bgcolor: "#131921", color: "#fff", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="lg">
        <Grid container spacing={2}>
          {section.items.map((s, i) => (
            <Grid item xs={6} md={12 / section.items.length} key={i} sx={{ textAlign: "center" }}>
              <Typography variant="h3" fontWeight={800} sx={{ color: "#ff9900" }}>
                {s.value}
              </Typography>
              <Typography variant="body2" sx={{ color: "#ccc", mt: 0.5 }}>
                {s.label}
              </Typography>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  );
}

// Re-export contact block como componente standalone (lo usaremos también en contacto/page.tsx)
export { ContactForm } from "./ContactForm";
import { ContactForm } from "./ContactForm";

function ContactBlock({ section }: { section: ContactSection }) {
  return (
    <Box sx={{ bgcolor: "#eaeded", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="sm">
        {section.title && (
          <Typography
            variant="h4"
            fontWeight={700}
            sx={{ color: "#131921", mb: 3, textAlign: "center" }}
          >
            {section.title}
          </Typography>
        )}
        {section.showForm !== false && <ContactForm />}
        {section.email && (
          <Box sx={{ textAlign: "center", mt: 3 }}>
            <Button
              href={`mailto:${section.email}`}
              startIcon={<EmailOutlined />}
              sx={{ color: "#131921", textTransform: "none", fontWeight: 600 }}
            >
              {section.email}
            </Button>
          </Box>
        )}
      </Container>
    </Box>
  );
}

function TeamBlock({ section }: { section: TeamSection }) {
  return (
    <Box sx={{ bgcolor: "#fff", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="lg">
        {section.title && (
          <Typography variant="h4" fontWeight={700} sx={{ color: "#131921", mb: 3, textAlign: "center" }}>
            {section.title}
          </Typography>
        )}
        <Grid container spacing={3}>
          {section.members.map((m, i) => (
            <Grid item xs={12} sm={6} md={4} key={i}>
              <Paper elevation={1} sx={{ p: 3, borderRadius: 3, textAlign: "center", height: "100%" }}>
                {m.photo ? (
                  <Avatar src={m.photo} alt={m.name} sx={{ width: 96, height: 96, mx: "auto", mb: 2 }} />
                ) : (
                  <Avatar sx={{ width: 96, height: 96, mx: "auto", mb: 2, bgcolor: "#ff9900" }}>
                    <GroupOutlined sx={{ color: "#131921" }} />
                  </Avatar>
                )}
                <Typography variant="h6" fontWeight={700} sx={{ color: "#131921" }}>
                  {m.name}
                </Typography>
                {m.role && (
                  <Typography variant="body2" sx={{ color: "#ff9900", fontWeight: 600, mb: 1 }}>
                    {m.role}
                  </Typography>
                )}
                {m.bio && (
                  <Typography variant="body2" sx={{ color: "#555", lineHeight: 1.7 }}>
                    {m.bio}
                  </Typography>
                )}
              </Paper>
            </Grid>
          ))}
        </Grid>
      </Container>
    </Box>
  );
}

function TimelineBlock({ section }: { section: TimelineSection }) {
  return (
    <Box sx={{ bgcolor: "#eaeded", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="md">
        {section.title && (
          <Typography variant="h4" fontWeight={700} sx={{ color: "#131921", mb: 4, textAlign: "center" }}>
            {section.title}
          </Typography>
        )}
        <Stack spacing={0}>
          {section.events.map((e, i) => (
            <Box key={i} sx={{ display: "flex", gap: 3, position: "relative" }}>
              <Box
                sx={{
                  minWidth: 80,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                }}
              >
                <Box
                  sx={{
                    bgcolor: "#ff9900",
                    color: "#131921",
                    fontWeight: 700,
                    borderRadius: "50%",
                    width: 48,
                    height: 48,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: 14,
                    boxShadow: "0 0 0 4px #eaeded",
                    zIndex: 1,
                  }}
                >
                  {e.year}
                </Box>
                {i < section.events.length - 1 && (
                  <Box sx={{ width: 2, flex: 1, bgcolor: "#d0d0d0", my: 0.5 }} />
                )}
              </Box>
              <Box sx={{ flex: 1, pb: i < section.events.length - 1 ? 4 : 0 }}>
                <Typography variant="h6" fontWeight={700} sx={{ color: "#131921" }}>
                  {e.title}
                </Typography>
                {e.description && (
                  <Typography variant="body2" sx={{ color: "#555", lineHeight: 1.7, mt: 0.5 }}>
                    {e.description}
                  </Typography>
                )}
              </Box>
            </Box>
          ))}
        </Stack>
      </Container>
    </Box>
  );
}

function JobsBlock({ section }: { section: JobsSection }) {
  return (
    <Box sx={{ bgcolor: "#fff", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="md">
        {section.title && (
          <Typography variant="h4" fontWeight={700} sx={{ color: "#131921", mb: 3, textAlign: "center" }}>
            {section.title}
          </Typography>
        )}
        {section.jobs.length === 0 ? (
          <Paper elevation={0} sx={{ p: 4, textAlign: "center", border: "1px dashed #d0d0d0", borderRadius: 2 }}>
            <WorkOutline sx={{ fontSize: 40, color: "#ff9900", mb: 1 }} />
            <Typography variant="body1" sx={{ color: "#555" }}>
              {section.emptyLabel || "Por ahora no tenemos vacantes abiertas, pero siempre buscamos talento."}
            </Typography>
          </Paper>
        ) : (
          <Stack spacing={2}>
            {section.jobs.map((j, i) => (
              <Paper
                key={i}
                component={j.href ? "a" : "div"}
                href={j.href}
                elevation={0}
                sx={{
                  p: 3,
                  borderRadius: 2,
                  border: "1px solid #e0e0e0",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  gap: 2,
                  textDecoration: "none",
                  transition: "all 150ms",
                  "&:hover": j.href ? { borderColor: "#ff9900", transform: "translateY(-2px)" } : {},
                }}
              >
                <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                  <WorkOutline sx={{ color: "#ff9900" }} />
                  <Box>
                    <Typography variant="subtitle1" fontWeight={700} sx={{ color: "#131921" }}>
                      {j.title}
                    </Typography>
                    <Box sx={{ display: "flex", gap: 1, mt: 0.5, flexWrap: "wrap" }}>
                      {j.location && (
                        <Chip
                          size="small"
                          icon={<PlaceOutlined sx={{ fontSize: 14 }} />}
                          label={j.location}
                          sx={{ bgcolor: "#eaeded" }}
                        />
                      )}
                      {j.type && (
                        <Chip size="small" label={j.type} sx={{ bgcolor: "#fff3e0", color: "#131921" }} />
                      )}
                    </Box>
                  </Box>
                </Box>
                {j.href && (
                  <Typography variant="body2" sx={{ color: "#ff9900", fontWeight: 600 }}>
                    Aplicar →
                  </Typography>
                )}
              </Paper>
            ))}
          </Stack>
        )}
      </Container>
    </Box>
  );
}

function ReturnStepsBlock({ section }: { section: ReturnStepsSection }) {
  return (
    <Box sx={{ bgcolor: "#eaeded", py: { xs: 4, md: 6 } }}>
      <Container maxWidth="md">
        {section.title && (
          <Typography variant="h4" fontWeight={700} sx={{ color: "#131921", mb: 3, textAlign: "center" }}>
            {section.title}
          </Typography>
        )}
        <Stack spacing={2}>
          {section.steps.map((s, i) => (
            <Paper
              key={i}
              elevation={0}
              sx={{ p: 3, borderRadius: 2, border: "1px solid #e0e0e0", display: "flex", gap: 2, alignItems: "flex-start" }}
            >
              <Box
                sx={{
                  minWidth: 48,
                  height: 48,
                  borderRadius: "50%",
                  bgcolor: "#ff9900",
                  color: "#131921",
                  fontWeight: 800,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                {typeof s.step === "number" ? s.step : String(s.step)}
              </Box>
              <Box sx={{ flex: 1 }}>
                <Typography variant="subtitle1" fontWeight={700} sx={{ color: "#131921" }}>
                  {s.title}
                </Typography>
                {s.description && (
                  <Typography variant="body2" sx={{ color: "#555", lineHeight: 1.7, mt: 0.5 }}>
                    {s.description}
                  </Typography>
                )}
              </Box>
              <AssignmentReturnOutlined sx={{ color: "#ff9900", display: { xs: "none", sm: "block" } }} />
            </Paper>
          ))}
        </Stack>
      </Container>
    </Box>
  );
}

// ─── Renderer principal ────────────────────────────────

export interface StudioPageRendererProps {
  config: LandingConfig | null | undefined;
}

export default function StudioPageRenderer({ config }: StudioPageRendererProps) {
  if (!config || !Array.isArray(config.sections)) {
    return (
      <Container maxWidth="md" sx={{ py: 8 }}>
        <Typography variant="body1" color="text.secondary">
          Esta página aún no tiene contenido configurado.
        </Typography>
      </Container>
    );
  }
  return (
    <Box sx={{ bgcolor: "#eaeded", minHeight: "100vh" }}>
      {config.sections.map((section, i) => {
        switch (section.type) {
          case "hero":
            return <HeroBlock key={i} section={section as HeroSection} />;
          case "content":
            return <ContentBlock key={i} section={section as ContentSection} />;
          case "features":
            return <FeaturesBlock key={i} section={section as FeaturesSection} />;
          case "faq":
            return <FaqBlock key={i} section={section as FaqSection} />;
          case "cta":
            return <CtaBlock key={i} section={section as CtaSection} />;
          case "contact":
            return <ContactBlock key={i} section={section as ContactSection} />;
          case "stats":
            return <StatsBlock key={i} section={section as StatsSection} />;
          case "team":
            return <TeamBlock key={i} section={section as TeamSection} />;
          case "timeline":
            return <TimelineBlock key={i} section={section as TimelineSection} />;
          case "jobs":
            return <JobsBlock key={i} section={section as JobsSection} />;
          case "return-steps":
            return <ReturnStepsBlock key={i} section={section as ReturnStepsSection} />;
          default:
            return null;
        }
      })}
    </Box>
  );
}
