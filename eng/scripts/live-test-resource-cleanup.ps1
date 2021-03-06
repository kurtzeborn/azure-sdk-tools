#!/usr/bin/env pwsh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#Requires -Version 6.0
#Requires -PSEdition Core

[CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param (
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')]
    [string] $ProvisionerApplicationId,

    [Parameter(Mandatory = $true)]
    [string] $ProvisionerApplicationSecret,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')]
    [ValidateNotNullOrEmpty()]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')]
    [string] $SubscriptionId,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Environment = "AzureCloud",

    [Parameter()]
    [switch] $Force,

    [Parameter(ValueFromRemainingArguments = $true)]
    $IgnoreUnusedArguments
)
eng/common/scripts/Import-AzModules.ps1

Write-Verbose "Logging in"
$provisionerSecret = ConvertTo-SecureString -String $ProvisionerApplicationSecret -AsPlainText -Force
$provisionerCredential = [System.Management.Automation.PSCredential]::new($ProvisionerApplicationId, $provisionerSecret)
Connect-AzAccount -Force -Tenant $TenantId -Credential $provisionerCredential -ServicePrincipal -Environment $Environment
Select-AzSubscription -Subscription $SubscriptionId

Write-Verbose "Fetching groups"
$allGroups = Get-AzResourceGroup

Write-Host "Total Resource Groups: $($allGroups.Count)"

$now = [DateTime]::UtcNow

$noDeleteAfter = $allGroups.Where({ $_.Tags.Keys -notcontains "DeleteAfter" })
Write-Host "Subscription contains $($noDeleteAfter.Count) resource groups with no DeleteAfter tags"
$noDeleteAfter | ForEach-Object { Write-Verbose $_.ResourceGroupName }

$hasDeleteAfter = $allGroups.Where({ $_.Tags.Keys -contains "DeleteAfter" })
Write-Host "Count $($hasDeleteAfter.Count)"
$toDelete = $hasDeleteAfter.Where({ $now -gt [DateTime]$_.Tags.DeleteAfter })
Write-Host "Groups to delete: $($toDelete.Count)"

foreach ($rg in $toDelete)
{
  if ($Force -or $PSCmdlet.ShouldProcess("$($rg.ResourceGroupName) (UTC: $($rg.Tags.DeleteAfter))", "Delete Group")) {
    Write-Verbose "Deleting group: $($rg.Name)"
    Write-Verbose "  tags $($rg.Tags | ConvertTo-Json -Compress)"
    Write-Host ($rg | Remove-AzResourceGroup -Force -AsJob).Name
  }
}
