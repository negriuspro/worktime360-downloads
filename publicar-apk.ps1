# Publica un APK oficial de WorkTime 360 como release de GitHub.
# El archivo siempre se llama WorkTime360.apk, así el enlace estable
#   https://github.com/negriuspro/worktime360-downloads/releases/latest/download/WorkTime360.apk
# descarga la versión más reciente.
param(
  [Parameter(Mandatory = $true)][string]$Apk,
  [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
  [Parameter(Mandatory = $true)][string]$Notas,
  # Revisa todo y muestra qué se publicaría, sin publicar nada.
  [switch]$Prueba
)
$ErrorActionPreference = 'Stop'
$repo = 'negriuspro/worktime360-downloads'
$cuenta = $repo.Split('/')[0]

if (-not (Test-Path -LiteralPath $Apk -PathType Leaf)) { throw "No existe el APK: $Apk" }
if ([IO.Path]::GetExtension($Apk) -ne '.apk') { throw "El archivo no es un .apk: $Apk" }
if ($Notas -match 'Describe aqu|Qué cambió') { throw 'Escribe en -Notas qué cambió de verdad en esta versión.' }

$sha = (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash.ToLower()

# gh debe usar la cuenta dueña del repositorio; al final se deja la que estaba activa.
$anterior = (gh api user --jq .login)
if ($LASTEXITCODE -ne 0) { throw 'gh no tiene sesión iniciada (ejecuta gh auth login).' }
if ($anterior -ne $cuenta) {
  gh auth switch --user $cuenta | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "No se pudo cambiar gh a la cuenta $cuenta." }
}
try {
  # Nada de duplicados: ni la misma versión ni el mismo archivo con otro número.
  # Sin filtros jq: PowerShell 5.1 rompe las comillas al pasarlas a gh. Se filtra aquí.
  # Cualquier fallo de gh detiene el script: nunca se publica sin haber podido revisar.
  $json = gh api "repos/$repo/releases?per_page=100"
  if ($LASTEXITCODE -ne 0) { throw "No se pudo leer la lista de versiones de $repo." }
  $releases = @($json | Out-String | ConvertFrom-Json)
  $tags = gh api "repos/$repo/tags?per_page=100" --jq '.[].name'
  if ($LASTEXITCODE -ne 0) { throw "No se pudieron leer las etiquetas de $repo." }
  if ((@($releases | ForEach-Object { $_.tag_name }) + @($tags)) -contains "v$Version") {
    throw "La versión v$Version ya existe (publicada, en borrador o como etiqueta)."
  }
  $publicado = @($releases | Where-Object { $_.body -like "*$sha*" } | ForEach-Object { $_.tag_name })
  if ($publicado.Count -gt 0) { throw "Este mismo APK ya está publicado como $($publicado -join ', '). Compila la versión nueva primero." }

  $mb = [math]::Round((Get-Item -LiteralPath $Apk).Length / 1MB, 1)
  Write-Host "Versión: v$Version  |  $mb MB  |  SHA-256: $sha"
  if ($Prueba) { Write-Host 'Modo prueba: todo correcto, no se publicó nada.'; return }

  # Copia con el nombre fijo en una carpeta temporal propia (el original no se toca).
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('wt360-release-' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  $destino = Join-Path $tmp 'WorkTime360.apk'
  Copy-Item -LiteralPath $Apk -Destination $destino
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
  Write-Host "Enlace estable: https://github.com/$repo/releases/latest/download/WorkTime360.apk"
  Write-Host "Copia temporal en $tmp (se puede enviar a la Papelera)."
} finally {
  if ($anterior -ne $cuenta) { gh auth switch --user $anterior | Out-Null }
}
