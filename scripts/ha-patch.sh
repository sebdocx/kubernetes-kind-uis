#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Ajustes de alta disponibilidad para api y frontend (usado por los Ejemplos 14 a 17). Es idempotente.
# nodeTaintsPolicy: Honor -> los nodos caídos o acordonados (con taint) no cuentan como dominio en topologySpreadConstraints
# tolerations 30 s        -> los Pods de un nodo caído se desalojan a los 30 s en lugar de los 300 s por defecto
for d in api frontend; do
  kubectl patch deployment $d -n demo --type=json -p '[
    {"op":"add","path":"/spec/template/spec/topologySpreadConstraints/0/nodeTaintsPolicy","value":"Honor"},
    {"op":"add","path":"/spec/template/spec/tolerations","value":[
      {"key":"node.kubernetes.io/unreachable","operator":"Exists","effect":"NoExecute","tolerationSeconds":30},
      {"key":"node.kubernetes.io/not-ready","operator":"Exists","effect":"NoExecute","tolerationSeconds":30}]}]'
  kubectl rollout status deployment/$d -n demo --timeout=180s
done
