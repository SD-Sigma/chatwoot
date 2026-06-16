@echo off
chcp 65001 >nul
cd /d "%~dp0.."
title Chatwoot - Apagar

echo ================================================================
echo   CHATWOOT - APAGAR (detiene los contenedores, conserva la BD)
echo ================================================================

docker version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker no esta en ejecucion.
  pause
  exit /b 1
)

echo Deteniendo servicios...
docker compose stop
if errorlevel 1 (
  echo [ERROR] No se pudieron detener los servicios.
  pause
  exit /b 1
)

echo.
echo  Servicios detenidos. Los datos se conservan.
echo  Para volver a iniciar usa: iniciar.bat
pause
exit /b 0
