'use client';
import * as React from 'react';
import Box from '@mui/material/Box';

import {
  KeyboardShortcutsProvider,
  useKeyboardShortcuts,
} from '../providers/KeyboardShortcutsProvider';
import {
  CommandPalette,
  type CommandPaletteProps,
  type CommandSection,
  type CommandItem,
  type SearchResult,
} from './CommandPalette';
import { KeyboardShortcutsCheatSheet } from './KeyboardShortcutsCheatSheet';

/**
 * AppBarWrapper
 *
 * Envoltura raíz del chrome de cualquier app Zentto. Además de montar el
 * layout flex vertical, provee:
 *   1. `KeyboardShortcutsProvider` — atajos globales + registry del cheat-sheet.
 *   2. `<CommandPalette>` global disparado por `Cmd/Ctrl-K` (opt-in via props).
 *   3. `<KeyboardShortcutsCheatSheet>` disparado por `?`.
 *
 * Las apps consumen lo siguiente opcionalmente:
 *   - `paletteStaticSections`  — navegación / acciones estáticas.
 *   - `paletteRecentRecords`   — últimos registros del módulo actual.
 *   - `paletteSavedViews`      — vistas guardadas del usuario.
 *   - `paletteOnSearch`        — búsqueda async cross-entity (CRM-110 backend).
 *
 * Si no se pasan props, el palette sigue abriéndose con Cmd-K y muestra un
 * estado vacío amable — backwards compatible.
 */

export interface AppBarWrapperProps {
  children: React.ReactNode;

  /** Secciones estáticas para el CommandPalette (navegación, acciones). */
  paletteStaticSections?: CommandSection[];
  /** Últimos registros abiertos por el usuario. */
  paletteRecentRecords?: CommandItem[];
  /** Vistas guardadas del módulo actual. */
  paletteSavedViews?: CommandItem[];
  /** Búsqueda async cross-entity (debounced 150ms). */
  paletteOnSearch?: (query: string) => Promise<SearchResult[]>;
  /** Placeholder del input del palette. */
  palettePlaceholder?: string;
  /** Desactiva el montaje del CommandPalette si la app maneja el suyo. */
  disableCommandPalette?: boolean;
  /** Desactiva el cheat-sheet si la app maneja el suyo. */
  disableCheatSheet?: boolean;
  /** Desactiva el atajo `Cmd/Ctrl-K` globalmente. */
  disableGlobalPaletteShortcut?: boolean;
  /** Desactiva el atajo `?` globalmente. */
  disableCheatSheetShortcut?: boolean;
  /** Props adicionales que se pasan al CommandPalette sin cambiar el API. */
  paletteProps?: Partial<Omit<CommandPaletteProps, 'open' | 'onClose'>>;
}

export default function AppBarWrapper({
  children,
  paletteStaticSections,
  paletteRecentRecords,
  paletteSavedViews,
  paletteOnSearch,
  palettePlaceholder,
  disableCommandPalette = false,
  disableCheatSheet = false,
  disableGlobalPaletteShortcut = false,
  disableCheatSheetShortcut = false,
  paletteProps,
}: AppBarWrapperProps) {
  return (
    <KeyboardShortcutsProvider
      disableGlobalPaletteShortcut={disableGlobalPaletteShortcut}
      disableCheatSheetShortcut={disableCheatSheetShortcut}
    >
      <Box sx={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
        {children}
      </Box>

      {!disableCommandPalette && (
        <MountedCommandPalette
          staticSections={paletteStaticSections}
          recentRecords={paletteRecentRecords}
          savedViews={paletteSavedViews}
          onSearch={paletteOnSearch}
          placeholder={palettePlaceholder}
          extra={paletteProps}
        />
      )}
      {!disableCheatSheet && <KeyboardShortcutsCheatSheet />}
    </KeyboardShortcutsProvider>
  );
}

/**
 * Wrapper interno que consume el contexto y monta el palette. Se aísla para
 * poder usar `useKeyboardShortcuts` sin romper el provider (el hook debe
 * vivir debajo del provider).
 */
function MountedCommandPalette({
  staticSections,
  recentRecords,
  savedViews,
  onSearch,
  placeholder,
  extra,
}: {
  staticSections?: CommandSection[];
  recentRecords?: CommandItem[];
  savedViews?: CommandItem[];
  onSearch?: (query: string) => Promise<SearchResult[]>;
  placeholder?: string;
  extra?: Partial<Omit<CommandPaletteProps, 'open' | 'onClose'>>;
}) {
  const { isPaletteOpen, closeCommandPalette } = useKeyboardShortcuts();
  return (
    <CommandPalette
      open={isPaletteOpen}
      onClose={closeCommandPalette}
      staticSections={staticSections}
      recentRecords={recentRecords}
      savedViews={savedViews}
      onSearch={onSearch}
      placeholder={placeholder}
      {...extra}
    />
  );
}
