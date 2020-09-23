param (
 [Parameter(Mandatory=$true)]
 [string]$TenantName,
 
 [Parameter(Mandatory=$true)]
 [guid]$ClientId
)
 
$Certificate = Get-Item Cert:\CurrentUser\My\3678e6a33550c0d26bf3477beae718beab4e5022
$Scope = "https://graph.microsoft.com/.default"
 
#Create Base64 Hash of certificate 
$Certificatehash = [System.Convert]::ToBase64String($Certificate.GetCertHash())
 
#Create JWT timestamp for expiration
$StartDate = (Get-Date "1970-01-01T00:00:00Z").ToUniversalTime()
$JwtTimespan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
$JwtExpiration = [math]::Round($JwtTimespan,0)
 
# Create JWT validity start timestamp
$NotBeforeTimespan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime()).TotalSeconds
$NotBefore = [math]::Round($NotBeforeTimespan,0)
 
#Jwt header
$JwtHeader = @{
 alg = "RS256"
 typ = "JWT"
 x5t = $Certificatehash -replace '\+','-' -replace '/','_' -replace '='
}
 
$JwtPayload = @{
 aud = "https://login.microsoftonline.com/$TenantName/oauth2/token"
 exp = $JwtExpiration
 iss = $ClientId
 jti = New-Guid
 nbf = $NotBefore
 sub = $ClientId
}
 
# Convert header and payload to base64
$JwtHeaderToBytes = [System.Text.Encoding]::UTF8.GetBytes(($JwtHeader | ConvertTo-Json))
$EncodedHeader = [System.Convert]::ToBase64String($JwtHeaderToBytes)
 
$JWTPayLoadToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
$EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)
 
# Join header and Payload with "." to create a valid (unsigned) JWT
$JWT = $EncodedHeader + "." + $EncodedPayload
 
# Get the private key object of your certificate
$PrivateKey = $Certificate.PrivateKey
 
# Define RSA signature and hashing algorithm
$RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
$HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256
 
# Create a signature of the JWT
$Signature = [Convert]::ToBase64String(
 $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
) -replace '\+','-' -replace '/','_' -replace '='
 
# Join the signature to the JWT with "."
$JWT = $JWT + "." + $Signature
 
$Body = @{
 client_id = $ClientId
 client_assertion = $JWT
 client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
 scope = $Scope
 grant_type = "client_credentials" 
}
$Uri = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"
 
$Header = @{
 Authorization = "Bearer = $JWT"
}
 
$Post = @{
 #ContentType = 'application/x-www-form-urlencoded'
 Method = 'Post'
 Body = $Body
 Uri = $Uri
 Headers = $Header
}
$TokenResponse = Invoke-RestMethod @Post

$api = 'https://graph.microsoft.com/beta/users/mfauser2@ancoughl.onmicrosoft.com/authentication/phoneMethods'


$Users = Invoke-RestMethod -Method GET -Headers @{Authorization = "Bearer $($TokenResponse.access_token)"} -URi $api -ContentType 'application/json'