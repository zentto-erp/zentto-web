'use client';

export { apiGet, apiPost, apiPut, apiPatch, apiDelete, resolveAssetUrl } from './api';
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
export type {
  PrinterConfig, KitchenPrinterConfig, PrinterStatus,
  CajaConfig, ClientePos, CartItem, VentaEnEspera,
  LocalizacionConfig,
} from './usePosStore';
export { calcTotals } from './usePosStore';
/** @deprecated Use useModuleSettings + useHydrateLocalizacion instead */
export * from './useConfigStore';
export { loadFrontendAddons } from './addons';

// Localizacion utilities (centralized)
export {
  PREDEFINED_COUNTRIES,
  fetchBcvRates,
  settingsToLocalizacion,
  localizacionToSettings,
  useCountries,
  useSaveCountry,
  getCountryDefaults,
} from './localizacion';
export type { CountryPreset, BcvRates, CountryRecord } from './localizacion';

// Settings hydration
export { useHydrateLocalizacion } from './useHydrateLocalizacion';
export { useHydrateModuleSettings } from './useHydrateModuleSettings';
export type { FrontendAddon } from './addons';
export type { RequestLog } from './requestLogger';

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

// Unified Settings hooks
export {
  useAllSettings, useModuleSettings, useModuleSettingsMeta,
  useSaveModuleSettings, useSettingModules,
} from './useSettings';
export type { SettingsModule, AllSettings, SettingMeta } from './useSettings';
