#!/usr/bin/env bash
# Chatwoot - Instalacion completa (Linux)
set -e
cd "$(dirname "$0")/.."

echo "================================================================"
echo "           CHATWOOT - INSTALACION COMPLETA (Linux)"
echo "================================================================"
echo " Carpeta del proyecto: $(pwd)"
echo

# 1) Comprobar Docker
echo "[1/7] Comprobando Docker..."
if ! docker version >/dev/null 2>&1; then
  echo
  echo "  [ERROR] Docker no responde. Asegurate de que:"
  echo "    - Docker esta instalado:  curl -fsSL https://get.docker.com | sh"
  echo "    - El servicio esta activo: sudo systemctl start docker"
  echo "    - Tu usuario esta en el grupo docker: sudo usermod -aG docker \$USER (re-loguea)"
  exit 1
fi
echo "      Docker OK."

# 2) .env
echo "[2/7] Preparando archivo .env..."
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "      .env creado desde .env.example"
  else
    echo "  [ERROR] No existe .env ni .env.example"; exit 1
  fi
else
  echo "      .env ya existe, se conserva."
fi

# Generar SECRET_KEY_BASE si esta por defecto o vacio
if grep -qE 'SECRET_KEY_BASE=replace_with_lengthy_secure_hex|^SECRET_KEY_BASE=\s*$' .env; then
  HEX=$(openssl rand -hex 64 2>/dev/null || head -c64 /dev/urandom | od -An -tx1 | tr -d ' \n')
  sed -i "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${HEX}|" .env
  echo "      SECRET_KEY_BASE generado."
else
  echo "      SECRET_KEY_BASE ya configurado."
fi

# 3) override de Postgres
echo "[3/7] Verificando docker-compose.override.yaml..."
if [ ! -f docker-compose.override.yaml ]; then
  cat > docker-compose.override.yaml <<'YAML'
services:
  postgres:
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
YAML
  echo "      override creado."
else
  echo "      override ya existe."
fi

# 4) Normalizar finales de linea (CRLF -> LF) en los entrypoints
echo "[4/7] Normalizando finales de linea (LF) de los entrypoints..."
for f in docker/entrypoints/rails.sh docker/entrypoints/vite.sh docker/entrypoints/helpers/pg_database_url.rb; do
  [ -f "$f" ] && sed -i 's/\r$//' "$f"
done
echo "      Entrypoints en LF."

# 5) Construir imagenes
echo "[5/7] Construyendo imagenes Docker (puede tardar varios minutos)..."
docker compose build base
docker compose build rails vite
echo "      Imagenes construidas."

# 6) Preparar base de datos
echo "[6/7] Preparando base de datos..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

# 7) Levantar
echo "[7/7] Levantando servicios..."
docker compose up -d

echo
echo " Esperando a que la aplicacion responda en http://localhost:3000 ..."
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo 000)
  case "$code" in 200|301|302) echo " Aplicacion lista."; break;; esac
  sleep 5
done

cat <<EOF

================================================================
  INSTALACION COMPLETADA
----------------------------------------------------------------
  URL:        http://localhost:3000
  Usuario:    john@acme.inc
  Password:   Password1!

  Correos de prueba (Mailhog):  http://localhost:8025
  Super admin:                  http://localhost:3000/super_admin
================================================================
EOF
