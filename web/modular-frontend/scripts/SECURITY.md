# Security precheck — modular-frontend

Reproduce localmente el escaneo de seguridad del workflow reutilizable
`zentto-erp/.github/.github/workflows/security.yml` antes de pushear.

## Uso rápido

```bash
# Modo report (no falla, solo informa)
npm run security:precheck

# Modo strict (falla con mismo gate que CI: critical)
npm run security:precheck -- --strict

# Threshold custom
npm run security:precheck -- --fail-on=high

# Saltar scanners específicos (acelera local)
npm run security:precheck -- --skip=trivy,osv
```

## Qué corre

| Scanner | Para qué | En CI gate-blocks |
|---|---|---|
| **Semgrep** | SAST — XSS, hardcoded secrets, OWASP top-10 patterns | ✅ sí (`fail-on: critical`) |
| **Trivy fs** | Vulnerabilidades en deps + misconfigs + secrets en code | ❌ informa, no bloquea |
| **OSV-Scanner** | Cross-check vulns vs GitHub Advisory + OSV DB | (no está en CI todavía) |

## Backend

Por defecto usa **Docker** (más confiable, multi-plataforma). Si docker no está, intenta binarios nativos en `.zentto/security/bin/` (ver fallback abajo).

## Outputs

Todos van a `.zentto/security/` (gitignored vía `.zentto/`):

- `semgrep.json` · `trivy.json` · `osv.json` — outputs crudos
- `REPORT.md` — agregado legible con tabla por severity y verdict del gate

## Flags

| Flag | Default | Significado |
|---|---|---|
| `--strict` | off | Setea `--fail-on=critical` y exit 1 si hay findings al threshold |
| `--fail-on=critical\|high\|medium\|none` | `none` | Threshold del gate |
| `--skip=semgrep,trivy,osv` | — | Salta scanners (CSV) |
| `--no-pull` | off | No hace `docker pull` (útil offline) |

## Antes del PR

Recomendado:

```bash
npm run security:precheck -- --strict
```

Si pasa: tu PR no romperá el gate de CI por findings críticos nuevos. Si falla: arregla los CRITICAL antes de pushear (overrides en `package.json`, bumps directos, o `.semgrepignore` con justificación documentada).

## Fallback sin Docker

Si no tenés Docker:

```bash
# Semgrep via venv (Python 3.10+)
python -m venv .zentto/security/venv
.zentto/security/venv/Scripts/pip install semgrep   # Windows
# .zentto/security/venv/bin/pip install semgrep    # Linux/Mac

# Trivy + OSV: descargar binarios
# Trivy:   https://github.com/aquasecurity/trivy/releases/latest
# OSV:     https://github.com/google/osv-scanner/releases/latest
# Colocar en .zentto/security/bin/ (trivy.exe, osv-scanner.exe en Win)
```

## Política del gate

Por decisión del product owner (memoria `feedback_security_gate_dev.md`):

- **WARNINGs nunca bloquean deploys** — se corrigen progresivamente en features dedicadas.
- Endurecer el gate de `critical` → `high` requiere autorización explícita y limpieza previa del backlog.

## Backlog de hallazgos aceptados

Ver [SECURITY-EXCEPTIONS.md](./SECURITY-EXCEPTIONS.md) — lista de CRITICAL/HIGH aceptados temporalmente con plan, owner y fecha de fix. Cada entry sale del backlog cuando su PR mergea y `npm run security:precheck:strict` pasa.
