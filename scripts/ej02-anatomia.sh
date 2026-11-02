#!/usr/bin/env bash
# Se ubica en la raíz del proyecto sin importar desde dónde se ejecute el script
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ejemplo 2: qué corre en cada nodo
kubectl get nodes -o wide                        # IP, versión, runtime y SO de cada nodo
kubectl get pods -n kube-system -o wide          # Componentes del sistema y el nodo donde corre cada uno
kubectl get daemonsets -n kube-system            # DaemonSets: un Pod por nodo (kube-proxy, kindnet)
# Nombre del nodo maestro (el que tiene la etiqueta control-plane)
CP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
kubectl describe node "$CP" | sed -n '1,25p'                      # Cabecera: roles, etiquetas y taints
kubectl describe node "$CP" | grep -A12 'Non-terminated Pods'     # Pods que corren en ese nodo
docker ps --filter "label=io.x-k8s.kind.cluster=uis"              # Cada nodo es un contenedor Docker
