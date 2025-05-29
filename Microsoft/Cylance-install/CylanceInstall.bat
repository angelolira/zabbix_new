@echo off
set url=http://172.16.0.109/install/ngav-windows/CylanceProtect_x64.exe
set url2=http://172.16.0.109/install/ngav-windows/CylanceOptics_x64.exe

set destino=C:\CylanceProtect_x64.exe
set destino2=C:\CylanceOptics_x64.exe

echo Baixando arquivo...
bitsadmin.exe /transfer "Download" %url% %destino%
bitsadmin.exe /transfer "Download" %url2% %destino2%


echo Download concluído. Iniciando a instalação...
c:\
cd\
ren CylanceProtect_x64.exe CylanceProtect_x64.msi
ren CylanceOptics_x64.exe CylanceOptics_x64.msi

msiexec /i CylancePROTECT_x64.msi /qn PIDKEY=muoGD9vMGb9qlu0uewT1TIZia LAUNCHAPP=0 /L*v C:\cylance-install.log
msiexec /i CylanceOptics_x64.msi /qn
