# AGROSABINA Portal Laboral

Repositorio privado de AGROSABINA, S.L.

## Estado de distribución

La primera instalación de la versión 2.5 se realiza mediante el **instalador autocontenido verificado**. No se debe utilizar todavía este repositorio como fuente de instalación hasta que una instalación completa publique aquí el árbol de código mediante `agrosabina-publish-github`.

El instalador autocontenido comprueba antes de instalar que el paquete v2.5 embebido tiene exactamente este SHA-256:

`b17529dd652403ca1b3f84613a89c7e63514557fb04372af6550a4e73f2bb0b5`

## Publicación segura desde el servidor

Después de instalar el portal en `/opt/agrosabina-portal`, ejecutar:

```bash
sudo agrosabina-publish-github
```

El publicador solicita de forma oculta un GitHub PAT con permiso de escritura sobre este repositorio, excluye `.env`, bases de datos, documentos laborales, firmas, nóminas, copias de seguridad y demás secretos/datos persistentes, publica el código completo y verifica que el commit remoto coincide exactamente con el local.

`agrosabina-update` permanece bloqueado hasta que esa verificación finaliza correctamente.

## Seguridad

Nunca deben versionarse `.env`, datos de trabajadores, nóminas, firmas, SQLite, backups `.agrobackup`, token de Cloudflare, PAT de GitHub ni claves privadas.
