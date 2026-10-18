[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('test', 'lint')]
    [string]$Target = 'test'
)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot

$wippy = if ($env:WIPPY) { $env:WIPPY } elseif ($env:WIPPY_EXE) { $env:WIPPY_EXE } else { 'wippy' }
$testConfig = if ($env:TEST_CONFIG) { $env:TEST_CONFIG } else { '.wippy.yaml' }

try {
    if ($Target -eq 'test') {
        $sourceDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
        & $wippy test --config $testConfig `
            -o "app.facade_test:source:directory=$sourceDir" `
            -o 'wippy.facade:server:default=app:gateway' `
            -o 'wippy.facade:router:default=app:api.public' `
            -o "wippy.facade:public_files:directory=$sourceDir/public/"
    } else {
        & $wippy lint --config $testConfig --level error
    }
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} catch {
    Write-Error $_
    exit 1
} finally {
    Pop-Location
}
