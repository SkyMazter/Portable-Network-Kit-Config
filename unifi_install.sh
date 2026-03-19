echo "Starting UniFi OS Server installation..."

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root:"
  echo "sudo ./install_unifi_os.sh"
  exit 1
fi

echo "Installing Podman"
sudo apt install podman -y

INSTALL_FILE="df5b-linux-arm64-5.0.6-f35e944c-f4b6-4190-93a8-be61b96c58f4.6-arm64"
DOWNLOAD_URL="https://fw-download.ubnt.com/data/unifi-os-server/$INSTALL_FILE"

echo "Downloading UniFi OS installer..."
wget -O "$INSTALL_FILE" "$DOWNLOAD_URL"

echo "Making installer executable..."
chmod +x "$INSTALL_FILE"

echo "Running installer..."
./"$INSTALL_FILE"

echo "Adding service to usergroup..."
usermod -aG uosserver admin

echo "UniFi OS installation script completed."