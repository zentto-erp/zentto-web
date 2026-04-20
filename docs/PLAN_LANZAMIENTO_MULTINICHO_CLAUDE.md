# Zentto — Plan de Lanzamiento Multinicho sin Reducir Alcance

**Versión:** 1.0  
**Autor:** Codex  
**Fecha:** 2026-04-20  
**Estado:** PLAN EJECUTABLE PARA CLAUDE

---

## Visión

Zentto **no va a reducir su oferta** antes de salir al mercado.

La estrategia es:

1. **Preservar todo el código y capacidades ya construidas**
2. **Empaquetar la amplitud actual como ofertas comerciales claras**
3. **Blindar operación, calidad y onboarding** para soportar varios nichos sin colapso operativo
4. **Usar la misma plataforma** (`web/api` + `web/modular-frontend` + servicios del ecosistema) como base para todos los nichos

**Frase guía:**  
*"No recortamos alcance; convertimos el alcance actual en una plataforma vendible, operable y repetible."*

---

## Objetivo del plan

Preparar Zentto para salir al mercado con:

- múltiples nichos
- múltiples paquetes comerciales
- una sola plataforma técnica
- sin perder código existente
- con ejecución coordinada por agentes Claude/Codex

---

## Principios no negociables

1. **No eliminar módulos ya construidos** salvo que haya duplicados obvios y se acuerde explícitamente.
2. **No reducir el portafolio comercial**; sí ordenar cómo se presenta y activa.
3. **No romper la plataforma actual** por perseguir mejoras cosméticas o cambios de framework.
4. **Usar el pipeline oficial de agentes**:
   - tarea
   - Planner
   - Developer
   - Disena
   - SQL Specialist
   - QA
5. **Todo cambio de datos o catálogo** debe respetar contratos API y dual DB cuando aplique.

---

## Base actual que se reaprovecha

### Plataforma

- API central Express + TypeScript: `web/api`
- Frontend modular multi-app: `web/modular-frontend`
- Contratos OpenAPI: `web/contracts/openapi.yaml`
- Infraestructura actual: Hetzner + Nginx + Docker + PM2

### Capacidades ya aprovechables para salida comercial

- Pricing y catálogo: `web/api/src/modules/pricing/`, `web/api/src/modules/catalog/`
- Licencias: `web/api/src/modules/license/`
- Suscripciones y entitlements: `web/api/src/modules/subscriptions/`
- Captura de leads: `web/api/src/modules/landing/`
- Integración de ecosistema: `docs/wiki/14-integracion-ecosistema.md`
- Health y observabilidad base: `web/api/src/modules/health/`, `web/api/src/middleware/observability.ts`

### Lo que este plan NO hace

- No migra de Next.js a otro framework
- No elimina verticales o módulos
- No reescribe la arquitectura central

---

## Resultado esperado al final

Al cerrar este plan, Zentto debe tener:

1. **Catálogo comercial multinicho oficial**
2. **Paquetes y addons definidos sobre la plataforma actual**
3. **Flujos críticos E2E automatizados**
4. **Onboarding repetible por nicho**
5. **Observabilidad operativa por tenant y producto**
6. **Checklist GO/NO-GO de lanzamiento**

---

## Streams de trabajo

### Stream A — Empaquetado comercial sin perder amplitud

Convierte módulos y verticales existentes en una matriz clara de venta:

- nicho
- producto de entrada
- módulos incluidos
- addons
- plan/precio
- complejidad de onboarding
- dependencia técnica

### Stream B — Certificación operativa de la plataforma

Endurece:

- release
- rollback
- backups
- restore
- health checks
- observabilidad
- soporte inicial

### Stream C — Flujos críticos del negocio

Garantiza que las rutas de mayor valor funcionen de punta a punta:

- login
- alta de tenant
- selección/consulta de plan
- clientes
- artículos
- factura
- pago
- logout

### Stream D — Onboarding por nicho

Formaliza cómo activar clientes de distintos nichos usando la misma plataforma:

- ERP general
- POS
- Restaurante
- Ecommerce
- CRM
- Contabilidad

### Stream E — Performance percibida y UX de confianza

Sin reescribir framework:

- menos waterfalls
- menos esperas silenciosas
- mejores estados vacíos
- mejores loading states
- mejor primera experiencia en demo y onboarding

---

## Fases

## Fase 1 — Matriz Comercial Multinicho

**Objetivo:** vender amplitud con orden, sin reducir portafolio.

### Entregables

- Documento maestro `Oferta x Nicho x Módulos x Addons x Onboarding`
- Taxonomía oficial:
  - `core`
  - `bundle`
  - `addon`
  - `enterprise`
