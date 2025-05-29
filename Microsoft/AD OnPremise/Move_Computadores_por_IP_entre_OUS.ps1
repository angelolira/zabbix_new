<#
################################################################################
# PowerShell rotina para mover as máquinas windows para suas OU por Vlan x IP  #
################################################################################
v1. Varrer computadores de Maringa para Vlans de Maringa.

.TODO

- Script executado 4 vezes ao dia. 07h30, 12h30, 17h30, 23h00 para migrar novos computadores da OU "computers" para respectivas OU de destino.

#>

#Importar Módulo Active Directory
Import-Module ActiveDirectory

# OU Computers
$computers_OU = "CN=Computers,DC=adm-cesumar,DC=local"
# OU Computadores > Desktops
$computadores_desktops = "OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local"
# Desktops sem IP
$Desktops_SemIP = "OU=Desktops_SemIP,OU=Outros_Status,OU=Computadores,DC=adm-cesumar,DC=local"
## Desktops desabilitados
$Desktops_Desabilitados = "OU=Desktops_Desativados,OU=Outros_Status,OU=Computadores,DC=adm-cesumar,DC=local"

## Computadores com mais de 30 dias "desabilitados"
$computer_Mais_30dias = (Get-Date).AddDays(-30)

#arquivo de saida
$csvPath = "C:\Scheduled_Scripts\Scripts_OUT\Move_Computadores\"
$dateTime = Get-Date -f "dd-MM-yyyy_hh-mm"
$csvFile = "computadores_Movidos_"+$dateTime + ".csv"
$csvfile_Deleted = "computadores_Excluidos_"+$dateTime + ".csv"
$path = $csvPath + $csvFile
$path_deleted = $csvPath + $csvFile_Deleted


# Tabela de hash para mapear padrões de IP/rede x Distinguished Names (DNs) das VLANS
$ip_vlan_mapping = @{
           
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:1)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.1.0/24 #> = "OU=Vlan_321,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_321 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:2)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.2.0/24 #> = "OU=Vlan_322,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_322 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:3)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.3.0/24 #> = "OU=Vlan_323,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_323 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:4)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.4.0/24 #> = "OU=Vlan_324,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_324 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:5)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.5.0/24 #> = "OU=Vlan_325,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_325 #>

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:6)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.6.0/24 #> = "OU=Vlan_326,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_326 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:7)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.7.0/24 #> = "OU=Vlan_327,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_327 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:8)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.8.0/24 #> = "OU=Vlan_328,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_328 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:9)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.9.0/24 #> = "OU=Vlan_329,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_329 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:10)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.10.0/24 #> = "OU=Vlan_3210,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3210 #>

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:11)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.11.0/24 #> = "OU=Vlan_3211,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3211 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:12)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.12.0/24 #> = "OU=Vlan_3212,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3212 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:13)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.13.0/24 #> = "OU=Vlan_3213,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3213 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:14)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.14.0/24 #> = "OU=Vlan_3214,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3214 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:15)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.15.0/24 #> = "OU=Vlan_3215,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3215 #>

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:16)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.16.0/24 #> = "OU=Vlan_3216,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3216 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:17)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.17.0/24 #> = "OU=Vlan_3217,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3217 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:18)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.18.0/24 #> = "OU=Vlan_3218,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3218 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:19)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.19.0/24 #> = "OU=Vlan_3219,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3219 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:20)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.20.0/24 #> = "OU=Vlan_3220,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3220 #>

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:21)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.21.0/24 #> = "OU=Vlan_3221,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3221 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:22)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.22.0/24 #> = "OU=Vlan_3222,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3222 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:23)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.23.0/24 #> = "OU=Vlan_3223,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3223 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:24)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.24.0/24 #> = "OU=Vlan_3224,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3224 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:25)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.25.0/24 #> = "OU=Vlan_3225,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3225 #> 

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:26)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.26.0/24 #> = "OU=Vlan_3226,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3226 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:27)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.27.0/24 #> = "OU=Vlan_3227,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3227 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:28)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.28.0/24 #> = "OU=Vlan_3228,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3228 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:29)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.29.0/24 #> = "OU=Vlan_3229,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3229 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:30)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.30.0/24 #> = "OU=Vlan_3230,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3230 #> 

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:31)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.31.0/24 #> = "OU=Vlan_3231,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3231 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:32)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.32.0/24 #> = "OU=Vlan_3232,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3232 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:33)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.33.0/24 #> = "OU=Vlan_3233,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3233 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:34)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.34.0/24 #> = "OU=Vlan_3234,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3234 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:35)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.35.0/24 #> = "OU=Vlan_3235,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3235 #>

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:36)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.36.0/24 #> = "OU=Vlan_3236,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3236 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:37)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.37.0/24 #> = "OU=Vlan_3237,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3237 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:38)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.38.0/24 #> = "OU=Vlan_3238,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3238 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:39)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.39.0/24 #> = "OU=Vlan_3239,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3239 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:40)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.40.0/24 #> = "OU=Vlan_3240,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3240 #> 

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:41)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.41.0/24 #> = "OU=Vlan_3241,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3241 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:42)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.42.0/24 #> = "OU=Vlan_3242,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3242 #>
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:43)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.43.0/24 #> = "OU=Vlan_3243,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3243 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:44)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.44.0/24 #> = "OU=Vlan_3244,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3244 #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:50)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.50.0/24 #> = "OU=Vlan_3250,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3250 #> 

    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:92)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.92.0/24 #> = "OU=Vlan_3292,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN mga_vlan_3292 #>

