<h1>Initiative Activity Log Alert Monitor for Network Security Groups </h1>

This initiative sets up the azure policies to deploy Azure Monitor Alerts for the following CIS 1.1.0 compliance in Azure Security Center:
* Ensure that Activity Log Alert exists for Create or Update Network Security Group
* Ensure that Activity Log Alert exists for Delete Network Security Group

<h1>Try on Portal</h1>



<h1>Try with Powershell</h1>

```Powershell
    $Scope = (Get-AzContext).Subscription.Id
```

<h1>Try with CLI</h1>

```cli
    az policy definition create --name
```