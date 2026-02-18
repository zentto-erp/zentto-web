param(
    [string]$LegacyRoot = "c:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL",
    [string]$TargetRoot = "c:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL net"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToIdentifier {
    param([Parameter(Mandatory = $true)][string]$Text)

    $id = $Text -replace "[^a-zA-Z0-9_]", "_"
    if ([string]::IsNullOrWhiteSpace($id)) { $id = "Item" }
    if ($id[0] -match "[0-9]") { $id = "N_" + $id }
    return $id
}

function Get-LegacyItems {
    param([Parameter(Mandatory = $true)][string]$VbpPath)

    $items = @()
    $content = Get-Content -Path $VbpPath -Encoding Default
    foreach ($line in $content) {
        if ($line -match "^(Form)=(.+)$") {
            $rawPath = $matches[2].Trim()
            $name = [System.IO.Path]::GetFileNameWithoutExtension($rawPath)
            $items += [PSCustomObject]@{
                Type = "Form"
                Name = $name
                RawPath = $rawPath
            }
            continue
        }

        if ($line -match "^(Module|Class)=([^;]+);\s*(.+)$") {
            $type = $matches[1]
            $name = $matches[2].Trim()
            $rawPath = $matches[3].Trim()
            $items += [PSCustomObject]@{
                Type = $type
                Name = $name
                RawPath = $rawPath
            }
            continue
        }
    }

    return $items
}

function Ensure-WinFormsEntryPoint {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDir,
        [Parameter(Mandatory = $true)][string]$RootNamespace
    )

    $programFile = Join-Path $ProjectDir "Program.vb"
    if (-not (Test-Path $programFile)) {
        @"
Imports System
Imports System.Windows.Forms

Friend Module Program
    <STAThread>
    Friend Sub Main(args As String())
        Application.SetHighDpiMode(HighDpiMode.SystemAware)
        Application.EnableVisualStyles()
        Application.SetCompatibleTextRenderingDefault(False)
        Application.Run(New MainShellForm())
    End Sub
End Module
"@ | Set-Content -Path $programFile -Encoding UTF8
    }

    $shellFile = Join-Path $ProjectDir "MainShellForm.vb"
    if (-not (Test-Path $shellFile)) {
        @"
Imports System.Windows.Forms

Public Class MainShellForm
    Inherits Form

    Public Sub New()
        Me.Text = "$RootNamespace - Migracion"
        Me.Width = 1200
        Me.Height = 800
    End Sub
End Class
"@ | Set-Content -Path $shellFile -Encoding UTF8
    }
}

function Write-Inventory {
    param(
        [Parameter(Mandatory = $true)][string]$InventoryFile,
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$VbpPath,
        [Parameter(Mandatory = $true)][array]$Items
    )

    $forms = @($Items | Where-Object { $_.Type -eq "Form" })
    $modules = @($Items | Where-Object { $_.Type -eq "Module" })
    $classes = @($Items | Where-Object { $_.Type -eq "Class" })

    $lines = @()
    $lines += "# Inventario Legacy - $ProjectName"
    $lines += ""
    $lines += "- VBP: $VbpPath"
    $lines += "- Forms: $($forms.Count)"
    $lines += "- Modules: $($modules.Count)"
    $lines += "- Classes: $($classes.Count)"
    $lines += ""
    $lines += "## Forms"
    foreach ($i in $forms) { $lines += "- $($i.Name) -> $($i.RawPath)" }
    $lines += ""
    $lines += "## Modules"
    foreach ($i in $modules) { $lines += "- $($i.Name) -> $($i.RawPath)" }
    $lines += ""
    $lines += "## Classes"
    foreach ($i in $classes) { $lines += "- $($i.Name) -> $($i.RawPath)" }

    $lines | Set-Content -Path $InventoryFile -Encoding UTF8
}

