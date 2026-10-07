param(
    [switch]$Editor
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

$godotPath = $env:GODOT_BIN
if ([string]::IsNullOrWhiteSpace($godotPath)) {
    $configPath = Join-Path $projectRoot 'project.yaml'
    $enginePathLine = Select-String -LiteralPath $configPath -Pattern '^\s*path:\s*"(.+)"\s*$' | Select-Object -First 1
    if ($enginePathLine) {
        $godotPath = $enginePathLine.Matches[0].Groups[1].Value
    }
}
if ([string]::IsNullOrWhiteSpace($godotPath)) {
    $godotCommand = Get-Command 'godot' -ErrorAction SilentlyContinue
    if ($godotCommand) {
        $godotPath = $godotCommand.Source
    }
}
if ([string]::IsNullOrWhiteSpace($godotPath) -or -not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
    throw "Godot executable not found. Set GODOT_BIN or configure project.yaml engine.path; current value was '$godotPath'."
}

$arguments = @('--path', $projectRoot)
if ($Editor) {
    $arguments += '--editor'
}
& $godotPath @arguments
exit $LASTEXITCODE
