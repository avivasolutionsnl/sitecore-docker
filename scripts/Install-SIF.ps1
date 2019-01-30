# Install SIF
Install-PackageProvider -Name NuGet -Force; `
Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2; `
Install-Module SitecoreInstallFramework -RequiredVersion 2.0.0 -Force
