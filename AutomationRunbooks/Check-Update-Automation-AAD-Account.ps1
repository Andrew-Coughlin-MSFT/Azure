param(
    [Parameter (Mandatory=$true)]
    [string] $SubscriptionID,
    [Parameter (Mandatory=$true)]
    [string] $UPN,
    [Parameter (Mandatory=$true)]
    [string] $KeyvaultName,
    [Parameter (Mandatory=$true)]
    [string] $AutomationAccountName,
    [Parameter (Mandatory=$true)]
    [string] $AutomationAccountRG
)

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}

function Login-Azure($subscription,$AutomationCredName)
{
    "Logging in to Azure AD..."
    $credObject = Get-AutomationPSCredential -Name $AutomationCredName
    Connect-MsolService -Credential $credObject
    Connect-AzAccount -Credential $credObject
    Select-AzSubscription -SubscriptionId $subscription
}

function Set-AzureAutomationCreds ($credname, $username, [securestring]$password){
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password
    Set-AzAutomationCredential -AutomationAccountName $AutomationAccountName -Name $credname -ResourceGroupName $AutomationAccountRG -Value $Credential
}
 
function Scramble-String([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

function GenerateRandomPassword{
    $returnpwd = ""
    $password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 2 -characters '1234567890'
    $password += Get-RandomCharacters -length 3 -characters '!$%&()=?{@#*+'
    $returnpwd =  Scramble-String $password
    return $returnpwd
}

function SetAzureKeyvaultSecret([string]$KeyVaultName, [string]$SecretName, [securestring]$SecretPassword){
    $Expires = (Get-Date).AddDays(30).ToUniversalTime()
    $NBF =(Get-Date).ToUniversalTime()
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $Secret -Expires $Expires -NotBefore $NBF
}

###############Variables#############
#Change these before running
[int]$PasswordLastChangedInDays = -29 #Password should be changed every X days, make sure to have a minus infront of the number.
[string]$AutomationCredName = "aacount" #This is the name of the credential that is stored in the automation account.
######################################

try{
    Login-Azure $SubscriptionID $AutomationCredName

    $DateChange = Get-MSolUser -UserPrincipalName $UPN | select LastPasswordChangeTimeStamp

    If ($DateChange.LastPasswordChangeTimestamp -gt (Get-Date).AddDays($PasswordLastChangedInDays))
    {
        Write-Output "Password is not older than 30 days: " $DateChange.LastPasswordChangeTimestamp
    }
    else
    {
        Write-Output "Password is older than 30 days: " $DateChange.LastPasswordChangeTimestamp
        $stringPwd = GenerateRandomPassword
       
        $Secret = ConvertTo-SecureString -String $stringPwd -AsPlainText -Force
        Write-Output "Set Automation Credentials"
        $AACredResults = Set-AzureAutomationCreds $UPN.Substring(0, $UPN.IndexOf('@')) $UPN $Secret
        Write-Output "Settings Password in Azure AD for: " $UPN
        $ADUserResults = Set-MsolUserPassword -UserPrincipalName $UPN -NewPassword $stringPwd -ForceChangePassword $false

        Login-Azure $SubscriptionID $AutomationCredName
        Write-Output "Password set."
        $kvResults = SetAzureKeyvaultSecret $KeyvaultName $UPN.Substring(0, $UPN.IndexOf('@')) $Secret
        Write-Output "Secret Stored in Kevault: " $KeyvaultName
    }
}
catch
{
    Write-Error -Message $_.Exception
    throw $_.Exception
}
finally
{
    disconnect-azaccount 
}


