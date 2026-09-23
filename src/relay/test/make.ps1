# Windows equivalent of the adjacent Makefile.
[CmdletBinding()]
param([ValidateSet('test', 'lint')][string]$Target = 'test')
$ErrorActionPreference = 'Stop'
$WippyExecutable = $env:WIPPY_BIN
if (-not $WippyExecutable) { $WippyExecutable = (Get-Command wippy -CommandType Application -ErrorAction Stop).Source }
Push-Location $PSScriptRoot
try {
    if ($Target -eq 'test') {
        & $WippyExecutable test -o 'wippy.relay:application_host:default=app:processes' -o 'wippy.relay:user_security_scope:default=app:user'
    } else {
        & $WippyExecutable lint --level error
    }
    if ($LASTEXITCODE -ne 0) { throw "Make target $Target failed with exit $LASTEXITCODE" }
} finally { Pop-Location }
