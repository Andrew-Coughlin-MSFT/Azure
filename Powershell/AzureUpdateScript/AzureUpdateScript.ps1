Function TitleCheckContent($Title) {
    $checkTitle = $Title
    if ($checkTitle -match "General availability:"){
        $NewTitle = $Title -replace "General availability:", "Generally Available:"
    }
    elseif (($checkTitle -match "Generally Available") -and ($checkTitle -notmatch "Generally Available:"))
    {
        $NewTitle = "Generally Available:$checkTitle"
    }
    elseif ($checkTitle -like "*Public Preview:*"){
        $NewTitle = $checkTitle
    }
    else {    
        if ($checkTitle -like "*GA:*"){
            $NewTitle = $Title -replace "GA:", "Generally Available:"
        }
        elseif (($checkTitle -like "*Generally availability*") -or ($checkTitle -like "*???General availability*") -or ($checkTitle -like "*General Availability*")){
            $NewTitle = "Generally Available:$checkTitle"
        }
        elseif (($checkTitle -like "*???Public Preview*") -or ($checkTitle -like "*Public Preview*")){
            $NewTitle = "Public Preview:$checkTitle"
        }
        elseif ($checkTitle -like "*Deprecation*"){
            $NewTitle = "Retirement Update:$checkTitle" 
        }
        elseif ($checkTitle -like "*Retirement*"){
            $NewTitle = "Retirement Update:$checkTitle" 
        }
        elseif (($checkTitle -like "*end of life*") -or ($checkTitle -like "*end*")){
            $NewTitle = "Retirement Update:$checkTitle" 
        }
        elseif ($checkTitle -like "*:*")
        {
            $NewTitle = $checkTitle
        }
        else {
            $NewTitle = "Generally Available:$checkTitle"
        }
    }
    return $NewTitle.trim()

}

$RssContent = Invoke-WebRequest -Uri 'https://azurecomcdn.azureedge.net/en-us/updates/feed/'

[xml]$Content = $RssContent

$Updates = @()
$Feed = $Content.rss.channel

  ForEach ($msg in $Feed.Item){
    $CheckedTitle =""
    $ParseData = ""
    Write-Host 
    $CheckedTitle = TitleCheckContent $msg.title
    $ParseData= (($CheckedTitle).split(':')).trim()
    $UpdateObj = New-Object PSObject
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name "LastUpdated" -Value $([datetime]$msg.pubDate)
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name "Description" -Value $($msg.description) 
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name "Title" -Value $($ParseData[1])
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name "AnnoucementsLink" -Value $($msg.link)
    #saves the properties in an array that exists outside of the loop to preserve information beyond one interation
    $Updates += $UpdateObj
   }#EndForEach



$WebResponse = Invoke-WebRequest "https://azure.microsoft.com/en-us/updates/ga-create-disks-from-cmkencrypted-snapshots-across-subscriptions-and-in-the-same-tenant/"
$WebResponse

$jsonObj = ConvertFrom-Json $([String]::new($WebResponse.Content))


$response = Invoke-WebRequest -Uri "https://azure.microsoft.com/en-us/updates/ga-create-disks-from-cmkencrypted-snapshots-across-subscriptions-and-in-the-same-tenant/"
$jsonObj = ConvertFrom-Json $([String]::new($response.Content))