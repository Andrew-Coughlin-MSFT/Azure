$BaseDir = 'C:\GitHub\Azure\Azure.Policy'
$Params = @{
    Name                  = 'ActionGroupsPolicy'
    ManagementGroupId     = '6f34bc28-ce0e-4936-a836-9730a5929bf7'
    Location              = 'centralus'
    TemplateParameterFile = "$BaseDir\main-deployment\linkedtemplate.paramters.json"
    TemplateFile          = "$BaseDir\main-deployment\azuredeployment.json"
}
New-AzManagementGroupDeployment @Params -Verbose