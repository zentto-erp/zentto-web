Lee la memoria del proyecto y las reglas críticas antes de empezar cualquier tarea.

## Paso 1 — Leer índice de memoria

Lee el archivo: `C:\Users\Dell\.claude\projects\d--DatqBoxWorkspace-DatqBoxWeb\memory\MEMORY.md`

## Paso 2 — Leer archivos relevantes a la tarea

Por cada entrada del índice que sea relevante a lo que se va a hacer, lee el archivo de detalle correspondiente. Presta especial atención a los archivos que empiezan con `feedback_` — son correcciones de comportamientos pasados que NO deben repetirse.

## Paso 3 — Verificar checklist antes de escribir código

Antes de tocar un solo archivo, confirma mentalmente:

- [ ] ¿El trabajo va en una rama desde `developer`? (NUNCA desde `main`, NUNCA directo en `developer`)
- [ ] ¿El PR va a `developer`? (no a `main`)
- [ ] ¿El commit NO lleva `Co-Authored-By: Claude`?
- [ ] Si hay cambio de BD: ¿va migración goose + sqlweb-pg + sqlweb (ambos motores)?
- [ ] Si hay tabla de datos en UI: ¿usa `<ZenttoDataGrid>` (no `<table>` HTML)?
- [ ] Si hay catálogos/listas en frontend: ¿vienen de API (no hardcodeados)?
- [ ] Si hay cambio de módulo: ¿se actualiza `zentto-erp-docs`?

## Paso 4 — Confirmar plan con el usuario si la tarea es compleja

Si la tarea afecta más de 3 archivos o toca infraestructura (CI/CD, BD, nginx), describe el plan brevemente antes de ejecutar.

---

Ahora describe la tarea que vas a realizar: $ARGUMENTS
