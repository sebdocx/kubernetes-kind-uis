#!/usr/bin/env bash
# Funciones auxiliares compartidas por los scripts (se cargan con "source")

# Crea el Pod "cliente" (usuario simulado dentro del clúster) y espera a que esté listo
esperar_cliente() {
  kubectl apply -f k8s/cliente.yaml
  kubectl wait --for=condition=Ready pod/cliente -n demo --timeout=120s
}

# Lanza en segundo plano un sondeo de disponibilidad: 1 petición por segundo durante $1 segundos.
# Guarda en $2 la versión devuelta por la API (v1, v2...) o la palabra FALLO si la petición falló.
sondeo() {
  kubectl exec -n demo cliente -- sh -c \
    "for i in \$(seq 1 $1); do wget -q -T 2 -O- http://frontend/api/version || echo FALLO; sleep 1; done" \
    > "$2" 2>/dev/null &
  SONDEO_PID=$!
}

# Espera a que termine el sondeo y muestra cuántas respuestas hubo de cada tipo
resumen_sondeo() {
  wait "$SONDEO_PID" 2>/dev/null
  echo "=== Resultado del sondeo (cantidad de respuestas de cada tipo) ==="
  grep -v '^$' "$1" | sort | uniq -c
}

# Hace un POST a un endpoint de control de la API dentro de un Pod: pod_post <pod> <ruta>
pod_post() {
  kubectl exec -n demo "$1" -- python -c "import urllib.request as u; print(u.urlopen(u.Request('http://localhost:5000$2', method='POST')).read().decode())"
}
