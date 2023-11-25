#--------Load modules-----------------
$a = (get-module|%{$_.name}) -join " "
if(!$a.Contains("Activedirectory")) {Import-Module Activedirectory -ErrorVariable err -Force}
if(!$a.Contains("SMLets")) {Import-Module smlets -ErrorVariable err -Force}

# Load SCSM cmdlets.

if ((Test-Path 'C:\Program Files\Microsoft System Center 2012\Service Manager\Powershell\System.Center.Service.Manager.psd1') -and (Test-Path 'C:\Program Files\Microsoft System Center 2012\Service Manager\Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1' ))
	{
		Import-Module 'C:\Program Files\Microsoft System Center 2012\Service Manager\Powershell\System.Center.Service.Manager.psd1' 
		Import-Module 'C:\Program Files\Microsoft System Center 2012\Service Manager\Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1' 
	}
else
	{
	if ((Test-Path 'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Powershell\System.Center.Service.Manager.psd1') -and (Test-Path 'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1'))
		{
		Import-Module 'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Powershell\System.Center.Service.Manager.psd1'
		Import-Module 'C:\Program Files\Microsoft System Center 2012 R2\Service Manager\Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1'
		}
	else	
        {
	        Write-Host "Can't load SCSM Powershell cmdlets. Check if Service Manager components are installed."
        	exit
		}
	}

Function CreateIncident
{
Param
    (
    $IncDescription,
    $IncSecurityAdmin
    )
#Get the Incident Class
$IRClass = get-SCSMClass -Name System.WorkItem.Incident

#Set the ID of the Incident
$id = "IR{0}"

#Set the title and description of the incident
$title="Инцидент контроля прав доступа пользователей"
$description = $IncDescription

#Set the impact and urgency of the incident
$impact = Get-SCSMEnumeration -Name   System.WorkItem.TroubleTicket.ImpactEnum.Medium
$urgency = Get-SCSMEnumeration -Name System.WorkItem.TroubleTicket.UrgencyEnum.Medium
$classification = Get-SCSMEnumeration -Name IncidentClassificationEnum.Other
$source = Get-SCSMEnumeration -Name IncidentSourceEnum.Console

#Create a hashtable of the incident values
$incidentHashTable = @{
Id = $id
Title = $title
Description = $description
Impact = $impact
Urgency = $urgency
Classification= $classification
Source = $source
}

#Create the incident
$newIncident = New-SCSMObject $IRClass -PropertyHashtable $incidentHashTable –PassThru
$newIncidentID=$newIncident.id

#Get The Incident Type Projection
$IncidentTypeProjection = Get-SCSMTypeProjection -name System.WorkItem.Incident.ProjectionType$

#Get the Incident created earlier in a form where we can apply the template
$IncidentProjection = Get-SCSMObjectProjection -ProjectionName $IncidentTypeProjection.Name -filter “ID -eq $newIncidentID”

#Get The Incident Template
$IncidentTemplate = Get-SCSMObjectTemplate -DisplayName “инцидент в Бресте”

#Apply the template to the Service Request
Set-SCSMObjectTemplate -Projection $IncidentProjection -Template $IncidentTemplate

$Inc = Get-SCSMObject $IRClass -Filter "Id -eq $newincidentid"
$RelWorkItemAssignedToUser = Get-SCSMRelationshipClass System.WorkItemAssignedToUser$
$AssignedToUser = New-SCSMRelationshipObject -Relationship $RelWorkItemAssignedToUser -Source $Inc -Target $IncSecurityAdmin -NoCommit
$AssignedToUser.Commit()
}

Function SendEmail
{
Param
    (
    $MessageSubject,
    $MessageBody
    )
$messagercpt ="DPA-SCSM-Email-Test@btg.by"
$messageto="DPA-SCSM-Email-Test@btg.by"
$SMTPServer ="beltg-01-74"


Send-Mailmessage -from $messagercpt -to $messageto -subject "$messagesubject" -body "$messagebody" -smtpServer $SMTPServer -Encoding UTF8
}

$SCSMServer = "beltg-01-scsm.btg.local"

# Define domain username and password
$username = 'btg\svc-SCSM-DisUser-RW'
$password = 'P9NDdEyG'
 
