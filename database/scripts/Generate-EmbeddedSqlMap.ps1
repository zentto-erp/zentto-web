param(
    [string]$LegacyRoot = "c:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL",
    [string]$HotspotFile = "c:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL net\docs\db\embedded-sql-hotspots.txt",
    [string]$OutputFile = "c:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL net\docs\db\SQL_TO_SP_MAP_INITIAL.md",
    [int]$MaxFiles = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToSafeToken {
    param([string]$Text)
    $t = $Text -replace "[^a-zA-Z0-9_]", "_"
    $t = $t.Trim("_")
    if ([string]::IsNullOrWhiteSpace($t)) { $t = "Unknown" }
    return $t
}

function Get-StatementType {
    param([string]$SqlText)
    $u = $SqlText.ToUpperInvariant()
    if ($u -match "\bSELECT\b") { return "SELECT" }
    if ($u -match "\bINSERT\s+INTO\b") { return "INSERT" }
    if ($u -match "\bUPDATE\b") { return "UPDATE" }
    if ($u -match "\bDELETE\s+FROM\b") { return "DELETE" }
    if ($u -match "\bEXEC(UTE)?\b") { return "EXEC" }
    return ""
}

function Get-MainObject {
    param(
        [string]$SqlText,
        [string]$StatementType
    )

    $u = $SqlText.ToUpperInvariant()
    switch ($StatementType) {
        "SELECT" {
            if ($u -match "\bFROM\s+([A-Z0-9_\.\[\]]+)") { return $matches[1] }
        }
        "INSERT" {
            if ($u -match "\bINSERT\s+INTO\s+([A-Z0-9_\.\[\]]+)") { return $matches[1] }
        }
        "UPDATE" {
            if ($u -match "\bUPDATE\s+([A-Z0-9_\.\[\]]+)") { return $matches[1] }
        }
        "DELETE" {
            if ($u -match "\bDELETE\s+FROM\s+([A-Z0-9_\.\[\]]+)") { return $matches[1] }
        }
        "EXEC" {
            if ($u -match "\bEXEC(UTE)?\s+([A-Z0-9_\.\[\]]+)") { return $matches[2] }
        }
    }
    return "UNKNOWN"
}

function Normalize-Sql {
    param([string]$Text)
    $x = $Text -replace "\s+", " "
    return $x.Trim()
}

function Build-SpName {
    param(
        [string]$FilePath,
        [string]$MainObject,
        [string]$StatementType,
        [int]$Ordinal
    )

    $verb = switch ($StatementType) {
        "SELECT" { "Get" }
        "INSERT" { "Insert" }
        "UPDATE" { "Update" }
        "DELETE" { "Delete" }
        "EXEC" { "Exec" }
        default { "Op" }
    }

    $area = Convert-ToSafeToken -Text (($FilePath -split "\\")[0])
    $obj = Convert-ToSafeToken -Text ($MainObject -replace "\[|\]", "" -replace "\.", "_")
    return "usp_{0}_{1}_{2}_{3}" -f $area, $obj, $verb, $Ordinal
}

if (-not (Test-Path $HotspotFile)) {
    throw "No se encontro hotspot file: $HotspotFile"
}

$hotspotPaths = New-Object System.Collections.Generic.List[string]
$raw = Get-Content $HotspotFile -Encoding UTF8
foreach ($line in $raw) {
    if ($line -match "^\d+\s+\|\s+(.+)$") {
        $hotspotPaths.Add($matches[1].Trim())
    }
}

$selected = $hotspotPaths | Select-Object -First $MaxFiles

$records = New-Object System.Collections.Generic.List[object]
$dedupe = @{}

foreach ($rel in $selected) {
    $full = Join-Path $LegacyRoot $rel
    if (-not (Test-Path $full)) { continue }

    $lineNo = 0
    $content = Get-Content $full -ErrorAction SilentlyContinue
    foreach ($line in $content) {
        $lineNo++
        $candidates = New-Object System.Collections.Generic.List[string]

        $matches = [regex]::Matches($line, '"([^"]+)"')
        foreach ($m in $matches) {
            $fragment = $m.Groups[1].Value
            if (-not [string]::IsNullOrWhiteSpace($fragment)) {
                $candidates.Add($fragment)
            }
        }

        $candidates.Add($line)

        foreach ($candidate in $candidates) {
            $normalized = Normalize-Sql -Text $candidate
            if ($normalized.Length -lt 12) { continue }

            $type = Get-StatementType -SqlText $normalized
            if ([string]::IsNullOrWhiteSpace($type)) { continue }

            $k = "{0}|{1}" -f $rel, $normalized.ToUpperInvariant()
            if ($dedupe.ContainsKey($k)) { continue }
            $dedupe[$k] = $true

            $obj = Get-MainObject -SqlText $normalized -StatementType $type
            $records.Add([PSCustomObject]@{
                File = $rel
                Line = $lineNo
                Type = $type
                MainObject = $obj
                SqlSnippet = $normalized
            })
        }
    }
}

$grouped = $records | Group-Object File | Sort-Object Count -Descending

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Mapa Inicial SQL Embebido -> SP")
$lines.Add("")
$lines.Add("- Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")")
$lines.Add("- Archivos analizados: $($selected.Count)")
$lines.Add("- Sentencias candidatas detectadas: $($records.Count)")
$lines.Add("")
$lines.Add("## Resumen por Archivo")
$lines.Add("")
$lines.Add("| Archivo | Sentencias | SELECT | INSERT | UPDATE | DELETE | EXEC |")
$lines.Add("|---|---:|---:|---:|---:|---:|---:|")

foreach ($g in $grouped) {
    $fileRows = @($g.Group)
    $sel = (@($fileRows | Where-Object { $_.Type -eq "SELECT" }).Count)
    $ins = (@($fileRows | Where-Object { $_.Type -eq "INSERT" }).Count)
    $upd = (@($fileRows | Where-Object { $_.Type -eq "UPDATE" }).Count)
    $del = (@($fileRows | Where-Object { $_.Type -eq "DELETE" }).Count)
    $exe = (@($fileRows | Where-Object { $_.Type -eq "EXEC" }).Count)
    $safeFile = $g.Name -replace "\|", "/"
    $lines.Add("| $safeFile | $($fileRows.Count) | $sel | $ins | $upd | $del | $exe |")
}

$lines.Add("")
$lines.Add("## Mapeo Propuesto")
$lines.Add("")

foreach ($g in $grouped) {
    $lines.Add("### $($g.Name)")
    $rows = @($g.Group | Sort-Object Line, Type, MainObject)
    $i = 0
    foreach ($r in $rows) {
        $i++
        $sp = Build-SpName -FilePath $r.File -MainObject $r.MainObject -StatementType $r.Type -Ordinal $i
        $snippet = $r.SqlSnippet
        if ($snippet.Length -gt 180) {
            $snippet = $snippet.Substring(0, 180) + "..."
        }

        $lines.Add("- L$($r.Line) [$($r.Type)] objeto: $($r.MainObject)")
        $lines.Add("  SP sugerido: $sp")
        $lines.Add("  SQL: $snippet")
    }
    $lines.Add("")
}

$outDir = Split-Path -Parent $OutputFile
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$lines | Set-Content -Path $OutputFile -Encoding UTF8

Write-Output ("Mapa generado: {0}" -f $OutputFile)
