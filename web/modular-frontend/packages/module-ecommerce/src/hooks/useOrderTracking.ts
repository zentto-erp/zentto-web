"use client";

import { useQuery } from "@tanstack/react-query";

const API_BASE =
  typeof window !== "undefined"
    ? process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000"
    : "http://localhost:4000";

export interface TrackingEvent {
  documentNumber: string;
  eventCode:
    | "ORDER_CREATED"
    | "ORDER_PAID"
    | "ORDER_SHIPPED"
    | "ORDER_DELIVERED"
    | "ORDER_CANCELLED"
    | "NOTE";
  eventLabel: string;
  description: string | null;
  occurredAt: string;
  actorUser: string;
}

export function useOrderTracking(orderToken?: string) {
  return useQuery<TrackingEvent[]>({
    queryKey: ["store-order-tracking", orderToken],
    enabled: !!orderToken,
    refetchInterval: 30_000, // refresca cada 30s para ver cambios de estado
    queryFn: async () => {
      const res = await fetch(`${API_BASE}/store/orders/${encodeURIComponent(orderToken!)}/tracking`);
      if (!res.ok) return [];
      return res.json();
    },
  });
}
