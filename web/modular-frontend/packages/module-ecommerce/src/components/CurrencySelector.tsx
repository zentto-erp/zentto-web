"use client";

import { useEffect, useMemo } from "react";
import { Autocomplete, Box, TextField, Tooltip, Typography } from "@mui/material";
import { useStorefrontCurrencies, useStorefrontCountries, useResolveCountry } from "../hooks/useStorefront";
import { useCartStore } from "../store/useCartStore";
import type { StorefrontCountry, StorefrontCurrency } from "../hooks/useStorefront";

/**
 * Selector de moneda + país para el header del storefront.
 *
 * Comportamiento:
 *  - Al montar (primera vez), resuelve país por IP (CF-IPCountry → endpoint /resolve)
 *    y aplica país + currencyCode + tasa default.
 *  - El usuario puede cambiar país (que recalcula tasa por país) o moneda directamente.
 *  - Persistido en localStorage vía useCartStore.
 *  - Usa Autocomplete para escalar a muchos países/monedas y soportar búsqueda integrada.
 *  - Dedupe defensivo por `countryCode` / `currencyCode` (la API puede devolver repetidos).
 */
export default function CurrencySelector() {
  const { data: countries } = useStorefrontCountries();
  const { data: currencies } = useStorefrontCurrencies();
  const { data: resolved } = useResolveCountry();

  const currency = useCartStore((s) => s.currency);
  const setCurrency = useCartStore((s) => s.setCurrency);

  // Auto-aplicar país resuelto la primera vez (si el usuario no lo ha cambiado).
  useEffect(() => {
    if (!resolved || !currencies?.length) return;
    if (currency.countryCode === resolved.countryCode) return;
    const matched = currencies.find((c) => c.currencyCode === resolved.currencyCode);
    setCurrency({
      currencyCode: resolved.currencyCode,
      symbol: matched?.symbol || resolved.currencySymbol || resolved.currencyCode,
      rateToBase: Number(matched?.rateToBase ?? resolved.defaultExchangeRate ?? 1),
      countryCode: resolved.countryCode,
      taxRate: Number(resolved.defaultTaxRate ?? 0),
      taxName: resolved.defaultTaxName || "IVA",
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resolved?.countryCode, currencies?.length]);

  const onCurrencyChange = (code: string) => {
    const m = currencies?.find((c) => c.currencyCode === code);
    if (!m) return;
    setCurrency({ ...currency, currencyCode: m.currencyCode, symbol: m.symbol, rateToBase: Number(m.rateToBase) });
  };

  const onCountryChange = async (code: string) => {
    if (!code) return;
    const country = countries?.find((c) => c.countryCode === code);
    const matchedCur = currencies?.find((c) => c.currencyCode === country?.currencyCode);
    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"}/store/storefront/country/${encodeURIComponent(code)}`
      );
      const data = await res.json();
      setCurrency({
        currencyCode: data.currencyCode,
        symbol: matchedCur?.symbol || data.currencySymbol || data.currencyCode,
        rateToBase: Number(matchedCur?.rateToBase ?? data.defaultExchangeRate ?? 1),
        countryCode: data.countryCode,
        taxRate: Number(data.defaultTaxRate ?? 0),
        taxName: data.defaultTaxName || "IVA",
      });
    } catch {
      // tasa fallback sin re-fetch
      if (country) {
        setCurrency({
          ...currency,
          countryCode: country.countryCode,
          currencyCode: country.currencyCode,
          symbol: matchedCur?.symbol || country.currencySymbol || country.currencyCode,
          rateToBase: Number(matchedCur?.rateToBase ?? 1),
        });
      }
    }
  };

  // Dedupe + orden alfabético por nombre de país.
  const countryOptions = useMemo<StorefrontCountry[]>(() => {
    const unique = Array.from(
      new Map((countries || []).map((c) => [c.countryCode, c])).values()
    );
    return unique.slice().sort((a, b) => a.countryName.localeCompare(b.countryName));
  }, [countries]);

  // Dedupe + orden alfabético por código de moneda.
  const currencyOptions = useMemo<StorefrontCurrency[]>(() => {
    const unique = Array.from(
      new Map((currencies || []).map((c) => [c.currencyCode, c])).values()
    );
    return unique.slice().sort((a, b) => a.currencyCode.localeCompare(b.currencyCode));
  }, [currencies]);

  const selectedCountry =
    countryOptions.find((c) => c.countryCode === currency.countryCode) || null;
  const selectedCurrency =
    currencyOptions.find((c) => c.currencyCode === currency.currencyCode) || null;

  // Estilos compactos reutilizables (dark theme del header).
  const inputSx = {
    bgcolor: "background.paper",
    borderRadius: 1,
    "& .MuiOutlinedInput-root": { fontSize: 13, height: 34 },
    "& .MuiOutlinedInput-input": { py: 0.3 },
  } as const;

  return (
    <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
      <Tooltip title="País de envío / reglas fiscales">
        <Autocomplete
          size="small"
          options={countryOptions}
          value={selectedCountry}
          onChange={(_e, val) => val && onCountryChange(val.countryCode)}
          disableClearable
          autoHighlight
          getOptionLabel={(opt) => `${opt.countryCode}`}
          isOptionEqualToValue={(a, b) => a.countryCode === b.countryCode}
          filterOptions={(opts, state) => {
            const q = state.inputValue.trim().toLowerCase();
            if (!q) return opts;
            return opts.filter(
              (o) =>
                o.countryCode.toLowerCase().includes(q) ||
                o.countryName.toLowerCase().includes(q)
            );
          }}
          sx={{ minWidth: 110 }}
          renderInput={(params) => (
            <TextField
              {...params}
              placeholder="País"
              sx={inputSx}
            />
          )}
          renderOption={(props, option) => (
            <Box component="li" {...props} key={option.countryCode} sx={{ fontSize: 13, gap: 1 }}>
              <span style={{ fontSize: 16, lineHeight: 1 }}>{option.flagEmoji}</span>
              <Typography component="span" sx={{ fontWeight: 600, fontSize: 13 }}>
                {option.countryCode}
              </Typography>
              <Typography component="span" sx={{ color: "text.secondary", fontSize: 12 }}>
                {option.countryName}
              </Typography>
            </Box>
          )}
        />
      </Tooltip>

      <Tooltip title="Moneda de visualización">
        <Autocomplete
          size="small"
          options={currencyOptions}
          value={selectedCurrency}
          onChange={(_e, val) => val && onCurrencyChange(val.currencyCode)}
          disableClearable
          autoHighlight
          getOptionLabel={(opt) => `${opt.symbol} ${opt.currencyCode}`}
          isOptionEqualToValue={(a, b) => a.currencyCode === b.currencyCode}
          filterOptions={(opts, state) => {
            const q = state.inputValue.trim().toLowerCase();
            if (!q) return opts;
            return opts.filter(
              (o) =>
                o.currencyCode.toLowerCase().includes(q) ||
                (o.symbol || "").toLowerCase().includes(q) ||
                (o.currencyName || "").toLowerCase().includes(q)
            );
          }}
          sx={{ minWidth: 140 }}
          renderInput={(params) => (
            <TextField
              {...params}
              placeholder="Moneda"
              sx={inputSx}
            />
          )}
          renderOption={(props, option) => (
            <Box component="li" {...props} key={option.currencyCode} sx={{ fontSize: 13, gap: 1 }}>
              <Typography component="span" sx={{ minWidth: 22, fontWeight: 600, fontSize: 13 }}>
                {option.symbol}
              </Typography>
              <Typography component="span" sx={{ fontWeight: 600, fontSize: 13 }}>
                {option.currencyCode}
              </Typography>
              <Typography component="span" sx={{ color: "text.secondary", fontSize: 12 }}>
                {option.currencyName}
              </Typography>
            </Box>
          )}
        />
      </Tooltip>
    </Box>
  );
}
