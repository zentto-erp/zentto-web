// Lab-local useTimezone — no depende de AuthProvider/NextAuth.
// Lee timezone desde la session del auto-login.
"use client";

import { useQuery } from "@tanstack/react-query";

export function useTimezone() {
  const { data: session } = useQuery({
    queryKey: ["lab-session"],
    queryFn: () => fetch("/api/auth/session").then((r) => r.json()),
    staleTime: 5 * 60 * 1000,
    retry: 1,
  });

  const timeZone = session?.company?.timeZone || "America/Caracas";
  const countryCode = session?.company?.countryCode || "VE";
  return { timeZone, countryCode };
}
