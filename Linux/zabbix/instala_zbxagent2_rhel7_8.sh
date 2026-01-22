#!/bin/bash
clear

# Variáveis de ambiente
arquivosdl="https://raw.githubusercontent.com/angelolira/zabbix_new/refs/heads/main/Linux/zabbix/zabbix_agent2.conf"
zabbixconf="zabbix_agent2.conf"
zabbixexec="/usr/sbin/zabbix_agent2"
zabbixdir="/etc/zabbix"
validaversaoSO=$(uname -r | cut -f 6 -d ".")

# System #
main() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "\e[1;31mO script deve ser executado como root.\e[0m" 
        exit 0
    else
        echo -e "\e[1;31m----------------------------------------------------\e[0m"
        echo -e "\e[1;31mBEM VINDO A INSTALACAO DO ZABBIX AGENT 2\e[0m"
        echo "O que deseja fazer?"
        echo "1 - Instalar Zabbix Agent 2"
        echo "2 - Remover Zabbix Agent 2"
        echo "0 - Sair"
        echo -ne "\e[1;31mDigite sua opcao: \e[0m"
        read resultado
        case $resultado in
        1) zabbix_install ;;
        2) zabbix_remove ;;
        0) exit 0 ;;
        *)
            echo -e "\e[1;31mOpcao invalida\e[0m"
            main
            ;;
        esac
    fi
}

zabbix_install() {
    echo
    echo -ne "\e[1;31mVerificando versao do SO... "

    case $MACHTYPE in
    x86_64-redhat-linux-gnu)

        if [[ "$validaversaoSO" =~ el8 ]]; then
            echo "encontrado SO Linux CentOS/RedHat versao 8 64 bits."
            echo -e "Iniciando instalacao do Zabbix Agent 2...\e[0m"
            sleep 2
            echo

            pgrep zabbix_agent2 >/dev/null
            result=$?

            if [ "$result" -eq "0" ] || [ -e "$zabbixexec" ]; then
                echo -ne "\e[1;31mZabbix Agent 2 ja instalado, deseja atualizar? [Y/N] \e[0m"
                read resultinstall
                case $resultinstall in
                [yY]) zabbix_update ;;
                [nN])
                    echo -en "\e[1;31mFinalizando script\e[0m"
                    exit 0
                    ;;
                *)
                    echo -en "\e[1;31mOpcao invalida, utilize Y ou N\e[0m"
                    sleep 2
                    zabbix_install
                    ;;
                esac
            fi

            rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-4.el8.noarch.rpm 2>&1

            if [ $? -eq 0 ]; then
                yum install -y zabbix-agent2
                systemctl enable zabbix-agent2
                sleep 2
                echo
                zabbix_update
            else
                echo -e "\e[1;31mFalha ao instalar o repositório Zabbix\e[0m"
                exit 0
            fi

        elif [[ "$validaversaoSO" =~ el7 ]] || [ "$validaversaoSO" = "" ]; then
            echo "encontrado SO Linux CentOS/RedHat versao 7 64 bits."
            echo -e "Iniciando instalacao do Zabbix Agent 2...\e[0m"
            sleep 2
            echo

            pgrep zabbix_agent2 >/dev/null
            result=$?

            if [ "$result" -eq "0" ] || [ -e "$zabbixexec" ]; then
                echo -ne "\e[1;31mZabbix Agent 2 ja instalado, deseja atualizar? [Y/N] \e[0m"
                read resultinstall
                case $resultinstall in
                [yY]) zabbix_update ;;
                [nN])
                    echo -en "\e[1;31mFinalizando script\e[0m"
                    exit 0
                    ;;
                *)
                    echo -en "\e[1;31mOpcao invalida, utilize Y ou N\e[0m"
                    sleep 2
                    zabbix_install
                    ;;
                esac
            fi

            rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/7/x86_64/zabbix-release-6.0-4.el7.noarch.rpm 2>&1

            if [ $? -eq 0 ]; then
                yum install -y zabbix-agent2
                chkconfig zabbix-agent2 on
                sleep 2
                echo
                zabbix_update
            else
                echo -e "\e[1;31mFalha ao instalar o repositório Zabbix\e[0m"
                exit 0
            fi
        fi
        exit 0
        ;;
    *)
        echo -e "\e[1;31mVersao de SO nao suportada, finalizando script\e[0m"
        exit 0
        ;;
    esac
}

zabbix_update() {
    echo
    echo -e "\e[1;31mConfigurando Zabbix Agent 2...\e[0m"
    sleep 2
    if [ -d $zabbixdir ]; then

		wget -c "$arquivosdl"	
		#tar xvf $arquivotar -C /tmp
		cp -v /root/zabbix_agentd2.conf  $zabbixdir 2>&1
		rm -fr /root/zabbix_agentd2.conf
		#rm -fr $arquivotar

		service zabbix-agent2 restart

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

zabbix_remove() {
    echo
    echo -e "\e[1;31mRemovendo Zabbix Agent 2...\e[0m"
    echo
    rpm -qa | grep zabbix-agent2 2>&1

    if [ $? -eq 0 ]; then
        yum remove zabbix-agent2 -y
        rpm -e zabbix-release

        if [ -d "$zabbixdir" ]; then
            rm -fr "$zabbixdir"
            echo
            echo -e "\e[1;31mRemocao concluida.\e[0m"
            sleep 2
            main
        else
            echo -e "\e[1;31mDiretorio de instalacao nao localizado para remocao\e[0m"
            exit 0
        fi
    else
        echo -e "\e[1;31mZabbix Agent 2 nao encontrado, finalizando script\e[0m"
        exit 0
    fi
}

main
