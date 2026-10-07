param(
    [string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_BIN)) {
        $GodotPath = $env:GODOT_BIN
    } else {
        $configPath = Join-Path $projectRoot 'project.yaml'
        $enginePathLine = Select-String -LiteralPath $configPath -Pattern '^\s*path:\s*"(.+)"\s*$' | Select-Object -First 1
        if ($enginePathLine) {
            $GodotPath = $enginePathLine.Matches[0].Groups[1].Value
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $godotCommand = Get-Command 'godot' -ErrorAction SilentlyContinue
    if ($godotCommand) {
        $GodotPath = $godotCommand.Source
    }
}

if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot executable not found. Set GODOT_BIN or pass -GodotPath; project.yaml engine.path was '$GodotPath'."
}

# Prefer the matching console binary on Windows so headless output and exit codes
# are captured. GODOT_BIN may still point to the locally installed GUI build.
$godotDirectory = Split-Path -Parent $GodotPath
$godotBaseName = [System.IO.Path]::GetFileNameWithoutExtension($GodotPath)
$consolePath = Join-Path $godotDirectory ($godotBaseName + '_console.exe')
if (Test-Path -LiteralPath $consolePath -PathType Leaf) {
    $GodotPath = $consolePath
}

& $GodotPath --headless --editor --path $projectRoot --import --quit
$importExitCode = $LASTEXITCODE
if ($importExitCode -ne 0) {
    exit $importExitCode
}

& $GodotPath --headless --path $projectRoot --script 'tests/gdunit4_runner.gd'
$testExitCode = $LASTEXITCODE
exit $testExitCode

