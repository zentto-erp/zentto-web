'use client';

import { useMemo, useState } from 'react';
import { Box, TextField, Autocomplete } from '@mui/material';
import { useCountries, type CountryRecord } from '@zentto/shared-api';

export interface PhoneInputProps {
  /** Valor completo: "+58 4145555555" o "+1 5551234567" */
  value: string;
  onChange: (fullNumber: string, parts: { dialCode: string; nationalNumber: string; countryCode: string | null }) => void;
  /** ISO2 del país preferido si el valor está vacío (default: VE) */
  defaultCountry?: string;
  label?: string;
  required?: boolean;
  error?: boolean;
  helperText?: string;
  disabled?: boolean;
  fullWidth?: boolean;
  size?: 'small' | 'medium';
}

/**
 * Input telefónico con selector de país (bandera + prefijo).
 * No usa libphonenumber-js para evitar el bundle. Validación básica de longitud.
 */
export function PhoneInput({
  value,
  onChange,
  defaultCountry = 'VE',
  label = 'Teléfono',
  required = false,
  error = false,
  helperText,
  disabled = false,
  fullWidth = true,
  size = 'medium',
}: PhoneInputProps) {
  const { data: countries = [] } = useCountries();

  // Parseo del valor inicial: separar +CC del resto
  const { initialDial, initialNational } = useMemo(() => {
    if (!value) return { initialDial: '', initialNational: '' };
    const match = value.match(/^(\+\d{1,4})\s*(.*)$/);
    if (match) return { initialDial: match[1], initialNational: match[2].trim() };
    return { initialDial: '', initialNational: value };
  }, [value]);

  const [country, setCountry] = useState<CountryRecord | null>(null);
  const [national, setNational] = useState(initialNational);

  // Resolver el país seleccionado (init from default or from value's dial code)
  const resolvedCountry = useMemo(() => {
    if (country) return country;
    if (initialDial && countries.length > 0) {
      const match = countries.find((c) => c.PhonePrefix === initialDial);
      if (match) return match;
    }
    return countries.find((c) => c.CountryCode === defaultCountry) ?? countries[0] ?? null;
  }, [country, initialDial, countries, defaultCountry]);

  const dialCode = resolvedCountry?.PhonePrefix ?? '';

  function emitChange(nextNational: string, nextCountry: CountryRecord | null) {
    const dc = nextCountry?.PhonePrefix ?? '';
    const sanitized = nextNational.replace(/[^\d]/g, '');
    const full = dc ? `${dc} ${sanitized}` : sanitized;
    onChange(full, {
      dialCode: dc,
      nationalNumber: sanitized,
      countryCode: nextCountry?.CountryCode ?? null,
    });
  }

  return (
    <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start', width: fullWidth ? '100%' : 'auto' }}>
      <Autocomplete
        value={resolvedCountry}
        onChange={(_e, c) => {
          setCountry(c);
          emitChange(national, c);
        }}
        options={countries}
        getOptionLabel={(c) => `${c.FlagEmoji ?? ''} ${c.PhonePrefix ?? ''} ${c.CountryName}`}
        isOptionEqualToValue={(a, b) => a.CountryCode === b.CountryCode}
        disabled={disabled}
        size={size}
        sx={{ minWidth: 140 }}
        renderOption={(props, c) => {
          const { key, ...rest } = props as any;
          return (
            <Box component="li" key={c.CountryCode} {...rest} sx={{ display: 'flex', gap: 1 }}>
              <span style={{ fontSize: '1.2em' }}>{c.FlagEmoji ?? '🏳️'}</span>
              <span style={{ minWidth: 50 }}>{c.PhonePrefix}</span>
              <span style={{ color: '#888', fontSize: '0.85em' }}>{c.CountryName}</span>
            </Box>
          );
        }}
        renderInput={(params) => (
          <TextField
            {...params}
            label="Código"
            size={size}
            InputProps={{
              ...params.InputProps,
              startAdornment: resolvedCountry?.FlagEmoji ? (
                <span style={{ fontSize: '1.2em', marginRight: 4 }}>{resolvedCountry.FlagEmoji}</span>
              ) : null,
            }}
          />
        )}
      />
      <TextField
        value={national}
        onChange={(e) => {
          const v = e.target.value.replace(/[^\d\s-]/g, '');
          setNational(v);
          emitChange(v, resolvedCountry);
        }}
        label={label}
        required={required}
        error={error}
        helperText={helperText ?? (dialCode ? `Número con prefijo ${dialCode}` : undefined)}
        disabled={disabled}
        fullWidth
        size={size}
        placeholder="4145551234"
      />
    </Box>
  );
}
