#!/bin/bash
source ./config.sh
source ./gestion_permisos.sh
source ./gestion_vdir.sh

function Initialize-FtpInfrastructure {
    echo -e "\e[36m[*] Configurando Grupos y Estructura...\e[0m"
    
    # 1. Crear grupos locales si no existen
    for grupo in "${GRUPOS_VALIDOS[@]}"; do
        getent group "$grupo" >/dev/null || groupadd "$grupo"
    done

    # 2. Crear carpetas base
    mkdir -p "$FTP_ROOT/general" "$FTP_ROOT/reprobados" "$FTP_ROOT/recursadores"
    mkdir -p "$LOCAL_USER_PATH/Public/general"
    
    # 3. Configuración estricta de la jaula del Anónimo (Reglas de vsftpd)
    # vsftpd exige que la raíz del anónimo sea de root y no escribible
    chown root:root "$LOCAL_USER_PATH/Public"
    chmod 755 "$LOCAL_USER_PATH/Public"
    
    chown root:root "$FTP_ROOT/general"
    chmod 755 "$FTP_ROOT/general"

    # 4. Etiquetado de SELinux para contenido público
    chcon -R -t public_content_t "$LOCAL_USER_PATH/Public" 2>/dev/null
    chcon -R -t public_content_t "$FTP_ROOT/general" 2>/dev/null
    
    # 5. Montar portal virtual "general" en la jaula del anónimo
    if ! mountpoint -q "$LOCAL_USER_PATH/Public/general"; then
        mount --bind "$FTP_ROOT/general" "$LOCAL_USER_PATH/Public/general"
        echo "$FTP_ROOT/general $LOCAL_USER_PATH/Public/general none bind 0 0" >> /etc/fstab
    fi
}

function Crear-Usuarios {
    read -p "¿Cuántos usuarios deseas crear? " n
    for ((i=1; i<=n; i++)); do
        echo -e "\e[36m\n--- Usuario $i de $n ---\e[0m"
        read -p "Nombre de usuario: " user
        read -s -p "Contraseña: " pass; echo ""
        read -p "Grupo (1 = reprobados, 2 = recursadores): " grupoOp
        
        if [ "$grupoOp" == "1" ]; then
            grupoNombre="reprobados"
        else
            grupoNombre="recursadores"
        fi

        # Crear usuario sin shell de login (seguridad) y asignarle su grupo
        if ! id "$user" &>/dev/null; then
            useradd -M -d "$LOCAL_USER_PATH/$user" -s /sbin/nologin -G "$grupoNombre" "$user"
            echo "$user:$pass" | chpasswd
        else
            echo -e "\e[33m[!] El usuario $user ya existe. Actualizando estructura...\e[0m"
        fi

        # === MAGIA DE AISLAMIENTO Y DASHBOARD ===
        Set-CarpetaPersonal "$user"
        Set-DashboardVirtual "$user"

        echo -e "\e[32m[+] Usuario $user creado, enjaulado y Dashboard listo.\e[0m"
    done
}

function Cambiar-Grupo {
    read -p "Nombre del usuario a modificar: " user
    
    # Verificar si el usuario existe
    if ! id "$user" &>/dev/null; then
        echo -e "\e[31m[!] El usuario no existe.\e[0m"
        return
    fi

    read -p "Nuevo Grupo (1 = reprobados, 2 = recursadores): " nuevoGrupoOp
    
    if [ "$nuevoGrupoOp" == "1" ]; then
        nuevoGrupo="reprobados"
        viejoGrupo="recursadores"
    else
        nuevoGrupo="recursadores"
        viejoGrupo="reprobados"
    fi

    # Cambiar de grupo
    gpasswd -d "$user" "$viejoGrupo" 2>/dev/null
    usermod -aG "$nuevoGrupo" "$user"
    
    # === ACTUALIZACIÓN DINÁMICA ===
    Set-DashboardVirtual "$user"
    
    echo -e "\e[32m[+] Usuario $user movido a $nuevoGrupo y su vista FTP actualizada.\e[0m"
}
