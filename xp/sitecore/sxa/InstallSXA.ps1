# Use Commerce SIF modules to install packages
[Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/files-mount/');

icacls "C:\IIS\*" /grant everyone:(OI)(CI)F /T

Get-ChildItem /files-mount/* | Unblock-File

Install-Module -Name sitecoreinstallextensions -Force -AllowClobber


Import-Module sitecoreinstallextensions

Install-SitecoreConfiguration -Path '/sxa/install-sxa2.json' `
    -LocalStorage /files-mount
    -SiteName sitecore

# # Copy utilities to install packages (this is taken from Sitecore Commerce SIF)
# Copy-Item -Path /files-mount/CommerceSIF/SiteUtilityPages -Destination c:\\inetpub\\wwwroot\\sitecore\\SiteUtilityPages -Force -Recurse



# mkdir sitecore_packages

# Copy-Item -Path '/files-mount/Sitecore Experience Accelerator 1.8 rev. 181112 for 9.1.zip' -Destination c:\\sitecore_packages -Force -Recurse

# Copy-Item -Path '/files-mount/Sitecore PowerShell Extensions-5.0.zip' -Destination c:\\sitecore_packages -Force -Recurse

# Get-Acl c:\\inetpub\\wwwroot\\sitecore | Set-Acl -Path 
# c:\\sitecore_packages

# Get-Acl c:\\inetpub\\wwwroot\\sitecore | Set-Acl -Path 
# c:\\inetpub\\wwwroot\\sitecore\\SiteUtilityPages

# Get-ChildItem C:\\inetpub\\wwwroot\\sitecore\\sitecore\\admin\\packages

# # Install PSE and SXA packages
# Install-SitecoreConfiguration -Path '/sxa/install-sxa.json' `
#     -PowershellExtensionPackageFullPath "/sitecore_package/$env:PSE_PACKAGE" `
#     -SXAPackageFullPath "/sitecore_package/$env:SXA_PACKAGE"
