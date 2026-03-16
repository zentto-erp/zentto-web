param(
  [string]$ApiBaseUrl = "http://localhost:4000",
  [string]$Usuario = "SUP",
  [string]$Clave = "1234",
  [int]$CompanyId = 1,
  [int]$BranchId = 1,
  [string]$DbServer = "",
  [string]$DbDatabase = "DatqBoxWeb",
  [string]$DbUser = "",
  [string]$DbPassword = "",
  [switch]$IncludeAllMasterFromSql = $true,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-VisualKind {
  param(
    [string]$Code,
    [string]$Name
  )

  $token = ("$Code $Name").ToUpperInvariant()

  if ($token -match "HAMB") { return "burger" }
  if ($token -match "PIZZA|PEPPERONI|MARGHERITA") { return "pizza" }
  if ($token -match "PASTA") { return "bowl" }
  if ($token -match "CAFE|CAPPUCCINO|ESPRESSO") { return "coffee" }
  if ($token -match "COLA|REFRESCO|MOJITO|GIN|LIMONADA|JUGO|BEBIDA") { return "drink" }
  if ($token -match "CHEESECAKE|BROWNIE|POSTRE") { return "dessert" }
  if ($token -match "PAPAS|TEQUENOS|ALITAS|COMBO|PROMO") { return "plate" }
  if ($token -match "INS|INSUMO|MATERIA") { return "ingredient" }

  return "plate"
}

function Get-IconMarkup {
  param([string]$Kind)

  switch ($Kind) {
    "burger" {
      return @"
<rect x="118" y="120" width="276" height="54" rx="27" fill="#F5C06A"/>
<rect x="126" y="180" width="260" height="20" rx="10" fill="#5E8B3D"/>
<rect x="126" y="206" width="260" height="24" rx="12" fill="#7C4A1E"/>
<rect x="118" y="236" width="276" height="56" rx="28" fill="#E2A857"/>
"@
    }
    "pizza" {
      return @"
<polygon points="130,90 400,190 190,390" fill="#F4C76A"/>
<polygon points="160,130 352,202 206,338" fill="#F6DE9A"/>
<circle cx="238" cy="200" r="13" fill="#C63A3A"/>
<circle cx="282" cy="222" r="11" fill="#C63A3A"/>
<circle cx="248" cy="260" r="11" fill="#C63A3A"/>
"@
    }
    "bowl" {
      return @"
<ellipse cx="256" cy="228" rx="136" ry="34" fill="#EECF8A"/>
<path d="M116 228 Q256 332 396 228 L396 250 Q256 360 116 250 Z" fill="#C76A3A"/>
<path d="M160 198 C190 170, 320 170, 350 198" stroke="#F2E5B0" stroke-width="10" fill="none" stroke-linecap="round"/>
"@
    }
    "coffee" {
      return @"
<rect x="156" y="146" width="184" height="136" rx="20" fill="#E9D9BE"/>
<path d="M340 178 Q386 178 386 212 Q386 246 340 246" stroke="#E9D9BE" stroke-width="18" fill="none"/>
<rect x="170" y="158" width="156" height="96" rx="16" fill="#8A5B32"/>
<path d="M204 120 C196 94, 216 84, 226 70" stroke="#D8C3A0" stroke-width="8" fill="none" stroke-linecap="round"/>
<path d="M252 116 C244 90, 264 80, 274 66" stroke="#D8C3A0" stroke-width="8" fill="none" stroke-linecap="round"/>
"@
    }
    "drink" {
      return @"
<polygon points="180,124 332,124 296,338 216,338" fill="#A5D8F3"/>
<polygon points="196,140 316,140 290,320 222,320" fill="#6DB6DE"/>
<rect x="242" y="90" width="14" height="66" rx="7" fill="#F0F5F9"/>
"@
    }
    "dessert" {
      return @"
<rect x="154" y="168" width="204" height="136" rx="14" fill="#B87042"/>
<rect x="154" y="150" width="204" height="30" rx="14" fill="#E6D0B4"/>
<circle cx="228" cy="194" r="10" fill="#C93939"/>
<circle cx="258" cy="186" r="10" fill="#C93939"/>
<circle cx="288" cy="198" r="10" fill="#C93939"/>
"@
    }
    "ingredient" {
      return @"
<rect x="146" y="134" width="220" height="198" rx="20" fill="#9CBF7A"/>
<rect x="166" y="154" width="180" height="42" rx="12" fill="#D4E7BF"/>
<rect x="166" y="208" width="180" height="30" rx="10" fill="#7EA95D"/>
<rect x="166" y="248" width="180" height="30" rx="10" fill="#7EA95D"/>
"@
    }
    default {
      return @"
<ellipse cx="256" cy="254" rx="146" ry="72" fill="#D2D9E0"/>
<ellipse cx="256" cy="250" rx="128" ry="56" fill="#F3F7FA"/>
<circle cx="214" cy="240" r="12" fill="#DB6F4B"/>
<circle cx="246" cy="224" r="10" fill="#7AAF58"/>
<circle cx="286" cy="242" r="11" fill="#DB6F4B"/>
"@
    }
  }
}

function New-ImageSvg {
  param(
    [string]$Code,
    [string]$Name
  )

  $kind = Get-VisualKind -Code $Code -Name $Name
  $icon = Get-IconMarkup -Kind $kind
  $title = ($Name -replace "&", "&amp;" -replace "<", "&lt;" -replace ">", "&gt;")
  $subtitle = ($Code -replace "&", "&amp;" -replace "<", "&lt;" -replace ">", "&gt;")

  return @"
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1F3550"/>
      <stop offset="100%" stop-color="#2A5A7A"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="url(#bg)"/>
  <circle cx="256" cy="220" r="168" fill="#FFFFFF" fill-opacity="0.10"/>
  $icon
  <rect x="40" y="372" width="432" height="100" rx="18" fill="#0E1B2A" fill-opacity="0.72"/>
  <text x="58" y="414" font-family="Segoe UI, Arial, sans-serif" font-size="26" fill="#FFFFFF">$title</text>
  <text x="58" y="446" font-family="Consolas, Arial, sans-serif" font-size="18" fill="#D1E8FF">$subtitle</text>
</svg>
"@
}

function Get-AuthToken {
  param(
    [string]$BaseUrl,
    [string]$User,
    [string]$Pass,
    [int]$CoId,
    [int]$BrId
  )

  $body = @{
    usuario = $User
    clave = $Pass
    companyId = $CoId
    branchId = $BrId
  } | ConvertTo-Json

  $login = Invoke-RestMethod -Method Post -Uri "$BaseUrl/v1/auth/login" -ContentType "application/json" -Body $body
  if (-not $login.token) {
    throw "No se obtuvo token de autenticacion."
  }
  return [string]$login.token
}

function Get-EntityImages {
  param(
    [string]$BaseUrl,
    [hashtable]$Headers,
    [string]$EntityType,
    [int]$EntityId
  )
  return Invoke-RestMethod -Method Get -Uri "$BaseUrl/v1/media/entities/$EntityType/$EntityId/images" -Headers $Headers
}

function Upload-EntityImage {
  param(
    [string]$BaseUrl,
    [string]$Token,
    [string]$FilePath,
    [string]$EntityType,
    [int]$EntityId,
    [string]$AltText
  )

  $uploadPath = ($FilePath -replace "\\", "/")
  $raw = & curl.exe -s -X POST "$BaseUrl/v1/media/upload" `
    -H "Authorization: Bearer $Token" `
    -F "file=@$uploadPath;type=image/svg+xml" `
    -F "entityType=$EntityType" `
    -F "entityId=$EntityId" `
    -F "isPrimary=true" `
    -F "altText=$AltText"

  if (-not $raw) { throw "Upload vacio para $EntityType/$EntityId" }
  $json = $raw | ConvertFrom-Json
  if (-not $json.ok) {
    throw "Upload fallo para $EntityType/$EntityId => $raw"
  }
  return $json
}

function New-ImageFile {
  param(
    [string]$Root,
    [string]$EntityType,
    [int]$EntityId,
    [string]$Code,
    [string]$Name
  )

  $safeCode = ($Code -replace "[^A-Za-z0-9\-_]", "_")
  $fileName = "$EntityType-$EntityId-$safeCode.svg"
  $fullPath = Join-Path $Root $fileName
  $svg = New-ImageSvg -Code $Code -Name $Name
  [IO.File]::WriteAllText($fullPath, $svg, [System.Text.UTF8Encoding]::new($false))
  return $fullPath
}

Write-Host "== DatqBox media seed =="
Write-Host "API: $ApiBaseUrl | CompanyId=$CompanyId | BranchId=$BranchId | Force=$Force"

$token = Get-AuthToken -BaseUrl $ApiBaseUrl -User $Usuario -Pass $Clave -CoId $CompanyId -BrId $BranchId
$headers = @{ Authorization = "Bearer $token" }

$tmpRoot = Join-Path (Get-Location) ".tmp_media_seed"
if (Test-Path $tmpRoot) { Remove-Item -Recurse -Force $tmpRoot }
New-Item -ItemType Directory -Path $tmpRoot | Out-Null

$pos = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/v1/pos/productos?limit=500" -Headers $headers
$menu = Invoke-RestMethod -Method Get -Uri "$ApiBaseUrl/v1/restaurante/admin/productos?soloDisponibles=false" -Headers $headers

$targets = @()
$targetKeys = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($r in $pos.rows) {
  $item = [pscustomobject]@{
    entityType = "MASTER_PRODUCT"
    entityId = [int]$r.id
    code = [string]$r.codigo
    name = [string]$r.nombre
  }
  $key = "$($item.entityType)|$($item.entityId)"
  if ($targetKeys.Add($key)) { $targets += $item }
}
foreach ($r in $menu.rows) {
  $item = [pscustomobject]@{
    entityType = "REST_MENU_PRODUCT"
    entityId = [int]$r.id
    code = [string]$r.codigo
    name = [string]$r.nombre
  }
  $key = "$($item.entityType)|$($item.entityId)"
  if ($targetKeys.Add($key)) { $targets += $item }
}

if ($IncludeAllMasterFromSql) {
  try {
    $resolvedServer = if ([string]::IsNullOrWhiteSpace($DbServer)) { $env:DB_SERVER } else { $DbServer }
    $resolvedUser = if ([string]::IsNullOrWhiteSpace($DbUser)) { $env:DB_USER } else { $DbUser }
    $resolvedPassword = if ([string]::IsNullOrWhiteSpace($DbPassword)) { $env:DB_PASSWORD } else { $DbPassword }

    if ([string]::IsNullOrWhiteSpace($resolvedServer) -or [string]::IsNullOrWhiteSpace($resolvedUser) -or [string]::IsNullOrWhiteSpace($resolvedPassword)) {
      throw "Credenciales SQL no disponibles. Define -DbServer/-DbUser/-DbPassword o variables de entorno DB_*."
    }

    $sqlQuery = @"
SET NOCOUNT ON;
SELECT
  CAST(ProductId AS varchar(20)) AS ProductId,
  ProductCode,
  ProductName
FROM [master].Product
WHERE CompanyId = $CompanyId
  AND IsDeleted = 0
  AND IsActive = 1
ORDER BY ProductId;
"@

    $rows = & sqlcmd -S $resolvedServer -U $resolvedUser -P $resolvedPassword -d $DbDatabase -h -1 -W -s "|" -Q $sqlQuery
    foreach ($line in $rows) {
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      $parts = $line -split "\|"
      if ($parts.Count -lt 3) { continue }

      $id = 0
      if (-not [int]::TryParse($parts[0].Trim(), [ref]$id)) { continue }
      $code = $parts[1].Trim()
      $name = $parts[2].Trim()
      if ($id -le 0 -or [string]::IsNullOrWhiteSpace($code)) { continue }

      $item = [pscustomobject]@{
        entityType = "MASTER_PRODUCT"
        entityId = $id
        code = [string]$code
        name = [string]$name
      }
      $key = "$($item.entityType)|$($item.entityId)"
      if ($targetKeys.Add($key)) { $targets += $item }
    }
  } catch {
    Write-Host "WARN sqlcmd source no disponible: $($_.Exception.Message)"
  }
}

$created = 0
$skipped = 0
$failed = 0

foreach ($t in $targets) {
  try {
    $existing = Get-EntityImages -BaseUrl $ApiBaseUrl -Headers $headers -EntityType $t.entityType -EntityId $t.entityId
    $hasExisting = ($existing.rows | Measure-Object).Count -gt 0
    if ($hasExisting -and -not $Force) {
      $skipped++
      Write-Host ("SKIP  {0}/{1}  {2}" -f $t.entityType, $t.entityId, $t.code)
      continue
    }

    $filePath = New-ImageFile -Root $tmpRoot -EntityType $t.entityType -EntityId $t.entityId -Code $t.code -Name $t.name
    $null = Upload-EntityImage -BaseUrl $ApiBaseUrl -Token $token -FilePath $filePath -EntityType $t.entityType -EntityId $t.entityId -AltText $t.name
    $created++
    Write-Host ("OK    {0}/{1}  {2}" -f $t.entityType, $t.entityId, $t.code)
  } catch {
    $failed++
    Write-Host ("FAIL  {0}/{1}  {2}  => {3}" -f $t.entityType, $t.entityId, $t.code, $_.Exception.Message)
  }
}

if (Test-Path $tmpRoot) {
  Remove-Item -Recurse -Force $tmpRoot
}

Write-Host ""
Write-Host "Resumen:"
Write-Host "  creadas:  $created"
Write-Host "  omitidas: $skipped"
Write-Host "  fallidas: $failed"

if ($failed -gt 0) {
  throw "Seed finalizado con errores."
}
