# code: insertSpaces=false tabSize=4

<#
Cypyright (c) Petr Řehoř https://github.com/prehor. All rights reserved.
Licensed under the Apache License, Version 2.0.
#>

<#
.SYNOPSIS
Example PowerSehll Runbook script.

.DESCRIPTION
This example Azure Automation runbook is ready to run in Azure Automation using System Managed Identity.

Prerequisite: an Azure Automation account with an Azure Managed Identity account credential.

NOTE: This script must be renamed to the target name before syncing to Azure Automation!

.PARAMETER Example
Example parameter description.

.LINK
https://github.com/prehor/AzureAutomationRunbookTemplate
#>

###############################################################################
### PARAMETERS ################################################################
###############################################################################

#region Parameters

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[String]$Example
)

# Set strict mode
Set-StrictMode -Version Latest

#endregion

###############################################################################
### CONSTANTS #################################################################
###############################################################################

#region Constants

# Stop on errors
$ErrorActionPreference = 'Stop'

#endregion

###############################################################################
### FUNCTIONS #################################################################
###############################################################################

#region Functions

### Write-Log #################################################################

# Write formatted log message
function Write-Log() {
	param(
		[Parameter(Position=0)]
		[String]$Message,

		[Parameter()]
		[String[]]$Property,

		[Parameter(ValueFromPipeline)]
		[Object[]]$Arguments
	)

	begin {
		$Properties = $Property
	}

	process {
		# Always output verbose messages
		$Private:SavedVerbosePreference = $VerbosePreference
		$VerbosePreference = 'Continue'

		# Format timestamp
		$Timestamp = '{0}Z' -f (Get-Date -Format 's')
		$MessageWithTimestamp = '{0} {1}' -f $Timestamp, $Message

		# Format arguments
		if ($null -eq $Properties) {
			# $Arguments contains array of values
			$Values = @()
			foreach ($Argument in $Arguments) {
				$Values += $_ | Out-String |
				# Remove ANSI colors
				ForEach-Object { $_ -replace '\e\[\d*;?\d+m','' }
			}
			Write-Verbose ($MessageWithTimestamp -f $Values)
		} else {
			# $Arguments contains array of objects with properties
			foreach ($Argument in $Arguments) {
				$Values = $()
				# Convert hashtable to object
				if ($Argument -is 'Hashtable') {
					$Argument = [PSCustomObject]$Argument
				}
				$ArgumentProperties = $Argument.PSObject.Properties.Name
				foreach ($Property in $Properties) {
					$Values += if ($ArgumentProperties -contains $Property) {
						if ($null -ne ($Value = $Argument.$_)) {
							$Value | Out-String |
							# Remove ANSI colors
							ForEach-Object { $_ -replace '\e\[\d*;?\d+m','' }
						} else {
							'ENULL'
						}
					} else {
						'ENONENT'
					}
				}
				Write-Verbose ($MessageWithTimestamp -f $Values)
			}
		}

		# Restore $VerbosePreference
		$VerbosePreference = $Private:SavedVerbosePreference
	}
}

### Login-AzureAutomation #####################################################

# Login in to Azure Active Directory
function Login-AzureAutomation() {
	Write-Log "### Sign in to Azure Active Directory"

	switch ($Env:POWERSHELL_DISTRIBUTION_CHANNEL) {
		'AzureAutomation' {
			Write-Log "Sign in with system managed identity"

			# Ensure that you do not inherit an AzContext
			Disable-AzContextAutosave -Scope Process | Out-Null

			# Connect using a Managed Service Identity
			$AzureContext = (Connect-AzAccount -Identity).Context

			# Set and store context
			Set-AzContext -Tenant $AzureContext.Tenant -SubscriptionId $AzureContext.Subscription -DefaultProfile $AzureContext | Out-Null
		}
		default {
			Write-Log "Using current user credentials"
		}
	}
}

### Get-AzToken ###############################################################

# Get an authentication token to access cloud services
function Get-AzToken {
	param (
		[Parameter(Mandatory = $true)]
		[String]$ResourceUri
	)

	# Get the current Azure context
	$AzureContext = Get-AzContext

	# Get Azure authentication token
	# https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.commands.common.authentication.abstractions.iauthenticationfactory.authenticate
	[Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
		$AzureContext.Account,
		$AzureContext.Environment,
		$AzureContext.Tenant.Id,
		$null,
		[Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never,
		$null,
		$ResourceUri
	).AccessToken
}

#endregion

###############################################################################
### MAIN ######################################################################
###############################################################################

#region Main

### Setup PowerShell Preferences ##############################################

# Stop on errors
$Private:SavedVerbosePreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

# Suppress verbose messages
$Private:SavedVerbosePreference = $VerbosePreference
$VerbosePreference = 'SilentlyContinue'

### Open log ##################################################################

# Log start time
$StartTimestamp = Get-Date
Write-Log "### Runbook started at $(Get-Date -Format 's')Z"

### Sign in to cloud services #################################################

# Sign in to Azure
Login-AzureAutomation

# Log Azure Context
Get-AzContext |
Format-List |
Out-String -Stream -Width 1000 |
Where-Object { $_ -notmatch '^\s*$' } |
Write-Log '{0}'

### Something useful ##########################################################

# TODO: Put some useful stuff here

### Close log #################################################################

# Log duration
$StopTimestamp = Get-Date
Write-Log "### Runbook finished in $($StopTimestamp - $StartTimestamp)"

### Restore PowerShell Preferences ############################################

# Restore $ErrorActionPreference
$ErrorActionPreference = $Private:SavedVerbosePreference

# Restore $VerbosePreference
$VerbosePreference = $Private:SavedVerbosePreference

#endregion
