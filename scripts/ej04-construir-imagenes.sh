#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ejemplo 4: construir las imágenes y cargarlas en los nodos de kind
set -euo pipefail
CLUSTER="${CLUSTER:-uis}"                                   # Nombre del clúster kind
IMAGENES="uis/api:1.0 uis/api:2.0 uis/frontend:1.0"         # Imágenes que usará el clúster
docker build -t uis/api:1.0 --build-arg APP_VERSION=v1 app/api        # Imagen de la API v1
docker build -t uis/frontend:1.0 app/frontend                          # Imagen del frontend
docker build -t uis/api:2.0 --build-arg APP_VERSION=v2 app/api        # API v2 (se usará en el Ejemplo 17)
docker images | grep -E 'REPOSITORY|uis/'                   # Verifica las imágenes locales
# kind no ve las imágenes del host: hay que cargarlas en cada nodo
if ! kind load docker-image $IMAGENES --name "$CLUSTER"; then
  # Alternativa si Docker Desktop usa el almacén containerd: exportar a .tar y cargar el archivo
  echo ">> kind load docker-image falló; usando image-archive"
  for img in $IMAGENES; do
    docker save "$img" -o /tmp/imagen.tar
    kind load image-archive /tmp/imagen.tar --name "$CLUSTER"
  done
  rm -f /tmp/imagen.tar
fi
# Comprueba que quedaron en un worker
docker exec "${CLUSTER}-worker" crictl images | grep -E 'IMAGE|uis/'
