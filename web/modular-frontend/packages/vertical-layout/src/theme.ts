/**
 * Re-exporta `brandColors` desde `@zentto/design-tokens` para consistencia con
 * el resto del ecosistema Zentto. El layout lee `brandColors.{accent,indigo,textMuted}`
 * — mismos tokens que usan shared-ui y todas las verticales.
 */
import { designTokens } from '@zentto/design-tokens';

export const brandColors = { ...designTokens.brand };
