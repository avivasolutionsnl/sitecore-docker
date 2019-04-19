$licenseFile = "C:/license/license.xml"
if(Test-Path $licenseFile)
{
    Write-Host "Found license file. Copying it to folders"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/AutomationEngine/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/IndexWorker/App_Data"
    Write-Host "Succesfully copied license file!" -ForegroundColor Green

    Write-Host "Starting the xconnect services"
    Start-Service "xconnect-IndexWorker"
    Start-Service "xconnect-MarketingAutomationService"
    Write-Host "Succesfully started the xconnect services" -ForegroundColor Green
}
else
{
    Write-Host "No license file found. Please put in a license.xml file in the /license folder. The container will now exit." -ForegroundColor Red
    exit
}
C:\ServiceMonitor.exe w3svc