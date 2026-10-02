# Chama o Godot local (tools/godot/) repassando todos os argumentos.
# Uso: .\scripts\godot.ps1 --version
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = Get-ChildItem -Path (Join-Path $root 'tools\godot') -Filter 'Godot_v*_win64_console.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    Write-Error 'Godot nao encontrado em tools/godot/. Veja docs/ARCHITECTURE.md (secao Ambiente).'
}
# O executavel "console" mostra a saida no terminal e espera o Godot terminar.
& $exe.FullName @args
exit $LASTEXITCODE
