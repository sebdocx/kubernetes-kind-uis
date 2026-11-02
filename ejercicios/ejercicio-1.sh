#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh

# Solución del Ejercicio 1
echo ">>> Problema: 4 réplicas sin nodeSelector"
kubectl apply -f ejercicios/e1-spread-sin-selector.yaml
sleep 20
kubectl get pods -n demo -l app=spread-e1 -o wide             # Una réplica debería quedar Pending
PEND=$(kubectl get pods -n demo -l app=spread-e1 --field-selector=status.phase=Pending -o jsonpath='{.items[0].metadata.name}')
[ -n "$PEND" ] && kubectl describe pod "$PEND" -n demo | tail -6   # Evento FailedScheduling por topology spread / taint
echo ">>> Solución: nodeTaintsPolicy Honor"
kubectl apply -f ejercicios/e1-spread-solucion.yaml
kubectl rollout status deployment/spread-e1 -n demo --timeout=120s
kubectl get pods -n demo -l app=spread-e1 -o wide             # Repartidas en los workers, ninguna Pending
kubectl delete -f ejercicios/e1-spread-solucion.yaml          # Limpieza
