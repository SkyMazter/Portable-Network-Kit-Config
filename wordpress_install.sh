#!/bin/bash

set -e

echo "Installing Wordpress..."
cd ~
echo "Creating Wordpress Directory..."
mkdir -p wordpress
cd wordpress

echo "Creating .env file..."
cat <<EOF > .env
ROOT_DB_PASSWORD=$(openssl rand -base64 16)
DB_PASSWORD=$(openssl rand -base64 16)
EOF

echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  db:
    image: mariadb:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${ROOT_DB_PASSWORD}
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./db_data:/var/lib/mysql

  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      - db
    volumes:
      - ./wp_data:/var/www/html

volumes:
  db_data:
  wp_data:
EOF

echo "Starting containers..."
sudo docker compose up -d

echo "Wordpress setup complete!"

echo "Updating the master .env records..."

SOURCE=".env"
DEST="/home/admin/.env"

if [ -f "$DEST" ]; then
    echo "Destination File exists..."
    echo "#####WORDPRESS#####" >> "$DEST"
    cat "$SOURCE" >> "$DEST"
else
    echo "File does not exist..."
    echo "#####WORDPRESS#####" >> "$DEST"

    cat "$SOURCE" >> "$DEST"
    echo "Master .env file created..."
fi


