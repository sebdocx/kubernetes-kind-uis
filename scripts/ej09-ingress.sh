#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 9: Ingress con Traefik (ingress-nginx fue retirado en marzo de 2026)
if ! command -v helm >/dev/null; then
  echo "Falta Helm. Instálelo con:  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  exit 1
fi
helm repo add traefik https://traefik.github.io/charts       # Repositorio oficial de Traefik
helm repo update
helm upgrade --install traefik traefik/traefik -n traefik --create-namespace \
  -f k8s/09-traefik-values.yaml --wait --timeout 3m           # Instala Traefik con los valores del proyecto
kubectl get pods -n traefik -o wide                           # Debe correr en el control-plane
kubectl get ingressclass                                      # Clase "traefik"
kubectl apply -f k8s/09-ingress.yaml
kubectl describe ingress entrada -n demo                      # Reglas y backends
sleep 5
# Pruebas con la cabecera Host (no hace falta editar /etc/hosts)
curl -s -H 'Host: app.uis.local' http://localhost/ | head -5          # Página del frontend
curl -s -H 'Host: app.uis.local' http://localhost/api/hostname; echo  # Ruta /api -> API
# Si localhost:80 no responde, alternativa con port-forward:
#   kubectl port-forward -n traefik deploy/traefik 8000:8000  y probar http://localhost:8000
