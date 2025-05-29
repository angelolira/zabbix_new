
Write-Host "Antes da execução, remova a função de restart dos serviços BITs e Windows Update,".ToUpper() -ForegroundColor Yellow
Write-Host "para evitar que os mesmos sejam recarregados antes da conclusão do script." -ForegroundColor Yellow
Write-Host "Após validado, continue a execução do script." -ForegroundColor Yellow
Write-Host "" -ForegroundColor Yellow

Write-Host ""
Write-Host "Parando serviço WUAUSERV." -ForegroundColor Yellow
Stop-Service -Name BITS, wuauserv -Force

$status1 = Get-Service BITS, wuauserv | Select-Object -Property Name, StartType, Status
Write-Host $status1 -ForegroundColor Cyan
Write-Host ""

Write-Host "Removendo registros do windows do wsus" -ForegroundColor Yellow
Remove-ItemProperty -Name SusClientId -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\
Remove-ItemProperty -Name SusClientIdValidation -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\

pause
Write-Host ""
Stop-Service -Name BITS, wuauserv -Force
Write-Host "Removendo pasta de atualizações, confira" -ForegroundColor Yellow
Rename-Item -Path "$env:SystemRoot\SoftwareDistribution\" -NewName "SoftwareDistribution-old"
Remove-Item "$env:SystemRoot\SoftwareDistribution-old\" -Recurse -Force -ErrorAction SilentlyContinue

Pause
Write-Host ""
Write-Host "Recarregando os servicos.. "
Start-Service -Name BITS, wuauserv

wuauclt /resetauthorization /detectnow 

(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()

#Get-Service BITS, wuauserv | Select-Object -Property Name, StartType, Status
Write-Host ""
Write-Host "Configurando BITs e Update para inicio automatico" -ForegroundColor Yellow
Set-Service -Name BITS -StartupType Automatic 
Set-Service -Name wuauserv -StartupType Automatic 

Write-Host ""
$status2 = Get-Service BITS, wuauserv | Select-Object -Property Name, StartType, Status
Write-Host $status2