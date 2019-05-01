param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname,
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname,
    [Parameter(Mandatory=$true)]
    [String]$identityServerHostname
)

If ((Test-Path C:\Workspace) -eq $False) { 
    New-Item -Type Directory c:\Workspace  
}
/Scripts/UpdateHostname.ps1 -commerceHostname $commerceHostname -sitecoreHostname $sitecoreHostname -identityServerHostname $identityServerHostname
/Scripts/WatchDefaultDirectories.ps1