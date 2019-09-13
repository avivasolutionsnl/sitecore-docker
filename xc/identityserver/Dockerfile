# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_SIF_PACKAGE

COPY files/$COMMERCE_SIF_PACKAGE /files/

# Copy required files
COPY scripts /Scripts

WORKDIR /files/

RUN Expand-Archive $env:COMMERCE_SIF_PACKAGE -DestinationPath /files/; `
    $sifConfigFile = Join-Path /files/ 'Configuration/Commerce/IdentityServer/IdentityServer.Config.json'; `
    Install-SitecoreConfiguration -Path $sifConfigFile `
    -CommerceInstallRoot c:\inetpub\wwwroot\ `
    -SitecoreIdentityServerApplicationName 'identity' 

# Copy default plumber identity server configuration
COPY xc/identityserver/Sitecore.Plumber.IdentityServer.Host.xml /inetpub/wwwroot/identity/Config/production/

COPY xp/identityserver/UpdateHostname.ps1 /Scripts
COPY xc/identityserver/UpdateCommerceHostname.ps1 /Scripts
COPY xc/identityserver/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-commerceHostname commerce.local -sitecoreHostname sitecore -identityHostname identity" ]