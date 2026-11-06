#!/usr/bin/env bash
# Instala a Braia (equipe de agentes do Claude Code) numa pasta local.
# Só copia arquivos de texto. Não usa sudo, não instala programas, não pede senha.
#
# Uso:
#   bash install.sh                 # instala em ~/Braia
#   bash install.sh /outra/pasta    # instala na pasta indicada
#   bash install.sh --sem-angelica  # instala sem a agente opcional Angélica
#   bash install.sh --desinstalar   # remove os arquivos da Braia (vão para backup)
#
# Variáveis opcionais:
#   BRAIA_DIR     pasta de destino (padrão: $HOME/Braia)
#   BRAIA_SOURCE  pasta local com a subpasta braia/ (padrão: ao lado deste script,
#                 ou download do GitHub quando executado via curl | bash)
#   BRAIA_REPO    repositório GitHub dono/nome (padrão abaixo)
#   BRAIA_REF     branch ou tag (padrão: main)
set -euo pipefail

BRAIA_REPO="${BRAIA_REPO:-superbrainpericiaadm/braia-claude-code-imersao}"
BRAIA_REF="${BRAIA_REF:-main}"
if [ -z "${BRAIA_DIR:-}" ] && [ -z "${HOME:-}" ]; then
  echo "Erro: HOME não definido; informe a pasta: bash install.sh /caminho" >&2; exit 1
fi
DEST="${BRAIA_DIR:-${HOME:-}/Braia}"
SEM_ANGELICA=0
DESINSTALAR=0

for arg in "$@"; do
  case "$arg" in
    --sem-angelica) SEM_ANGELICA=1 ;;
    --desinstalar) DESINSTALAR=1 ;;
    -h|--help) sed -n '2,16p' "$0" 2>/dev/null || true; exit 0 ;;
    -*) echo "Opção desconhecida: $arg" >&2; exit 2 ;;
    *) DEST="$arg" ;;
  esac
done

[ -n "$DEST" ] || { echo "Erro: pasta de destino vazia." >&2; exit 2; }

MANAGED=(
  ".claude/settings.json"
  ".claude/agents/braia.md"
  ".claude/agents/isaura.md"
  ".claude/agents/paulo.md"
  ".claude/agents/juliana.md"
  ".claude/agents/angelica.md"
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
  command -v curl >/dev/null 2>&1 || { echo "Erro: curl não encontrado." >&2; exit 1; }
  command -v tar  >/dev/null 2>&1 || { echo "Erro: tar não encontrado." >&2; exit 1; }
  TMP="$(mktemp -d)"
  URL="https://codeload.github.com/$BRAIA_REPO/tar.gz/$BRAIA_REF"
  echo "Baixando $BRAIA_REPO ($BRAIA_REF)..."
  if ! curl -fsSL "$URL" -o "$TMP/braia.tar.gz"; then
    echo "Erro: não foi possível baixar $URL (repositório privado ou sem internet?)." >&2
    exit 1
  fi
  tar -xzf "$TMP/braia.tar.gz" -C "$TMP"
  SRC="$(find "$TMP" -mindepth 2 -maxdepth 2 -type d -name braia | head -n 1)"
fi

[ -n "${SRC:-}" ] && [ -f "$SRC/.claude/agents/braia.md" ] || {
  echo "Erro: arquivos da Braia não encontrados na origem." >&2; exit 1; }
# Confere a origem inteira antes de mexer no destino (evita instalação parcial).
for rel in "${MANAGED[@]}"; do
  [ -f "$SRC/$rel" ] || { echo "Erro: origem incompleta, falta $rel." >&2; exit 1; }
done
for d in "$DEST" "$DEST/.claude" "$DEST/.claude/agents"; do
  if [ -L "$d" ]; then echo "Erro: $d é um link simbólico; use uma pasta real." >&2; exit 1; fi
done

mkdir -p "$DEST/.claude/agents"
installed=0; unchanged=0; backed=0
for rel in "${MANAGED[@]}"; do
  if [ "$SEM_ANGELICA" = 1 ] && [ "$rel" = ".claude/agents/angelica.md" ]; then
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

echo "Braia instalada em: $DEST"
echo "  arquivos novos/atualizados: $installed | já iguais: $unchanged | backups: $backed"
[ "$backed" -gt 0 ] && echo "  backup dos arquivos anteriores: $BACKUP"
echo
echo "Próximo passo:"
echo "  cd \"$DEST\" && claude"
echo "Depois escreva: Braia, quem é a sua equipe?"
