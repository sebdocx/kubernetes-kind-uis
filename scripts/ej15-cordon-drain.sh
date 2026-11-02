#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 15: mantenimiento con cordon / drain
NODO=uis-worker3
bash scripts/ha-patch.sh
kubectl rollout restart deployment/api deployment/frontend -n demo   # Reequilibra los Pods entre los dos workers
kubectl rollout status deployment/api -n demo --timeout=180s
kubectl rollout status deployment/frontend -n demo --timeout=180s
esperar_cliente
kubectl get pods -n demo -o wide
sondeo 70 /tmp/sondeo15.txt            # Usuario simulado: 1 petición por segundo durante 70 s
sleep 5
echo ">>> cordon: el nodo deja de recibir Pods nuevos"
kubectl cordon "$NODO"
kubectl get nodes                      # Aparece SchedulingDisabled
echo ">>> drain: se desalojan los Pods del nodo"
kubectl drain "$NODO" --ignore-daemonsets --delete-emptydir-data --timeout=180s
kubectl get pods -n demo -o wide       # Ningún Pod de usuario queda en $NODO
echo ">>> uncordon: el nodo vuelve a aceptar Pods"
kubectl uncordon "$NODO"
kubectl get nodes
resumen_sondeo /tmp/sondeo15.txt       # Debe haber pocos o ningún FALLO
