# DatqBox Local Fiscal Agent - Servicio de Windows (Paso a paso)

Este instructivo permite dejar el agente fiscal activo automáticamente al encender la PC.

## Requisitos

- Windows 10/11
- .NET SDK instalado (para publicar)
- Ejecutar PowerShell **como Administrador**
- Carpeta del proyecto: [DatqBox.LocalFiscalAgent](.)

## Opción recomendada (script automático)

1. Abrir PowerShell como Administrador.
2. Ir a la carpeta del proyecto:

   `cd "d:\DatqBoxWorkspace\DatqBoxWeb\DatqBox.LocalFiscalAgent"`

3. Ejecutar instalación:

   `powershell -ExecutionPolicy Bypass -File .\INSTALAR_SERVICIO.ps1`

   Si quieres ver todos los warnings de NuGet/compilación:

   `powershell -ExecutionPolicy Bypass -File .\\INSTALAR_SERVICIO.ps1 -SuppressKnownWarnings:$false`

4. Verificar estado:

   `Get-Service DatqBoxHardwareHub`

5. Verificar API:

   - `http://localhost:5059/`
   - `http://localhost:5059/api/status?marca=PNP&puerto=COM1&conexion=emulador`

## Opción manual (sin script)

1. Publicar ejecutable:

   `dotnet publish .\DatqBox.LocalFiscalAgent.csproj -c Release -r win-x64 --self-contained false -o .\publish`

2. Crear servicio:

   `sc.exe create DatqBoxHardwareHub binPath= "\"d:\DatqBoxWorkspace\DatqBoxWeb\DatqBox.LocalFiscalAgent\publish\DatqBox.LocalFiscalAgent.exe\" --urls \"http://localhost:5059\"" start= auto DisplayName= "DatqBox Hardware Hub"`

3. Configurar reinicio automático:

   `sc.exe failure DatqBoxHardwareHub reset= 86400 actions= restart/5000/restart/5000/restart/5000`

4. Iniciar servicio:

   `Start-Service DatqBoxHardwareHub`

5. Validar:

   `Get-Service DatqBoxHardwareHub`

## Comandos útiles

- Reiniciar servicio: `Restart-Service DatqBoxHardwareHub`
- Detener servicio: `Stop-Service DatqBoxHardwareHub`
- Ver logs en vivo (si está en consola): usar `dotnet run --urls http://localhost:5059`

## Desinstalar servicio

1. Abrir PowerShell como Administrador.
2. Ejecutar:

   `powershell -ExecutionPolicy Bypass -File .\DESINSTALAR_SERVICIO.ps1`

## Notas

- Si sale "apagado o bloqueado", revisar firewall y puerto 5059.
- El script ahora falla con mensaje claro si el servicio no se pudo crear.
- Por defecto el script usa `NuGetAudit=false` y suprime solo `CS0219` para mantener la salida limpia en instalación.
- La publicación del servicio se hace en `.service-publish` (carpeta limpia) para evitar problemas de copia tipo `publish\\publish`.
- Para comprobar uso de puerto:

  `netstat -ano | findstr :5059`

- Si hay conflicto de puerto, cambiar URL en el script de instalación (`-Url`).
