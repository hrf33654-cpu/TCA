param(
	[string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
	$GodotPath = $env:GODOT_BIN
}
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
	$enginePathLine = Select-String -LiteralPath (Join-Path $projectRoot 'project.yaml') -Pattern '^\s*path:\s*"(.+)"\s*$' | Select-Object -First 1
	if ($enginePathLine) {
		$GodotPath = $enginePathLine.Matches[0].Groups[1].Value
	}
}
if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
	throw "Godot executable not found. Set GODOT_BIN, pass -GodotPath, or configure project.yaml engine.path."
}

$godotDirectory = Split-Path -Parent $GodotPath
$godotBaseName = [System.IO.Path]::GetFileNameWithoutExtension($GodotPath)
$consolePath = Join-Path $godotDirectory ($godotBaseName + '_console.exe')
if (Test-Path -LiteralPath $consolePath -PathType Leaf) {
	$GodotPath = $consolePath
}

$buildTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$buildId = "TCA-PC-prototype-$buildTimestamp"
$reportsDirectory = Join-Path $projectRoot 'reports'
$deliveryRoot = Join-Path $projectRoot 'exports/delivery'
$windowsExportDirectory = Join-Path $projectRoot 'exports/windows'
$packageRoot = Join-Path $deliveryRoot $buildId
$packageName = "$buildId.zip"
$packagePath = Join-Path $deliveryRoot $packageName

New-Item -ItemType Directory -Path $reportsDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $deliveryRoot -Force | Out-Null
New-Item -ItemType Directory -Path $windowsExportDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

$testLogPath = Join-Path $reportsDirectory "gdunit4-$buildId.log"
$testOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run_tests.ps1') 2>&1
$testExitCode = $LASTEXITCODE
$testOutput | Set-Content -LiteralPath $testLogPath -Encoding UTF8
if ($testExitCode -ne 0) {
	throw "gdUnit4 failed with exit code $testExitCode. See $testLogPath."
}

$latestReport = Get-ChildItem -LiteralPath $reportsDirectory -Directory -Filter 'report_*' |
	Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $latestReport) {
	throw 'gdUnit4 did not create an XML report.'
}
$xmlReportPath = Join-Path $latestReport.FullName 'results.xml'
if (-not (Test-Path -LiteralPath $xmlReportPath -PathType Leaf)) {
	throw "gdUnit4 XML report is missing: $xmlReportPath"
}
[xml]$xmlReport = Get-Content -LiteralPath $xmlReportPath -Raw -Encoding UTF8
$testCaseCount = $xmlReport.SelectNodes('//testcase').Count
$failureCount = [int]$xmlReport.testsuites.failures
$errorCount = [int]$xmlReport.testsuites.errors
if ($testCaseCount -lt 1 -or $failureCount -ne 0 -or $errorCount -ne 0) {
	throw "Unexpected gdUnit4 report: $testCaseCount cases, $failureCount failures, $errorCount errors."
}

$exePath = Join-Path $windowsExportDirectory 'TCA.exe'
if (Test-Path -LiteralPath $exePath -PathType Leaf) {
	Remove-Item -LiteralPath $exePath -Force
}
$exportLogPath = Join-Path $reportsDirectory "godot-export-$buildId.log"
$exportOutput = & $GodotPath --headless --path $projectRoot --export-release 'Windows Desktop' $exePath 2>&1
$exportExitCode = $LASTEXITCODE
$exportOutput | Set-Content -LiteralPath $exportLogPath -Encoding UTF8
if ($exportExitCode -ne 0 -or -not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
	throw "Windows export failed with exit code $exportExitCode. See $exportLogPath."
}

$packageExe = Join-Path $packageRoot 'TCA.exe'
Copy-Item -LiteralPath $exePath -Destination $packageExe -Force
$testingRoot = Join-Path $packageRoot 'TESTING'
New-Item -ItemType Directory -Path (Join-Path $testingRoot 'docs/qa') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $testingRoot 'design/gdd') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $testingRoot 'production/qa/evidence') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $testingRoot 'reports') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $packageRoot 'LICENSES') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/qa/full-test-flow.md') -Destination (Join-Path $testingRoot 'docs/qa/full-test-flow.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/qa/zcode-handoff-prompt.md') -Destination (Join-Path $testingRoot 'docs/qa/zcode-handoff-prompt.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'design/gdd/combat.md') -Destination (Join-Path $testingRoot 'design/gdd/combat.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'production/qa/evidence/README.md') -Destination (Join-Path $testingRoot 'production/qa/evidence/README.md') -Force
Copy-Item -LiteralPath $testLogPath -Destination (Join-Path $testingRoot 'reports/gdunit4-latest.log') -Force
Copy-Item -LiteralPath $xmlReportPath -Destination (Join-Path $testingRoot 'reports/gdunit4-results.xml') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'godot_assets/fonts/OFL.txt') -Destination (Join-Path $packageRoot 'LICENSES/NotoSansSC-OFL.txt') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/GodotEngine-MIT.txt') -Destination (Join-Path $packageRoot 'LICENSES/GodotEngine-MIT.txt') -Force

$exeHash = (Get-FileHash -LiteralPath $packageExe -Algorithm SHA256).Hash.ToLowerInvariant()
$testerReadme = @"
TCA Windows PC prototype

