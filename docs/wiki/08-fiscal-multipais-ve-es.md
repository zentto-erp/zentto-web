# 08 - Fiscal Multi-pais (VE + ES Verifactu)

Fecha de verificacion documental: 2026-02-25

## Objetivo

Definir una base de conocimiento fiscal por pais para parametrizar POS y Restaurante en DatqBoxWeb.

## Espana (AEAT / Verifactu)

Marco principal:
- Real Decreto 1007/2023 (texto consolidado)
- Orden HAC/1177/2024
- Reglamento de facturacion RD 1619/2012

Fechas vigentes (actualizadas):
- 2026-07-29: inicio de sancion para productores/comercializadores de SIF.
- 2027-01-01: obligacion para contribuyentes del Impuesto sobre Sociedades.
- 2027-07-01: obligacion para el resto de obligados tributarios.

Notas:
- Esta linea temporal sustituye referencias previas de 2025-2026.
- El limite de factura simplificada es dual:
  - 400 EUR (regla general)
  - 3000 EUR en sectores como hosteleria/restauracion y ventas al por menor.

Requisitos clave a parametrizar:
- Registro de facturacion de alta y anulacion.
- Encadenamiento de registros (hash).
- Codigo QR en factura.
- Modalidad Verifactu (envio automatico) o No Verifactu (conservacion local cumpliendo requisitos).
- Series diferenciadas por tipo de factura cuando aplique.

## Venezuela (SENIAT)

Modelo de operacion base:
- Impresora fiscal homologada.
- Reportes/cierres fiscales (ej. Z).
- IVA nacional y reglas locales por configuracion de negocio.

## Implementacion en DatqBoxWeb

API:
- Modulo nuevo: `web/api/src/modules/fiscal`
- Fiscal Engine (Strategy): `web/api/src/modules/fiscal/engine.ts`
- Endpoints:
  - `GET /v1/fiscal/plugins`
  - `GET /v1/fiscal/countries`
  - `GET /v1/fiscal/countries/:countryCode`
  - `GET /v1/fiscal/countries/:countryCode/default-config`
  - `GET /v1/fiscal/countries/:countryCode/tax-rates`
  - `GET /v1/fiscal/countries/:countryCode/invoice-types`
  - `GET /v1/fiscal/countries/:countryCode/milestones`
  - `GET /v1/fiscal/countries/:countryCode/sources`
  - `GET /v1/fiscal/config`
  - `PUT /v1/fiscal/config`

Frontend:
- Pantalla actualizada: `web/frontend/src/app/(dashboard)/configuracion/page.tsx`
- Hook nuevo: `web/frontend/src/hooks/useFiscalConfig.ts`

SQL:
- Script base: `web/api/sql/fiscal/001_fiscal_multipais_base.sql`
- Tablas:
  - `FiscalCountryConfig`
  - `FiscalTaxRates`
  - `FiscalInvoiceTypes`
  - `FiscalRecords`

## Fuentes oficiales

- BOE RD 1007/2023 (consolidado): https://www.boe.es/buscar/act.php?id=BOE-A-2023-24840
- BOE Orden HAC/1177/2024: https://www.boe.es/diario_boe/txt.php?id=BOE-A-2024-22138
- BOE RD 1619/2012: https://www.boe.es/buscar/act.php?id=BOE-A-2012-14696
- AEAT Sistemas Informaticos de Facturacion: https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion.html
- AEAT FAQ Productores y comercializadores SIF: https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion/preguntas-frecuentes/productores-comercializadores-sistemas-informaticos-facturacion.html
