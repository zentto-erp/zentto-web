param(
    [string]$ServiceName = "DatqBoxHardwareHub",
    [string]$DisplayName = "DatqBox Hardware Hub",
    [string]$Url = "http://localhost:5059",
    [switch]$SuppressKnownWarnings = $true
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

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$publishDir = Join-Path $projectRoot ".service-publish"
$exePath = Join-Path $publishDir "DatqBox.LocalFiscalAgent.exe"

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[1/6] El servicio ya existe. Deteniendo y eliminando..." -ForegroundColor Yellow
    if ($existing.Status -ne "Stopped") {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    sc.exe delete $ServiceName | Out-Null

    for ($i = 0; $i -lt 15; $i++) {
        if (-not (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 500
    }

    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        throw "No se pudo eliminar el servicio '$ServiceName'. Cierre procesos que lo estén usando e intente de nuevo."
    }
}

Write-Host "[2/6] Limpiando carpeta de publicación..." -ForegroundColor Cyan
if (Test-Path $publishDir) {
    Remove-Item -Path $publishDir -Recurse -Force
}
New-Item -ItemType Directory -Path $publishDir | Out-Null

Write-Host "[3/6] Publicando DatqBox.LocalFiscalAgent..." -ForegroundColor Cyan
$publishArgs = @(
    "publish",
    "$projectRoot\DatqBox.LocalFiscalAgent.csproj",
    "-c", "Release",
    "-r", "win-x64",
    "--self-contained", "false",
    "-o", "$publishDir"
)

if ($SuppressKnownWarnings) {
    $publishArgs += "-p:NuGetAudit=false"
    $publishArgs += "-p:NoWarn=CS0219"
    $publishArgs += "-clp:ErrorsOnly"
}

& dotnet @publishArgs
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish fallo con codigo $LASTEXITCODE"
}

if (-not (Test-Path $exePath)) {
    throw "No se encontró el ejecutable publicado: $exePath"
}

Write-Host "[4/6] Creando servicio de Windows..." -ForegroundColor Cyan
$binaryPath = "`"$exePath`" --urls `"$Url`""
try {
    New-Service -Name $ServiceName -BinaryPathName $binaryPath -DisplayName $DisplayName -StartupType Automatic -ErrorAction Stop | Out-Null
} catch {
    throw "No se pudo crear el servicio '$ServiceName'. Error: $($_.Exception.Message)"
}

$created = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $created) {
    throw "El servicio '$ServiceName' no fue creado correctamente."
}

Write-Host "[5/6] Configurando reinicio automatico ante fallo..." -ForegroundColor Cyan
sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/5000/restart/5000 | Out-Null

Write-Host "[6/6] Iniciando servicio..." -ForegroundColor Cyan
Start-Service -Name $ServiceName

$svc = Get-Service -Name $ServiceName
Write-Host "Servicio: $($svc.Name) | Estado: $($svc.Status) | Inicio: Automatico" -ForegroundColor Green

try {
    $health = Invoke-RestMethod -Uri "$Url/" -Method Get -TimeoutSec 5
    Write-Host "Healthcheck: OK ($($health.Status))" -ForegroundColor Green
} catch {
    Write-Host "Healthcheck: No respondio en $Url/. Revise firewall o puerto." -ForegroundColor Yellow
}

Write-Host "Verificacion recomendada: abrir $Url/ y $Url/api/status?marca=PNP&puerto=COM1&conexion=emulador" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# TAREAS PROGRAMADAS: permiten iniciar/detener el servicio SIN elevacion UAC
# La API Node.js llama a: schtasks /run /tn DatqBoxAgentStart
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[Extra] Registrando tareas programadas de control sin UAC..." -ForegroundColor Cyan

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
$settingsTask = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew

$actionStart = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Start-Service -Name '$ServiceName' -ErrorAction SilentlyContinue`""

$actionStop = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Stop-Service -Name '$ServiceName' -Force -ErrorAction SilentlyContinue`""

$actionRestart = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"Stop-Service -Name '$ServiceName' -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 3; Start-Service -Name '$ServiceName' -ErrorAction SilentlyContinue`""

Register-ScheduledTask -TaskName "DatqBoxAgentStart"   -Action $actionStart   -Principal $principal -Settings $settingsTask -Force | Out-Null
Register-ScheduledTask -TaskName "DatqBoxAgentStop"    -Action $actionStop    -Principal $principal -Settings $settingsTask -Force | Out-Null
Register-ScheduledTask -TaskName "DatqBoxAgentRestart" -Action $actionRestart -Principal $principal -Settings $settingsTask -Force | Out-Null

Write-Host "Tareas registradas: DatqBoxAgentStart / DatqBoxAgentStop / DatqBoxAgentRestart (SYSTEM, sin UAC)" -ForegroundColor Green
