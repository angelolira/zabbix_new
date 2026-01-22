#!/bin/bash
clear

#Variaveis de ambiente
arquivosdl="https://raw.githubusercontent.com/angelolira/zabbix_new/refs/heads/main/Linux/zabbix/zabbix_agentd.conf"
arquivotar="zabbix_agentd.conf"
zabbixconf="zabbix_agentd.conf"
zabbixexec="/usr/sbin/zabbix_agentd"
zabbixdir="/etc/zabbix"
zabbixdirextra="/etc/zabbix/zabbix_agentd.d"
validaversaoSO=$(uname -r | cut -f 6 -d ".")

#System#

main () {

if [ "$(id -u)" != "0" ]; then
	echo -e "\e[1;31mO script deve ser executado como root.\e[0m"
	exit 0;

else

	echo -e "\e[1;31m----------------------------------------------------\e[0m"
	echo -e "\e[1;31mBEM VINDO A INSTALACAO DO ZABBICADA\e[0m"
	echo "O que deseja fazer?"
	echo "1 - Instalar Zabbix"
	echo "2 - Remover Zabbix"
	echo "0 - Sair"
	echo -ne "\e[1;31mDigite sua opcao: \e[0m"

	read resultado

	case $resultado in 

	1) zabbix_install;;
	2) zabbix_remove;;
	0) exit 0;;
	*) echo -e "\e[1;31mOpcao invalida\e[0m" ; main  ;;

	esac
fi
}

zabbix_install () {

	echo 
	echo -ne  "\e[1;31mVerificando versao do SO... "

	case $MACHTYPE in

	x86_64-redhat-linux-gnu)
	

		if [ "$validaversaoSO" = "el9" ] || [ "$validaversaoSO" = "el9_1" ] || [ "$validaversaoSO" = "el9_2" ] || [ "$validaversaoSO" = "el9_3" ] || [ "$validaversaoSO" = "el9_4" ] || [ "$validaversaoSO" = "el9_5" ] || [ "$validaversaoSO" = "el9_6" ] || [ "$validaversaoSO" = "el9_7" ] || [ "$validaversaoSO" = "el9_8" ] || [ "$validaversaoSO" = "el9_9" ]; then

			echo "encontrado SO Linux CentOS/RedHat versao 9 64 bits."
			echo -e "Iniciando instalacao\e[0m"
			sleep 2;
			echo

			ps -s | grep zabbix_agentd | grep -v grep 2>&1 
			result=$?

			if [ "$result" -eq "0" ]  || [ -e "$zabbixexec" ]; then
				echo -ne "\e[1;31mZabbix ja existente, deseja atualizar? [Y/N] \e[0m"
				read resultinstall
				case $resultinstall in
				[yY]) zabbix_update;;
				[nN]) echo -en "\e[1;31mFinalizando script\e[0m"; exit 0;;
				*) echo -en "\e[1;31mOpcao invalida, utilize Y para Sim ou N para Nao\e[0m" ; sleep 2 ; zabbix_install ;;
				esac
			fi
			#rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-agent-6.0.30-release1.el9.x86_64.rpm 2>&1
			rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm 2>&1
				
			if [ $? -eq 0 ]; then

				yum install -y zabbix-agent 
				systemctl enable zabbix-agent 
				sleep 2;
				echo -e "\e[0m"
				echo
				zabbix_update
			else 
					echo
					echo -e "\e[1;31mFalha ao instalar zabbix\e[0m"
					exit 0;
			fi
		
		
		elif [ "$validaversaoSO" = "el6" ] || [ "$validaversaoSO" = "" ]; then
		
			echo "encontrado SO Linux CentOS/RedHat versao 6 64 bits."
			echo -e "Iniciando instalacao\e[0m"
			sleep 2;
			echo

			ps -s | grep zabbix_agentd | grep -v grep 2>&1
			result=$?
                        if [ "$result" -eq "0" ]  || [ -e "$zabbixexec" ]; then
                                echo -ne "\e[1;31mZabbix ja existente, deseja atualizar? [Y/N] \e[0m"
                                read resultinstall
                                case $resultinstall in
                                [yY]) zabbix_update;;
                                [nN]) echo -en "\e[1;31mFinalizando script\e[0m"; exit 0;;
                                *) echo -en "\e[1;31mOpcao invalida, utilize Y para Sim ou N para Nao\e[0m" ; sleep 2 ; zabbix_install ;;
                                esac
                        fi
            		#rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-agent-6.0.30-release1.el9.x86_64.rpm 2>&1
           		#rpm -Uvh http://mirror.centos.org/centos/6/os/x86_64/Packages/pcre2-10.23-2.el7.x86_64.rpm 2>&1
			rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/6/x86_64/zabbix-release-6.0-4.el6.noarch.rpm 2>&1 

			if [ $? -eq 0 ]; then

				yum install -y zabbix-agent 
				chkconfig zabbix-agent on 
				sleep 2;
				echo -e "\e[0m"
				echo
				zabbix_update
			else 
					echo
					echo -e "\e[1;31mFalha ao instalar zabbix\e[0m"
					exit 0;
			fi

		fi
		exit 0;;
	*)
		echo -e "\e[1;31mversao de SO nao suportada, finalizando script\e[0m"
		exit 0;;
esac
}

zabbix_update () {
	
	echo
	echo -e "\e[1;31mConfigurando zabbix.\e[0m"
	sleep 2
	if [ -d $zabbixdir ]; then

		wget -c "$arquivosdl"	
		tar xvf $arquivotar -C /tmp
		cp -v /tmp/ito-scripts-main/Linux/zabbix/zabbix_agentd.conf  $zabbixdir 2>&1
		rm -fr /tmp/ito-scripts-main*
		rm -fr $arquivotar

		service zabbix-agent restart

		echo
		echo -e "\e[1;31mZabbix configurado com sucesso.\e[0m"
		echo -e "\e[1;31mUtilize o nome \e[1;36m" `$zabbixexec -t system.hostname | cut -f 2 -d "|" | cut -d "]" -f 1` "\e[1;31m para configurar o host\e[0m"
		sleep 3;
		echo
		main
	else
		echo -e "\e[1;31mNao encontrado diretorio de instalacao.\e[0m"
		exit 0;
	fi
}


zabbix_remove () {

	echo
	echo -e "\e[1;31mRemovendo zabbix\e[0m"
	echo
	rpm -qa | grep zabbix 2>&1

	if [ $? -eq 0 ];then
		
		yum remove zabbix-agent -y
	 	rpm -e zabbix-release
		
		if [ -d $zabbixdir ];then
			
			rm -fr $zabbixdir
			echo
			echo -e "\e[1;31mRemocao concluida.\e[0m"
			sleep 2;
			main
		else
			
			echo -e "\e[1;31mDiretorio de instalacao nao localizado para remocao\e[0m"
			exit 0;
		fi
	else 
		echo -e "\e[1;31mInstalacao nao localizada via RPM, finalizando script\e[0m"
		exit 0;
	fi
}

main
