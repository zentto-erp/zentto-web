# AddOn Framework (Base inicial)

## Objetivo
Esta base permite un modelo tipo SAP B1:
- Cada control UI principal tiene `ReferenceId` numerico.
- DLLs externas pueden cargar en runtime (`addons\*.dll`).
- DLLs externas pueden agregar botones y campos UDF visuales.

## Referencias UI core
Archivo: `src/DatqBox.Admin.Desktop/Extensibility/CoreUiRefIds.vb`

Ejemplos:
- `1000` -> Form principal
- `1600` -> Boton validar conexion
- `1800` -> Host CommandBars
- `1801` -> Host TrueDBGrid
- `30000+` -> Base para UDF

En la app se puede activar `Ver Referencias` para mostrar tooltip:
`Ref <numero> | <clave>`

## API para AddOns
Interfaces:
- `IAddonModule`
- `IAddonContext`

Contrato minimo de un add-on:

```vb
Public Class MiAddon
    Implements IAddonModule

    Public ReadOnly Property Id As String Implements IAddonModule.Id
        Get
            Return "com.datqbox.demo"
        End Get
    End Property

    Public ReadOnly Property Name As String Implements IAddonModule.Name
        Get
            Return "Addon Demo"
        End Get
    End Property

    Public Sub Initialize(context As IAddonContext) Implements IAddonModule.Initialize
        context.AddActionButton(New AddonButtonRequest With {
            .ReferenceId = 21000,
            .Caption = "Boton Demo AddOn",
            .Action = Sub() context.SetStatus("Accion demo ejecutada")
        })

        context.RegisterUdf(New UdfDefinition With {
            .ReferenceId = 31000,
            .TableName = "CLIENTES",
            .FieldName = "UDF_DEMO",
            .Caption = "Campo Demo",
            .DataType = UdfDataType.Text,
            .DefaultValue = ""
        })
    End Sub
End Class
```

## Despliegue de AddOns
1. Compilar DLL referenciando `DatqBox.Admin.Desktop.dll`.
2. Copiar DLL en:
   - `<output>\addons\`
3. Iniciar app.

## Estado actual
- Carga dinamica de DLLs: implementada.
- Registro de IDs UI: implementado.
- Render visual de UDF: implementado (panel derecho).
- Persistencia DB de UDF/UDT: pendiente (siguiente fase).
