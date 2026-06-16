#!/usr/bin/env bash
# Chatwoot - Iniciar (Linux)
set -e
cd "$(dirname "$0")/.."

echo "=== CHATWOOT - INICIAR ==="
if ! docker version >/dev/null 2>&1; then
  echo "[ERROR] Docker no esta en ejecucion. Inicia el servicio: sudo systemctl start docker"
  exit 1
fi

docker compose up -d
echo
echo " Servicios arriba.  URL: http://localhost:3000"
echo " Usuario: john@acme.inc   Password: Password1!"
echo " (Si acabas de iniciar, espera ~30s a que Rails termine de arrancar)"
