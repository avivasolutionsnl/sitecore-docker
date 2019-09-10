# escape=`

# Stage 0: prepare files & build prerequisites
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2-windowsservercore-ltsc2019 AS prepare

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_SIF_PACKAGE
ARG COMMERCE_ENGINE_PACKAGE

WORKDIR /Files

COPY files /Files
COPY scripts /Scripts

# Expand installation files
RUN Expand-Archive -Force -Path "/Files/$Env:COMMERCE_SIF_PACKAGE" -DestinationPath '/Files/SIF.Sitecore.Commerce';;

# Remove DacFx and SQL dependencies from the Commerce Engine WebDeploy (WDP) package which is not needed in the Commerce image
# The dependencies has been removed in the parameters.xml and archive.xml and the Commerce Engine WDP package gets updated with these custom files.
COPY xc/commerce/parameters.xml /Files
COPY xc/commerce/archive.xml /Files
RUN Compress-Archive -Path "/Files/parameters.xml" -DestinationPath "/Files/$Env:COMMERCE_ENGINE_PACKAGE" -Update; `
    Compress-Archive -Path "/Files/archive.xml" -DestinationPath "/Files/$Env:COMMERCE_ENGINE_PACKAGE" -Update;

# Stage 1: create actual image
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2-windowsservercore-ltsc2019

ARG HOST_NAME="commerce"
ARG COMMERCE_ENGINE_PACKAGE
ARG PLUMBER_FILE_NAME="plumber.zip"
ARG REDIS_HOSTNAME="redis"
ARG REDIS_INSTANCE_NAME="Redis"
ARG SITECORE_BIZFX_PACKAGE

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SOLR_PORT=8983
ARG SOLR_CORE_PREFIX="sitecore"

ARG XCONNECT_CERT_PATH
ARG COMMERCE_CERT_PATH
ARG ROOT_CERT_PATH

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Web Deploy
ARG WEBDEPLOY_MSI='c:\\Files\\webdeploy.msi'
ADD https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi ${WEBDEPLOY_MSI}
RUN Start-Process msiexec.exe -ArgumentList '/i', $env:WEBDEPLOY_MSI, '/quiet', '/norestart' -NoNewWindow -Wait;

WORKDIR /Files

# Copy required files
COPY scripts /Scripts

COPY files/*.pfx /Files/
COPY --from=prepare /Files/SIF.Sitecore.Commerce /Files/SIF.Sitecore.Commerce/
COPY --from=prepare /Files/${SITECORE_BIZFX_PACKAGE} /Files/
COPY --from=prepare /Files/${COMMERCE_ENGINE_PACKAGE} /Files/
COPY --from=prepare /Files/${PLUMBER_FILE_NAME} /Files/

# Trust & import self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:ROOT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; `
    /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'; 

