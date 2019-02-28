$licenseFile = "C:/license/license.xml"
if(Test-Path $licenseFile)
{
    Write-Host "Found license file. Copying it to folders"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/AutomationEngine/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/IndexWorker/App_Data"
}
else
{
    Write-Host "No license file found. Please put in a license.xml file in the /license folder"
    exit
}
C:\ServiceMonitor.exe w3svc