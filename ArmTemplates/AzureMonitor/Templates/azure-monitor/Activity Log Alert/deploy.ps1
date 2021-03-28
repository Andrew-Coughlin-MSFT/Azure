<#
        .Disclaimer
        MIT License - Copyright (c) Microsoft Corporation. All rights reserved.
        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
        FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
        IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE
        .SYNOPSIS
        Creates Azure Monitor Alerts for Azure CIS 1.1.0. Creates the requirements for a resource group and if needed action group.

        .DESCRIPTION
        Creates Azure Monitor Alerts for Azure CIS 1.1.0.:
        5.2.1. Ensure that Activity Log Alert exists for Create Policy Assignment
        5.2.2. Ensure that Activity Log Alert exists for Create or Update Network Security Group
        5.2.3. Ensure that Activity Log Alert exists for Delete Network Security Group
        5.2.4. Ensure that Activity Log Alert exists for Create or Update Network Security Group Rule
        5.2.5. Ensure that activity log alert exists for the Delete Network Security Group Rule
        5.2.6. Ensure that Activity Log Alert exists for Create or Update Security Solution
        5.2.7. Ensure that Activity Log Alert exists for Delete Security Solution
        5.2.8. Ensure that Activity Log Alert exists for Create or Update or Delete SQL Server Firewall Rule
        5.2.9. Ensure that Activity Log Alert exists for Update Security Policy

        Creates the requirements for a resource group and if needed action group.

        .PARAMETER bSingleSubscription
        (Optional)
        Specifies if the script should run across all subscriptions or only one.  True = single subscription, False = multiple subscription.

        .PARAMETER AzureRegion
        (Optional)
        Specifies the azure region to create the action group and resource group.

        .EXAMPLE
        PS> deploy.ps1 

        This example will run against all subscriptions you have permissions to create Azure Monitor alerts.

        .EXAMPLE
        PS> deploy.ps1 -AzureRegion "centralus"

        This example will run against all subscriptions you have permissions to create Azure Monitor alerts and create resources in the central us region.

        .EXAMPLE
        PS> deploy.ps1 -bSingleSubscription $true -AzureRegion "centralus" -AzsubScriptionID "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

        This example will run against only 1 subscription, create resources in central us region and run against the subscription you specify.

    #>

Param
(
    [Parameter(Position = 0)]
    [bool] $bSingleSubscription = $false,
    [Parameter(Position = 1)]
    [string] $AzureRegion,
    [Parameter(Position = 2)]
    [string] $AzsubScriptionID
)
function Create_Action_Group {
    Param
    (
        [Parameter(Position = 0)]
        [string] $rgName,
        [Parameter(Position = 1)]
        [string] $actionGroupName,
        [Parameter(Position = 2)]
        [string] $Email
    )
    try {
        $EmailAddresses = New-AzActionGroupReceiver -Name "Email" -EmailReceiver -EmailAddress $Email
        Set-AzActionGroup -Name $actionGroupName -ResourceGroupName $rgName -ShortName 'email' -Receiver $EmailAddresses
    }
    catch {
        $PSCmdlet.WriteError($_)
        Break
    }
}
function AzAccountLogin() {
    $AzContext = Get-AzContext

    if (!$AzContext) {
        Write-Host "Connecting to Azure"
        Connect-AzAccount
    } 
}

##################################Configuration Area ##########################################################
#Configure these variables before executing this script

$AlertRuleActionGroupName = "Activity_Log_Alerts" #action group, where you want the emails to go to when these alerts fire
#Alteratively you can create the action group a different way just need to reference the name here and it won't recreate it.
$myResourceGroupName = "rg-alerts" #resource group where you want the alerts to be created
$emailAddress = "ancoughlin@microsoft.com"  #email address to send the alerts when the alert is triggered

###############################################################################################################

try {
    $BaseDir = 'https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/ArmTemplates/AzureMonitor/Templates'
    $templateUri = "$BaseDir/azure-monitor/Activity%20Log%20Alert/main-deployment/azuredeployment.json"
    
    if ($bSingleSubscription -eq $false) {
        AzAccountLogin
        $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }
    }
    else {
        AzAccountLogin
        if (([string]::IsNullOrEmpty($AzsubScriptionID))) {
            
            $SubscriptionId = Read-Host "Type the Subscription Id"
            $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId
        }
        else {
            $SubscriptionId = $AzsubScriptionID
            $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId
        }
    }
    if ($subscriptions.Count -lt 1) {
        Write-Output "No Subscriptions to run against." -BackgroundColor Yellow -ForegroundColor Black
    }
    foreach ($subscription in $subscriptions) {
        Select-AzSubscription -SubscriptionID $subscription.Id
        Get-AzResourceGroup -Name $myResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
        if ($notPresent) {
            # ResourceGroup doesn't exist
            Write-Output "Creating Resource Group."
            if (([string]::IsNullOrEmpty($AzureRegion))) {
                $AzRegionName = Read-Host "Specify Azure Region Name (ex: centralus)"
            }
            else {
                $AzRegionName = $AzureRegion
            }
            #Create Resource Group
            New-AzResourceGroup -Location $AzRegionName -Name $myResourceGroupName
            Write-Output "Creating Action Group"
            Create_Action_Group -rgName $myResourceGroupName -actionGroupName $AlertRuleActionGroupName -Email $emailAddress
        }
        else {
            Write-Output "Resource Group Already Created, going to next step."
            Get-AzActionGroup -Name $myResourceGroupName -ResourceGroupName $myResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
            if ($notPresent) {
                ##Action Group Doesn't exist
                Write-Output "Creation Action Group"
                Create_Action_Group -rgName $myResourceGroupName -actionGroupName $AlertRuleActionGroupName -Email $emailAddress
            }
        }
        #execute deployment for Azure Monitor Alerts
        $targetsub = $subscription.Id
        New-AzResourceGroupDeployment -ResourceGroupName $myResourceGroupName -TemplateUri $templateUri -targetsub $targetsub -AlertRuleActionGroupName $AlertRuleActionGroupName -Verbose
    }
}
catch {
    Write-Output $_.Exception.Message
}


