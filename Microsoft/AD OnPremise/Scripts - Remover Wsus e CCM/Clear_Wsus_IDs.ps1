

Write-Host "parando serviço WUAUSERV"
Stop-Service -Name BITS, wuauserv -Force

Write-Host "Removendo registros do windows do wsus"
Remove-ItemProperty -Name SusClientId -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\
Remove-ItemProperty -Name SusClientIdValidation -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\

Write-Host "Removendo pasta de atualizações"
Rename-Item -Path "$env:SystemRoot\SoftwareDistribution\" -NewName "SoftwareDistribution-old"
Remove-Item "$env:SystemRoot\SoftwareDistribution-old\" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Recarregando os servicos"
Start-Service -Name BITS, wuauserv

wuauclt /resetauthorization /detectnow 

(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
