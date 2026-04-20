"use client";

import { useEffect, useMemo } from "react";
import { Autocomplete, Box, TextField, Tooltip, Typography } from "@mui/material";
import { useStorefrontCurrencies, useStorefrontCountries, useResolveCountry } from "../hooks/useStorefront";
import { useCartStore } from "../store/useCartStore";
import type { StorefrontCountry, StorefrontCurrency } from "../hooks/useStorefront";

/**
 * Selector de país + moneda unificado para el header del storefront.
 *
 * Comportamiento:
 *  - Al montar (primera vez), resuelve país por IP (CF-IPCountry → endpoint /resolve)
 *    y aplica país + currencyCode + tasa default.
 *  - Un único `<Autocomplete>` agrupado por continente (spec Ola 1 §1A), con búsqueda
 *    por nombre de país, código ISO, moneda o símbolo.
 *  - Persistido en localStorage vía useCartStore.
 *  - Dedupe defensivo por `countryCode` (la API puede devolver repetidos).
 *
 * Mobile: el layout del header esconde este componente (solo se muestra >= md).
 * El drawer mobile recibirá su propia copia full-width en la sección "Envío y moneda".
 */

interface CountryOption extends StorefrontCountry {
  /** Moneda resuelta (symbol + name) — si la API de currencies la conoce. */
  currencyMatch: StorefrontCurrency | undefined;
  /** Continente calculado localmente para `groupBy` del Autocomplete. */
  continent: string;
}

/**
 * Mapa ISO-3166 alpha-2 → continente (continentes relevantes para Zentto).
 * Usamos estos buckets: "Latinoamérica", "Norteamérica", "Europa", "Asia",
 * "África", "Oceanía", "Otros". Faltantes caen en "Otros" sin bloquear.
 */
const CONTINENT_BY_COUNTRY: Record<string, string> = {
  // Latinoamérica (México + Centro/Sudamérica + Caribe español)
  AR: "Latinoamérica", BO: "Latinoamérica", BR: "Latinoamérica", CL: "Latinoamérica",
  CO: "Latinoamérica", CR: "Latinoamérica", CU: "Latinoamérica", DO: "Latinoamérica",
  EC: "Latinoamérica", SV: "Latinoamérica", GT: "Latinoamérica", HN: "Latinoamérica",
  MX: "Latinoamérica", NI: "Latinoamérica", PA: "Latinoamérica", PY: "Latinoamérica",
  PE: "Latinoamérica", PR: "Latinoamérica", UY: "Latinoamérica", VE: "Latinoamérica",
  // Norteamérica
  US: "Norteamérica", CA: "Norteamérica",
  // Europa
  ES: "Europa", PT: "Europa", FR: "Europa", DE: "Europa", IT: "Europa", GB: "Europa",
  IE: "Europa", NL: "Europa", BE: "Europa", LU: "Europa", CH: "Europa", AT: "Europa",
  SE: "Europa", NO: "Europa", DK: "Europa", FI: "Europa", PL: "Europa", CZ: "Europa",
  RO: "Europa", HU: "Europa", GR: "Europa", BG: "Europa", HR: "Europa", SI: "Europa",
  SK: "Europa", EE: "Europa", LV: "Europa", LT: "Europa", IS: "Europa",
  // Asia
  CN: "Asia", JP: "Asia", KR: "Asia", IN: "Asia", ID: "Asia", PH: "Asia",
  TH: "Asia", VN: "Asia", MY: "Asia", SG: "Asia", AE: "Asia", SA: "Asia",
  IL: "Asia", TR: "Asia",
  // África
  ZA: "África", EG: "África", MA: "África", NG: "África", KE: "África",
  // Oceanía
  AU: "Oceanía", NZ: "Oceanía",
};

