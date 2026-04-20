# Integration Review - Ecommerce (4 olas paralelas) - 2026-04-20

Autor: integration-reviewer (horizontal).
Audiencia: implementadores de las 4 olas feat/ecommerce-*.
Objetivo: cerrar los puntos donde las olas rompen la integracion horizontal (API, auth, multi-tenant, notify, obs, CI/CD, BD dual, modulos hermanos) antes de mergear a developer.

---

## 0. TL;DR - top 5 bloqueadores

1. **OpenAPI desactualizado (todo el storefront)**. El contrato web/contracts/openapi.yaml (10 143 lineas) NO documenta ningun endpoint de /store/*. Las 4 olas suman ~40 endpoints nuevos y ninguno quedara documentado si no se introduce primero la seccion tags [Store] + paths. Esto degrada el contrato para consumidores externos (panel, landings, hotel, mobile).
2. **Scope multi-tenant fragil en storefront**. web/api/src/modules/ecommerce/service.ts:8-11 hace scope() -> companyId=1, branchId=1 por defecto cuando no hay JWT. Cualquier endpoint publico nuevo (CMS, landing afiliado, press) servira datos del tenant 1 a todos los visitantes. Bloqueante para olas 2, 3 y 4.
3. **No existe bucket zentto-product-images ni config R2 publica**. En .github/workflows/deploy-api.yml:272-378 solo existe HETZNER_S3_* apuntando a zentto-api-backups (privado). El modulo media actual (web/api/src/modules/media/routes.ts:51-66) escribe a disco local con multer.diskStorage - rompe escalado horizontal y blue/green. Ola 2 depende de esto.
4. **@zentto/studio-react ya publicado v0.14.0**. NO hay dilema. Instalar @zentto/studio-react ^0.14.0. El renderer interno debe descartarse para no romper consistencia con apps/lab/landing-designer que ya lo consume.
5. **Admin endpoints usan user.isAdmin ad-hoc**. 12 ocurrencias en web/api/src/modules/ecommerce/routes.ts (lines 884, 894, 900, 924, 937, 949, 964, 976, 997, 1016, 1082). Existe requireAdmin middleware en web/api/src/middleware/auth.ts:273 (ya usado en studio/routes.ts). Las 4 olas deben usarlo.

---

## 1. BLOQUEADORES (resolver antes de mergear)

### B1 - OpenAPI no cubre /store/*

- Archivo: web/contracts/openapi.yaml
- Verificado: grep storefront|/store/|ecommerce -> 0 paths.
- Paths a documentar por ola:

| Ola | Paths minimos |
|---|---|
| Ola 1 UX | /store/storefront/countries, /store/storefront/currencies, /store/storefront/country/{code}, /store/storefront/resolve, /store/search |
| Ola 2 Admin | POST/PUT/DELETE /store/admin/products, POST /store/admin/products/{code}/images, /store/admin/categories, /store/admin/brands, /store/admin/reviews |
| Ola 3 CMS | GET /store/cms/pages, GET /store/cms/pages/{slug}, POST/PUT/DELETE /store/admin/cms/pages, /store/press, POST /store/admin/press |
| Ola 4 Afiliados | POST /store/affiliate/apply, GET /store/affiliate/me, GET /store/affiliate/clicks, POST /store/admin/affiliates/{id}/approve, GET /store/admin/affiliates, GET /store/admin/sellers, POST /store/seller/apply |

Accion: cada ola anade fragmento YAML antes de mergear.

### B2 - scope() fallback a companyId=1

- Archivo: web/api/src/modules/ecommerce/service.ts:8-11
- Impacto: endpoints publicos sirven datos del tenant 1 aunque el request venga de otro subdominio. Critico para ola 3 (CMS publico /store/cms/pages/{slug}) y ola 4 (landing afiliado publico).
- Accion:
  1. Cablear middleware web/api/src/middleware/subdomain-tenant.ts al storefront router.
  2. Si req._tenantCompanyId existe, scope() lo retorna.
  3. Deprecar fallback companyId=1 o hacerlo explicito via STORE_DEFAULT_COMPANY_ID + obs.audit("store.no_scope_fallback").

### B3 - Storage de imagenes en disco local

- Archivos: web/api/src/modules/media/routes.ts:51-66, web/api/src/config/env.ts:45-47
- multer.diskStorage -> MEDIA_STORAGE_PATH rompe blue/green, backup, sin CDN.
- Hetzner S3 configurado en .github/workflows/deploy-api.yml:272-378 pero bucket privado (zentto-api-backups).
- Accion para ola 2:
  1. Bucket nuevo zentto-product-images (publico, CORS *.zentto.net).
  2. Env vars nuevas (seccion 5).
  3. Cliente S3 en web/api/src/lib/object-storage.ts (no reutilizar cloudflare.client.ts).
  4. Migrar media/routes.ts a S3 con key c{companyId}/b{branchId}/{yyyy}/{mm}/{uuid}.{ext}.
  5. publicUrl via cdn.zentto.net o directo endpoint Hetzner.

### B4 - Admin endpoints sin requireAdmin

- Duplicado 12 veces en web/api/src/modules/ecommerce/routes.ts:884-1100.
- Correcto en web/api/src/modules/studio/routes.ts:169,213,247 (middleware).
- Accion: 4 olas usan requireJwt, requireAdmin en /store/admin/*. Rutas /store/affiliate/me y /store/seller/me de cliente usan requireJwt + ownership check. Aprobacion con requireAdmin.

### B5 - Coordinacion ola 2 y ola 4 en checkout

- Checkout en ecommerce/routes.ts:337-382 usa ar.SalesDocument (consumido por facturacion, contabilidad, CRM - ver 005_functions.sql).
- Ola 4 debe anadir affiliate_code / referral_source.
- Si ambas olas tocan el mismo SP sin coordinacion, la ultima gana.
- Accion recomendada: tabla lateral store.OrderAttribution (OrderNumber, CompanyId, AffiliateCode, SellerCode, ReferralUrl, UtmSource, UtmMedium, UtmCampaign, ClickedAt). Evita modificar ar.SalesDocument.

### B6 - Colision store.seller vs master.Seller

- master.Seller YA existe: web/api/sqlweb-pg/baseline/005_functions.sql:19078,19325,19376,19415,19431,39554 (vendedor ERP).
- store.seller* de ola 4 es marketplace seller (comerciante externo).
- Accion: renombrar a store.Merchant (preferido) o store.MarketplaceSeller.

### B7 - PII en payout_details

- store.affiliate.payout_details jsonb con IBAN/CBU. Dato financiero sensible.
- Accion:
  1. Cifrar con pgcrypto.pgp_sym_encrypt usando MASTER_KEY (ya existe en deploy-api.yml:278).
  2. Anadir keys a redactar en web/api/src/modules/integrations/observability.ts (payout_details, iban, cbu, tax_id).
  3. GET /store/affiliate/me solo masked (****1234).

---

## 2. ADVERTENCIAS (implementar con guardas)

### W1 - SQL Server mirror obligatorio

- Cada SP nueva (usp_Store_Product_Upsert, usp_Store_Images_Set, usp_Store_CmsPage_*, usp_Store_Affiliate_*) DEBE ir tambien en T-SQL en web/api/sqlweb/includes/sp/ y regenerar DDL con cd web/api/sqlweb-mssql && node pg2mssql.cjs.
- 16 archivos PG actuales usan p_company_id integer DEFAULT 1 (ver 00139_store_admin_metrics_and_rma.sql:58). No replicar el DEFAULT 1 en SPs nuevas.

### W2 - Cache invalidation

- web/api/src/lib/storefront-cache.ts cachea products:list/detail, categories:list, brands:list, search:list.
- Ola 2 debe llamar invalidatePrefix() tras cada upsert. Ola 3 igual con cms:* y press:*.
- Endpoint existe: POST /store/admin/cache/invalidate (routes.ts:900). Llamarlo automaticamente desde service.ts, no delegar a UI.

### W3 - Observabilidad en writes admin

- SDK: web/api/src/modules/integrations/observability.ts exporta obs.audit/perf/event.
- Precedente: middleware/auth.ts:188,258.
- Requerido:
  - obs.audit("store.product.upsert", { companyId, productCode, userId })
  - obs.audit("store.affiliate.approve", { companyId, affiliateId, approvedBy })
  - obs.perf("store.admin.metrics", ms)

### W4 - Notify para contact/affiliate-apply

- SDK: @zentto/platform-client/notify via web/api/src/modules/_shared/notify.ts:9-15.
- NUNCA fetch directo a notify.zentto.net. Usar emitBusinessNotification como checkout (ecommerce/routes.ts:221,367).
- Templates nuevos en zentto-notify:
  - AFFILIATE_APPLIED (admin + aplicante)
  - AFFILIATE_APPROVED / AFFILIATE_REJECTED
  - SELLER_APPLIED / SELLER_APPROVED
  - PRESS_INQUIRY (contact form tenant)
  - AFFILIATE_PAYOUT_SCHEDULED

### W5 - Compliance fiscal

- VE: retencion ISLR codigo 019 si afiliado es persona natural residente.
- ES: IRPF rendimiento actividad - modelo 111 trimestral, 190 anual.
- Accion: emitir obs.event("compliance.affiliate_payout_pending") para zentto-fiscal-agent. No bloqueante si payout detras de feature flag STORE_AFFILIATE_PAYOUT_ENABLED=false.

### W6 - Datagrid obligatorio en listas admin

- Regla workspace: <ZenttoDataGrid> de @zentto/shared-ui en TODA lista (productos, afiliados, CMS pages, press, sellers).
- Ola 1 menciona "tabla afiliados" - NO usar <table> HTML ni MUI DataGrid.

### W7 - CSRF + rate-limit

- web/api/src/middleware/csrf-origin.ts cubre admin heredado.
- POST /store/affiliate/apply (publico): anadir rate-limit (middleware/rate-limit.ts).

---

## 3. RECOMENDACIONES (no criticas)

### R1 - Usar @zentto/studio-react v0.14.0

- Publicado y consumido: apps/lab/package.json:32 ("^0.14.0"), apps/panel/package.json:17 ("^0.14.0").
- Store-frontend importa y renderiza JSON de store.cms_page.content_json.
- Monorepo fuente: D:\DatqBoxWorkspace\zentto-studio/packages/react.

### R2 - i18n en store.cms_page

- Schema sugerido: store.cms_page (cms_page_id, company_id, slug, locale, content_json, ...) UNIQUE (company_id, slug, locale).

### R3 - Mini-cart reusa endpoints existentes

- GET /store/cart?token=... (routes.ts:677), POST /store/cart/merge (routes.ts:725) ya existen. Ola 1 los consume.

### R4 - Hermanos NO comparten store.Product

- Hotel (../zentto-hotel), medical (../zentto-medical), pos tienen htl.Service, med.Service etc.
- Admin productos del store = CRUD especifico sobre master."Product" + campos ecommerce que ya existen (ShortDescription, LongDescription, Slug, BrandCode, WeightKg, WidthCm, HeightCm, DepthCm, WarrantyMonths, IsVariantParent, IndustryTemplateCode, SearchVector) en 003_tables.sql:3211-3248.

### R5 - Secuencia de branches

```
feat/ecommerce-openapi-storefront       (B1 baseline)
feat/ecommerce-scope-fix                (B2)
feat/ecommerce-object-storage           (B3)
feat/ecommerce-require-admin-refactor   (B4)
feat/ecommerce-ux-fixes                 (ola 1)
feat/ecommerce-admin-productos          (ola 2, depende B3+B4)
feat/ecommerce-studio-cms               (ola 3, depende R1)
feat/ecommerce-affiliates-marketplace   (ola 4, depende B5+B6+B7)
```

### R6 - master.Product es la tabla real (NO inv.product)

- El prompt menciona inv.product - NO existe. Producto vive en master."Product" (003_tables.sql:3211).
- inv.* solo tiene ProductBinStock (2646), ProductLot (2668), ProductSerial (2694).
- 75+ referencias en 005_functions.sql. Ola 2 anade columnas via ALTER TABLE, nunca cambia firmas de SPs existentes.

---

## 4. DEPENDENCIAS ENTRE OLAS

```
PRE-REQUISITOS HORIZONTALES (bloquean las 4 olas):
  B1  OpenAPI baseline /store/*
  B2  scope() multi-tenant fix
  B3  bucket zentto-product-images + env vars
  B4  requireAdmin refactor

Ola 1 (UX)          -> depende de B1.
Ola 2 (Admin prod.) -> depende de B1 + B2 + B3 + B4.
                       Aporta: usp_Store_Product_Upsert, tablas categoria/marca.
Ola 3 (Studio CMS)  -> depende de B1 + B2 + B4 + R1.
                       Tambien de ola 2 si inserta productos en paginas.
Ola 4 (Afiliados)   -> depende de B1 + B2 + B4 + B6 + B7.
                       Coordinacion con ola 2: NO modificar checkout.
                       Usar store.OrderAttribution como tabla lateral.
```

---

## 5. ENV VARS / SECRETS NUEVOS

| Nombre | Donde | Valor |
|---|---|---|
| HETZNER_S3_PRODUCT_IMAGES_BUCKET | GH secret + env API | zentto-product-images |
| HETZNER_S3_PRODUCT_IMAGES_ENDPOINT | GH secret + env API | https://nbg1.your-objectstorage.com |
| HETZNER_S3_PRODUCT_IMAGES_ACCESS_KEY | GH secret + env API | (nueva access key) |
| HETZNER_S3_PRODUCT_IMAGES_SECRET_KEY | GH secret + env API | (nueva secret key) |
| HETZNER_S3_PRODUCT_IMAGES_REGION | GH secret + env API | nbg1 |
| HETZNER_S3_PRODUCT_IMAGES_PUBLIC_URL | env API | https://cdn.zentto.net |
| STORE_DEFAULT_COMPANY_ID | env API | 1 (explicito) |
| STORE_CMS_STUDIO_VERSION | env API | ^0.14.0 (trazabilidad) |
| STORE_AFFILIATE_PAYOUT_ENABLED | GitHub Vars | false (opt-in flag) |
| STORE_AFFILIATE_DEFAULT_COMMISSION_PCT | env API | 10 |
| STORE_CONTACT_FORM_TO | env API (por tenant) | contacto@{tenant}.zentto.net |

MASTER_KEY ya existe (deploy-api.yml:278) - reutilizar para cifrar payout_details.

.github/workflows/deploy-api.yml debe anadir estas vars:
- envs: list (linea 284) - agregar los 6 HETZNER_S3_PRODUCT_IMAGES_*
- bloque sed/echo (desde linea 363) - replicar patron existente para cada var

NO tocar .github/workflows/security.yml - fail-on: critical sigue correcto para developer.

---

## 6. TABLA DE HALLAZGOS POR VECTOR

| Vector | Ola 1 | Ola 2 | Ola 3 | Ola 4 | Accion horizontal |
|---|---|---|---|---|---|
| API contracts (openapi.yaml) | WARN | BLOQ | BLOQ | BLOQ | B1 |
| Auth centralizado | OK | WARN | WARN | WARN | B4 |
| Notify | WARN | OK | WARN | BLOQ | W4 |
| Observability | WARN | WARN | WARN | WARN | W3 |
| Multi-tenant (scope) | BLOQ | BLOQ | BLOQ | BLOQ | B2 |
| Shared-UI datagrid | WARN | WARN | WARN | WARN | W6 |
| CI/CD + secrets | OK | BLOQ | OK | WARN | seccion 5 |
| BD dual PG+MSSQL | OK | BLOQ | BLOQ | BLOQ | W1 |
| Modulos hermanos | OK | OK | OK | BLOQ | B6 |
| PII / secretos | OK | OK | OK | BLOQ | B7 |
| Compliance fiscal | OK | OK | OK | WARN | W5 |

BLOQ = bloqueante. WARN = advertencia. OK = sin hallazgo.

---

## 7. SECUENCIA DE PRs

1. docs: merge de este documento a developer (referencia).
2. feat/ecommerce-openapi-storefront (B1 - baseline de rutas existentes).
3. feat/ecommerce-scope-fix (B2).
4. feat/ecommerce-require-admin-refactor (B4 - tactico).
5. feat/ecommerce-object-storage (B3).
6. feat/ecommerce-ux-fixes (ola 1, paralelo a 2-5).
7. feat/ecommerce-admin-productos (ola 2, depende 3/4/5).
8. feat/ecommerce-studio-cms (ola 3, depende 3/4).
9. feat/ecommerce-affiliates-marketplace (ola 4, depende 3/4 + B6 + B7).

Cada PR debe:
- Actualizar web/contracts/openapi.yaml con sus paths.
- Migracion goose en web/api/migrations/postgres/NNNNN_*.sql.
- SP T-SQL en web/api/sqlweb/includes/sp/.
- Regenerar DDL SQL Server con pg2mssql.cjs.
- obs.audit/perf en writes admin.
- <ZenttoDataGrid> en listas.
- Nunca Co-Authored-By: Claude en commits.

---

## 8. REFERENCIAS DE CODIGO

- web/api/src/modules/ecommerce/routes.ts:1-1126 (router storefront)
- web/api/src/modules/ecommerce/service.ts:8-11 (scope fallback companyId=1)
- web/api/src/middleware/auth.ts:121-269 (requireJwt)
- web/api/src/middleware/auth.ts:273-279 (requireAdmin)
- web/api/src/middleware/auth.ts:281-296 (requireModule)
- web/api/src/modules/studio/routes.ts:169,213,247 (uso correcto requireAdmin)
- web/api/src/modules/media/routes.ts:51-66 (disco local a migrar a S3)
- web/api/src/modules/_shared/notify.ts:9-15 (wrapper notify SDK)
- web/api/src/modules/_shared/scope.ts:14-33 (getActiveScope)
- web/api/src/modules/integrations/observability.ts:1-28 (obs SDK)
- web/api/src/config/env.ts:45-47 (media storage config)
- web/api/src/app.ts:71,294 (montaje /store)
- web/api/sqlweb-pg/baseline/003_tables.sql:3211-3248 (master.Product)
- web/api/migrations/postgres/00139_store_admin_metrics_and_rma.sql:58 (SPs store)
- .github/workflows/deploy-api.yml:272-378 (Hetzner S3 backups)
- .github/workflows/security.yml:21-25 (fail-on: critical developer)
- web/contracts/openapi.yaml (0 paths /store/*)

---

Fin del reporte. Revision horizontal - no redisenar, validar integracion.
