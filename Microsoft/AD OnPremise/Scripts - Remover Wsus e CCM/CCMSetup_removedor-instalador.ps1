
Write-Host "parando serviço CCM"

Get-Service -Name ccm*
Get-Service -Name ccmsetup* | Stop-Service
Get-Service -Name ccmexec* | Stop-Service

Write-Host "desinstalando ccmsetup"
Start-Process "C:\windows\ccmsetup\ccmsetup.exe" /uninstall