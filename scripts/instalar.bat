@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0.."
title Chatwoot - Instalador

echo ================================================================
echo            CHATWOOT - INSTALACION COMPLETA (Windows)
echo ================================================================
echo  Carpeta del proyecto: %cd%
echo.

REM ---------------------------------------------------------------
REM 1) Comprobar que Docker esta instalado y EN EJECUCION
REM ---------------------------------------------------------------
echo [1/7] Comprobando Docker...
docker version >nul 2>&1
if errorlevel 1 (
  echo.
  echo  [ERROR] Docker no responde. Asegurate de que:
  echo    - Docker Desktop esta INSTALADO:
  echo        https://www.docker.com/products/docker-desktop/
  echo    - Docker Desktop esta ABIERTO y el icono dice "Running".
  echo.
  pause
  exit /b 1
)
echo       Docker OK.

REM ---------------------------------------------------------------
REM 2) Crear .env si no existe
REM ---------------------------------------------------------------
echo [2/7] Preparando archivo .env...
if not exist ".env" (
  if exist ".env.example" (
    copy /Y ".env.example" ".env" >nul
    echo       .env creado desde .env.example
  ) else (
    echo  [ERROR] No existe .env ni .env.example
    pause
    exit /b 1
  )
) else (
  echo       .env ya existe, se conserva.
)

REM Generar SECRET_KEY_BASE si esta con el valor por defecto o vacio
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='.env'; $c=Get-Content $f -Raw; if($c -match 'replace_with_lengthy_secure_hex' -or $c -match '(?m)^SECRET_KEY_BASE=\s*$'){ $h=-join((1..64)|ForEach-Object{'{0:x2}' -f (Get-Random -Max 256)}); $c=$c -replace '(?m)^SECRET_KEY_BASE=.*$',('SECRET_KEY_BASE='+$h); Set-Content $f $c -NoNewline; Write-Host '      SECRET_KEY_BASE generado.' } else { Write-Host '      SECRET_KEY_BASE ya configurado.' }"

REM ---------------------------------------------------------------
REM 3) Crear override de Postgres si no existe
REM ---------------------------------------------------------------
echo [3/7] Verificando docker-compose.override.yaml...
if not exist "docker-compose.override.yaml" (
  > docker-compose.override.yaml echo services:
  >> docker-compose.override.yaml echo   postgres:
  >> docker-compose.override.yaml echo     environment:
  >> docker-compose.override.yaml echo       - POSTGRES_DB=chatwoot
  >> docker-compose.override.yaml echo       - POSTGRES_USER=postgres
  >> docker-compose.override.yaml echo       - POSTGRES_PASSWORD=postgres
  echo       override creado.
) else (
  echo       override ya existe.
)

REM ---------------------------------------------------------------
REM 4) Normalizar finales de linea (CRLF -> LF) en los scripts de arranque
REM    (imprescindible en Windows o el contenedor no arranca)
REM ---------------------------------------------------------------
echo [4/7] Normalizando finales de linea (LF) de los entrypoints...
docker run --rm -v "%cd%":/app alpine sh -c "sed -i 's/\r$//' /app/docker/entrypoints/rails.sh /app/docker/entrypoints/vite.sh /app/docker/entrypoints/helpers/pg_database_url.rb" 2>nul
if errorlevel 1 (
  echo       [AVISO] No se pudo normalizar automaticamente. Si falla el arranque, revisa CRLF.
) else (
  echo       Entrypoints en LF.
)

REM ---------------------------------------------------------------
REM 5) Construir imagenes (base primero, luego rails y vite)
REM ---------------------------------------------------------------
echo [5/7] Construyendo imagenes Docker (puede tardar varios minutos)...
docker compose build base
if errorlevel 1 goto :buildfail
docker compose build rails vite
if errorlevel 1 goto :buildfail
echo       Imagenes construidas.

REM ---------------------------------------------------------------
REM 6) Preparar base de datos (crea, carga esquema y datos + usuario admin)
REM ---------------------------------------------------------------
echo [6/7] Preparando base de datos...
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
if errorlevel 1 (
  echo  [ERROR] Fallo la preparacion de la base de datos.
  pause
  exit /b 1
)

REM ---------------------------------------------------------------
REM 7) Levantar todos los servicios
REM ---------------------------------------------------------------
echo [7/7] Levantando servicios...
docker compose up -d
if errorlevel 1 (
  echo  [ERROR] No se pudieron levantar los servicios.
  pause
  exit /b 1
)

echo.
echo  Esperando a que la aplicacion responda en http://localhost:3000 ...
powershell -NoProfile -Command "for($i=0;$i -lt 60;$i++){try{$r=Invoke-WebRequest -UseBasicParsing http://localhost:3000 -TimeoutSec 3; if([int]$r.StatusCode -ge 200){exit 0}}catch{}; Start-Sleep 5}; exit 1"
if errorlevel 1 (
  echo  [AVISO] Aun no responde. Puede tardar un poco mas en el primer arranque.
  echo          Revisa los logs con: docker compose logs -f rails
) else (
  echo  Aplicacion lista.
)

echo.
echo ================================================================
echo   INSTALACION COMPLETADA
echo ----------------------------------------------------------------
echo   URL:        http://localhost:3000
echo   Usuario:    john@acme.inc
echo   Password:   Password1!
echo.
echo   Correos de prueba (Mailhog):  http://localhost:8025
echo   Super admin:                  http://localhost:3000/super_admin
echo ================================================================
echo.
pause
exit /b 0

:buildfail
echo.
echo  [ERROR] Fallo la construccion de las imagenes Docker.
echo          Revisa el mensaje de error mas arriba.
pause
exit /b 1
