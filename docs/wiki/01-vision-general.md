# 01 - Visión General

## Contexto del producto

DatqBox es un ERP en modernización desde VB6 hacia arquitectura moderna con:

- Escritorio .NET (`src/*Desktop`) para continuidad operativa
- Web stack (`web/api`, `web/frontend`) para evolución funcional
- Modular frontend (`web/modular-frontend`) para escalamiento por dominio

## Estructura principal relevante

- `src/`: capas .NET (Domain, Application, Infrastructure, Desktop)
- `web/api`: backend Express + TypeScript
- `web/frontend`: app Next.js actual
- `web/modular-frontend`: monorepo de módulos (shell + packages)
- `docs/legacy-inventory`: inventario real de formularios/módulos VB6

## Estrategia de migración activa

Según `docs/MIGRATION_PLAN.md`:

1. Inventario legacy por proyecto
2. Extracción de lógica y SQL fuera de formularios
3. Implementación de casos de uso prioritarios
4. Migración de UI crítica
5. Pruebas de regresión por módulo

## Convenciones operativas

- API versionada en `/v1/*`.
- Frontend consume contrato estable y hooks por módulo.
- Modular frontend no rompe al frontend actual; coexisten.
