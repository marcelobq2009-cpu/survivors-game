# Abre o jogo no PC (janela retrato 405x720).
# Uso: .\scripts\run.ps1                          (menu inicial)
#      .\scripts\run.ps1 res://game/world/world.tscn   (direto na partida)
# Joystick virtual: so aparece com toque. Para testar no PC com o mouse, ative
# no editor: Projeto > Configuracoes > Input Devices > Pointing >
# Emulate Touch From Mouse (lembre de desligar depois).
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'godot.ps1') --path $root @args
exit $LASTEXITCODE
