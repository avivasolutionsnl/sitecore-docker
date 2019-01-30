# escape=`

# Stage 0: prepare files
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

ARG CONFIG_PACKAGE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD files/$CONFIG_PACKAGE /Files/

RUN Expand-Archive -Path /Files/$Env:CONFIG_PACKAGE -DestinationPath /Files/Config 


# Stage 1: create actual image
FROM microsoft/aspnet:4.7.1-windowsservercore-1709

ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SITE_NAME="identity"
ARG IDENTITYSERVER_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"] 


COPY files/license.xml /Files/
COPY files/$IDENTITYSERVER_PACKAGE /Files/
COPY files/*.pfx /Files/
COPY --from=prepare /Files/Config /Files/Config/
ADD scripts /Scripts

ENV IDENTITY_CERT_PATH "C:\\Files\\identity.pfx"

# Trust Self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:IDENTITY_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'

# Import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:IDENTITY_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

RUN /Scripts/Install-SIF.ps1

# Install WebDeploy
ENV WEBDEPLOY_MSI="webdeploy.msi"
ADD http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi ${WEBDEPLOY_MSI}
RUN Start-Process msiexec.exe -ArgumentList '/i', $Env:WEBDEPLOY_MSI, '/quiet', '/norestart' -NoNewWindow -Wait

RUN Remove-Website -Name 'Default Web Site'

ENV SIF_CONFIG="c:\\Files\\Config\\identityserver.json"

RUN $config = Get-Content $Env:SIF_CONFIG | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path $Env:SIF_CONFIG

RUN Install-SitecoreConfiguration -Path $Env:SIF_CONFIG `
    -Package c:/Files/$Env:IDENTITYSERVER_PACKAGE `
    -SqlDbPrefix $Env:SQL_DB_PREFIX `
    -SitecoreIdentityCert "Identity"`
    -LicenseFile "c:\\Files\\license.xml"`
    -SiteName $Env:SITE_NAME`
    -SqlCoreUser "sa"`
    -SqlCorePassword $Env:SQL_SA_PASSWORD`
    -SqlServer $Env:SQL_SERVER`
    -PasswordRecoveryUrl http://$Env:SITE_NAME`
    -AllowedCorsOrigins http://$Env:SITE_NAME`
    -ClientSecret "SIF-Default"

RUN Start-WebAppPool -Name $Env:SITE_NAME 
RUN Start-Website -Name $Env:SITE_NAME