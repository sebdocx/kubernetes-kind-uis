#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 16: PodDisruptionBudget
NODO=uis-worker3
bash scripts/ha-patch.sh
kubectl rollout restart deployment/api deployment/frontend -n demo
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl rollout status deployment/frontend -n demo --timeout=180s
kubectl apply -f k8s/16-pdb.yaml
kubectl get pdb -n demo                                       # ALLOWED DISRUPTIONS indica cuántos Pods se pueden desalojar
echo ">>> Fase A: PDB minAvailable=2 con 3 réplicas -> el drain avanza de a un Pod"
kubectl cordon "$NODO"
kubectl drain "$NODO" --ignore-daemonsets --delete-emptydir-data --timeout=180s
kubectl get pods -n demo -o wide
kubectl uncordon "$NODO"
kubectl rollout restart deployment/api -n demo && kubectl rollout status deployment/api -n demo --timeout=180s
echo ">>> Fase B: PDB minAvailable=3 con 3 réplicas -> el drain se bloquea"
kubectl patch pdb api-pdb -n demo --type=merge -p '{"spec":{"minAvailable":3}}'
kubectl get pdb -n demo                                       # ALLOWED DISRUPTIONS = 0
kubectl cordon "$NODO"
timeout 40 kubectl drain "$NODO" --ignore-daemonsets --delete-emptydir-data   # Verá: "Cannot evict pod as it would violate the pod's disruption budget"
echo ">>> Restaurando"
kubectl uncordon "$NODO"
kubectl patch pdb api-pdb -n demo --type=merge -p '{"spec":{"minAvailable":2}}'
kubectl get pdb -n demo
