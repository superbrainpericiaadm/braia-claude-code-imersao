# Instala a Braia como AGENTE do Claude Code (nível de usuário, em $HOME\.claude):
# comando /braia + subagentes isaura, paulo, juliana, angelica. Vale em qualquer pasta.
# Só copia arquivos de texto. Não pede administrador, não altera o PATH, não envia dados.
#
# Uso (caminho recomendado: baixar, ler e só então rodar):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
#   .\install.ps1 -Destino C:\Pasta    # pasta de configuração indicada (padrão: $HOME\.claude)
#   .\install.ps1 -SemAngelica         # sem a agente opcional Angélica
#   .\install.ps1 -Desinstalar         # remove os arquivos da Braia (vão para backup)
#
# Origem dos arquivos, nesta ordem: BRAIA_SOURCE; pasta braia\ ao lado do script;
# pacote .zip da versão FIXADA (tag ou SHA, nunca main), conferido por SHA256 antes
# de extrair (aborta se divergir). Variáveis do pacote: BRAIA_REF, BRAIA_SHA256,
# BRAIA_ARCHIVE (zip já baixado), BRAIA_URL. Destino: BRAIA_DIR. Ver install.sh.
# Arquivo salvo em UTF-8 com BOM para o Windows PowerShell 5.1 ler os acentos.
param(
  [string]$Destino = $(if ($env:BRAIA_DIR) { $env:BRAIA_DIR } elseif ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }),
  [switch]$SemAngelica,
  [switch]$Desinstalar
)
$ErrorActionPreference = 'Stop'

# Preenchidos por tools/gerar-release.sh na cópia publicada; vazios aqui de propósito.
$RefFixo    = '<TAG-A-DEFINIR>'
$Sha256Fixo = '<SHA256-A-DEFINIR>'
$Repo = if ($env:BRAIA_REPO) { $env:BRAIA_REPO } else { 'superbrainpericiaadm/braia-claude-code-imersao' }

$Managed = @(
  'commands/braia.md',
  'agents/braia.md',
  'agents/isaura.md',
  'agents/paulo.md',
  'agents/juliana.md',
  'agents/angelica.md'
)
$Stamp  = (Get-Date -Format 'yyyyMMdd-HHmmss') + "-$PID"
$Backup = Join-Path $Destino ".braia-backup/$Stamp"

