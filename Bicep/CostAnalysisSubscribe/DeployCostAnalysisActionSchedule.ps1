
param(
    [Parameter(Mandatory=$true)]
    [String]$tenantid,

    [Parameter(Mandatory=$true)]
    [String]$resourceGroupName,

    [Parameter(Mandatory=$true)]
    [String]$scheduleActionName,

    [Parameter(Mandatory=$true)]
    [bool]$IsPrivate = $false,

    [Parameter(Mandatory=$true)]
    [string]$scheduleActionRecipients

)

Connect-AzAccount -tenantid $tenantid

$subscriptions = Get-AzSubscription -TenantId $tenantid

foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    Set-AzContext -SubscriptionId $subscriptionId

    $resourceGroups = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($resourceGroups) {
        Write-Host "Resource group '$ResourceGroupName' already exists."
        New-AzResourceGroupDeployment -Name VMCostScheduleActionDeploy -TemplateFile .\CostAnalysisSubscribeAction.bicep -ResourceGroupName $resourceGroupName -ScheduleActionName $scheduleActionName -ScheduleActionDisplayName $scheduleActionName -IsPrivate $IsPrivate -scheduleActionRecipients $scheduleActionRecipients
    }
    else {
    
        Write-Host "Resource group '$ResourceGroupName'... not created yet."
        Exit
    }


}