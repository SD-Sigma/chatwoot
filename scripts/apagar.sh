#!/usr/bin/env bash
# Chatwoot - Apagar (Linux). Detiene contenedores, conserva la BD.
set -e
cd "$(dirname "$0")/.."

echo "=== CHATWOOT - APAGAR ==="
if ! docker version >/dev/null 2>&1; then
  echo "[ERROR] Docker no esta en ejecucion."
  exit 1
fi

docker compose stop
echo
echo " Servicios detenidos. Los datos se conservan."
echo " Para volver a iniciar: ./scripts/iniciar.sh"
