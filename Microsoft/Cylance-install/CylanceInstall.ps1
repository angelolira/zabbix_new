$url = "http://172.16.0.109/install/ngav-windows/CylanceProtect_x64.exe"
$url2 = "http://172.16.0.109/install/ngav-windows/CylanceOptics_x64.exe"

$destino = "C:\CylanceProtect_x64.exe"
$destino2 = "C:\CylanceOptics_x64.exe"

Write-Host "Baixando arquivos..."
Invoke-WebRequest -Uri $url -OutFile $destino
Invoke-WebRequest -Uri $url2 -OutFile $destino2

Write-Host "Download concluído. Iniciando a instalação..."

# Renomeando os arquivos para terem extensão .msi
Rename-Item -Path $destino -NewName "CylanceProtect_x64.msi"
Rename-Item -Path $destino2 -NewName "CylanceOptics_x64.msi"

# Iniciando a instalação dos MSIs
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "C:\CylanceProtect_x64.msi", "/qn", "PIDKEY=muoGD9vMGb9qlu0uewT1TIZia", "LAUNCHAPP=0", "/L*v", "C:\cylance-install.log" -Wait
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "C:\CylanceOptics_x64.msi", "/qn" -Wait