function Write-Stubs {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectDir,
        [Parameter(Mandatory = $true)][array]$Items
    )

    $formsDir = Join-Path $ProjectDir "LegacyStubs/Forms"
    $modulesDir = Join-Path $ProjectDir "LegacyStubs/Modules"
    $classesDir = Join-Path $ProjectDir "LegacyStubs/Classes"
    New-Item -ItemType Directory -Force -Path $formsDir, $modulesDir, $classesDir | Out-Null

    $usedNames = @{}
    foreach ($item in $Items) {
        $safeName = Convert-ToIdentifier -Text $item.Name
        if ($usedNames.ContainsKey($safeName)) {
            $usedNames[$safeName] += 1
            $safeName = "{0}_{1}" -f $safeName, $usedNames[$safeName]
        } else {
            $usedNames[$safeName] = 1
        }

        switch ($item.Type) {
            "Form" {
                $file = Join-Path $formsDir ($safeName + ".vb")
                @"
Imports System.Windows.Forms

' Legacy source: $($item.RawPath)
Public Class $safeName
    Inherits Form

    Public Sub New()
        Me.Text = "$safeName (Stub)"
    End Sub
End Class
"@ | Set-Content -Path $file -Encoding UTF8
            }
            "Module" {
                $file = Join-Path $modulesDir ($safeName + ".vb")
                @"
' Legacy source: $($item.RawPath)
Public Module $safeName
    ' TODO: Migrar funciones y SQL incrustado desde VB6.
End Module
"@ | Set-Content -Path $file -Encoding UTF8
            }
            "Class" {
                $file = Join-Path $classesDir ($safeName + ".vb")
                @"
' Legacy source: $($item.RawPath)
Public Class $safeName
    ' TODO: Migrar metodos y estado desde VB6.
End Class
"@ | Set-Content -Path $file -Encoding UTF8
            }
        }
    }
}

$projectMap = @(
    @{
        Name = "Admin"
        Vbp = "DatQBox Admin/DatQBoxAdmin.vbp"
        NetProjectDir = "src/DatqBox.Admin.Desktop"
        RootNamespace = "DatqBox.Admin.Desktop"
    },
    @{
        Name = "Compras"
        Vbp = "DatQBox Compras/DatQBoxCompras.vbp"
        NetProjectDir = "src/DatqBox.Compras.Desktop"
        RootNamespace = "DatqBox.Compras.Desktop"
    },
    @{
        Name = "PtoVenta"
        Vbp = "DatQBox PtoVenta/DatQBoxPtoVenta.vbp"
        NetProjectDir = "src/DatqBox.PtoVenta.Desktop"
        RootNamespace = "DatqBox.PtoVenta.Desktop"
    },
    @{
        Name = "Configurador"
        Vbp = "DatQBox Configurador/DatQBoxConfigurador.vbp"
        NetProjectDir = "src/DatqBox.Configurador.Desktop"
        RootNamespace = "DatqBox.Configurador.Desktop"
    }
)

$docsDir = Join-Path $TargetRoot "docs/legacy-inventory"
New-Item -ItemType Directory -Force -Path $docsDir | Out-Null

foreach ($entry in $projectMap) {
    $vbpPath = Join-Path $LegacyRoot $entry.Vbp
    if (-not (Test-Path $vbpPath)) {
        Write-Warning "No se encontro: $vbpPath"
        continue
    }

    $projectDir = Join-Path $TargetRoot $entry.NetProjectDir
    if (-not (Test-Path $projectDir)) {
        Write-Warning "No se encontro proyecto .NET: $projectDir"
        continue
    }

    $items = Get-LegacyItems -VbpPath $vbpPath
    Ensure-WinFormsEntryPoint -ProjectDir $projectDir -RootNamespace $entry.RootNamespace
    Write-Stubs -ProjectDir $projectDir -Items $items

    $inventoryFile = Join-Path $docsDir ($entry.Name + ".md")
    Write-Inventory -InventoryFile $inventoryFile -ProjectName $entry.Name -VbpPath $entry.Vbp -Items $items
}

Write-Output "Scaffold generado en: $TargetRoot"
