# DatqBoxWeb

Repositorio raíz de la migración web de DatQBox.

## Proyectos principales

Este workspace tiene **3 proyectos web** activos:

1. **API**: `web/api`  
   - Nombre de paquete: `datqbox-api`  
   - Stack: Node.js + Express + TypeScript

2. **Frontend clásico**: `web/frontend`  
   - Nombre de paquete: `datqbox-frontend`  
   - Stack: Next.js + React + MUI

3. **Frontend modular**: `web/modular-frontend`  
   - Nombre de paquete: `datqbox-modular-frontend`  
   - Stack: monorepo npm workspaces (`apps/*`, `packages/*`)

## .gitignore por proyecto

Para evitar subir dependencias y artefactos, están definidos:

- `web/api/.gitignore`
- `web/frontend/.gitignore`
- `web/modular-frontend/.gitignore`

Adicionalmente existe un `.gitignore` raíz en este repo para reglas globales.

## Cómo ejecutar

### API

```bash
cd web/api
npm install
npm run dev
```

### Frontend clásico

```bash
cd web/frontend
npm install
npm run dev
```

### Frontend modular

```bash
cd web/modular-frontend
npm install
npm run dev:shell
```

## Documentación recomendada

- `docs/wiki/README.md`
- `docs/wiki/02-api.md`
- `docs/wiki/03-frontend.md`
- `docs/wiki/04-modular-frontend.md`
- `docs/wiki/05-mapa-vb6-a-web.md`

## Nota operativa

`main` queda como rama estable y `develop` como rama de trabajo continuo para nuevos cambios.
