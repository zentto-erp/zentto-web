/**
 * `@zentto/vertical-layout` — Layout compartido para dashboards de las 8 apps
 * verticales de Zentto (hotel, medical, education, tickets, rental,
 * inmobiliario, restaurante, pos).
 *
 * Standalone: NO depende de `@zentto/shared-auth`/`@zentto/shared-api`.
 * Cada vertical mantiene su propio `useSession` de next-auth.
 *
 * @example
 * ```tsx
 * "use client";
 * import { ZenttoVerticalLayout } from "@zentto/vertical-layout";
 *
 * const nav = [
 *   { kind: 'header', title: 'OPERACIONES' },
 *   { kind: 'page', segment: 'dashboard', title: 'Dashboard', icon: <DashboardIcon /> },
 *   { kind: 'divider' },
 * ];
 *
 * export default function Layout({ children }) {
 *   return (
 *     <ZenttoVerticalLayout navigationFields={nav} appTitle="Zentto Hotel">
 *       {children}
 *     </ZenttoVerticalLayout>
 *   );
 * }
 * ```
 */
export { default as ZenttoVerticalLayout } from './ZenttoVerticalLayout';
export { default as ThemeToggle } from './ThemeToggle';
export { brandColors } from './theme';
