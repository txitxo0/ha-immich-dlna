# Immich DLNA - Documentación (experimental)

Este paquete crea una app de Home Assistant que empaqueta el proyecto Immich-DLNA (https://github.com/SemaiCZE/immich-dlna) para pruebas locales en Home Assistant OS.

Estado: experimental. Prioriza que funcione localmente y sea fácil de depurar. No publicar imágenes en registros remotos.

Requisitos
- Immich accesible por la LAN (no "localhost"). Si la URL no incluye path, el servidor añadirá "/api" automáticamente.
- API key de Immich (solo lectura) con permisos mínimos para listar y servir activos.
- Home Assistant OS en la misma red local que los clientes DLNA para pruebas (host_network: true recomendado).

Instalación (app local)
1. Copia la carpeta `immich_dlna` a `/addons` en el host de Home Assistant.
2. En Supervisor / Apps, recarga la lista de apps y deberías ver "Immich DLNA".
3. Instala la app.
4. Rellena las opciones (immich_url, immich_api_token, ...).
5. Arranca la app y revisa el log.

Opciones
- immich_url: URL base de Immich. Obligatoria.
- immich_api_token: Token de API de Immich. Obligatoria.
- verify_ssl: Verificar el TLS upstream (true por defecto).
- friendly_name: Nombre mostrado por el servidor DLNA.
- base_url: URL pública a anunciar. Si está vacío se intentará autodetectar; fijarlo si hay problemas con la URL anunciada.
- server_uuid: UUID del servidor; si está vacío se generará y se persistirá en `/data/server_uuid`.
- log_level: Nivel de logs.

Pruebas recomendadas (resumen)
1. Local, fuera de Home Assistant: construir la imagen con `docker build .` dentro de la carpeta del addon y ejecutar con `--network host`.
2. Validar `immich-dlna --check-config` con un options.json de prueba montado en `/data`.
3. En Home Assistant: instalar la app local, rellenar opciones y revisar logs.
4. Comprobar descubrimiento en VLC/Kodi/BubbleUPnP y reproducción de foto/vídeo.

Seguridad
DLNA no tiene autenticación: cualquier dispositivo en la LAN podrá explorar la biblioteca. No exponer la app a Internet. Usa permisos restrigidos en la API key.

Limitaciones
- No se realiza integración con Home Assistant como entidades.
- No se usan ingress ni servicios del Supervisor en esta versión.

Si hay que aplicar parches al código upstream, propondré cambios separados y lo documentaré aquí.
