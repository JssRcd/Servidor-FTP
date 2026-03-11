#!/bin/bash
source ./config.sh

function Set-DashboardVirtual {
    local userName=$1
    local userJail="$LOCAL_USER_PATH/$userName"
    
    # Limpiar montajes viejos de este usuario si existen
    for p in "general" "${GRUPOS_VALIDOS[@]}"; do
        if mountpoint -q "$userJail/$p"; then
            umount "$userJail/$p"
            sed -i "\|\s$userJail/$p\s|d" /etc/fstab # Borrar de fstab
        fi
    done

    # 1. Montar portal General
    mkdir -p "$userJail/general"
    mount --bind "$FTP_ROOT/general" "$userJail/general"
    echo "$FTP_ROOT/general $userJail/general none bind 0 0" >> /etc/fstab

    # 2. Montar portal de Grupo
    # Obtenemos a qué grupo de FTP pertenece el usuario
    for gName in "${GRUPOS_VALIDOS[@]}"; do
        if id -nG "$userName" | grep -qw "$gName"; then
            mkdir -p "$userJail/$gName"
            mount --bind "$FTP_ROOT/$gName" "$userJail/$gName"
            echo "$FTP_ROOT/$gName $userJail/$gName none bind 0 0" >> /etc/fstab
        fi
    done
}
