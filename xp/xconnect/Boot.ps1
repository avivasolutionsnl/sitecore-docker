param(
    [String]$licenseFile = "C:/license/license.xml",
    [String]$xconnectUrl = "https://xconnect"
)

if(Test-Path $licenseFile)
{
    Write-Host "Found license file. Copying it to folders"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/AutomationEngine/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/IndexWorker/App_Data"
    Copy-Item -Path $licenseFile -Destination "C:/inetpub/wwwroot/xconnect/App_Data/jobs/continuous/ProcessingEngine/App_Data"
    Write-Host "Succesfully copied license file!" -ForegroundColor Green

    # Warm-up xconnect to prevent errors during start of service workers
    Invoke-WebRequest $xconnectUrl -UseBasicParsing

    Write-Host "Starting the xconnect services"
    try { # Starting a service should not result in an exiting container
        Start-Service "xconnect-IndexWorker"
        Start-Service "xconnect-MarketingAutomationService"
        Start-Service "xconnect-ProcessingEngineService"
        Write-Host "Succesfully started the xconnect services" -ForegroundColor Green
    } catch {
        Write-Host "Failed to start all services"
    }
}
else
{
    Write-Host "No license file found. Please put in a license.xml file in the /license folder. The container will now exit." -ForegroundColor Red
    exit
}
C:\ServiceMonitor.exe w3svc