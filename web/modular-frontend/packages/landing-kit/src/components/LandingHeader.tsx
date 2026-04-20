/**
 * LandingHeader — header sticky B2B canónico (logo · nav · auth CTAs · drawer mobile).
 *
 * Client Component (scroll listener + drawer state). Cada vertical pasa su
 * nombre, icono, nav links, y rutas de auth/demo.
 */

"use client";

import * as React from "react";
import BoxComp from "@mui/material/Box";
// Cast de Box a any para permitir `component` polimórfico con `href`.
// MUI sin TS augmentation de Next.js Link da overload errors aquí.
const Box = BoxComp as unknown as React.ComponentType<any>;
import Button from "@mui/material/Button";
import Container from "@mui/material/Container";
import IconButton from "@mui/material/IconButton";
import Drawer from "@mui/material/Drawer";
import Stack from "@mui/material/Stack";
import Typography from "@mui/material/Typography";
import Divider from "@mui/material/Divider";
import MenuIcon from "@mui/icons-material/Menu";
import CloseIcon from "@mui/icons-material/Close";
import type { LandingTokens } from "../tokens";
import type { NavLink } from "../types";
import { CTAButton } from "./CTAButton";

export interface LandingHeaderProps {
  tokens: LandingTokens;
  verticalName: string;
  logoIcon: React.ReactNode;
  navLinks: NavLink[];
  /** Ruta del CTA primario (default: /demo). */
  primaryCtaHref?: string;
  primaryCtaLabel?: string;
  /** Ruta del CTA secundario login (default: /login). */
  loginHref?: string;
  /** Ruta home para el logo. */
  homeHref?: string;
  /** Link component (Next.js Link). Si no se pasa, usa anchor nativo. */
  LinkComponent?: React.ElementType;
  /** Callback para scroll a anchor cuando los nav links empiezan con "#". */
  onAnchorClick?: (hash: string) => void;
  /** Pathname actual para marcar aria-current. */
  currentPath?: string;
}

