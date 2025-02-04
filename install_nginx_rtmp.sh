#!/bin/bash

# Actualizar sistema
echo "🔹 Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
echo "🔹 Instalando dependencias..."
sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev unzip git

# Descargar Nginx y el módulo RTMP
echo "🔹 Descargando Nginx y el módulo RTMP..."
cd /usr/local/src
sudo git clone https://github.com/arut/nginx-rtmp-module.git
sudo wget http://nginx.org/download/nginx-1.24.0.tar.gz
sudo tar -xvzf nginx-1.24.0.tar.gz
cd nginx-1.24.0

# Configurar, compilar e instalar Nginx con RTMP
echo "🔹 Configurando e instalando Nginx..."
sudo ./configure --with-http_ssl_module --add-module=../nginx-rtmp-module
sudo make && sudo make install

# Configurar Nginx para RTMP y HLS
echo "🔹 Configurando Nginx con RTMP y HLS..."
sudo tee /usr/local/nginx/conf/nginx.conf > /dev/null <<EOT
worker_processes  1;
events {
    worker_connections  1024;
}
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
            hls on;
            hls_path /usr/local/nginx/html/hls;
            hls_fragment 5s;
        }
    }
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    server {
        listen 80;
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /usr/local/nginx/html;
            add_header 'Access-Control-Allow-Origin' '*';
        }
    }
}
EOT

# Crear carpeta HLS
echo "🔹 Creando carpeta HLS..."
sudo mkdir -p /usr/local/nginx/html/hls
sudo chmod -R 777 /usr/local/nginx/html

# Iniciar Nginx
echo "🔹 Iniciando Nginx..."
sudo /usr/local/nginx/sbin/nginx

echo "✅ Instalación completada. Nginx está ejecutándose en el puerto 80 y RTMP en el 1935."
