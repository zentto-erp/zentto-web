# UI AutoSize Strategy (.NET)

## Objetivo
Evitar el problema clasico VB6 de formularios pequenos en resoluciones grandes.

## Implementado
1. DPI moderno global:
   - `HighDpiMode.PerMonitorV2` en `Program.vb`.
2. Shell principal adaptable:
   - Panel izquierdo y derecho ajustan ancho segun resolucion, con limites min/max.
3. Formulario de consultas responsive:
   - Barra de filtros en `TableLayoutPanel`.
   - Grid en `Dock=Fill` y columnas en `AutoSizeColumnsMode.Fill`.
4. Helper legacy para formularios migrados:
   - `LegacyFormAutoScaler` para escalado proporcional de controles absolutos.

## Uso recomendado al migrar cada formulario VB6
1. Preferir `Dock/Anchor/TableLayoutPanel`.
2. Activar `AutoScaleMode = Dpi`.
3. Si el formulario es muy legacy/absoluto, usar:

```vb
Private _autoScale As LegacyFormAutoScaler

Protected Overrides Sub OnLoad(e As EventArgs)
    MyBase.OnLoad(e)
    _autoScale = LegacyFormAutoScaler.Attach(Me)
End Sub
```
