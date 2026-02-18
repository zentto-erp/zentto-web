param(
    [string]$Server = "DELLXEONE31545\SQLEXPRESS",
    [string]$Database = "DatqBoxExpress",
    [string]$User = "sa",
    [string]$Password = "e!334011"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$snapshotDir = Join-Path $root "snapshots"

New-Item -ItemType Directory -Force -Path $snapshotDir | Out-Null

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$items = @(
    @{ Name = "tables"; Query = "inventory_tables.sql" },
    @{ Name = "columns"; Query = "inventory_columns.sql" },
    @{ Name = "indexes"; Query = "inventory_indexes.sql" },
    @{ Name = "foreign_keys"; Query = "inventory_foreign_keys.sql" }
)

foreach ($item in $items) {
    $queryFile = Join-Path $scriptDir $item.Query
    $outFile = Join-Path $snapshotDir ("{0}_{1}.csv" -f $stamp, $item.Name)
    & sqlcmd -S $Server -U $User -P $Password -d $Database -W -s "|" -h -1 -i $queryFile -o $outFile
}

Write-Output ("Inventario exportado en: {0}" -f $snapshotDir)
