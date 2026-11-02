# Ejercicios propuestos (las soluciones están en los scripts `ejercicio-N.sh`)

**Ejercicio 1 — Nivel medio — Tema: topologySpreadConstraints y taints (refuerza Ejemplos 3 y 5).**
Despliegue un Deployment de 4 réplicas con `topologySpreadConstraints` (maxSkew 1, `DoNotSchedule`) **sin** `nodeSelector`.
Observe qué Pod queda en Pending y explique por qué el control-plane, aunque tenga taint, influye en el reparto.
Corrija el problema sin quitar la restricción de reparto.

**Ejercicio 2 — Nivel básico — Tema: Ingress por host (refuerza Ejemplo 9).**
Agregue un segundo host, `api.uis.local`, que envíe todo el tráfico directamente al Service `api`.
Compruebe con `curl` y la cabecera `Host` que ambos hosts funcionan.

**Ejercicio 3 — Nivel medio — Tema: HPA (refuerza Ejemplos 10 y 11).**
Cambie el objetivo del HPA al 30 % de CPU y el máximo a 4 réplicas. Aplique la misma carga y mida cuánto tarda en aparecer la primera réplica nueva.
Compare con el HPA original (50 %, máximo 6) y explique la diferencia.

**Ejercicio 4 — Nivel avanzado — Tema: mantenimiento continuo con PDB (refuerza Ejemplos 15 y 16).**
Con un PodDisruptionBudget `maxUnavailable: 1` para la API, haga mantenimiento de los dos workers de aplicación, uno después del otro
(cordon, drain, uncordon), mientras un usuario simulado hace peticiones. Demuestre cuántas peticiones fallaron.

**Ejercicio 5 — Nivel avanzado — Tema: persistencia (refuerza Ejemplos 5 y 14).**
Compruebe que la base de datos del Ejemplo 5 pierde sus datos cuando su Pod se recrea (usa `emptyDir`).
Cambie la BD para que use un PersistentVolumeClaim y demuestre que el contador de visitas sobrevive a la eliminación del Pod.