- Relación entre catálogo técnico y oferta comercial
- Propuesta de páginas/landings por nicho

### Salida mínima

- tabla con 8-12 ofertas iniciales
- criterio de activación por paquete
- qué es venta de entrada vs upsell

### Riesgo que reduce

- vender “todo” pero sin claridad
- demos caóticas
- promesas comerciales difíciles de operar

---

## Fase 2 — Certificación de Salida

**Objetivo:** que la plataforma actual aguante los primeros clientes sin improvisación.

### Entregables

- checklist de release
- checklist de rollback
- checklist de backup/restore
- checklist de health operativo
- política de severidades y soporte inicial
- tablero mínimo de operación

### Salida mínima

- runbook único de despliegue y contingencia
- tablero por tenant/app con errores, latencia y jobs fallidos
- definición de responsables

### Riesgo que reduce

- incidentes sin respuesta clara
- soporte reactivo
- salida al mercado sin control operativo

---

## Fase 3 — Flujos E2E Críticos

**Objetivo:** cubrir negocio real, no solo endpoints.

### Flujos mínimos sugeridos

1. Login exitoso
2. Login fallido controlado
3. Registro / activación inicial
4. Visualización de pricing o catálogo
5. Alta de cliente
6. Alta de artículo
7. Creación de factura
8. Registro de pago
9. Consulta de inventario
10. Logout limpio

### Entregables

- suite E2E mínima priorizada
- evidencia reproducible
- matriz de cobertura por flujo

### Riesgo que reduce

- bugs inter-app
- fallas de sesión
- regresiones funcionales invisibles desde API

---

## Fase 4 — Onboarding Repetible por Nicho

**Objetivo:** soportar varios nichos usando el mismo código base.

### Entregables

- playbook por nicho
- datos semilla mínimos
- checklist de configuración inicial
- demo sugerida por vertical

### Nichos iniciales sugeridos

- ERP general
- POS
- Restaurante
- Ecommerce
- CRM
- Contabilidad

### Riesgo que reduce

- cada venta parece un proyecto distinto
- implementación manual excesiva
- activación lenta del cliente

---

## Fase 5 — Performance Percibida y Experiencia

**Objetivo:** que el producto se sienta listo sin reescribir la arquitectura.

### Entregables

- lista de 10 pantallas críticas
- top 20 mejoras UX/performance
- corrección de loading states, vacíos y errores
- reducción de fricción en demo y onboarding

### Riesgo que reduce

- percepción de lentitud
- pérdida de confianza comercial
- abandono temprano en pruebas/demo

---

## Dependencias recomendadas

### Lectura obligatoria para cualquier agente

1. `docs/wiki/README.md`
2. `docs/wiki/02-api.md`
3. `docs/wiki/03-frontend.md`
4. `docs/wiki/04-modular-frontend.md`
5. `docs/wiki/06-playbook-agentes.md`
6. `docs/wiki/07-compatibilidad-multi-ia.md`

### Fuentes de contexto clave

- `docs/wiki/12-infraestructura.md`
- `docs/wiki/14-integracion-ecosistema.md`
- `docs/adr/ADR-CMS-001-ecosystem-cms.md`
- `web/api/src/app.ts`
- `web/modular-frontend/package.json`

---

## Criterios GO/NO-GO

## GO mínimo

- existe matriz comercial multinicho aprobada
- hay checklist operativo de release/rollback
- los flujos E2E críticos corren o tienen evidencia manual controlada
- el onboarding por nicho está definido para al menos 4 ofertas iniciales
- existe tablero mínimo de observabilidad

## NO-GO

- no está claro qué se vende y qué activa cada plan
- la sesión entre apps es inestable
- no existe restore probado
- no hay forma de detectar fallas por tenant/módulo
- la demo comercial depende de pasos manuales no documentados

---

## Resumen para Agentes

Este plan se ejecuta en 5 frentes paralelos:

1. **Planner:** convierte amplitud técnica en oferta comercial operable
2. **Developer:** implementa gaps concretos en catálogo, onboarding, UX, dashboards y pruebas
3. **SQL Specialist:** valida cualquier cambio en catálogo, licencias, pricing o onboarding persistido
4. **QA:** certifica flujos reales de salida a mercado

**Nota crítica:** este plan **no busca recortar** ni “simplificar” el producto quitando cosas. Busca **ordenar, empaquetar, validar y operar** lo ya construido.

---

## Prompt listo para Claude — Coordinador Principal

