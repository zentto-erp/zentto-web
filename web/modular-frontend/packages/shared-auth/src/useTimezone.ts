'use client';

import { useAuth } from './AuthContext';

const COUNTRY_TIMEZONES: Record<string, string> = {
  VE: 'America/Caracas',
  ES: 'Europe/Madrid',
  CO: 'America/Bogota',
  MX: 'America/Mexico_City',
  US: 'America/New_York',
};

export function useTimezone() {
  const { company } = useAuth();
  const timeZone =
    company?.timeZone ||
    (company?.countryCode ? COUNTRY_TIMEZONES[company.countryCode] : null) ||
    'UTC';
  const countryCode = company?.countryCode || 'UTC';
  return { timeZone, countryCode };
}
