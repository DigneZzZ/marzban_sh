#!/bin/bash

# Спрашиваем у пользователя на какой домен нужно выпустить сертификаты
read -p "Введите домен для выпуска сертификатов: " domain

# Устанавливаем certbot
apt-get install certbot -y

# Выпускаем сертификаты
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$domain"

# Производим dry-run для обновления сертификатов
certbot renew --dry-run

# Копируем путь до сертификатов в переменную
cert_path="/var/lib/marzban/certs/$domain"

# Вносим изменения в файл .env
echo "UVICORN_SSL_CERTFILE=\"$cert_path/fullchain.pem\"" >> /opt/marzban/.env
echo "UVICORN_SSL_KEYFILE=\"$cert_path/privkey.pem\"" >> /opt/marzban/.env
echo "XRAY_SUBSCRIPTION_URL_PREFIX=\"https://$domain\"" >> /opt/marzban/.env

# Устанавливаем wget
apt install wget -y

# Переходим в папку /opt/marzban/
cd /opt/marzban/


# Вносим изменения в файл docker-compose.yml
if ! grep -q "index.html:/code/app/templates/subscription/index.html" docker-compose.yml; then
  sed -i '/volumes:/a \      - /opt/marzban/index.html:/code/app/templates/subscription/index.html' docker-compose.yml
fi

# Запускаем контейнеры
marzban restart -n
