$TenantId= "78dd488d-892f-4724-9861-9486288f62b8"
$ClientId = "5b178a17-7b59-4af6-a06d-f1af0a33b32a"
$ClientSecret = "3I._M6MASnbX~I~0oJK36-x42c7688ky_J"

param(
   [Parameter(Mandatory=$true)]
   [string]$TenantId,
   [Parameter(Mandatory=$true)]
   [string]$ClientId,
   [Parameter(Mandatory=$true)]
   [string]$ClientSecret

)
try {
        # Create a hashtable for the body, the data needed for the token request
        # The variables used are explained above
        $Body = @{
            'tenant' = $TenantId
            'client_id' = $ClientId
            'scope' = 'https://graph.microsoft.com/.default'
            'client_secret' = $ClientSecret
            'grant_type' = 'client_credentials'
        }

        # Assemble a hashtable for splatting parameters, for readability
        # The tenant id is used in the uri of the request as well as the body
        $Params = @{
            'Uri' = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
            'Method' = 'Post'
            'Body' = $Body
            'ContentType' = 'application/x-www-form-urlencoded'
        }

        $AuthResponse = Invoke-RestMethod @Params

        $Headers = @{
            'Authorization' = "Bearer $($AuthResponse.access_token)"
            'ConsistencyLevel' = 'eventual'
        }

        $Result = Invoke-RestMethod -Method GET -Uri 'https://graph.microsoft.com/v1.0/users?$filter=onPremisesSyncEnabled ne true and userType eq ''member''&$count=true' -Headers $Headers

        $CloudUsers = $Result.value

        while ($Result.'@odata.nextLink')
        {
        Write-Host "Getting another page of 100 users..."
            $Result = Invoke-RestMethod -Uri $Result.'@odata.nextLink' -Headers $Headers
            $CloudUsers += $Result.value
        }

        return $CloudUsers
}
catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName

    Write-Output "An error has occured:" $ErrorMessage  $FailedItem
}
