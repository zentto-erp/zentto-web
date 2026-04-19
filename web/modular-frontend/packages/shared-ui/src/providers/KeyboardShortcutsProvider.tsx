'use client';

import * as React from 'react';

/**
 * KeyboardShortcutsProvider
 *
 * Contexto global para registrar atajos de teclado en el ecosistema Zentto.
 * Soporta combos simples (`Cmd/Ctrl-K`, `?`, `/`) y secuencias tipo Linear
 * (`G` seguido de `L`). Evita disparar atajos cuando el foco está en un
 * input editable a menos que el consumidor indique lo contrario.
 */

export interface KeyboardShortcutOptions {
  /** Ignorar el atajo cuando el foco está en un input editable. Default: true. */
  ignoreInEditable?: boolean;
  /** Prevenir el comportamiento default del navegador. Default: true. */
  preventDefault?: boolean;
  /** Desactivar temporalmente el atajo (flag reactivo). Default: false. */
  disabled?: boolean;
  /** Descripción legible (aparece en el cheat-sheet si se registra ahí). */
  description?: string;
  /** Grupo del cheat-sheet (ej. 'Navegación', 'Acciones'). */
  group?: string;
}

export interface ShortcutEntry {
  combo: string;
  description: string;
  group: string;
}

interface KeyboardShortcutsContextValue {
  openCommandPalette: () => void;
  closeCommandPalette: () => void;
  toggleCommandPalette: () => void;
  openCheatSheet: () => void;
  closeCheatSheet: () => void;
  isPaletteOpen: boolean;
  isCheatSheetOpen: boolean;
  registerShortcut: (entry: ShortcutEntry) => () => void;
  shortcuts: ShortcutEntry[];
}

const KeyboardShortcutsContext = React.createContext<KeyboardShortcutsContextValue | null>(null);

/** Normaliza un evento a combo canónico (`mod+k`, `shift+/`, `g`). */
function eventToCombo(event: KeyboardEvent): string {
  const parts: string[] = [];
  const isMac =
    typeof navigator !== 'undefined' && /Mac|iPhone|iPod|iPad/i.test(navigator.platform);
  if (event.ctrlKey && !isMac) parts.push('mod');
  if (event.metaKey && isMac) parts.push('mod');
  if (event.shiftKey) parts.push('shift');
  if (event.altKey) parts.push('alt');
  const key = event.key.toLowerCase();
  if (!['control', 'meta', 'shift', 'alt'].includes(key)) parts.push(key);
  return parts.join('+');
}

function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;
  const tag = target.tagName.toLowerCase();
  if (tag === 'input' || tag === 'textarea' || tag === 'select') return true;
  if (target.isContentEditable) return true;
  return false;
}

/**
 * Hook para registrar un atajo. Soporta combo simple o secuencia separada
 * por espacios (`g l` para navegar a leads, estilo Linear).
 */
export function useKeyboardShortcut(
  combo: string,
  handler: (event: KeyboardEvent) => void,
  options: KeyboardShortcutOptions = {},
) {
  const {
    ignoreInEditable = true,
    preventDefault = true,
    disabled = false,
    description,
    group,
  } = options;
  const handlerRef = React.useRef(handler);
  handlerRef.current = handler;

  const ctx = React.useContext(KeyboardShortcutsContext);

  React.useEffect(() => {
    if (!ctx || !description) return;
    const unregister = ctx.registerShortcut({
      combo,
      description,
      group: group ?? 'General',
    });
    return unregister;
  }, [ctx, combo, description, group]);

  React.useEffect(() => {
    if (disabled) return;
    const normalized = combo.trim().toLowerCase();
    const sequence = normalized.includes(' ') ? normalized.split(/\s+/) : null;
    let seqIdx = 0;
    let seqTimer: number | null = null;

    const resetSequence = () => {
      seqIdx = 0;
      if (seqTimer) {
        window.clearTimeout(seqTimer);
        seqTimer = null;
      }
    };

    const onKey = (event: KeyboardEvent) => {
      if (ignoreInEditable && isEditableTarget(event.target)) return;
      const current = eventToCombo(event);

      if (sequence) {
        const expected = sequence[seqIdx];
        if (current === expected) {
          seqIdx++;
          if (seqIdx >= sequence.length) {
            if (preventDefault) event.preventDefault();
            handlerRef.current(event);
            resetSequence();
            return;
          }
          if (seqTimer) window.clearTimeout(seqTimer);
          seqTimer = window.setTimeout(resetSequence, 1200);
        } else {
          resetSequence();
        }
        return;
      }

      if (current === normalized) {
        if (preventDefault) event.preventDefault();
        handlerRef.current(event);
      }
    };

    window.addEventListener('keydown', onKey);
    return () => {
      window.removeEventListener('keydown', onKey);
      if (seqTimer) window.clearTimeout(seqTimer);
    };
  }, [combo, disabled, ignoreInEditable, preventDefault]);
}

