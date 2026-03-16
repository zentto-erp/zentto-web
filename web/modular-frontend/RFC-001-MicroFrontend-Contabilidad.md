# ADR 001: Migración a Micro-Frontends (Múltiples Apps Next.js) - Caso: Contabilidad

## 1. Visión General de la Decisión Architectural (ADR)

**Estado Actual:** `apps/shell` actúa como un monolito modular. Las rutas de contabilidad (`/contabilidad/...`) se renderizan dentro de la aplicación principal que corre en un solo servidor de Next.js (Puerto 3000). Componentes lógicos y visuales residen en `packages/module-contabilidad`.
**Problema:** A medida que el ecosistema crece, cualquier cambio en Contabilidad requiere recompilar todo el portal de Zentto, incluyendo Nómina, Bancos, etc. Equipos humanos o agentes de IA colisionan en un solo proyecto, afectando los tiempos de despliegue y estabilidad.
**Decisión:** Convertir `Contabilidad` en su propio servidor Next.js totalmente aislado bajo la estrategia **Next.js Multi-Zones** (o Reverse Proxy). 

## 2. Estructura de Carpetas Físicas Propuestas

La nueva estructura separará dominios operativos:

```text
web/modular-frontend/
├── apps/
│   ├── shell/                (Puerto 3000) -> Portal, App Selector y Reverse Proxy
│   └── contabilidad/         (Puerto 3001) -> NUEVA APP RECIPIENTE
│       ├── src/app/          (Rutas propias /contabilidad/*)
│       └── package.json      (Dependencias exclusivas de contabilidad)
├── packages/
│   ├── shared-ui/            (Sigue existiendo, alimenta a ambas apps)
│   ├── shared-auth/          (Core de sesión)
│   ├── shared-api/           (Hooks genéricos)
│   └── module-contabilidad/  -> [A DEPRECAR] Su código se migrará directamente a apps/contabilidad/src/
```

## 3. Red y Puertos (Next.js Multi-Zones / Rewrites)

El `Shell` se convierte en un enrutador inteligente. Para el usuario final, no cambia la URL. Sigue viendo `zentto.local/contabilidad`.

**Configuración en `apps/shell/next.config.mjs`:**
```javascript
export default {
  async rewrites() {
    return [
      {
        source: '/contabilidad',
        destination: `http://localhost:3001/contabilidad`,
      },
      {
        source: '/contabilidad/:path*',
        destination: `http://localhost:3001/contabilidad/:path*`,
      },
    ]
  },
}
```

**Configuración en `apps/contabilidad/next.config.mjs`:**
```javascript
export default {
  basePath: '/contabilidad', // Obligatorio para aislar los estáticos de esta app
}
```

## 4. Compartición de Sesión (Auth)

**Reto:** El usuario se loguea en el puerto 3000 (Shell) pero viaja al puerto 3001 (Contabilidad).
**Solución:** Al estar bajo el mismo dominio base en producción (Ej. `.zentto.com`) o `localhost` en desarrollo, la cookie de NextAuth (`next-auth.session-token`) es válida en ambas si comparten la misma firma de secreto (`NEXTAUTH_SECRET`). Ambas aplicaciones invocarán `useAuth()` desde `@zentto/shared-auth`, y este extraerá la sesión mágica centralizada del navegador. Ninguna app de negocio (Contabilidad) tendrá página de login propia; si no hay sesión, devuelven error o redirigen al Shell.

## 5. Pros y Contras de esta Decisión

### Pros
* **Supervivencia (Zero Downtime):** Si hay un error fatal compilando un reporte de Asientos Contables, solo muere el puerto 3001. El POS y Ventas (puerto 3000 u otro) siguen activos al 100%.
* **Velocidad de IAs/Equipos:** Cualquier agente IA o developer que toques, solo leerá el repo `apps/contabilidad` y no se mezclará con otras rutas, ahorrando memoria y contexto.
* **Escalabilidad Pura:** Podemos hostear Contabilidad en un servidor con el doble de memoria RAM si requiere procesar mucha data, mientras el Shell se queda en uno modesto.

### Contras
* **Complejidad de Servidores Locales:** Para desarrollar visualizando todo, el programador tendrá que correr 2 comandos simultáneos (`npm run dev:shell` y `npm run dev:contabilidad`), o usar Turborepo (`npm run dev` en root) para iniciar múltiples puertos.
* **Redundancia de Estáticos Base:** React y Material UI se "compilan" doble vez a nivel servidor, aunque el navegador los puede almacenar en caché.

## 6. Checklist de Implementación para el 'Super Developer'

- [ ] 1. Crear la plantilla básica de frontend (`npx create-next-app` o copia limpia manual) dentro de `apps/contabilidad`.
- [ ] 2. Ajustar `apps/contabilidad/package.json` para heredar los local packages (`@zentto/shared-ui`, `@zentto/shared-auth`).
- [ ] 3. Configurar su `next.config.mjs` con `basePath: '/contabilidad'`.
- [ ] 4. Escribir el Layout raíz de `apps/contabilidad` para que monte y lea el `<OdooLayout>` usando los menús de Contabilidad aislados.
- [ ] 5. Mapear en `apps/shell/next.config.mjs` los `rewrites` hacia `http://localhost:3001`.
- [ ] 6. Migrar físicamente los componentes funcionales desde `packages/module-contabilidad` hacia dentro de la nueva `apps/contabilidad/src/`.
- [ ] 7. Borrar de `apps/shell` las rutas duras relativas a contabilidad para que el proxy re-write entre en acción limpiamente.
