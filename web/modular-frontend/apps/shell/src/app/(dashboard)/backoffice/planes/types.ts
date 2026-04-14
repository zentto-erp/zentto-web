export interface PlanAdmin {
  PricingPlanId: number;
  Name: string;
  Slug: string;
  VerticalType: string;
  ProductCode: string;
  Description: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  BillingCycleDefault: 'monthly' | 'annual' | 'both';
  MaxUsers: number;
  MaxTransactions: number;
  Features: string[];
  ModuleCodes: string[];
  Limits: Record<string, number | boolean>;
  IsAddon: boolean;
  IsTrialOnly: boolean;
  TrialDays: number;
  SortOrder: number;
  PaddleProductId?: string;
  PaddlePriceIdMonthly: string;
  PaddlePriceIdAnnual: string;
  PaddleSyncStatus: 'draft' | 'syncing' | 'synced' | 'error' | 'skip';
  IsActive: boolean;
}

export interface PendingSyncRow {
  PricingPlanId: number;
  Slug: string;
  Name: string;
  ProductCode: string;
  MonthlyPrice: number;
  AnnualPrice: number;
  PaddleProductId: string;
  PaddlePriceIdMonthly: string;
  PaddlePriceIdAnnual: string;
  PaddleSyncStatus: string;
}

export const VERTICAL_OPTIONS = [
  { value: 'none',      label: 'Ninguna (trial universal)' },
  { value: 'erp',       label: 'ERP' },
  { value: 'medical',   label: 'Medical' },
  { value: 'hotel',     label: 'Hotel' },
  { value: 'tickets',   label: 'Tickets' },
  { value: 'education', label: 'Education' },
  { value: 'rental',    label: 'Rental' },
] as const;

export const PRODUCT_OPTIONS = [
  'erp-core', 'medical', 'hotel', 'tickets', 'education', 'rental',
] as const;

export const SYNC_STATUS_COLORS: Record<string, 'default' | 'info' | 'success' | 'warning' | 'error'> = {
  draft:   'warning',
  syncing: 'info',
  synced:  'success',
  error:   'error',
  skip:    'default',
};

export const SYNC_STATUS_LABEL: Record<string, string> = {
  draft:   'Pendiente',
  syncing: 'Sincronizando',
  synced:  'Sincronizado',
  error:   'Error',
  skip:    'No aplica',
};
