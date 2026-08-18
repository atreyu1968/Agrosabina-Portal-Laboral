#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

REPOSITORY="${GITHUB_REPOSITORY:-atreyu1968/Agrosabina-Portal-Laboral}"
REF="${GITHUB_REF:-main}"
EXPECTED_SHA256="b17529dd652403ca1b3f84613a89c7e63514557fb04372af6550a4e73f2bb0b5"
TOKEN="${GITHUB_TOKEN:-}"
TMP=""

cleanup() {
  [[ -n "${TMP:-}" && -d "$TMP" ]] && rm -rf "$TMP"
  unset TOKEN GITHUB_TOKEN || true
}
trap cleanup EXIT

[[ $EUID -eq 0 ]] || { echo "Ejecuta este instalador con sudo." >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
if ! command -v curl >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates curl unzip coreutils
fi

if [[ -z "$TOKEN" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "GitHub PAT de solo lectura para ${REPOSITORY}: " TOKEN
    echo
  else
    echo "Falta GITHUB_TOKEN para acceder al repositorio privado." >&2
    exit 1
  fi
fi

TMP="$(mktemp -d /tmp/agrosabina-install.XXXXXX)"
mkdir -p "$TMP/parts" "$TMP/extract"

echo "[1/4] Descargando paquete v2.5 desde GitHub privado..."
for n in 00 01 02 03 04 05 06 07; do
  url="https://api.github.com/repos/${REPOSITORY}/contents/dist/v2.5/part${n}.b64?ref=${REF}"
  curl -fsSL --retry 3 --retry-delay 2 \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github.raw+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$url" -o "$TMP/parts/part${n}.b64"
done

cat "$TMP"/parts/part*.b64 | tr -d '\r\n' | base64 -d > "$TMP/agrosabina-v2.5.zip"

actual="$(sha256sum "$TMP/agrosabina-v2.5.zip" | awk '{print $1}')"
if [[ "$actual" != "$EXPECTED_SHA256" ]]; then
  echo "ERROR: SHA-256 incorrecto." >&2
  echo "Esperado: $EXPECTED_SHA256" >&2
  echo "Obtenido: $actual" >&2
  exit 1
fi

echo "[2/4] Integridad verificada: ${EXPECTED_SHA256}"
unzip -q "$TMP/agrosabina-v2.5.zip" -d "$TMP/extract"
APP_DIR="$TMP/extract/Agrosabina_Portal_Laboral_v2.5"
[[ -x "$APP_DIR/install.sh" || -f "$APP_DIR/install.sh" ]] || { echo "No se encontró install.sh en el paquete." >&2; exit 1; }
chmod +x "$APP_DIR/install.sh"

# El token solo se usa para la descarga del repositorio privado; no se pasa al portal.
unset TOKEN GITHUB_TOKEN

echo "[3/4] Lanzando instalador completo de AGROSABINA..."
cd "$APP_DIR"
GITHUB_REPOSITORY="$REPOSITORY" GITHUB_BRANCH="$REF" ./install.sh "$@"

echo "[4/4] Instalación finalizada."
