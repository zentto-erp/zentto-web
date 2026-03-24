"use client";

// Theme
export { default as theme } from './theme';
export { brandColors } from './theme';

// Providers
export { default as ToastProvider, useToast } from './providers/ToastProvider';
export { default as LocalizationProviderWrapper } from './providers/LocalizationProviderWrapper';

// Components
export { default as Copyright } from './components/Copyright';
export { default as Logo } from './components/Logo';
export { default as AppTitle } from './components/AppTitle';
export { default as AppBarWrapper } from './components/AppBarWrapper';
export { default as SidebarFooterAccount, ToolbarAccountOverride } from './components/SidebarFooterAccount';
export { default as PerfilDrawer } from './components/PerfilDrawer';
export { LoadingFallback } from './components/LoadingFallback';
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

// Payment Gateway Components
export { default as PaymentSettingsPanel } from './components/PaymentSettingsPanel';
export { default as ProviderConfigCard } from './components/ProviderConfigCard';
export { default as AcceptedMethodsManager } from './components/AcceptedMethodsManager';

// MUI X re-exports (single source to avoid duplicated contexts across apps)
export { DatePicker } from '@mui/x-date-pickers/DatePicker';

// ─── ZenttoDataGrid — componente unificado que reemplaza DataGrid en todo el proyecto ───
// Incluye: responsive, master-detail, pivot, aggregation, column pinning, export,
// row grouping, tree data, header filters, clipboard, cell selection, lazy loading,
// column groups, row pinning, row reordering
export { ZenttoDataGrid } from './components/ZenttoDataGrid';
export type {
  ZenttoDataGridProps,
  ZenttoColDef,
  PivotConfig,
  AggregationType,
  RowGroupingConfig,
  TreeDataConfig,
  ColumnGroup,
  HeaderFilter,
  CellRange,
  GridRow,
} from './components/ZenttoDataGrid/types';

// ResponsiveDataGrid → alias de ZenttoDataGrid para compatibilidad
export { ZenttoDataGrid as ResponsiveDataGrid } from './components/ZenttoDataGrid';
export type { ZenttoDataGridProps as ResponsiveDataGridProps } from './components/ZenttoDataGrid/types';

// ─── Dialogs genéricos — CRUD, confirmación, formularios ───
export { ConfirmDialog, DeleteDialog } from './components/dialogs';
export type { ConfirmDialogProps, DeleteDialogProps } from './components/dialogs';
export { FormDialog } from './components/dialogs';
export type { FormDialogProps } from './components/dialogs';
export { CrudActions, buildCrudActionsColumn } from './components/dialogs';
export type { CrudActionHandlers } from './components/dialogs';

// Form layout — Grid wrapper para formularios consistentes
export { FormGrid, FormField } from './components/FormGrid';
export type { FormGridProps, FormFieldProps } from './components/FormGrid';

// Db Mode Toggle
export { DbModeToggle } from './components/DbModeToggle';

// Help
export { default as HelpButton } from './components/HelpButton';
export { HELP_MAP, getHelpForPath } from './lib/help-map';
export type { HelpEntry } from './lib/help-map';
