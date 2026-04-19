"use client";

import { useEffect, useMemo } from "react";
import { Box, MenuItem, Select, Tooltip } from "@mui/material";
import { useStorefrontCurrencies, useStorefrontCountries, useResolveCountry } from "../hooks/useStorefront";
import { useCartStore } from "../store/useCartStore";

/**
 * Selector de moneda + país para el header del storefront.
 *
 * Comportamiento:
 *  - Al montar (primera vez), resuelve país por IP (CF-IPCountry → endpoint /resolve)
 *    y aplica país + currencyCode + tasa default.
 *  - El usuario puede cambiar país (que recalcula tasa por país) o moneda directamente.
 *  - Persistido en localStorage vía useCartStore.
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

  const sortedCountries = useMemo(
    () => (countries || []).slice().sort((a, b) => a.countryName.localeCompare(b.countryName)),
    [countries]
  );

  return (
    <Box sx={{ display: "flex", gap: 1, alignItems: "center" }}>
      <Tooltip title="País de envío / reglas fiscales">
        <Select
          size="small"
          value={currency.countryCode}
          onChange={(e) => onCountryChange(String(e.target.value))}
          sx={{ minWidth: 110, bgcolor: "background.paper", fontSize: 13 }}
        >
          {sortedCountries.map((c) => (
            <MenuItem key={c.countryCode} value={c.countryCode}>
              <span style={{ marginRight: 6 }}>{c.flagEmoji}</span>
              {c.countryCode}
            </MenuItem>
          ))}
        </Select>
      </Tooltip>
      <Tooltip title="Moneda de visualización">
        <Select
          size="small"
          value={currency.currencyCode}
          onChange={(e) => onCurrencyChange(String(e.target.value))}
          sx={{ minWidth: 95, bgcolor: "background.paper", fontSize: 13 }}
        >
          {(currencies || []).map((c) => (
            <MenuItem key={c.currencyCode} value={c.currencyCode}>
              {c.symbol} {c.currencyCode}
            </MenuItem>
          ))}
        </Select>
      </Tooltip>
    </Box>
  );
}
