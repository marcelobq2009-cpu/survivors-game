# Servidor local simples para testar build/web no navegador do PC.
# Uso: .\scripts\serve-web.ps1   e abra http://localhost:8060   (Ctrl+C para parar)
param([int]$Port = 8060)
$root = Join-Path (Split-Path -Parent $PSScriptRoot) 'build\web'
$types = @{
    '.html' = 'text/html'; '.js' = 'application/javascript'; '.wasm' = 'application/wasm'
    '.pck' = 'application/octet-stream'; '.png' = 'image/png'; '.json' = 'application/json'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Servindo $root em http://localhost:$Port (Ctrl+C para parar)"
try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrEmpty($path)) { $path = 'index.html' }
        $file = Join-Path $root $path
        if ((Test-Path $file -PathType Leaf) -and ((Resolve-Path $file).Path.StartsWith($root))) {
            $bytes = [IO.File]::ReadAllBytes($file)
            $ext = [IO.Path]::GetExtension($file)
            $ctx.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' }
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    }
} finally {
    $listener.Stop()
}
