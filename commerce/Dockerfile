# escape=`

# Stage 0: prepare files & build prerequisites
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_SIF_PACKAGE
ARG COMMERCE_SDK_PACKAGE
ARG SITECORE_BIZFX_PACKAGE
ARG SITECORE_IDENTITY_PACKAGE

WORKDIR /Files

ADD files /Files
ADD scripts /Scripts

# Expand installation files
RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SDK_PACKAGE" -DestinationPath '/Files/Sitecore.Commerce.SDK'; 
RUN Expand-Archive -Path "/Files/$Env:SITECORE_IDENTITY_PACKAGE" -DestinationPath '/Files/Sitecore.IdentityServer.SDK'; 
RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SIF_PACKAGE" -DestinationPath '/Files/SIF.Sitecore.Commerce'; 
RUN Expand-Archive -Path '/Files/$Env:SITECORE_BIZFX_PACKAGE' -DestinationPath '/Files/Sitecore.BizFX'; 

ENV DOTNET_SDK_DOWNLOAD_URL="https://download.microsoft.com/download/2/9/3/293BC432-348C-4D1C-B628-5AC8AB7FA162/dotnet-sdk-2.1.3-win-x64.exe"

RUN Invoke-WebRequest $Env:DOTNET_SDK_DOWNLOAD_URL -OutFile dotnetsdk.exe; `
    & ./dotnetsdk.exe -q;

ENV DOTNET_DEVELOPER_PACK_URL="https://download.microsoft.com/download/E/F/D/EFD52638-B804-4865-BB57-47F4B9C80269/NDP462-DevPack-KB3151934-ENU.exe"

RUN Invoke-WebRequest $Env:DOTNET_DEVELOPER_PACK_URL -OutFile dotnetdevpack.exe; `
    & ./dotnetdevpack.exe -q;

ENV DOTNET_47_DEVELOPER_PACK_URL="https://download.microsoft.com/download/A/1/D/A1D07600-6915-4CB8-A931-9A980EF47BB7/NDP47-DevPack-KB3186612-ENU.exe"

RUN Invoke-WebRequest $Env:DOTNET_47_DEVELOPER_PACK_URL -OutFile dotnetdevpack47.exe; `
    & ./dotnetdevpack47.exe -q;

ENV DOTNET_HOSTING_URL="https://download.microsoft.com/download/5/C/1/5C190037-632B-443D-842D-39085F02E1E8/DotNetCore.2.0.3-WindowsHosting.exe"

RUN dotnet restore './Sitecore.Commerce.SDK/Customer.Sample.Solution.sln'; `
    dotnet publish './Sitecore.Commerce.SDK/Customer.Sample.Solution.sln' -o '/Publish/Customer.Sample.Solution'; `
    New-Item C:\Deploy\Customer.Sample.Solution -type directory; `
    Compress-Archive -Path '/Publish/Customer.Sample.Solution/*' -DestinationPath C:\Deploy\Customer.Sample.Solution\Customer.Sample.Solution.zip