export function LandingHeader({
  tokens,
  verticalName,
  logoIcon,
  navLinks,
  primaryCtaHref = "/demo",
  primaryCtaLabel = "Solicitar demo",
  loginHref = "/login",
  homeHref = "/",
  LinkComponent,
  onAnchorClick,
  currentPath,
}: LandingHeaderProps) {
  const [scrolled, setScrolled] = React.useState(false);
  const [open, setOpen] = React.useState(false);

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const LinkEl = (LinkComponent ?? "a") as React.ElementType;

  function handleNavClick(href: string) {
    setOpen(false);
    if (href.startsWith("#") && onAnchorClick) {
      onAnchorClick(href);
    }
  }

  return (
    <Box
      component="header"
      sx={{
        position: "sticky",
        top: 0,
        zIndex: 50,
        transition: `background-color ${tokens.motion.ui}, border-color ${tokens.motion.ui}, backdrop-filter ${tokens.motion.ui}`,
        bgcolor: scrolled ? "rgba(11,10,31,0.85)" : "transparent",
        backdropFilter: scrolled ? "saturate(180%) blur(14px)" : "none",
        borderBottom: scrolled
          ? `1px solid ${tokens.color.border}`
          : "1px solid transparent",
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
          height: { xs: 64, md: 76 },
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 3,
        }}
      >
        <LinkEl
          href={homeHref}
          style={{ textDecoration: "none" }}
          aria-label={`${verticalName} — inicio`}
        >
          <Stack direction="row" alignItems="center" spacing={1.2}>
            <Box
              sx={{
                width: 36,
                height: 36,
                borderRadius: `${tokens.radius.md}px`,
                background: `linear-gradient(135deg, ${tokens.color.brand}, ${tokens.color.accent})`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                boxShadow: tokens.shadow.cta,
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
        </LinkEl>

        <Stack
          direction="row"
          spacing={3.5}
          alignItems="center"
          sx={{ display: { xs: "none", md: "flex" } }}
          component="nav"
          aria-label="Navegación principal"
        >
          {navLinks.map((link) => {
            const isActive =
              !link.href.startsWith("#") && currentPath === link.href;
            const LinkTag = (link.href.startsWith("#") ? "a" : LinkEl) as React.ElementType;
            return (
              <Box
                key={link.href}
                component={LinkTag as unknown as React.ElementType<any>}
                href={link.href}
                onClick={
                  link.href.startsWith("#")
                    ? (e: React.MouseEvent) => {
                        e.preventDefault();
                        handleNavClick(link.href);
                      }
                    : undefined
                }
                aria-current={isActive ? "page" : undefined}
                sx={{
                  fontSize: "0.9375rem",
                  fontWeight: 500,
                  color: isActive
                    ? tokens.color.textPrimary
                    : tokens.color.textSecondary,
                  textDecoration: "none",
                  cursor: "pointer",
                  transition: `color ${tokens.motion.micro}`,
                  borderRadius: `${tokens.radius.sm}px`,
                  px: 0.5,
                  py: 0.5,
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

        <Stack
          direction="row"
          spacing={1.25}
          alignItems="center"
          sx={{ display: { xs: "none", md: "flex" } }}
        >
          <Button
            component={LinkEl}
            href={loginHref}
            sx={{
              color: tokens.color.textPrimary,
              fontWeight: 600,
              textTransform: "none",
              fontSize: "0.9375rem",
              px: 1.5,
              borderRadius: `${tokens.radius.md}px`,
              "&:hover": { bgcolor: "rgba(255,255,255,0.06)" },
              "&:focus-visible": {
                outline: `2px solid ${tokens.color.brandLight}`,
                outlineOffset: 2,
              },
            }}
          >
            Iniciar sesión
          </Button>
          <CTAButton
            tokens={tokens}
            href={primaryCtaHref}
            LinkComponent={LinkComponent}
            variant="primary"
            size="md"
          >
            {primaryCtaLabel}
          </CTAButton>
        </Stack>

        <IconButton
          onClick={() => setOpen(true)}
          sx={{
            display: { xs: "inline-flex", md: "none" },
            color: tokens.color.textPrimary,
            "&:focus-visible": {
              outline: `2px solid ${tokens.color.brandLight}`,
              outlineOffset: 2,
            },
          }}
          aria-label="Abrir menú"
        >
          <MenuIcon />
        </IconButton>
      </Container>

      <Drawer
        anchor="right"
        open={open}
        onClose={() => setOpen(false)}
        PaperProps={{
          sx: {
            width: { xs: "84%", sm: 360 },
            bgcolor: tokens.color.bgSurface,
            borderLeft: `1px solid ${tokens.color.border}`,
            p: 3,
          },
        }}
      >
        <Stack
          direction="row"
          justifyContent="space-between"
          alignItems="center"
          sx={{ mb: 3 }}
        >
          <Typography sx={{ fontWeight: 800, color: tokens.color.textPrimary }}>
            Menú
          </Typography>
          <IconButton
            onClick={() => setOpen(false)}
            sx={{ color: tokens.color.textSecondary }}
            aria-label="Cerrar menú"
          >
            <CloseIcon />
          </IconButton>
        </Stack>

        <Stack spacing={0.5} sx={{ mb: 3 }} component="nav">
          {navLinks.map((link) => (
            <Button
              key={link.href}
              onClick={() => handleNavClick(link.href)}
              component={link.href.startsWith("#") ? "button" : LinkEl}
              href={link.href.startsWith("#") ? undefined : link.href}
              sx={{
                justifyContent: "flex-start",
                textTransform: "none",
                color: tokens.color.textPrimary,
                fontSize: "1rem",
                fontWeight: 500,
                py: 1.5,
                px: 1.5,
                borderRadius: `${tokens.radius.md}px`,
                "&:hover": { bgcolor: "rgba(255,255,255,0.05)" },
              }}
            >
              {link.label}
            </Button>
          ))}
        </Stack>

        <Divider sx={{ borderColor: tokens.color.border, mb: 3 }} />

        <Stack spacing={1.5}>
          <Button
            variant="outlined"
            fullWidth
            component={LinkEl}
            href={loginHref}
            onClick={() => setOpen(false)}
            sx={{
              textTransform: "none",
              fontWeight: 600,
              py: 1.2,
              borderRadius: `${tokens.radius.md}px`,
              borderColor: tokens.color.borderStrong,
              color: tokens.color.textPrimary,
              "&:hover": {
                borderColor: tokens.color.brandLight,
                bgcolor: "rgba(255,255,255,0.04)",
              },
            }}
          >
            Iniciar sesión
          </Button>
          <CTAButton
            tokens={tokens}
            href={primaryCtaHref}
            LinkComponent={LinkComponent}
            variant="primary"
            fullWidth
          >
            {primaryCtaLabel}
          </CTAButton>
        </Stack>
      </Drawer>
    </Box>
  );
}
