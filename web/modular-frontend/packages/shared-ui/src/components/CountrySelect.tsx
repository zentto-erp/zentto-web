'use client';

import { Autocomplete, TextField, Box } from '@mui/material';
import { useCountries, type CountryRecord } from '@zentto/shared-api';

export interface CountrySelectProps {
  value: string | null;
  onChange: (countryCode: string | null, country?: CountryRecord) => void;
  label?: string;
  required?: boolean;
  error?: boolean;
  helperText?: string;
  disabled?: boolean;
  fullWidth?: boolean;
  size?: 'small' | 'medium';
  /** Filtra por estos códigos ISO2 (ej. ['VE','CO','MX'] para LatAm) */
  onlyCountries?: string[];
  /** Excluye estos códigos */
  excludeCountries?: string[];
  /** Muestra prefijo telefónico al lado del nombre */
  showPhonePrefix?: boolean;
}

/**
 * Selector universal de países. Pulls 195 países desde /v1/config/countries.
 * Render: bandera + nombre (+ prefijo opcional).
 */
export function CountrySelect({
  value,
  onChange,
  label = 'País',
  required = false,
  error = false,
  helperText,
  disabled = false,
  fullWidth = true,
  size = 'medium',
  onlyCountries,
  excludeCountries,
  showPhonePrefix = false,
}: CountrySelectProps) {
  const { data: countries = [], isLoading } = useCountries();

  const filtered = countries.filter((c) => {
    if (onlyCountries && !onlyCountries.includes(c.CountryCode)) return false;
    if (excludeCountries && excludeCountries.includes(c.CountryCode)) return false;
    return true;
  });

  const selected = filtered.find((c) => c.CountryCode === value) ?? null;

  return (
    <Autocomplete
      value={selected}
      onChange={(_e, c) => onChange(c?.CountryCode ?? null, c ?? undefined)}
      options={filtered}
      getOptionLabel={(c) => c.CountryName}
      isOptionEqualToValue={(a, b) => a.CountryCode === b.CountryCode}
      loading={isLoading}
      disabled={disabled}
      fullWidth={fullWidth}
      size={size}
      renderOption={(props, c) => {
        const { key, ...rest } = props as any;
        return (
          <Box component="li" key={c.CountryCode} {...rest} sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <span style={{ fontSize: '1.2em', lineHeight: 1 }}>{c.FlagEmoji ?? '🏳️'}</span>
            <span style={{ flex: 1 }}>{c.CountryName}</span>
            {showPhonePrefix && c.PhonePrefix && (
              <span style={{ color: '#888', fontSize: '0.85em' }}>{c.PhonePrefix}</span>
            )}
            <span style={{ color: '#aaa', fontSize: '0.75em' }}>{c.CountryCode}</span>
          </Box>
        );
      }}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          required={required}
          error={error}
          helperText={helperText}
          InputProps={{
            ...params.InputProps,
            startAdornment: selected?.FlagEmoji ? (
              <span style={{ fontSize: '1.2em', marginRight: 4 }}>{selected.FlagEmoji}</span>
            ) : params.InputProps.startAdornment,
          }}
        />
      )}
    />
  );
}
