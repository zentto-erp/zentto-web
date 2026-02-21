"use client";

// Theme
export { default as theme } from './theme';

// Providers
export { default as ToastProvider, useToast } from './providers/ToastProvider';
export { default as LocalizationProviderWrapper } from './providers/LocalizationProviderWrapper';

// Components
export { default as Copyright } from './components/Copyright';
export { default as Logo } from './components/Logo';
export { default as AppTitle } from './components/AppTitle';
export { default as AppBarWrapper } from './components/AppBarWrapper';
export { default as SidebarFooterAccount, ToolbarAccountOverride } from './components/SidebarFooterAccount';
export { LoadingFallback } from './components/LoadingFallback';
export { default as CustomStepper } from './components/CustomStepper';
export type { CustomStepperProps, StepDef } from './components/CustomStepper';
export { default as ContextActionHeader } from './components/ContextActionHeader';
export { default as OdooLayout } from './components/OdooLayout';
export { default as SettingsLayout } from './components/SettingsLayout';
export { default as SettingsSection } from './components/SettingsSection';
export { default as SettingsItem } from './components/SettingsItem';
export { default as SettingsInputGroup } from './components/SettingsInputGroup';

// MUI X re-exports (single source to avoid duplicated contexts across apps)
export { DatePicker } from '@mui/x-date-pickers/DatePicker';
