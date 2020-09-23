#Import-Module "C:\Users\ancoughl\Downloads\AzureADAuthenticationMethods\AzureADAuthenticationMethods.psm1"

$TenantId= "fb650217-ff77-4479-a108-6a8a1aa9f190"
$ClientId = "d8c38dc5-2773-40a8-be5e-367408277420"
$ClientSecret = "3~8L7lvke_TNi.RW-__6DWNq~uG.dvdV7."

$Credential = Get-Credential

$Body = @{
    'tenant' = $TenantId
    'client_id' = $ClientId
    'scope' = 'https://graph.microsoft.com/.default'
    'client_secret' = $ClientSecret
    'grant_type' = 'password'
    #'grant_type' ='client_credentials'
    'username'=$Credential.UserName
    'password'= ConvertFrom-SecureString -SecureString $Credential.Password -AsPlainText
}

$Header = @{
    'Authorization' = "Bearer $($AuthResponse.access_token)"
}

# Assemble a hashtable for splatting parameters, for readability
# The tenant id is used in the uri of the request as well as the body
$Post = @{
    'Uri' = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    'Method' = 'Post'
    'Body' = $Body
    'Headers' = $Header
}

$AuthResponse = Invoke-RestMethod @Post

$api = 'https://graph.microsoft.com/beta/users/mfauser2@ancoughl.onmicrosoft.com/authentication/phoneMethods'


$Users = Invoke-RestMethod -Method GET -Headers @{Authorization = "Bearer $($AuthResponse.access_token)"} -URi $api -ContentType 'application/json'

