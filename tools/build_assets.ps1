# Regenerates all procedural assets for Giggle 64: The Gauntlet of Fire.
# Usage: powershell -ExecutionPolicy Bypass -File tools\build_assets.ps1 -Godot "C:\path\to\Godot_v4.7.2-stable_win64.exe"
param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [string]$LogDir = "$PSScriptRoot\..\..\_giggle64_work\tmp"
)
$ErrorActionPreference = "Stop"
$project = Resolve-Path "$PSScriptRoot\.."
New-Item -ItemType Directory -Force $LogDir | Out-Null

function Run-Step([string]$name, [string[]]$godotArgs) {
    $log = Join-Path $LogDir "build_$name.log"
    Write-Host "== $name =="
    $p = Start-Process -FilePath $Godot -ArgumentList $godotArgs -RedirectStandardOutput $log -RedirectStandardError "$log.err" -Wait -NoNewWindow -PassThru
    Get-Content $log, "$log.err" | Where-Object { $_ -match "ERROR|SCRIPT ERROR|Parse Error|build_assets" } | ForEach-Object { Write-Host "  $_" }
}

Run-Step "media"   @("--headless", "--path", "`"$project`"", "--script", "res://tools/build_assets.gd", "--", "media")
Run-Step "import1" @("--headless", "--path", "`"$project`"", "--import")
Run-Step "scenes"  @("--headless", "--path", "`"$project`"", "--script", "res://tools/build_assets.gd", "--", "scenes")
# Windowed (needs a GPU): renders the gauntlet picture behind the title logo.
Run-Step "title_art" @("--path", "`"$project`"", "res://tools/render_title_art.tscn")
# Windowed too: item icons for the HUD and pause pages, from the item meshes.
Run-Step "import_icons" @("--headless", "--path", "`"$project`"", "--import")
Run-Step "icons" @("--path", "`"$project`"", "res://tools/render_icons.tscn")
Run-Step "import2" @("--headless", "--path", "`"$project`"", "--import")
Write-Host "Done."
