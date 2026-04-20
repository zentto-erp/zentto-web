/**
 * LandingFooter — footer enterprise 4 columnas + bottom bar.
 * Server Component. Sin newsletter form decorativo (si se requiere newsletter
 * real, agregar como sección dedicada con endpoint funcional — NO aquí).
 */

import * as React from "react";
import BoxComp from "@mui/material/Box";
// Cast de Box a any para permitir `component` polimórfico con `href`.
// MUI sin TS augmentation de Next.js Link da overload errors aquí.
const Box = BoxComp as unknown as React.ComponentType<any>;
import Container from "@mui/material/Container";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import type { LandingTokens } from "../tokens";
import type { FooterColumn, SocialLink } from "../types";

export interface LandingFooterProps {
  tokens: LandingTokens;
  verticalName: string;
  logoIcon: React.ReactNode;
  brandTagline: string;
  columns: FooterColumn[];
  social?: SocialLink[];
  /** Link component (Next.js Link). */
  LinkComponent?: React.ElementType;
  /** Ruta legal (terms/privacy) mostrada en el bottom bar. */
  legalLinks?: Array<{ label: string; href: string }>;
  /** Link al estado del servicio (ej. status.zentto.net). */
  statusLink?: { label: string; href: string };
}

export function LandingFooter({
  tokens,
  verticalName,
  logoIcon,
  brandTagline,
  columns,
  social = [],
  LinkComponent,
  legalLinks = [
    { label: "Términos", href: "/terminos" },
    { label: "Privacidad", href: "/privacidad" },
  ],
  statusLink = { label: "Estado del servicio", href: "https://status.zentto.net" },
}: LandingFooterProps) {
  const LinkEl = (LinkComponent ?? "a") as React.ElementType;
  const year = new Date().getFullYear();

  return (
    <Box
      component="footer"
      sx={{
        bgcolor: tokens.color.bg,
        borderTop: `1px solid ${tokens.color.border}`,
        pt: { xs: 8, md: 12 },
        pb: 4,
      }}
    >
      <Container
        maxWidth={false}
        sx={{
          maxWidth: tokens.container.maxWidth,
          px: {
            xs: `${tokens.container.gutterMobile}px`,
            md: `${tokens.container.gutterDesktop}px`,
          },
        }}
      >
        <Box
          sx={{
            display: "grid",
            gridTemplateColumns: {
              xs: "1fr",
              sm: "1fr 1fr",
              md: `1.4fr repeat(${columns.length}, 1fr)`,
            },
            gap: { xs: 4, md: 5 },
            mb: { xs: 5, md: 7 },
          }}
        >
          {/* Brand block */}
          <Box sx={{ gridColumn: { xs: "1 / -1", sm: "1 / -1", md: "auto" } }}>
            <Stack direction="row" alignItems="center" spacing={1.2} sx={{ mb: 2 }}>
              <Box
                sx={{
                  width: 36,
                  height: 36,
                  borderRadius: `${tokens.radius.md}px`,
                  background: `linear-gradient(135deg, ${tokens.color.brand}, ${tokens.color.accent})`,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#fff",
                }}
              >
                {logoIcon}
              </Box>
              <Typography
                sx={{
                  fontWeight: 800,
                  fontSize: "1.0625rem",
                  color: tokens.color.textPrimary,
                  letterSpacing: "-0.01em",
                }}
              >
                Zentto{" "}
                <Box component="span" sx={{ color: tokens.color.accent }}>
                  {verticalName}
                </Box>
              </Typography>
            </Stack>
            <Typography
              sx={{
                color: tokens.color.textMuted,
                fontSize: tokens.type.body,
                lineHeight: tokens.leading.body,
                mb: 3,
                maxWidth: 320,
              }}
            >
              {brandTagline}
            </Typography>

            {social.length > 0 ? (
              <Stack direction="row" spacing={1}>
                {social.map((s) => (
                  <Box
                    key={s.label}
                    component="a"
                    href={s.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    aria-label={s.label}
                    sx={{
                      width: 32,
                      height: 32,
                      borderRadius: `${tokens.radius.sm}px`,
                      bgcolor: "rgba(255,255,255,0.04)",
                      border: `1px solid ${tokens.color.border}`,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: tokens.color.textSecondary,
                      transition: `all ${tokens.motion.ui}`,
                      textDecoration: "none",
                      "&:hover": {
                        bgcolor: tokens.color.brandSoft,
                        color: tokens.color.brandLight,
                        borderColor: "rgba(165,180,252,0.32)",
                        transform: "translateY(-1px)",
                      },
                      "&:focus-visible": {
                        outline: `2px solid ${tokens.color.brandLight}`,
                        outlineOffset: 2,
                      },
                    }}
                  >
                    {s.icon}
                  </Box>
                ))}
              </Stack>
            ) : null}
          </Box>

          {columns.map((col) => (
            <Box key={col.title}>
              <Typography
                sx={{
                  fontWeight: 700,
                  color: tokens.color.textPrimary,
                  fontSize: tokens.type.eyebrow,
                  letterSpacing: tokens.tracking.eyebrow,
                  textTransform: "uppercase",
                  mb: 2.5,
                }}
              >
                {col.title}
              </Typography>
              <Stack spacing={1.4}>
                {col.links.map((link) => {
                  const props: Record<string, unknown> = link.external
                    ? {
                        component: "a",
                        href: link.href,
                        target: "_blank",
                        rel: "noopener noreferrer",
                      }
                    : { component: LinkEl, href: link.href };
                  return (
                    <Box
                      key={link.label}
                      {...(props as any)}
                      sx={{
                        color: tokens.color.textMuted,
                        fontSize: tokens.type.body,
                        textDecoration: "none",
                        cursor: "pointer",
                        transition: `color ${tokens.motion.micro}`,
                        display: "inline-block",
                        "&:hover": { color: tokens.color.textPrimary },
                        "&:focus-visible": {
                          outline: `2px solid ${tokens.color.brandLight}`,
                          outlineOffset: 2,
                        },
                      }}
                    >
                      {link.label}
                    </Box>
                  );
                })}
              </Stack>
            </Box>
          ))}
        </Box>

        {/* Bottom bar */}
        <Box
          sx={{
            pt: 3,
            borderTop: `1px solid ${tokens.color.border}`,
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: 2,
          }}
        >
          <Typography
            sx={{
              color: tokens.color.textFaint,
              fontSize: tokens.type.bodySm,
            }}
          >
            © {year} Zentto {verticalName}. Parte del ecosistema Zentto.
          </Typography>
          <Stack direction="row" spacing={3} flexWrap="wrap">
            {legalLinks.map((link) => (
              <Box
                key={link.href}
                component={LinkEl as unknown as React.ElementType<any>}
                href={link.href}
                sx={{
                  color: tokens.color.textFaint,
                  fontSize: tokens.type.bodySm,
                  textDecoration: "none",
                  "&:hover": { color: tokens.color.textSecondary },
                }}
              >
                {link.label}
              </Box>
            ))}
            {statusLink ? (
              <Box
                component="a"
                href={statusLink.href}
                target="_blank"
                rel="noopener noreferrer"
                sx={{
                  color: tokens.color.textFaint,
                  fontSize: tokens.type.bodySm,
                  textDecoration: "none",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: 0.75,
                  "&:hover": { color: tokens.color.textSecondary },
                }}
              >
                <Box
                  aria-hidden
                  sx={{
                    width: 6,
                    height: 6,
                    borderRadius: "50%",
                    bgcolor: tokens.color.success,
                  }}
                />
                {statusLink.label}
              </Box>
            ) : null}
          </Stack>
        </Box>
      </Container>
    </Box>
  );
}
