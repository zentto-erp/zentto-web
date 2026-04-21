# Auditoría flujo marketplace multi-vendedor

> Fecha: 2026-04-20
> Scope: Ola 4 (PRs #476 + #497 + #506)
> Rama revisada: `fix/zentto-grid-registro-automatico`
> Migraciones: `00150`, `00151`, `00156`
> Feature flag: `STORE_AFFILIATE_PAYOUT_ENABLED` (mencionada en `00156`)

---

## 1. Onboarding

### Afiliado

**Implementado**

- Tabla `store.Affiliate` con estados (`pending|active|suspended|rejected`), índices por `CompanyId+CustomerId` y por status (`00150`).
- SP `usp_store_affiliate_register`: genera `ReferralCode` único `ZEN-XXXXXXXX` y persiste como `status='pending'`. Idempotente — si el customer ya aplicó, retorna la aplicación existente.
- Cifrado PII de `PayoutDetails` (pgcrypto, GUC `zentto.master_key`) — migración `00156` renombra `PayoutDetails` a `PayoutDetailsPlain` y añade `PayoutDetailsEnc bytea`. Writes usan `callSpOutWithPii`.
- Endpoint público `POST /store/affiliate/register` (requiere JWT de customer). Zod schema en `affiliate.routes.ts:123-129`.
- Admin endpoints: `GET /store/admin/affiliates`, `POST /store/admin/affiliates/:id/{status|approve|suspend}`. SP `usp_store_affiliate_admin_set_status` marca `ApprovedAt`/`ApprovedBy` cuando se activa.
- SP `usp_store_affiliate_track_click` exige `Status='active'`, así que pending no registra clicks.
- Página UI `/afiliados/registro` + `/afiliados/dashboard`.
- Seeds QA: 3 afiliados demo (DEMO001/002/003 en estados distintos).

**Falta**

- **Email de notificación** al registrarse (pending) y al aprobarse (active). No hay template `affiliateApprovedTemplate` en `email-templates/base.ts` y ningún lado llama `sendAuthMail` desde `adminSetAffiliateStatus`.
- **No hay migración de data vieja** del plaintext `PayoutDetailsPlain` → `PayoutDetailsEnc`. La migración `00156` lo advierte: "NO cifra la data vieja. Queda en `PayoutDetailsPlain` hasta que el PO dispare un script manual". No existe `docs/security/pii-encryption.md` referenciado.
- **No hay verificación KYC ni documentos**: el form pide `legalName`, `taxId`, `contactEmail`, `payoutMethod` + details, pero no hay upload de documentos (DNI/RIF/certificado bancario), ni validación externa.
- **Seeds tienen `CustomerId=NULL`** → rompe la query `WHERE "CompanyId"=$1 AND "CustomerId"=$2` en `usp_store_affiliate_get_dashboard`: los 3 demo no son consultables por un customer real. Solo se listan en admin.
- **CHECK constraint `status IN ('active','suspended','pending','rejected')`** deja sin camino explícito para `banned`/`deleted` (borrado lógico).

### Merchant

**Implementado**

- Tabla `store.Merchant` con estados (`pending|approved|suspended|rejected`), `StoreSlug UNIQUE` (auto-generado desde `legal_name`), `CommissionRate numeric(5,2) DEFAULT 15.00`, `RejectionReason` (`00151`).
- SP `usp_store_merchant_apply`: idempotente, genera slug único. Cifra `PayoutDetails` en `00156`.
- Admin endpoints `/admin/merchants/:id/{approve|reject|suspend}` con `reason` opcional.
- Dashboard `usp_store_merchant_dashboard` (contadores de productos y `SUM(TotalAmount)` de líneas con su `MerchantId`).
- Detail admin `usp_store_merchant_admin_get_detail` descifra `payoutDetails` on-the-fly.
- Wizard UI `/vender/aplicar` (4 pasos): Datos / Documentos / Método de pago / Confirmar.
- Seeds QA: 2 merchants (`techhub` approved, `moda-andina` pending).

**Falta**

- **Paso "Documentos" del wizard es cosmético** (`vender/aplicar/page.tsx:136-155`): solo captura email/teléfono/URL de logo. Comentario del front: "documentos opcionales en MVP". No hay upload de RIF/DNI/certificado bancario.
- **Sin KYC real** (validación automática de tax_id vs registro mercantil). `taxId` se guarda como string libre.
- **Sin email de notificación** al aplicar, al aprobar, al rechazar ni al suspender. Idéntico gap al de afiliado.
- **No hay tabla de historial de estados** (`MerchantStatusHistory`) para auditoría — solo `ApprovedAt/ApprovedBy` last-write-wins.
- **Sin validación anti-duplicado** por `tax_id` (solo por `CustomerId` + `StoreSlug`).
- **`BannerUrl`** está en la tabla pero no se captura en el wizard ni se expone en UI admin.

---

## 2. Catálogo merchant

**Implementado**

- Tabla separada `store.MerchantProduct` (no reutiliza `master.Product`) con estados `draft|pending_review|approved|rejected` y `ReviewNotes`.
- SP `usp_store_merchant_product_submit` (toggle `p_submit` → guarda draft o envía a `pending_review`).
- Workflow de moderación: `usp_store_merchant_admin_product_review` → `approved|rejected` + notas.
- Admin endpoint `/store/admin/merchant-products/pending` con filtro por status.
- UI merchant `/vender/dashboard` con dialog de nuevo producto (botón "Guardar borrador" y "Enviar a revisión").
- UI admin `/admin/vendedores/productos` (página existe).
- Merchant gestiona stock propio (columna `Stock` en `MerchantProduct`, independiente de `master.Inventory`).

**Falta** (bloqueos mayores)

- **Productos del merchant NO aparecen en el storefront público**. `listProducts()` en `service.ts` usa `usp_Store_Product_List` que lee `master.Product`, no `store.MerchantProduct`. Esto es el **hueco P0 más grave**: la tienda no muestra productos del marketplace.
- **`MerchantProduct` y `master.Product` son esquemas distintos** → sin vista unificada, sin resolución única por `ProductCode` ni por categoría. El `ProductCode` se auto-genera `MP-xxxxxx` y no se cruza con `master.Product`.
- **`ar.SalesDocumentLine."MerchantId"` existe pero NUNCA se popula**. El SP `usp_Store_Order_Create` (referenciado en `service.ts:522`, no visible en `sqlweb-mssql/includes/sp/`) recibe `ItemsXml` solo con `ProductCode`, `ProductName`, `quantity`, `unitPrice`, `taxRate`, `subtotal`, `taxAmount`. No hay `MerchantId` en el payload → todas las líneas quedan con `MerchantId=NULL`. El dashboard `ordersTotal` y `grossSalesUsd` del merchant darán **0**.
- **Sin moderación automática** (SKU duplicado, imagen prohibida, palabras clave).
- **Sin pricing por variantes, sin SKU variants** (un merchant no puede subir "Camisa M/L/XL" como variantes — solo productos separados).
- **Sin imágenes múltiples**: `MerchantProduct.ImageUrl` es una sola URL (vs. `master.Product` que tiene tabla aparte).
- **Sin reseñas/rating** ligados a `MerchantProduct`.
- **Sin shipping config** por merchant (regiones que envía, tarifas).

---

## 3. Transacción (checkout multi-vendor)

**Implementado**

- Afiliado: atribución automática en `POST /store/checkout` vía `tryAttributeOrder` leyendo cookie `zentto_ref` o `body.referralCode` (`routes.ts:353-386`). Fire-and-forget, anti-duplicado por `(CompanyId, OrderNumber)` en `usp_store_affiliate_attribute_order`.
- Cookie de atribución 30 días vía `GET /store/affiliate/link/:code` (httpOnly=false, SameSite=Lax).
- Comisión calculada por categoría mayoritaria de la orden: el SP de atribución hace `JOIN master.Product ON ProductCode` + `JOIN store.AffiliateCommissionRate ON lower(Category)`, con fallback a rate `IsDefault=true`.
- Pago integrado con zentto-payments (Paddle u otros providers) vía `POST /v1/checkout` (`service.ts:566-613`).
- Callback URL: `${PUBLIC_API}/v1/payments/callback`.
- Tracking timeline: `usp_Store_Order_Tracking_Add` con evento `ORDER_CREATED`.
- Email transaccional: `orderCreatedTemplate` + `sendAuthMail` post-checkout.

**Falta** (bloqueos críticos)

- **NO hay split de pagos**. El payment gateway cobra el monto total a la cuenta Zentto (Paddle master account). No se usa Stripe Connect, Paddle split, ni custodia/escrow. Zentto queda como deudor del merchant hasta el payout manual.
- **`MerchantId` no se propaga al `SalesDocumentLine`** — ver punto 2. Sin `MerchantId` en líneas, no hay forma de saber de qué merchant era cada producto en la orden → imposible calcular commission splits reales.
- **Sin SP `usp_store_merchant_attribute_order`** (análogo al afiliado). El merchant no "recibe" ventas; solo se ven en su dashboard si alguien seteara `MerchantId` manualmente.
- **Carrito con múltiples merchants no se segmenta**. No hay separación visual en `/carrito` ni en `/checkout` por tienda. Todo se cobra en una sola factura a Zentto.
- **Factura**: el comprador recibe factura de **Zentto** (la instancia ERP emisora, `usp_Store_Order_Create`). No hay emisión separada por merchant. `fiscal-agent` no tiene integración merchant-aware.
- **Shipping**: no existe — no hay tabla `ShippingRate`, `ShippingZone`, ni columnas de peso/dimensiones en `MerchantProduct`. El checkout asume envío gratuito o fuera de sistema.
- **Sin reserva de stock cruzada**. `MerchantProduct.Stock` no se decrementa en `usp_Store_Order_Create` porque ese SP solo mueve `master.Inventory`.
- **Sin validación de merchant `Status='approved'` al agregar al carrito** — si un merchant se suspende, sus productos pendientes en carrito siguen cobrando.

---

## 4. Comisiones y payouts

**Implementado — AFILIADOS**

- `store.AffiliateCommissionRate` con seed de 5 rates (ver tabla abajo). SP `usp_store_affiliate_commission_rates_list` público.
- `store.AffiliateCommission` con estados `pending|approved|paid|reversed`. Ligada a `ClickId` y `PayoutId`.
- SP `usp_store_affiliate_payout_generate` agrupa approved por afiliado, crea `AffiliatePayout`, marca commissions como `paid`.
- Bulk approve/paid/reverse: `usp_store_affiliate_admin_commissions_bulk_status` (Ola 4).
- Dashboard afiliado con serie mensual últimos 6 meses.

**Implementado — MERCHANTS**

- Tabla `store.MerchantPayout` con `GrossAmount`, `CommissionAmount`, `NetAmount`, `CurrencyCode`, `Status`.
- `store.Merchant.CommissionRate numeric(5,2) DEFAULT 15.00` — **fija por merchant, no por categoría**.

**Falta — MERCHANTS** (gap crítico)

- **NO existe `usp_store_merchant_payout_generate`**. Búsqueda en todo el repo retorna 0 archivos. El SP no está en `migrations/00151`, ni en `sqlweb-mssql/07_patch_store_affiliates_marketplace.sql`, ni en `sqlweb-pg/`.
- **NO existe tabla `store.MerchantCommission`**. El marketplace no tiene granularidad línea-a-línea de comisiones; solo se agregaría a nivel `MerchantPayout` si existiera un SP.
- **No hay hook al checkout** que genere `MerchantCommission` por cada línea con `MerchantId IS NOT NULL`.
- **`CommissionRate` plano por merchant, no por categoría**. Se setea al aprobar (seed pone 12% para TechHub, 15% para default). Imposible diferenciar categorías de alto/bajo margen.
- **Sin rate override por producto** ni por campaña.
- **Sin minimum payout threshold** (vs afiliado que lo menciona en la UI de `/afiliados` como "USD 10" pero no está enforced en el SP).
- **Sin moneda multi-currency por merchant**: `currencyCode` default `USD`.
- **Combinación afiliado + merchant**: no está considerada. Si un cliente viene vía `zentto_ref` y compra a merchant X, `usp_store_affiliate_attribute_order` genera commission para el afiliado tomando `order_amount` completo (el merchant ni existe en el cálculo). No hay doble descuento: **Zentto pagará comisión al afiliado del 3-10% sobre el total Y al merchant el 85% del mismo total** → pérdida.

### Tabla de rates actuales

| Categoría | Commission Rate (afiliado) | Fuente |
|---|---|---|
| Electrónica | 3.00% | Seed `00150:116` |
| Ropa | 5.00% | Seed `00150:117` |
| Hogar | 7.00% | Seed `00150:118` |
| Software | 10.00% | Seed `00150:119` |
| default (afiliado) | 3.00% | Seed `00150:120` |
| **TODOS (merchant)** | **15.00% plano** | `Merchant.CommissionRate DEFAULT` (`00151:43`) |
| TechHub (seed merchant) | 12.00% | `00151:547` |

Nota: los rates de **afiliado** son lo que Zentto paga al afiliado sobre la venta bruta. El rate de **merchant** es lo que Zentto retiene de la venta (comisión plataforma). Hoy no hay rates por categoría para merchant.

---

## 5. Devoluciones / reversal

**Implementado**

- Estado `reversed` en `AffiliateCommission.Status` (`00150:83`).
- Bulk `adminBulkSetCommissionStatus` acepta `reversed` como target.
- Módulo de devoluciones existe en frontend (`/admin/devoluciones`, `useReturns.ts`).

**Falta**

- **No hay hook automático RMA → `AffiliateCommission.status='reversed'`**. El admin debe hacer bulk manual.
- **Sin equivalente para merchants**: como no hay `MerchantCommission`, no hay reversal merchant.
- **Sin logic de claw-back** si la commission ya fue pagada en un payout cerrado (Status='paid', PayoutId set). El bulk status update pone `reversed` pero no ajusta `AffiliatePayout.TotalAmount` ni genera cargo negativo.
- **Sin workflow merchant RMA**: no hay endpoint "merchant acepta/rechaza devolución" ni impacto en su próximo payout.
- **Sin notification email** al afiliado/merchant cuando se revierte una commission.

---

## 6. Fiscal / compliance

**Implementado**

- `Affiliate.TaxId` y `Merchant.TaxId` (campos libres).
- Cifrado PII de datos bancarios (pgcrypto + GUC).
- Paridad SQL Server del cifrado en `sqlweb-mssql/08_patch_pii_pgcrypto_payout_details.sql` (ENCRYPTBYPASSPHRASE).
- `currency_code` en commission/payout (USD default).

**Falta**

- **IVA se calcula a nivel orden**, no por merchant. `SalesDocumentLine.TaxAmount` viene del `taxRate` del item en el checkout — no hay lógica "merchant A es VE, merchant B es ES → cada uno con su IVA".
- **Sin cálculo de IVA por país del merchant** ni por país del comprador (importante para UE — OSS/IOSS).
- **Sin emisión de resumen anual al merchant** (1099 USA, RECIBO LATAM, ISLR Venezuela).
- **Sin retención de impuestos** en payouts. El merchant recibe el neto sin impuesto retenido — complicado en VE (ISLR 3%), CO (ReteFuente), MX (IVA retenido), etc.
- **Sin integración con `fiscal-agent`** para emitir factura/recibo al merchant con el payout.
- **Sin export contable** (asientos a `ar.JournalEntry`) de los payouts generados.
- **No hay campo `CountryCode` en Merchant/Affiliate** para determinar régimen fiscal.

---

## 7. Operación (dashboards + notify)

**Implementado — Dashboard afiliado** (`/afiliados/dashboard`)

- Clicks total (12m), conversiones, pending/approved/paid amounts.
- Serie mensual últimos 6m (SVG chart inline).
- Tabla paginada de commissions (`ZenttoRecordTable`).
- Referral link con botón copy.
- Banners visuales (solo cosmético, no funcionales).
- FAQ de mínimo pago (USD 10).

**Implementado — Dashboard merchant** (`/vender/dashboard`)

- Métricas: productsTotal / approved / pendingReview / ordersTotal / grossSalesUsd / payoutsPaidUsd.
- Sección acordeones: Productos / Ventas / Payouts.
- Dialog de creación de productos (draft o submit).

**Implementado — Admin**

- `/admin/afiliados` (lista + aprobar/suspender + ver commissions).
- `/admin/afiliados/comisiones` (bulk status).
- `/admin/vendedores` (lista + aprobar/rechazar/suspender con reason).
- `/admin/vendedores/productos` (moderación de productos pending).

**Falta — Dashboards**

- **Merchant: `ordersTotal` y `grossSalesUsd` siempre en 0** porque `MerchantId` no se popula en `SalesDocumentLine` (ver §3).
- **Merchant: sin vista de payouts individuales** — solo total agregado. No hay SP `usp_store_merchant_payouts_list`.
- **Merchant: sin gráficos de ventas por periodo**, ni top productos.
- **Admin merchant payouts**: no existe página. No hay botón "generar payouts merchant" (tampoco SP ni endpoint).
- **Afiliado: botones de banner no hacen nada** (links dead).

**Falta — Notificaciones (zentto-notify)**

- **CERO integraciones con zentto-notify o email templates** para:
  - Afiliado registrado (pending)
  - Afiliado aprobado/rechazado/suspendido
  - Afiliado: commission generada (nueva venta)
  - Afiliado: payout enviado
  - Merchant aplicó (pending)
  - Merchant aprobado/rechazado/suspendido
  - Merchant: producto aprobado/rechazado
  - Merchant: nueva venta (orden con su producto)
  - Merchant: payout enviado
- Solo existe `orderCreatedTemplate` en `email-templates/base.ts` para el comprador.
- `/admin/merchants/:id/approve` no llama `sendAuthMail` ni `/v1/send` de zentto-notify.

---

## 8. Tabla resumen de huecos (priorizados P0/P1/P2)

| # | Hueco | Prioridad | Esfuerzo | Impacto |
|---|---|---|---|---|
| 1 | Productos merchant no visibles en storefront (`listProducts` ignora `MerchantProduct`) | **P0** | M (2-3d) | Bloquea marketplace — no hay venta posible |
| 2 | `ar.SalesDocumentLine.MerchantId` nunca populado (SP `usp_Store_Order_Create` no recibe merchant) | **P0** | M (2d) | Dashboards merchant dan 0, payouts imposibles |
| 3 | No existe SP `usp_store_merchant_payout_generate` ni tabla `MerchantCommission` | **P0** | L (4-5d) | No hay forma de pagar al merchant |
| 4 | Sin split real de pagos (Zentto custodia total) | **P0** | XL (10d+) | Riesgo contable + cashflow merchant |
| 5 | Cero notificaciones email para afiliado/merchant (approval, venta, payout) | **P0** | M (3d) | Onboarding silencioso = abandono; merchants no saben que venden |
| 6 | Comisiones merchant planas (15% DEFAULT) sin rates por categoría | **P1** | S (1-2d) | No competitivo vs Amazon/ML |
| 7 | Combinación afiliado+merchant doble descuento sobre mismo total | **P1** | M (2d) | Pérdida económica por orden |
| 8 | Sin KYC ni upload documentos (wizard merchant paso "Documentos" cosmético) | **P1** | M (3d) | Compliance + fraude |
| 9 | Sin shipping (tabla, zonas, tarifas, peso/dimensiones) | **P1** | L (5d) | No se puede operar productos físicos |
| 10 | Sin cálculo IVA por país del merchant/comprador (OSS/IOSS) | **P1** | L (5-7d) | Bloquea expansión UE/LATAM |
| 11 | Sin factura separada del merchant (todo factura Zentto) | **P1** | L (5d) | Riesgo fiscal merchant |
| 12 | Reversal de commission no ajusta `AffiliatePayout.TotalAmount` (ni clawback) | **P1** | S (1d) | Datos financieros inconsistentes |
| 13 | Data PII vieja no migrada a `PayoutDetailsEnc` (script manual pendiente) | **P1** | S (1d) | Gap de seguridad pre-GA |
| 14 | Seeds `Affiliate` tienen `CustomerId=NULL` → no consultables como customer | **P2** | XS (2h) | QA inconsistente |
| 15 | `MerchantProduct` sin variantes, sin imágenes múltiples, sin reviews | **P2** | M (3-4d) | UX limitada vs `master.Product` |
| 16 | Sin `MerchantStatusHistory` para auditoría de aprobaciones | **P2** | S (1d) | Trazabilidad |
| 17 | Sin resumen anual fiscal (1099/ISLR/RECIBO) al merchant/afiliado | **P2** | M (3d) | Compliance anual |
| 18 | `BannerUrl` de merchant no capturado en wizard ni expuesto | **P2** | XS (2h) | UX storefront |
| 19 | Merchant pending/suspended: productos en carrito siguen pagables | **P2** | S (1d) | Edge case |
| 20 | Botones de banner del dashboard afiliado dead (no descargan) | **P2** | S (1d) | UX |

---

## 9. Recomendación de rate merchant

### Análisis del 15% default actual

| Plataforma | Rate típico | Categoría |
|---|---|---|
| Amazon | 8–15% | Variable por categoría; 15% solo en ropa/accesorios |
| Mercado Libre | 11–17% | Clásico 11%, Premium 17%; +$ fijo por venta |
| Shopify | 0% (suscripción) | Solo fees de pago (~2.9% + $0.30) |
| eBay | 8–14% | Final value fee |
| Etsy | 6.5% + $0.20 listing | Mucho menor |

**Diagnóstico**: 15% plano es competitivo en ropa/accesorios, pero **alto para electrónica** (Amazon cobra 8%, ML cobra 11%) y **muy bajo para software/digitales** (Amazon 15–20%, Envato 30–50%). Un rate plano desincentiva a merchants de margen bajo (electrónica) y regala margen a merchants de margen alto (software/servicios).

Además, el ejercicio **"rates entre 1–3%"** del usuario tiene sentido solo si Zentto quiere **competir en precio sobre todos** (estrategia Shopify), pero en ese caso habría que cobrar **suscripción mensual al merchant**, algo que **no existe** en el modelo actual (sería `store.MerchantSubscription`). Con rates tan bajos como 1–3% sin subscripción, Zentto no cubriría costos de payments (Paddle 5%+) ni infra.

### Propuesta: rates por categoría (transaccional, sin subscripción)

Recomiendo una tabla escalonada realista (no 1-3%):

| Categoría | Rate propuesto | Justificación |
|---|---|---|
| Electrónica | 8.00% | Alinear con Amazon; margen merchant típico 10-15% |
| Ropa y Accesorios | 14.00% | Estándar marketplace fashion |
| Hogar y Jardín | 12.00% | Mid-volume |
| Belleza y Cuidado | 13.00% | Alto margen merchant |
| Alimentos y Bebidas | 10.00% | Volumen alto, margen bajo |
| Software y Digitales | 18.00% | Sin logística, alto margen |
| Servicios profesionales | 15.00% | Hotel/medical/education verticales |
| Libros y Medios | 12.00% | Benchmark Amazon |
| Juguetes | 13.00% | Mid |
| Salud | 10.00% | Regulado, margen bajo |
| **default** | **12.00%** | Mediana del catálogo |

> Si el PO quiere los **1–3% literal** pedidos en el prompt, la única forma viable es migrar a modelo **SaaS subscription**: crear `store.MerchantPlan` con Basic (29 USD/mes + 3%), Pro (99 USD/mes + 2%), Enterprise (299 USD/mes + 1%). Esto requiere integrar con Paddle subscription + extender `Merchant.PlanId`.

### Calculadora — ejemplo numérico

**Caso 1 — Merchant de Electrónica, venta de USD 1.000 (rate 8%)**

```
Venta bruta:              USD 1,000.00
Commission Zentto (8%):   USD    80.00
Payment fee Paddle (~5%): USD    50.00
Net al merchant:          USD   870.00
```

**Caso 2 — Merchant de Software, venta digital USD 200 (rate 18%)**

```
Venta bruta:              USD   200.00
Commission Zentto (18%):  USD    36.00
Payment fee Paddle:       USD    10.00
Net al merchant:          USD   154.00
```

**Caso 3 — Combinación afiliado + merchant (HUECO ACTUAL)**

Cliente viene de afiliado `ZEN-XX`, compra USD 500 al merchant TechHub (electrónica):

```
Venta bruta:                     USD 500.00
Affiliate commission (3%):       USD  15.00   ← Zentto le paga al afiliado
Merchant commission actual (12%): USD  60.00   ← Zentto retiene
Merchant recibe (88%):           USD 440.00

Zentto se queda con:   USD 60 − USD 15 = USD 45 (9%)
Fee Paddle:            USD 25
Zentto neto real:      USD 20 (4%)  ← marginal, no cubre infra
```

**Solución propuesta**: affiliate commission debe descontarse del `CommissionAmount` del merchant, **no del total de la venta**. El merchant absorbe el costo de adquisición del cliente.

```
Venta bruta:                     USD 500.00
Merchant commission (12%):       USD  60.00
Affiliate commission (3% sobre los USD 60): USD 1.80
Zentto se queda con:             USD 58.20
Fee Paddle:                      USD 25.00
Zentto neto:                     USD 33.20 (6.6%)  ← sostenible
Merchant recibe:                 USD 440.00
```

Alternativa: affiliate commission plana sobre el total, pero reducir `Merchant.CommissionRate` por la exposición al tráfico orgánico vs. tráfico atribuido a afiliado — lógica demasiado compleja, preferir la primera.

---

## Anexos — Archivos de referencia

- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/migrations/postgres/00150_store_affiliate_program.sql`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/migrations/postgres/00151_store_merchant_marketplace.sql`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/migrations/postgres/00156_pii_pgcrypto_payout_details.sql`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/affiliate.service.ts`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/affiliate.routes.ts`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/merchant.service.ts`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/merchant.routes.ts`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/service.ts` (checkout líneas 466-646)
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/api/src/modules/ecommerce/routes.ts` (atribución checkout líneas 340-386)
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/apps/ecommerce/src/app/vender/aplicar/page.tsx`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/apps/ecommerce/src/app/vender/dashboard/page.tsx`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/apps/ecommerce/src/app/afiliados/page.tsx`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/apps/ecommerce/src/app/afiliados/dashboard/page.tsx`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/apps/ecommerce/src/app/admin/vendedores/page.tsx`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/packages/module-ecommerce/src/hooks/useAffiliate.ts`
- `d:/DatqBoxWorkspace/DatqBoxWeb/web/modular-frontend/packages/module-ecommerce/src/hooks/useMerchant.ts`
