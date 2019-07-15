param(
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname,
    [Parameter(Mandatory=$true)]
    [String]$identityHostname
)

/Scripts/UpdateHostname.ps1 -sitecoreHostname $sitecoreHostname -identityHostname $identityHostname