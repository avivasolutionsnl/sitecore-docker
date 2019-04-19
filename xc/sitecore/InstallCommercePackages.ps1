Param(
    $certificateFile = 'c:\\Files\\commerce.pfx',
    $shopsServiceUrl = 'https://commerce.local:5000/api/',
    $commerceOpsServiceUrl = 'https://commerce.local:5000/commerceops/',
    $identityServerUrl = 'https://commerce.local:5050/',
    $defaultEnvironment = 'HabitatShops',
    $defaultShopName = 'CommerceEngineDefaultStorefront',
    $sitecoreUserName = 'sitecore\admin',
    $sitecorePassword = 'b',
    $sitecoreUrl = "http://sitecore"
)

Function GetIdServerToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$userName,
        [Parameter(Mandatory = $true)]
        [string]$password,
        [Parameter(Mandatory = $true)]
        [string]$urlIdentityServerGetToken
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", 'application/x-www-form-urlencoded')
    $headers.Add("Accept", 'application/json')

    $body = @{
        password   = $password
        grant_type = 'password'
        username   = $userName
        client_id  = 'postman-api'
        scope      = 'openid EngineAPI postman_api'
    }

    Write-Host "Get Token From Sitecore.IdentityServer" -ForegroundColor Green
    $response = Invoke-RestMethod $urlIdentityServerGetToken -Method Post -Body $body -Headers $headers

    return "Bearer {0}" -f $response.access_token
}

Function BootStrapCommerceServices {
    param(
        [Parameter(Mandatory = $true)]
        [string]$urlCommerceShopsServicesBootstrap,
        [Parameter(Mandatory = $true)]
        [string]$bearerToken
    )

    Write-Host "BootStrapping Commerce Services: $($urlCommerceShopsServicesBootstrap)" -ForegroundColor Yellow
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $bearerToken)
    Invoke-RestMethod $urlCommerceShopsServicesBootstrap -TimeoutSec 1200 -Method PUT -Headers $headers
    Write-Host "Commerce Services BootStrapping completed" -ForegroundColor Green
}

Function InitializeCommerceServices {
    param(
        [Parameter(Mandatory = $true)]
        [string]$urlCommerceShopsServicesInitializeEnvironment,
        [Parameter(Mandatory = $true)]
        [string]$bearerToken
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $bearerToken);
    Write-Host "Initializing Shops: $($urlCommerceShopsServicesInitializeEnvironment)" -ForegroundColor Yellow

    Invoke-RestMethod $urlCommerceShopsServicesInitializeEnvironment -TimeoutSec 1200 -Method PUT -Headers $headers

    Write-Host "Shops initialization complete..." -ForegroundColor Green 
}

[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules');

Copy-Item -Path /Files/CommerceSIF/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore\\SiteUtilityPages -Force -Recurse

# Enlarge timeout to 7200 seconds
((Get-Content -path C:/Files/CommerceSIF/Modules/SitecoreUtilityTasks/SitecoreUtilityTasks.psm1 -Raw) -replace '720','7200') | Set-Content -Path C:/Files/CommerceSIF/Modules/SitecoreUtilityTasks/SitecoreUtilityTasks.psm1

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/Connect/Connect.json' `
     -ModuleFullPath '/Files/SitecoreCommerceConnectCore/package.zip' `
     -ModulesDirDst c:\\inetpub\wwwroot\\sitecore\\App_Data\\packages `
     -BaseUrl "$sitecoreUrl/SiteUtilityPages"

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/Connect/Connect_xProfiles.json' `
     -ModuleFullPath '/Files/CommerceXProfiles/package.zip' `
     -ModulesDirDst c:\\inetpub\wwwroot\\sitecore\\App_Data\\packages `
     -BaseUrl "$sitecoreUrl/SiteUtilityPages"

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/Connect/Connect_xAnalytics.json' `
    -ModuleFullPath '/Files/CommerceXAnalytics/package.zip' `
    -ModulesDirDst c:\\inetpub\wwwroot\\sitecore\\App_Data\\packages `
    -BaseUrl "$sitecoreUrl/SiteUtilityPages"

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/Connect/Connect_MarketingAutomation.json' `
    -ModuleFullPath '/Files/CommerceMACore/package.zip' `
    -ModulesDirDst c:\\inetpub\wwwroot\\sitecore\\App_Data\\packages `
    -BaseUrl "$sitecoreUrl/SiteUtilityPages" `
    -AutomationEngineModule 'none' `
    -XConnectSitePath 'none' `
    -Skip 'InstallAutomationEngineModule' # Automation Engine is installed in XConnect

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/CEConnect/CEConnect.json' `
    -PackageFullPath /Files/Sitecore.Commerce.Engine.Connect.update `
    -PackagesDirDst c:\\inetpub\wwwroot\\sitecore\\sitecore\\admin\\Packages `
    -BaseUrl "$sitecoreUrl/SiteUtilityPages" `
    -MergeTool '/Files/Microsoft.Web.XmlTransform.dll' `
    -InputFile c:\\inetpub\\wwwroot\\sitecore\\MergeFiles\\Sitecore.Commerce.Engine.Connectors.Merge.Config `
    -WebConfig c:\\inetpub\\wwwroot\\sitecore\\web.config

# Modify the commerce engine connection
$engineConnectIncludeDir = 'c:\\inetpub\\wwwroot\\sitecore\\App_Config\\Include\\Y.Commerce.Engine'; `
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; `
$cert.Import($certificateFile, 'secret', 'MachineKeySet'); `
$pathToConfig = $(Join-Path -Path $engineConnectIncludeDir -ChildPath "\Sitecore.Commerce.Engine.Connect.config"); `
$xml = [xml](Get-Content $pathToConfig); `
$node = $xml.configuration.sitecore.commerceEngineConfiguration; `
$node.certificateThumbprint = $cert.Thumbprint; `
$node.shopsServiceUrl = $shopsServiceUrl; `
$node.commerceOpsServiceUrl = $commerceOpsServiceUrl; `
$node.defaultEnvironment = $defaultEnvironment; `
$node.defaultShopName = $defaultShopName; `
$xml.Save($pathToConfig);

# Initialize the commerce engine
$bearerToken = GetIdServerToken -userName $sitecoreUserName -password $sitecorePassword -urlIdentityServerGetToken "${identityServerUrl}connect/token"

BootStrapCommerceServices -urlCommerceShopsServicesBootstrap "${commerceOpsServiceUrl}Bootstrap()" -bearerToken $bearerToken
InitializeCommerceServices -urlCommerceShopsServicesInitializeEnvironment "${commerceOpsServiceUrl}InitializeEnvironment(environment='$defaultEnvironment')" -bearerToken $bearerToken

$commerceConfigFolder = 'C:\inetpub\wwwroot\sitecore\App_Config\Include\Y.Commerce.Engine'
Rename-Item $commerceConfigFolder\Sitecore.Commerce.Engine.DataProvider.config.disabled $commerceConfigFolder\Sitecore.Commerce.Engine.DataProvider.config
Rename-Item $commerceConfigFolder\Sitecore.Commerce.Engine.Connectors.Index.Common.config.disabled $commerceConfigFolder\Sitecore.Commerce.Engine.Connectors.Index.Common.config
Rename-Item $commerceConfigFolder\Sitecore.Commerce.Engine.Connectors.Index.Solr.config.disabled $commerceConfigFolder\Sitecore.Commerce.Engine.Connectors.Index.Solr.config
