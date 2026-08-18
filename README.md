# AGROSABINA Portal Laboral

Repositorio privado de **AGROSABINA, S.L.** para el Portal Laboral, PRL, formación, documentación de trabajadores y gestión integrada de evidencias GLOBALG.A.P./OPP.

## Estado de distribución

La **primera instalación** debe realizarse mediante el **instalador autocontenido verificado de la versión 2.5**. Este repositorio no debe utilizarse todavía como fuente de instalación inicial hasta que una instalación completa publique aquí el árbol de código y quede verificado mediante `agrosabina-publish-github`.

El instalador autocontenido valida antes de instalar que el paquete de aplicación embebido tiene exactamente este SHA-256:

```text
b17529dd652403ca1b3f84613a89c7e63514557fb04372af6550a4e73f2bb0b5
```

## Requisitos

- Servidor o máquina virtual con **Ubuntu**.
- Acceso `sudo`.
- Conexión a Internet durante la instalación para descargar actualizaciones, Docker y, si se utiliza, `cloudflared`.
- Para publicación posterior en este repositorio privado: un **GitHub Personal Access Token (PAT)** con permiso de escritura sobre `atreyu1968/Agrosabina-Portal-Laboral`.
- Para acceso público mediante Cloudflare Tunnel: hostname/túnel creado en Cloudflare y su **Tunnel Token**.

No es necesario instalar previamente Docker, Docker Compose, Git, curl ni cloudflared: el instalador se encarga de ello.

## 1. Primera instalación en Ubuntu

Copiar al servidor el archivo:

```text
Agrosabina_instalador_autocontenido_v2.5.sh
```

Dar permisos de ejecución:

```bash
chmod +x Agrosabina_instalador_autocontenido_v2.5.sh
```

Ejecutar como administrador:

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh
```

El instalador:

1. Extrae el paquete completo v2.5 embebido en el propio archivo.
2. Comprueba su SHA-256 antes de continuar.
3. Actualiza Ubuntu e instala las herramientas necesarias.
4. Instala Docker Engine y Docker Compose desde el repositorio oficial de Docker.
5. Instala la aplicación en `/opt/agrosabina-portal`.
6. Genera las claves y la configuración local.
7. Construye e inicia los contenedores.
8. Comprueba el endpoint `/health`.
9. Configura Cloudflare Tunnel si se proporciona un token.
10. Deja disponibles los comandos de administración.

### Instalación indicando la URL pública

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh \
  --public-url https://portal.ejemplo.es
```

La URL debe ser HTTPS para utilizar correctamente WebAuthn/passkeys y las funciones que requieren contexto seguro.

### Instalación sin Cloudflare

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh --no-cloudflare
```

El portal quedará accesible directamente en el puerto configurado, por defecto:

```text
http://IP_DEL_SERVIDOR:8088
```

### Omitir `apt upgrade`

Si no se desea realizar una actualización completa de paquetes del sistema durante la instalación:

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh --skip-system-upgrade
```

### Cambiar el puerto local

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh --port 8088
```

El puerto por defecto es `8088`.

## 2. Cloudflare Tunnel

Si durante la instalación se proporciona el Tunnel Token, el instalador instala `cloudflared` y registra el servicio de sistema.

El hostname público de Cloudflare debe dirigir al servicio local:

```text
http://localhost:8088
```

El token de Cloudflare **no se guarda en `.env` ni se incluye en los backups del portal**.

También puede pasarse mediante un fichero local protegido:

```bash
sudo ./Agrosabina_instalador_autocontenido_v2.5.sh \
  --public-url https://portal.ejemplo.es \
  --cloudflare-token-file /root/cloudflare-token.txt
