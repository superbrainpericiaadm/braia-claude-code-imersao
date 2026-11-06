#!/usr/bin/env bash
# Gera, LOCALMENTE, os artefatos de uma versão fixada da Braia: pacotes .tar.gz/.zip
# a partir de um commit (git archive, reprodutível), SHA256SUMS e cópias dos
# instaladores com a versão e o hash já preenchidos.
# Não cria tag, não faz push, não publica nada: só grava em dist/<tag>/.
#
# Uso:   bash tools/gerar-release.sh <tag> [commit]     (ex.: v1.0.0 HEAD)
# Teste: bash tools/gerar-release.sh v0.0.0-teste && (cd dist/v0.0.0-teste && sha256sum -c SHA256SUMS)
set -euo pipefail

TAG="${1:-}"; COMMIT="${2:-HEAD}"
if ! printf '%s' "$TAG" | grep -Eq '^v[0-9][0-9A-Za-z._-]*$'; then
  echo "Uso: bash tools/gerar-release.sh <tag vX.Y.Z> [commit]" >&2; exit 2
fi
ROOT="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
cd "$ROOT"
SHA="$(git rev-parse --verify "$COMMIT^{commit}")"
if [ "$COMMIT" = "HEAD" ] && [ -n "$(git status --porcelain)" ]; then
  echo "Aviso: árvore com alterações não commitadas; o pacote usa só o commit $SHA." >&2
fi

OUT="$ROOT/dist/$TAG"
mkdir -p "$OUT"
NAME="braia-$TAG"
# git archive usa a data do commit nos metadados; gzip -n omite nome/data: mesmo commit => mesmos bytes.
git archive --format=tar --prefix="$NAME/" "$SHA" | gzip -n -9 > "$OUT/$NAME.tar.gz"
git archive --format=zip --prefix="$NAME/" "$SHA" > "$OUT/$NAME.zip"

TGZ_SUM="$(sha256sum "$OUT/$NAME.tar.gz" | cut -d' ' -f1)"
ZIP_SUM="$(sha256sum "$OUT/$NAME.zip" | cut -d' ' -f1)"

# Instaladores avulsos (para "baixar, ler, rodar") com versão e hash fixados.
git show "$SHA:install.sh" \
  | sed -e "s|^REF_FIXO=\"<TAG-A-DEFINIR>\"|REF_FIXO=\"$TAG\"|" \
        -e "s|^SHA256_FIXO=\"<SHA256-A-DEFINIR>\"|SHA256_FIXO=\"$TGZ_SUM\"|" > "$OUT/install.sh"
git show "$SHA:install.ps1" \
  | sed -e "s|^\$RefFixo    = '<TAG-A-DEFINIR>'|\$RefFixo    = '$TAG'|" \
        -e "s|^\$Sha256Fixo = '<SHA256-A-DEFINIR>'|\$Sha256Fixo = '$ZIP_SUM'|" > "$OUT/install.ps1"
grep -q "REF_FIXO=\"$TAG\"" "$OUT/install.sh" || { echo "Erro: falha ao fixar versão no install.sh" >&2; exit 1; }
grep -q "RefFixo    = '$TAG'" "$OUT/install.ps1" || { echo "Erro: falha ao fixar versão no install.ps1" >&2; exit 1; }

( cd "$OUT" && sha256sum "$NAME.tar.gz" "$NAME.zip" install.sh install.ps1 > SHA256SUMS )
echo "Commit: $SHA"
echo "Artefatos em: $OUT"
cat "$OUT/SHA256SUMS"
