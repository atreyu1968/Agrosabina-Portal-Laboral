# AGROSABINA Portal Laboral

Repositorio de **AGROSABINA, S.L.** para el Portal Laboral, PRL, formación, documentación de trabajadores y gestión integrada de evidencias GLOBALG.A.P./OPP.

## Estado actual de distribución

La distribución v2.5 está publicada en `main` en partes verificables bajo:

```text
dist/v2.5/part00.b64
...
dist/v2.5/part07.b64
```

El instalador de consola está en:

```text
installers/Agrosabina_instalador_github_v2.5.sh
```

El paquete reconstruido debe tener exactamente este SHA-256:

```text
b17529dd652403ca1b3f84613a89c7e63514557fb04372af6550a4e73f2bb0b5
```

## Requisitos

- Ubuntu con acceso `root` o `sudo`.
- Conexión a Internet.
- `curl` y certificados CA para la descarga inicial.
- Cloudflare Tunnel solo si se desea publicar el portal mediante un hostname HTTPS.
- Si el repositorio se vuelve privado, un PAT de GitHub con acceso al repositorio y permiso `Contents: Read`.

No es necesario instalar previamente Docker, Docker Compose, Git ni `cloudflared`; el instalador se ocupa de ello.

# 1. Descargar e instalar desde la consola del servidor

## Opción A — repositorio público: recomendada en el estado actual

Actualmente el repositorio permite descargar el instalador sin autenticación. En un Ubuntu limpio ejecutar:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
```

Descargar el instalador directamente desde `main`:

```bash
curl -fsSL \
  "https://raw.githubusercontent.com/atreyu1968/Agrosabina-Portal-Laboral/main/installers/Agrosabina_instalador_github_v2.5.sh" \
  -o Agrosabina_instalador_github_v2.5.sh
```

Comprobar que existe y empieza por un `shebang` Bash:

```bash
ls -lh Agrosabina_instalador_github_v2.5.sh
head -n 3 Agrosabina_instalador_github_v2.5.sh
```

Dar permisos y ejecutar:

```bash
chmod +x Agrosabina_instalador_github_v2.5.sh
sudo ./Agrosabina_instalador_github_v2.5.sh
```

El instalador descargará las ocho partes de `dist/v2.5/`, reconstruirá el ZIP, verificará su SHA-256 y **cancelará la instalación si no coincide** con el valor esperado.

## Opción B — si el repositorio se cambia a privado

No se debe escribir el PAT directamente en el historial del shell. Introducirlo de forma oculta:

```bash
read -rsp "GitHub PAT (Contents: Read): " GH_PAT
echo
```

Comprobar primero que el PAT es válido:

```bash
curl -fsSL \
  -H "Authorization: Bearer ${GH_PAT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user | grep '"login"'
```

Si esta comprobación devuelve `401`, el PAT está vacío, es incorrecto o ha caducado y no debe continuarse.

Descargar el instalador del repositorio privado:

```bash
curl -fsSL \
  -H "Authorization: Bearer ${GH_PAT}" \
  -H "Accept: application/vnd.github.raw+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/atreyu1968/Agrosabina-Portal-Laboral/contents/installers/Agrosabina_instalador_github_v2.5.sh?ref=main" \
  -o Agrosabina_instalador_github_v2.5.sh
```

Guardar temporalmente el PAT para que el instalador pueda descargar las partes privadas:

```bash
printf '%s' "$GH_PAT" | sudo tee /root/.agrosabina-github-token.tmp >/dev/null
sudo chmod 600 /root/.agrosabina-github-token.tmp
unset GH_PAT
```

Ejecutar:

```bash
chmod +x Agrosabina_instalador_github_v2.5.sh
sudo ./Agrosabina_instalador_github_v2.5.sh \
  --github-token-file /root/.agrosabina-github-token.tmp
```

Al terminar:

```bash
sudo rm -f /root/.agrosabina-github-token.tmp
```

# 2. Opciones de instalación

## URL pública HTTPS

```bash
sudo ./Agrosabina_instalador_github_v2.5.sh \
  --public-url https://portal.ejemplo.es
```

## Sin Cloudflare

```bash
sudo ./Agrosabina_instalador_github_v2.5.sh --no-cloudflare
```

Por defecto el portal escucha en:

```text
http://IP_DEL_SERVIDOR:8088
```

## Omitir `apt upgrade`

```bash
sudo ./Agrosabina_instalador_github_v2.5.sh --skip-system-upgrade
```

## Cambiar puerto

```bash
sudo ./Agrosabina_instalador_github_v2.5.sh --port 8088
```

# 3. Cloudflare Tunnel

Si se proporciona un Tunnel Token, el instalador configura `cloudflared`. El hostname público debe dirigir al servicio local, normalmente:

```text
http://localhost:8088
```

Ejemplo con fichero de token protegido:

```bash
sudo ./Agrosabina_instalador_github_v2.5.sh \
  --public-url https://portal.ejemplo.es \
  --cloudflare-token-file /root/cloudflare-token.txt
```

Borrar el fichero de token una vez registrado correctamente el servicio.

# 4. Comprobaciones tras instalar

```bash
cd /opt/agrosabina-portal
sudo docker compose ps
curl http://127.0.0.1:8088/health
sudo systemctl status docker
```

Si se usa Cloudflare:

```bash
sudo systemctl status cloudflared
```

Logs:

```bash
cd /opt/agrosabina-portal
sudo docker compose logs --tail=200
```

# 5. Publicación y actualizaciones posteriores

Una vez comprobada la instalación completa:

```bash
sudo agrosabina-publish-github
```

El publicador debe excluir `.env`, bases de datos, documentos laborales, nóminas, firmas, backups, tokens y claves privadas.

Solo después de verificar que la publicación remota coincide con la instalación local debe utilizarse:

```bash
sudo agrosabina-update
```

# 6. Desinstalación

```bash
sudo agrosabina-uninstall
```

Antes de eliminar una instalación en producción, crear y verificar una copia de seguridad.

# 7. Seguridad

Nunca deben versionarse:

```text
.env
.env.*
data/
documents/
certificates/
backups/
logs/
*.sqlite
*.sqlite3
*.db
*.agrobackup
Cloudflare Tunnel Token
GitHub PAT
claves privadas
datos de trabajadores
nóminas
firmas
```

El hecho de que el código fuente pueda estar visible no autoriza a publicar datos laborales o secretos. Si se desea mantener también el código privado, cambiar la visibilidad del repositorio y utilizar el procedimiento con PAT descrito arriba.

---

**AGROSABINA, S.L. — Portal Laboral**
