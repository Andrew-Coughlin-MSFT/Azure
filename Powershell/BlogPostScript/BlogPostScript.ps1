
function Write-ProgressHelper {
    param(
        [int]$StepNumber,
        [string]$Message,
        [int]$steps
    )
    
    Write-Progress -Activity 'Completion Status' -Status $Message -PercentComplete (($StepNumber / $steps) * 100)
}

 Function ConvertFrom-Html
 {
     <#
         .SYNOPSIS
             Converts a HTML-String to plaintext.

         .DESCRIPTION
             Creates a HtmlObject Com object und uses innerText to get plaintext. 
             If that makes an error it replaces several HTML-SpecialChar-Placeholders and removes all <>-Tags via RegEx.

         .INPUTS
             String. HTML als String

         .OUTPUTS
             String. HTML-Text als Plaintext

         .EXAMPLE
         $html = "<p><strong>Nutzen:</strong></p><p>Der&nbsp;Nutzen ist &uuml;beraus gro&szlig;.<br />Test ob 3 &lt; als 5 &amp; &quot;4&quot; &gt; &apos;2&apos; it?"
         ConvertFrom-Html -Html $html
         $html | ConvertFrom-Html

         Result:
         "Nutzen:
         Der Nutzen ist überaus groß.
         Test ob 3 < als 5 ist & "4" > '2'?"


#         .Notes
#             Author: Ludwig Fichtinger FILU
#             Inital Creation Date: 01.06.2021
#             ChangeLog: v2 20.08.2021 try catch with replace for systems without Internet Explorer

     #>

     [CmdletBinding(SupportsShouldProcess = $True)]
     Param(
         [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "HTML als String")]
         [AllowEmptyString()]
         [string]$Html
     )

     try
     {
         $HtmlObject = New-Object -Com "HTMLFile"
         $HtmlObject.IHTMLDocument2_write($Html)
         $PlainText = $HtmlObject.documentElement.innerText
     }
     catch
     {
         $nl = [System.Environment]::NewLine
         $PlainText = $Html -replace '<br>',$nl
         $PlainText = $PlainText -replace '<br/>',$nl
         $PlainText = $PlainText -replace '<br />',$nl
         $PlainText = $PlainText -replace '</p>',$nl
         $PlainText = $PlainText -replace '&nbsp;',' '
         $PlainText = $PlainText -replace '&Auml;','Ä'
         $PlainText = $PlainText -replace '&auml;','ä'
         $PlainText = $PlainText -replace '&Ouml;','Ö'
         $PlainText = $PlainText -replace '&ouml;','ö'
         $PlainText = $PlainText -replace '&Uuml;','Ü'
         $PlainText = $PlainText -replace '&uuml;','ü'
         $PlainText = $PlainText -replace '&szlig;','ß'
         $PlainText = $PlainText -replace '&amp;','&'
         $PlainText = $PlainText -replace '&quot;','"'
         $PlainText = $PlainText -replace '&apos;',"'"
         $PlainText = $PlainText -replace '<.*?>',''
         $PlainText = $PlainText -replace '&gt;','>'
         $PlainText = $PlainText -replace '&lt;','<'
     }

     return $PlainText
 }

$Urls = Get-Content -Path (Read-Host -Prompt 'Get path')
$iCount = 0
$now = Get-Date
[string]$strOutput ="<html><body>"
foreach ($url in $Urls){
    Write-ProgressHelper -StepNumber $iCount -Message "Working on $($url)" -Steps $urls.Count
    $Responses = Invoke-RestMethod -Uri $url -UseBasicParsing -ContentType "application/xml"
    If ($Responses.Count -gt 0) {
        Write-Host "Collected posts: " $($Responses.Count) $($url)
        #set counter to determine if the blog header needs to be added to file.
        [int]$icountposts=0
            ForEach ($post in $Responses) {
                $postdate = $post.pubDate.Remove($post.pubDate.LastIndexOf(" "))
                If (($now - [datetime]$postdate).TotalHours -le 144) {
                    #Blog site has new content posted in the last week   
                    if ($icountposts -eq 0)
                    {
                        #Check if this is the first post for the blog, add the area to the top. 
                        try{
                            $Blogsite = $url.Split("=")
                            $strOutput = $strOutput + "<h1>"+$Blogsite[2].remove($Blogsite[2].IndexOf("&"))+" Blogs:`r`n</h1>"
                        }
                        catch {
                            #Azure Update RSS feed is formated differently, handle that condition.
                            $strOutput = $strOutput + "Azure Updates:`r`n"
                        }
                    }              
                    $description = $post.description | ConvertFrom-Html
                    $description = $description.replace("`n",", ").replace("`r",", ")
                    $description = $description.replace(",","")
                    $strOutput = $strOutput +"<h2>"+$post.title.ToString()+"</h2>"+"`r`n"+"<p>"+[datetime]$postdate.ToString()+"</p>"+"`r`n"+"<p>"+$description.Remove($description.IndexOf(".")+1)+"</p>"+"<p>&nbsp;</p>"+"<p><a href="+$post.link.ToString()+">"+$post.title.ToString() +"</a></p>"+"<p>&nbsp;&nbsp;</p>"
                    $icountposts++
                }
            }
    $iCount++
        }
    else {
        Write-Host "Collected posts: 0 on $($url)"
    } 
}
$strOutput = $strOutput + "</body></html>"
$strOutput | Out-File .\blogs.htm
