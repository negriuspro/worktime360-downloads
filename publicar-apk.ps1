# Publica un APK oficial de WorkTime 360 como release de GitHub.
# El archivo siempre se llama WorkTime360.apk, así el enlace estable
#   https://github.com/negriuspro/worktime360-downloads/releases/latest/download/WorkTime360.apk
# descarga la versión más reciente.
param(
  [Parameter(Mandatory = $true)][string]$Apk,
  [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
  [string]$Notas = ''
)
$ErrorActionPreference = 'Stop'
$repo = 'negriuspro/worktime360-downloads'

if (-not (Test-Path -LiteralPath $Apk -PathType Leaf)) { throw "No existe el APK: $Apk" }
if ([IO.Path]::GetExtension($Apk) -ne '.apk') { throw "El archivo no es un .apk: $Apk" }

# Copia con el nombre fijo en una carpeta temporal propia (el original no se toca).
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("wt360-release-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$destino = Join-Path $tmp 'WorkTime360.apk'
Copy-Item -LiteralPath $Apk -Destination $destino

$sha = (Get-FileHash -LiteralPath $destino -Algorithm SHA256).Hash.ToLower()
$mb = [math]::Round((Get-Item -LiteralPath $destino).Length / 1MB, 1)
$cuerpo = @"
WorkTime 360 $Version para Android.

$Notas

- Archivo: WorkTime360.apk ($mb MB)
- SHA-256: ``$sha``

Comprueba la huella antes de instalar (ver README).
"@
$notasArchivo = Join-Path $tmp 'notas.md'
# UTF-8 sin BOM (Set-Content -Encoding utf8 de PowerShell 5.1 añade BOM y se ve en las notas).
[IO.File]::WriteAllText($notasArchivo, $cuerpo, (New-Object Text.UTF8Encoding $false))

gh release create "v$Version" $destino --repo $repo --title "WorkTime 360 $Version" --notes-file $notasArchivo --latest
if ($LASTEXITCODE -ne 0) { throw "gh release create falló ($LASTEXITCODE)" }

Write-Host "Publicado v$Version"
Write-Host "SHA-256: $sha"
Write-Host "Enlace estable: https://github.com/$repo/releases/latest/download/WorkTime360.apk"
Write-Host "Copia temporal en $tmp (se puede enviar a la Papelera)."
