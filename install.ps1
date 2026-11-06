# Instala a Braia (equipe de agentes do Claude Code) numa pasta local.
# Só copia arquivos de texto. Não pede administrador, não instala programas, não pede senha.
#
# Uso (PowerShell):
#   .\install.ps1                      # instala em $HOME\Braia
#   .\install.ps1 -Destino C:\Pasta    # instala na pasta indicada
#   .\install.ps1 -SemAngelica         # sem a agente opcional Angélica
#   .\install.ps1 -Desinstalar         # remove os arquivos da Braia (vão para backup)
#
# Variáveis opcionais: BRAIA_DIR, BRAIA_SOURCE, BRAIA_REPO, BRAIA_REF (ver install.sh).
param(
  [string]$Destino = $(if ($env:BRAIA_DIR) { $env:BRAIA_DIR } else { Join-Path $HOME 'Braia' }),
  [switch]$SemAngelica,
  [switch]$Desinstalar
)
$ErrorActionPreference = 'Stop'

$Repo = if ($env:BRAIA_REPO) { $env:BRAIA_REPO } else { 'superbrainpericiaadm/braia-claude-code-imersao' }
$Ref  = if ($env:BRAIA_REF)  { $env:BRAIA_REF }  else { 'main' }

$Managed = @(
  '.claude/settings.json',
  '.claude/agents/braia.md',
  '.claude/agents/isaura.md',
  '.claude/agents/paulo.md',
  '.claude/agents/juliana.md',
  '.claude/agents/angelica.md'
)
$Stamp  = (Get-Date -Format 'yyyyMMdd-HHmmss') + "-$PID"
$Backup = Join-Path $Destino ".braia-backup/$Stamp"

function Backup-File([string]$rel) {
  $target = Join-Path $Backup $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
  Move-Item -Force -LiteralPath (Join-Path $Destino $rel) -Destination $target
}

if ($Desinstalar) {
  $n = 0
  foreach ($rel in $Managed) {
    if (Test-Path -LiteralPath (Join-Path $Destino $rel) -PathType Leaf) { Backup-File $rel; $n++ }
  }
  Write-Host "Braia removida de $Destino ($n arquivos movidos para $Backup)."
  Write-Host 'Seus outros arquivos na pasta não foram tocados.'
  return
}

$Tmp = $null
try {
  if ($env:BRAIA_SOURCE) {
    $Src = Join-Path $env:BRAIA_SOURCE 'braia'
  } elseif ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'braia/.claude/agents'))) {
    $Src = Join-Path $PSScriptRoot 'braia'
  } else {
    $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("braia-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    $Url = "https://codeload.github.com/$Repo/zip/$Ref"
    Write-Host "Baixando $Repo ($Ref)..."
    # Windows PowerShell 5.1 em .NET antigo pode não negociar TLS 1.2 (exigido pelo GitHub).
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile (Join-Path $Tmp 'braia.zip')
    } catch {
      throw "Não foi possível baixar $Url (repositório privado ou sem internet?): $($_.Exception.Message)"
    }
    Expand-Archive -Path (Join-Path $Tmp 'braia.zip') -DestinationPath $Tmp
    $Src = Get-ChildItem -Path $Tmp -Directory | ForEach-Object { Join-Path $_.FullName 'braia' } |
      Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $Src -or -not (Test-Path -LiteralPath (Join-Path $Src '.claude/agents/braia.md'))) {
    throw 'Arquivos da Braia não encontrados na origem.'
  }
  # Confere a origem inteira antes de mexer no destino (evita instalação parcial).
  foreach ($rel in $Managed) {
    if (-not (Test-Path -LiteralPath (Join-Path $Src $rel) -PathType Leaf)) { throw "Origem incompleta, falta $rel." }
  }

  New-Item -ItemType Directory -Force -Path (Join-Path $Destino '.claude/agents') | Out-Null
  $installed = 0; $unchanged = 0; $backed = 0
  foreach ($rel in $Managed) {
    $dst = Join-Path $Destino $rel
    $srcFile = Join-Path $Src $rel
    if ($SemAngelica -and $rel -eq '.claude/agents/angelica.md') {
      if (Test-Path -LiteralPath $dst -PathType Leaf) { Backup-File $rel; $backed++ }
      continue
    }
    if (Test-Path -LiteralPath $dst -PathType Leaf) {
      if ((Get-FileHash -LiteralPath $srcFile).Hash -eq (Get-FileHash -LiteralPath $dst).Hash) { $unchanged++; continue }
      Backup-File $rel; $backed++
    }
    Copy-Item -LiteralPath $srcFile -Destination $dst
    $installed++
  }

  Write-Host "Braia instalada em: $Destino"
  Write-Host "  arquivos novos/atualizados: $installed | já iguais: $unchanged | backups: $backed"
  if ($backed -gt 0) { Write-Host "  backup dos arquivos anteriores: $Backup" }
  Write-Host ''
  Write-Host 'Próximo passo:'
  Write-Host "  cd `"$Destino`"; claude"
  Write-Host 'Depois escreva: Braia, quem é a sua equipe?'
} finally {
  if ($Tmp -and (Test-Path -LiteralPath $Tmp)) { Remove-Item -LiteralPath $Tmp -Recurse -Force }
}