# Item existente (arquivo, pasta ou link, inclusive link quebrado) ou $null.
function Get-Present([string]$path) {
  Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
}
function Test-Link($item) {
  $item -and (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}
function Backup-File([string]$rel) {
  $target = Join-Path $Backup $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
  Move-Item -Force -LiteralPath (Join-Path $Destino $rel) -Destination $target
}
function Exit-Erro([string]$msg, [int]$code) {
  Write-Host "Erro: $msg" -ForegroundColor Red
  # Rodando como arquivo (-File): sai com código próprio. Via irm | iex: throw,
  # para não fechar a janela do PowerShell do aluno.
  if ($PSCommandPath) { exit $code }
  throw $msg
}

foreach ($d in @($Destino, (Join-Path $Destino 'agents'), (Join-Path $Destino 'commands'))) {
  if (Test-Link (Get-Present $d)) { Exit-Erro "$d é um link simbólico ou junção; use uma pasta real." 1 }
}

if ($Desinstalar) {
  $n = 0
  foreach ($rel in $Managed) {
    if (Get-Present (Join-Path $Destino $rel)) { Backup-File $rel; $n++ }
  }
  if ($n -gt 0) { Write-Host "Braia removida de $Destino ($n arquivos movidos para $Backup)." }
  else { Write-Host "Nenhum arquivo da Braia encontrado em $Destino." }
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
    $Ref = if ($env:BRAIA_REF) { $env:BRAIA_REF } else { $RefFixo }
    $Sum = if ($env:BRAIA_SHA256) { $env:BRAIA_SHA256 } else { $Sha256Fixo }
    if (-not $Ref -or $Ref -eq '<TAG-A-DEFINIR>') { Exit-Erro 'versão não fixada (BRAIA_REF). Use uma tag ou SHA; nunca main.' 3 }
    if (@('main', 'master', 'HEAD', 'develop') -contains $Ref) { Exit-Erro "'$Ref' é um branch móvel; use uma tag ou SHA completo." 3 }
    if ($Ref -cnotmatch '^(v[0-9][0-9A-Za-z._-]*|[0-9a-f]{40})$') { Exit-Erro "BRAIA_REF inválido ('$Ref'): use tag vX.Y.Z ou SHA de 40 caracteres." 3 }
    $Sum = $Sum.ToLowerInvariant()
    if ($Sum -notmatch '^[0-9a-f]{64}$') { Exit-Erro 'SHA256 esperado ausente ou inválido (BRAIA_SHA256).' 3 }

    $Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("braia-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $Tmp | Out-Null
    $Pkg = Join-Path $Tmp 'braia.zip'
    if ($env:BRAIA_ARCHIVE) {
      Copy-Item -LiteralPath $env:BRAIA_ARCHIVE -Destination $Pkg
    } else {
      $Url = if ($env:BRAIA_URL) { $env:BRAIA_URL } else { "https://github.com/$Repo/releases/download/$Ref/braia-$Ref.zip" }
      Write-Host "Baixando $Url ..."
      # Windows PowerShell 5.1 em .NET antigo pode não negociar TLS 1.2 (exigido pelo GitHub).
      [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
      $ProgressPreference = 'SilentlyContinue'
      try {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Pkg
      } catch {
        Exit-Erro "não foi possível baixar $Url (repositório privado ou sem internet?): $($_.Exception.Message)" 1
      }
    }
    $Got = (Get-FileHash -Algorithm SHA256 -LiteralPath $Pkg).Hash.ToLowerInvariant()
    if ($Got -ne $Sum) {
      Exit-Erro "SHA256 do pacote não confere. Nada foi instalado. esperado: $Sum obtido: $Got" 4
    }
    Write-Host "SHA256 conferido: $Got"
    Expand-Archive -LiteralPath $Pkg -DestinationPath $Tmp
    $Src = Get-ChildItem -LiteralPath $Tmp -Directory | ForEach-Object { Join-Path $_.FullName 'braia' } |
      Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  }
  if ($Src) { $Src = Join-Path $Src '.claude' }
  if (-not $Src -or -not (Test-Path -LiteralPath (Join-Path $Src 'agents/braia.md'))) {
    Exit-Erro 'arquivos da Braia não encontrados na origem.' 1
  }
  # Confere a origem inteira antes de mexer no destino (evita instalação parcial).
  foreach ($rel in $Managed) {
    if (-not (Test-Path -LiteralPath (Join-Path $Src $rel) -PathType Leaf)) { Exit-Erro "origem incompleta, falta $rel." 1 }
  }

  New-Item -ItemType Directory -Force -Path (Join-Path $Destino 'agents'), (Join-Path $Destino 'commands') | Out-Null
  $installed = 0; $unchanged = 0; $backed = 0
  foreach ($rel in $Managed) {
    $dst = Join-Path $Destino $rel
    $srcFile = Join-Path $Src $rel
    $item = Get-Present $dst
    if ($SemAngelica -and $rel -eq 'agents/angelica.md') {
      if ($item) { Backup-File $rel; $backed++ }
      continue
    }
    if ($item -and -not (Test-Link $item) -and -not $item.PSIsContainer) {
      if ((Get-FileHash -LiteralPath $srcFile).Hash -eq (Get-FileHash -LiteralPath $dst).Hash) { $unchanged++; continue }
    }
    # Link (inclusive quebrado), pasta ou arquivo diferente: vai para o backup antes da cópia,
    # para que a cópia nunca escreva através de um link fora da pasta da Braia.
    if ($item) { Backup-File $rel; $backed++ }
    Copy-Item -LiteralPath $srcFile -Destination $dst
    $installed++
  }

  Write-Host "Braia instalada em: $Destino (comando /braia + agentes isaura, paulo, juliana, angelica)"
  Write-Host "  arquivos novos/atualizados: $installed | já iguais: $unchanged | backups: $backed"
  if ($backed -gt 0) { Write-Host "  backup dos arquivos anteriores: $Backup" }
  Write-Host ''
  Write-Host 'Próximo passo (em qualquer pasta):'
  Write-Host '  claude          # abra o Claude Code (feche e abra de novo se já estava aberto)'
  Write-Host '  /braia Braia, quem é a sua equipe?'
  Write-Host 'Google (Gmail, Agenda, Drive): conecte em https://claude.ai/customize/connectors,'
  Write-Host '  entre no Claude Code com a mesma conta e confira em /mcp. A Braia explica o passo a passo.'
} finally {
  if ($Tmp -and (Test-Path -LiteralPath $Tmp)) { Remove-Item -LiteralPath $Tmp -Recurse -Force }
}
