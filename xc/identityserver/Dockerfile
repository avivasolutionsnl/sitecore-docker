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
    $sifConfigFile = Join-Path /files/ 'Configuration/Commerce/IdentityServer/sitecore-identity-config.json'; `
    Install-SitecoreConfiguration -Path $sifConfigFile `
    -CommerceInstallRoot c:\inetpub\wwwroot\ `
    -SitecoreIdentityServerApplicationName 'identity' 

# Configure plumber
# RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\IdentityServer\wwwroot -ChildPath "appsettings.json"); `
# $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
# $client = @{}; `
# $client.ClientId = 'Plumber'; `
# $client.ClientName = 'Plumber'; `
# $client.AccessTokenType = 0; `
# $client.AccessTokenLifetimeInSeconds = 3600; `
# $client.IdentityTokenLifetimeInSeconds = 3600; `
# $client.AllowAccessTokensViaBrowser = $true; `
# $client.RequireConsent = $false; `
# $client.RequireClientSecret = $false; `
# $client.AllowedGrantTypes = @('implicit'); `
# $client.AllowedScopes = @('openid', 'dataEventRecords', 'dataeventrecordsscope', 'securedFiles', 'securedfilesscope', 'role', 'EngineAPI'); `
# $client.RedirectUris = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000/?' -f $Env:HOST_NAME)); `
# $client.PostLogoutRedirectUris = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000/?' -f $Env:HOST_NAME)); `
# $client.AllowedCorsOrigins = @(('http://{0}:4000' -f $Env:HOST_NAME), ('http://{0}:4000' -f $Env:HOST_NAME)); `
# $json.AppSettings.Clients += $client; `
# $json = ConvertTo-Json $json -Depth 100; `
# Set-Content $pathToAppSettings -Value $json -Encoding UTF8

COPY xc/identityserver/UpdateCommerceHostname.ps1 /Scripts
COPY xc/identityserver/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-commerceHostname commerce.local" ]