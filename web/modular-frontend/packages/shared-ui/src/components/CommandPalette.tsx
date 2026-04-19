'use client';

import * as React from 'react';
import Dialog from '@mui/material/Dialog';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';
import SearchIcon from '@mui/icons-material/SearchOutlined';
import { Command } from 'cmdk';
import { alpha, useTheme, type Theme } from '@mui/material/styles';

/**
 * CommandPalette — Cmd/Ctrl-K global inspirado en Linear / HubSpot.
 *
 * Basado en `cmdk` (Shadcn) envuelto en tema MUI para respetar el design
 * system de Zentto (tipografía Inter, radios 12, dark mode, tokens de color).
 *
 * Estados:
 *  - idle    → muestra `staticSections` + recents + saved views.
 *  - typing  → debounce 150ms y `onSearch` devuelve `SearchResult[]`.
 *  - empty   → feedback accionable cuando la query no retorna.
 *
 * ARIA / accesibilidad:
 *  - `cmdk` implementa `role="combobox"` + `aria-autocomplete="list"` y
 *    navegación por teclado `↑/↓/Enter`. El diálogo MUI aporta `role="dialog"`
 *    + `aria-modal="true"` y focus trap. `Esc` cierra.
 */

export interface CommandItem {
  /** ID único (key de React y `cmdk value`). */
  id: string;
  /** Texto principal. */
  label: string;
  /** Subtítulo opcional ("Go to", "Create", timestamp…). */
  hint?: string;
  /** Icono (React node) — 20x20 alineado a la izquierda. */
  icon?: React.ReactNode;
  /** Indicador visual de atajo (`G L`, `Cmd+Enter`). */
  shortcut?: string;
  /** Callback al activar — el palette se cierra automáticamente. */
  onSelect: () => void;
  /** Keywords adicionales para matching fuzzy (no se muestran). */
  keywords?: string[];
  /** Desactiva temporalmente el item. */
  disabled?: boolean;
}

export interface CommandSection {
  /** Título visible de la sección (`NAVEGACIÓN`, `ACCIONES`…). */
  heading: string;
  items: CommandItem[];
}

export interface SearchResult extends CommandItem {
  /** Tipo de entidad para agrupar (`lead`, `contact`, `deal`…). */
  entity?: string;
}

export interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
  /** Búsqueda async cross-entity — se dispara con debounce 150ms. */
  onSearch?: (query: string) => Promise<SearchResult[]>;
  /** Secciones estáticas (navegación, acciones globales). */
  staticSections?: CommandSection[];
  /** Últimos registros abiertos por el usuario. */
  recentRecords?: CommandItem[];
  /** Vistas guardadas del módulo actual. */
  savedViews?: CommandItem[];
  /** Placeholder del input. */
  placeholder?: string;
  /** Texto cuando no hay resultados. */
  emptyText?: string;
  /** Footer custom (si no se pasa, muestra atajos por defecto). */
  footerHint?: React.ReactNode;
}

const DEBOUNCE_MS = 150;

function groupByEntity(results: SearchResult[]): Record<string, SearchResult[]> {
  const groups: Record<string, SearchResult[]> = {};
  for (const r of results) {
    const key = r.entity ?? 'Resultados';
    if (!groups[key]) groups[key] = [];
    groups[key].push(r);
  }
  return groups;
}