RUN dotnet restore './Sitecore.IdentityServer.SDK/Sitecore.IdentityServer.sln'; `
    dotnet publish './Sitecore.IdentityServer.SDK/Sitecore.IdentityServer.sln' -o '/Publish/Sitecore.IdentityServer'; `
    New-Item C:\Deploy\Sitecore.IdentityServer -type directory; `
    Compress-Archive -Path '/Publish/Sitecore.IdentityServer/*' -DestinationPath C:\Deploy\Sitecore.IdentityServer\Sitecore.IdentityServer.zip


# Stage 1: create actual image
FROM microsoft/aspnet:4.7.1-windowsservercore-1709

ARG HOST_NAME="commerce"
ARG SITECORE_HOSTNAME="sitecore"
ARG SHOP_NAME="myshop"
ARG ENVIRONMENT_NAME="myshopauthoring"

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SOLR_PORT=8983
ARG SOLR_CORE_PREFIX="xp0"
ENV XCONNECT_CERT_PATH "c:\\Files\\xConnect.pfx"
ENV SOLR_CERT_PATH "c:\\Files\\solr.pfx"
ENV SITECORE_CERT_PATH "c:\\Files\\sitecore.pfx"
ENV COMMERCE_CERT_PATH "c:\\Files\\commerce.pfx"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /Files

# Copy required files
ADD scripts /Scripts

COPY files/*.pfx /Files/
COPY --from=prepare /Files/Sitecore.Commerce.SDK /Files/Sitecore.Commerce.SDK/
COPY --from=prepare /Files/SIF.Sitecore.Commerce /Files/SIF.Sitecore.Commerce/
COPY --from=prepare /Files/Sitecore.BizFX /Files/Sitecore.BizFX/
COPY --from=prepare /Deploy/Customer.Sample.Solution /Deploy/Customer.Sample.Solution/
COPY --from=prepare /Deploy/Sitecore.IdentityServer /Deploy/Sitecore.IdentityServer/

# Trust Self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SOLR_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'

# Import certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

# Import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

RUN $pathToProj = './Sitecore.Commerce.SDK/src/Sitecore.Commerce.Engine/Sitecore.Commerce.Engine.csproj'; `
    [xml] $xml = Get-Content $pathToProj; `
    $node = $xml.SelectSingleNode('//Project/PropertyGroup/TargetFramework'); `
    $node.InnerText = 'net47'; `
    $xml.Save($pathToProj);

RUN net user /add commerceuser 'Pa$$w0rd'

# Install SIF
RUN /Scripts/Install-SIF.ps1

# Configure
RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    $solrUrl = 'https://solr:{0}/solr' -f $Env:SOLR_PORT; `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/CommerceEngine/CommerceEngine.Deploy.json' `
    -CommerceServicesDbServer $Env:SQL_SERVER `
    -CommerceServicesDbName SitecoreCommerce9_SharedEnvironments `
    -CommerceServicesGlobalDbName SitecoreCommerce9_Global `
    -CommerceServicesPostfix Sc9 `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core"`
    -SolrUrl $solrUrl `
    -SolrCorePrefix $Env:SOLR_CORE_PREFIX `
    -CommerceOpsServicesPort 5015 `
    -CommerceShopsServicesPort 5005 `
    -CommerceAuthoringServicesPort 5000 `
    -CommerceMinionsServicesPort 5010 `
    -CommerceOpsServicesContentPath /Deploy/Customer.Sample.Solution `
    -CommerceShopsServicesContentPath /Deploy/Customer.Sample.Solution `
    -CommerceAuthoringServicesContentPath /Deploy/Customer.Sample.Solution `
    -CommerceMinionsServicesContentPath /Deploy/Customer.Sample.Solution `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' } `
    -CommerceEngineDacPac '/Files/Dacpac.dacpac' `
    -CommerceServicesSQL '/Files/sql.sql' `
    -Skip "DeployCommerceDatabase", "AddCommerceUserToCoreDatabase"

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/SitecoreBizFx/SitecoreBizFx.json' `
    -SitecoreBizFxServicesContentPath './Sitecore.BizFX' `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce/Configuration/Commerce/SitecoreIdentityServer/SitecoreIdentityServer.json' `
    -SitecoreIdentityServerContentPath /Deploy/Sitecore.IdentityServer `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core" `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }    

ADD commerce/UpdateConnectionString.ps1 /Scripts

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER; `
    /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

# Install hosting
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install -y --params="Quiet" dotnetcore-windowshosting

# Install IIS URL Rewrite
RUN choco install -y --params="Quiet" urlrewrite

RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $connectionString = 'Data Source={0};Initial Catalog=Sitecore_Core;Integrated Security=False;User Id={1};Password={2};' -f $Env:SQL_SERVER, 'sa', $Env:SQL_SA_PASSWORD; `
    $json.AppSettings.SitecoreMembershipOptions.ConnectionString = $connectionString; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8;

RUN $hostFileName = 'c:\\windows\\system32\\drivers\\etc\\hosts'; '\"`r`n127.0.0.1`t$Env:HOST_NAME\"' | Add-Content $hostFileName

ADD commerce/UpdateIdentityServerUrl.ps1 /Scripts

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName $Env:HOST_NAME; `
    /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName $Env:HOST_NAME;

ADD commerce/UpdateSitecoreUrl.ps1 /Scripts

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME; `
    /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName $Env:SITECORE_HOSTNAME

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
        $certificateNode.Subject = $cert.Subject; `
        $certificateNode.IssuerCN = $cert.Issuer; `
		$originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson; `
    } 

# Configure the business tools
RUN $pathToJson = $(Join-Path -Path 'C:\\inetpub\\wwwroot\\SitecoreBizFx' -ChildPath "assets\\config.json"); `
    $originalJson = Get-Content $pathToJson -Raw | ConvertFrom-Json; `
    $originalJson.EnvironmentName = $Env:ENVIRONMENT_NAME; `
    $originalJson.EngineUri = ('http://{0}:5000' -f $Env:HOST_NAME); `
    $originalJson.IdentityServerUri = ('http://{0}:5050' -f $Env:HOST_NAME); `
    $originalJson.BizFxUri = ('http://{0}:4200' -f $Env:HOST_NAME); `
    $originalJson.ShopName = $Env:SHOP_NAME; `
    $originalJson | ConvertTo-Json -Depth 100 -Compress | set-content $pathToJson;

# Configure the business tools with the correct settings in Identity server
RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $json.AppSettings.Clients[0].RedirectUris[0] = ('http://{0}:4200' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].RedirectUris[1] = ('http://{0}:4200/?' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].PostLogoutRedirectUris[0] = ('http://{0}:4200' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].PostLogoutRedirectUris[1] = ('http://{0}:4200/?' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].AllowedCorsOrigins[0] = ('http://{0}:4200/' -f $Env:HOST_NAME); `
    $json.AppSettings.Clients[0].AllowedCorsOrigins[1] = ('http://{0}:4200' -f $Env:HOST_NAME); `         
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8;
