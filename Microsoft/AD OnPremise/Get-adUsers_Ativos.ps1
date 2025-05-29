#Array para declaração de OU's que serão verificadas:
$OUs = @("OU=CESUMAR,DC=adm-cesumar,DC=local", "OU=Contas Especificas - Geral,DC=adm-cesumar,DC=local", "OU=UNICESUMAR,DC=adm-cesumar,DC=local")
Foreach ($ou in $OUs) {
$users = Get-ADUser -Filter {Enabled -eq $true} -SearchBase $ou -Properties DisplayName, EmailAddress, SamAccountName, whenCreated, whenChanged, lastlogondate, passwordlastset, Department, Title, Company, Enabled, DistinguishedName 


}
$count = $users.Count
Write-Host "Usuários ativos no active directory: $count" -ForegroundColor Green