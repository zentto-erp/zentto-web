# Script de Diagnóstico - API DatQBox
Write-Host "🔍 DIAGNÓSTICO DE API DATQBOX" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════`n"

# 1. Verificar proceso de Node.js
Write-Host "1️⃣  Verificando proceso Node.js..." -ForegroundColor Yellow
$nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcess) {
    Write-Host "   ✅ Node.js encontrado" -ForegroundColor Green
    Write-Host "   PID: $($nodeProcess.Id)" -ForegroundColor Gray
    Write-Host "   Memoria: $([math]::Round($nodeProcess.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "   Tiempo: $($nodeProcess.StartTime)`n" -ForegroundColor Gray
} else {
    Write-Host "   ❌ No hay proceso Node.js corriendo`n" -ForegroundColor Red
}

# 2. Verificar puerto 3001
Write-Host "2️⃣  Verificando puerto 3001..." -ForegroundColor Yellow
$portInfo = netstat -ano | findstr ":3001"
if ($portInfo) {
    Write-Host "   ✅ Puerto 3001 está activo" -ForegroundColor Green
    $portInfo | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    Write-Host ""
} else {
    Write-Host "   ❌ Puerto 3001 no está escuchando`n" -ForegroundColor Red
}

# 3. Probar health endpoint
Write-Host "3️⃣  Probando endpoint /health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ API responde correctamente" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)`n" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ API no responde" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}

# 4. Verificar archivos de build
Write-Host "4️⃣  Verificando archivos compilados..." -ForegroundColor Yellow
$distPath = ".\dist"
if (Test-Path $distPath) {
    $files = Get-ChildItem $distPath -Recurse -File | Measure-Object
    Write-Host "   ✅ Directorio dist existe" -ForegroundColor Green
    Write-Host "   Archivos compilados: $($files.Count)`n" -ForegroundColor Gray
} else {
    Write-Host "   ❌ No se encontró directorio dist`n" -ForegroundColor Red
}

# 5. Verificar configuración
Write-Host "5️⃣  Verificando configuración .env..." -ForegroundColor Yellow
if (Test-Path ".\.env") {
    Write-Host "   ✅ Archivo .env existe" -ForegroundColor Green
    $envContent = Get-Content ".\.env" -Raw
    if ($envContent -match "DB_SERVER") { Write-Host "   - DB_SERVER configurado" -ForegroundColor Gray }
    if ($envContent -match "DB_DATABASE") { Write-Host "   - DB_DATABASE configurado" -ForegroundColor Gray }
    if ($envContent -match "PORT") { Write-Host "   - PORT configurado" -ForegroundColor Gray }
    Write-Host ""
} else {
    Write-Host "   ⚠️  No se encontró archivo .env`n" -ForegroundColor Yellow
}

# 6. Resumen
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 RESUMEN DEL DIAGNÓSTICO" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════`n"

if ($nodeProcess -and $portInfo) {
    Write-Host "La API está en ejecución pero puede tener problemas de conectividad." -ForegroundColor Yellow
    Write-Host "Sugerencias:" -ForegroundColor Gray
    Write-Host "  1. Verifica la conexión a SQL Server" -ForegroundColor Gray
    Write-Host "  2. Revisa los logs de la aplicación" -ForegroundColor Gray
    Write-Host "  3. Intenta reiniciar la API`n" -ForegroundColor Gray
} else {
    Write-Host "La API no está en ejecución. Iníciala con:" -ForegroundColor Red
    Write-Host "  npm run dev`n" -ForegroundColor Gray
}

Write-Host "Para más detalles, ejecuta los agentes MCP:" -ForegroundColor Cyan
Write-Host "  @api-agent analiza todas las rutas registradas" -ForegroundColor Gray
Write-Host "  @database-agent verifica la conexión a la base de datos`n" -ForegroundColor Gray
