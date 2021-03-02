<h1>Initiative Activity Log Alert Monitor for Network Security Groups </h1>

This initiative sets up the azure policies to deploy Azure Monitor Alerts for the following CIS 1.1.0 compliance in Azure Security Center:
* Ensure that Activity Log Alert exists for Create or Update Network Security Group
* Ensure that Activity Log Alert exists for Delete Network Security Group

<h1>Try on Portal</h1>

Not supported At this time

<h1>Try with Powershell</h1>

```Powershell
    $policydefinitions = "https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/AzurePolicyExports/Monitoring/initiative-activity-log-alert-monitor-network-security-group/azurepolicyset.definitions.json"
    $policysetparameters = "https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/AzurePolicyExports/Monitoring/initiative-activity-log-alert-monitor-network-security-group/azurepolicyset.parameters.json"

    $policyset= New-AzPolicySetDefinition -Name "Activity-log-alert-nsg" -DisplayName "Activity Log Alert Monitor Network Security Group Policy Initiative" -Description "Initiative to define Network Security Group Alert rules for creation or updates" -PolicyDefinition $policydefinitions -Parameter $policysetparameters 
```

<h1>Try with CLI</h1>

```cli
    CLI for policy set is not supported yet
```