#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 6: Service ClusterIP y DNS interno
kubectl get svc -n demo -o wide                       # ClusterIP de db, api y frontend
kubectl get endpointslices -n demo                    # Pods (IP) detrás de cada Service
kubectl get pods -n demo -o wide                      # Las IP de los Pods deben coincidir con los endpoints
# frontend -> API por nombre de Service
kubectl exec -n demo deploy/frontend -- nslookup api.demo.svc.cluster.local   # El DNS devuelve el ClusterIP
kubectl exec -n demo deploy/frontend -- wget -qO- http://api:5000/api/hostname # Llamada usando solo el nombre
# API -> base de datos por nombre de Service
kubectl exec -n demo deploy/api -- python -c "import socket; print('db ->', socket.gethostbyname('db'))"
# Cadena completa frontend -> API -> BD
kubectl exec -n demo deploy/frontend -- wget -qO- http://localhost/api/visits
