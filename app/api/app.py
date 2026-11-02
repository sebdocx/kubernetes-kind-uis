"""API de la aplicación de tres capas (capa 2).
Endpoints:
  /api/hostname  -> Pod y nodo que atienden la petición (Ejemplos 5 y 7)
  /api/visits    -> incrementa un contador en PostgreSQL (Ejemplos 5 y 6)
  /api/health    -> usado como livenessProbe (Ejemplo 12)
  /api/ready     -> usado como readinessProbe, verifica la BD y la bandera "listo" (Ejemplo 13)
  /api/pod       -> nombre del Pod en texto plano (Ejemplo 7)
  /api/version   -> versión en texto plano (Ejemplos 15 a 18)
  /api/unready   -> (POST) hace que este Pod deje de estar "listo" (Ejemplo 13)
  /api/cpu?ms=N  -> consume CPU N milisegundos (Ejemplo 10, HPA)
  /api/break     -> (POST) simula un contenedor colgado (Ejemplo 12)
  /api/heal      -> (POST) revierte /api/break
"""
import os
import socket
import time

import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)

VERSION = os.getenv("APP_VERSION", "v1")            # Versión de la app (Ejemplos 17 y 18)
POD = os.getenv("POD_NAME", socket.gethostname())    # Nombre del Pod (inyectado por downward API)
NODE = os.getenv("NODE_NAME", "desconocido")         # Nodo donde corre el Pod
estado = {"sano": True, "listo": True}               # Banderas para simular fallos


def conectar():
    """Abre una conexión a PostgreSQL usando el Service 'db' (DNS interno)."""
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "appdb"),
        user=os.getenv("DB_USER", "appuser"),
        password=os.getenv("DB_PASSWORD", ""),
        connect_timeout=3,
    )


@app.get("/api/hostname")
def hostname():
    return jsonify(pod=POD, nodo=NODE, version=VERSION)


@app.get("/api/health")
def health():
    if not estado["sano"]:
        return jsonify(estado="colgado", pod=POD), 500
    return jsonify(estado="ok", pod=POD)


@app.get("/api/ready")
def ready():
    if not estado["listo"]:
        return jsonify(estado="no listo (simulado)", pod=POD), 503
    try:
        conectar().close()
        return jsonify(estado="listo", pod=POD)
    except Exception as e:  # noqa: BLE001
        return jsonify(estado="sin base de datos", error=str(e)), 503


@app.get("/api/pod")
def pod():
    return POD + "\n", 200, {"Content-Type": "text/plain"}


@app.get("/api/version")
def version():
    return VERSION + "\n", 200, {"Content-Type": "text/plain"}


@app.post("/api/unready")
def no_listo():
    estado["listo"] = False
    return jsonify(estado="no listo", pod=POD)


@app.get("/api/visits")
def visits():
    try:
        conn = conectar()
        try:
            with conn, conn.cursor() as cur:
                cur.execute("CREATE TABLE IF NOT EXISTS visitas ("
                            "id serial PRIMARY KEY, pod text, ts timestamptz DEFAULT now())")
                cur.execute("INSERT INTO visitas(pod) VALUES (%s)", (POD,))
                cur.execute("SELECT count(*) FROM visitas")
                total = cur.fetchone()[0]
        finally:
            conn.close()
        return jsonify(total=total, pod=POD, nodo=NODE, version=VERSION)
    except Exception as e:  # noqa: BLE001
        return jsonify(error=str(e), pod=POD), 503


@app.get("/api/cpu")
def cpu():
    ms = min(int(request.args.get("ms", 200)), 5000)
    fin = time.time() + ms / 1000
    while time.time() < fin:      # Bucle ocupado: consume CPU
        pass
    return jsonify(cpu_ms=ms, pod=POD)


@app.post("/api/break")
def romper():
    estado["sano"] = False
    return jsonify(estado="colgado", pod=POD)


@app.post("/api/heal")
def sanar():
    estado["sano"] = True
    estado["listo"] = True
    return jsonify(estado="ok", pod=POD)
