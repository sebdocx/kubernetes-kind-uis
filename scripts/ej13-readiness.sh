#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 13: readiness probe y salida del balanceo
kubectl apply -f k8s/12-api-probes.yaml
kubectl rollout status deployment/api -n demo --timeout=180s
POD=$(kubectl get pods -n demo -l app=api -o jsonpath='{.items[0].metadata.name}')
echo "Pod que dejará de estar listo: $POD"
echo ">>> Antes: reparto entre Pods"
kubectl exec -n demo deploy/frontend -- sh -c 'for i in $(seq 1 60); do wget -qO- http://api:5000/api/pod; done' | sort | uniq -c
echo ">>> Marcando el Pod como no listo"
pod_post "$POD" /api/unready
sleep 15
kubectl get pods -n demo -l app=api                           # El Pod aparece 0/1 y sin reiniciarse
kubectl get endpointslices -n demo -l kubernetes.io/service-name=api \
  -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"  ready="}{.conditions.ready}{"\n"}{end}'
echo ">>> Durante: ese Pod ya no recibe tráfico"
kubectl exec -n demo deploy/frontend -- sh -c 'for i in $(seq 1 60); do wget -qO- http://api:5000/api/pod; done' | sort | uniq -c
echo ">>> Recuperando el Pod"
pod_post "$POD" /api/heal
sleep 15
kubectl get pods -n demo -l app=api
kubectl exec -n demo deploy/frontend -- sh -c 'for i in $(seq 1 60); do wget -qO- http://api:5000/api/pod; done' | sort | uniq -c
