# UI Compatibility (VB6 -> .NET)

## Controles legacy detectados en `DatQBoxAdmin.vbp`
- `Codejock.SkinFramework.v15.3.1.ocx`
- `Codejock.CommandBars.v15.3.1.ocx`
- `truedc8.ocx` (True DBGrid)

## Estado en este equipo
- Ruta Codejock ActiveX detectada:
  - `C:\Program Files (x86)\Codejock Software\ActiveX\Xtreme SuitePro ActiveX v15.3.1\Bin`
- OCX detectados:
  - `Codejock.CommandBars.v15.3.1.ocx`
  - `Codejock.SkinFramework.v15.3.1.ocx`
- TrueDBGrid detectado:
  - `C:\Windows\SysWOW64\truedc8.ocx`
  - `C:\Windows\SysWOW64\todg8.ocx`

## Estrategia de migracion visual
1. Mantener comportamiento: migrar primero sin rediseño.
2. Reusar controles legacy via COM Host en WinForms donde aplique.
3. Si un formulario depende totalmente de grid/menu legacy, migrarlo con wrapper COM en primera fase.
4. En segunda fase, evaluar reemplazo gradual a controles .NET nativos o equivalentes comerciales.

## Nota importante
Aunque exista soporte .NET en la familia Codejock/TrueDBGrid, el codigo VB6 no es "copiar/pegar" directo:
- Cambian eventos, ciclo de vida de controles y binding.
- Se requiere capa adaptadora por formulario para minimizar riesgo.
