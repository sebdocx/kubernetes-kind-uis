# Imagen de la API (capa 2)

# Imagen base ligera con Python 3.12
FROM python:3.12-slim
# Argumento de construcción: versión que reportará la API (v1, v2...)
ARG APP_VERSION=v1
# Variables de entorno; PYTHONUNBUFFERED envía los logs sin retraso
ENV APP_VERSION=${APP_VERSION} \
    PYTHONUNBUFFERED=1
# Directorio de trabajo dentro del contenedor
WORKDIR /app
# Copia primero las dependencias (aprovecha la caché de capas de Docker)
COPY requirements.txt .
# Instala dependencias sin guardar caché para reducir el tamaño
RUN pip install --no-cache-dir -r requirements.txt
# Copia el código de la aplicación
COPY app.py .
# Documenta el puerto en el que escucha la API
EXPOSE 5000
# Servidor de producción: 1 proceso y 8 hilos (la bandera de /api/break es por proceso)
CMD ["gunicorn", "-b", "0.0.0.0:5000", "-w", "1", "--threads", "8", "app:app"]
