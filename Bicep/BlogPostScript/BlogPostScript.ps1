$Url = "https://techcommunity.microsoft.com/plugins/custom/microsoft/o365/custom-blog-rss?tid=-2649243005794744624&board=AzureArchitectureBlog&size=25"

$Response = Invoke-RestMethod -Uri $url -UseBasicParsing -ContentType "application/xml"
If ($Response.StatusCode -ne "200") {
    # Feed failed to respond.
    Write-Host "Message: $($Response.StatusCode) $($Response.StatusDescription)"
}


$FeedXml = [xml]$Response.Content
$Entries = @()
$Now = Get-Date

ForEach ($Entry in $FeedXml.feed.entry) {

    If (($Now - [datetime]$Entry.updated).TotalHours -le 24) {

        $Entries += [PSCustomObject] @{
            'Id' = "status.digitalocean.com - " + ($Entry.id).Remove(0, 24)
            'Updated' = [datetime]$Entry.updated
            'Title' = $Entry.title
            'Content' = $Entry.content.'#text'
        }
    }
}


Foreach ($Entry in $Response)
{
    
}

Function IsBetweenDates2([Datetime]$start,[Datetime]$end, [DateTime]$ComparedDate)
{
	$d = $ComparedDate
	if (($d -ge $start.ToDateTime()) -and ($d -le $end.ToDateTime()))
	{
		return $true
	}
	else
	{
		return $false
	}
}

$startDate = (Get-Date).AddDays(-4)
$endDate = (Get-Date).AddDays(3)
$today = Get-Date

IsBetweenDates2($startDate,$endDate,$today)