# Zentto — Presentacion Inversores (Figma Spec)

## Archivo

`investor-deck.json` — 15 slides, 1920x1080, sistema de diseno Zentto.

## Como importar en Figma

### Opcion 1: Plugin "JSON to Figma"

1. Abrir Figma Desktop o Web
2. Crear un nuevo archivo: **Zentto — Presentacion Inversores**
3. Instalar el plugin **JSON to Figma** desde Figma Community
4. Ejecutar el plugin y pegar el contenido de `investor-deck.json`
5. Ajustar posiciones si es necesario

### Opcion 2: Plugin "Figma Tokens" (recomendado para tokens)

1. Instalar **Tokens Studio for Figma** desde Figma Community
2. Importar la seccion `tokens` del JSON como design tokens
3. Crear los frames manualmente siguiendo la spec de cada slide

### Opcion 3: Replicacion manual

Cada slide tiene:
- `name`: nombre del frame
- `background`: color o gradiente de fondo
- `children[]`: array de elementos con coordenadas absolutas (x, y, width, height)
- Tipos de elementos: `text`, `rect`, `ellipse`, `line`, `group`

## Estructura de cada slide

```
{
  "id": "slide-1",
  "name": "Slide 1 — Cover",
  "width": 1920,
  "height": 1080,
  "background": { ... },
  "children": [
    { "type": "text", "x": 960, "y": 400, "text": "Zentto", ... },
    { "type": "rect", "x": 0, "y": 0, "width": 1920, ... },
    ...
  ]
}
```

## Orden de slides

| # | Nombre | Fondo |
|---|--------|-------|
| 1 | Cover | Oscuro (gradiente) |
| 2 | Problema | Blanco |
| 3 | Solucion | Blanco |
| 4 | Producto | Gris suave |
| 5 | Arquitectura | Oscuro (#131921) |
| 6 | Mercado | Blanco |
| 7 | Modelo de Negocio | Blanco |
| 8 | Traccion | Blanco |
| 9 | Competencia | Gris (#f8f8f8) |
| 10 | Tecnologia | Oscuro (#232f3e) |
| 11 | Go-to-Market | Blanco |
| 12 | Equipo | Blanco |
| 13 | Financieros | Blanco |
| 14 | The Ask | Oscuro (gradiente) |
| 15 | Gracias | Oscuro (#131921) |

## Tokens de diseno

- **Font**: Inter (Google Fonts)
- **Primary**: #ff9900 (naranja Zentto)
- **Secondary**: #232f3e (navy oscuro)
- **Tertiary**: #007185 (teal)
- Ver seccion `tokens` del JSON para la paleta completa
