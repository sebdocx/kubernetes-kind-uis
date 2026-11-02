#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 17: actualización sin caída (rolling update) de v1 a v2
kubectl apply -f k8s/12-api-probes.yaml                       # Parte de la imagen 1.0 (v1) con readinessProbe
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl patch deployment api -n demo -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
# maxSurge=1: puede haber 1 Pod extra durante el cambio; maxUnavailable=0: nunca baja de las réplicas deseadas
kubectl get deployment api -n demo -o jsonpath='{.spec.strategy}'; echo
esperar_cliente
sondeo 90 /tmp/sondeo17.txt
sleep 10
echo ">>> Actualizando a la imagen 2.0"
kubectl set image deployment/api api=uis/api:2.0 -n demo
kubectl annotate deployment/api -n demo kubernetes.io/change-cause="Actualización a v2 (imagen 2.0)" --overwrite
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl get rs -n demo -l app=api                             # ReplicaSet viejo en 0 y nuevo con las réplicas
kubectl rollout history deployment/api -n demo
resumen_sondeo /tmp/sondeo17.txt                              # Respuestas v1 y v2, con 0 FALLO idealmente
