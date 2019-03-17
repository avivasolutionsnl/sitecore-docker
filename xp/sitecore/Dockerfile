# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS prepare

ARG CONFIG_PACKAGE

COPY files /Files

RUN Expand-Archive -Path /Files/$Env:CONFIG_PACKAGE -DestinationPath /Files/Config 


# Stage 1: create actual image
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SITE_NAME="sitecore"
ARG SOLR_PORT=8983
ARG SITECORE_CORE_PREFIX
ARG SITECORE_PACKAGE

COPY Files/*.pfx /Files/
COPY dummylicense.xml /license/license.xml
COPY xp/sitecore/Boot.ps1 ./
COPY files/$SITECORE_PACKAGE /Files/
COPY --from=prepare /Files/Config /Files/Config/
COPY scripts /Scripts

ENV XCONNECT_CLIENT_CERT_PATH "c:\\Files\\xconnect-client.pfx"
ENV XCONNECT_SSL_CERT_PATH "c:\\Files\\xconnect-ssl.pfx"
ENV SITECORE_CERT_PATH "c:\\Files\\sitecore.pfx"

# Trust Self signed certificates & import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_SSL_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CLIENT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CLIENT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

# Install chocolatey
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install -y --params="Quiet" vcredist2015

ENV SIF_CONFIG="c:/Files/Config/sitecore-XP0.json"

RUN $config = Get-Content $Env:SIF_CONFIG | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path $Env:SIF_CONFIG

RUN $solrUrl = 'http://solr:{0}/solr' -f $Env:SOLR_PORT; `
    Install-SitecoreConfiguration -Path $Env:SIF_CONFIG `
    -Package c:/Files/$Env:SITECORE_PACKAGE `
    -LicenseFile "c:/license/license.xml" `
    -Sitename $Env:SITE_NAME `
    -SqlDbPrefix $Env:SQL_DB_PREFIX `
    -SqlServer $Env:SQL_SERVER `
    -SqlAdminUser $Env:SQL_USER `
    -SqlAdminPassword $Env:SQL_SA_PASSWORD `
    -SqlCoreUser $Env:SQL_USER `
    -SqlCorePassword $Env:SQL_SA_PASSWORD `
    -SqlMasterUser $Env:SQL_USER `
    -SqlMasterPassword $Env:SQL_SA_PASSWORD `
    -SqlWebUser $Env:SQL_USER `
    -SqlWebPassword $Env:SQL_SA_PASSWORD `
    -SqlFormsUser $Env:SQL_USER `
    -SqlFormsPassword $Env:SQL_SA_PASSWORD `
    -SolrCorePrefix $Env:SITECORE_CORE_PREFIX `
    -SqlProcessingTasksUser $Env:SQL_USER `
    -SqlProcessingTasksPassword $Env:SQL_SA_PASSWORD `
    -SqlReferenceDataUser $Env:SQL_USER `
    -SqlReferenceDataPassword $Env:SQL_SA_PASSWORD ` 
    -SqlExmMasterUser "sa" `
    -SqlExmMasterPassword $Env:SQL_SA_PASSWORD `
    -SqlMessagingUser "sa" `
    -SqlMessagingPassword $Env:SQL_SA_PASSWORD `	
    -SqlProcessingPoolsUser $Env:SQL_USER `
    -SqlProcessingPoolsPassword $Env:SQL_SA_PASSWORD `
    -SqlReportingUser $Env:SQL_USER `
    -SqlReportingPassword $Env:SQL_SA_PASSWORD `  
    -SqlMarketingAutomationUser $Env:SQL_USER `
    -SqlMarketingAutomationPassword $Env:SQL_SA_PASSWORD `
    -SolrUrl $solrUrl `
    -XConnectCert "xConnect.client" `
    -XConnectCollectionService "https://xconnect" `
    -Skip "UpdateSolrSchema"; `
    Remove-Item -Recurse -Force -Path "c:\inetpub\wwwroot\$Env:SITE_NAME\App_Data\logs"

# Get the web binding of the site
RUN $pwd = ConvertTo-SecureString -String 'secret' -Force -AsPlainText; `
    $PFXCert = Get-PfxData -FilePath $Env:SITECORE_CERT_PATH -Password $pwd; `
    New-WebBinding -Name $Env:SITE_NAME -IPAddress * -Port 443 -Protocol "https"; `
    $binding = Get-WebBinding -Name $Env:SITE_NAME -Protocol "https"; `
    $binding.AddSslCertificate($PFXCert.EndEntityCertificates.ThumbPrint, 'my')

# Copy custom config & enable live-mode
COPY xp/sitecore/config /Config
RUN Copy-Item /Config/*.* c:\inetpub\wwwroot\$Env:SITE_NAME\App_Config\Include; `
    mv C:\inetpub\wwwroot\sitecore\App_Config\Include\Examples\LiveMode.config.example C:\inetpub\wwwroot\sitecore\App_Config\Include\Examples\LiveMode.config

ENTRYPOINT /Boot.ps1
