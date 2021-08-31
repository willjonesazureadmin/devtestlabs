  
##################################################################################################
#
# Parameters to this script file.
#

[CmdletBinding()]
param(
    # comma- separated list of powershell modules.
    [string] $PsModules = "Az",

    # domain name
    [string] $DomainName = "azureadmin.local",

    # secret reference
    [string] $SecretReference = "DTL-DomainJoin",

    # keyvault name name
    [string] $KeyVaultName = "aadtlkv01",

    # domain join username
    [string] $DomainJoinUsername = "dtl-domainjoin",

    # OU Path to use
    [string] $OUPath = $Null,

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
        $response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata="true"} -UseBasicParsing
        Write-Host "Success: " + $(Get-Date)
        $content = $response.Content | ConvertFrom-Json
        $KeyVaultToken = $content.access_token

        # Get credentials
        $result = (Invoke-WebRequest -Uri "https://$($KeyVaultName).vault.azure.net/secrets/$($SecretReference)?api-version=2016-10-01" -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"} -UseBasicParsing).content
        $begin = $result.IndexOf("value") + 8
        $endlength = ($result.IndexOf('"',$begin) -10)
        $DomainJoinPassword = $result.Substring($begin,$endlength)

        Write-Host "Attempting to join computer $($Env:COMPUTERNAME) to domain $DomainName."
        $securePass = ConvertTo-SecureString $DomainJoinPassword -AsPlainText -Force

        if ((Get-WmiObject Win32_ComputerSystem).Domain -eq $DomainName)
        {
            Write-Host "Computer $($Env:COMPUTERNAME) is already joined to domain $DomainName."
        }
        else
        {
            $credential = New-Object System.Management.Automation.PSCredential($DomainJoinUsername, $securePass)
        
            if ($OUPath)
            {
                [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -Credential $credential -OUPath $OUPath -Force -PassThru
            }
            else
            {
                [Microsoft.PowerShell.Commands.ComputerChangeInfo]$computerChangeInfo = Add-Computer -DomainName $DomainName -Credential $credential -Force -PassThru
            }
        
            if (-not $computerChangeInfo.HasSucceeded)
            {
                throw "Failed to join computer $($Env:COMPUTERNAME) to domain $DomainName."
            }
        
            Write-Host "Computer $($Env:COMPUTERNAME) successfully joined domain $DomainName."
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

function Validate-Params
{
    [CmdletBinding()]
    param(
    )

    if ([string]::IsNullOrEmpty($PsModules))
    {
        throw 'Packages parameter is required.'
    }
}

###################################################################################################
#
# Main execution block.
#

try
{
    pushd $PSScriptRoot

    Write-Host 'Validating parameters.'
    Validate-Params

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