# Convert to a single set of credentials
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $username, $securePassword

$RelGroup = Get-SCRelationship -Name "NAVUS.BusinessService.NewSecurityRole.ADGroup" -ComputerName $SCSMServer
$RelUser = Get-SCRelationship -Name "NAVUS.BusinessService.NewSecurityRole.User" -ComputerName $SCSMServer
$RelSystem = Get-SCRelationship -Name "NAVUS.BusinessService.InformationSystem.NewSecurityRole" -ComputerName $SCSMServer
$RelSecurityAdmin=Get-SCRelationship -Name "NAVUS.BusinessService.SecurityAdministrator" -ComputerName $SCSMServer
$SecurityRole=Get-SCClassInstance -Class (Get-SCClass -Name "NAVUS.BusinessService.NewAccessSecurityRole" -ComputerName $SCSMServer) -ComputerName $SCSMServer
$User=Get-SCClassInstance -Class (Get-SCClass -Name "System.Domain.User" -ComputerName $SCSMServer) -ComputerName $SCSMServer | Where {$_.objectstatus -notmatch "Pending"}

#get AD domains
$forest = Get-Adforest
$domainList = @($forest.Domains)
# Проверяем каждую роль безопасности

Foreach($RoleItem in $SecurityRole)
{
    # Определяем использование группы безопасности для доступа   
    if ($RoleItem.Accessbygroup -eq $true)
    {
        $SCSMGroupGuid = $RoleItem.GetRelatedObjectsWhereSource($RelGroup.ID).EnterpriseManagementObject.id.GUID
        $InfSystem = $RoleItem.GetRelatedObjectsWhereTarget($RelSystem.ID)
        $InfSystemGUID = $InfSystem.EnterpriseManagementObject.id.GUID      
        $InfSystemIns = Get-SCClassInstance -ID $InfSystemGUID -ComputerName $SCSMServer
        $InfSystemType = ($InfSystemIns).InformationSystemType.Displayname
        $SecurityAdmin= $InfSystem.GetRelatedObjectsWhereSource($RelSecurityAdmin.ID)
        $SecurityAdminGuid=$SecurityAdmin.EnterpriseManagementObject.id.GUID
        $TierQueue=$InfSystemType                        
        
        switch ($TierQueue) 
            { 
                "Оршанское УМГ" {$TierQueue="АдминистраторИБ_Оршанское УМГ";break;}
                "Крупское УМГ" {$TierQueue="АдминистраторИБ_Крупское УМГ";break;}
                "Минское УМГ" {$TierQueue="АдминистраторИБ_Минское УМГ";break;}
                "Несвижское УМГ" {$TierQueue="АдминистраторИБ_Несвижское УМГ";break;}
                "Слонимское УМГ" {$TierQueue="АдминистраторИБ_Слонимское УМГ";break;}
                "Кобринское УМГ" {$TierQueue="АдминистраторИБ_Кобринское УМГ";break;}
                "Осиповичское УМГ" {$TierQueue="АдминистраторИБ_Осиповичское УМГ";break;}
                "Гомельское УМГ" {$TierQueue="АдминистраторИБ_Гомельское УМГ";break;}
                "Администрация" {$TierQueue="АдминистраторИБ";break;}
                "Мозырское ПХГ" {$TierQueue="АдминистраторИБ_Мозырское ПХГ";break;}
                "Молодечненское УБР" {$TierQueue="АдминистраторИБ_Молодечненское УБР";break;}
                "ИТЦ" {$TierQueue="АдминистраторИБ_ИТЦ";break;}
                "УМТСиК" {$TierQueue="АдминистраторИБ_УМТСиК";break;}
                "Минскавтогаз" {$TierQueue="АдминистраторИБ_Минскавтогаз";break;}
                "УООП" {$TierQueue="АдминистраторИБ_УООП";break;}
                'Дом отдыха "Алеся"' {$TierQueue="АдминистраторИБ_Алеся";break;} 
                "МФК" {$TierQueue="АдминистраторИБ_МФК";break;} 
                default {$TierQueue="АдминистраторИБ";break;}
            }

        $InfSystemType
        $TierQueue

        #проверка, что поле группы безопасности заполнено

        If ($SCSMGroupGuid -ne $Null)
            {
            
            # определяем SID каждой группы
            $SCSMGroup=Get-SCClassInstance -ID $SCSMGroupGuid -ComputerName $SCSMServer | Where {$_.objectstatus -notmatch "Pending"}
            $SCSMGroupSID=($SCSMGroup).SID
 
            $UsersGuid = $RoleItem.GetRelatedObjectsWhereSource($RelUser.ID).EnterpriseManagementObject.id.GUID
                
                #Проверка, что в матрице доступа указаны пользователи
                    if ([string]::IsNullOrEmpty($UsersGuid))
                        {
                
                        #Write-Host "Информационная система - $InfSystem. Для роли $RoleItem не указаны пользователи в матрице доступа" -foregroundcolor "magenta"
                        $EmailSubject="Для роли не указаны пользователи в матрице доступа"
                        $EmailBody="
                        Информационная система - $InfSystem
                        Используется в филиале - $InfSystemType
                        Для роли $RoleItem не указаны пользователи в матрице доступа"
                        #SendEmail -MessageSubject $EmailSubject -MessageBody $EmailBody

                        }
                    Else
                        {
                        
                        $SCSMUser=Get-SCClassInstance -ID $UsersGuid -ComputerName $SCSMServer | Where {$_.objectstatus -notmatch "Pending"} | Where {$_.objectstatus -notmatch "Ожидание удаления"}
                        $SCSMUserSID=($SCSMUser).SID
                        
                        }
 
            Foreach($SCSMGroupSIDItem in $SCSMGroupSID)
                {

                $SCSMGroupDomain=($User | Where-Object{$_.SID -eq $SCSMGroupSIDItem}).Domain

                    #Проверка, что в поле группа безопасности указана группа

                    $objectclass=(Get-ADObject -Filter {objectSid -eq $SCSMGroupSIDItem} -Server $SCSMGroupDomain -Credential $credential).objectclass 
                    If ($objectclass -like "Group")
                        {
                        $AdGroupName = (Get-ADGroup -filter {SID -eq $SCSMGroupSIDItem} -Server $SCSMGroupDomain -Credential $credential).Name
                       # write-host "------------------------------------------------------"
                       # write-host "Информационная система - $InfSystem. Группа АД $AdGroupName"
                        $ADGroupMember=Get-ADGroupMember $AdGroupName -Server $SCSMGroupDomain -Credential $credential | Get-ADUser | Where {$_.Enabled -eq $True}
                        $ADGroupMemberSID=($ADGroupMember).SID.Value
                        
                        $AlowADusersSID = @()
                        $DenyADusersSID = @()
                        $DenySCSMusersSID = @()
                        $AlowBranchADusersSID = @()
                        $DenyBranchADusersSID = @()
                        $DenyBranchSCSMusersSID = @()
                                                
                        # проверка наличия пользователей указанных в роли безопасности также в группе безопасности
                     
                    <#    foreach ($SCSMUserSIDItem in $SCSMUserSID)
                            {

                            If ($ADGroupMemberSID -eq $SCSMUserSIDItem ) 
                                {

                                $AlowADusersSID = $AlowADusersSID + $SCSMUserSIDItem

                                }
                            else
                                {

                                $DenyADusersSID = $DenyADusersSID +$SCSMUserSIDItem

                                }
                            }

                                if ($AlowADusersSID -ne "Null" )
                                {
                                   $AlowADuser=$User | Where-Object{$AlowADusersSID -contains $_.SID}
                                   #write-host "------------------------------------------------------"
                                   #Write-Host "Пользователь(и) имеют доступ в AD"
                                   $AlowADusers= $AlowADuser -join [Environment]::NewLine                 
                                }

                                if ($DenyADusersSID -ne "Null" )
                                {
                                   $DenyADuser=$User |Where-Object{$DenyADusersSID -contains $_.SID}
                                   # write-host "------------------------------------------------------"
                                   # Write-Host "Пользователь(и) не имеют доступ в AD"
                                   $DenyADusers=$DenyADuser -join [Environment]::NewLine
                                   $ADDescription="
Системой контроля прав доступа пользователей на базе System Center Service Manager создан инцидент о несоответствии предоставленых полномочий матрице доступа:
    Наименование информационной системы: $InfSystem
    Принадлежность инфрмационной системы к филиалу: - $InfSystemType
    Наименование роли в информационной системе: - $RoleItem
    Группа АД - $ADGroupName
    Пользователи отсутствующие в матрице доступа, которым доступ предоставлен:
    $DenyADusers
"
                                #CreateIncident -IncDescription $ADDescription -IncSecurityAdmin $SecurityAdmin

                                }
                                
                        # проверка наличия пользователей указанных в группе безопасности также в роли безопасности
               
                        #write-host "------------------------------------------------------"
                        #write-host "Информационная система - $InfSystem. Роль $RoleItem"
                                                                     
                        foreach ($ADUserSIDItem in $ADGroupMemberSID)
                            {

                            If ($SCSMUserSID -eq $ADUserSIDItem ) 
                                {
                                                                
                                $AlowSCSMusersSID = $AlowSCSMusersSID +$ADUserSIDItem

                                }                     
                            else
                                {

                                $DenySCSMusersSID = $DenySCSMusersSID +$ADUserSIDItem    

                                }
                            }

                            if ($AlowSCSMusersSID -ne "Null" )
                                {
                                #write-host "------------------------------------------------------"
                                #Write-Host "Пользователь(и) имеют доступ в матрице доступа"
                                #$SCSMUser -join [Environment]::NewLine
                                }

                            if ($DenySCSMusersSID -ne "Null")
                                {
                                $DenySCSMuser=$User | Where-Object{$DenySCSMusersSID -contains $_.SID}
                                #write-host "------------------------------------------------------"
                                #Write-Host "Пользователь(и) не имеют доступ в матрице доступа"
                                $DenySCSMusers=$DenySCSMuser -join [Environment]::NewLine
                                $SCSMDescription="
Системой контроля прав доступа пользователей на базе System Center Service Manager создан инцидент о несоответствии предоставленых полномочий матрице доступа:
    Наименование информационной системы: $InfSystem
    Принадлежность инфрмационной системы к филиалу: - $InfSystemType
    Наименование роли в информационной системе: - $RoleItem
    Группа АД - $ADGroupName
    Пользователи отсутствующие в матрице доступа, которым доступ предоставлен:
    $DenySCSMusers
"

                                #CreateIncident -IncDescription $SCSMDescription -IncSecurityAdmin $SecurityAdmin

                                }
                       #>
                       foreach ($domain in $domainList)
                            {
                            if ($domain -ne "btg.local")
                                {
                                $ADBranchGroupMember=Get-ADGroupMember $AdGroupName -Server $domain -Credential $credential | Get-ADUser | Where {$_.Enabled -eq $True}
                                $ADBranchGroupMemberSID=($ADBranchGroupMember).SID.Value
                                
                                    foreach ($SCSMBranchUserItem in $SCSMUser)
                                    {

                                        If (($SCSMBranchUserItem).FQDN -eq $domain ) 
                                        {

                                        $SCSMBranchUserSID = ($SCSMBranchUserItem).SID

                                        }
                                    }
                                # проверка наличия пользователей указанных в роли безопасности также в группе безопасности

                                      foreach ($SCSMBranchUserSIDItem in $SCSMBranchUserSID)
                                        {

                            If ($ADBranchGroupMemberSID -eq $SCSMBranchUserSIDItem ) 
                                {

                                $AlowBranchADusersSID = $AlowBranchADusersSID + $SCSMBranchUserSIDItem

                                }
                            else
                                {

                                $DenyBranchADusersSID = $DenyBranchADusersSID +$SCSMBranchUserSIDItem

                                }
                            }

                                if ($AlowBranchADusersSID -ne "Null" )
                                {
                                   $AlowBranchADuser=$User | Where-Object{$AlowBranchADusersSID -contains $_.SID}
                                   #write-host "------------------------------------------------------"
                                   #Write-Host "Пользователь(и) имеют доступ в AD"
                                   $AlowBranchADusers= $AlowBranchADuser -join [Environment]::NewLine                 
                                }

                                if ($DenyBranchADusersSID -ne "Null" )
                                {
                                   $DenyBranchADuser=$User |Where-Object{$DenyBranchADusersSID -contains $_.SID}
                                   # write-host "------------------------------------------------------"
                                   # Write-Host "Пользователь(и) не имеют доступ в AD"
                                   $DenyBranchADusers=$DenyBranchADuser -join [Environment]::NewLine
                                   $ADDescription="
Системой контроля прав доступа пользователей на базе System Center Service Manager создан инцидент о несоответствии предоставленых полномочий матрице доступа:
    Наименование информационной системы: $InfSystem
    Принадлежность инфрмационной системы к филиалу: - $InfSystemType
    Наименование роли в информационной системе: - $RoleItem
    Группа АД - $ADGroupName
    Пользователи отсутствующие в матрице доступа, которым доступ предоставлен:
    $DenyBranchADusers
"
                                #CreateIncident -IncDescription $ADDescription -IncSecurityAdmin $SecurityAdmin

                                }
                    
 # проверка наличия пользователей указанных в группе безопасности также в роли безопасности

 foreach ($ADBranchUserSIDItem in $ADBranchGroupMemberSID)
                            {

                            If ($SCSMBranchUserSID -eq $ADBranchUserSIDItem ) 
                                {
                                                                
                                $AlowBranchSCSMusersSID = $AlowBranchSCSMusersSID +$ADBranchUserSIDItem

                                }                     
                            else
                                {

                                $DenyBranchSCSMusersSID = $DenyBranchSCSMusersSID +$ADBranchUserSIDItem    

                                }
                            }

                            if ($AlowBranchSCSMusersSID -ne "Null" )
                                {
                                #write-host "------------------------------------------------------"
                                #Write-Host "Пользователь(и) имеют доступ в матрице доступа"
                                #$SCSMUser -join [Environment]::NewLine
                                }

                            if ($DenyBranchSCSMusersSID -ne "Null")
                                {
                                $DenyBranchSCSMuser=$User | Where-Object{$DenyBranchSCSMusersSID -contains $_.SID}
                                #write-host "------------------------------------------------------"
                                #Write-Host "Пользователь(и) не имеют доступ в матрице доступа"
                                $DenyBranchSCSMusers=$DenyBranchSCSMuser -join [Environment]::NewLine
                                $SCSMDescription="
Системой контроля прав доступа пользователей на базе System Center Service Manager создан инцидент о несоответствии предоставленых полномочий матрице доступа:
    Наименование информационной системы: $InfSystem
    Принадлежность инфрмационной системы к филиалу: - $InfSystemType
    Наименование роли в информационной системе: - $RoleItem
    Группа АД - $ADGroupName
    Пользователи отсутствующие в матрице доступа, которым доступ предоставлен:
    $DenyBranchSCSMusers
"

                                #CreateIncident -IncDescription $SCSMDescription -IncSecurityAdmin $SecurityAdmin

                                }
                                }
                            }
                        }
                    #Сообщение, используется не группа безопасности
                    else
                        {
                        #Write-host "Для роли $RoleItem используется не группа безопасности" -foregroundcolor "magenta"
                        $EmailSubject="Для роли используется не группа безопасности"
                        $EmailBody="
                        Информационная система - $InfSystem
                        Используется в филиале - $InfSystemType
                        Для роли $RoleItem используется не группа безопасности"
                        #SendEmail -MessageSubject $EmailSubject -MessageBody $EmailBody
                        }
                }
            
            }

        #Сообщение, поле группа безопасности не заполнено

     else
            {
            #Write-host "Для роли $RoleItem не указана группа безопасности" -foregroundcolor "magenta"
            $EmailSubject="Для роли не указана группа безопасности"
            $EmailBody="
            Информационная система - $InfSystem
            Используется в филиале - $InfSystemType
            Для роли $RoleItem не указана группа безопасности"
            #SendEmail -MessageSubject $EmailSubject -MessageBody $EmailBody
            }
    }
}

#--------Unload modules-----------------
remove-module -name Activedirectory -force
remove-module -name System.Center.Service.Manager -force
remove-module -name SMLets -force