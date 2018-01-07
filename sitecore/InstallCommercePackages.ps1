[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules');

Expand-Archive -Path '/Files/SIF.Sitecore.Commerce.1.0.1626.zip' -DestinationPath /Files/CommerceSIF -Force

Copy-Item -Path /Files/CommerceSIF/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore\\SiteUtilityPages -Force -Recurse

Expand-Archive -Path '/Files/Sitecore Commerce Connect Core 11.0.106.zip' -DestinationPath '/Files/Sitecore Commerce Connect Core' -Force

Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/Connect/Connect.json' `
    -ModuleFullPath '/Files/Sitecore Commerce Connect Core/package.zip' `
    -ModulesDirDst c:\\inetpub\wwwroot\\sitecore\\App_Data\\packages `
    -BaseUrl 'http://sitecore/SiteUtilityPages'
   
Expand-Archive -Path '/Files/Sitecore.Commerce.Deployment.HelperTools.1.0.1.zip' -DestinationPath /Files/Sitecore.Commerce.Deployment.HelperTools -Force
    
Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/CEConnect/CEConnect.json' `
    -PackageFullPath /Files/Sitecore.Commerce.Engine.Connect.2.0.497.update `
    -PackagesDirDst c:\\inetpub\wwwroot\\sitecore\\sitecore\\admin\\Packages `
    -BaseUrl 'http://sitecore/SiteUtilityPages' `
    -MergeTool '/Files/Sitecore.Commerce.Deployment.HelperTools/CSSiteCoreWebConfigMerger.exe' `
    -InputFile c:\\inetpub\\wwwroot\\sitecore\\MergeFiles\\Sitecore.Commerce.Engine.Connectors.Merge.Config `
    -WebConfig c:\\inetpub\\wwwroot\\sitecore\\web.config

# Modify the commerce engine connection
$engineConnectIncludeDir = 'c:\\inetpub\\wwwroot\\sitecore\\App_Config\\Include\\Y.Commerce.Engine'; `
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; `
$cert.Import('c:\\Files\\commerce.pfx', 'secret', 'MachineKeySet'); `
$pathToConfig = $(Join-Path -Path $engineConnectIncludeDir -ChildPath "\Sitecore.Commerce.Engine.config"); `
$xml = [xml](Get-Content $pathToConfig); `
$node = $xml.configuration.sitecore.commerceEngineConfiguration; `
$node.certificateThumbprint = $cert.Thumbprint; `
$xml.Save($pathToConfig); `
$pathToConfig = $(Join-Path -Path $engineConnectIncludeDir -ChildPath "\Sitecore.Commerce.Engine.DataProvider.config.disabled"); `
$xml = [xml](Get-Content $pathToConfig); `
$node = $xml.configuration.sitecore.catalogProviderEngineConfiguration; `
$node.certificateThumbprint = $cert.Thumbprint; `
$xml.Save($pathToConfig)

$engineConnectIncludeDir = 'c:\\inetpub\\wwwroot\\sitecore\\App_Config\\Include\\Y.Commerce.Engine'; `
$pathToConfig = $(Join-Path -Path $engineConnectIncludeDir -ChildPath "\Sitecore.Commerce.Engine.DataProvider.config.disabled"); `
$xml = [xml](Get-Content $pathToConfig); `
$node = $xml.configuration.sitecore.catalogProviderEngineConfiguration; `
$node.shopsServiceUrl = 'http://commerce:5000/api/'; `
$node.commerceOpsServiceUrl = 'http://commerce:5000/commerceops/'; `
$node.defaultEnvironment = 'MercuryFoodAuthoring'; `
$node.defaultShopName = 'MercuryFood'; `
$xml.Save($pathToConfig)