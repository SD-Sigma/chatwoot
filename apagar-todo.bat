@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   CHATWOOT - Apagar entorno (Docker)
echo ============================================
echo.

REM --- Verificar que Docker este corriendo ---
docker info >nul 2>&1
if errorlevel 1 (
  echo [AVISO] Docker no parece estar corriendo. No hay nada que apagar.
  pause
  exit /b 0
)

echo Deteniendo y apagando todos los contenedores...
docker compose down
if errorlevel 1 (
  echo.
  echo [ERROR] No se pudo apagar el entorno.
  pause
  exit /b 1
)

echo.
echo ============================================
echo   Chatwoot APAGADO
echo --------------------------------------------
echo   Los datos (base de datos, redis) se
echo   conservan en los volumenes de Docker.
echo.
echo   Para volver a arrancar: levantar-todo.bat
echo   Para BORRAR tambien los datos, ejecuta
echo   manualmente:  docker compose down -v
echo ============================================
echo.
pause
