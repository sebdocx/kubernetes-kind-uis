#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh

# Solución del Ejercicio 5
visitas() { kubectl exec -n demo cliente -- wget -qO- http://frontend/api/visits; echo; }
esperar_cliente
kubectl rollout status deployment/db -n demo --timeout=120s
echo ">>> Con emptyDir: se generan visitas"
visitas; visitas; visitas
echo ">>> Se elimina el Pod de la BD"
kubectl delete pod -n demo -l app=db
kubectl rollout status deployment/db -n demo --timeout=120s; sleep 15
visitas                                                       # El contador vuelve a empezar: se perdieron los datos
echo ">>> Con PersistentVolumeClaim"
kubectl delete deployment db -n demo
kubectl apply -f ejercicios/e5-db-pvc.yaml
kubectl rollout status deployment/db -n demo --timeout=180s; sleep 15
kubectl get pvc,pv -n demo
visitas; visitas; visitas
echo ">>> Se elimina de nuevo el Pod de la BD"
kubectl delete pod -n demo -l app=db
kubectl rollout status deployment/db -n demo --timeout=180s; sleep 15
visitas                                                       # El contador continúa: los datos sobrevivieron
