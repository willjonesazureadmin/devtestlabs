  
##################################################################################################
#
# Parameters to this script file.
#

[CmdletBinding()]
param(
    # DevTest Lab Names
    [string] $DTLName = "DTL",

    # domain name
    [string] $DomainName = "azureadmin.local",

    # secret reference
    [string] $SecretReference = "DTL-DomainJoin",

    # keyvault name name
    [string] $KeyVaultName = "aadtlkv01",

    # domain join username
    [string] $DomainJoinUsername = "dtl-domainjoin",

    #Groups To Add User To
    [string] $Groups = "SQLAdmins,Administrators",
    
    # Boolean indicating if we should allow empty checksums. Default to true to match previous artifact functionality despite security
    [bool] $AllowEmptyChecksums = $true,

    # Boolean indicating if we should ignore checksums. Default to false for security
    [bool] $IgnoreChecksums = $false,
    
    # Minimum PowerShell version required to execute this script.
    [int] $PSVersionRequired = 5
)

###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = 'Stop'

# Suppress progress bar output.
$ProgressPreference = 'SilentlyContinue'

# Ensure we force use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Expected path of the choco.exe file.
$choco = "$Env:ProgramData/chocolatey/choco.exe"

###################################################################################################
#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    $message = $Error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "`nERROR: $message" -ForegroundColor Red
    }

    Write-Host "`nThe artifact failed to apply.`n"

    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

###################################################################################################
#
# Functions used in this script.
#


function Ensure-PowerShell
{
    [CmdletBinding()]
    param(
        [int] $Version
    )

    if ($PSVersionTable.PSVersion.Major -lt $Version)
    {
        throw "The current version of PowerShell is $($PSVersionTable.PSVersion.Major). Prior to running this artifact, ensure you have PowerShell $Version or higher installed."
    }
}

function RunCommand
{
        $VM = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET  -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
        $response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com' -Method GET -Headers @{Metadata="true"} -UseBasicParsing
        Write-Host "Success: " + $(Get-Date)
        $content = $response.Content | ConvertFrom-Json
        $apiToken = $content.access_token

       
        $dtlVM = ConvertFrom-Json (Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$($VM.compute.subscriptionId)/resourceGroups/$($VM.compute.resourceGroupName)/providers/Microsoft.DevTestLab/labs/$($DTLName)/virtualmachines/$($VM.compute.name)?api-version=2016-05-15" -Method GET -Headers @{Authorization="Bearer $apiToken"} -ContentType "application/json").content
        
        
        foreach($GroupName in $Groups -split ",")
        {
                Write-Host "Getting group $GroupName"
                $group = Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue
                if($group -eq $null)
                {
                    New-LocalGroup -Name $GroupName 
                }
                Add-LocalGroupMember -Group $GroupName -Member $($dtlVM.properties.ownerUserPrincipalName) -ErrorAction SilentlyContinue
        }
 
    
}

function Invoke-ExpressionImpl
{
    [CmdletBinding()]
    param(
        $Expression
    )

    # This call will normally not throw. So, when setting -ErrorVariable it causes it to throw.
    # The variable $expError contains whatever is sent to stderr.
    iex $Expression -ErrorVariable expError

    # This check allows us to capture cases where the command we execute exits with an error code.
    # In that case, we do want to throw an exception with whatever is in stderr. Normally, when
    # Invoke-Expression throws, the error will come the normal way (i.e. $Error) and pass via the
    # catch below.
    if ($LastExitCode -or $expError)
    {
        if ($LastExitCode -eq 3010)
        {
            # Expected condition. The recent changes indicate a reboot is necessary. Please reboot at your earliest convenience.
        }
        elseif ($expError[0])
        {
            throw $expError[0]
        }
        else
        {
            throw "Installation failed ($LastExitCode)."
        }
    }
}



###################################################################################################
#
# Main execution block.
#

try
{
    pushd $PSScriptRoot

    Write-Host 'Configuring PowerShell session.'
    Ensure-PowerShell -Version $PSVersionRequired
    Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null

    Write-Host 'Running Command'
    RunCommand

    Write-Host "`nThe artifact was applied successfully.`n"
}
finally
{
    popd
}
