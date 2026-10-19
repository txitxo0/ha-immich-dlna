## Rol y objetivo

Eres un ingeniero con experiencia en Home Assistant OS y en empaquetado de contenedores. Necesito crear una **app de Home Assistant** (antes llamada "add-on"; desde Home Assistant 2026.2 se llaman "apps", pero el fichero de configuración sigue siendo `config.yaml` y la estructura de carpetas es la clásica) que empaquete el proyecto https://github.com/SemaiCZE/immich-dlna (licencia MIT), para poder probar en mi Home Assistant OS que mis TVs y reproductores DLNA pueden explorar y reproducir mi biblioteca de Immich.

Es una prueba de concepto: prioriza que funcione, sea reproducible y fácil de depurar. No hace falta publicar imágenes en ningún registro: la app se construirá localmente en el propio Home Assistant.

## Qué hace el proyecto upstream (ya verificado, no lo reinventes)

- Servidor DLNA/UPnP escrito en Python (gestionado con `uv`) que se conecta a la API de Immich. Estructura: `Timeline` y `Albums`, incluidos álbumes compartidos y timeline de pareja. Dice ser compatible con la API de álbumes de Immich v3.
- Descubrimiento por **SSDP**: multicast UDP `239.255.255.250:1900`. Servicios HTTP en el puerto `8200` (por defecto): `/health`, `/metrics` (Prometheus), `/device.xml`, `/ContentDirectory/*`, `/ConnectionManager/*`, `/media/asset/{id}` y `/media/asset/{id}/thumbnail`.
- Configuración solo por variables de entorno. Las relevantes:
  - Obligatorias: `IMMICH_URL` (si no lleva path se añade `/api`), `IMMICH_API_TOKEN` (API key de solo lectura).
  - Opcionales: `IMMICH_VERIFY_SSL` (true), `IMMICH_DLNA_HTTP_PORT` (8200), `IMMICH_DLNA_BASE_URL` (autodetectada), `IMMICH_DLNA_FRIENDLY_NAME` ("Immich DLNA"), `IMMICH_DLNA_SERVER_UUID` (autogenerado), `IMMICH_DLNA_LOG_LEVEL` (INFO).
- `immich-dlna --check-config` valida la configuración sin arrancar el servidor.
- Dockerfile upstream: `python:3.12-slim`, copia `uv` desde `ghcr.io/astral-sh/uv`, `uv sync --frozen --no-dev`, `WORKDIR /app`, `PATH` con `/app/.venv/bin`, `EXPOSE 8200`, `CMD ["immich-dlna"]`.
- El README recomienda **`--network host`** para DLNA/SSDP; con bridge/NAT el descubrimiento y las URLs de medios suelen romperse.
- El proyecto es joven (pocos commits, sin releases): **fija una versión concreta**.

## Entregable

Un repositorio de apps de Home Assistant con esta estructura, que sirva tanto para copiar la carpeta a `/addons` (app local) como para añadirlo como repositorio por URL:

```
repository.yaml
immich_dlna/
  config.yaml
  Dockerfile
  run.sh
  DOCS.md
  README.md
  translations/
    es.yaml
    en.yaml
```

### `config.yaml` (requisitos)

- `name: Immich DLNA`, `slug: immich_dlna`, `version: "0.1.0"`, `description` breve, `url` apuntando al repo upstream.
- `arch: [amd64, aarch64]`.
- `host_network: true` (imprescindible para SSDP multicast). No dependas de `ports` para la publicación; si lo declaras, que sea solo documental y comprueba en la documentación oficial cómo se comporta con `host_network`.
- `startup: application`, `boot: manual` durante las pruebas (documenta cómo pasarlo a `auto`).
- No definas `image:` (construcción local). No uses ingress (los clientes DLNA no pasan por él). No pidas `hassio_api`, `homeassistant_api` ni `map` en esta versión.
- `options` y `schema` con estas opciones (mapeadas a las variables de entorno upstream):
  - `immich_url` (`url`), obligatoria.
  - `immich_api_token` (`password`), obligatoria.
  - `verify_ssl` (`bool`, por defecto `true`).
  - `friendly_name` (`str`, por defecto `Immich DLNA`).
  - `base_url` (`str?`), opcional: sobrescribe `IMMICH_DLNA_BASE_URL`.
  - `server_uuid` (`str?`), opcional.
  - `log_level` (`list(DEBUG|INFO|WARNING|ERROR)`, por defecto `INFO`).
- Valida contra la documentación oficial vigente de apps de Home Assistant (developers.home-assistant.io, sección de configuración de apps) que cada clave y tipo del schema existe. Si dudas de algo, dilo en vez de inventarlo.

### `Dockerfile` (requisitos)

