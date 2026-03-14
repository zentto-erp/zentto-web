param(
    [string]$ServiceName = "DatqBoxHardwareHub"
)

$ErrorActionPreference = "Stop"

function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    throw "Este script requiere PowerShell como Administrador."
}

# Verificar que el servicio existe
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
    throw "No se encontro el servicio '$ServiceName'. Ejecute primero INSTALAR_SERVICIO.ps1."
}

Write-Host "Configurando permisos del servicio para usuarios interactivos..." -ForegroundColor Cyan

# Grant Interactive Users (IU) permission to start/stop the service directly via sc sdset.
# SDDL breakdown:
#   (A;;CCLCSWRPWPDTLOCRRC;;;SY) = SYSTEM - full service control
#   (A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA) = Builtin Admins - full control
#   (A;;CCLCSWRPWPLOCRRC;;;IU)   = Interactive Users - start (RP) + stop (WP) + query added
#   (A;;CCLCSWLOCRRC;;;SU)       = Service Users - query only
$serviceSddl = "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWRPWPLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)"
$scResult = & sc.exe sdset $ServiceName $serviceSddl 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Permisos del servicio configurados (usuarios interactivos pueden iniciar/detener)" -ForegroundColor Green
} else {
    Write-Warning "No se pudieron configurar permisos del servicio: $scResult"
}

Write-Host ""
Write-Host "Registrando tareas programadas de control sin UAC..." -ForegroundColor Cyan

$principal   = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$settings    = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew

$actionStart = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Start-Service -Name '$ServiceName' -ErrorAction SilentlyContinue`""

$actionStop  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Stop-Service -Name '$ServiceName' -Force -ErrorAction SilentlyContinue`""

$actionRestart = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Stop-Service -Name '$ServiceName' -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 3; Start-Service -Name '$ServiceName' -ErrorAction SilentlyContinue`""

Register-ScheduledTask -TaskName "DatqBoxAgentStart"   -Action $actionStart   -Principal $principal -Settings $settings -Force | Out-Null
Register-ScheduledTask -TaskName "DatqBoxAgentStop"    -Action $actionStop    -Principal $principal -Settings $settings -Force | Out-Null
Register-ScheduledTask -TaskName "DatqBoxAgentRestart" -Action $actionRestart -Principal $principal -Settings $settings -Force | Out-Null

Write-Host ""
Write-Host "OK - Tareas registradas como SYSTEM (sin UAC):" -ForegroundColor Green
Write-Host "  DatqBoxAgentStart   -> inicia el servicio" -ForegroundColor Green
Write-Host "  DatqBoxAgentStop    -> detiene el servicio" -ForegroundColor Green
Write-Host "  DatqBoxAgentRestart -> reinicia el servicio" -ForegroundColor Green
Write-Host ""
Write-Host "Verificando con prueba rapida..." -ForegroundColor Cyan

# Prueba rapida: listar las tareas para confirmar
$tasks = Get-ScheduledTask -TaskName "DatqBoxAgent*" -ErrorAction SilentlyContinue
if ($tasks.Count -eq 3) {
    Write-Host "Verificacion OK: $($tasks.Count) tareas encontradas." -ForegroundColor Green
    Write-Host "Ahora puede iniciar/detener/reiniciar desde el navegador web." -ForegroundColor Green
} else {
    Write-Host "Advertencia: Solo se encontraron $($tasks.Count) tareas (se esperaban 3)." -ForegroundColor Yellow
}
