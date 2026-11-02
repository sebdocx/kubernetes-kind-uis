#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ejemplo 5: desplegar las tres capas repartidas entre nodos
set -euo pipefail
kubectl apply -f k8s/01-base-datos.yaml      # Namespace, Secret, BD y Service
kubectl apply -f k8s/02-api.yaml             # API y Service (antes que el frontend, que resuelve 'api' al iniciar)
kubectl apply -f k8s/03-frontend.yaml        # Frontend y Service
kubectl rollout status deployment/db -n demo --timeout=180s
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl rollout status deployment/frontend -n demo --timeout=180s
kubectl get pods -n demo -o wide             # Columna NODE: BD en tier=db; API y frontend repartidos
kubectl get pods -n demo -o custom-columns=POD:.metadata.name,NODO:.spec.nodeName --sort-by=.spec.nodeName
kubectl get svc,endpointslices -n demo       # Services y los Pods detrás de cada uno
# Prueba de extremo a extremo: port-forward temporal al Service del frontend
kubectl port-forward -n demo svc/frontend 8080:80 >/dev/null 2>&1 &
PF=$!
sleep 3
curl -s localhost:8080/api/hostname; echo     # Pod y nodo de la API que respondió
for i in $(seq 1 15); do                       # Reintenta mientras PostgreSQL termina de iniciar
  curl -sf localhost:8080/api/visits && break || sleep 3
done
echo
curl -s localhost:8080/api/visits; echo        # El contador debe aumentar
kill "$PF"                                     # Cierra el port-forward
