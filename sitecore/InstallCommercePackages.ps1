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