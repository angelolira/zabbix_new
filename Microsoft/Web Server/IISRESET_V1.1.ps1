$user = "adm-cesumar\adm.luz"

function Reset-IISEmMassa {
    # Declaração de máquinas em diferentes pools
    $AOnlineEad = "W2K19-WEB06", "W2K19-WEB07", "W2K19-WEB08", "W2K19-WEB09", "W2K19-WEB10" 
    $PseletivoEad = "W2K19-WEB21", "W2K19-WEB22", "W2K19-WEB23", "W2K19-WEB24", "W2K19-WEB28"
    $AOnline = "W2K19-WEB01", "W2K19-WEB02", "W2K19-WEB03", "W2K19-WEB04", "W2K19-WEB05"
    $DOnline = "W2K19-WEB11", "W2K19-WEB12", "W2K19-WEB13", "W2K19-WEB14", "W2K19-WEB15"
    $Pseletivo = "W2K19-WEB16", "W2K19-WEB17", "W2K19-WEB18", "W2K19-WEB19", "W2K19-WEB20"
    $todos = "W2K19-WEB06", "W2K19-WEB07", "W2K19-WEB08", "W2K19-WEB09", "W2K19-WEB10", "W2K19-WEB21", "W2K19-WEB22", "W2K19-WEB23", "W2K19-WEB24", "W2K19-WEB28", "W2K19-WEB01", "W2K19-WEB02", "W2K19-WEB03", "W2K19-WEB04", "W2K19-WEB05", "W2K19-WEB11", "W2K19-WEB12", "W2K19-WEB13", "W2K19-WEB14", "W2K19-WEB15", "W2K19-WEB16", "W2K19-WEB17", "W2K19-WEB18", "W2K19-WEB19", "W2K19-WEB20"
    #$teste = "w2k19-web30", "w2k19-web31", "w2k19-web32" 

    Clear-Host
    # Submenu para escolher o pool                
    Write-Host 
    "     ######################
     ### Escolha o Pool ###
     ###################### "
    Write-Host "1. Aluno Online (AonlineEad) - EAD"
    Write-Host "2. Processo Seletivo (PseletivoEad) - EAD"
    Write-Host "3. Aluno Online (Aonline) - PRESENCIAL"
    Write-Host "4. Docente Online (Donline)- PRESENCIAL"
    Write-Host "5. Processo Seletivo (Pseletivo) - PRESENCIAL"
    Write-host "6. Todos os Servidores"
    Write-host "7. Voltar ao Menu Principal"
    
    
    $poolOption = Read-Host "Digite o número do pool que você deseja reiniciar"
    $credential = Get-Credential -Credential $user

    switch ($poolOption) {
        1 {Invoke-IISReset $AOnlineEad }
        2 {Invoke-IISReset $PseletivoEad $credential}
        3 {Invoke-IISReset $AOnline $credential }
        4 {Invoke-IISReset $DOnline $credential }
        5 {Invoke-IISReset $Pseletivo $credential}
        6 {Invoke-IISReset $Todos $credential}
        7 { Return }
        
        
        default { Write-Host "Opção inválida. Tente novamente." }
    }
}

function Reset-IISPorHost {
    # Pedir ao colaborador que insira o nome da máquina
    $credential = Get-Credential -Credential $user
    $servidor = Read-Host "Digite o nome do servidor IIS que você deseja reiniciar"
            
    Invoke-IISReset $servidor $credential
}

function Invoke-IISReset($servers) {
    Clear-Host
    Write-Host "Servidores a serem reiniciados: $($servers -join ', ')" -ForegroundColor Yellow
    
    # Pede confirmação
    $confirmacao = Read-Host "Tem certeza que deseja reiniciar esses servidores? (S para Sim, N para Não)"
    
    if ($confirmacao -eq 'S' -or $confirmacao -eq 's') {
    # Reiniciar IIS nas máquinas especificadas
    foreach ($server in $servers) {
        Write-Host "Reiniciando servidor $server" -ForegroundColor Cyan
        Invoke-Command -ComputerName $server -ScriptBlock {iisreset /RESTART}  -Credential $credential -ArgumentList $credential
        
    }
    Write-Host "Operação concluída." -ForegroundColor Cyan
    
        # Pergunta se deseja voltar ao menu principal ou sair
        $opcaoMenu = Read-Host "Deseja voltar ao Menu Principal (1) ou Sair (2)?" 

        if ($opcaoMenu -eq '1') {
            return  # Retorna para o menu principal
        }
        elseif ($opcaoMenu -eq '2') {
            Write-Host "Saindo..." -ForegroundColor Cyan
            exit  # Sai do script
        }
        else {
            Write-Host "Opção inválida. Saindo..." -ForegroundColor Red
            exit  # Sai do script
        }
    }
    elseif ($confirmacao -eq 'N' -or $confirmacao -eq 'n') {
        Write-Host "Operação cancelada." 
    }
    else {
        Write-Host "Opção inválida. Operação cancelada."
    }

    Start-Sleep -Seconds 7
}

    


do {
    Clear-Host
    Write-Host 
    "     ######################
     ### Menu IIS Reset ###
     ######################"
    Write-Host "1. Reset por Pool"
    Write-Host "2. Reset por Host"
    Write-Host "3. Sair"

    $opcao = Read-Host "Digite o número da opção desejada"

    switch ($opcao) {
        1 { Reset-IISEmMassa }
        2 { Reset-IISPorHost }
        3 { Write-Host "Saindo..."; break }
        default { Write-Host "Opção inválida. Tente novamente." }
    }
} while ($opcao -ne 3)
