#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 12: liveness probe y auto-recuperación
kubectl apply -f k8s/12-api-probes.yaml                       # API con livenessProbe/readinessProbe
kubectl rollout status deployment/api -n demo --timeout=180s
POD=$(kubectl get pods -n demo -l app=api -o jsonpath='{.items[0].metadata.name}')
echo "Pod que se va a colgar: $POD"
kubectl get pods -n demo -l app=api                           # RESTARTS = 0
kubectl describe pod "$POD" -n demo | grep -E 'Liveness|Readiness'   # Parámetros de las sondas
echo ">>> Colgando la aplicación (/api/health pasará a devolver 500)"
pod_post "$POD" /api/break
echo ">>> Observando 60 s: la columna RESTARTS debe subir a 1"
timeout 60 kubectl get pods -n demo -l app=api -w
kubectl describe pod "$POD" -n demo | tail -12                # Eventos: "Liveness probe failed" y reinicio
kubectl get pods -n demo -l app=api
