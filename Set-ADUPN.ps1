function Set-ADUPN {
    <#
    .SYNOPSIS
    Used to prepare AD connect sync by changing the users UPN to match their UPN in AzureAD before a sync
    .DESCRIPTION
    Set-ADUPN can be used with a CSV file in the following format "Name","UserLogon". This command will get a list of users defined in your CSV file and loop through each user and match the display name to an AD object once found it will change the UPN to the specified UPN that was put into the CSV. The command will also create a changelog in the current working directory with the Display name, Old UPN and the New UPN. If the UPN was not able to be changed it will set item in the New UPN column to ERROR.
    .PARAMETER CSV
    CSV Parameter is mandatory and will take the objects in the CSV file and loop through them to change the UPN for each user and add them each to the changelog
    .PARAMETER ChangeLogPath
    Parameter is not mandatory but it can be changed it you prefer to a different location
    .EXAMPLE
    Set-ADUPN -CSV .\users.csv
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true,Position=0)]
        [string]$CSV,

        [parameter(Mandatory=$false)]
        [string]$ChangelogPath = '.\ChangeLog.csv'
    )

    Begin{            
            $Users = Import-CSV $CSV
    }

    Process{
        foreach ($User in $Users) {

        $Changelog = @{
            'DisplayName' = ''
            'OldUPN' = ''
            'NewUPN' = ''
        }
        
            $Name = $User.Name
            $NewUPN = $User.Userlogon

            Write-Verbose "Looking for user $Name in AD..."

            $Changelog.DisplayName = $Name

            $ADUser = Get-ADUser -Filter "displayname -eq '$($User.Name)'"

            $OldUPN = $ADUser.UserPrincipalName

            $Changelog.OldUPN = $OldUPN


            if ($null -ne $ADUser) {

                Write-Verbose "Found user $Name changing upn from $OldUPN to $NewUPN"

                Set-ADUser -Identity $ADUser -UserPrincipalName $NewUPN

                $Changelog.NewUPN = $NewUPN
            }

            else {
                Write-Warning "$Name was not able to be updated"
                $Changelog.NewUPN = "#ERROR"
            }

            $obj = New-Object -TypeName PSObject -Property $Changelog
            $obj | Export-Csv -Path $ChangelogPath -Append

        } #Foreach

    }#Process

    End{
        Import-Csv -Path $ChangelogPath
    }

}#Function


function Set-ADProxyAddress {
    [cmdletbinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true,ValuefromPipeline=$true,Position=0)]
        [string[]]$CSV
    )

    Begin{
        $Users = Import-Csv $CSV
    }

    Process {

        foreach ($User in $Users) {
            
            $ADUser = Get-ADUser -Filter "displayname -eq '$($User.Name)'"

            if ($null -ne $ADUser) {

                $Address = $ADUser.userprincipalname.replace('.com',"")

                Set-ADUser -Identity $ADUser -add @{'Proxyaddresses'="SMTP:$Address.com"}
                Set-ADUser -Identity $ADUser -add @{'Proxyaddresses'="smtp:$Address.onmicrosoft.com"}
                Set-ADUser -Identity $ADUser -add @{'Proxyaddresses'="smtp:$Address.mail.onmicrosoft.com"}
                

            }#If

            else {
                Write-Warning "Not able to chage Proxy Address for user $User"
            }#Else

        }#foreach
    }#process
    End{}#end
}#function
