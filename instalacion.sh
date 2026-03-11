#!/bin/bash
source ./config.sh

function Install-FtpEnvironment {
    echo -e "\e[33m[*] Instalando vsftpd y herramientas necesarias...\e[0m"
    dnf install -y vsftpd acl policycoreutils-python-utils > /dev/null 2>&1

    # Configuración maestra de vsftpd
    cat <<EOF > /etc/vsftpd/vsftpd.conf
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
pam_service_name=vsftpd
userlist_enable=YES
# --- CONFIGURACION DE LA JAULA (CHROOT) ---
chroot_local_user=YES
allow_writeable_chroot=YES
local_root=$LOCAL_USER_PATH/\$USER
user_sub_token=\$USER
# --- REGLAS DEL ANONIMO ---
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
anon_root=$LOCAL_USER_PATH/Public
EOF

    echo -e "\e[33m[*] Configurando Firewall y SELinux...\e[0m"
    firewall-cmd --permanent --add-service=ftp > /dev/null
    firewall-cmd --reload > /dev/null
    
    # Domando a SELinux para permitir FTP y lectura/escritura en nuestra ruta
    setsebool -P allow_ftpd_full_access 1
    setsebool -P ftpd_anon_write 0
    
    systemctl enable vsftpd --now > /dev/null
}
