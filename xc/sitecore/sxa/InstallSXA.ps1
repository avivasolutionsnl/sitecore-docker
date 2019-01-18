# Use Commerce SIF modules to install packages
[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules');

# Copy utilities to install packages (this is taken from Sitecore Commerce SIF)
Copy-Item -Path /Files/CommerceSIF/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore\\SiteUtilityPages -Force -Recurse

# Install PSE and SXA packages
Install-SitecoreConfiguration -Path '/sxa/install-sxa.json' `
    -PowershellExtensionPackageFullPath "/files-mount/$env:PSE_PACKAGE" `
    -SXAPackageFullPath "/files-mount/$env:SXA_PACKAGE" `
    -SCXAPackageFullPath "/files-mount/$env:SCXA_PACKAGE"
