#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh

# Solución del Ejercicio 2 (requiere el Ejemplo 9: Traefik instalado)
kubectl apply -f ejercicios/e2-ingress-host.yaml
sleep 5
kubectl get ingress -n demo
echo ">>> Host original (frontend + /api)"
curl -s -H 'Host: app.uis.local' http://localhost/api/hostname; echo
echo ">>> Nuevo host (todo va a la API)"
curl -s -H 'Host: api.uis.local' http://localhost/api/hostname; echo
curl -s -o /dev/null -w "Host desconocido -> HTTP %{http_code}\n" -H 'Host: otro.uis.local' http://localhost/