- Base `python:3.12-slim`, igual que upstream (evita problemas de musl/Alpine con wheels). Acepta `ARG BUILD_FROM=python:3.12-slim` y úsalo en el `FROM`, por si el Supervisor lo pasa.
- Descarga el código upstream **sin git**, con `ADD https://github.com/SemaiCZE/immich-dlna/archive/${IMMICH_DLNA_REF}.tar.gz`, con `ARG IMMICH_DLNA_REF` fijado a un **commit SHA o tag concreto**. Consulta cuál es el último commit estable de la rama `master` y fíjalo; no uses `master` como ref.
- Instala con `uv` siguiendo el Dockerfile upstream (`uv sync --frozen --no-dev`). Copia `uv` desde `ghcr.io/astral-sh/uv` con una versión fija.
- Instala `jq` (y nada más que sea necesario) con `apt-get ... --no-install-recommends` y limpia las listas de apt.
- No uses s6-overlay ni la imagen base de Home Assistant. Deja el `init` por defecto y dime si esto interfiere con algo.
- `ENTRYPOINT`/`CMD` ejecutan `run.sh`.

### `run.sh` (requisitos)

- `#!/bin/sh` o bash, con `set -eu`. Sin bashio (la imagen no lo trae): lee `/data/options.json` con `jq`.
- Exporta las variables `IMMICH_*` a partir de las opciones. Solo exporta las opcionales si no están vacías.
- Persistencia del UUID: si `server_uuid` está vacío, genera un UUID una sola vez, guárdalo en `/data/server_uuid` y reutilízalo en los siguientes arranques (así las TVs no ven servidores duplicados tras cada reinicio).
- Ejecuta primero `immich-dlna --check-config` y, si falla, imprime un mensaje claro en español y sale con error. Después `exec immich-dlna`.
- **Nunca** imprimas el token en los logs. Registra qué opciones se aplicaron (con el token enmascarado) y la `base_url` efectiva.
- Si `base_url` está vacío, registra una advertencia indicando que la autodetección puede elegir una interfaz equivocada en Home Assistant OS (con `host_network` el contenedor ve también las interfaces de Docker, por ejemplo `172.30.32.x`) y que, si los clientes no reproducen, hay que fijarla a `http://<IP-LAN-de-HA>:8200`.

### Idiomas

- Código, comentarios, mensajes de commit, claves de `config.yaml`, slug, nombres de variables y valores internos: en **inglés**.
- Textos visibles para el usuario (etiquetas y descripciones de opciones en `translations/es.yaml`, mensajes de log pensados para el usuario, `DOCS.md`): en **español**. `translations/en.yaml` como alternativa.

### `DOCS.md` / `README.md`

En español, breves. Incluye:
1. Qué hace la app y su estado experimental.
2. Requisitos: Immich accesible por IP/hostname de la LAN (no `localhost`), API key de solo lectura (indica cómo crearla en Immich y que se empiece con los permisos mínimos que funcionen), versión de Immich compatible con el proyecto upstream.
3. Instalación como app local (carpeta `/addons`, recargar la tienda, instalar) y como repositorio por URL.
4. Opciones, una a una.
5. Aviso de seguridad: DLNA no tiene autenticación; cualquier dispositivo de la LAN puede explorar la biblioteca expuesta (incluido el timeline de pareja). No exponer el puerto a Internet.
6. Resolución de problemas (ver plan de pruebas).

## Plan de pruebas que quiero que documentes (y que puedas ejecutar tú donde sea posible)

1. Local, sin Home Assistant: `docker build` de la carpeta `immich_dlna` y `docker run --network host` con un `options.json` de prueba montado en `/data`; comprobar `--check-config`, `GET /health`, `GET /device.xml`, `GET /metrics`.
2. En Home Assistant OS: instalar como app local, rellenar opciones, arrancar y revisar el log.
3. Descubrimiento: abrir VLC (Ver > Lista de reproducción > Red local > Universal Plug'n'Play), o Kodi, o BubbleUPnP en el móvil, y comprobar que aparece "Immich DLNA", que se ve `Timeline` y `Albums`, y que se reproduce una foto y un vídeo (probar el salto en el vídeo para validar HTTP Range).
4. Después, la TV real.
5. Si no aparece: comprobar `base_url`, colisiones en el puerto 1900/8200 con otras apps (Plex, Jellyfin, Serviio...), que el cliente esté en la misma VLAN/segmento, y que el router o el mesh no filtre multicast (IGMP snooping, aislamiento de clientes wifi).

## Restricciones

- No modifiques el código upstream; solo empaquétalo. Si hace falta un parche, explícalo y propónlo aparte.
- No inventes claves de `config.yaml` ni opciones de upstream: si algo no está en el README o en el código, no lo uses.
- Mantén la solución mínima: nada de ingress, servicios de Supervisor, discovery de Home Assistant ni integración con entidades en esta fase.
- Antes de escribir código, revisa (con las herramientas que tengas) la documentación oficial actual de apps de Home Assistant y el código fuente de `immich-dlna` (puerto, cómo autodetecta la `base_url`, cómo se genera el UUID y dependencias del `pyproject.toml`), y resume en pocas líneas cualquier discrepancia con lo que te he dado aquí.

## Cómo quiero que trabajes

1. Primero, un plan corto con los puntos dudosos que hayas encontrado en la documentación o en el código.
2. Luego, genera los ficheros.
3. Al final, una lista de lo que has verificado y de lo que **no** has podido verificar (por ejemplo, el comportamiento real en Home Assistant OS), para que yo lo pruebe.