# Despliegue de Chatwoot (fork Sigma)

Esta guía cubre **dos cosas**:

1. **Local (Windows + Docker Desktop)** — levantar el proyecto en tu PC para desarrollar/probar.
2. **Servidor Linux + CI/CD** — clonar en un servidor y que **cada push a Git recompile y despliegue automáticamente** (BD + backend + frontend), todo con Docker.

> Versión: Chatwoot 4.5.2 · Rails 7 + Vue 3 (Vite) · Postgres (pgvector) + Redis + Sidekiq.

---

## 1. Local en tu PC (Windows + Docker Desktop)

### Requisitos
- Docker Desktop instalado y **en ejecución**.

### Pasos (ya dejados listos en este repo)
Se usa el `docker-compose.yaml` de desarrollo. Los ajustes ya aplicados:

- `.env` → `SECRET_KEY_BASE` con valor seguro generado.
- `docker-compose.override.yaml` → fija `POSTGRES_PASSWORD=postgres` para que el contenedor de BD acepte la misma contraseña que usa Rails (en `.env`).

Comandos (desde la carpeta del proyecto):

```bash
# 1) Construir imágenes (base primero -> luego rails y vite derivan de ella)
docker compose build base
docker compose build rails vite

# 2) Crear BD, cargar esquema y datos de ejemplo (incluye el usuario admin)
docker compose run --rm rails bundle exec rails db:create db:schema:load db:seed

# 3) Levantar todo
docker compose up -d

# Ver logs
docker compose logs -f rails vite
```

Abrir: **http://localhost:3000**

### Credenciales de acceso (entorno local)
El seed de desarrollo crea un SuperAdmin:

| Campo        | Valor             |
|--------------|-------------------|
| **Usuario**  | `john@acme.inc`   |
| **Password** | `Password1!`      |

> Panel de super-admin: http://localhost:3000/super_admin (mismas credenciales).
> Correos salientes en desarrollo se capturan en **Mailhog**: http://localhost:8025

### Comandos útiles (local)
```bash
docker compose ps                 # estado
docker compose stop               # parar
docker compose down               # parar y borrar contenedores (mantiene volúmenes/BD)
docker compose down -v            # ⚠ borra también la BD
docker compose run --rm rails bundle exec rails c   # consola Rails
```

### Contraseñas usadas en local
| Servicio | Usuario   | Password   |
|----------|-----------|------------|
| Postgres | `postgres`| `postgres` |
| Redis    | —         | (sin password) |

---

## 2. Servidor Linux — preparación

Probado en Ubuntu 22.04/24.04 (Debian similar).

```bash
# Docker + Compose plugin
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER     # re-loguéate después
sudo apt-get install -y git rsync

docker --version
docker compose version
```

### Clonar el repositorio
```bash
sudo mkdir -p /opt/chatwoot
sudo chown $USER:$USER /opt/chatwoot
git clone -b master-sigma <URL_DE_TU_REPO_GIT> /opt/chatwoot
cd /opt/chatwoot
```

---

## 3. Configurar el entorno de producción

### 3.1 Crear el `.env` de producción
```bash
cp .env.example .env
```

Edita `/opt/chatwoot/.env` y ajusta como mínimo:

```ini
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker

# Genera uno con: openssl rand -hex 64
SECRET_KEY_BASE=<pega_aqui_un_hex_largo>

# URL pública real (con https si usas dominio + SSL)
FRONTEND_URL=https://chat.tudominio.com

# Postgres (debe coincidir con docker-compose.prod.build.yaml)
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=<password_pg_segura>
POSTGRES_DATABASE=chatwoot_production

# Redis (puedes poner una contraseña en producción)
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=<password_redis_segura>

# SMTP real para envío de correos (ejemplo)
MAILER_SENDER_EMAIL=Soporte <soporte@tudominio.com>
SMTP_ADDRESS=smtp.tudominio.com
SMTP_PORT=587
SMTP_USERNAME=<usuario_smtp>
SMTP_PASSWORD=<password_smtp>
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
```

> ⚠ Importante: el valor de `POSTGRES_PASSWORD` del `.env` **debe ser igual** al
> `POSTGRES_PASSWORD` del servicio `postgres` en `docker-compose.prod.build.yaml`.
> Edita ahí el placeholder `CAMBIA_ESTA_PASSWORD_PG`.

### 3.2 Primer arranque (manual, una sola vez)
Usamos `docker-compose.prod.build.yaml`, que **compila tu propio código** (backend + assets de frontend) en lugar de descargar la imagen pública.

```bash
cd /opt/chatwoot
docker compose -f docker-compose.prod.build.yaml build
docker compose -f docker-compose.prod.build.yaml run --rm rails bundle exec rails db:chatwoot_prepare
docker compose -f docker-compose.prod.build.yaml up -d
```

`db:chatwoot_prepare` es idempotente: la primera vez crea la BD y carga el esquema;
en arranques posteriores solo aplica las **migraciones** nuevas.

### 3.3 Crear el usuario administrador (producción)
En producción **no** se cargan datos de ejemplo. Crea el admin de una de estas formas:

