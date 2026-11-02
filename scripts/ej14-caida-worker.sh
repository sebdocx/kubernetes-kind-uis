#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 14: caída de un worker y reprogramación (se detiene el contenedor del nodo)
NODO=uis-worker2                       # Worker de aplicación (NO uis-worker, que aloja la base de datos)
bash scripts/ha-patch.sh
kubectl get pods -n demo -o wide       # Estado inicial: qué Pods hay en cada nodo
echo ">>> Deteniendo el nodo $NODO"
docker stop "$NODO"
for i in $(seq 1 9); do                # Se observa durante 3 minutos
  echo "--- t=$((i*20))s"
  kubectl get nodes --no-headers | awk '{print $1, $2}'
  kubectl get pods -n demo -o wide --no-headers | awk '{print $1, $3, $7}'
  sleep 20
done
kubectl describe node "$NODO" | grep -iE 'taint|NodeNotReady|Unknown' | head
echo ">>> Recuperando el nodo"
docker start "$NODO"
sleep 45
kubectl get nodes
kubectl get pods -n demo -o wide       # Los Pods NO vuelven solos al nodo recuperado