export function CommandPalette({
  open,
  onClose,
  onSearch,
  staticSections,
  recentRecords,
  savedViews,
  placeholder = 'Buscar o navegar...',
  emptyText = 'Sin resultados para esa búsqueda.',
  footerHint,
}: CommandPaletteProps) {
  const theme = useTheme();
  const [query, setQuery] = React.useState('');
  const [results, setResults] = React.useState<SearchResult[]>([]);
  const [searching, setSearching] = React.useState(false);
  const [searched, setSearched] = React.useState(false);

  // Reset al cerrar.
  React.useEffect(() => {
    if (!open) {
      setQuery('');
      setResults([]);
      setSearching(false);
      setSearched(false);
    }
  }, [open]);

  // Debounce onSearch.
  React.useEffect(() => {
    if (!onSearch) return;
    const q = query.trim();
    if (!q) {
      setResults([]);
      setSearching(false);
      setSearched(false);
      return;
    }
    setSearching(true);
    const handle = window.setTimeout(async () => {
      try {
        const res = await onSearch(q);
        setResults(Array.isArray(res) ? res : []);
      } catch {
        setResults([]);
      } finally {
        setSearching(false);
        setSearched(true);
      }
    }, DEBOUNCE_MS);
    return () => {
      window.clearTimeout(handle);
    };
  }, [query, onSearch]);

  const handleSelect = React.useCallback(
    (item: CommandItem) => {
      if (item.disabled) return;
      item.onSelect();
      onClose();
    },
    [onClose],
  );

  const isTyping = query.trim().length > 0;
  const grouped = React.useMemo(() => groupByEntity(results), [results]);

  const defaultFooter = (
    <>
      <KbdHint label="↵" /> seleccionar &nbsp;&nbsp;
      <KbdHint label="↑ ↓" /> navegar &nbsp;&nbsp;
      <KbdHint label="Esc" /> cerrar
    </>
  );

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      aria-labelledby="command-palette-title"
      PaperProps={{
        sx: {
          borderRadius: 3,
          overflow: 'hidden',
          bgcolor: 'background.paper',
          boxShadow:
            theme.palette.mode === 'dark'
              ? '0 24px 48px rgba(0,0,0,0.6)'
              : '0 24px 48px rgba(15,23,42,0.18)',
          mt: { xs: 2, sm: 6 },
          alignSelf: 'flex-start',
        },
      }}
      BackdropProps={{
        sx: {
          backgroundColor: alpha(
            theme.palette.common.black,
            theme.palette.mode === 'dark' ? 0.65 : 0.45,
          ),
          backdropFilter: 'blur(2px)',
        },
      }}
    >
      <Box component="span" id="command-palette-title" sx={visuallyHidden}>
        Command palette
      </Box>

      <Command
        label="Command palette"
        shouldFilter={!onSearch || !isTyping}
        loop
        style={paletteRootStyles(theme)}
      >
        {/* Input */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1.5,
            px: 2,
            py: 1.5,
            borderBottom: `1px solid ${theme.palette.divider}`,
          }}
        >
          <SearchIcon fontSize="small" sx={{ color: 'text.secondary' }} />
          <Command.Input
            value={query}
            onValueChange={setQuery}
            placeholder={placeholder}
            autoFocus
            style={inputStyles(theme)}
          />
          {searching && (
            <CircularProgress size={16} thickness={5} sx={{ color: 'text.secondary' }} />
          )}
        </Box>

        {/* Lista */}
        <Command.List style={listStyles}>
          <Command.Empty>
            <Box sx={emptyBoxStyles}>
              <Typography variant="body2" color="text.secondary">
                {isTyping ? emptyText : 'Comienza a escribir para buscar.'}
              </Typography>
            </Box>
          </Command.Empty>

          {isTyping &&
            onSearch &&
            searched &&
            results.length > 0 &&
            Object.entries(grouped).map(([entity, items]) => (
              <Command.Group
                key={`results-${entity}`}
                heading={entity}
                style={groupStyles(theme)}
              >
                {items.map((item) => (
                  <PaletteRow key={item.id} item={item} onSelect={handleSelect} />
                ))}
              </Command.Group>
            ))}

          {!isTyping &&
            staticSections?.map((section) => (
              <Command.Group
                key={`static-${section.heading}`}
                heading={section.heading}
                style={groupStyles(theme)}
              >
                {section.items.map((item) => (
                  <PaletteRow key={item.id} item={item} onSelect={handleSelect} />
                ))}
              </Command.Group>
            ))}

          {!isTyping && recentRecords && recentRecords.length > 0 && (
            <Command.Group heading="Recientes" style={groupStyles(theme)}>
              {recentRecords.map((item) => (
                <PaletteRow key={`recent-${item.id}`} item={item} onSelect={handleSelect} />
              ))}
            </Command.Group>
          )}

          {!isTyping && savedViews && savedViews.length > 0 && (
            <Command.Group heading="Vistas guardadas" style={groupStyles(theme)}>
              {savedViews.map((item) => (
                <PaletteRow key={`view-${item.id}`} item={item} onSelect={handleSelect} />
              ))}
            </Command.Group>
          )}
        </Command.List>

        {/* Footer */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: 1,
            px: 2,
            py: 1,
            borderTop: `1px solid ${theme.palette.divider}`,
            bgcolor: alpha(
              theme.palette.text.primary,
              theme.palette.mode === 'dark' ? 0.04 : 0.02,
            ),
            fontSize: 12,
            color: 'text.secondary',
          }}
        >
          {footerHint ?? defaultFooter}
        </Box>
      </Command>
    </Dialog>
  );
}

