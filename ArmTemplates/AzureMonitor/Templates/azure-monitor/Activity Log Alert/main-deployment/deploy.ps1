<#
        .SYNOPSIS
        Adds a file name extension to a supplied name.

        .DESCRIPTION
        Adds a file name extension to a supplied name.
        Takes any strings for the file name or extension.

        .PARAMETER bSingleSubscription
        Specifies if the script should run across all subscriptions or only one.  True = single subscription, False = multiple subscription.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        System.String. Add-Extension returns a string with the extension or file name.

        .EXAMPLE
        PS> extension -name "File"
        File.txt

        .EXAMPLE
        PS> extension -name "File" -extension "doc"
        File.doc

        .EXAMPLE
        PS> extension "File" "doc"
        File.doc

        .LINK
        Online version: http://www.fabrikam.com/extension.html

        .LINK
        Set-Item
    #>

Param
(
    [Parameter(Position = 0)]
    [bool] $bSingleSubscription = $false
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

try {
    $BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'
    $resourceGroupName = "rg-alerts"
    $BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'
    $templateUri = "$BaseDir\main-deployment\azuredeployment.json"
    $AlertRuleActionGroupName = "email_me"
    ##$templateFile ="$BaseDir\\main-deployment\azuredeployment.parameters.json"
    $myResourceGroupName = "rg-alerts"
    $emailAddress = "ancoughlin@microsoft.com"

    if ($bSingleSubscription -eq $false) {
        $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }
    }
    else {
        $SubscriptionId = Read-Host "Type the Subscription Id"
        $subscriptions = Get-AzSubscription -SubscriptionId $SubscriptionId
    }

    foreach ($subscription in $subscriptions) {
        Select-AzSubscription -SubscriptionID $subscription.Id
        Get-AzResourceGroup -Name $myResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
        if ($notPresent) {
            # ResourceGroup doesn't exist
            Write-Output "Creating Resource Group."
            $AzRegionName = Read-Host "Specify Azure Region Name (ex: centralus)"
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
        
        $targetsub = $subscription.Id
        New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -targetsub $targetsub -AlertRuleActionGroupName $AlertRuleActionGroupName -Verbose
    }
}
catch {
    Write-Output $_.Exception.Message
}

