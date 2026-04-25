Arranca una tarea nueva en Zentto con todo el setup: estado actual sincronizado, memoria del proyecto cargada, reglas críticas verificadas, toolset zb listo.

## Paso 1 — Sincronizar estado actual con `zb resume`

Ejecuta primero:

```bash
bash ~/.claude/scripts/zentto/zb resume
```

Eso devuelve en un solo bloque: working tree, sesiones activas (incluyendo otras terminales concurrentes en este proyecto si las hay), commits hechos recientemente, archivos tocados en últimas 4h, TODOs/WIPs en archivos activos, último intercambio de Claude Code en este proyecto, y último checkpoint manual. Léelo antes de actuar — el welcome del SessionStart pudo quedar obsoleto.

## Paso 2 — Leer índice de memoria del proyecto

Lee:

```
~/.claude/projects/d--DatqBoxWorkspace-DatqBoxWeb/memory/MEMORY.md
```

Por cada entrada relevante a la tarea, lee el archivo de detalle. Presta especial atención a `feedback_*.md` — son correcciones de comportamientos pasados que NO deben repetirse.

## Paso 3 — Verificar checklist antes de escribir código

- [ ] ¿El trabajo va en una rama desde `developer`? (NUNCA desde `main`, NUNCA directo en `developer`)
- [ ] ¿El PR va a `developer`? (no a `main`)
- [ ] ¿El commit NO lleva `Co-Authored-By: Claude`?
- [ ] Si hay cambio de BD: ¿va migración goose + sqlweb-pg + sqlweb (ambos motores)?
- [ ] Si hay tabla de datos en UI: ¿usa `<ZenttoDataGrid>` (no `<table>` HTML)?
- [ ] Si hay catálogos/listas en frontend: ¿vienen de API (no hardcodeados)?
- [ ] Si hay cambio de módulo: ¿se actualiza `zentto-erp-docs`?

## Paso 4 — Antes de leer archivos > 500 líneas o navegar cross-repo

Usa el symbol index zb en lugar de Read masivo:

```bash
bash ~/.claude/scripts/zentto/zb find <símbolo>     # buscar en este repo (índice ya construido)
bash ~/.claude/scripts/zentto/zb impact <símbolo>   # buscar en los 39 repos del workspace
```

Para outputs que pueden ser grandes (logs, queries verbose, builds completos):

```bash
bash ~/.claude/scripts/zentto/zb capture <cmd...>   # devuelve handle + head + tail
bash ~/.claude/scripts/zentto/zb show <handle>      # ver completo
bash ~/.claude/scripts/zentto/zb grep <handle> <regex>  # buscar dentro
```

Para comandos git/gh/docker/npm/goose con output verboso, usa los wrappers comprimidos:

```bash
bash ~/.claude/scripts/zentto/zb git-diff
bash ~/.claude/scripts/zentto/zb git-log [N]
bash ~/.claude/scripts/zentto/zb git-status
bash ~/.claude/scripts/zentto/zb pr-checks [pr]
bash ~/.claude/scripts/zentto/zb docker-logs <ctr>
bash ~/.claude/scripts/zentto/zb npm-install
bash ~/.claude/scripts/zentto/zb goose-status
```

## Paso 5 — Confirmar plan si la tarea es compleja

Si la tarea afecta más de 3 archivos o toca infraestructura (CI/CD, BD, nginx), describe el plan brevemente antes de ejecutar.

## Paso 6 — Al cerrar la tarea

Guarda checkpoint para que cualquier modelo (Claude/Codex/Gemini/Cursor/Antigravity/Windsurf) pueda retomar sin pérdida:

```bash
bash ~/.claude/scripts/zentto/zb session-save "qué hice, dónde quedó, qué falta"
```

---

Ahora describe la tarea que vas a realizar: $ARGUMENTS
