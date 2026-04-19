"use client";

import { useEffect, useRef } from "react";
import { useCartStore, type CartItem } from "../store/useCartStore";
import {
  fetchServerCart,
  pushCartItem,
  deleteCartItem,
  clearServerCart as serverClear,
  useMergeCart,
} from "../hooks/useServerCart";

/**
 * Mantiene en sync el cart local (zustand) con el server cart (store.Cart).
 *
 * Comportamiento:
 *  - Al montar: hidrata el cart local con lo que haya en el server (merge no destructivo).
 *  - Tras cada cambio en `items`: hace push (debounced 600ms) por cada item nuevo/cambiado
 *    y delete por los removidos.
 *  - Al detectar `customerToken` (login), dispara merge guest→customer.
 *
 * No bloquea la UI: errores se ignoran silenciosamente (best-effort).
 */
export default function CartSyncProvider() {
  const items = useCartStore((s) => s.items);
  const cartToken = useCartStore((s) => s.cartToken);
  const customerToken = useCartStore((s) => s.customerToken);
  const customerInfo = useCartStore((s) => s.customerInfo);
  const currency = useCartStore((s) => s.currency);
  const hydrateFromServer = useCartStore((s) => s.hydrateFromServer);
  const merge = useMergeCart();

  const lastSyncedRef = useRef<Map<string, CartItem> | null>(null);
  const initialHydrateRef = useRef(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // 1) Hidratación inicial desde server
  useEffect(() => {
    if (initialHydrateRef.current || !cartToken) return;
    initialHydrateRef.current = true;
    fetchServerCart(cartToken)
      .then((server) => {
        if (!server.items?.length) {
          // Si server vacío y local tiene items, el push diferencial los subirá.
          lastSyncedRef.current = new Map();
          return;
        }
        // Merge: server gana sobre local (multi-device → siempre lo más reciente del server).
        const local = useCartStore.getState().items;
        const merged = new Map<string, CartItem>();
        for (const i of server.items) {
          merged.set(i.productCode, {
            productCode: i.productCode,
            productName: i.productName ?? "Producto",
            imageUrl: i.imageUrl,
            quantity: Number(i.quantity),
            unitPrice: Number(i.unitPrice),
            taxRate: Number(i.taxRate),
            subtotal: Math.round(Number(i.unitPrice) * Number(i.quantity) * 100) / 100,
            taxAmount: Math.round(Number(i.unitPrice) * Number(i.quantity) * Number(i.taxRate) * 100) / 100,
            total: Math.round(Number(i.unitPrice) * Number(i.quantity) * (1 + Number(i.taxRate)) * 100) / 100,
          });
        }
        // Items locales que no están en server → conservar (intent del user antes de sync)
        for (const li of local) {
          if (!merged.has(li.productCode)) merged.set(li.productCode, li);
        }
        const finalItems = Array.from(merged.values());
        hydrateFromServer(finalItems);
        lastSyncedRef.current = new Map(finalItems.map((i) => [i.productCode, i]));
      })
      .catch(() => {
        lastSyncedRef.current = new Map();
      });
  }, [cartToken, hydrateFromServer]);

  // 2) Sync diferencial al cambiar items (debounced)
  useEffect(() => {
    if (!initialHydrateRef.current || !cartToken) return;
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      const prev = lastSyncedRef.current ?? new Map<string, CartItem>();
      const next = new Map(items.map((i) => [i.productCode, i]));

      // Removed
      for (const [code] of prev) {
        if (!next.has(code)) {
          deleteCartItem(cartToken, code).catch(() => {});
        }
      }
      // Added or updated
      for (const [code, it] of next) {
        const prevIt = prev.get(code);
        if (!prevIt || prevIt.quantity !== it.quantity || prevIt.unitPrice !== it.unitPrice) {
          pushCartItem({
            cartToken,
            productCode: code,
            productName: it.productName,
            imageUrl: it.imageUrl,
            quantity: it.quantity,
            unitPrice: it.unitPrice,
            taxRate: it.taxRate,
            currencyCode: currency.currencyCode,
            countryCode: currency.countryCode,
            exchangeRate: currency.rateToBase,
          }).catch(() => {});
        }
      }
      lastSyncedRef.current = next;
    }, 600);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [items, cartToken, currency]);

  // 3) Vaciado total cuando items pasa a vacío explícitamente
  useEffect(() => {
    if (!initialHydrateRef.current || !cartToken) return;
    if (items.length === 0 && (lastSyncedRef.current?.size ?? 0) > 0) {
      serverClear(cartToken).catch(() => {});
      lastSyncedRef.current = new Map();
    }
  }, [items, cartToken]);

  // 4) Merge guest → customer al detectar login
  useEffect(() => {
    if (!customerToken || !cartToken) return;
    merge.mutate(cartToken, {
      onSuccess: (res: { mergedCartToken?: string | null } | undefined) => {
        if (res?.mergedCartToken && res.mergedCartToken !== cartToken) {
          useCartStore.getState().setCartToken(res.mergedCartToken);
          fetchServerCart(res.mergedCartToken).then((server) => {
            const items = server.items.map((i) => ({
              productCode: i.productCode,
              productName: i.productName ?? "Producto",
              imageUrl: i.imageUrl,
              quantity: Number(i.quantity),
              unitPrice: Number(i.unitPrice),
              taxRate: Number(i.taxRate),
              subtotal: Math.round(Number(i.unitPrice) * Number(i.quantity) * 100) / 100,
              taxAmount: Math.round(Number(i.unitPrice) * Number(i.quantity) * Number(i.taxRate) * 100) / 100,
              total: Math.round(Number(i.unitPrice) * Number(i.quantity) * (1 + Number(i.taxRate)) * 100) / 100,
            })) as CartItem[];
            hydrateFromServer(items);
            lastSyncedRef.current = new Map(items.map((i) => [i.productCode, i]));
          }).catch(() => {});
        }
      },
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [customerToken, customerInfo?.email]);

  return null;
}
