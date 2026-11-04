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

newgrp docker

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


sudo apt update && sudo apt install xfce4-clipman xfce4-clipman-plugin -y

echo "=================================================="
echo " 6. Configurando e instalando AnyDesk..."
echo "=================================================="
curl -fsSL https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /usr/share/keyrings/anydesk-stable-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/anydesk-stable-keyring.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
sudo dpkg --configure -a
sudo apt update && sudo apt install anydesk -y

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

echo "=== 1. VERIFICACIÓN DE COMANDOS Y APPS ==="
for cmd in code tailscale anydesk remmina filezilla docker cron xfce4-clipman; do
  if command -v $cmd &> /dev/null; then
    echo -e " [OK]  $cmd está instalado"
  else
    echo -e " [X]   $cmd NO se encontró"
  fi
done

echo -e "\n=== 2. ESTADO DE SERVICIOS EN SEGUNDO PLANO ==="
for service in docker tailscaled cron fail2ban unattended-upgrades; do
  if systemctl is-active --quiet $service; then
    echo -e " [ACTIVO]    Servicio: $service"
  else
    echo -e " [INACTIVO]  Servicio: $service"
  fi
done

echo -e "\n=== 3. PERMISOS DE USUARIO PARA DOCKER ==="
if groups $USER | grep &>/dev/null \bdocker\b; then
  echo " [OK]  Tu usuario ($USER) pertenece al grupo docker"
else
  echo " [!]   Tu usuario NO pertenece al grupo docker (requiere sudo o reiniciar sesión)"
fi

echo -e "\n=== 4. ACCESO A REDES COMPARTIDAS (SAMBA/CIFS) ==="
if dpkg -l | grep -E "cifs-utils|smbclient" &>/dev/null; then
  echo " [OK]  Soportes de red Samba/CIFS instalados correctamente"
else
  echo " [X]   Faltan paquetes de red Samba"
fi