/** Accede al contexto global (estado del palette, cheat-sheet, registry). */
export function useKeyboardShortcuts(): KeyboardShortcutsContextValue {
  const ctx = React.useContext(KeyboardShortcutsContext);
  if (!ctx) {
    throw new Error(
      'useKeyboardShortcuts debe usarse dentro de <KeyboardShortcutsProvider>. ' +
        'Asegúrate de envolver tu app con <AppBarWrapper>.',
    );
  }
  return ctx;
}

export interface KeyboardShortcutsProviderProps {
  children: React.ReactNode;
  disableGlobalPaletteShortcut?: boolean;
  disableCheatSheetShortcut?: boolean;
}

/**
 * Provider que expone estado del palette + cheat-sheet y registra atajos
 * globales base (`Cmd/Ctrl-K` y `?`). Las apps registran más con
 * `useKeyboardShortcut`.
 */
export function KeyboardShortcutsProvider({
  children,
  disableGlobalPaletteShortcut = false,
  disableCheatSheetShortcut = false,
}: KeyboardShortcutsProviderProps) {
  const [isPaletteOpen, setPaletteOpen] = React.useState(false);
  const [isCheatSheetOpen, setCheatSheetOpen] = React.useState(false);
  const [shortcuts, setShortcuts] = React.useState<ShortcutEntry[]>([]);

  const openCommandPalette = React.useCallback(() => setPaletteOpen(true), []);
  const closeCommandPalette = React.useCallback(() => setPaletteOpen(false), []);
  const toggleCommandPalette = React.useCallback(() => setPaletteOpen((v) => !v), []);
  const openCheatSheet = React.useCallback(() => setCheatSheetOpen(true), []);
  const closeCheatSheet = React.useCallback(() => setCheatSheetOpen(false), []);

  const registerShortcut = React.useCallback((entry: ShortcutEntry) => {
    setShortcuts((prev) => {
      if (prev.some((s) => s.combo === entry.combo && s.description === entry.description))
        return prev;
      return [...prev, entry];
    });
    return () => {
      setShortcuts((prev) =>
        prev.filter((s) => !(s.combo === entry.combo && s.description === entry.description)),
      );
    };
  }, []);

  const value = React.useMemo<KeyboardShortcutsContextValue>(
    () => ({
      isPaletteOpen,
      isCheatSheetOpen,
      openCommandPalette,
      closeCommandPalette,
      toggleCommandPalette,
      openCheatSheet,
      closeCheatSheet,
      registerShortcut,
      shortcuts,
    }),
    [
      isPaletteOpen,
      isCheatSheetOpen,
      openCommandPalette,
      closeCommandPalette,
      toggleCommandPalette,
      openCheatSheet,
      closeCheatSheet,
      registerShortcut,
      shortcuts,
    ],
  );

  return (
    <KeyboardShortcutsContext.Provider value={value}>
      <GlobalShortcuts
        disablePalette={disableGlobalPaletteShortcut}
        disableCheatSheet={disableCheatSheetShortcut}
      />
      {children}
    </KeyboardShortcutsContext.Provider>
  );
}

function GlobalShortcuts({
  disablePalette,
  disableCheatSheet,
}: {
  disablePalette: boolean;
  disableCheatSheet: boolean;
}) {
  const { toggleCommandPalette, openCheatSheet, closeCheatSheet, isCheatSheetOpen } =
    useKeyboardShortcuts();

  useKeyboardShortcut('mod+k', () => toggleCommandPalette(), {
    disabled: disablePalette,
    description: 'Abrir command palette',
    group: 'Global',
  });

  useKeyboardShortcut('?', () => (isCheatSheetOpen ? closeCheatSheet() : openCheatSheet()), {
    disabled: disableCheatSheet,
    description: 'Mostrar / ocultar atajos de teclado',
    group: 'Global',
  });

  return null;
}

export default KeyboardShortcutsProvider;
