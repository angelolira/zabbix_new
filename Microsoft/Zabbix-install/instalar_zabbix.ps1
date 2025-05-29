param([switch]$Elevated)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) 
    {
        # tried to elevate, did not work, aborting
    } 
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}

exit
}

'running with full privileges'

$url = "https://github.com/angelolira/zabbix_new/tree/main/Microsoft/Zabbix-install/zabbix-agent.zip"

$destino = "C:\zabbix-agent.zip"

Write-Host "Baixando arquivos..."
Invoke-WebRequest -Uri $url -OutFile $destino

Write-Host "Download concluído..."

#Descompactando
Expand-Archive -Force C:\zabbix-agent.zip C:\

#exluindo arquivo zip
del c:\zabbix-agent.zip

cd 'C:\Zabbix Agent'

timeout 2

#iniciando zabbix.

Start-Process -FilePath "iniciar-zabbix.bat" -Wait

Write-Host "SUCESSO, PODE ENCERRAR !"

exit