/** Fila de cmdk con layout consistente (icono + label/hint + shortcut). */
function PaletteRow({
  item,
  onSelect,
}: {
  item: CommandItem;
  onSelect: (item: CommandItem) => void;
}) {
  const theme = useTheme();
  const keywords = React.useMemo(() => {
    const set = new Set<string>([item.label.toLowerCase()]);
    if (item.hint) set.add(item.hint.toLowerCase());
    (item.keywords ?? []).forEach((k) => set.add(k.toLowerCase()));
    return Array.from(set);
  }, [item]);

  return (
    <Command.Item
      value={`${item.id} ${item.label} ${(item.keywords ?? []).join(' ')}`}
      keywords={keywords}
      onSelect={() => onSelect(item)}
      disabled={item.disabled}
      style={itemStyles(theme)}
    >
      {item.icon && (
        <Box
          component="span"
          sx={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: 24,
            height: 24,
            color: 'text.secondary',
            flexShrink: 0,
          }}
        >
          {item.icon}
        </Box>
      )}
      <Box sx={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
        <Typography
          variant="body2"
          sx={{ fontWeight: 500, color: 'text.primary', lineHeight: 1.3 }}
        >
          {item.label}
        </Typography>
        {item.hint && (
          <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1.3 }}>
            {item.hint}
          </Typography>
        )}
      </Box>
      {item.shortcut && <KbdHint label={item.shortcut} />}
    </Command.Item>
  );
}

/** Chip visual de atajo reusable en footer, filas y cheat-sheet. */
export function KbdHint({ label }: { label: string }) {
  const theme = useTheme();
  const tokens = label.split(/\s+/);
  return (
    <Box component="span" sx={{ display: 'inline-flex', gap: 0.5, flexShrink: 0 }}>
      {tokens.map((t, i) => (
        <Box
          key={`${t}-${i}`}
          component="kbd"
          sx={{
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            minWidth: 18,
            height: 20,
            px: 0.75,
            borderRadius: 1,
            border: `1px solid ${theme.palette.divider}`,
            bgcolor: alpha(
              theme.palette.text.primary,
              theme.palette.mode === 'dark' ? 0.08 : 0.04,
            ),
            color: 'text.secondary',
            fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace',
            fontSize: 11,
            fontWeight: 600,
            lineHeight: 1,
          }}
        >
          {t}
        </Box>
      ))}
    </Box>
  );
}

/* ── estilos ────────────────────────────────────────────────────────────── */

const visuallyHidden: React.CSSProperties = {
  position: 'absolute',
  width: 1,
  height: 1,
  padding: 0,
  margin: -1,
  overflow: 'hidden',
  clip: 'rect(0,0,0,0)',
  whiteSpace: 'nowrap',
  border: 0,
};

function paletteRootStyles(theme: Theme): React.CSSProperties {
  return {
    display: 'flex',
    flexDirection: 'column',
    fontFamily: theme.typography.fontFamily,
    color: theme.palette.text.primary,
  };
}

function inputStyles(theme: Theme): React.CSSProperties {
  return {
    flex: 1,
    border: 'none',
    outline: 'none',
    background: 'transparent',
    color: theme.palette.text.primary,
    fontSize: 15,
    fontFamily: 'inherit',
    padding: 0,
  };
}

const listStyles: React.CSSProperties = {
  maxHeight: 400,
  overflowY: 'auto',
  padding: 4,
  scrollBehavior: 'smooth',
};

const emptyBoxStyles = {
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  px: 2,
  py: 6,
  textAlign: 'center' as const,
};

function groupStyles(theme: Theme): React.CSSProperties {
  return {
    padding: '6px 4px',
    color: theme.palette.text.primary,
  };
}

function itemStyles(theme: Theme): React.CSSProperties {
  return {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    padding: '8px 10px',
    borderRadius: 8,
    cursor: 'pointer',
    userSelect: 'none',
    color: theme.palette.text.primary,
  };
}

export default CommandPalette;
