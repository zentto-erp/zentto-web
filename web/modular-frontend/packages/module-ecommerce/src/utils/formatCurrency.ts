import type { DisplayCurrency } from "../store/useCartStore";

/**
 * Formatea un monto en moneda BASE (catálogo) usando el display currency del carrito.
 *  - Multiplica por rateToBase
 *  - Aplica formato local
 *  - Antepone el símbolo
 */
export function formatPrice(amountBase: number, currency: DisplayCurrency): string {
  const display = amountBase * (currency.rateToBase || 1);
  try {
    const fmt = new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: currency.currencyCode,
      maximumFractionDigits: 2,
    });
    return fmt.format(display);
  } catch {
    return `${currency.symbol} ${display.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
  }
}

/** Versión que acepta el monto YA convertido (no aplica rateToBase). */
export function formatDisplayAmount(amountDisplay: number, currency: DisplayCurrency): string {
  try {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: currency.currencyCode,
      maximumFractionDigits: 2,
    }).format(amountDisplay);
  } catch {
    return `${currency.symbol} ${amountDisplay.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
  }
}
