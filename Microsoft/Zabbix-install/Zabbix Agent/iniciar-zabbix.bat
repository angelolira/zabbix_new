@echo off
cd /
cd zabbix
echo PARANDO O SERVICO...
zabbix_agentd.exe --stop
timeout 1
echo DESINSTALANDO AGENTE ANTIGO....
zabbix_agentd.exe --uninstall
timeout 1
cd ..
cd Zabbix Agent
echo INSTALANDO AGENTE NOVO....
zabbix_agentd.exe -i -c zabbix_agentd.conf
timeout 1
echo INICIALIZANDO SERVICO....
net start "Zabbix Agent"
timeout 1
echo DELETANDO PASTA ZABBIX ANTIGA....
cd /
del /f zabbix
timeout 1