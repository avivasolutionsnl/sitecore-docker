FROM microsoft/aspnet

ENV sa_password "AV!va1234"
ENV sql_server "mssql"
ENV mongo_server "mongo"

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"] 

# Add extracted files
ADD Data /Sitecore/Data
ADD Website /Sitecore/Website

# Add project specific configuration
ADD DataFolder.config /Sitecore/Website/App_Config/Include/

# Configure IIS
RUN Remove-IISSite -Name 'Default Web Site' -Confirm:$false; \
    New-IISSite -Name "Sitecore" -PhysicalPath C:\Sitecore\Website -BindingInformation "*:80:"

# Add scripts
ADD Setup-ConnectionStrings.ps1 /Sitecore/Scripts/

# See: https://github.com/Microsoft/iis-docker/issues/1
ENTRYPOINT C:\Sitecore\Scripts\Setup-ConnectionStrings.ps1; \
           C:\ServiceMonitor.exe w3svc
