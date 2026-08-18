#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

REPOSITORY="${GITHUB_REPOSITORY:-atreyu1968/Agrosabina-Portal-Laboral}"
REF="${GITHUB_REF:-main}"
EXPECTED_SHA256="b17529dd652403ca1b3f84613a89c7e63514557fb04372af6550a4e73f2bb0b5"
TOKEN="${GITHUB_TOKEN:-}"
TOKEN_FILE=""
TMP=""
INSTALL_ARGS=()

usage() {
  cat <<'USAGE'
Instalador AGROSABINA desde GitHub.

Opciones propias:
  --github-token-file /ruta/token   PAT para repositorio privado (opcional si es público).
  --repository OWNER/REPO           Repositorio GitHub.
  --ref main                        Rama/ref de distribución.

Las demás opciones se pasan al instalador principal, por ejemplo:
  --public-url https://portal.ejemplo.es
  --no-cloudflare
  --skip-system-upgrade
  --port 8088
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github-token-file)
      [[ $# -ge 2 ]] || { echo "Falta ruta tras --github-token-file" >&2; exit 2; }
      TOKEN_FILE="$2"; shift 2;;
    --repository)
      [[ $# -ge 2 ]] || { echo "Falta OWNER/REPO tras --repository" >&2; exit 2; }
      REPOSITORY="$2"; shift 2;;
    --ref)
      [[ $# -ge 2 ]] || { echo "Falta ref tras --ref" >&2; exit 2; }
      REF="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) INSTALL_ARGS+=("$1"); shift;;
  esac
done

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

if [[ -n "$TOKEN_FILE" ]]; then
  [[ -f "$TOKEN_FILE" ]] || { echo "No existe el fichero de token: $TOKEN_FILE" >&2; exit 1; }
  TOKEN="$(tr -d '\r\n' < "$TOKEN_FILE")"
fi

TMP="$(mktemp -d /tmp/agrosabina-install.XXXXXX)"
mkdir -p "$TMP/parts" "$TMP/extract"

download_part() {
  local n="$1"
  local url="https://api.github.com/repos/${REPOSITORY}/contents/dist/v2.5/part${n}.b64?ref=${REF}"
  local out="$TMP/parts/part${n}.b64"
  local -a headers
  headers=(
    -H "Accept: application/vnd.github.raw+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
  )
  if [[ -n "$TOKEN" ]]; then
    headers+=( -H "Authorization: Bearer ${TOKEN}" )
  fi

  if ! curl -fsSL --retry 3 --retry-delay 2 "${headers[@]}" "$url" -o "$out"; then
    echo >&2
    echo "ERROR: no se pudo descargar part${n}.b64 desde ${REPOSITORY}." >&2
    if [[ -z "$TOKEN" ]]; then
      echo "Si el repositorio es privado, vuelve a ejecutar con --github-token-file /ruta/token" >&2
      echo "o define GITHUB_TOKEN con un PAT que tenga Contents: Read." >&2
    else
      echo "El PAT suministrado no es válido, ha caducado o no tiene acceso al repositorio." >&2
    fi
    exit 1
  fi
}

echo "[1/4] Descargando paquete v2.5 desde GitHub..."
for n in 00 01 02 03 04 05 06 07; do
  download_part "$n"
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
[[ -f "$APP_DIR/install.sh" ]] || { echo "No se encontró install.sh en el paquete." >&2; exit 1; }
chmod +x "$APP_DIR/install.sh"

# El token, si se utilizó, solo sirve para leer GitHub y no se pasa al portal.
unset TOKEN GITHUB_TOKEN

echo "[3/4] Lanzando instalador completo de AGROSABINA..."
cd "$APP_DIR"
GITHUB_REPOSITORY="$REPOSITORY" GITHUB_BRANCH="$REF" ./install.sh "${INSTALL_ARGS[@]}"

echo "[4/4] Instalación finalizada."
