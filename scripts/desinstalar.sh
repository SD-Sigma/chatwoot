#!/usr/bin/env bash
# Chatwoot - Desinstalar (Linux). BORRA contenedores, volumenes (BD) e imagenes.
set -e
cd "$(dirname "$0")/.."

echo "================================================================"
echo "  CHATWOOT - DESINSTALAR (BORRA TODO)"
echo "----------------------------------------------------------------"
echo "  Esto eliminara:"
echo "    - Contenedores de Chatwoot"
echo "    - Volumenes (¡INCLUYE LA BASE DE DATOS!)"
echo "    - Imagenes construidas (chatwoot, chatwoot-rails, chatwoot-vite)"
echo
echo "  NO borra el codigo fuente ni tu archivo .env"
echo "================================================================"
echo

read -r -p "Escribe SI (mayusculas) para continuar: " CONF
if [ "$CONF" != "SI" ]; then
  echo "Operacion cancelada."
  exit 0
fi

if ! docker version >/dev/null 2>&1; then
  echo "[ERROR] Docker no esta en ejecucion."
  exit 1
fi

echo
echo "Eliminando contenedores y volumenes..."
docker compose down -v --remove-orphans

echo "Eliminando imagenes construidas..."
docker rmi -f chatwoot-rails:development chatwoot-vite:development chatwoot:development 2>/dev/null || true

echo
echo "================================================================"
echo "  DESINSTALACION COMPLETA."
echo "  Para volver a instalar desde cero: ./scripts/instalar.sh"
echo "================================================================"
