$BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'
$Params = @{
    Name                  = 'ActivityMonitorAlerts'
    Location              = 'centralus'
    TemplateParameterFile = "$BaseDir\main-deployment\azuredeployment.json"
    TemplateFile          = "$BaseDir\\main-deployment\azuredeployment.parameters.json"
}
##New-AzManagementGroupDeployment @Params -Verbose
New-AzDeployment @Params -Verbose