/** Orden de presentación de continentes (Latinoamérica primero — base LATAM). */
const CONTINENT_ORDER: Record<string, number> = {
  Latinoamérica: 0,
  Norteamérica: 1,
  Europa: 2,
  Asia: 3,
  África: 4,
  Oceanía: 5,
  Otros: 9,
};

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

  // Dedupe + enriquecer con continente + moneda matched + orden alfabético.
  const countryOptions = useMemo<CountryOption[]>(() => {
    const unique = Array.from(
      new Map((countries || []).map((c) => [c.countryCode, c])).values()
    );
    const enriched: CountryOption[] = unique.map((c) => ({
      ...c,
      currencyMatch: currencies?.find((cc) => cc.currencyCode === c.currencyCode),
      continent: CONTINENT_BY_COUNTRY[c.countryCode] || "Otros",
    }));
    // Orden: continente (según CONTINENT_ORDER) luego nombre de país.
    enriched.sort((a, b) => {
      const ca = CONTINENT_ORDER[a.continent] ?? 9;
      const cb = CONTINENT_ORDER[b.continent] ?? 9;
      if (ca !== cb) return ca - cb;
      return a.countryName.localeCompare(b.countryName);
    });
    return enriched;
  }, [countries, currencies]);

  const selectedCountry =
    countryOptions.find((c) => c.countryCode === currency.countryCode) || null;

  const inputSx = {
    bgcolor: "background.paper",
    borderRadius: 1,
    "& .MuiOutlinedInput-root": { fontSize: 13, height: 34 },
    "& .MuiOutlinedInput-input": { py: 0.3 },
  } as const;

  return (
    <Tooltip title="Seleccionar país y moneda (reglas fiscales + visualización)">
      <Box>
        <Autocomplete
          size="small"
          options={countryOptions}
          value={selectedCountry}
          onChange={(_e, val) => val && onCountryChange(val.countryCode)}
          disableClearable
          autoHighlight
          groupBy={(opt) => opt.continent}
          getOptionLabel={(opt) =>
            `${opt.flagEmoji} ${opt.countryCode} · ${opt.currencyMatch?.symbol ?? opt.currencySymbol ?? ""} ${opt.currencyCode}`.trim()
          }
          isOptionEqualToValue={(a, b) => a.countryCode === b.countryCode}
          filterOptions={(opts, state) => {
            const q = state.inputValue.trim().toLowerCase();
            if (!q) return opts;
            return opts.filter((o) => {
              const hay =
                o.countryCode.toLowerCase() +
                " " +
                o.countryName.toLowerCase() +
                " " +
                (o.currencyCode || "").toLowerCase() +
                " " +
                (o.currencyMatch?.symbol || o.currencySymbol || "").toLowerCase() +
                " " +
                (o.currencyMatch?.currencyName || "").toLowerCase();
              return hay.includes(q);
            });
          }}
          sx={{ minWidth: { xs: 160, md: 200 } }}
          slotProps={{
            paper: { sx: { minWidth: 280 } },
          }}
          renderInput={(params) => (
            <TextField
              {...params}
              placeholder="País / Moneda"
              inputProps={{
                ...params.inputProps,
                "aria-label": "Seleccionar país y moneda",
              }}
              sx={inputSx}
            />
          )}
          renderOption={(props, option) => (
            <Box
              component="li"
              {...props}
              key={option.countryCode}
              sx={{ fontSize: 13, gap: 1, display: "flex", alignItems: "center" }}
            >
              <span style={{ fontSize: 16, lineHeight: 1 }}>{option.flagEmoji}</span>
              <Typography component="span" sx={{ fontWeight: 600, fontSize: 13, minWidth: 28 }}>
                {option.countryCode}
              </Typography>
              <Typography component="span" sx={{ color: "text.primary", fontSize: 13, flex: 1 }}>
                {option.countryName}
              </Typography>
              <Typography component="span" sx={{ color: "text.secondary", fontSize: 12 }}>
                {option.currencyMatch?.symbol || option.currencySymbol || ""} {option.currencyCode}
              </Typography>
            </Box>
          )}
        />
      </Box>
    </Tooltip>
  );
}
