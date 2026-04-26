# Security exceptions — modular-frontend

Lista de hallazgos de seguridad **aceptados temporalmente** con plan de fix concreto. Cada entrada debe tener: CVE/ID, package, severity, justificación, plan, owner, fecha estimada.

> El archivo lo lee el agregador (`security-aggregate.cjs`) en futuras versiones para suprimir CVEs específicas del gate. Hoy solo es referencia humana.

---

## ❌ CRITICAL pendientes

### 1. `jspdf@2.5.2` — CVE-2025-68428 (CVSS 9.6)
- **Tipo:** RegEx DoS / billion laughs
- **Vector:** Requiere PDF generation con contenido attacker-controlled
- **Uso real:** `packages/module-bancos/src/components/VoucherPdf.ts` — único uso, genera vouchers de pago con datos de movimientos bancarios del usuario autenticado
- **Riesgo real:** **Bajo** — los datos del voucher (nombres de banco, beneficiario, concepto) provienen de la BD del propio tenant, no de input público
- **Fix disponible:** jspdf 4.0.0+
- **Bloqueo del fix:** jspdf v4 introdujo `fflate` como dep transitiva, que usa `new Worker(c + workerAdd, { eval: true })` — Turbopack/Next 16 falla SSR build con `Module not found: Can't resolve <dynamic>` en `fflate/lib/node.cjs:22`
- **Plan:** PR separado `fix/jspdf-v4-ssr-compat` con una de:
  - `serverExternalPackages: ['jspdf', 'fflate']` en cada `next.config.mjs` que use jspdf
  - O reemplazar jspdf por alternativa SSR-friendly (`pdfmake`, `pdfkit`)
- **Owner:** TBD
- **Fecha estimada:** próximo sprint de seguridad

### 2. `jspdf@2.5.2` — CVE-2026-31938 (CVSS 9.2)
- **Tipo:** Prototype pollution via canvas-context internals
- **Vector:** Mismo que CVE-2025-68428
- **Uso real, riesgo real, fix disponible, bloqueo, plan:** mismos que CVE-2025-68428
- **Owner:** TBD
- **Fecha estimada:** próximo sprint de seguridad

---

## ✅ HIGH resueltas en este PR

| Package | Antes | Ahora | Cómo |
|---|---|---|---|
| `dompurify` | 2.5.9 (sin uso) | REMOVED | Eliminada de `module-nomina/package.json` (0 imports en código) — fix 7 HIGH |
| `lodash` | 4.17.23 | 4.17.21 | Override root — fix 2 HIGH |
| `flatted` | 3.3.3 | 3.4.2 | Override root — fix 1 CRITICAL (CVSS 8.9) + 1 HIGH |
| `postcss` | 8.4.31 | 8.5.10 | Override root — fix 1 HIGH |
| `brace-expansion` | 1.1.12/2.0.2 | 2.1.0 | Override root — fix 2 HIGH |
| `yaml` | 1.10.2/2.5.1 | 2.8.3 | Override root — fix 2 HIGH |
| `uuid` | 9.0.1 (direct) | 11.1.0 | Bump en `apps/restaurante` — fix 1 HIGH |

**Subtotal:** 1 CRITICAL minor + 16 HIGH cerradas en este commit.

## ⚠️ HIGH pendientes (no bloquean gate `critical`, sí bloquearían gate `high`)

Pendientes de PRs separados por dep (alto riesgo de breaking change):

| Package | Versión | CVEs | Plan |
|---|---|---|---|
| `jspdf@2.5.2` | direct | 9 HIGH (CVE-2025-29907, CVE-2025-57810, CVE-2026-24133, CVE-2026-24737, CVE-2026-25535, CVE-2026-25755, CVE-2026-25940, CVE-2026-31898) | Mismo PR que CRITICAL (jspdf 4.x rompe SSR Turbopack) |
| `next-auth@5.0.0-beta.25` | direct (19 archivos) | 1 HIGH (GHSA-5jpx-9hw9-2fx4) | PR separado `fix/next-auth-bump-beta31` — afecta 19 workspaces, requiere validar cada app |
| `next@14.2.35 / 16.2.0` | direct (multi-version) | 5+1 HIGH | PR separado `fix/next-bump` — pin a 16.2.3+, validar cada app |
| `cross-spawn@5.1.0` | transitive (override existente no aplica) | 1 HIGH | Investigar por qué el override `cross-spawn: 7.0.6` no resuelve |
| `minimatch@3.1.2 / 9.0.5` | transitive | 6 HIGH | Override `minimatch: 10.x` (breaking API, validar consumidores) |
| `picomatch@2.3.1 / 4.0.3` | transitive | 4 HIGH | Override `picomatch: 4.x` (breaking ESM, validar fast-glob/chokidar) |

---

## 🟢 Limpio

- **Semgrep SAST**: 0 ERROR. 1 WARNING (`react-dangerouslysetinnerhtml` en `apps/shell/.../cms/PostForm.tsx:305`) — uso intencional de CMS para renderizar HTML de posts editados; ya tiene sanitización aguas arriba.
- **Trivy misconfigs**: 0
- **Trivy secrets**: 0

---

## Política

- WARNINGs nunca bloquean (memoria `feedback_security_gate_dev.md`).
- CRITICALs aceptados solo con justificación documentada arriba + plan + owner + fecha.
- Endurecer gate de `critical` → `high` requiere autorización explícita y backlog limpio.
- Una entry desaparece cuando el CVE tiene fix mergeado y PASS confirmado por `npm run security:precheck:strict`.
