param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname
)

/Scripts/UpdateCommerceHostname.ps1 -commerceHostname $commerceHostname

while($true)
{   
    Sleep -Milliseconds 500
}