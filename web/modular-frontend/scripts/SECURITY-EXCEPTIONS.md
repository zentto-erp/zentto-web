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

## ⚠️ HIGH pendientes (no bloquean gate `critical`, sí bloquearían gate `high`)

Pendientes de PRs separados por dep:

| Package | Versión | CVEs | Plan |
|---|---|---|---|
| `jspdf@2.5.2` | direct | 9 HIGH (CVE-2025-29907, CVE-2025-57810, CVE-2026-24133, CVE-2026-24737, CVE-2026-25535, CVE-2026-25755, CVE-2026-25940, CVE-2026-31898, GHSA-...) | Mismo PR que CRITICAL (todos los HIGH se fixean en jspdf 4.x) |
| `dompurify@2.5.9` | direct (sin uso real) | 7 HIGH | PR `fix/remove-unused-dompurify` — eliminar de module-nomina (no se usa en código) |
| `next-auth@5.0.0-beta.25` | direct (19 archivos) | 1 HIGH (GHSA-5jpx-9hw9-2fx4) | PR `fix/next-auth-bump-beta31` — bump a 5.0.0-beta.31 en TODOS los workspaces |
| `next@14.2.35 / 16.2.0` | direct (multi-version) | 5+1 HIGH | PR `fix/next-bump` — pin a 16.2.3+ |
| `cross-spawn@5.1.0` | transitive (override existente no aplica) | 1 HIGH | Investigar override raíz que no se aplica |
| `lodash@4.17.23` | transitive | 2 HIGH | Override `lodash: 4.17.21` |
| `minimatch@3.1.2 / 9.0.5` | transitive | 6 HIGH | Override versión segura |
| `picomatch@2.3.1 / 4.0.3` | transitive | 4 HIGH | Override |
| `flatted@3.3.3` | transitive | 2 (1 HIGH + 1 CRITICAL CVSS 8.9) | Override |
| `brace-expansion@1.1.12 / 2.0.2` | transitive | 2 | Override |
| `postcss@8.4.31` | transitive | 1 HIGH | Override `^8.4.49` |
| `uuid@9.0.1` | direct (apps/restaurante) | 1 HIGH | PR `fix/uuid-bump` — `^11.1.0` (mantiene CJS) |
| `yaml@1.10.2 / 2.5.1` | transitive | 2 HIGH | Override |

Total: **23 HIGH + 22 MEDIUM** identificados en baseline 2026-04-25.

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
