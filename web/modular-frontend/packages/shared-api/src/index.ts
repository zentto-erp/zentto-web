'use client';

export {
  apiGet, apiPost, apiPut, apiPatch, apiDelete,
  apiPublicGet, apiPublicPost,
  iamGet, iamPost, iamPut, iamDelete,
  resolveAssetUrl, setActiveCompanyForApi,
} from './api';
export {
  isWebAuthnSupported,
  listSupervisorBiometricCredentials,
  enrollSupervisorBiometricCredential,
  authenticateSupervisorBiometricCredential,
} from './supervisorBiometric';
export type { SupervisorBiometricCredential } from './supervisorBiometric';
export { formatCurrency, formatDate, formatDateTime, toDateOnly, formatName, formatPercent, truncateText, getStatusColor } from './formatters';
export { requestLogger } from './requestLogger';
export { default as QueryProvider } from './QueryProvider';
export { useStore } from './store';
export { usePosStore } from './usePosStore';
export { useGridLayoutSync } from './useGridLayoutSync';
export type {
  PrinterConfig, KitchenPrinterConfig, PrinterStatus,
  CajaConfig, ClientePos, CartItem, VentaEnEspera,
  LocalizacionConfig,
} from './usePosStore';
export { calcTotals } from './usePosStore';
export { loadFrontendAddons, listAddons, getAddon, createAddon, updateAddon, deleteAddon } from './addons';
export { listSavedReports, listPublicReports, getSavedReport, getPublicReport, createSavedReport, updateSavedReport, deleteSavedReport } from './reports';
export type { SavedReport, SaveReportInput } from './reports';

// Localizacion utilities (centralized)
export {
  PREDEFINED_COUNTRIES,
  fetchBcvRates,
  settingsToLocalizacion,
  localizacionToSettings,
  useCountries,
  useSaveCountry,
  getCountryDefaults,
  useStates,
  useLookup,
} from './localizacion';
export type { CountryPreset, BcvRates, CountryRecord, StateRecord, LookupRecord } from './localizacion';

// Catálogo unificado + registro + suscripciones
export {
  useCatalogPlans, useCatalogPlan, useCatalogProducts, useCheckSubdomain,
  useStartTrial, useStartCheckout, useCaptureLead,
  useMySubscription, useMyEntitlements, useAddSubscriptionItem,
} from './useCatalog';
export type {
  PricingPlan, CatalogProduct, SubscriptionItem, SubscriptionSummary,
  Entitlements, RegistroBody,
} from './useCatalog';

// Settings hydration
export { useHydrateLocalizacion } from './useHydrateLocalizacion';
export { useHydrateModuleSettings } from './useHydrateModuleSettings';
export type { FrontendAddon, StudioAddon, SaveAddonInput } from './addons';
export type { RequestLog } from './requestLogger';
export type { GridLayoutSnapshot } from './types/grid-layout';

// Usuarios hooks
export {
  useUsuariosList, useUsuario, useCreateUsuario, useUpdateUsuario,
  useDeleteUsuario, useSystemModules, useUsuarioModulos, useSetUsuarioModulos,
  useResetPassword, useChangePassword,
} from './useUsuarios';
export type {
  Usuario, ModuloAcceso, CreateUsuarioInput, UpdateUsuarioInput, SystemModuleInfo,
} from './useUsuarios';

// Payment Gateway hooks
export {
  usePaymentMethods, usePaymentProviders, usePaymentProvider, usePaymentPlugins,
  useCompanyPaymentConfigs, useSaveCompanyPaymentConfig, useDeleteCompanyPaymentConfig,
  useAcceptedPaymentMethods, useSaveAcceptedPaymentMethod, useRemoveAcceptedPaymentMethod,
  usePaymentTransactions, useProcessPayment,
} from './usePayments';
export type {
  PaymentMethod, PaymentProvider, ProviderCapability, ConfigField,
  CompanyPaymentConfig, AcceptedPaymentMethod, PaymentTransaction,
} from './usePayments';

// Brand Config hooks (dedicated white-label API)
export { useBrandConfig, useSaveBrandConfig } from './useBrandConfig';
export type { BrandConfig, BrandConfigInput } from './useBrandConfig';

// Unified Settings hooks
export {
  useAllSettings, useModuleSettings, useModuleSettingsMeta,
  useSaveModuleSettings, useSettingModules, useSettingsSync,
} from './useSettings';
export type { SettingsModule, AllSettings, SettingMeta } from './useSettings';

// Roles & Permissions hooks
export {
  useRolesList, useCreateRole, useDeleteRole,
  useRolePermissions, useSaveRolePermissions,
  useUserRoles, useAssignUserRole,
  useLicenseLimits,
} from './useRoles';
export type {
  Role, CreateRoleInput, RolePermission, BulkPermissionInput,
  UserRole, LicenseLimits,
} from './useRoles';

// Notification Center hooks
export {
  useNotificationsList, useMarkNotificationsRead,
  useTasksList, useToggleTask,
  useMessagesList, useMarkMessageRead,
} from './useNotifications';
export type {
  NotificationItem, NotificationFilters,
  TaskItem, TaskFilters,
  MessageItem, MessageFilters,
} from './useNotifications';
