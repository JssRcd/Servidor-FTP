function Set-DashboardVirtual {
    param($userName)
    $iisPath = "IIS:\Sites\$global:siteName\LocalUser\$userName"
    $userJail = "$global:localUserPath\$userName"

    # 1. Limpiar portales viejos (Evita el bug de duplicados)
    $portales = @("general", "recursadores", "reprobados")
    foreach ($p in $portales) {
        if (Test-Path "$iisPath\$p") { Remove-Item "$iisPath\$p" -Force -Recurse }
    }

    # 2. Portal General (Y su carpeta 'fantasma' para visibilidad)
    New-WebVirtualDirectory -Site $global:siteName -Name "LocalUser/$userName/general" -PhysicalPath "$global:ftpRoot\general" -Force | Out-Null
    if (-not (Test-Path "$userJail\general")) { New-Item "$userJail\general" -ItemType Directory | Out-Null }

    # 3. Portal de Grupo (Detectar a cuál pertenece)
    $misGrupos = Get-LocalGroup | Where-Object { (Get-LocalGroupMember $_.Name -ErrorAction SilentlyContinue).Name -match $userName }
    foreach ($g in $misGrupos) {
        if ($global:gruposValidos -contains $g.Name) {
            $gName = $g.Name
            New-WebVirtualDirectory -Site $global:siteName -Name "LocalUser/$userName/$gName" -PhysicalPath "$global:ftpRoot\$gName" -Force | Out-Null
            if (-not (Test-Path "$userJail\$gName")) { New-Item "$userJail\$gName" -ItemType Directory | Out-Null }
        }
    }
}