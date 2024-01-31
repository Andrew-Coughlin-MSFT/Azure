# Deployment Options
The below sectionals provide examples of how this can be deployed - please note, when utilising the "Deploy to Azure" button, some properties are ignored by the portal (e.g. non-compliance message). This will need to be manually filled. 

## Deploy via Portal
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_Policy/CreatePolicyDefinitionBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-policy%2Fmaster%2Fsamples%2FNetwork%2Faddress-space-must-be-pre-allocated-for-region%2Fazurepolicy.json)

## Deploy via PowerShell
```PowerShell
$definition = New-AzPolicyDefinition -Name "Deny, Audit, Disable of Machine Learning worksapces." -DisplayName "Deny, Audit, Disable of Machine Learning worksapces." -Policy 'https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/Policy/MachineLearning/azurepolicy.rules.json' -Parameter 'https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/Policy/MachineLearning/azurepolicy.parameters.json' -Mode All
$assignment = New-AzPolicyAssignment -Name <assignmentname> -Scope <scope> -PolicyDefinition $definition
```
## Deploy via Az CLI
````cli

az policy definition create --name 'Address space must be pre-allocated for region' --display-name 'VNETs should abide by regional IPAM allocations' --description 'Deny, Audit, Disable of Machine Learning worksapces." --rules 'https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/Policy/MachineLearning/azurepolicy.rules.json' --params 'https://raw.githubusercontent.com/Andrew-Coughlin-MSFT/Azure/master/Policy/MachineLearning/azurepolicy.parameters.json' --mode Indexed

az policy assignment create --name <assignmentname> --scope <scope> --policy "Address space must be pre-allocated for region" 