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
	[Parameter(Mandatory)]
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

### SignInTo-AzureAutomation ##################################################

# Sign in to Azure Automation account
function SignInTo-AzureAutomation() {
	Write-Log "### Sign in to Azure Automation Account"

	switch ($Env:POWERSHELL_DISTRIBUTION_CHANNEL) {
		'AzureAutomation' {
			Write-Log "Sign in with Azure Automation managed identity"

			# Ensure that you do not inherit an AzContext
			Disable-AzContextAutosave -Scope Process | Out-Null

			# Connect using a Managed Service Identity
			$AzureContext = (Connect-AzAccount -Identity).Context

			# Set and store context
			Set-AzContext -Tenant $AzureContext.Tenant -SubscriptionId $AzureContext.Subscription -DefaultProfile $AzureContext |
			Write-Log
		}
		default {
			Write-Log "Using current user connection"
			Get-AzContext |
			Write-Log
		}
	}
}

### SignInTo-MicrosoftGraph ###################################################

### Sign in to Microsoft Graph
function SignInTo-MicrosoftGraph() {
	param(
		[Parameter()]
		[String]$Version
	)

	Write-Log "### Sign in to Microsoft Graph"

	# Switch to required Microsoft Graph version
	if ($Version) {
		Write-Log "Switching to Microsoft Graph $($Version) API"
		Select-MgProfile -Name $Version
	} else {
		Write-Log "Using Microsoft Graph API $($Version)"
	}

	# Sign in to Microsoft Graph
	switch ($Env:POWERSHELL_DISTRIBUTION_CHANNEL) {
		'AzureAutomation' {
			$AccessToken = (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com/').Token
			Connect-MgGraph -AccessToken $AccessToken |
			Write-Log
		}
		default {
			Write-Log "Using current user connection"
		}
	}

	# Log Microsoft Graph Context
	Get-MgContext |
	Write-Log
}

### Write-Log #################################################################

# Write formatted log message
function Write-Log() {
	[CmdletBinding(DefaultParameterSetName='Arguments')]
	param(
		[Parameter(Position=0)]
		[String]$Message,

		[Parameter(ParameterSetName='Arguments',ValueFromRemainingArguments)]
		[Object[]]$Arguments,

		[Parameter(ParameterSetName='Pipeline', ValueFromRemainingArguments)]
		[String[]]$Property,

		[Parameter(ParameterSetName='Pipeline',ValueFromPipeline)]
		[Object]$InputObject
	)

	process {
		# Always output verbose messages
		$Private:SavedVerbosePreference = $VerbosePreference
		$VerbosePreference = 'Continue'

		# Process arguments
		$Lines = @()
		switch ($PsCmdlet.ParameterSetName) {
			'Pipeline' {
				# Default message format for pipeline input
				if (-not $Message) {
					$Message = '{0}'
				}
				# Get arguments from object
				if ($null -eq $Property) {
					# Input object is string
					if ($InputObject -is [String]) {
						$Lines += $Message -f $InputObject
					# Format input object
					} else {
						$Lines += $InputObject |
						Format-List |										# Format object as a list
						Out-String -Stream -Width 1000 |					# Convert lines to string
						ForEach-Object { $_ -replace '\e\[\d*;?\d+m','' } |	# Remove ANSI colors
						Where-Object { $_ -notmatch '^\s*$' } |				# Strip empty lines
						ForEach-Object { $Message -f $_ }					# Format message
					}
				} else {
					# Get arguments from object properties
					$Arguments = $Property | ForEach-Object { $InputObject.$_ }
					$Lines += $Message -f $Arguments
				}
			}
			default {
				# Format message with arguments
				if ($Arguments) {
					$Lines += $Message -f $Arguments
				# Format message without arguments
				} else {
					$Lines += $Message
				}
			}
		}

		# Add timestamp to the message
		$Timestamp = '{0:s}{0:%K}' -f (Get-Date)
		$Lines | ForEach-Object {
			Write-Verbose ('{0} {1}' -f $Timestamp, $_)
		}

		# Restore $VerbosePreference
		$VerbosePreference = $Private:SavedVerbosePreference
	}
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
Write-Log "### Runbook started at {0:s}{0:%K}" -Arguments $StartTimestamp

### Sign in to cloud services #################################################

# Sign in to Azure Automation account
SignInTo-AzureAutomation

# Sign in to Microsoft Graph
SignInTo-MicrosoftGraph

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
