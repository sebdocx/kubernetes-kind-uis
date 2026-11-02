#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh

# Solución del Ejercicio 3 (requiere metrics-server funcionando)
medir() {   # medir <segundos>: imprime la hora, la CPU y las réplicas cada 15 s
  for i in $(seq 1 $(( $1 / 15 ))); do
    echo "$(date +%T)  $(kubectl get hpa api -n demo --no-headers)"; sleep 15
  done
}
echo ">>> HPA original (50 %, máx 6)"
kubectl apply -f k8s/10-hpa.yaml
kubectl apply -f k8s/10-carga.yaml; date +"Carga iniciada: %T"; medir 180
kubectl delete -f k8s/10-carga.yaml; sleep 150
echo ">>> HPA sensible (30 %, máx 4)"
kubectl apply -f ejercicios/e3-hpa-30.yaml
kubectl apply -f k8s/10-carga.yaml; date +"Carga iniciada: %T"; medir 180
kubectl delete -f k8s/10-carga.yaml
kubectl apply -f k8s/10-hpa.yaml                              # Restaura el HPA original