RUN net user /add commerceuser 'Pa$$w0rd'; `
    Set-LocalUser -Name 'commerceuser' -PasswordNeverExpires:$true

# Install SIF
RUN /Scripts/Install-SIF.ps1

# Patch bug in CommerceEngine.json file. It misses the definition of the parameter CommerceServicesPostfix. Only a problem
# because we use it directly. Also have to remove the comments from the json file when reading it, because
# json does not support comments and the powershell command will fail otherwise.
RUN $configPath = '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/CommerceEngine/CommerceEngine.json'; `
    $json = (Get-Content $configPath) -replace '^\s*//.*' | Out-String | ConvertFrom-Json; `
    $json.Parameters | Add-Member -Name 'CommerceServicesPostfix' -Value @{'Type' = 'string'; 'Description' = 'The Commerce Engine postfix for services names'; 'DefaultValue' = ''} -MemberType NoteProperty; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $configPath -Value $json -Encoding UTF8

# Configure
RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    $solrUrl = 'http://solr:{0}/solr' -f $Env:SOLR_PORT; `
    cd '/Files/SIF.Sitecore.Commerce'; `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/CommerceEngine/CommerceEngine.json' `
    -CommerceServicesDbServer $Env:SQL_SERVER `
    -CommerceServicesDbName SitecoreCommerce9_SharedEnvironments `
    -CommerceServicesGlobalDbName SitecoreCommerce9_Global `    
    -CommerceServicesPostfix Sc9 `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core" `
    -BizFxPort 4200 `
    -SolrUrl $solrUrl `
    -SearchIndexPrefix $Env:SOLR_CORE_PREFIX `
    -EnvironmentsPrefix commerce `
    -SitecoreIdentityServerUrl https://identity`
    -CommerceOpsServicesPort 5015 `
    -CommerceShopsServicesPort 5005 `
    -CommerceAuthoringServicesPort 5000 `
    -CommerceMinionsServicesPort 5010 `
    -SiteHostHeaderName 'sitecore' `
    -UserDomain $Env:COMPUTERNAME ` 
    -UserName 'commerceuser' `
    -UserPassword 'Pa$$w0rd' `
    -CommerceSearchProvider 'SOLR' `
    -CommerceEngineCertificateName 'commerce' `
    -CommerceEngineWdpFullPath "/Files/$Env:COMMERCE_ENGINE_PACKAGE" `
    -SitecoreDomain 'sitecore' `
    -SitecoreUsername 'admin' `
    -SitecoreUserPassword 'b' `
    -RedisConfiguration $Env:REDIS_HOSTNAME `
    -RedisInstanceName $Env:REDIS_INSTANCE_NAME `
    -Skip "CommerceEngine-Pre_ClearRedis", "CommerceEngine-Pre_AddCommerceUserToCoreDatabase", "CommerceEngine-Pre_CreateSignedEngineCert", "CommerceEngine-Pre_CreateSignedCert", "CommerceEngine-Pre_CreateLocalhostSignedCert"

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/SitecoreBizFx/SitecoreBizFx.Install.json' `
    -UserDomain $Env:COMPUTERNAME ` 
    -UserName 'commerceuser' `
    -UserPassword 'Pa$$w0rd' `
    -Port 4200 `
    -SiteName 'SitecoreBizFx' `
    -SitecoreIdentityServerUrl https://identity `
    -EngineAuthoringUrl https://commerce:5000 `
    -EngineBizFxUrl https://commerce:4200 `
    -Package "/Files/$Env:SITECORE_BIZFX_PACKAGE"

COPY xc/commerce/UpdateConnectionString.ps1 /Scripts

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -userName $Env:SQL_USER `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -userName $Env:SQL_USER `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -userName $Env:SQL_USER `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -userName $Env:SQL_USER `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

# Install hosting, IIS URL Rewrite, and vim
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install -y --params="Quiet" --version 2.2.5 dotnetcore-windowshosting; `
    choco install -y --params="Quiet" urlrewrite; `
    /Scripts/Install-Vim.ps1;

# Set the certificate details of the certificate sitecore will connect with
RUN $CommerceServicesPathCollection = @('C:\\inetpub\\wwwroot\\CommerceAuthoring_Sc9', 'C:\\inetpub\\wwwroot\\CommerceMinions_Sc9', `
                                       'C:\\inetpub\\wwwroot\\CommerceOps_Sc9', 'C:\\inetpub\\wwwroot\\CommerceShops_Sc9'); `
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2; `
    $cert.Import('c:\\Files\\commerce.pfx', 'secret', 'MachineKeySet'); `
    foreach($path in $CommerceServicesPathCollection) { `
        $pathToJson = $(Join-Path -Path $path -ChildPath "wwwroot\config.json"); `
        $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
        $certificateNode = $originalJson.Certificates.Certificates[0]; `
		$certificateNode.Thumbprint = $cert.Thumbprint; `
        $appSettingsNode = $originalJson.AppSettings; `
        $appSettingsNode.AntiForgeryEnabled = $False; `
		$originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; `
    } 

# Install plumber
RUN Expand-Archive -Path "/Files/$Env:PLUMBER_FILE_NAME" -DestinationPath 'c:\\inetpub\\plumber'; `
    Import-Module -Name WebAdministration; `
    $iisApp = New-Item IIS:\Sites\Plumber -bindings @{protocol='http';bindingInformation='*:4000:*'} -physicalPath 'c:\inetpub\plumber'; `
    $pathToJson = $(Join-Path -Path 'C:\\inetpub\\plumber' -ChildPath "config.json"); `
    $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
    $originalJson.EngineUri = ('https://{0}:5000' -f $Env:HOST_NAME); `
    $originalJson.IdentityServerUri = 'https://identity'; `
    $originalJson.PlumberUri = ('http://{0}:4000' -f $Env:HOST_NAME); `
    $originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; 

# Expose Plumber port
EXPOSE 4000

COPY xc/commerce/WatchDefaultDirectories.ps1 /Scripts
COPY xc/commerce/UpdateHostname.ps1 /Scripts
COPY xc/commerce/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-commerceHostname commerce.local -sitecoreHostname sitecore -identityHostname identity" ]