<h1>Initiative Activity Log Alert Monitor for Network Security Groups </h1>

This initiative sets up the azure policies to deploy Azure Monitor Alerts for the following CIS 1.1.0 compliance in Azure Security Center:
* Ensure that Activity Log Alert exists for Create or Update Network Security Group
* Ensure that Activity Log Alert exists for Delete Network Security Group

<h1>Try on Portal</h1>

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrew-Coughlin-MSFT%2FAzure%2Fmaster%2FAzurePolicyExports%2FMonitoring%2Finitiative-activity-log-alert-monitor-network-security-group%2Fpolicyset.json)

<h1>Try with Powershell</h1>

```Powershell
    
    $Scope = (Get-AzContext).Subscription.Id

```

<h1>Try with CLI</h1>