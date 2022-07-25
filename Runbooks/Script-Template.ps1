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
		[Object[]]$Arguments
	)

	# Format timestamp
	$Timestamp = '{0}Z' -f (Get-Date -Format 's')
	$Mesage = '{0} {1}' -f $Timestamp, $Message

	# Format arguments
	if ($null -ne $Arguments) {
		$Message = $Mesage -f $Arguments
	}

	# Always output verbose messages
	$OldVerbosePreference = $VerbosePreference
	$VerbosePreference = 'Continue'

	# Output message
	Write-Verbose $Message

	# Restore $VerbosePreference
	$VerbosePreference = $OldVerbosePreference
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
			Set-AzContext -Tenant $AzureContext.Tenant -SubscriptionId $AzureContext.Subscription -DefaultProfile $AzureContext | Format-List
		}
		default {
			Write-Log "Using current user credentials"
			Get-AzContext | Format-List
		}
	}
}

#endregion

###############################################################################
### MAIN ######################################################################
###############################################################################

#region Main

### Open log ##################################################################
$StartTimestamp = Get-Date
Write-Log "### Runbook started at $(Get-Date -Format 's')Z"

### Sign in to Azure ##########################################################
Login-AzureAutomation

### Something useful ##########################################################
# TODO: Put some useful stuff here

### Close log #################################################################
$StopTimestamp = Get-Date
Write-Log "### Runbook finished in $($StopTimestamp - $StartTimestamp)"

#endregion
