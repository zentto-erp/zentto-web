# @zentto/vertical-auth

Multi-tenant auth primitives para apps verticales Zentto (hotel, medical, education, tickets, etc.).

## Qué resuelve

Las apps verticales del ecosistema Zentto son Next.js (frontend) + Express (API) standalone que se autentican contra `zentto-auth`. Este paquete unifica:

- Captura de `companyAccesses[]` desde el login response y persistencia en JWT/session de NextAuth v5.
- Persistencia de la empresa activa en `localStorage["zentto-active-company:{userId}"]` (misma key que el ERP modular → sync cross-app en `.zentto.net`).
- Headers HTTP multi-tenant (`x-company-id`, `x-branch-id`, `x-timezone`, `x-country-code`) inyectados automáticamente en requests al backend.
- Componente MUI `CompanySwitcher` para cambiar de empresa sin relogin.
- Middleware Express que verifica JWT vía JWKS remoto y popula `req.scope` con el tenant.

## Uso frontend (Next.js + NextAuth v5)

```ts
// auth.ts
import NextAuth from "next-auth";
import { buildNextAuthConfig } from "@zentto/vertical-auth/frontend";
import { getServerAuthClient } from "@/lib/auth";

export const { handlers, signIn, signOut, auth } = NextAuth(
  buildNextAuthConfig({
    appId: "zentto-hotel",
    authClient: getServerAuthClient(),
    pages: { signIn: "/login" },
  }),
);
```

```tsx
// Providers.tsx
import { CompanyProvider } from "@zentto/vertical-auth/frontend";

export default function Providers({ children }) {
  return (
    <SessionProvider>
      <CompanyProvider>{children}</CompanyProvider>
    </SessionProvider>
  );
}
```

```tsx
// Layout (topbar)
import { CompanySwitcher } from "@zentto/vertical-auth/frontend";
<CompanySwitcher />
```

```ts
// api.ts
import { companyHeaders, getActiveCompany } from "@zentto/vertical-auth/frontend";

const userId = session.user.id;
const headers = {
  "Content-Type": "application/json",
  ...companyHeaders(getActiveCompany(userId)),
};
```

## Uso backend (Express)

```ts
import { createTenantMiddleware, requireCompany } from "@zentto/vertical-auth/backend";

const tenant = createTenantMiddleware({
  jwksUrl: "https://auth.zentto.net/.well-known/jwks.json",
});

app.use(tenant);

app.get("/v1/rooms", requireCompany, async (req, res) => {
  const { companyId, branchId, userId } = req.scope;
  // ...
});
```

## Peer deps

- React 18+
- Next.js 14+ / NextAuth v5 (solo si usas la parte frontend)
- Express 4+ y jose 5+ (solo si usas la parte backend)
- `@mui/material` 5+ (solo si usas `CompanySwitcher`)
- `@zentto/auth-client` (SDK zentto-auth)

## Versión

1.0.0 — 2026-04-20
