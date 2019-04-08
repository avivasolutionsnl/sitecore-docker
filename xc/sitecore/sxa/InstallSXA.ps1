$filesPath = "/files-mount"

# Extract Commerce SIF
& (Join-Path $env:INSTALL_TEMP "Extract-Commerce-Sif-SiteUtilities.ps1") -FromPath $filesPath -ToPath $env:INSTALL_TEMP;

# Use Commerce SIF modules to install packages
[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';' + "$env:INSTALL_TEMP/Modules");

# Copy utilities to install packages (this is taken from Sitecore Commerce SIF)
Copy-Item -Path $env:INSTALL_TEMP/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore -Force -Recurse

# Enlarge timeout to 7200 seconds
((Get-Content -path $env:INSTALL_TEMP/Modules/SitecoreUtilityTasks/SitecoreUtilityTasks.psm1 -Raw) -replace '720','7200') | Set-Content -Path $env:INSTALL_TEMP/Modules/SitecoreUtilityTasks/SitecoreUtilityTasks.psm1

# Install PSE and SXA packages
Install-SitecoreConfiguration -Path '/sxa/install-sxa.json' `
    -PowershellExtensionPackageFullPath "$filesPath/$env:PSE_PACKAGE" `
    -SXAPackageFullPath "$filesPath/$env:SXA_PACKAGE" `
    -SCXAPackageFullPath "$filesPath/$env:SCXA_PACKAGE"
