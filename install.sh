#!/usr/bin/env bash
# Instala a Braia como AGENTE do Claude Code (nível de usuário, em ~/.claude):
# comando /braia + subagentes isaura, paulo, juliana, angelica. Vale em qualquer pasta.
# Só copia arquivos de texto. Não usa sudo, não altera o PATH, não envia dados.
#
# Uso (caminho recomendado: baixar, ler e só então rodar):
#   bash install.sh                 # instala em ~/.claude (ou $CLAUDE_CONFIG_DIR)
#   bash install.sh /outra/pasta    # instala na pasta de configuração indicada
#   bash install.sh --sem-angelica  # instala sem a agente opcional Angélica
#   bash install.sh --desinstalar   # remove os arquivos da Braia (vão para backup)
#
# Origem dos arquivos, nesta ordem:
#   1. BRAIA_SOURCE  pasta local com a subpasta braia/
#   2. a pasta braia/ ao lado deste script (pacote baixado e extraído)
#   3. pacote da versão FIXADA (tag ou SHA, nunca main), conferido por SHA256
#      antes de extrair; aborta se o hash divergir.
# Variáveis do modo 3:
#   BRAIA_REF      tag (ex.: v1.0.0) ou SHA completo de 40 caracteres
#   BRAIA_SHA256   SHA256 esperado do pacote .tar.gz (64 hex)
#   BRAIA_ARCHIVE  pacote .tar.gz já baixado (dispensa download)
#   BRAIA_URL      endereço do pacote (padrão: asset da Release da tag)
#   BRAIA_DIR      pasta de destino (padrão: $CLAUDE_CONFIG_DIR ou $HOME/.claude)
set -euo pipefail

# Preenchidos por tools/gerar-release.sh na cópia publicada; vazios aqui de propósito.
REF_FIXO="<TAG-A-DEFINIR>"
SHA256_FIXO="<SHA256-A-DEFINIR>"
BRAIA_REPO="${BRAIA_REPO:-superbrainpericiaadm/braia-claude-code-imersao}"
if [ -z "${BRAIA_DIR:-}" ] && [ -z "${HOME:-}" ]; then
  echo "Erro: HOME não definido; informe a pasta: bash install.sh /caminho" >&2; exit 1
fi
DEST="${BRAIA_DIR:-${CLAUDE_CONFIG_DIR:-${HOME:-}/.claude}}"
SEM_ANGELICA=0
DESINSTALAR=0

for arg in "$@"; do
  case "$arg" in
    --sem-angelica) SEM_ANGELICA=1 ;;
    --desinstalar) DESINSTALAR=1 ;;
    -h|--help) sed -n '2,21p' "$0" 2>/dev/null || true; exit 0 ;;
    -*) echo "Opção desconhecida: $arg" >&2; exit 2 ;;
    *) DEST="$arg" ;;
  esac
done

[ -n "$DEST" ] || { echo "Erro: pasta de destino vazia." >&2; exit 2; }

MANAGED=(
  "commands/braia.md"
  "agents/braia.md"
  "agents/isaura.md"
  "agents/paulo.md"
  "agents/juliana.md"
  "agents/angelica.md"
)

STAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP="$DEST/.braia-backup/$STAMP"

# Existe como arquivo ou como link (inclusive quebrado): deve ir para o backup,
# para que cp nunca escreva através de um symlink fora da pasta da Braia.
present() { [ -e "$DEST/$1" ] || [ -L "$DEST/$1" ]; }

backup_file() {
  local rel="$1"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  mv "$DEST/$rel" "$BACKUP/$rel"
}

if [ "$DESINSTALAR" = 1 ]; then
  removed=0
  for rel in "${MANAGED[@]}"; do
    if present "$rel"; then backup_file "$rel"; removed=$((removed+1)); fi
  done
  if [ "$removed" -gt 0 ]; then
    echo "Braia removida de $DEST ($removed arquivos movidos para $BACKUP)."
  else
    echo "Nenhum arquivo da Braia encontrado em $DEST."
  fi
  echo "Seus outros arquivos na pasta não foram tocados."
  exit 0
fi

TMP=""
cleanup() { if [ -n "$TMP" ]; then rm -rf "$TMP"; fi; }
trap cleanup EXIT

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "${BRAIA_SOURCE:-}" ]; then
  SRC="$BRAIA_SOURCE/braia"
