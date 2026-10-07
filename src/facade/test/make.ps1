param([ValidateSet('test', 'lint')][string]$Target = 'test')
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $runner = if ($env:WIPPY_EXE) { $env:WIPPY_EXE } else { 'wippy.exe' }
    $config = if ($env:TEST_CONFIG) { $env:TEST_CONFIG } else { '.wippy.yaml' }
    if ($Target -eq 'test') {
        $facadeSource = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
        if (-not (Test-Path -LiteralPath (Join-Path $facadeSource 'index.jet'))) {
            throw 'Facade source template is missing'
        }
        & $runner test --config $config `
            -o "app.facade_test:source:directory=$facadeSource" `
            -o 'wippy.facade:server:default=app:gateway' `
            -o 'wippy.facade:router:default=app:api.public' `
            -o "wippy.facade:public_files:directory=$facadeSource/public/"
    }
    else {
        & $runner lint --config $config --level error
    }
    $result = $LASTEXITCODE
}
finally {
    Pop-Location
}
exit $result