## rede biotec
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:100)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.100.0/24 #> = "OU=Vlan_100,OU=Desktops Maringa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN $mga_vlan_100 #>

### Definição das redes IP/vlan do administrativa de Londrina.
    "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:32)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.64.32.0/24 #> = "OU=Vlan_100,OU=Desktops Londrina,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN lda_vlan_100 #>

### Definição das redes IP/vlan do administrativa de Ponta Grossa.
    "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:16)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.64.16.0/24 #> = "OU=Vlan_100,OU=Desktops Ponta Grossa,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN pgo_vlan_100 #> 

### Definição das redes IP/vlan do administrativa de Curitiba.
    "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:0)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.64.0.0/24 #> = "OU=Vlan_100,OU=Desktops Curitiba,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN ctba_vlan_100 #> 
    "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:1)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.64.1.0/24 #> = "OU=Vlan_110,OU=Desktops Curitiba,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN ctba_vlan_110 #>
<# "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:2)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" # 10.64.2.0/24 = 
   "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:4)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" # 10.64.4.0/24 #>

### Definição das redes IP/vlan do administrativa de Corumba.
    "\b(?:(?:10)\.)+\b(?:(?:64)\.)+\b(?:(?:48)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.64.48.0/24 #> = "OU=Vlan_100,OU=Desktops Corumba,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN cmba_vlan_100 #> 

### Definição das redes IP/vlan para wifi ADM no AD.
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:72)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.72.0/24 #> = "OU=Vlan_ADM_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_adm_geral #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:73)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.73.0/24 #> = "OU=Vlan_ADM_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_adm_geral #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:74)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.74.0/24 #> = "OU=Vlan_ADM_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_adm_geral #> 
    "\b(?:(?:10)\.)+\b(?:(?:32)\.)+\b(?:(?:75)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.32.75.0/24 #> = "OU=Vlan_ADM_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_adm_geral #> 

### Definição das redes IP/vlan para wifi ACAD no AD.
    "\b(?:(?:10)\.)+\b(?:(?:27)\.)+\b(?:(?:8)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.27.8.0/24 #> = "OU=Vlan_ACAD_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_acad_geral #> 
    "\b(?:(?:10)\.)+\b(?:(?:27)\.)+\b(?:(?:9)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.27.9.0/24 #> = "OU=Vlan_ACAD_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_acad_geral #>
    "\b(?:(?:10)\.)+\b(?:(?:27)\.)+\b(?:(?:10)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.27.10.0/24 #> = "OU=Vlan_ACAD_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_acad_geral #>
    "\b(?:(?:10)\.)+\b(?:(?:27)\.)+\b(?:(?:11)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.27.11.0/24 #> = "OU=Vlan_ACAD_WIFI,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN wifi_acad_geral #>
    #VPN SAML   
    "\b(?:(?:10)\.)+\b(?:(?:212)\.)+\b(?:(?:134)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.212.134.0/24 #> = "OU=VPN_SAML,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN VPN_SAML #>
    #VPN Antiga
    "\b(?:(?:10)\.)+\b(?:(?:212)\.)+\b(?:(?:136)\.)+\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))" <# 10.212.136.0/24 #> = "OU=VPN_Old,OU=Desktops,OU=Computadores,DC=adm-cesumar,DC=local" <# DN VPN_Antiga #>  
}
##### PARTE 1 - rotina para mover computadores #####

