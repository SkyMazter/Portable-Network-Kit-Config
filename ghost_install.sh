#!/bin/bash

# Exit if any command fails
set -e

echo "Installing Ghost..."
echo "Creating Ghost project directory..."
mkdir -p ghost-server
cd ghost-server

echo "Creating .env file..."
cat <<EOF > .env
GHOST_USER=ghostuser
GHOST_DATABASE=ghostdb
GHOST_DB_ROOTPASSWORD=$(openssl rand -base64 16)
GHOST_PASSWORD=$(openssl rand -base64 16)
EOF

echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  ghost:
    image: ghost:latest
    restart: always
    ports:
      - 80:2368
    environment:
      url: http://pnk.local
      database__client: mysql
      database__connection__host: db
      database__connection__user: \${GHOST_USER}
      database__connection__password: \${GHOST_PASSWORD}
      database__connection__database: \${GHOST_DATABASE}
    depends_on:
      - db
    volumes:
      - ./ghost-data:/var/lib/ghost/content

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${GHOST_DB_ROOTPASSWORD}
      MYSQL_DATABASE: \${GHOST_DATABASE}
      MYSQL_USER: \${GHOST_USER}
      MYSQL_PASSWORD: \${GHOST_PASSWORD}
    volumes:
      - ./mysql-data:/var/lib/mysql
EOF

echo "Starting containers..."
sudo docker compose up -d

echo "Ghost setup complete!"