1. Extract this folder to a writable location.
2. Start TCA.exe. Godot Editor and the project source are not required.
3. Use the main menu to start the fixed 1v1 battle. No Steam/Epic login is used.
4. Follow TESTING/docs/qa/full-test-flow.md and record PASS, FAIL, BLOCKED, or NOT RUN for each manual case.
5. Return the completed report and original screenshots/videos/logs with the package file name and SHA-256.

Build ID: $buildId
Engine: Godot 4.6.2 stable, GDScript, Windows x86_64
Controls: click a card then use its action button; Tab/Shift+Tab moves focus; Enter/Space activates; R resolves a ready reaction; C clears reaction slots; E ends the turn; Escape opens pause.
Drag and drop into reaction slots is optional. The delivered fixture does not contain an any-target card; those cards show a target selector when present.

Known test boundary: automated tests cover logic, data loading, scene projection, direct UI signals, and restart/result projection. Physical keyboard/mouse input and a complete external battle run remain for the tester. MT-07 terminal setup cases need a QA fixture entry point and should be marked BLOCKED if no supported setup is available.

Automated checks: $testCaseCount gdUnit4 cases, $failureCount failures, $errorCount errors.
Executable SHA-256: $exeHash
"@
$testerReadme | Set-Content -LiteralPath (Join-Path $packageRoot 'README-TESTER.txt') -Encoding UTF8

$manifest = @"
Build ID: $buildId
Artifact: TCA.exe (single-file Windows x86_64 export; embedded game data)
Engine: Godot 4.6.2 stable
Language: GDScript
Target: Windows PC prototype
Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')
Automated tests: $testCaseCount cases; $failureCount failures; $errorCount errors; runner exit $testExitCode
Executable SHA-256: $exeHash
Clean-extract smoke: PENDING
External manual full-flow: NOT RUN
Performance profile: NOT MEASURED; stated budget remains provisional

This is an internal prototype build. It is not a Steam/Epic release and contains no store integration.
"@
$manifestPath = Join-Path $packageRoot 'BUILD-MANIFEST.txt'
$manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$verificationZip = Join-Path $reportsDirectory "$buildId-verification.zip"
Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $verificationZip -CompressionLevel Optimal -Force
$verificationDirectory = Join-Path $reportsDirectory "package-smoke-$buildId"
New-Item -ItemType Directory -Path $verificationDirectory -Force | Out-Null
Expand-Archive -LiteralPath $verificationZip -DestinationPath $verificationDirectory -Force
$verificationExe = Join-Path $verificationDirectory 'TCA.exe'
if (-not (Test-Path -LiteralPath $verificationExe -PathType Leaf)) {
	throw 'The clean package extraction did not contain TCA.exe.'
}
$smokeOutput = & $verificationExe --headless --quit-after 12 2>&1
$smokeExitCode = $LASTEXITCODE
$smokeLogPath = Join-Path $reportsDirectory "package-smoke-$buildId.log"
$smokeLogLines = @("Command: TCA.exe --headless --quit-after 12", "Exit code: $smokeExitCode", "Clean extraction: $verificationDirectory")
if ($smokeOutput) {
	$smokeLogLines += @('', 'Process output:', [string]::Join([Environment]::NewLine, [string[]]$smokeOutput))
} else {
	$smokeLogLines += 'Process emitted no console output.'
}
$smokeLogLines | Set-Content -LiteralPath $smokeLogPath -Encoding UTF8
if ($smokeExitCode -ne 0) {
	throw "Clean-extract launch failed with exit code $smokeExitCode. See $smokeLogPath."
}

Copy-Item -LiteralPath $smokeLogPath -Destination (Join-Path $testingRoot 'reports/clean-extract-smoke.log') -Force

$manifest = $manifest -replace 'Clean-extract smoke: PENDING', "Clean-extract smoke: PASS (headless start, 12 frames, exit $smokeExitCode)"
$manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8
if (Test-Path -LiteralPath $packagePath -PathType Leaf) {
	Remove-Item -LiteralPath $packagePath -Force
}
Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $packagePath -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
"$zipHash *$packageName" | Set-Content -LiteralPath "$packagePath.sha256" -Encoding ASCII

$archive = [System.IO.Compression.ZipFile]::OpenRead($packagePath)
try {
	$requiredEntries = @('TCA.exe', 'README-TESTER.txt', 'BUILD-MANIFEST.txt', 'TESTING/docs/qa/full-test-flow.md', 'TESTING/docs/qa/zcode-handoff-prompt.md', 'TESTING/reports/gdunit4-results.xml', 'TESTING/reports/clean-extract-smoke.log')
	$entryNames = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
	foreach ($requiredEntry in $requiredEntries) {
		if ($entryNames -notcontains $requiredEntry) {
			throw "Final package is missing required entry '$requiredEntry'."
		}
	}
}
finally {
	$archive.Dispose()
}

Write-Output "Build ID: $buildId"
Write-Output "Package: $packagePath"
Write-Output "Package SHA-256: $zipHash"
Write-Output "Executable SHA-256: $exeHash"
Write-Output "gdUnit4: $testCaseCount cases passed"
Write-Output "Clean-extract smoke: PASS"
