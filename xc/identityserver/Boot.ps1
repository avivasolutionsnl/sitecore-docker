param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname,
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname,
    [Parameter(Mandatory=$true)]
    [String]$identityHostname
)

/Scripts/UpdateHostname.ps1 -sitecoreHostname $sitecoreHostname -identityHostname $identityHostname
/Scripts/UpdateCommerceHostname.ps1 -commerceHostname $commerceHostname 

while($true)
{   
    Sleep -Milliseconds 500
}