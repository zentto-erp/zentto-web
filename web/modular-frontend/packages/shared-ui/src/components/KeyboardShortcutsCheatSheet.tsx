'use client';

import * as React from 'react';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import IconButton from '@mui/material/IconButton';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import CloseIcon from '@mui/icons-material/CloseOutlined';
import KeyboardIcon from '@mui/icons-material/KeyboardOutlined';
import { alpha, useTheme } from '@mui/material/styles';

import { useKeyboardShortcuts, type ShortcutEntry } from '../providers/KeyboardShortcutsProvider';
import { KbdHint } from './CommandPalette';

/**
 * Modal cheat-sheet que lista los atajos globales registrados vía
 * `useKeyboardShortcut(..., { description, group })`. Se abre con `?` y se
 * cierra con `?` nuevamente o `Esc`.
 *
 * Patrón visual: dos columnas — descripción + chip `<kbd>`. Agrupado por
 * `group`. Tipografía y colores del theme MUI (respeta dark mode).
 */

export interface KeyboardShortcutsCheatSheetProps {
  /** Atajos adicionales a mostrar además de los registrados en runtime. */
  extraShortcuts?: ShortcutEntry[];
  /** Orden preferido de grupos (los no listados van al final en orden alfa). */
  groupOrder?: string[];
}

const DEFAULT_GROUP_ORDER = ['Global', 'Navegación', 'Acciones', 'Listas', 'Registros'];

export function KeyboardShortcutsCheatSheet({
  extraShortcuts = [],
  groupOrder = DEFAULT_GROUP_ORDER,
}: KeyboardShortcutsCheatSheetProps) {
  const { isCheatSheetOpen, closeCheatSheet, shortcuts } = useKeyboardShortcuts();
  const theme = useTheme();

  const allShortcuts = React.useMemo<ShortcutEntry[]>(() => {
    const seen = new Set<string>();
    const merged: ShortcutEntry[] = [];
    for (const s of [...shortcuts, ...extraShortcuts]) {
      const key = `${s.group}::${s.combo}::${s.description}`;
      if (seen.has(key)) continue;
      seen.add(key);
      merged.push(s);
    }
    return merged;
  }, [shortcuts, extraShortcuts]);

  const grouped = React.useMemo(() => {
    const groups: Record<string, ShortcutEntry[]> = {};
    for (const s of allShortcuts) {
      if (!groups[s.group]) groups[s.group] = [];
      groups[s.group].push(s);
    }
    return groups;
  }, [allShortcuts]);

  const orderedGroups = React.useMemo(() => {
    const keys = Object.keys(grouped);
    const ordered = [
      ...groupOrder.filter((g) => keys.includes(g)),
      ...keys.filter((g) => !groupOrder.includes(g)).sort(),
    ];
    return ordered;
  }, [grouped, groupOrder]);

  return (
    <Dialog
      open={isCheatSheetOpen}
      onClose={closeCheatSheet}
      maxWidth="sm"
      fullWidth
      aria-labelledby="kbd-cheatsheet-title"
      PaperProps={{
        sx: {
          borderRadius: 3,
          overflow: 'hidden',
        },
      }}
    >
      <DialogTitle
        id="kbd-cheatsheet-title"
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          fontSize: 16,
          fontWeight: 700,
          py: 2,
        }}
      >
        <KeyboardIcon fontSize="small" />
        Atajos de teclado
        <Box sx={{ flex: 1 }} />
        <IconButton
          size="small"
          onClick={closeCheatSheet}
          aria-label="Cerrar atajos de teclado"
        >
          <CloseIcon fontSize="small" />
        </IconButton>
      </DialogTitle>
      <DialogContent sx={{ pt: 0, pb: 2 }}>
        {orderedGroups.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
            No hay atajos registrados aún.
          </Typography>
        ) : (
          orderedGroups.map((group) => (
            <Box
              key={group}
              sx={{
                mb: 2,
                '&:last-of-type': { mb: 0 },
              }}
            >
              <Typography
                variant="caption"
                sx={{
                  display: 'block',
                  fontWeight: 700,
                  letterSpacing: '0.08em',
                  textTransform: 'uppercase',
                  color: 'text.secondary',
                  mb: 1,
                }}
              >
                {group}
              </Typography>
              <Box
                component="ul"
                sx={{
                  listStyle: 'none',
                  m: 0,
                  p: 0,
                  border: `1px solid ${theme.palette.divider}`,
                  borderRadius: 2,
                  overflow: 'hidden',
                  bgcolor: alpha(theme.palette.text.primary, theme.palette.mode === 'dark' ? 0.02 : 0.01),
                }}
              >
                {grouped[group].map((s, idx) => (
                  <Box
                    key={`${s.combo}-${s.description}-${idx}`}
                    component="li"
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 2,
                      px: 2,
                      py: 1,
                      borderTop: idx === 0 ? 'none' : `1px solid ${theme.palette.divider}`,
                    }}
                  >
                    <Typography variant="body2" sx={{ flex: 1 }}>
                      {s.description}
                    </Typography>
                    <KbdHint label={formatComboForDisplay(s.combo)} />
                  </Box>
                ))}
              </Box>
            </Box>
          ))
        )}
      </DialogContent>
    </Dialog>
  );
}

/**
 * Convierte un combo canónico (`mod+k`, `g l`, `shift+/`) a su representación
 * visual amigable según plataforma (`Cmd K` en Mac, `Ctrl K` en Win/Linux).
 */
function formatComboForDisplay(combo: string): string {
  const isMac =
    typeof navigator !== 'undefined' && /Mac|iPhone|iPod|iPad/i.test(navigator.platform);
  return combo
    .split(/\s+/)
    .map((token) =>
      token
        .split('+')
        .map((part) => {
          if (part === 'mod') return isMac ? 'Cmd' : 'Ctrl';
          if (part === 'shift') return 'Shift';
          if (part === 'alt') return isMac ? 'Opt' : 'Alt';
          if (part === 'escape') return 'Esc';
          if (part === 'enter') return '↵';
          if (part === 'arrowup') return '↑';
          if (part === 'arrowdown') return '↓';
          if (part === 'arrowleft') return '←';
          if (part === 'arrowright') return '→';
          if (part.length === 1) return part.toUpperCase();
          return part.charAt(0).toUpperCase() + part.slice(1);
        })
        .join(' '),
    )
    .join('  ');
}

export default KeyboardShortcutsCheatSheet;