```

Se recomienda borrar ese fichero una vez registrado correctamente el servicio.

## 3. Comprobaciones después de instalar

Comprobar los contenedores:

```bash
cd /opt/agrosabina-portal
sudo docker compose ps
```

Comprobar la salud de la aplicación:

```bash
curl http://127.0.0.1:8088/health
```

Comprobar Docker:

```bash
sudo systemctl status docker
```

Si se utiliza Cloudflare Tunnel:

```bash
sudo systemctl status cloudflared
```

Los registros de la aplicación pueden consultarse con:

```bash
cd /opt/agrosabina-portal
sudo docker compose logs --tail=200
```

El instalador muestra al finalizar la URL local, URL pública, acceso a `/admin`, usuario del formador y las credenciales iniciales. **Las credenciales iniciales deben cambiarse tras verificar la instalación.**

## 4. Publicar la instalación completa en este repositorio privado

La instalación inicial es independiente de GitHub. Una vez comprobado que el portal funciona correctamente, publicar el árbol de código completo ejecutando:

```bash
sudo agrosabina-publish-github
```

Si el comando todavía no está instalado, copiar al servidor `Agrosabina_publicar_GitHub_v2.5.sh` y ejecutar:

```bash
chmod +x Agrosabina_publicar_GitHub_v2.5.sh
sudo ./Agrosabina_publicar_GitHub_v2.5.sh
```

El publicador solicita de forma oculta un GitHub PAT con permiso de escritura sobre este repositorio. El PAT **no se introduce en la URL del repositorio ni se escribe en `.git/config`**.

Antes de publicar, el script excluye expresamente:

```text
.env
.env.*
data/
certificates/
backups/
documents/
logs/
*.sqlite
*.sqlite3
*.db
*.agrobackup
cloudflare-token.txt
claves privadas
PAT de GitHub
```

También realiza una búsqueda de patrones de credenciales y cancela la publicación si encuentra material sensible.

Al finalizar compara el commit remoto con el commit local. Solo si ambos SHA coinciden crea la marca local `.github-distribution-verified`.

## 5. Habilitar actualizaciones desde GitHub

Por seguridad, después de la primera instalación `agrosabina-update` permanece bloqueado hasta que el repositorio haya sido publicado y verificado correctamente.

Una vez ejecutado con éxito:

```bash
sudo agrosabina-publish-github
```

las actualizaciones posteriores se realizan con:

```bash
sudo agrosabina-update
```

El sistema conserva fuera de Git los datos persistentes y la configuración sensible.

## 6. Desinstalación

El instalador deja disponible:

```bash
sudo agrosabina-uninstall
```

Antes de eliminar una instalación en producción debe realizarse una copia de seguridad y comprobar que puede restaurarse.

## 7. Directorios y datos persistentes

La aplicación se instala por defecto en:

```text
/opt/agrosabina-portal
```

Los datos laborales, documentos, certificados, backups y secretos de ejecución **no deben versionarse nunca**.

La configuración sensible se mantiene localmente y los backups de aplicación no deben contener el token de Cloudflare ni credenciales de GitHub.

## 8. Seguridad

Este repositorio debe permanecer **privado**.

Nunca deben subirse a GitHub datos de trabajadores, nóminas, documentos firmados, certificados personales, firmas, bases SQLite, backups `.agrobackup`, `.env`, tokens de Cloudflare, PAT de GitHub ni claves privadas.

Para verificar permisos locales de los secretos:

```bash
sudo ls -l /opt/agrosabina-portal/.env
sudo ls -l /etc/agrosabina-portal/github-token 2>/dev/null || true
```

Los ficheros con secretos deben quedar accesibles únicamente por `root` o por el servicio que realmente los necesite.

## 9. Resumen del flujo recomendado

```text
Ubuntu limpio
   ↓
Instalador autocontenido v2.5
   ↓
Verificación SHA-256
   ↓
Docker + Portal + Cloudflare
   ↓
Comprobación funcional
   ↓
agrosabina-publish-github
   ↓
Verificación commit local = remoto
   ↓
agrosabina-update habilitado
```

---

**AGROSABINA, S.L. — Portal Laboral**
