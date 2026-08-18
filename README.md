# AGROSABINA Portal Laboral — v2.5

Portal laboral, PRL y documental de **AGROSABINA, S.L.**

## Distribución recomendada

La instalación inicial se realiza mediante **un único ZIP verificado**. Se abandona el sistema anterior de distribución fragmentada en partes Base64.

Archivo oficial de esta versión:

```text
Agrosabina_Portal_Laboral_v2.5_FINAL.zip
```

SHA-256:

```text
6eff6ce26246ab0a8cc81b8deebf9b7db87742a27615fe59dd822d9eb3979757
```

**No instales el paquete si el SHA-256 obtenido no coincide exactamente.**

## Opción 1 — copiar el ZIP directamente al servidor

Es el método más sencillo para la primera instalación. Copia el ZIP al servidor por SCP, SFTP, WinSCP o equivalente.

Ejemplo desde otro equipo:

```bash
scp Agrosabina_Portal_Laboral_v2.5_FINAL.zip root@IP_DEL_SERVIDOR:/root/
```

En Ubuntu:

```bash
cd /root
sudo apt-get update
sudo apt-get install -y unzip ca-certificates curl
sha256sum Agrosabina_Portal_Laboral_v2.5_FINAL.zip
```

Debe devolver:

```text
6eff6ce26246ab0a8cc81b8deebf9b7db87742a27615fe59dd822d9eb3979757
```

Descomprimir e instalar:

```bash
rm -rf /root/Agrosabina_Portal_Laboral_v2.5
unzip Agrosabina_Portal_Laboral_v2.5_FINAL.zip -d /root/
cd /root/Agrosabina_Portal_Laboral_v2.5
chmod +x install.sh uninstall.sh update.sh bootstrap.sh
sudo ./install.sh
```

El instalador prepara Ubuntu, instala Docker Engine y Docker Compose si son necesarios, copia la aplicación a `/opt/agrosabina-portal`, genera la configuración local, construye los contenedores, comprueba `/health` y permite configurar Cloudflare Tunnel.

## Opción 2 — subir manualmente el ZIP a este repositorio

Si se desea descargar el paquete posteriormente desde la consola del servidor, subir manualmente el ZIP a esta ruta del repositorio:

```text
dist/Agrosabina_Portal_Laboral_v2.5_FINAL.zip
```

### Repositorio público

Después de haber subido el ZIP:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl unzip
cd /root
curl -fL \
  https://raw.githubusercontent.com/atreyu1968/Agrosabina-Portal-Laboral/main/dist/Agrosabina_Portal_Laboral_v2.5_FINAL.zip \
  -o Agrosabina_Portal_Laboral_v2.5_FINAL.zip
sha256sum Agrosabina_Portal_Laboral_v2.5_FINAL.zip
```

### Repositorio privado

Utiliza un PAT con permiso `Contents: Read` y evita escribirlo directamente en el historial:

```bash
read -rsp "GitHub PAT: " GH_PAT
echo

curl -fL \
  -H "Authorization: Bearer ${GH_PAT}" \
  -H "Accept: application/vnd.github.raw+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/atreyu1968/Agrosabina-Portal-Laboral/contents/dist/Agrosabina_Portal_Laboral_v2.5_FINAL.zip?ref=main" \
  -o Agrosabina_Portal_Laboral_v2.5_FINAL.zip

unset GH_PAT
sha256sum Agrosabina_Portal_Laboral_v2.5_FINAL.zip
```

El SHA-256 debe ser exactamente:

```text
6eff6ce26246ab0a8cc81b8deebf9b7db87742a27615fe59dd822d9eb3979757
```

Después:

```bash
rm -rf /root/Agrosabina_Portal_Laboral_v2.5
unzip Agrosabina_Portal_Laboral_v2.5_FINAL.zip -d /root/
cd /root/Agrosabina_Portal_Laboral_v2.5
chmod +x install.sh uninstall.sh update.sh bootstrap.sh
sudo ./install.sh
```

## Opciones de instalación

URL pública HTTPS:

```bash
sudo ./install.sh --public-url https://portal.ejemplo.es
```

Sin Cloudflare Tunnel:

```bash
sudo ./install.sh --no-cloudflare
```

Sin ejecutar `apt upgrade`:

```bash
sudo ./install.sh --skip-system-upgrade
```

Puerto distinto:

```bash
sudo ./install.sh --port 8088
```

El puerto por defecto es `8088`.

## Comprobación después de instalar

```bash
cd /opt/agrosabina-portal
sudo docker compose ps
curl -fsS http://127.0.0.1:8088/health
```

Para consultar los logs:

```bash
cd /opt/agrosabina-portal
sudo docker compose logs --tail=200
```

Si se utiliza Cloudflare Tunnel:

```bash
sudo systemctl status cloudflared
```

## Cloudflare Tunnel

El hostname configurado en Cloudflare debe publicar:

```text
http://localhost:8088
```

El token del túnel no debe guardarse en `.env`, GitHub ni en las copias de seguridad del portal.

## Acceso inicial

La configuración local se crea en:

```text
/opt/agrosabina-portal/.env
```

La contraseña inicial de `/admin` de esta distribución es:

```text
19631965
```

Debe cambiarse después de comprobar que la instalación funciona correctamente.

## Actualizaciones desde GitHub

`agrosabina-update` solo debe utilizarse cuando el **árbol completo del código fuente** esté publicado correctamente en GitHub.

Si en el repositorio únicamente se ha subido el ZIP de distribución, **no utilices `agrosabina-update`**. En ese caso, las actualizaciones se realizan descargando un nuevo ZIP verificado y ejecutando su `install.sh`; el instalador preserva `.env`, datos persistentes, certificados y backups.

## Información sensible que nunca debe subirse

No subir al repositorio:

```text
.env
.env.*
data/ con información real
certificates/ con certificados reales
backups/
documents/
logs/
*.sqlite
*.sqlite3
*.db
*.agrobackup
tokens de Cloudflare
PAT de GitHub
claves privadas
nóminas
firmas
documentos personales de trabajadores
```

El ZIP oficial de distribución no contiene `.env` real, bases de datos de producción, tokens ni documentación personal. Los directorios persistentes incluidos están vacíos salvo los ficheros `.keep` necesarios para conservar la estructura.

## Desinstalación

```bash
sudo agrosabina-uninstall
```

Antes de eliminar una instalación en producción, realiza una copia de seguridad y comprueba que puede restaurarse.

---

**AGROSABINA, S.L. — Portal Laboral v2.5**
