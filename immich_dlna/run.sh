#!/bin/sh
set -eu

DATA_DIR="/data"
OPTIONS_FILE="$DATA_DIR/options.json"

mask_token() {
  token="$1"
  if [ -z "$token" ]; then
    echo ""
  else
    echo "********"
  fi
}

if [ ! -f "$OPTIONS_FILE" ]; then
  echo "No options.json found at $OPTIONS_FILE. Create one with the add-on options."
  exit 1
fi

# Read options with jq
IMMICH_URL=$(jq -r '.immich_url // empty' "$OPTIONS_FILE")
IMMICH_API_TOKEN=$(jq -r '.immich_api_token // empty' "$OPTIONS_FILE")
IMMICH_VERIFY_SSL=$(jq -r 'if has("verify_ssl") then (.verify_ssl | tostring) else "true" end' "$OPTIONS_FILE")
IMMICH_FRIENDLY_NAME=$(jq -r '.friendly_name // "Immich DLNA"' "$OPTIONS_FILE")
IMMICH_BASE_URL=$(jq -r '.base_url // empty' "$OPTIONS_FILE")
IMMICH_SERVER_UUID=$(jq -r '.server_uuid // empty' "$OPTIONS_FILE")
IMMICH_LOG_LEVEL=$(jq -r '.log_level // "INFO"' "$OPTIONS_FILE")

# Persist server UUID if not provided
if [ -z "$IMMICH_SERVER_UUID" ]; then
  if [ -f "$DATA_DIR/server_uuid" ]; then
    IMMICH_SERVER_UUID=$(cat "$DATA_DIR/server_uuid")
  else
    # generate a stable UUID based on hostname using python
    IMMICH_SERVER_UUID=$(python - <<'PY'
import uuid, socket
print(uuid.uuid5(uuid.NAMESPACE_DNS, socket.gethostname() + "-immich-dlna"))
PY
)
    echo "$IMMICH_SERVER_UUID" > "$DATA_DIR/server_uuid"
  fi
fi

# Export environment variables expected by upstream
export IMMICH_URL="$IMMICH_URL"
export IMMICH_API_TOKEN="$IMMICH_API_TOKEN"
export IMMICH_VERIFY_SSL="$IMMICH_VERIFY_SSL"
export IMMICH_DLNA_FRIENDLY_NAME="$IMMICH_FRIENDLY_NAME"
if [ -n "$IMMICH_BASE_URL" ]; then
  export IMMICH_DLNA_BASE_URL="$IMMICH_BASE_URL"
else
  echo "Advertencia: la autodetección de base_url puede elegir una interfaz incorrecta en Home Assistant OS (por ejemplo, una IP 172.30.32.x). Si los clientes no reproducen el contenido, configura base_url como http://<IP-LAN-de-HA>:8200."
fi
export IMMICH_DLNA_SERVER_UUID="$IMMICH_SERVER_UUID"
export IMMICH_DLNA_LOG_LEVEL="$IMMICH_LOG_LEVEL"
export IMMICH_DLNA_HTTP_PORT="8200"

# Log startup info (mask token)
MASKED_TOKEN=$(mask_token "$IMMICH_API_TOKEN")
EFFECTIVE_BASE_URL=${IMMICH_BASE_URL:-"(auto-detect)"}
echo "Starting Immich DLNA with IMMICH_URL=${IMMICH_URL}, IMMICH_API_TOKEN=${MASKED_TOKEN}, base_url=${EFFECTIVE_BASE_URL}, server_uuid=${IMMICH_SERVER_UUID}, log_level=${IMMICH_LOG_LEVEL}"

# Validate configuration
if ! immich-dlna --check-config; then
  echo "Configuración inválida: comprueba las opciones proporcionadas. El contenedor saldrá con error."
  exit 1
fi

# Exec the server
exec immich-dlna
