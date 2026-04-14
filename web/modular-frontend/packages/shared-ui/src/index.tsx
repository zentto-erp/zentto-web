"use client";

// Web component type declarations (zentto-grid, report-viewer, report-designer)
import './web-components';

// Theme
export { default as theme } from './theme';
export { brandColors, createBrandedTheme, DEFAULT_BRANDING } from './theme';
export type { BrandingColors } from './theme';

// Providers
export { default as ToastProvider, useToast } from './providers/ToastProvider';
export { default as LocalizationProviderWrapper } from './providers/LocalizationProviderWrapper';
export { default as BrandingProvider } from './providers/BrandingProvider';
export type { BrandingConfig, BrandingContextValue } from './providers/BrandingProvider';

// Branding
export { default as BrandedThemeProvider } from './components/BrandedThemeProvider';
export { useBranding } from './hooks/useBranding';

// Components
export { default as Copyright } from './components/Copyright';
export { default as Logo } from './components/Logo';
export { default as AppTitle } from './components/AppTitle';
export { default as AppBarWrapper } from './components/AppBarWrapper';
export { default as SidebarFooterAccount, ToolbarAccountOverride } from './components/SidebarFooterAccount';
export { default as PerfilDrawer } from './components/PerfilDrawer';
export { LoadingFallback } from './components/LoadingFallback';
export { default as ThemeToggle, EyeIcon, EyeOffIcon } from './components/ThemeToggle';
export { default as CustomStepper } from './components/CustomStepper';
export type { CustomStepperProps, StepDef } from './components/CustomStepper';
export { default as ContextActionHeader } from './components/ContextActionHeader';
export { default as OdooLayout } from './components/OdooLayout';
export { default as SettingsLayout } from './components/SettingsLayout';
export { default as SettingsSection } from './components/SettingsSection';
export { default as SettingsItem } from './components/SettingsItem';
export { default as SettingsInputGroup } from './components/SettingsInputGroup';
export { LocalizacionModal } from './components/LocalizacionModal';
export type { LocalizacionConfig } from './components/LocalizacionModal';
export { CountrySelect } from './components/CountrySelect';
export type { CountrySelectProps } from './components/CountrySelect';
export { PhoneInput } from './components/PhoneInput';
export type { PhoneInputProps } from './components/PhoneInput';

// Payment Gateway Components
export { default as PaymentSettingsPanel } from './components/PaymentSettingsPanel';
export { default as ProviderConfigCard } from './components/ProviderConfigCard';
export { default as AcceptedMethodsManager } from './components/AcceptedMethodsManager';

// MUI X re-exports (single source to avoid duplicated contexts across apps)
export { DatePicker } from '@mui/x-date-pickers/DatePicker';

// ─── ZenttoDataGrid — MIGRADO a @zentto/datagrid (web component nativo) ───
// El grid MUI legacy fue eliminado. Usar <zentto-grid> directamente.
// Ver: https://www.npmjs.com/package/@zentto/datagrid

// ─── Dialogs genéricos — CRUD, confirmación, formularios ───
export { ConfirmDialog, DeleteDialog } from './components/dialogs';
export type { ConfirmDialogProps, DeleteDialogProps } from './components/dialogs';
export { FormDialog } from './components/dialogs';
export type { FormDialogProps } from './components/dialogs';

// Form layout — Grid wrapper para formularios consistentes
export { FormGrid, FormField } from './components/FormGrid';
export type { FormGridProps, FormFieldProps } from './components/FormGrid';

// ─── ZenttoFilterPanel — panel de filtros reutilizable para tablas ───
export { ZenttoFilterPanel } from './components/ZenttoFilterPanel';
export type {
  ZenttoFilterPanelProps,
  FilterFieldDef,
  FilterFieldType,
  FilterSelectOption,
} from './components/ZenttoFilterPanel';

// Db Mode Toggle
export { DbModeToggle } from './components/DbModeToggle';

// i18n — Locale Selector (MUI)
export { default as LocaleSelectorButton } from './components/LocaleSelectorButton';

// Help
export { default as HelpButton } from './components/HelpButton';
export { HELP_MAP, getHelpForPath } from './lib/help-map';
export type { HelpEntry } from './lib/help-map';
