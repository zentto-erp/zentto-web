# INI Encryption Compatibility

## Origen VB6
- Funcion legacy: `EnCryt(cadena, tipo)`
- Uso:
  - `tipo = 0`: descifrar
  - `tipo <> 0`: cifrar
- Algoritmo base:
  - desplaza cada byte ANSI en `-80` (decrypt) o `+80` (encrypt)
  - variante adicional en algunos modulos para `Ñ` (`NtildeQuirk`)

## Implementacion .NET
- Archivo: `src/DatqBox.Infrastructure/Legacy/LegacyCrypto.vb`
- Implementacion byte a byte en `Windows-1252` para compatibilidad real con VB6 (`Asc/Chr` ANSI).
- Archivos INI:
  - parser legacy en `src/DatqBox.Infrastructure/Legacy/LegacyIniFile.vb`
  - carga runtime en `src/DatqBox.Admin.Desktop/AdminRuntimeConfig.vb`

## Resultado validado con `DatQBox.ini`
- `SysWin.Datos` -> `C:\Syswin Limited\DatQBox\Datos\Syswin.mdb`
- `FACTURA.FactPequeña` -> `Uno`
- `Topicos.Linea_uno` -> `SYSWIN LIMITED, C.A`
