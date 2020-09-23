$TenantName = "ancoughl.onmicrosoft.com"
$OutDirectory = "C:\temp\Certificates\SelfSigned\PowershellGraphCert.cer"
$CertStore = "Cert:\CurrentUser\My"
$ExpireDate = (Get-Date).AddYears(2)
 
$CertData = @{
 FriendlyName = "GraphApi.Application"
 DNSName = "$TenantName"
 CertStoreLocation = $CertStore
 NotAfter = $ExpireDate
 KeyExportPolicy = "Exportable"
 KeySpec = "Signature"
 Provider = "Microsoft Enhanced RSA and AES Cryptographic Provider"
 HashAlgorithm = "SHA256"
}
 
$Certificate = New-SelfSignedCertificate @CertData
 
# Get certificate path
$CertificatePath = Join-Path -Path $CertStore -ChildPath $Certificate.Thumbprint
 
# Export certificate without private key
Export-Certificate -Cert $CertificatePath -FilePath $OutDirectory | Out-Null