
# referencia 
# https://docs.microsoft.com/en-us/archive/blogs/michaelgriswold/manual-removal-of-the-sccm-client

New-Item -Path C:\tmp -ItemType Directory
Start-Transcript -Path "C:\tmp\remove_CCMSetup_log.txt"

Write-Host "Desinstalando o pacote CCMSetup... "

Get-Service -Name ccm*
Get-Service -Name ccmusetp* | Stop-Service
Get-Service -Name ccmexec* | Stop-Service

Write-Host "desinstalando ccmsetup" -ForegroundColor Yellow
Start-Process "C:\windows\ccmsetup\ccmsetup.exe" /uninstall

Write-Host "Validar se a remoção foi concluída, em seguida pressione ENTER..." -ForegroundColor Cyan
pause

 
# Stop the Service "SMS Agent Host" which is a Process "CcmExec.exe"
Write-Host "Stop dos serviços... "
Get-Service -Name CcmExec -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose

# Stop the Service "ccmsetup" which is also a Process "ccmsetup.exe" if it wasn't stopped in the services after uninstall
Get-Service -Name ccmsetup -ErrorAction SilentlyContinue | Stop-Service -Force -Verbose

# Delete the folder of the SCCM Client installation: "C:\Windows\CCM"
Write-Host ""
Write-Host "Removendo diretorios de instalacao, cache e .ini".ToUpper() -ForegroundColor Yellow
Remove-Item -Path "$($Env:WinDir)\CCM" -Force -Recurse -Confirm:$false -Verbose

# Delete the folder of the SCCM Client Cache of all the packages and Applications that were downloaded and installed on the Computer: "C:\Windows\ccmcache"
Remove-Item -Path "$($Env:WinDir)\CCMSetup" -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path "$($Env:WinDir)\SysWOW64\CCMSetup" -Force -Recurse -Confirm:$false -Verbose

# Delete the folder of the SCCM Client Setup files that were used to install the client: "C:\Windows\ccmsetup"
Remove-Item -Path "$($Env:WinDir)\CCMCache" -Force -Recurse -Confirm:$false -Verbose

# Delete the file with the certificate GUID and SMS GUID that current Client was registered with
Remove-Item -Path "$($Env:WinDir)\smscfg.ini" -Force -Confirm:$false -Verbose

# Delete the certificate itself
Write-Host ""
Write-Host "removendo registros do windows".ToUpper() -ForegroundColor Yellow
Remove-Item -Path 'HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*' -Force -Confirm:$false -Verbose

# Remove all the registry keys associated with the SCCM Client that might not be removed by ccmsetup.exe
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM' -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\SMS' -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS' -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path 'HKLM:\Software\Microsoft\CCMSetup' -Force -Recurse -Confirm:$false -Verbose
#Remove-Item -Path 'HKLM:\Software\Wow6432Node\Microsoft\CCMSetup' -Force -Confirm:$false -Recurse -Verbose
#Remove-Item -Path 'HKLM:\SYSTEM\ControlSet002\Services\CCMSetup' -Force -Confirm:$false -Recurse -Verbose
#Remove-Item -Path 'HKLM:\SYSTEM\ControlSet002\Services\CcmExec' -Force -Confirm:$false -Recurse -Verbose


# Remove the service from "Services"
Write-Host ""
Write-Host "Removendo serviços do services".ToUpper() -ForegroundColor Yellow
Remove-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\CcmExec' -Force -Recurse -Confirm:$false -Verbose
Remove-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\ccmsetup' -Force -Recurse -Confirm:$false -Verbose

# Remove the Namespaces from the WMI repository
Write-Host ""
Write-Host "Removendo registros WMI...".ToUpper() -ForegroundColor Yellow
Get-CimInstance -query "Select * From __Namespace Where Name='CCM'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" | Remove-CimInstance -Verbose -Confirm:$false

# Alternative command for WMI Removal in case of something goes wrong with the above.
# Get-WmiObject -query "Select * From __Namespace Where Name='CCM'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" | Remove-WmiObject -Verbose | Out-Host

Stop-Transcript