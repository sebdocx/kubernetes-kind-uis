#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source scripts/lib.sh        # Funciones auxiliares (sondeo de disponibilidad, etc.)
# Ejemplo 11: diagnóstico del <unknown> del HPA (caso K1). EJECUTAR ANTES que el Ejemplo 10.
# 1) Instalación "ingenua" de metrics-server (sin ajustes para kind)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl rollout status deployment/metrics-server -n kube-system --timeout=60s || echo "(metrics-server no llega a estar listo)"
kubectl apply -f k8s/10-hpa.yaml
sleep 60
# 2) Síntoma
kubectl get hpa -n demo                                       # TARGETS <unknown>/50%
kubectl describe hpa api -n demo | tail -12                   # Condiciones y eventos (FailedGetResourceMetric)
# 3) Búsqueda de la causa
kubectl get apiservices | grep metrics                        # v1beta1.metrics.k8s.io debe aparecer con AVAILABLE False
kubectl get pods -n kube-system -l k8s-app=metrics-server     # Pod sin estar READY
kubectl logs -n kube-system deploy/metrics-server | tail -15  # Lea el error real (típicamente de certificados TLS del kubelet)
kubectl top nodes || true                                     # Falla mientras no haya métricas
# 4) Corrección: metrics-server no puede validar el certificado del kubelet de kind
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s
sleep 60
# 5) Verificación
kubectl get apiservices | grep metrics                        # AVAILABLE True
kubectl top nodes
kubectl top pods -n demo
kubectl get hpa -n demo                                       # TARGETS con un porcentaje, ya sin <unknown>
