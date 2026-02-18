# =============================================
# Script de prueba para SP de CxC
# =============================================

$body = @{
    requestId = "test_$(Get-Random)"
    codCliente = "CLI001"
    fecha = "2026-02-14"
    montoTotal = 1500.00
    codUsuario = "API"
    observaciones = "Prueba SP optimizado"
    documentos = @(
        @{
            tipoDoc = "FACT"
            numDoc = "F001"
            montoAplicar = 1000.00
        },
        @{
            tipoDoc = "FACT"
            numDoc = "F002"
            montoAplicar = 500.00
        }
    )
    formasPago = @(
        @{
            formaPago = "EFECTIVO"
            monto = 800.00
        },
        @{
            formaPago = "CHEQUE"
            monto = 700.00
            banco = "Banco Test"
            numCheque = "CHK001"
        }
    )
} | ConvertTo-Json -Depth 5

Write-Host "Enviando request..." -ForegroundColor Cyan
Write-Host $body -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3001/v1/cxc/aplicar-cobro-tx" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body
    
    Write-Host "`n✅ ÉXITO:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
}
catch {
    Write-Host "`n❌ ERROR:" -ForegroundColor Red
    $_.Exception.Message
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host $responseBody -ForegroundColor Red
    }
}
