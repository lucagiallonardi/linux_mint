#!/bin/bash

# Verificar que se ejecute con privilegios de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecutá el script con sudo: sudo ./setup.sh"
  exit 1
fi

echo "=================================================="
echo " 1. Actualizando índices del sistema..."
echo "=================================================="
apt update && apt upgrade -y

echo "=================================================="
echo " 2. Instalando utilidades básicas, Cron y Samba..."
echo "=================================================="
# cifs-utils y smbclient permiten acceder a recursos compartidos de red (Windows/NAS)
apt install -y curl wget git remmina remmina-plugin-rdp filezilla ufw apt-transport-https \
               cron samba cifs-utils smbclient gvfs-backends gvfs-fuse

echo "=================================================="
echo " 3. Instalando Docker y Docker Compose..."
echo "=================================================="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Asignar usuario al grupo docker para usar 'docker' sin sudo (se activa al reiniciar/reinciar sesión)
if [ -n "$SUDO_USER" ]; then
  usermod -aG docker "$SUDO_USER"
fi

echo "=================================================="
echo " 4. Configurando Seguridad y Actualizaciones Automáticas..."
echo "=================================================="
# unattended-upgrades aplica parches de seguridad oficiales de forma automática
apt install -y unattended-upgrades fail2ban
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "=================================================="
echo " 5. Instalando Tailscale..."
echo "=================================================="
curl -fsSL https://tailscale.com/install.sh | sh

echo "=================================================="
echo " 6. Configurando e instalando AnyDesk..."
echo "=================================================="
wget -qO - https://keys.anydesk.com/repos/gpg-key.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/anydesk.gpg
echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk.list
apt update
apt install -y anydesk

echo "=================================================="
echo " 7. Instalando Visual Studio Code..."
echo "=================================================="
wget -O /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
apt install -y /tmp/vscode.deb
rm -f /tmp/vscode.deb

echo "=================================================="
echo " ¡Instalación finalizada con éxito!"
echo " Reiniciá tu PC para aplicar los permisos de grupo Docker."
echo "=================================================="
