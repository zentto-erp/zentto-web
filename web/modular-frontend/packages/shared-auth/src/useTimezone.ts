'use client';

import { useAuth } from './AuthContext';
import { useCountries } from '@datqbox/shared-api';

export function useTimezone() {
  const { company } = useAuth();
  const { data: countries = [] } = useCountries();

  const countryTimezones: Record<string, string> = countries.reduce(
    (acc, c) => ({ ...acc, [c.CountryCode]: c.TimeZoneIana ?? 'UTC' }),
    {} as Record<string, string>,
  );

  const timeZone =
    company?.timeZone ||
    (company?.countryCode ? countryTimezones[company.countryCode] : null) ||
    'UTC';
  const countryCode = company?.countryCode || 'UTC';
  return { timeZone, countryCode };
}
