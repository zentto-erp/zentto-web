# Script de Pruebas Rápidas - DatQBox API
param(
    [string]$BaseUrl = "http://localhost:3001",
    [string]$Usuario = "SUP",
    [string]$Clave = "SUP"
)

Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🧪 PRUEBAS RÁPIDAS - DATQBOX API" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 1. Login
Write-Host "1️⃣  AUTENTICACIÓN" -ForegroundColor Yellow
try {
    $loginBody = @{ usuario = $Usuario; clave = $Clave } | ConvertTo-Json
    $auth = Invoke-RestMethod -Uri "$BaseUrl/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json" -TimeoutSec 10
    $token = $auth.token
    Write-Host "   ✅ POST /v1/auth/login - OK (Token: $($token.Substring(0,20))...)" -ForegroundColor Green
    Write-Host "   User: $($auth.usuario.nombre) ($($auth.usuario.codUsuario))" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Error de autenticación: $_" -ForegroundColor Red
    exit 1
}

$headers = @{ Authorization = "Bearer $token" }

# 2. Health Check
Write-Host "`n2️⃣  HEALTH CHECK" -ForegroundColor Yellow
try {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 5
    Write-Host "   ✅ GET /health - OK" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

try {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/health/db" -Method GET -TimeoutSec 10
    Write-Host "   ✅ GET /health/db - $($resp.database)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error: $_" -ForegroundColor Red
}

# 3. Documentos
Write-Host "`n3️⃣  DOCUMENTOS" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "documentos-venta (FACT)"; Path = "/v1/documentos-venta?tipoOperacion=FACT&limit=1" },
    @{ Name = "documentos-compra (ORDC)"; Path = "/v1/documentos-compra?tipoOperacion=ORDC&limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 0 }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 4. Terceros
Write-Host "`n4️⃣  TERCEROS" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "clientes"; Path = "/v1/clientes?limit=1" },
    @{ Name = "proveedores"; Path = "/v1/proveedores?limit=1" },
    @{ Name = "vendedores"; Path = "/v1/vendedores?limit=1" },
    @{ Name = "empleados"; Path = "/v1/empleados?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 0 }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 5. Inventario
Write-Host "`n5️⃣  INVENTARIO" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "inventario/articulos"; Path = "/v1/inventario/articulos?limit=1" },
    @{ Name = "categorias"; Path = "/v1/categorias?limit=1" },
    @{ Name = "marcas"; Path = "/v1/marcas?limit=1" },
    @{ Name = "lineas"; Path = "/v1/lineas?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 0 }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 6. Bancos
Write-Host "`n6️⃣  BANCOS" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "bancos"; Path = "/v1/bancos?limit=1" },
    @{ Name = "bancos/cuentas"; Path = "/v1/bancos/cuentas/list" },
    @{ Name = "bancos/conciliaciones"; Path = "/v1/bancos/conciliaciones?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } elseif ($resp.rows) { $resp.rows.Count } else { $resp.Count }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 7. CxC / CxP
Write-Host "`n7️⃣  CUENTAS POR COBRAR/PAGAR" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "cxc/documentos"; Path = "/v1/cxc/documentos?limit=1" },
    @{ Name = "cxp/documentos"; Path = "/v1/cxp/documentos?limit=1" },
    @{ Name = "cuentas-por-pagar"; Path = "/v1/cuentas-por-pagar?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 0 }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 8. Nómina
Write-Host "`n8️⃣  NÓMINA" -ForegroundColor Yellow
try {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/v1/nomina/conceptos-legales?limit=1" -Headers $headers -TimeoutSec 10
    Write-Host "   ✅ GET nomina/conceptos-legales - $($resp.Count) registros" -ForegroundColor Green
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    Write-Host "   ❌ GET nomina/conceptos-legales - HTTP $status" -ForegroundColor Red
}

# 9. Contabilidad
Write-Host "`n9️⃣  CONTABILIDAD" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "contabilidad/cuentas"; Path = "/v1/contabilidad/cuentas?limit=1" },
    @{ Name = "centro-costo"; Path = "/v1/centro-costo?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 0 }
        Write-Host "   ✅ GET $($ep.Name) - $count registros" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

# 10. Configuración
Write-Host "`n🔟  CONFIGURACIÓN" -ForegroundColor Yellow
$endpoints = @(
    @{ Name = "empresa"; Path = "/v1/empresa" },
    @{ Name = "usuarios"; Path = "/v1/usuarios?limit=1" },
    @{ Name = "unidades"; Path = "/v1/unidades?limit=1" }
)
foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl$($ep.Path)" -Headers $headers -TimeoutSec 10
        $count = if ($resp.data) { $resp.data.Count } else { 1 }
        Write-Host "   ✅ GET $($ep.Name) - OK" -ForegroundColor Green
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        Write-Host "   ❌ GET $($ep.Name) - HTTP $status" -ForegroundColor Red
    }
}

Write-Host "`n═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ PRUEBAS COMPLETADAS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════`n" -ForegroundColor Cyan
