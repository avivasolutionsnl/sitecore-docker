param(
    [Parameter(Mandatory=$true)]
    [String]$hostname
)

If ((Test-Path C:\Workspace) -eq $False) { 
    New-Item -Type Directory c:\Workspace  
}
/Scripts/UpdateHostname.ps1 -commerceHostname $hostname
/Scripts/WatchDefaultDirectories.ps1