#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ejemplo 3: etiquetas, taints y nodeSelector
set -euo pipefail
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -   # Crea el namespace si no existe
# Lista de workers (todo nodo que no sea control-plane)
mapfile -t WORKERS < <(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')
kubectl label node "${WORKERS[0]}" tier=db --overwrite      # El primer worker alojará la base de datos
for n in "${WORKERS[@]:1}"; do
  kubectl label node "$n" tier=app --overwrite              # Los demás alojarán frontend y API
done
kubectl get nodes -L tier                                   # Muestra la etiqueta como columna
kubectl describe node "$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')" | grep -i taint   # Taint del control-plane
kubectl apply -f k8s/ej03-nodeselector.yaml
sleep 10
kubectl get pods -n demo -o wide                            # pod-en-worker: Running; pod-en-control-plane: Pending
kubectl describe pod pod-en-control-plane -n demo | tail -8 # Evento FailedScheduling por el taint
kubectl delete -f k8s/ej03-nodeselector.yaml                # Limpieza
