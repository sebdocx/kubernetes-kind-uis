#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh

# Solución del Ejercicio 4
bash scripts/ha-patch.sh
kubectl rollout restart deployment/api deployment/frontend -n demo
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl rollout status deployment/frontend -n demo --timeout=180s
kubectl delete pdb --all -n demo
kubectl apply -f ejercicios/e4-pdb-maxunavailable.yaml
kubectl get pdb -n demo
esperar_cliente
sondeo 200 /tmp/sondeo-e4.txt
for NODO in uis-worker2 uis-worker3; do
  echo ">>> Mantenimiento de $NODO"
  kubectl cordon "$NODO"
  kubectl drain "$NODO" --ignore-daemonsets --delete-emptydir-data --timeout=180s
  kubectl get pods -n demo -o wide
  kubectl uncordon "$NODO"
  kubectl rollout restart deployment/api -n demo          # Reequilibra antes de pasar al siguiente nodo
  kubectl rollout status deployment/api -n demo --timeout=180s
done
resumen_sondeo /tmp/sondeo-e4.txt
kubectl apply -f k8s/16-pdb.yaml                              # Restaura los PDB del Ejemplo 16
