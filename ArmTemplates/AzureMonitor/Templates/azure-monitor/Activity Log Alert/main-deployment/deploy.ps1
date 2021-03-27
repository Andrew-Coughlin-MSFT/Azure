$BaseDir = 'C:\Azure\Azure\ArmTemplates\AzureMonitor\Templates\azure-monitor\Activity Log Alert\'
$Params = @{
    Name                  = 'ActivityMonitorAlerts'
    Location              = 'centralus'
    Subscription          = 'bde5ac7d-d5cc-4e8a-ae6c-73788d8a7af5'
    activityLogAlertName  = ''
    TemplateParameterFile = "$BaseDir\main-deployment\azuredeployment.json"
    TemplateFile          = "$BaseDir\\main-deployment\azuredeployment.parameters.json"
}
New-AzManagementGroupDeployment @Params -Verbose