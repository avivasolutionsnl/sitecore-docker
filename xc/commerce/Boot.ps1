If ((Test-Path C:\Workspace) -eq $False) { 
    New-Item -Type Directory c:\Workspace  
}
/Scripts/UpdateHostname.ps1
/Scripts/WatchDefaultDirectories.ps1