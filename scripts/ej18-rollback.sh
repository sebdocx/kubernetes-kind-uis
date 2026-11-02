#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 18: rollback tras una versión defectuosa (imagen inexistente)
kubectl rollout history deployment/api -n demo                # Revisiones antes del cambio
esperar_cliente
sondeo 100 /tmp/sondeo18.txt
sleep 5
echo ">>> Desplegando una versión defectuosa (la imagen no existe)"
kubectl set image deployment/api api=uis/api:3.0-defectuosa -n demo
kubectl annotate deployment/api -n demo kubernetes.io/change-cause="Versión defectuosa 3.0" --overwrite
kubectl rollout status deployment/api -n demo --timeout=45s || echo "(la actualización no avanza, como se esperaba)"
kubectl get pods -n demo -l app=api                           # Pod nuevo en ErrImagePull/ImagePullBackOff; los viejos siguen sirviendo
kubectl rollout history deployment/api -n demo
echo ">>> Rollback a la revisión anterior"
kubectl rollout undo deployment/api -n demo
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl get pods -n demo -l app=api
kubectl exec -n demo cliente -- wget -qO- http://frontend/api/version   # Debe volver a la versión estable (v2)
kubectl rollout history deployment/api -n demo
resumen_sondeo /tmp/sondeo18.txt
