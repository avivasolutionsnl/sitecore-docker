param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname
)

/Scripts/UpdateHostname.ps1 -commerceHostname $commerceHostname

If ((Test-Path C:\Workspace) -eq $False) { 
    New-Item -Type Directory c:\Workspace  
}
/Scripts/Watch-Directory.ps1 -Path C:\Workspace -Destination c:\inetpub\wwwroot\sitecore