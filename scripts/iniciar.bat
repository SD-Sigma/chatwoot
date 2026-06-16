@echo off
chcp 65001 >nul
cd /d "%~dp0.."
title Chatwoot - Iniciar

echo ================================================================
echo   CHATWOOT - INICIAR
echo ================================================================

docker version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker no esta en ejecucion. Abre Docker Desktop y reintenta.
  pause
  exit /b 1
)

echo Levantando servicios...
docker compose up -d
if errorlevel 1 (
  echo [ERROR] No se pudieron levantar los servicios.
  pause
  exit /b 1
)

echo.
echo  Servicios arriba.  URL: http://localhost:3000
echo  Usuario: john@acme.inc   Password: Password1!
echo.
echo  (Si acabas de iniciar, espera ~30s a que Rails termine de arrancar)
pause
exit /b 0
