##############################################################################################################
#                                                                                                            #
# Rotina de manutenção criada para Mover usuários desabilitados da OU Unicesumar para a OU Func_demitidos.   #
#                                                                                                            #
##############################################################################################################

# Monta arquivo de Saida
$csvPath = "C:\Scheduled_Scripts\Scripts_OUT\Move_user_Func_Demitidos\"
$dateTime = Get-Date -f "dd-MM-yyyy_hh-mm"
$csvFile = "Desabilitados_Movidos"+$dateTime + ".csv"
$path = $csvPath + $csvFile

# OU de destino
$funcDem = "OU=Func_Demitidos,DC=adm-cesumar,DC=local"

$OUs = @("OU=UNICESUMAR,DC=adm-cesumar,DC=local","OU=Contas Especificas - Geral,DC=adm-cesumar,DC=local" )
Foreach ($ou in $OUs) {
# Obtém os usuários desabilitados da OU Unicesumar e OUs filhas
$users = Get-ADUser -Filter {Enabled -eq $false} -SearchBase $ou -Properties DisplayName, EmailAddress, SamAccountName, whenCreated, whenChanged, lastlogondate, passwordlastset, Department, Title, Company, Enabled, DistinguishedName 
if ($users -eq $null){ 
    Write-Host "Não há usuários desabilitados."
    continue
}
$observacao = ""
$count = 0
$move = Foreach ($user in $users){

    $dn = $user.distinguishedName
    Try{
        # Desabilita a proteção contra exclusão acidental
        Set-ADObject $dn -ProtectedFromAccidentalDeletion $false -Confirm: $False
        # Move objeto desabilitado para a OU Func_Demitidos
        Move-ADObject -Identity $dn -TargetPath $funcDem
        # Registra a observação
        $observacao = "Usuario movido para a OU Func_Demitidos."
        $count++
    } 
        Catch{
            $observacao = "$($_.Exception.Message)"
    }
    [PSCustomObject] @{
        DisplayName = $user.displayName
        UserPrincipalName = $user.UserPrincipalName
        SamAccountName = $user.samAccountName
        WhenCreated = $user.whenCreated
        WhenChanged = $user.whenChanged
        LastLogonDate = $user.lastLogonDate
        PasswordLastSet = $user.passwordLastSet
        Departament = $user.departament
        Title = $user.title
        Company = $user.company
        Enabled = $user.enabled
        DistinguishedName = $user.distinguishedName
        Comments = $observacao
    
    }
}
}
$move | Select-Object DisplayName, UserPrincipalName, SamAccountName, WhenChanged, WhenCreated, LastLogonDate, PasswordLastSet, Department, Title, Company, Enabled, DistinguishedName `
| Export-Csv $path -Delimiter ";" -NoTypeInformation -Encoding UTF8


$Username = "ito.reports@unicesumar.edu.br";

# Função para enviar arquivo por e-mail
function Send-ToEmail([string]$email){
    $message = New-Object Net.Mail.MailMessage;
    $message.From = $Username;
    $message.To.Add($email);
    $message.Subject = "ITO Reports - Contas desativadas movidas para Func_demitidos";
    $message.Body =  "Atenção:
    Anexo report de contas de usuários desativadas encontradas nas OUs principais.
    Usuários desabilitados: $count
    As contas encontradas desativadas, foram movidas para OU Func_Demitidos por padrão.
    Nenhuma exclusão será executada nesta rotina que ocorrerá 1 vez por semana, toda sexta-feira às 23h00. ";
    

    Write-Host "Anexando arquivo" -ForegroundColor Red

    $file = "$($path)"
    $att = New-Object Net.Mail.Attachment($file)
    $message.Attachments.Add($file)

    Write-Host "Autenticando no SMTP para envio" -ForegroundColor Red
    $smtp = New-Object Net.Mail.SmtpClient("172.16.0.72", "25"); 
    $smtp.EnableSSL = $false;
    $smtp.Credentials = New-Object System.Net.NetworkCredential($credential);

    try {
        Write-Host "Enviando mensagem" -ForegroundColor Cyan
        $smtp.Send($message);
        Write-Host "Mensagem enviada com sucesso" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Erro ao enviar mensagem: $_" -ForegroundColor Red
    }
    finally {
        $att.Dispose()
    }
}

Send-ToEmail -email "renata.belo@vitru.com.br";
Send-ToEmail -email "fernando.cordeiro@unicesumar.edu.br";