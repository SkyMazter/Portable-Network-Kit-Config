#!/bin/bash

set -e

echo "Installing Etherpad..."
cd ~
echo "Creating Etherpad Directory..."
mkdir -p etherpad
cd etherpad

echo "Creating .env file..."
cat <<EOF > .env
POSTGRES_USER=admin
POSTGRES_PASSWORD=$(openssl rand -base64 16)
POSTGRES_DATABASE=etherpad
POSTGRES_PORT=5432
EOF

echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  app:
    user: "0:0"
    image: etherpad/etherpad:latest
    tty: true
    stdin_open: true
    volumes:
      - plugins:/opt/etherpad-lite/src/plugin_packages
      - etherpad-var:/opt/etherpad-lite/var
    depends_on:
      - postgres
    environment:
      NODE_ENV: production
      ADMIN_PASSWORD: \${DOCKER_COMPOSE_APP_ADMIN_PASSWORD:-admin}
      DB_CHARSET: \${DOCKER_COMPOSE_APP_DB_CHARSET:-utf8mb4}
      DB_HOST: postgres
      DB_NAME: \${POSTGRES_DATABASE}
      DB_PASS: \${POSTGRES_PASSWORD}
      DB_PORT: \${POSTGRES_PORT}
      DB_TYPE: "postgres"
      DB_USER: \${POSTGRES_USER}
      # For now, the env var DEFAULT_PAD_TEXT cannot be unset or empty; it seems to be mandatory in the latest version of etherpad
      DEFAULT_PAD_TEXT: \${DOCKER_COMPOSE_APP_DEFAULT_PAD_TEXT:- }
      DISABLE_IP_LOGGING: \${DOCKER_COMPOSE_APP_DISABLE_IP_LOGGING:-false}
      SOFFICE: \${DOCKER_COMPOSE_APP_SOFFICE:-null}
      TRUST_PROXY: \${DOCKER_COMPOSE_APP_TRUST_PROXY:-true}
    restart: always
    ports:
      - "\${DOCKER_COMPOSE_APP_PORT_PUBLISHED:-9001}:\${DOCKER_COMPOSE_APP_PORT_TARGET:-9001}"

  postgres:
    image: docker.io/postgres:15-alpine
    environment:
      POSTGRES_DB: \${POSTGRES_DATABASE}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_PORT: \${POSTGRES_PORT}
      POSTGRES_USER: \${POSTGRES_USER}
      PGDATA: /var/lib/postgresql/data/pgdata
    restart: always
    #   - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
  plugins:
  etherpad-var:
EOF

echo "Starting containers..."
sudo docker compose up -d

echo "Etherpad setup complete!"

echo "Updating the master .env records..."

SOURCE=".env"
DEST="/home/admin/.env"

if [ -f "$DEST" ]; then
    echo "Destination File exists..."
    echo "#####ETHERPAD#####" >> "$DEST"
    cat "$SOURCE" >> "$DEST"
else
    echo "File does not exist..."
    echo "#####ETHERPAD#####" >> "$DEST"

    cat "$SOURCE" >> "$DEST"
    echo "Master .env file created..."
fi

