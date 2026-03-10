function Initialize-FtpInfrastructure {
    Write-Host '[*] Configurando Grupos Locales y Estructura...' -ForegroundColor Cyan
    foreach ($grupo in $global:gruposValidos) {
        if (-not (Get-LocalGroup -Name $grupo -ErrorAction SilentlyContinue)) {
            New-LocalGroup -Name $grupo -Description "Grupo FTP: $grupo" | Out-Null
        }
    }

    # Crear todas las carpetas, incluida la jaula Pública para el Anónimo
    $carpetas = @('general', 'reprobados', 'recursadores', 'LocalUser', 'LocalUser\Public', 'LocalUser\Public\general')
    foreach ($carpeta in $carpetas) {
        $ruta = "$global:ftpRoot\$carpeta"
        if (-not (Test-Path $ruta)) { New-Item -Path $ruta -ItemType Directory -Force | Out-Null }
    }

    # Preparar al Anónimo
    icacls "$global:localUserPath\Public" /inheritance:r /Q
    icacls "$global:localUserPath\Public" /grant "Todos:(OI)(CI)(RX)" /Q
    New-WebVirtualDirectory -Site $global:siteName -Name "LocalUser/Public/general" -PhysicalPath "$global:ftpRoot\general" -Force -ErrorAction SilentlyContinue | Out-Null
}

function Crear-Usuarios {
    $n = Read-Host "`n¿Cuántos usuarios deseas crear?"
    for ($i=1; $i -le $n; $i++) {
        Write-Host "`n--- Usuario $i de $n ---" -ForegroundColor Cyan
        $user = Read-Host 'Nombre de usuario'
        $pass = Read-Host 'Contraseña'
        $grupoOp = Read-Host 'Grupo (1 = reprobados, 2 = recursadores)'
        
        $grupoNombre = if ($grupoOp -eq '1') { 'reprobados' } else { 'recursadores' }

        if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
            $securePass = ConvertTo-SecureString $pass -AsPlainText -Force
            New-LocalUser -Name $user -Password $securePass -PasswordNeverExpires | Out-Null
        }
        
        Add-LocalGroupMember -Group $grupoNombre -Member $user -ErrorAction SilentlyContinue

        # === AQUÍ INYECTAMOS TU NUEVA TECNOLOGÍA ===
        # En lugar de solo crear su carpeta suelta, lo enjaulamos y le hacemos su Dashboard
        Set-CarpetaPersonal -userName $user
        Set-DashboardVirtual -userName $user

        Write-Host "[+] Usuario $user creado, enjaulado y Dashboard listo." -ForegroundColor Green
    }
}

function Cambiar-Grupo {
    $user = Read-Host "`nNombre del usuario a modificar"
    $nuevoGrupoOp = Read-Host 'Nuevo Grupo (1 = reprobados, 2 = recursadores)'
    
    $nuevoGrupo = if ($nuevoGrupoOp -eq '1') { 'reprobados' } else { 'recursadores' }
    $viejoGrupo = if ($nuevoGrupoOp -eq '1') { 'recursadores' } else { 'reprobados' }

    Remove-LocalGroupMember -Group $viejoGrupo -Member $user -ErrorAction SilentlyContinue
    Add-LocalGroupMember -Group $nuevoGrupo -Member $user -ErrorAction SilentlyContinue
    
    # === MAGIA DE ACTUALIZACIÓN ===
    # Al cambiar de grupo, le re-hacemos sus portales para que deje de ver el viejo y vea el nuevo
    Set-DashboardVirtual -userName $user

    Write-Host "[+] Usuario $user movido a $nuevoGrupo y su vista en FileZilla fue actualizada." -ForegroundColor Green
}