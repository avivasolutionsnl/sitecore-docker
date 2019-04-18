param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname,
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname
)

If ((Test-Path C:\Workspace) -eq $False) { 
    New-Item -Type Directory c:\Workspace  
}
/Scripts/UpdateHostname.ps1 -commerceHostname $commerceHostname -sitecoreHostname $sitecoreHostname
/Scripts/WatchDefaultDirectories.ps1