#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 10: HPA con generador de carga. Requiere metrics-server funcionando (ejecute antes ej11).
kubectl apply -f k8s/10-hpa.yaml
kubectl top pods -n demo                                      # Consumo de CPU en reposo
kubectl get hpa -n demo                                       # Estado inicial
echo ">>> Iniciando carga (4 generadores)"
kubectl apply -f k8s/10-carga.yaml
echo ">>> Observando el HPA durante 4 minutos (las réplicas deben subir)"
timeout 240 kubectl get hpa api -n demo -w
kubectl top pods -n demo -l app=api
kubectl get pods -n demo -l app=api -o wide
echo ">>> Deteniendo la carga"
kubectl delete -f k8s/10-carga.yaml
echo ">>> Observando 4 minutos más (las réplicas deben bajar al mínimo)"
timeout 240 kubectl get hpa api -n demo -w
kubectl get pods -n demo -l app=api
