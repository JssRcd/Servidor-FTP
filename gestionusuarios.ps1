function Set-CarpetaPersonal {
    param($userName)
    $userJail = "$global:localUserPath\$userName"
    $userPersonal = "$userJail\$userName"

    if (-not (Test-Path $userJail)) { New-Item $userJail -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $userPersonal)) { New-Item $userPersonal -ItemType Directory -Force | Out-Null }

    # Sellar Habitación: (OI)(CI)(RX) permite atravesar las carpetas fantasma
    # pero NO permite crear archivos sueltos en la raíz.
    icacls $userJail /inheritance:r /Q
    icacls $userJail /grant "${userName}:(OI)(CI)(RX)" /Q
    icacls $userJail /grant "Administradores:(OI)(CI)F" /Q
    icacls $userJail /grant "SYSTEM:(OI)(CI)F" /Q

    # Sellar Carpeta Personal: Control Total / Modificar
    icacls $userPersonal /inheritance:r /Q
    icacls $userPersonal /grant "${userName}:(OI)(CI)M" /Q
    icacls $userPersonal /grant "Administradores:(OI)(CI)F" /Q
    icacls $userPersonal /grant "SYSTEM:(OI)(CI)F" /Q
}

function Set-PermisosCompartidos {
    Write-Host "[*] Aplicando NTFS con SIDs y Herencia Corregida..." -ForegroundColor Cyan

    # === 1. CARPETA GENERAL (Tu código original perfeccionado) ===
    $rutaGen = "$global:ftpRoot\general"
    icacls $rutaGen /inheritance:r /Q
    
    # S-1-1-0 = Todos (incluye Anonymous) -> SOLO LECTURA
    icacls $rutaGen /grant "*S-1-1-0:(OI)(CI)(RX)" /Q
    
    # S-1-5-11 = Usuarios Autenticados (con contraseña) -> MODIFICAR Y SUBIR
    icacls $rutaGen /grant "*S-1-5-11:(OI)(CI)M" /Q
    
    icacls $rutaGen /grant "Administradores:(OI)(CI)F" /Q
    icacls $rutaGen /grant "SYSTEM:(OI)(CI)F" /Q

    # === 2. CARPETAS DE GRUPO ===
    foreach ($grupo in $global:gruposValidos) {
        $rutaGrupo = "$global:ftpRoot\$grupo"
        icacls $rutaGrupo /inheritance:r /Q
        
        # Solo su grupo puede entrar y modificar
        icacls $rutaGrupo /grant "${grupo}:(OI)(CI)M" /Q
        icacls $rutaGrupo /grant "Administradores:(OI)(CI)F" /Q
        icacls $rutaGrupo /grant "SYSTEM:(OI)(CI)F" /Q
    }
}