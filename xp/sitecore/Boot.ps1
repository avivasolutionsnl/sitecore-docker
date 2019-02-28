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
./Scripts/Watch-Directory.ps1 -Path C:\Workspace -Destination c:\inetpub\wwwroot\sitecore