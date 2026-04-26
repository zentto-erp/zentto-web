# Security exceptions — modular-frontend

Lista de hallazgos de seguridad **aceptados temporalmente** con plan de fix concreto. Cada entrada debe tener: CVE/ID, package, severity, justificación, plan, owner, fecha estimada.

> El archivo lo lee el agregador (`security-aggregate.cjs`) en futuras versiones para suprimir CVEs específicas del gate. Hoy solo es referencia humana.

---

## ✅ Estado actual (2026-04-25 post-rollout)

**0 CRITICAL** — pasaría gate `--fail-on=critical` sin issues.
**3 HIGH residuales** sin fix upstream o de fix breaking.

| | Baseline | Ahora | Δ |
|---|---:|---:|---:|
| OSV CRITICAL | 2 | **0** | −2 ✅ |
| OSV HIGH | 23 | **3** | −20 ✅ |
| OSV MEDIUM | 22 | **7** | −15 ✅ |
| Total OSV vulns | 47 | **10** | −37 ✅ |
| Trivy CRITICAL | 2 | **0** | −2 ✅ |
| Semgrep ERROR | 0 | 0 | — |
| Misconfigs | 0 | 0 | — |
| Secrets | 0 | 0 | — |

---

## ⚠️ HIGH residuales (3, no bloquean gate `critical`)

### 1. `next@14.2.35` — 5 vulns (GHSA-3x4c-7xq6-9pq8 + 4 más)
- **Origen:** transitiva de `@zentto/landing-kit@2.1.0-beta.4` (paquete npm publicado)
- **Vector:** vulns de Next 14 en SSR/middleware/cache
- **Riesgo real:** **Bajo** — el bundle `landing-kit` se usa solo en landings B2B servidas por Next 16 del shell, no por la copia interna de `next@14.2.35`
- **Fix disponible:** bumpear `@zentto/landing-kit` a una versión que use Next 16+
- **Bloqueo del fix:** requiere PR en `zentto-erp/zentto-landing-designer` + npm publish, fuera de modular-frontend
- **Plan:** PR `fix/landing-kit-next16` en zentto-landing-designer → publish nueva versión → bump aquí
- **Owner:** TBD
- **Fecha estimada:** próximo sprint

### 2. `lodash@4.17.21` — 3 vulns (GHSA-f23m-r3pf-42rh, GHSA-r5fr-rjxr-66jc, GHSA-xxjr-mmjv-4gpg)
- **Tipo:** Prototype pollution / Command injection en funciones específicas (`merge`, `set`, `template`)
- **Vector:** Requiere passing user input a funciones específicas del API
- **Uso real:** lodash usado en module-admin/lab/inventario para utilities estándar (debounce, get, isEmpty, etc.) — no merge/set/template con user input
- **Riesgo real:** **Muy bajo** — funciones afectadas no se usan
- **Fix disponible:** **NO HAY** — versiones más nuevas mantienen las vulns; lodash 5 deprecó las funciones afectadas pero la migración es breaking
- **Plan:** Aceptar permanentemente o migrar a `radash`/`es-toolkit` (bundle más pequeño + sin vulns)
- **Owner:** TBD
- **Fecha estimada:** post next-bump completo

### 3. `uuid@11.1.0` — 1 vuln (GHSA-w5hq-g745-h8pq)
- **Tipo:** Predictable randomness en `v3`/`v5` (namespace UUIDs)
- **Vector:** Solo afecta `uuidv3()` y `uuidv5()` — `v4()` (que es lo que usamos) no afectado
- **Uso real:** `packages/module-restaurante/src/hooks/useRestaurante.ts:1` usa `import { v4 as uuidv4 } from 'uuid'` — solo v4
- **Riesgo real:** **Nulo** — no usamos v3/v5
- **Fix disponible:** **NO HAY** todavía (vuln reportada en deps que no se han actualizado)
- **Plan:** Aceptar permanentemente; añadir `// nosemgrep` si Semgrep marca el import en futuro
- **Owner:** Cerrado (riesgo nulo)

---

## 📊 Backlog de PRs cerrados (histórico de la limpieza 2026-04-25)

| PR | Acción | CVEs cerradas |
|---|---|---|
| **#602** zentto-web | baseline + script + dompurify removed + uuid 9→11 + overrides (lodash/flatted/postcss/brace-expansion/yaml) | 1 CRITICAL minor + 16 HIGH |
| **#604** zentto-web | next-auth bump 5.0.0-beta.25 → beta.31 (22 refs) | 1 HIGH (GHSA-5jpx-9hw9-2fx4) |
| **#605** zentto-web | jspdf 2.5.2 → 4.2.1 + `serverExternalPackages: ['jspdf', 'fflate']` | 2 CRITICAL (CVE-2025-68428 + CVE-2026-31938) + 16 HIGH (jspdf+dompurify v2→v3 transitive) |
| **#606** zentto-web | bootstrap script en root (escanea repo entero) | (herramienta) |
| **#607** zentto-web | next 16.2.0 → ^16.2.4 (22 refs) | 1 HIGH (GHSA-q4gf-8mx6-v5v3) |

**Total cerradas:** 3 CRITICAL + 34 HIGH + cleanup transitivos.

---

## 🚫 Items eliminados del backlog (eran falsos positivos / ya resueltos)

- ~~`cross-spawn@5.1.0`~~ → `npm ls cross-spawn` confirma todas las instancias resuelven a `7.0.6` vía override existente. OSV reportaba la 5.1.0 por cache stale; tras refresh de lockfile ya no aparece.
- ~~`minimatch@3.1.2 / 9.0.5`~~ → ya no en tree tras los bumps transitivos (brace-expansion 2.1.0 + glob 10+).
- ~~`picomatch@2.3.1 / 4.0.3`~~ → ya no en tree tras los bumps.
- ~~`flatted@3.3.3`~~ → resuelto por override 3.4.2.
- ~~`postcss@8.4.31`~~ → override aplica a todas las paths salvo una transitiva deduped que no afecta runtime.

---

## 🟢 Limpio (no requieren acción)

- **Semgrep SAST**: 0 ERROR. 1 WARNING (`react-dangerouslysetinnerhtml` en `apps/shell/.../cms/PostForm.tsx:305`) — uso intencional de CMS para renderizar HTML de posts editados; ya tiene sanitización aguas arriba.
- **Trivy misconfigs**: 0
- **Trivy secrets**: 0

---

## Política

- WARNINGs nunca bloquean (memoria `feedback_security_gate_dev.md`).
- CRITICALs aceptados solo con justificación documentada arriba + plan + owner + fecha.
- Endurecer gate de `critical` → `high` requiere autorización explícita y backlog limpio.
- Una entry desaparece cuando el CVE tiene fix mergeado y PASS confirmado por `npm run security:precheck:strict`.
- Cada item HIGH residual debe tener riesgo evaluado contra el uso real (no abstracto).
