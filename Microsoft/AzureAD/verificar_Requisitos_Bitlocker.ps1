# Caminho para o arquivo CSV
$arquivoCSV = "C:\Scripts\Entrada\pcs.csv"

# Caminho para o arquivo de saída CSV
$arquivoSaidaCSV = "C:\Scripts\SAida\saida22112023.csv"

# Ler computadores do arquivo CSV
$computadores = Import-Csv $arquivoCSV | Select-Object -ExpandProperty NomeDoComputador

# Inicializar array para armazenar resultados
$resultadosArray = @()

foreach ($computador in $computadores) {
    #  PsExec para o primeiro comando
    $comandoPsExec1 = "PsExec \\$computador cmd /c wmic /namespace:\\root\cimv2\security\microsofttpm path Win32_Tpm get IsEnabled_InitialValue | findstr -i True" 
    
    # Tentar executar o comando PsExec para o primeiro comando
    try {
        $saida1 = Invoke-Expression -Command $comandoPsExec1 -ErrorAction Stop
        
        ####SE A SAIDA FOR A SAIDA ABAIXO E O COMANDO 2 ESTIVER PREENCHIDO CORRETAMENTE (NÃO ESTIVER VAZIO), CONSIDERAR FALSE.(O Psexec está procurando apenas por TRUE, por isso sai como nulo se for Falso)
        ## SE A SAIDA FOR A ABAIXO MAS O COMANDO 2 ESTIVER VAZIO, CONSIDERE: PC UNREACHABLE.
        if ($saida1 -eq $null){
        $saida1 = "False / pc unreachable "}
    } catch {
        $saida1 = "$($_.Exception.Message)"
    }

    # Construir o comando PsExec para o segundo comando
    $comandoPsExec2 = "PsExec \\$computador cmd /c reagentc /info | findstr -i Status"

    # Tentar executar o comando PsExec para o segundo comando
    try {
        $saida2 = Invoke-Expression -Command $comandoPsExec2 -ErrorAction Stop 
    } catch {
        $saida2 = "Erro: $($_.Exception.Message)"
    }

    # Criar objeto com informações
    $informacoesComputador = [PSCustomObject]@{
        Computador = $computador
        IsEnabled_InitialValue = $saida1
        WinRM = $saida2
    }

    # Adicionar objeto ao array de resultados
    $resultadosArray += $informacoesComputador
}

# Exportar resultados para CSV
$resultadosArray | Export-Csv -Path $arquivoSaidaCSV -NoTypeInformation -Delimiter ";"
