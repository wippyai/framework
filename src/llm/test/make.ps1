param(
    [ValidateSet('test', 'lint')]
    [string]$Target = $(if ($env:MAKE_TARGET) { $env:MAKE_TARGET } else { 'test' })
)

$ErrorActionPreference = 'Stop'
$wippyCommand = $env:WIPPY_EXE
if (-not $wippyCommand) {
    $wippyCommand = (Get-Command wippy.exe -ErrorAction Stop).Source
}
if (-not (Test-Path -LiteralPath $wippyCommand -PathType Leaf)) {
    throw 'The configured wippy.exe does not exist.'
}

$configArgs = @()
if ($env:TEST_CONFIG) { $configArgs = @('--config', $env:TEST_CONFIG) }
Push-Location -LiteralPath $PSScriptRoot
try {
    if ($Target -eq 'test') {
        & $wippyCommand test @configArgs -o 'wippy.llm:process_host:default=wippy.terminal:host' -o 'wippy.llm:env_storage:default=app:env_storage'
    }
    else {
        & $wippyCommand lint @configArgs --level error
    }
    $result = $LASTEXITCODE
}
finally {
    Pop-Location
}
exit $result
