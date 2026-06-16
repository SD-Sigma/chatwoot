@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   CHATWOOT - Levantar entorno (Docker)
echo ============================================
echo.

REM --- 1. Verificar que Docker este corriendo ---
echo [1/3] Verificando Docker...
docker info >nul 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Docker no esta corriendo.
  echo         Abre Docker Desktop, espera a que inicie y vuelve a ejecutar este .bat
  echo.
  pause
  exit /b 1
)
echo       Docker OK.
echo.

REM --- 2. Si es la primera vez, construir imagenes y preparar la base de datos ---
if not exist ".docker_setup_done" (
  echo [2/3] Primera vez detectada: montando el entorno...
  echo.
  echo       - Construyendo imagenes ^(puede tardar varios minutos^)...
  docker compose build
  if errorlevel 1 (
    echo.
    echo [ERROR] Fallo la construccion de las imagenes.
    pause
    exit /b 1
  )

  echo       - Preparando la base de datos ^(crear + migrar + seed^)...
  docker compose run --rm rails bundle exec rails db:chatwoot_prepare
  if errorlevel 1 (
    echo.
    echo [ERROR] Fallo la preparacion de la base de datos.
    pause
    exit /b 1
  )

  echo montado> ".docker_setup_done"
  echo       Entorno montado correctamente.
) else (
  echo [2/3] El entorno ya esta montado: solo se arrancara.
)
echo.

REM --- 3. Arrancar todos los contenedores ---
echo [3/3] Arrancando contenedores...
docker compose up -d
if errorlevel 1 (
  echo.
  echo [ERROR] No se pudieron levantar los contenedores.
  pause
  exit /b 1
)

echo.
echo ============================================
echo   Chatwoot LEVANTADO
echo --------------------------------------------
echo   App      : http://localhost:3000
echo   Vite     : http://localhost:3036
echo   Mailhog  : http://localhost:8025
echo ============================================
echo.
docker compose ps
echo.
echo (La app puede tardar ~1 min en responder mientras Rails arranca)
pause
