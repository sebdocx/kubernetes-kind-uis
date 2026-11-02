# Imagen del frontend (capa 1)

# Servidor web ligero
FROM nginx:1.27-alpine
# Reemplaza la configuración por defecto de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Página estática
COPY index.html /usr/share/nginx/html/index.html
# Puerto en el que escucha nginx
EXPOSE 80