**Opción A — Asistente web (recomendado):** abre la URL pública y verás la pantalla
de "Crear cuenta de administrador". Rellena nombre, email y contraseña.

**Opción B — Por consola:**
```bash
docker compose -f docker-compose.prod.build.yaml run --rm rails bundle exec rails c
```
```ruby
u = User.new(name: 'Admin', email: 'admin@tudominio.com', password: 'CambiaEsto123!', type: 'SuperAdmin')
u.skip_confirmation!
u.save!
acc = Account.create!(name: 'Mi Empresa')
AccountUser.create!(account_id: acc.id, user_id: u.id, role: :administrator)
```

---

## 4. CI/CD — compilar y desplegar automáticamente al hacer `git push`

Estrategia: un **self-hosted runner** de GitHub Actions instalado en el servidor.
Cuando haces push a la rama de producción, el runner (que vive en el servidor)
recompila la imagen, aplica migraciones y reinicia los contenedores. Así un cambio
de **BD, backend o frontend** queda desplegado solo.

> El workflow ya está en el repo: `.github/workflows/deploy-prod.yml`.
> Usa la rama `master-sigma`; cámbiala si usas otra.

### 4.1 Instalar el runner en el servidor
En GitHub: **Repo → Settings → Actions → Runners → New self-hosted runner** (Linux x64).
Copia los comandos que te da GitHub. Quedan así (el token lo da GitHub):

```bash
sudo mkdir -p /opt/actions-runner && sudo chown $USER:$USER /opt/actions-runner
cd /opt/actions-runner
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.X.X/actions-runner-linux-x64-2.X.X.tar.gz
tar xzf actions-runner.tar.gz

# Configurar (añade las etiquetas que espera el workflow)
./config.sh --url https://github.com/<TU_USUARIO>/<TU_REPO> \
            --token <TOKEN_QUE_DA_GITHUB> \
            --labels chatwoot-prod

# Instalar como servicio (arranca solo con el servidor)
sudo ./svc.sh install
sudo ./svc.sh start
```

> El runner ejecuta Docker, así que el usuario del runner debe estar en el grupo
> `docker` (`sudo usermod -aG docker $USER` y reiniciar el servicio del runner).

### 4.2 Qué hace el workflow en cada push
1. `actions/checkout` baja el código nuevo.
2. `rsync` lo sincroniza a `/opt/chatwoot`.
3. `docker compose ... build` → recompila backend **y** assets de frontend.
4. `... run --rm rails ... db:chatwoot_prepare` → aplica migraciones de BD.
5. `... up -d` → reinicia los contenedores con la versión nueva.
6. `docker image prune -f` → limpia imágenes viejas.

### 4.3 Flujo de trabajo diario
```bash
git add .
git commit -m "mi cambio"
git push origin master-sigma     # <- esto dispara el despliegue automático
```
Sigue el progreso en GitHub → pestaña **Actions**.

> **Alternativa sin GitHub Actions** (push directo al servidor por SSH): puedes usar
> un `git hook` `post-receive` en un repo bare del servidor que ejecute los mismos
> comandos del paso 3.2. El runner de Actions es más simple de mantener y da logs.

---

## 5. (Opcional pero recomendado) Nginx + HTTPS

El contenedor `rails` publica en `127.0.0.1:3000` (solo local). Pon Nginx delante
para exponerlo con dominio y certificado SSL.

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

`/etc/nginx/sites-available/chatwoot`:
```nginx
server {
    server_name chat.tudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    client_max_body_size 100M;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/chatwoot /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d chat.tudominio.com    # emite y configura SSL
```

Recuerda dejar `FRONTEND_URL=https://chat.tudominio.com` y `FORCE_SSL=true` en `.env`.

---

## 6. Operación y problemas comunes

```bash
# Estado y logs
docker compose -f docker-compose.prod.build.yaml ps
docker compose -f docker-compose.prod.build.yaml logs -f rails sidekiq

# Reiniciar solo la web
docker compose -f docker-compose.prod.build.yaml restart rails

# Migrar manualmente
docker compose -f docker-compose.prod.build.yaml run --rm rails bundle exec rails db:chatwoot_prepare
```

| Síntoma | Causa / Solución |
|---|---|
| `password authentication failed` en Postgres | `POSTGRES_PASSWORD` del `.env` y del compose no coinciden. |
| `SECRET_KEY_BASE` vacío / error al iniciar | Define un hex largo en `.env`. |
| Cambios de frontend no aparecen | Recompila: el build vuelve a precompilar assets. Borra caché del navegador. |
| Sidekiq no procesa trabajos | Revisa que `redis` esté arriba y `REDIS_PASSWORD` coincida en `.env`. |
| Primer push no despliega | El runner self-hosted no está corriendo o le faltan las etiquetas `chatwoot-prod`. |

---

## 7. Copias de seguridad de la BD
```bash
# Backup
docker compose -f docker-compose.prod.build.yaml exec postgres \
  pg_dump -U postgres chatwoot_production > backup_$(date +%F).sql

# Restore
cat backup_YYYY-MM-DD.sql | docker compose -f docker-compose.prod.build.yaml exec -T postgres \
  psql -U postgres chatwoot_production
```
