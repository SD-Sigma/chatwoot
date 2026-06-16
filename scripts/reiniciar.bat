@echo off
chcp 65001 >nul
cd /d "%~dp0.."
title Chatwoot - Reiniciar

echo ================================================================
echo   CHATWOOT - REINICIAR
echo ================================================================

docker version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker no esta en ejecucion. Abre Docker Desktop y reintenta.
  pause
  exit /b 1
)

echo Recreando servicios...
docker compose down
docker compose up -d
if errorlevel 1 (
  echo [ERROR] No se pudieron reiniciar los servicios.
  pause
  exit /b 1
)

echo.
echo  Reiniciado.  URL: http://localhost:3000
echo  (Espera ~30s a que Rails termine de arrancar)
pause
exit /b 0
