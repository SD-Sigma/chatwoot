# Scripts de gestión de Chatwoot (Windows y Linux)

Scripts para **instalar, iniciar, apagar, reiniciar y desinstalar** Chatwoot con Docker,
sin tener que recordar comandos. Solo clona el repo y ejecuta el script que necesites.

| Acción        | Windows                     | Linux                         |
|---------------|-----------------------------|-------------------------------|
| Instalar todo | `scripts\instalar.bat`      | `scripts/instalar.sh`         |
| Iniciar       | `scripts\iniciar.bat`       | `scripts/iniciar.sh`          |
| Apagar        | `scripts\apagar.bat`        | `scripts/apagar.sh`           |
| Reiniciar     | `scripts\reiniciar.bat`     | `scripts/reiniciar.sh`        |
| Desinstalar   | `scripts\desinstalar.bat`   | `scripts/desinstalar.sh`      |

---

## ✅ Requisitos (IMPORTANTE)

Estos scripts **NO instalan Docker**. Docker debe estar instalado y **en ejecución** antes.

### Windows
- **Docker Desktop** instalado: https://www.docker.com/products/docker-desktop/
- Docker Desktop **abierto** y con el icono en estado **"Running"** (ballena verde).
- Recomendado: WSL2 habilitado (lo configura el propio instalador de Docker Desktop).
- Recursos sugeridos en Docker Desktop: **≥ 4 GB de RAM** y **≥ 15 GB de disco libre**
  (la imagen ocupa ~3.5 GB).

### Linux
- Docker Engine + plugin Compose:
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER   # luego cierra y abre sesión
  sudo systemctl enable --now docker
  ```
- Utilidades usadas por los scripts: `bash`, `curl`, `sed`, `openssl` (vienen por defecto
  en la mayoría de distros).

> Para comprobar que Docker está listo:  `docker version`  y  `docker compose version`

---

## 🚀 Uso

### Windows
1. Abre **Docker Desktop** y espera a que diga *Running*.
2. En el Explorador, entra a la carpeta `scripts`.
3. **Doble clic** en `instalar.bat` (o clic derecho → *Ejecutar como administrador* si tu
   política de Docker lo requiere).
4. Espera a que termine (la primera vez tarda varios minutos por la construcción de imágenes).
5. Al final verás la URL y las credenciales.

### Linux
```bash
# Dar permisos de ejecución la primera vez
chmod +x scripts/*.sh

# Instalar todo desde cero
./scripts/instalar.sh
```

---

## 🔑 Acceso tras instalar

| Dato        | Valor               |
|-------------|---------------------|
| **URL**     | http://localhost:3000 |
| **Usuario** | `john@acme.inc`     |
| **Password**| `Password1!`        |

- Correos de prueba (Mailhog): http://localhost:8025
- Panel super admin: http://localhost:3000/super_admin

---

## ℹ️ Qué hace cada script

- **instalar**: comprueba Docker → crea `.env` (y genera `SECRET_KEY_BASE`) → crea el
  override de Postgres → normaliza saltos de línea de los entrypoints (LF) → construye las
  imágenes → prepara la base de datos (con el usuario admin) → levanta los servicios.
  Es **idempotente**: si lo ejecutas otra vez, no duplica datos (solo aplica migraciones).
- **iniciar**: arranca los contenedores ya construidos (`docker compose up -d`).
- **apagar**: detiene los contenedores **conservando la base de datos** (`docker compose stop`).
- **reiniciar**: recrea los contenedores (`down` + `up -d`).
- **desinstalar**: ⚠ **borra contenedores, volúmenes (BASE DE DATOS) e imágenes**. Pide
  confirmación escribiendo `SI`. No borra el código ni el `.env`.

---

## 🛠️ Problemas comunes

| Síntoma | Solución |
|---|---|
| "Docker no responde" | Abre Docker Desktop (Windows) o `sudo systemctl start docker` (Linux). |
| El contenedor `rails` se reinicia / `no such file or directory` | Vuelve a ejecutar `instalar` (normaliza los saltos de línea de los entrypoints a LF). |
| La página no carga al instante | En el primer arranque Rails tarda ~30-60 s. Reintenta o mira `docker compose logs -f rails`. |
| Quiero empezar de cero | `desinstalar` y luego `instalar`. |

> Para desplegar en un **servidor de producción con auto-compilación al hacer `git push`**,
> consulta el archivo **`DESPLIEGUE.md`** en la raíz del proyecto.
