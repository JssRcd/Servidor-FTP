#!/bin/bash

# Validar que se ejecute como Root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mPor favor ejecuta este script como root (sudo ./main.sh)\e[0m"
  exit 1
fi

source ./config.sh
source ./instalacion.sh
source ./gestion_permisos.sh
source ./gestion_vdir.sh
source ./funciones.sh

echo -e "\e[33mInicializando entorno en Fedora...\e[0m"

Install-FtpEnvironment
Initialize-FtpInfrastructure
Set-PermisosCompartidos
systemctl restart vsftpd

while true; do
    echo ""
    echo -e "\e[33m=== GESTION AUTOMATIZADA DE SERVIDOR FTP (LINUX) ===\e[0m"
    echo "1. Crear nuevos usuarios masivamente"
    echo "2. Cambiar a un usuario de grupo"
    echo "3. Salir"
    read -p "Elige una opcion: " opcion

    case $opcion in
        1) Crear-Usuarios ;;
        2) Cambiar-Grupo ;;
        3) echo "Saliendo del sistema..."; break ;;
        *) echo "Opción no válida." ;;
    esac
done
