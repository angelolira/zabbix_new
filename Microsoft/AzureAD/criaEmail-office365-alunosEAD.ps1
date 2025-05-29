$clientID = "12801273-fe92-4dd3-9665-12cedf26d740"
$tenantID = "ba201131-9621-49ca-b50d-57d968b4ac35"
$graphScopes = "Directory.ReadWrite.All"

Connect-MgGraph -ClientId $clientId -TenantId $tenantId -Scopes $graphScopes
Get-MgSubscribedSku | Select-Object SkuPartNumber, SkuId
Import-Module Microsoft.Graph.Users

###########                                                          #############
## A PARTIR DESTE PONTO, COMEÇA O IMPORT DO ARQUIVO CSV PARA CRIAÇÃO DAS CONTAS ##
##                                                                              ##
## IMPORTANTE: APÓS CONECTADO NO AZURE A PRIMEIRA VEZ, PARA EXECUTAR NOVOS      ##
##             ARQUIVOS SELECIONE APARTIR DAS LINHAS ABAIXO                     ##
##                                                                              ##
##                                                                              ##
###########                                                          #############

Write-Host "Iniciando processo de validacao e criacao de novas contas no Office365..."
Write-Host "Carregando o arquivo... " -ForegroundColor Green
Write-Host ""
# Coloque o nome do arquivo de lote que deve ser carregado.
# Carrega arquivo de lote e delimita nome e variavel ----
$origem_csv = "C:\Office 365 Alunos EAD\Contas Novas\" # Caminho do arquivo
$nome_csv = "alunosOffice365 (10)" # Nome do arquivo .csv
# ----
Write-Host ""
Write-Host "Montando o arquivo de saída... " -ForegroundColor Green
Write-Host ""
# cria caminho e arquivo de log
$PathLogDir = "C:\Office 365 Alunos EAD\Saida Lotes\" # entrada original
$full_path_log = $PathLogDir + $nome_csv + ".csv"

Write-Host ""
Write-Host "Importando o arquivo: "$nome_csv -ForegroundColor Yellow
Write-Host ""
$path_csv = $origem_csv + $nome_csv + ".csv"
$array_dados = Import-Csv $path_csv -Delimiter "," -Encoding UTF8 # entrada original
# --- Gerando o contador
$i=0 
$tot = $array_dados.count

Write-Host "Total de linhas para adicionar: "$array_dados.Count -ForegroundColor Yellow

$array_dados[0..10] | ft
Pause

$Output = foreach ($item in $array_dados) {

    

    <# Aplicando contador 
    $i++
    $status = "{0:N0}" -f ($i / $tot * 100)
    Write-Progress -Activity "Adicionando contas ===> " -status "Processando $i de $tot : $status% Completado" -PercentComplete ($i / $tot * 100)#>
    
    # Variaveis do nome 
    $FirstName = $item.FirstName
    $LastName = $item.LastName
    $DisplayName = $item.DisplayName
    
    
    # Variaveis do curso
    $Office = $item.Office
    $Title = $item.Title
    $Department = $item.Department

    # Variaveis de RA e login
    $RaLetra = $item.RaLetra
    $RaNumber = $item.RaNumber
    $Domain = $item.Domain
    $UserPName = $RaLetra + $RaNumber + "@" +$Domain
    $userNickName = $RaLetra + $RaNumber
    
    # Variaveis de contato e localidade
    $City = $item.City
    $TelephoneNumber = $item.TelephoneNumber
    $Mobile = $item.Mobile
    $StAddress = $item.StreetAddress
    
    # Variaveis de licenciamento e senhas
    $UsageLocation = $item.UsageLocation
    $Pass_Letra = $item.Letra
    $CPF = $item.CPF
    $Pass_final = $Pass_Letra + $CPF

    $passwordProfile = @{
    Password = $Pass_final
    ForceChangePasswordNextSignIn = $false
}
   $filtro = "userPrincipalName eq '$UserPName'"
   $tent = Get-MgUser -Filter $filtro -ErrorAction SilentlyContinue -ErrorVariable errorVariable

    if($tent -eq $null){

            $Conta_Existe_EAD = "Usuario nao existe, criando nova conta...: $($UserPName) "
            Write-Host "Usuario nao existe, criando nova conta...: $($UserPName) "

            New-MgUser -MailNickname $userNickName `
                 -DisplayName $DisplayName `
                 -PasswordProfile $passwordProfile -AccountEnabled `                  `
                 -UserPrincipalName $UserPName                 `
                 -GivenName $FirstName `
                 -Surname $LastName `
                 -MobilePhone $Mobile  `
                 -Office $Office `
                 -JobTitle $Title `
                 -City "$City" `
                 -UsageLocation $UsageLocation `
                 
                 
        } 
        else {

            $Conta_Existe_EAD = "Usuario ja existe: $($DisplayName) e-mail: $($UserPName) " 
            ## Escreve na tela a saída do comando para acompanhamento
            Write-Host "Usuario ja existe: $($DisplayName) e-mail: $($UserPName) "
            
        }
	Write-Host "Ativando Licença"
	$license = Get-MgSubscribedSku | `
	Where-Object {$_.SkuPartNumber -eq "STANDARDWOFFPACK_IW_STUDENT"}
	$userrr = Get-MgUser -Filter "userPrincipalName eq '$UserPName'" 
	Set-MgUserLicense -UserId $userrr.Id `
	-AddLicenses @{SkuId = ($license.SkuId)} -RemoveLicenses @()
	Write-Host "ativando licença"

        New-Object -TypeName psobject -Property @{
            UserPrincipalName=$UserPName
            DisplayName=$DisplayName
            Password=$Pass_final
            AlternativeEmail=$StAddress
            ExistenteEAD=$_Conta_Existe_EAD
        } 
    
        
}
Write-Host
Write-Host "Escrevendo o arquivo de log da saída no caminho ($full_path_log)" -ForegroundColor Cyan
$Output | Select-Object UserPrincipalName,DisplayName,Password,AlternativeEmail,ExistenteEAD | Export-Csv $full_path_log -Delimiter "," -Encoding UTF8 

# Após tudo ocorrer, remover as sessões criadas com o Office 365. Realiza a desconexão com Microsoft.
Write-Host "Desconectando da sessão remota" -ForegroundColor Yellow
#Remove-PSSession $Session
Disconnect-MgGraph