$movereport = @()
$removeReport = @()
$ous = @($computers_OU,$computadores_desktops,$Desktops_SemIP)


             foreach ($ou in $ous){
              $computers = Get-ADComputer -SearchBase $ou -Filter * -Properties Name,DistinguishedName,LastLogonDate,PasswordLastSet,IPv4Address, Enabled
                 
                foreach ($computer in $computers) {
                # Inicialize a variável de observação
                $observacao = ""
                # Endereço IP do computador
                $ipDoComputador = $computer.IPv4Address
                $nomeDoPC = $computer.Name
                $Computer_LastLogonDate = $computer.LastLogonDate
                $Computer_DN = $computer.DistinguishedName.ToString()
                $date = Get-Date 
                $vlan_dn = ""
                $enabled = $computer.Enabled
                $daysSinceLastLogon = ($date - $Computer_LastLogonDate).Days
                try {   
                
                        if ($computer.Enabled -eq $False){
                            
                                $vlan_dn += $Desktops_Desabilitados
                                Write-Host "Computador $nomeDoPC movido: Objeto desabilitado"
                                Move-ADObject -Identity $Computer_DN -TargetPath $vlan_dn 
                                $observacao += "Computado movido: Objeto desabilitado" }   

                        elseif ($nomeDoPC -like "*W2K*") {
                                Write-Host "Servidor encon $nomeDoPC . Saindo do loop." -ForegroundColor Yellow
                                break  # Sair do loop 
                                }                       
                         
                        # Verifica se o último logon foi feito a mais de 90 dias.
                        elseif ($computer_LastLogonDate -eq $null) {
                        Write-host "login nulo" -ForegroundColor Yellow
                        break
                           }
                           
                        elseif($daysSinceLastLogon -gt 90){
                                $data = Get-Date -f "dd/MM/yyyy_hh:mm"                                
                                $formattedLastLogonDate = $Computer_LastLogonDate.ToString("dd/MM/yyyy_hh:mm")
                                $novaDescricao = "Computador: $nomeDoPC desabilitado por Inatividade em $data - Último login: $formattedLastLogonDate " 
                                $vlan_dn += $Desktops_Desabilitados
                                Write-Host "Computador: $nomeDoPC desabilitado por Inatividade em $data - Último login: $formattedLastLogonDate " -ForegroundColor Yellow
                                # Desabilita computador
                                Disable-ADAccount -Identity $computer_DN 
                                Set-ADComputer -Identity $computer_DN -Description $novaDescricao 
                                # Move computador para OU Computadores_Desabilitados
                                Write-Host "Movendo $nomeDoPC para Computadores_Desabilitados" -ForegroundColor Yellow
                                Move-ADObject -Identity $Computer_DN -TargetPath $vlan_dn 
                                $observacao += "Computador desabilitado: sem login a mais de 90 dias"}
                                                          
                            
                        # Verifica se o computador está sem IP
                        elseif ($ipDoComputador -eq $null) {

                                $vlan_dn += $Desktops_SemIP
                                $isInTargetOU = $Computer_DN -like "*$vlan_dn*"

                            if ($isInTargetOU){
                                Write-Host "O computador já está na OU de destino. Nenhuma ação será feita." -ForegroundColor Green

                                }

                            else {
                                Write-Host "Movendo objeto sem IP: $nomeDoPC" -ForegroundColor Yellow
                                Move-ADObject -Identity $Computer_DN -TargetPath $vlan_dn 
                                $observacao += "Computador movido: Objeto sem IP" }
                        }
        
        
                        # Verifica se o IP do computador corresponde a alguma das redes listadas na hash table
                        else {
                                foreach ($ipPattern in $ip_vlan_mapping.Keys) {
                                          if ($ipDoComputador -match $ipPattern) {
                                            $vlan_dn += $ip_vlan_mapping[$ipPattern]
                                            # Verifique se o DN do computador já está contido no DN da OU de destino.
                                            $isInTargetOU = $Computer_DN -like "*$vlan_DN*"
                                                if ($isInTargetOU){
                                                Write-Host "O computador já está na OU de destino. Nenhuma ação será feita." -ForegroundColor Green
                                                
                                                }
                                                Else {
                                                Write-Host "O endereço IP do computador $nomeDoPC corresponde ao padrão." -ForegroundColor Cyan
                                                Write-Host "Movendo o computador para $vlan_dn" -ForegroundColor Cyan
                                                Move-ADObject -Identity $Computer_DN -TargetPath $vlan_dn 
                                                $observacao += "Computador movido"}
                                                break
                }
            }
        }
        # Se nenhuma das condições forem atendidas, não faça nada.
        if ($vlan_dn -eq "") {
            Write-Host "Computador $nomeDoPC : nenhuma alteração será feita" -ForegroundColor Red
            
        }
    }
    catch {
        # Em caso de erro, a excessão sera capturada
        $observacao += "Erro: $($_.Exception.Message)"
    }
    $moveReportEntry = [PSCustomObject] @{
        Name = $nomeDoPC
        IpAddress = $ipDoComputador
        Enabled = $enabled
        DistinguishedName = $Computer_DN
        Comments = $observacao
        DestinationOU = $vlan_dn
        Date = $data
    }
    $moveReport += $moveReportEntry
    } 
    }
