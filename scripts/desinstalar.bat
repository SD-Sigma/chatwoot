@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0.."
title Chatwoot - Desinstalar

echo ================================================================
echo   CHATWOOT - DESINSTALAR (BORRA TODO)
echo ----------------------------------------------------------------
echo   Esto eliminara:
echo     - Contenedores de Chatwoot
echo     - Volumenes (¡INCLUYE LA BASE DE DATOS!)
echo     - Imagenes Docker construidas (chatwoot, chatwoot-rails, chatwoot-vite)
echo.
echo   NO borra el codigo fuente ni tu archivo .env
echo ================================================================
echo.

set /p CONF="Escribe SI (mayusculas) para continuar: "
if /i not "%CONF%"=="SI" (
  echo Operacion cancelada.
  pause
  exit /b 0
)

docker version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker no esta en ejecucion. Abre Docker Desktop y reintenta.
  pause
  exit /b 1
)

echo.
echo Eliminando contenedores y volumenes...
docker compose down -v --remove-orphans

echo Eliminando imagenes construidas...
docker rmi -f chatwoot-rails:development chatwoot-vite:development chatwoot:development 2>nul

echo.
echo ================================================================
echo   DESINSTALACION COMPLETA.
echo   Para volver a instalar desde cero: instalar.bat
echo ================================================================
pause
exit /b 0
