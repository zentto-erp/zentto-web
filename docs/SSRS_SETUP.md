# DatqBox SSRS — SQL Server Reporting Services

Tu SQL Server 2012 Enterprise ya tiene SSRS instalado y el servicio `ReportServer` está **Running**.
Sin embargo, las URLs web no están configuradas aún. Sigue estos pasos:

## Paso 1: Configurar SSRS

1. Abre **Reporting Services Configuration Manager**
   - Inicio → buscar "Reporting Services Configuration Manager"
   - Si no aparece, buscar en: `C:\Program Files\Microsoft SQL Server\MSRS11.MSSQLSERVER\Reporting Services\`

2. Conectar a la instancia:
   - Server Name: `DELLXEONE31545`
   - Report Server Instance: `MSSQLSERVER` (default)

3. **Web Service URL** (tab):
   - Virtual Directory: `ReportServer`
   - IP Address: `All Assigned`
   - TCP Port: `80` (o `8080` si el 80 está ocupado)
   - Click **Apply**

4. **Database** (tab):
   - Click **Change Database**
   - Create a new report server database
   - Server: `DELLXEONE31545`
   - Database Name: `ReportServer` (default)
   - Credentials: Service credentials

5. **Report Manager URL** (tab):
   - Virtual Directory: `Reports`
   - Click **Apply**

6. Verificar en el navegador:
   - http://localhost/ReportServer (Web Service)
   - http://localhost/Reports (Portal visual)

## Paso 2: Crear un Reporte de Ejemplo

### Opción A: Report Builder (gratuito, descargable)
1. Desde el portal http://localhost/Reports
2. Click "Report Builder" para descargarlo
3. Diseña visualmente como Crystal Reports

### Opción B: Visual Studio + SQL Server Data Tools
1. Instalar SSDT (SQL Server Data Tools)
2. Crear un proyecto "Report Server Project"
3. Agregar DataSource → SQL Server → DELLXEONE31545/sanjose
4. Crear reportes .rdl con el diseñador visual

## Paso 3: Integración con DatqBox Web

Una vez SSRS esté configurado, puedes renderizar reportes via URL:

```
# Ver reporte en HTML
http://localhost/ReportServer?/MiReporte&Desde=2026-01-01&Hasta=2026-02-28&rs:Format=HTML5.0

# Descargar como PDF
http://localhost/ReportServer?/MiReporte&Desde=2026-01-01&Hasta=2026-02-28&rs:Format=PDF

# Descargar como Excel
http://localhost/ReportServer?/MiReporte&rs:Format=EXCELOPENXML
```

### Formatos disponibles en SSRS (rs:Format=)
| Valor | Formato |
|---|---|
| `PDF` | Adobe PDF |
| `EXCELOPENXML` | Excel 2007+ (.xlsx) |
| `WORDOPENXML` | Word 2007+ (.docx) |
| `HTML5.0` | HTML para web |
| `CSV` | Texto delimitado |
| `IMAGE` | TIFF/PNG |
| `XML` | XML con datos |

## Proxy desde API Node.js

Las rutas ya están configuradas en `/v1/reportes/ssrs/*` (pendiente de activar SSRS).

```
GET /v1/reportes/engines   → Muestra estado de Crystal, jsreport y SSRS
```

## SQL Server 2012 Enterprise + SSRS: Lo que incluye

✅ **Gratis** (ya está incluido en tu licencia Enterprise)
✅ Report Builder (diseñador desktop gratuito)
✅ Subscripciones (enviar reportes por email)
✅ Caché de reportes
✅ Snapshots y histórico
✅ Seguridad por roles
✅ API REST y SOAP
✅ Data-driven subscriptions

## Comparación Final: 3 Motores

| Criterio | Crystal (.NET 4.8) | jsreport (Node.js) | SSRS |
|---|---|---|---|
| **Costo** | Licencia SAP | Gratis (MIT) | Gratis (ya incluido) |
| **Diseñador** | VS Desktop | Web Browser | Report Builder Desktop |
| **Reportes Existentes** | ✅ 244 .rpt | ❌ Rediseñar | ❌ Rediseñar a .rdl |
| **Templates** | .rpt (binario) | HTML (código) | .rdl (XML estándar) |
| **Sub-reportes** | ⭐ Nativo | Manual | ⭐ Nativo |
| **Cross-tabs** | ⭐ Nativo | Manual | ⭐ Nativo (Matrix) |
| **Gráficos** | Limitados | CSS/JS libs | ⭐ Incluidos |
| **Export PDF** | ✅ | ✅ | ✅ |
| **Export Excel** | ✅ | ✅ | ✅ |
| **Scheduler** | ❌ | ✅ (cron) | ⭐ Subscripciones |
| **API REST** | Custom | ✅ Nativa | ✅ Nativa |
| **Rendimiento** | Bueno | ⭐ Excelente | Bueno |
| **Escalabilidad** | 1 instancia | Múltiples workers | Scale-out nativos |
| **Curva aprendizaje** | Baja (ya lo sabes) | Media (HTML) | Media (Report Builder) |