$moveReport | Export-Csv -Path $path -Encoding UTF8 -Delimiter ";"  -NoTypeInformation 

## Parte 2 - Exclusão de computadores desabilitados a mais de 30 dias. ##

$desktops_Desativados = Get-ADComputer -SearchBase $Desktops_Desabilitados -Filter * -Properties Name, DistinguishedName, LastLogonDate, PasswordLastSet, IPv4Address, Enabled, WhenChanged
$remove = foreach ($desktop in $desktops_Desativados) {
        
        $distinguishedName = $desktop.DistinguishedName.ToString()
        $whenChanged = $desktop.whenChanged
        $formattedwhenChanged = $whenChanged.ToString("dd/MM/yyyy_hh:mm")
        $lastLogon = $desktop.LastLogonDate
        $name = $desktop.Name
        $enabled = $desktop.Enabled
        $data = Get-Date -f "dd/MM/yyyy_hh:mm"
        $observacao = ""

      if ($desktop.Enabled -eq $True) {
        Write-host "Movendo computador habilitado para a OU Computers" -ForegroundColor Cyan
        Move-ADObject -Identity $distinguishedName -TargetPath $computers_OU 
        $observacao += "Objeto movido para a OU Computers"
      
      }
      elseif ($whenChanged -le $computer_Mais_30dias){
        Write-Host "Removendo Computador $name - Ultima alteração: $whenChanged "
       Try { Remove-ADObject -Identity $distinguishedName -Confirm:$False 
                $observacao += "Objeto removido"
                }
                Catch { $observacao += "Erro: $($_.Exception.Message)"}
      }
      else {
        Write-Host "Computador $name Não será removido. Ultima alteração: $data "
         }
        
                  
        $removeReportEntry = [PSCustomObject] @{
            Name = $name
            DistinguishedName = $distinguishedName
            LastLogonDate = $lastLogon
            WhenChanged = $formattedwhenChanged
            Enabled = $enabled
            Comments = $observacao
            Date = $data        }

        $removeReport += $removeReportEntry
          }
$removeReport | Export-Csv -Path $path_deleted -Encoding UTF8 -Delimiter ";" -NoTypeInformation
######Parte 3

 #Função para enviar o relatório via e-mail | Caso haja necessidade, retire o comentário.

#$Username = "teste@unicesumar.edu.br";

<#

function Send-ToEmail([string]$email){
    $message = New-Object Net.Mail.MailMessage;
    $message.From = $Username;
    $message.To.Add($file1);
    $message.To.Add($file2)
    $message.Subject = "Computadores movidos";
    $message.Body = "Anexo relatório de rotinas de organização de computadores e de computadores excluidos por estarem desabilitados a mais de 30 dias.";

    Write-Host "Anexando arquivo" -ForegroundColor Red

    $file1 = "$($path_deleted)"
    $att = New-Object Net.Mail.Attachment($file1)
    $message.Attachments.Add($file1)
    $file2 = "$($path)"
    $att = New-Object Net.Mail.Attachment($file2)
    $message.Attachments.Add($file2)

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
    
    }


Send-ToEmail -email "renata.belo@vitru.com.br";
#Send-ToEmail -email "fernando.cordeiro@unicesumar.edu.br"; #>