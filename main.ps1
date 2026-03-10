Import-Module WebAdministration

# Importar TODAS las dependencias
. .\config.ps1
. .\instalacion.ps1
. .\funciones.ps1
. .\gestionusuarios.ps1
. .\gestioniis.ps1

Write-Host 'Inicializando entorno...' -ForegroundColor Yellow

Install-FtpEnvironment
Initialize-FtpInfrastructure

# Sellar permisos base e inyectar el Aislamiento en IIS al arrancar
Set-PermisosCompartidos
C:\Windows\System32\inetsrv\appcmd.exe set site $global:siteName /ftpServer.userIsolation.mode:IsolateAllDirectories | Out-Null
Restart-Service ftpsvc -Force

do {
    Write-Host ''
    Write-Host '=== GESTION AUTOMATIZADA DE SERVIDOR FTP ===' -ForegroundColor Yellow
    Write-Host '1. Crear nuevos usuarios masivamente'
    Write-Host '2. Cambiar a un usuario de grupo'
    Write-Host '3. Salir'
    $opcion = Read-Host 'Elige una opcion'

    switch ($opcion) {
        '1' { Crear-Usuarios }
        '2' { Cambiar-Grupo }
        '3' { Write-Host 'Saliendo del sistema...'; break }
    }
} while ($opcion -ne '3')