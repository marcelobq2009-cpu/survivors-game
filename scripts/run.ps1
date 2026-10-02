# Abre o jogo no PC (janela retrato 405x720).
# Uso: .\scripts\run.ps1                          (menu inicial)
#      .\scripts\run.ps1 res://game/world/world.tscn   (direto na partida)
# Dica: para testar o joystick com o mouse, use --emulate-touch? Nao existe;
# ative em Projeto > Configuracoes > Input Devices > Emulate Touch From Mouse.
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'godot.ps1') --path $root @args
exit $LASTEXITCODE
