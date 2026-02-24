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

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Host "El servicio '$ServiceName' no existe." -ForegroundColor Yellow
    exit 0
}

if ($svc.Status -ne "Stopped") {
    Write-Host "Deteniendo servicio $ServiceName..." -ForegroundColor Cyan
    Stop-Service -Name $ServiceName -Force
    Start-Sleep -Seconds 2
}

Write-Host "Eliminando servicio $ServiceName..." -ForegroundColor Cyan
sc.exe delete $ServiceName | Out-Null
Write-Host "Servicio eliminado." -ForegroundColor Green
