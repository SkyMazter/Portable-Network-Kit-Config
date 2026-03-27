#!/bin/bash

set -e

echo "#####...Installing Wordpress...#####"
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
      MYSQL_ROOT_PASSWORD: \${ROOT_DB_PASSWORD}
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: \${DB_PASSWORD}
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
      WORDPRESS_DB_PASSWORD: \${DB_PASSWORD}
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
DEST="~/.env"

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

echo "#####...Installing Etherpad...#####"
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
DEST="~/.env"

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

#!/bin/bash

set -e

#!/bin/bash

set -e

echo "Installing OwnCloud..."
cd ~
echo "Creating OwnCloud Directory..."
mkdir -p owncloud
cd owncloud

echo "Creating .env file..."
cat <<EOF > .env
OWNCLOUD_VERSION=10.16
OWNCLOUD_DOMAIN=localhost:8080
OWNCLOUD_TRUSTED_DOMAINS=localhost, pnkv4, pnkv4.local
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$(openssl rand -base64 16)
OWNCLOUD_DB_USERNAME=owncloud
OWNCLOUD_DB_PASSWORD=$(openssl rand -base64 16)
OWNCLOUD__ROOTDB_PASSWORD=$(openssl rand -base64 16)
HTTP_PORT=9003
EOF

echo "Creating docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  owncloud:
    image: owncloud/server:\${OWNCLOUD_VERSION}
    container_name: owncloud_server
    restart: always
    ports:
      - \${HTTP_PORT}:8080
    depends_on:
      - mariadb
      - redis
    environment:
      - OWNCLOUD_DOMAIN=\${OWNCLOUD_DOMAIN}
      - OWNCLOUD_TRUSTED_DOMAINS=\${OWNCLOUD_TRUSTED_DOMAINS}
      - OWNCLOUD_DB_TYPE=mysql
      - OWNCLOUD_DB_NAME=owncloud
      - OWNCLOUD_DB_USERNAME=\${OWNCLOUD_DB_USERNAME}
      - OWNCLOUD_DB_PASSWORD=\${OWNCLOUD_DB_PASSWORD}
      - OWNCLOUD_DB_HOST=mariadb
      - OWNCLOUD_ADMIN_USERNAME=\${ADMIN_USERNAME}
      - OWNCLOUD_ADMIN_PASSWORD=\${ADMIN_PASSWORD}
      - OWNCLOUD_MYSQL_UTF8MB4=true
      - OWNCLOUD_REDIS_ENABLED=true
      - OWNCLOUD_REDIS_HOST=redis
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - ./file-data:/mnt/data

  mariadb:
    image: mariadb:latest # minimum required ownCloud version is 10.9
    container_name: owncloud_mariadb
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=\${OWNCLOUD__ROOTDB_PASSWORD}
      - MYSQL_USER=\${OWNCLOUD_DB_USERNAME}
      - MYSQL_PASSWORD=\${OWNCLOUD_DB_PASSWORD}
      - MYSQL_DATABASE=owncloud
      - MARIADB_AUTO_UPGRADE=1
    command: ["--max-allowed-packet=128M", "--innodb-log-file-size=64M"]
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-u", "root", "--password=\${OWNCLOUD_DB_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - ./mysql-data:/var/lib/mysql

  redis:
    image: redis:6
    container_name: owncloud_redis
    restart: always
    command: ["--databases", "1"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - ./redis-data:/data
volumes:
  files:
    driver: local
  mysql:
    driver: local
  redis:
    driver: local
EOF

echo "Starting containers..."
sudo docker compose up -d

echo "OwnCloud setup complete!"

echo "Updating the master .env records..."

SOURCE=".env"
DEST="~/.env"

if [ -f "$DEST" ]; then
    echo "Destination File exists..."
    echo "#####OWNCLOUD#####" >> "$DEST"
    cat "$SOURCE" >> "$DEST"
else
    echo "File does not exist..."
    echo "#####OWNCLOUD#####" >> "$DEST"

    cat "$SOURCE" >> "$DEST"
    echo "Master .env file created..."
fi

echo "#####...Installing Matrix...#####"

#!/bin/bash
set -e

echo "Starting Matrix setup..."

SYNAPSE_DIR="$HOME/matrix"

# Create directory
echo "Creating Matrix directory..."
mkdir -p "$SYNAPSE_DIR"
cd "$SYNAPSE_DIR"

echo "Creating .env File with AutoGenerated Password..."
cat <<EOF > .env
POSTGRES_USER=matrix
POSTGRES_PASSWORD=$(openssl rand -base64 16)
EOF

# Create docker-compose.yml
echo "Creating docker-compose.yml..."

cat <<EOF > docker-compose.yml
services:
  synapse:
    container_name: synapse
    build:
      context: ../..
      dockerfile: docker/Dockerfile
    image: docker.io/matrixdotorg/synapse:latest
    restart: unless-stopped
    environment:
      - SYNAPSE_CONFIG_PATH=/data/homeserver.yaml
      - SYNAPSE_REPORT_STATS=yes
    volumes:
      - ./files:/data
    depends_on:
      - postgres-db
    ports:
      - 8008:8008

  postgres-db:
    container_name: postgres-db
    image: docker.io/postgres:15-alpine
    environment:
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - ./schemas:/var/lib/postgresql/data
  cinny:
    container_name: cinny
    image: ajbura/cinny:latest
    ports:
      - 9002:80
EOF

echo "docker-compose.yml created."

# Create required folders
mkdir -p files
mkdir -p schemas

# Ask for server name
read -p "Enter your Matrix server name (example: matrix.example.com): " SERVER_NAME

echo "Generating Matrix configuration..."

sudo docker compose run --rm \
  -e SYNAPSE_SERVER_NAME="$SERVER_NAME" \
  -e SYNAPSE_REPORT_STATS=yes \
  synapse generate

echo "Starting Matrix containers..."
sudo docker compose up -d

echo "Waiting for Matrix container to initialize..."
sleep 10

echo ""
echo "Create admin user:"
echo "Run the following command:"
echo ""
echo "docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml"
echo ""

docker compose run --rm -e SYNAPSE_SERVER_NAME=$SERVER_NAME synapse generate

# Modify config
cat <<EOF | sudo tee -a homeserver.yaml > /dev/null
enable_registration: true
enable_registration_without_verification: true
EOF

# Start server
docker compose up -d
echo "Synapse setup complete."
echo "Cinny setup complete."
echo "Create your admin user"

docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml

echo "Updating the master .env records..."

SOURCE=".env"
DEST="~/.env"

if [ -f "$DEST" ]; then
    echo "Destination File exists..."
    echo "#####MATRIX#####" >> "$DEST"
    cat "$SOURCE" >> "$DEST"
else
    echo "File does not exist..."
    echo "#####MATRIX#####" >> "$DEST"

    cat "$SOURCE" >> "$DEST"
    echo "Master .env file created..."
fi

echo "You can now access Matrix via Cinny on http://$HOSTNAME:9002"
