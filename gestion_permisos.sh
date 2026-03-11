#!/bin/bash
source ./config.sh

function Set-CarpetaPersonal {
    local userName=$1
    local userJail="$LOCAL_USER_PATH/$userName"
    local userPersonal="$userJail/$userName"

    mkdir -p "$userPersonal"
    
    # Dueño de la jaula y la carpeta personal
    chown -R $userName:$userName "$userJail"
    
    # La jaula es Solo Lectura (550), la carpeta personal es Modificable (700)
    chmod 550 "$userJail"
    chmod 700 "$userPersonal"
}

function Set-PermisosCompartidos {
    echo -e "\e[36m[*] Aplicando ACLs maestras...\e[0m"
    local rutaGen="$FTP_ROOT/general"
    
    # Limpiar ACLs previas
    setfacl -b -R "$rutaGen"
    
    # Permisos Base para la carpeta general
    # Dueño: root, Grupo: root. Permisos base: 755 (Lectura para todos)
    chown root:root "$rutaGen"
    chmod 755 "$rutaGen"
    
    # El usuario anónimo en vsftpd se llama 'ftp'. Le damos solo lectura explícita.
    setfacl -m u:ftp:r-x "$rutaGen"
    setfacl -d -m u:ftp:r-x "$rutaGen" # Por defecto para futuros archivos
    
    # Los grupos tienen permiso de Modificar y Subir (rwx)
    for grupo in "${GRUPOS_VALIDOS[@]}"; do
        local rutaGrupo="$FTP_ROOT/$grupo"
        setfacl -m g:$grupo:rwx "$rutaGen"
        setfacl -d -m g:$grupo:rwx "$rutaGen"
        
        # Permisos para las carpetas de grupo
        chown root:$grupo "$rutaGrupo"
        chmod 770 "$rutaGrupo" # Solo el grupo entra y modifica
    done
    
    # Etiquetado SELinux final
    semanage fcontext -a -t public_content_rw_t "$FTP_ROOT(/.*)?" 2>/dev/null
    restorecon -R "$FTP_ROOT"
}
