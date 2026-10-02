# Roda todos os testes GUT em modo headless (sem janela).
# Uso: .\scripts\test.ps1            (todos os testes)
#      .\scripts\test.ps1 -gtest=res://tests/test_pool.gd   (um arquivo)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $PSScriptRoot 'godot.ps1'
Push-Location $root
try {
    # Importa os assets e registra as class_name antes de testar.
    & $godot --headless --import | Out-Null
    & $godot --headless -s addons/gut/gut_cmdln.gd @args
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $code
