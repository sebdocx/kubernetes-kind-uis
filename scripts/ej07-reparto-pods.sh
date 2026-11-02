#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 7: reparto de peticiones entre Pods
kubectl get pods -n demo -l app=api -o wide           # Las 3 réplicas de la API
# 100 peticiones al Service api desde un Pod del frontend; cada una abre una conexión nueva
kubectl exec -n demo deploy/frontend -- sh -c 'for i in $(seq 1 100); do wget -qO- http://api:5000/api/pod; done' | sort | uniq -c
echo "(Cada línea: cantidad de respuestas atendidas por ese Pod. Debe ser un reparto aproximadamente parejo.)"
