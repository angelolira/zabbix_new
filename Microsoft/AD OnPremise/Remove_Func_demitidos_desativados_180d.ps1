<#######################################################################
 Descrição: Este script verifica e remove automaticamente os
 usuários que estão na Unidade Organizacional (OU)
 'Func_Demitidos' e que estão desabilitados há mais de seis meses.

 Data de Criação: [15/09/2023]
 
#########################################################################>


# Caminho para a OU Func_Demitidos
$ouPath = "OU=Func_Demitidos,DC=adm-cesumar,DC=local"

# Caminho para o arquivo CSV de saída
$csvPath = "C:\Scheduled_Scripts\Scripts_OUT\Exclui_usuarios_desabilitados\"
$DateTime = Get-Date -f "dd-MM-yyyy_hh-mm"
$csvfile = "demitidos_"+$DateTime
$full_path_log = $csvPath + $csvfile + ".csv"


# data de seis meses atrás
$date180DaysAgo = (Get-Date).AddDays(-180)
 
# Consulta o Active Directory para obter os usuários na OU especificada e verifica a data da última alteração
$users = Get-ADUser -Filter {Enabled -eq $false -and whenChanged -lt $date180DaysAgo} -SearchBase $ouPath -Properties DisplayName, EmailAddress, whenChanged, Department, Title, Company, Enabled
if ($users -eq $null){ 
    Write-Host "Não há usuários desabilitados."
    return
}
$count = $users.Count
Write-host "Foram encontrados $count usuários desabilitados a mais de seis meses" -ForegroundColor Yellow
#pause
Write-Host "Removendo usuários desabilitados a mais de 6 meses.."
$usersRemovidos = 0
$erros = 0
$remove = foreach ($user in $users) {
   
    Try{
      Remove-ADObject -Identity $user.DistinguishedName -Recursive -Confirm:$False  
      $usersRemovidos++
      $observacao = "usuário removido."}
    Catch{
    $observacao = "$($_.Exception.Message)"
    $erros++
    }
    [PSCustomObject] @{
        Name = $user.DisplayName
        Email = $user.UserPrincipalName
        Title = $user.Title
        Company = $user.Company
	    Enabled = $user.Enabled
        Comments = $observacao
        Date = $DateTime}
        
    }
    Write-Host
    $remove | Select-Object Name, Email, Title, Company, Enabled, Comments, Date |  Export-Csv -LiteralPath $full_path_log -Encoding UTF8 -Delimiter ";" -NoTypeInformation


#Enviar arquivo compactado por e-mail

$Username = "ito.reports@unicesumar.edu.br";
#$Password = "#senha"

function Send-ToEmail([string]$email){
    $message = New-Object Net.Mail.MailMessage;
    $message.From = $Username;
    $message.To.Add($email);
    $message.Subject = "Usuários desabilitados a mais de 6 meses";
    $message.Body = "Foram encontrados $count usuários inativos a mais de seis meses na OU Func_Demitidos.
    Usuários removidos: $usersRemovidos
    Com erro: $erros ";

    Write-Host "Anexando arquivo" -ForegroundColor Red

    $file = "$($full_path_log)"
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
