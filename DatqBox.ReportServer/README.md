# DatqBox Report Server

Microservicio .NET Framework 4.8 para renderizar reportes Crystal Reports (.rpt) como PDF, Excel o Word.

## Arquitectura

```
[Frontend Web]
   → GET /v1/reportes/catalogo
   → POST /v1/reportes/render  { reporte: "Facturas", parametros: {...} }
      ↓
[API Node.js :4000] ── proxy ──→ [Report Server :5060]
                                       ↓
                                 Crystal Reports Runtime
                                 carga .rpt → conecta SQL Server
                                       ↓
                                 ← PDF / Excel / Word bytes
```

## Requisitos

### 1. .NET Framework 4.8
Ya viene preinstalado en Windows 10/11. Verificar con:
```powershell
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release
# Si el valor >= 528040, tienes .NET Framework 4.8
```

### 2. Crystal Reports Runtime (OBLIGATORIO)
Descargar e instalar el **SAP Crystal Reports Runtime SP37** (o superior):

**Opción A - Runtime completo (recomendado):**
1. Ir a https://origin.softwaredownloads.sap.com/public/site/index.html
2. Buscar: "Crystal Reports, developer version for Microsoft Visual Studio"
3. Descargar: `CR for Visual Studio (SP37) MSI x64`
4. Instalar (requiere reinicio)

**Opción B - Solo runtime (sin Visual Studio):**
1. Buscar: "SAP Crystal Reports runtime engine for .NET framework x64"
2. Descargar: `CRRuntime_64bit_13_0_35.msi`
3. Instalar

### 3. Los archivos de reportes
Los `.rpt` deben estar en la carpeta `Reportes/` junto al ejecutable.
Ya están configurados para copiarse desde `DatqBox.LocalFiscalAgent/Reportes/`.

## Compilar y Ejecutar

```powershell
cd DatqBox.ReportServer

# Restaurar dependencias
dotnet restore

# Compilar
dotnet build

# Ejecutar (puerto 5060 por defecto)
dotnet run

# O con puerto personalizado
dotnet run -- --port 5061
```

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/health` | Estado del servidor y Crystal Runtime |
| GET | `/api/reportes/catalogo` | Lista todos los .rpt disponibles |
| GET | `/api/reportes/parametros?reporte=Facturas` | Inspecciona parámetros de un .rpt |
| POST | `/api/reportes/render` | Genera PDF/Excel/Word |

### Ejemplo: Renderizar Factura como PDF

```bash
curl -X POST http://localhost:5060/api/reportes/render \
  -H "Content-Type: application/json" \
  -d '{
    "reporte": "Facturas",
    "formato": "pdf",
    "parametros": {
      "Desde": "2026-01-01",
      "Hasta": "2026-02-24"
    },
    "server": "127.0.0.1",
    "database": "sasdatqbox",
    "user": "sas_user",
    "password": "ML!gsx90l02"
  }' --output factura.pdf
```

### Ejemplo: Exportar a Excel

```json
{
  "reporte": "Inventario",
  "formato": "excel",
  "parametros": {}
}
```

### Ejemplo: Usar fórmula de selección Crystal

```json
{
  "reporte": "VentasResumen",
  "formato": "pdf",
  "formulaSeleccion": "{Facturas.Fecha} >= #2026-01-01# AND {Facturas.Fecha} <= #2026-02-28#"
}
```

## Desde el Frontend (vía API proxy)

El frontend NO llama directamente al Report Server.  
Usa la API Node.js como proxy (`/v1/reportes/*`):

```typescript
// Abrir reporte en nueva pestaña
const abrirReporte = async (nombre: string, params: Record<string, any>) => {
  const response = await fetch('/v1/reportes/render', {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      reporte: nombre,
      formato: 'pdf',
      parametros: params
    })
  });
  
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  window.open(url, '_blank');
};

// Uso
abrirReporte('Facturas', { Desde: '2026-01-01', Hasta: '2026-02-24' });
```

## Catálogo de Reportes Disponibles (255 archivos)

### Facturación y Ventas
- `Facturas.rpt` - Factura completa
- `factura.rpt` - Formato factura
- `facturaMediaHoja.rpt` - Media hoja
- `factura40col.rpt` - 40 columnas
- `FactReportZ.rpt` - Reporte Z fiscal
- `FactFormaPago.rpt` - Por forma de pago
- `VentasResumen.rpt` - Resumen de ventas
- `VentasVendedores.rpt` - Por vendedor
- `analisventas*.rpt` - Análisis de ventas (múltiples variantes)

### Compras
- `Compras.rpt` - Compras detalladas
- `ComprasResumen.rpt` - Resumen
- `analiscompras*.rpt` - Análisis de compras

### Inventario
- `Inventario.rpt` - Inventario actual
- `MovimientoInventario*.rpt` - Movimientos
- `listaprecio*.rpt` - Listas de precios
- `Etiquetas Barra*.rpt` - Etiquetas con código de barras

### Fiscal / SENIAT
- `libroventasFiscal*.rpt` - Libros de ventas
- `LibrocomprasFiscal.rpt` - Libro de compras
- `Seniat.rpt` - Formato SENIAT
- `retencionISLR.rpt` - Retención ISLR
- `rptCpaRetIvaCom*.rpt` - Retención IVA

### Nómina
- `detallenomina.rpt` - Detalle
- `resumenomina.rpt` - Resumen
- `sabananomina.rpt` - Sábana
- `SobreNomina.rpt` - Sobre de pago

### Bancos
- `Bancos.rpt`, `edoctabanco.rpt` - Estado de cuenta
- `cheque*.rpt` - Formatos de cheques

### CxC / CxP
- `Ctasporcobrar.rpt` - Por cobrar
- `CtasporPagar.rpt` - Por pagar
- `clisaldo*.rpt` - Saldos de clientes

## Notas

- El servidor corre en el puerto **5060** (diferente al agente fiscal que usa 5059)
- Los reportes se conectan a SQL Server usando las credenciales proporcionadas
- Si no se envían credenciales, usa las configuradas en `App.config`
- Crystal Reports soporta sub-reportes automáticamente
- Los `.rpt` originales del sistema VB6 funcionan sin modificación
