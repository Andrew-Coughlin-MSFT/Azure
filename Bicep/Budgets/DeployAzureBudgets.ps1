
param(
    [Parameter(Mandatory=$true)]
    [String]$tenantid
)


Connect-AzAccount -tenantid $tenantid

$subscriptions = Get-AzSubscription -TenantId $tenantid

foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.Id
    Set-AzContext -SubscriptionId $subscriptionId

    New-AzDeployment -name "AzureBudgets" -Location "Central US" -TemplateParameterFile .\AzureBudgets.bicepparam

}
Disconnect-AzAccount