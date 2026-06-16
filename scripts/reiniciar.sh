#!/usr/bin/env bash
# Chatwoot - Reiniciar (Linux)
set -e
cd "$(dirname "$0")/.."

echo "=== CHATWOOT - REINICIAR ==="
if ! docker version >/dev/null 2>&1; then
  echo "[ERROR] Docker no esta en ejecucion."
  exit 1
fi

docker compose down
docker compose up -d
echo
echo " Reiniciado.  URL: http://localhost:3000"
echo " (Espera ~30s a que Rails termine de arrancar)"
