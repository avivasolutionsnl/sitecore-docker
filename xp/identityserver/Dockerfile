# escape=`
# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS prepare

ARG CONFIG_PACKAGE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD files/$CONFIG_PACKAGE /Files/

RUN Expand-Archive -Path /Files/$Env:CONFIG_PACKAGE -DestinationPath /Files/Config 

 # Stage 1: create actual image
FROM ${BASE_IMAGE}

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SITE_NAME="identity"
ARG SITECORE_SITE_NAME="sitecore"
ARG IDENTITYSERVER_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"] 

COPY xp/license/license.xml /Files/
COPY files/$IDENTITYSERVER_PACKAGE /Files/
COPY files/*.pfx /Files/
COPY --from=prepare /Files/Config /Files/Config/
ADD scripts /Scripts

ENV IDENTITY_CERT_PATH "C:\\Files\\identity.pfx"
ENV ROOT_CERT_PATH "C:\\Files\\root.pfx"

 #Instal donet core windows hosting
RUN choco install -y --params="Quiet" dotnetcore-windowshosting; 

 # Trust Self signed certificates & certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:ROOT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:ROOT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:IDENTITY_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

ENV SIF_CONFIG="c:\\Files\\Config\\identityserver.json"

RUN $config = Get-Content $Env:SIF_CONFIG | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path $Env:SIF_CONFIG

RUN Install-SitecoreConfiguration -Path $Env:SIF_CONFIG `
    -Package c:/Files/$Env:IDENTITYSERVER_PACKAGE `
    -SqlDbPrefix $Env:SQL_DB_PREFIX `
    -SitecoreIdentityCert "Identity"`
    -LicenseFile "c:/Files/license.xml" `
    -SiteName $Env:SITE_NAME `
    -SqlCoreUser $Env:SQL_USER `
    -SqlCorePassword $Env:SQL_SA_PASSWORD `
    -SqlServer $Env:SQL_SERVER `
    -PasswordRecoveryUrl http://$Env:SITE_NAME `
    -AllowedCorsOrigins http://$Env:SITECORE_SITE_NAME `
    -ClientSecret "SIF-Default"

COPY xp/identityserver/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-sitecoreHostname sitecore -identityHostname identity" ]