elif [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/braia/.claude/agents" ]; then
  SRC="$SCRIPT_DIR/braia"
else
  REF="${BRAIA_REF:-$REF_FIXO}"
  SUM="${BRAIA_SHA256:-$SHA256_FIXO}"
  case "$REF" in
    "<TAG-A-DEFINIR>"|"") echo "Erro: versão não fixada (BRAIA_REF). Use uma tag ou SHA; nunca main." >&2; exit 3 ;;
    main|master|HEAD|develop) echo "Erro: '$REF' é um branch móvel; use uma tag ou SHA completo." >&2; exit 3 ;;
  esac
  if ! printf '%s' "$REF" | grep -Eq '^(v[0-9][0-9A-Za-z._-]*|[0-9a-f]{40})$'; then
    echo "Erro: BRAIA_REF inválido ('$REF'): use tag vX.Y.Z ou SHA de 40 caracteres." >&2; exit 3
  fi
  SUM="$(printf '%s' "$SUM" | tr 'A-F' 'a-f')"
  if ! printf '%s' "$SUM" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "Erro: SHA256 esperado ausente ou inválido (BRAIA_SHA256)." >&2; exit 3
  fi
  if command -v sha256sum >/dev/null 2>&1; then HASHER="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then HASHER="shasum -a 256"
  else echo "Erro: sha256sum/shasum não encontrado; não é possível conferir o pacote." >&2; exit 1; fi
  command -v tar >/dev/null 2>&1 || { echo "Erro: tar não encontrado." >&2; exit 1; }
  TMP="$(mktemp -d)"
  PKG="$TMP/braia.tar.gz"
  if [ -n "${BRAIA_ARCHIVE:-}" ]; then
    cp "$BRAIA_ARCHIVE" "$PKG"
  else
    command -v curl >/dev/null 2>&1 || { echo "Erro: curl não encontrado." >&2; exit 1; }
    URL="${BRAIA_URL:-https://github.com/$BRAIA_REPO/releases/download/$REF/braia-$REF.tar.gz}"
    echo "Baixando $URL ..."
    if ! curl -fsSL "$URL" -o "$PKG"; then
      echo "Erro: não foi possível baixar $URL (repositório privado ou sem internet?)." >&2
      exit 1
    fi
  fi
  GOT="$($HASHER "$PKG" | cut -d' ' -f1)"
  if [ "$GOT" != "$SUM" ]; then
    echo "Erro: SHA256 do pacote não confere. Nada foi instalado." >&2
    echo "  esperado: $SUM" >&2
    echo "  obtido:   $GOT" >&2
    exit 4
  fi
  echo "SHA256 conferido: $GOT"
  tar -xzf "$PKG" -C "$TMP"
  SRC="$(find "$TMP" -mindepth 2 -maxdepth 2 -type d -name braia | head -n 1)"
fi

SRC="${SRC:+$SRC/.claude}"
[ -n "${SRC:-}" ] && [ -f "$SRC/agents/braia.md" ] || {
  echo "Erro: arquivos da Braia não encontrados na origem." >&2; exit 1; }
# Confere a origem inteira antes de mexer no destino (evita instalação parcial).
for rel in "${MANAGED[@]}"; do
  [ -f "$SRC/$rel" ] || { echo "Erro: origem incompleta, falta $rel." >&2; exit 1; }
done
for d in "$DEST" "$DEST/agents" "$DEST/commands"; do
  if [ -L "$d" ]; then echo "Erro: $d é um link simbólico; use uma pasta real." >&2; exit 1; fi
done

mkdir -p "$DEST/agents" "$DEST/commands"
installed=0; unchanged=0; backed=0
for rel in "${MANAGED[@]}"; do
  if [ "$SEM_ANGELICA" = 1 ] && [ "$rel" = "agents/angelica.md" ]; then
    if present "$rel"; then backup_file "$rel"; backed=$((backed+1)); fi
    continue
  fi
  if [ -f "$DEST/$rel" ] && [ ! -L "$DEST/$rel" ] && cmp -s "$SRC/$rel" "$DEST/$rel"; then
    unchanged=$((unchanged+1)); continue
  fi
  if present "$rel"; then backup_file "$rel"; backed=$((backed+1)); fi
  cp "$SRC/$rel" "$DEST/$rel"
  installed=$((installed+1))
done

echo "Braia instalada em: $DEST (comando /braia + agentes isaura, paulo, juliana, angelica)"
echo "  arquivos novos/atualizados: $installed | já iguais: $unchanged | backups: $backed"
[ "$backed" -gt 0 ] && echo "  backup dos arquivos anteriores: $BACKUP"
echo
echo "Próximo passo (em qualquer pasta):"
echo "  claude          # abra o Claude Code (feche e abra de novo se já estava aberto)"
echo "  /braia Braia, quem é a sua equipe?"
echo "Google (Gmail, Agenda, Drive): conecte em https://claude.ai/customize/connectors,"
echo "  entre no Claude Code com a mesma conta e confira em /mcp. A Braia explica o passo a passo."
