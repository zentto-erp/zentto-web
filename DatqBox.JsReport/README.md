# DatqBox jsreport Server

Motor de reportes **open source** basado en Node.js con diseñador visual web.

## Inicio Rápido

```powershell
cd DatqBox.JsReport
npm install        # Ya instalado
node server.js     # Inicia en puerto 5070
```

## Studio Visual (Diseñador Web)

Abre **http://localhost:5070** en tu navegador para acceder al diseñador visual.

Aquí puedes:
- Crear/editar templates con HTML + Handlebars
- Preview en tiempo real
- Exportar a PDF, Excel, Word, PowerPoint
- Usar scripts para cargar datos desde SQL Server
- Versionar templates

## Ejemplo: Crear un Reporte de Inventario

### 1. En el Studio, crea un nuevo Template:
- Click **+** → **Template**
- Nombre: `inventario`
- Engine: **Handlebars**
- Recipe: **chrome-pdf**

### 2. En el tab "Content", pega el HTML del reporte
(usa `data/inventario/content.html` como ejemplo)

### 3. En el tab "Script", crea un Script helper:
- Click **+** → **Script**
- Pega el contenido de `data/inventario/helpers.js`
- Asócialo al template

### 4. Click **Run** para generar el PDF

## API de Renderizado

```bash
# Renderizar un template guardado
curl -X POST http://localhost:5070/api/report \
  -H "Content-Type: application/json" \
  -d '{"template": {"name": "inventario"}}' \
  --output inventario.pdf

# Renderizar con datos custom
curl -X POST http://localhost:5070/api/report \
  -H "Content-Type: application/json" \
  -d '{
    "template": {"name": "ventas-resumen"},
    "data": {"desde": "2026-01-01", "hasta": "2026-02-24"}
  }' --output ventas.pdf

# Renderizar template inline (sin guardar)
curl -X POST http://localhost:5070/api/report \
  -H "Content-Type: application/json" \
  -d '{
    "template": {
      "content": "<h1>Hola {{nombre}}</h1>",
      "engine": "handlebars",
      "recipe": "chrome-pdf"
    },
    "data": {"nombre": "DatqBox"}
  }' --output test.pdf
```

## Via API Node.js (proxy)

```
POST /v1/reportes/jsreport/render
{
  "template": "inventario",
  "data": { ... }
}
```

## Recipes Disponibles (formatos de salida)

| Recipe | Formato | Uso |
|---|---|---|
| `chrome-pdf` | PDF | Reportes, facturas, listados |
| `html-to-xlsx` | Excel | Exportación de datos tabulares |
| `xlsx` | Excel avanzado | Hojas complejas con fórmulas |
| `docx` | Word | Documentos con plantilla .docx |
| `pptx` | PowerPoint | Presentaciones |
| `html` | HTML | Vista web directa |
| `text` | Texto plano | Tickets, recibos |

## Comparación con Crystal Reports

| Aspecto | Crystal Reports | jsreport |
|---|---|---|
| **Diseñador** | Desktop (Visual Studio) | Web (navegador) ⭐ |
| **Costo** | Licencia SAP | **Gratis** (MIT) ⭐ |
| **Templates** | Binarios .rpt | HTML + Handlebars ⭐ |
| **Sub-reportes** | Nativo ⭐ | Via child-templates |
| **Cross-tabs** | Nativo ⭐ | Manual con HTML |
| **Agrupaciones** | Drag & Drop ⭐ | {{#each}} + CSS |
| **Fórmulas** | Crystal Formula | JavaScript ⭐ |
| **Exportación** | PDF/XLS/DOC | PDF/XLS/DOC/PPTX ⭐ |
| **Rendimiento** | Bueno | Excelente ⭐ |
| **Versionado** | No | Git nativo ⭐ |
| **API REST** | Custom | Incluida ⭐ |

## Archivos

```
DatqBox.JsReport/
├── server.js                       # Servidor principal
├── package.json                    # Dependencias
├── data/                           # Templates (auto-detectados por jsreport)
│   ├── inventario/
│   │   ├── content.html           # Template HTML del reporte
│   │   └── helpers.js             # Script de datos SQL Server
│   └── ventas-resumen/
│       └── content.html           # Template ventas
└── README.md
```
