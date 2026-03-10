function Install-FtpEnvironment {
    Write-Host '[*] Verificando e Instalando IIS y FTP Server...' -ForegroundColor Cyan
    Install-WindowsFeature Web-FTP-Server, Web-FTP-Ext, Web-FTP-Service, Web-Server -IncludeManagementTools | Out-Null
    Start-Service ftpsvc
    Set-Service ftpsvc -StartupType Automatic

    $siteName = 'SitioFTP_Tarea5'
    $ftpRoot = 'C:\FTP_Server'

    # Crear la carpeta física antes de que IIS la busque
    if (-not (Test-Path $ftpRoot)) { New-Item -Path $ftpRoot -ItemType Directory -Force | Out-Null }

    if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
        Remove-Website -Name $siteName
    }

    # Crear sitio FTP
    New-WebFtpSite -Name $siteName -Port 21 -PhysicalPath $ftpRoot -Force | Out-Null
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "ftpServer.security.ssl.controlChannelPolicy" -Value "SslAllow"
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "ftpServer.security.ssl.dataChannelPolicy" -Value "SslAllow"
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "ftpServer.security.authentication.basicAuthentication.enabled" -Value $true
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "ftpServer.security.authentication.anonymousAuthentication.enabled" -Value $true
    Set-ItemProperty "IIS:\Sites\$siteName" -Name "ftpServer.userIsolation.mode" -Value "None"

    # MAGIA: Escribir en la configuración global apuntando a nuestro sitio para evitar el bloqueo
    Clear-WebConfiguration -Filter /system.ftpServer/security/authorization -PSPath "IIS:\" -Location $siteName
    Add-WebConfiguration -Filter /system.ftpServer/security/authorization -PSPath "IIS:\" -Location $siteName -Value @{accessType='Allow'; users='?'; permissions='Read'}
    Add-WebConfiguration -Filter /system.ftpServer/security/authorization -PSPath "IIS:\" -Location $siteName -Value @{accessType='Allow'; users='*'; permissions='Read, Write'}

    Restart-Service ftpsvc -Force
    Write-Host '[+] Entorno FTP base instalado y asegurado.' -ForegroundColor Green
}