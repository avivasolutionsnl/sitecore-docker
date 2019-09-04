param(
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname,
    [Parameter(Mandatory=$true)]
    [String]$identityHostname
)

$licenseFile = "C:/license/license.xml"
if(Test-Path $licenseFile)
{
    Write-Host "Found license file"
}
else
{
    Write-Host "No license file found. Please put in a license.xml file in the /license folder"
    exit
}

/Scripts/UpdateHostname.ps1 -sitecoreHostname $sitecoreHostname -identityHostname $identityHostname

while($true)
{   
    Sleep -Milliseconds 500
}