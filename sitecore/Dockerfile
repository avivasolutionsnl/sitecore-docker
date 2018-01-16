# escape=`

# Stage 0: prepare files
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

ARG CONFIG_PACKAGE

ADD files /Files

RUN Expand-Archive -Path /Files/$Env:CONFIG_PACKAGE -DestinationPath /Files/Config 


# Stage 1: create actual image
FROM microsoft/aspnet:4.7.1-windowsservercore-1709

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SITE_NAME="sitecore"
ARG SOLR_PORT=8983
ARG SITECORE_PACKAGE

COPY files/*.pfx /Files/
COPY files/license.xml /Files/
COPY files/$SITECORE_PACKAGE /Files/
COPY --from=prepare /Files/Config /Files/Config/
ADD scripts /Scripts

ENV XCONNECT_CERT_PATH "c:\\Files\\xConnect.pfx"
ENV SOLR_CERT_PATH "c:\\Files\\solr.pfx"
ENV SITECORE_CERT_PATH "c:\\Files\\sitecore.pfx"

# Trust Self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SOLR_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'

# Import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

# Install WebDeploy
ENV WEBDEPLOY_MSI="webdeploy.msi"
ADD http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi ${WEBDEPLOY_MSI}
RUN Start-Process msiexec.exe -ArgumentList '/i', $Env:WEBDEPLOY_MSI, '/quiet', '/norestart' -NoNewWindow -Wait

# Install IIS URL Rewrite
ENV URLREWRITE_MSI="urlrewrite.msi"
ADD http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi ${URLREWRITE_MSI}
RUN Start-Process msiexec.exe -ArgumentList '/i', $Env:URLREWRITE_MSI, '/quiet', '/norestart' -NoNewWindow -Wait

# Install SIF
RUN /Scripts/Install-SIF.ps1

RUN Remove-Website -Name 'Default Web Site'

ENV SIF_CONFIG="c:/Files/Config/sitecore-XP0.json"

RUN $config = Get-Content $Env:SIF_CONFIG | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path $Env:SIF_CONFIG

RUN $solrUrl = 'https://solr:{0}/solr' -f $Env:SOLR_PORT; `
    Install-SitecoreConfiguration -Path $Env:SIF_CONFIG `
    -Package c:/Files/$Env:SITECORE_PACKAGE `
    -LicenseFile "c:/Files/license.xml" `
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
    -SolrCorePrefix $Env:SQL_DB_PREFIX `
    -SqlProcessingTasksUser $Env:SQL_USER `
    -SqlProcessingTasksPassword $Env:SQL_SA_PASSWORD `
    -SqlReferenceDataUser $Env:SQL_USER `
    -SqlReferenceDataPassword $Env:SQL_SA_PASSWORD `       
    -SqlProcessingPoolsUser $Env:SQL_USER `
    -SqlProcessingPoolsPassword $Env:SQL_SA_PASSWORD `
    -SqlReportingUser $Env:SQL_USER `
    -SqlReportingPassword $Env:SQL_SA_PASSWORD `  
    -SqlMarketingAutomationUser $Env:SQL_USER `
    -SqlMarketingAutomationPassword $Env:SQL_SA_PASSWORD `
    -SolrUrl $solrUrl `
    -XConnectCert "xConnect.client" `
    -XConnectCollectionService "https://xconnect" `
    -Skip "UpdateSolrSchema"

RUN Remove-Item -Recurse -Force -Path "c:\inetpub\wwwroot\$Env:SITE_NAME\App_Data\logs"

# get the web binding of the site
RUN $pwd = ConvertTo-SecureString -String 'secret' -Force -AsPlainText; `
    $PFXCert = Get-PfxData -FilePath $Env:SITECORE_CERT_PATH -Password $pwd; `
    New-WebBinding -Name $Env:SITE_NAME -IPAddress * -Port 443 -Protocol "https"; `
    $binding = Get-WebBinding -Name $Env:SITE_NAME -Protocol "https"; `
    $binding.AddSslCertificate($PFXCert.EndEntityCertificates.ThumbPrint, 'my')

ADD config /Config
RUN Copy-Item /Config/*.* c:\inetpub\wwwroot\$Env:SITE_NAME\App_Config\Include

# enable live-mode
RUN mv C:\inetpub\wwwroot\sitecore\App_Config\Include\Examples\LiveMode.config.example C:\inetpub\wwwroot\sitecore\App_Config\Include\Examples\LiveMode.config

# Start site
RUN Start-WebAppPool -Name $Env:SITE_NAME; `
    Start-Website -Name $Env:SITE_NAME

ENTRYPOINT C:\ServiceMonitor.exe w3svc