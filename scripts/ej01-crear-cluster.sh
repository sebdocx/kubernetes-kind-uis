#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ejemplo 1: crear el clúster con kind y verificarlo con kubectl
set -euo pipefail
docker version                                   # Verifica que Docker responde (cliente y servidor)
kind version                                     # Versión de kind
kubectl version --client                         # Versión de kubectl
kind create cluster --config kind/kind-config.yaml   # Crea 1 control-plane + 3 workers
kubectl config get-contexts                      # Debe aparecer el contexto kind-uis
kubectl cluster-info --context kind-uis          # Direcciones del API server y CoreDNS
kubectl get nodes                                # 4 nodos en estado Ready
