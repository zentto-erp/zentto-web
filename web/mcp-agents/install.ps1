# Script para instalar dependencias de todos los agentes MCP
# Ejecutar desde: DatqBox Administrativo ADO SQL net/web/mcp-agents/

Write-Host "=== Instalando dependencias de agentes MCP ===" -ForegroundColor Cyan
Write-Host ""

$agents = @("database-agent", "api-agent", "frontend-agent")

foreach ($agent in $agents) {
    Write-Host "📦 Instalando $agent..." -ForegroundColor Yellow
    Push-Location $agent
    
    if (Test-Path "package.json") {
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $agent instalado correctamente" -ForegroundColor Green
        } else {
            Write-Host "❌ Error instalando $agent" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  No se encontró package.json en $agent" -ForegroundColor Yellow
    }
    
    Pop-Location
    Write-Host ""
}

Write-Host "=== Instalación completada ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Los agentes MCP están listos para usar en VS Code." -ForegroundColor Green
Write-Host "Reinicia VS Code para que los cambios surtan efecto." -ForegroundColor Yellow
