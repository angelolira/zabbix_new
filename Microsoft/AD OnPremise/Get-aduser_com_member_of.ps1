$users = Get-ADUser -Filter * -SearchBase "DC=adm-cesumar,DC=local" -Properties DisplayName, DistinguishedName, UserprincipalName, Memberof, ExtensionAttribute1, Enabled

# Hash para armazenar os resultados
$resultados = @()

foreach ($user in $users) {
    
    $grupos = ""
    foreach ($group in $user.MemberOf) {
        # Obter o nome do grupo
        $groupName = (Get-ADGroup $group).Name

        # Adicionar o nome do grupo à string de grupos
        $grupos += "$groupName;"
    }

    # Adicionar o usuário e seus grupos à lista de resultados
    $resultado = [PSCustomObject]@{
        "Enabled" = $user.Enabled
        "DisplayName" = $user.DisplayName
        "DistinguishedName" = $user.DistinguishedName
        "UserprincipalName" = $user.UserprincipalName
        "Grupos" = $grupos
        "ExtensionAttribute1" = $user.ExtensionAttribute1
    }

    $resultados += $resultado
}
$resultados | Export-Csv -Path "C:\Users\renata.belo\OneDrive - unicesumar.edu.br\Demandas Operação\Scripts\enforce mfa relatorio usuarios.csv" -Encoding UTF8 -Delimiter ";" -NoTypeInformation