```md
Actúa como coordinador principal de ejecución del plan `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`.

Reglas:
- No reduzcas el alcance comercial de Zentto.
- No propongas eliminar módulos ya construidos.
- Trabaja sobre la plataforma actual.
- Usa el pipeline: Planner -> Developer -> SQL Specialist -> QA.
- Lee primero:
  1. docs/wiki/README.md
  2. docs/wiki/02-api.md
  3. docs/wiki/03-frontend.md
  4. docs/wiki/04-modular-frontend.md
  5. docs/wiki/06-playbook-agentes.md
  6. docs/wiki/07-compatibilidad-multi-ia.md

Objetivo:
- Ejecutar el plan por fases.
- Entregar progreso por stream.
- Mantener trazabilidad de decisiones.
- Producir salidas concretas, no solo análisis.

Formato de salida por iteración:
- Resumen
- Stream/Fase trabajada
- Archivos tocados
- Riesgos abiertos
- Validación
- Siguiente acción recomendada
```

---

## Prompt listo para Claude — Super Planner

```md
Ejecuta el rol de Planner sobre `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`.

Necesito:
- descomponer el plan en tareas ejecutables
- identificar dependencias
- proponer secuencia por fases
- definir criterios de aceptación por entregable
- listar archivos y módulos impactados

Restricciones:
- no reducir portafolio
- no eliminar código existente
- reutilizar catálogo, licencias, pricing, subscriptions, landing y observabilidad ya existentes

Entrega:
- backlog priorizado
- fases
- dependencias
- riesgos
- quick wins
- definición de GO/NO-GO por fase
```

---

## Prompt listo para Claude — Super Developer

```md
Ejecuta el rol de Developer sobre `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`.

Objetivo:
- implementar únicamente los gaps concretos del plan
- preservar la plataforma actual
- no introducir refactors amplios innecesarios

Prioridades:
1. matriz comercial soportada por catálogo/licencias actuales
2. onboarding por nicho
3. observabilidad mínima
4. flujos E2E críticos
5. performance percibida en pantallas clave

Reglas:
- cambios pequeños y verificables
- contratos antes que UI si aplica
- si toca DB, coordinar con SQL Specialist
- no romper compatibilidad entre apps

Formato final:
- resumen
- archivos tocados
- validación
- riesgos
- mensaje de commit sugerido
```

---

## Prompt listo para Claude — SQL Specialist

```md
Ejecuta el rol de SQL Specialist sobre `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`.

Tu tarea:
- validar impacto SQL en pricing, catálogo, licencias, onboarding o nuevos tableros
- asegurar paridad entre PostgreSQL y SQL Server
- revisar contratos SP y migraciones si se agrega persistencia nueva

Checklist obligatorio:
- cambio en PostgreSQL
- cambio equivalente en SQL Server
- contratos o tests actualizados
- validación de ambos motores

Formato de salida:
- resumen
- objetos BD afectados
- motores afectados
- riesgos
- validación
- siguiente acción
```

---

## Prompt listo para Claude — Super QA

```md
Ejecuta el rol de QA sobre `docs/PLAN_LANZAMIENTO_MULTINICHO_CLAUDE.md`.

Objetivo:
- emitir GO/NO-GO sobre preparación de salida a mercado
- enfocarte en flujos reales, no solo pruebas unitarias

Validar:
- login
- pricing/catalog
- onboarding inicial
- alta de cliente
- alta de artículo
- factura
- pago
- logout
- errores visibles y recuperables
- observabilidad mínima disponible

Formato de salida:
- hallazgos primero
- severidad
- evidencia
- riesgos
- decisión GO/NO-GO
```

---

## Orden sugerido de ejecución para Claude

1. Ejecutar `Super Planner`
2. Abrir issues/tareas por stream
3. Ejecutar `Super Developer` por bloques pequeños
4. Ejecutar `SQL Specialist` cuando haya persistencia nueva o cambio de catálogo/licencias
5. Ejecutar `Super QA` al cierre de cada bloque

---

## Primer lote de ejecución recomendado

### Lote 1

- matriz comercial multinicho
- definición de bundles y addons
- alineación con pricing/catalog/licensing existentes

### Lote 2

- onboarding por nicho
- checklist de activación
- datos semilla mínimos

### Lote 3

- E2E de flujos críticos
- observabilidad operativa mínima

### Lote 4

- mejoras de UX/performance en rutas clave de demo y activación

---

## Cierre esperado

Si este plan se ejecuta bien, Zentto llega al mercado como:

- una plataforma amplia
- con varios nichos vendibles
- sin perder código
- sin reescribir la base técnica
- con suficiente orden comercial y operativo para escalar

No se trata de tener menos producto.  
Se trata de que **todo lo que ya existe empiece a comportarse como un portafolio serio y ejecutable**.
