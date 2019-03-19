$filesPath = "/files-mount"

# Extract Commerce SIF
& (Join-Path $env:INSTALL_TEMP "Extract-Commerce-Sif-SiteUtilities.ps1") -FromPath $filesPath -ToPath $env:INSTALL_TEMP;

# Use Commerce SIF modules to install packages
[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';' + "$env:INSTALL_TEMP/Modules");

# Copy utilities to install packages (this is taken from Sitecore Commerce SIF)
Copy-Item -Path $env:INSTALL_TEMP/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore -Force -Recurse

# Install JSS packages
Install-SitecoreConfiguration -Path '/jss/install-jss.json' `
    -JSSPackageFullPath "$filesPath/$env:JSS_PACKAGE" `
    -TransformFolderPath 'c:\jss' `
    -SitePhysicalPath 'c:\inetpub\wwwroot\sitecore'