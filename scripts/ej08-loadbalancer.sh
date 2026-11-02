#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 8: Service tipo LoadBalancer con MetalLB
# kind no trae un balanceador externo; MetalLB asigna IP de la red Docker "kind".
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
kubectl wait -n metallb-system --for=condition=ready pod -l app=metallb --timeout=180s
# Rango de IP libre dentro de la subred IPv4 de la red Docker de kind
SUBNET=$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}} {{end}}' | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/' | head -1)
PREFIX=$(echo "$SUBNET" | cut -d. -f1,2)
echo "Subred de kind: $SUBNET  -> pool ${PREFIX}.255.200-${PREFIX}.255.250"
cat > /tmp/metallb-pool.yaml <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool                  # Rango de IP que MetalLB puede entregar
metadata:
  name: pool-kind
  namespace: metallb-system
spec:
  addresses:
    - ${PREFIX}.255.200-${PREFIX}.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement                # Anuncia las IP en la red local (modo capa 2)
metadata:
  name: l2
  namespace: metallb-system
EOF
for i in $(seq 1 10); do               # El webhook de MetalLB puede tardar unos segundos
  kubectl apply -f /tmp/metallb-pool.yaml && break || sleep 5
done
kubectl apply -f k8s/08-frontend-lb.yaml
sleep 10
kubectl get svc -n demo frontend-lb                  # EXTERNAL-IP debe mostrar una IP, no <pending>
IP=$(kubectl get svc -n demo frontend-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "IP externa: $IP"
# Acceso desde la red de kind (siempre funciona, incluso con Docker Desktop)
docker run --rm --network kind curlimages/curl -s "http://$IP/api/hostname"; echo
# Acceso desde el host (puede no funcionar en Docker Desktop/WSL: anótelo en el análisis)
curl -s --max-time 5 "http://$IP/api/hostname" || echo "(sin acceso directo desde el host a $IP)"
