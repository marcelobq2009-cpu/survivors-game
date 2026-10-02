# Exporta o jogo para web em build/web/ (preset "Web", sem threads).
# Para testar localmente: .\scripts\serve-web.ps1 e abra http://localhost:8060
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $PSScriptRoot 'godot.ps1'
Push-Location $root
try {
    # Versao + hash do commit, mostrados no menu (game/build_info.gd nao vai pro git).
    $commit = 'dev'
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $hash = (git rev-parse --short HEAD 2>$null)
        if ($hash) { $commit = $hash }
        if (git status --porcelain 2>$null) { $commit = "$commit+" }
    }
    $info = "extends RefCounted`n## Gerado por scripts/build-web. Nao edite.`nconst COMMIT := `"$commit`"`n"
    [IO.File]::WriteAllText((Join-Path $root 'game\build_info.gd'), $info)

    New-Item -ItemType Directory -Force 'build\web' | Out-Null
    if (-not (Test-Path 'build\.gdignore')) { New-Item -ItemType File 'build\.gdignore' | Out-Null }
    $ErrorActionPreference = 'Continue'
    & $godot --headless --import | Out-Null
    & $godot --headless --export-release 'Web' 'build/web/index.html'
    $code = $LASTEXITCODE
    Write-Host "Build web pronta em build/web/ (commit $commit)"
} finally {
    Pop-Location
}
exit $code
