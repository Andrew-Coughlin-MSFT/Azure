$BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'

$resourceGroupName = "rg-alerts"
$BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'
$templateUri = "$BaseDir\main-deployment\azuredeployment.json"
$templateFile ="$BaseDir\\main-deployment\azuredeployment.parameters.json"
#$location = "centralus"

New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri  -TemplateParameterFile $templateFile -Verbose