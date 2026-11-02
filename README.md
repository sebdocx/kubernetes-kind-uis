# Kubernetes multinodo con kind — Ejemplos 1 a 18 y Ejercicios 1 a 5

Aplicación de tres capas: **frontend (nginx) → API (Flask) → base de datos (PostgreSQL)** sobre un clúster kind
de 1 control-plane + 3 workers (`uis-worker` = base de datos, `uis-worker2` y `uis-worker3` = aplicación).

## Cómo ejecutar
Desde cualquier carpeta, en la terminal de Ubuntu (Docker Desktop abierto):
```bash
chmod +x scripts/*.sh ejercicios/*.sh        # solo la primera vez
./scripts/ej01-crear-cluster.sh 2>&1 | tee ej01.txt
```
Use `2>&1 | tee ejNN.txt` para guardar la salida como evidencia en texto además de las capturas.

## ORDEN OBLIGATORIO (cada paso depende de los anteriores)
| Orden | Script | Ejemplo | Requiere |
|---|---|---|---|
| 1 | `ej01-crear-cluster.sh` | 1. Clúster con kind | Docker, kind, kubectl |
| 2 | `ej02-anatomia.sh` | 2. Anatomía | 1 |
| 3 | `ej03-etiquetas-taints.sh` | 3. Etiquetas, taints, nodeSelector | 1 |
| 4 | `ej04-construir-imagenes.sh` | 4. Imágenes propias | 1 |
| 5 | `ej05-desplegar.sh` | 5. App de 3 capas | 3 y 4 |
| 6 | `ej06-clusterip-dns.sh` | 6. ClusterIP y DNS | 5 |
| 7 | `ej07-reparto-pods.sh` | 7. Reparto entre Pods | 5 |
| 8 | `ej08-loadbalancer.sh` | 8. LoadBalancer (MetalLB) | 5 |
| 9 | `ej09-ingress.sh` | 9. Ingress (Traefik + Helm) | 5 y Helm |
| 10 | **`ej11-diagnostico-unknown.sh` primero** | 11. Diagnóstico `<unknown>` | 5 |
| 11 | `ej10-hpa-carga.sh` | 10. HPA con carga | 11 |
| 12 | `ej12-liveness.sh` | 12. Liveness | 5 |
| 13 | `ej13-readiness.sh` | 13. Readiness | 12 |
| 14 | `ej14-caida-worker.sh` | 14. Caída de worker | 12 |
| 15 | `ej15-cordon-drain.sh` | 15. cordon/drain | 14 |
| 16 | `ej16-pdb.sh` | 16. PodDisruptionBudget | 15 |
| 17 | `ej17-rolling-update.sh` | 17. Rolling update | 12 |
| 18 | `ej18-rollback.sh` | 18. Rollback | 17 |
| E | `ejercicios/ejercicio-1.sh` … `-5.sh` | Ejercicios 1 a 5 | ver `ejercicios/ENUNCIADOS.md` |

El Ejemplo 11 se ejecuta **antes** que el 10 porque reproduce el error `<unknown>` y deja metrics-server corregido.
Si el HPA queda con más de 3 réplicas, espere unos minutos a que baje antes del Ejemplo 16.

## Cosas que hay que validar en su máquina (no se probaron en un clúster real)
- **Si ya construyeron las imágenes antes de recibir esta versión**, repitan `ej04-construir-imagenes.sh` y luego
  `kubectl rollout restart deployment/api -n demo`: la API tiene endpoints nuevos (`/api/pod`, `/api/version`, `/api/unready`).
- **Ejemplo 8:** MetalLB asigna una IP de la red Docker de kind; desde WSL/Docker Desktop puede que el host no la alcance.
  El script prueba también desde la red de kind. Documenten lo que observen.
- **Ejemplo 9:** `ingress-nginx` fue retirado en marzo de 2026, por eso se usa Traefik con Helm.
  Si `localhost:80` no responde, use el `port-forward` indicado en el script.
- **Ejemplo 14:** el Pod de la BD no se mueve (tiene `nodeSelector` y `emptyDir`); por eso se detiene `uis-worker2` y no `uis-worker`.
  `ha-patch.sh` baja a 30 s el desalojo de Pods y evita que el nodo caído cuente en el reparto topológico.
- **Ejemplos 15, 17 y 18:** "cero fallos" no está garantizado; puede haber algún FALLO aislado por la propagación de endpoints. Repórtenlo tal como salga.
- **Ejercicio 1:** el Pending esperado se basa en el comportamiento por defecto del scheduler; si en su versión no ocurre, documéntenlo.
- Versiones usadas: metrics-server (`latest`), MetalLB v0.14.9, chart de Traefik (última). Si algo no descarga, revisen la versión vigente.

## Si algo falla
- `kind delete cluster --name uis` y repetir desde el Ejemplo 1.
- `kubectl describe pod <pod> -n demo` → sección Events.
- Poca memoria en WSL: suba la memoria en `.wslconfig` o use 2 workers.
