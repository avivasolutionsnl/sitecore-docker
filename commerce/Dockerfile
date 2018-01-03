# escape=`
FROM microsoft/aspnet:4.7.1-windowsservercore-1709

ARG SQL_USER="sa"
ARG SQL_SA_PASSWORD
ARG SQL_DB_PREFIX
ARG SQL_SERVER="mssql"
ARG SOLR_PORT=8983
ARG SOLR_CORE_PREFIX="xp0"
ARG HOST_NAME="commerce"

ADD files /Files
ADD scripts /Scripts

ENV XCONNECT_CERT_PATH "c:\\Files\\xConnect.pfx"
ENV SOLR_CERT_PATH "c:\\Files\\solr.pfx"
ENV SITECORE_CERT_PATH "c:\\Files\\sitecore.pfx"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /Files

# Trust Self signed certificates
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SOLR_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:SITECORE_CERT_PATH -secret 'secret' -storeName 'Root' -storeLocation 'LocalMachine'

# Import XConnect certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile $Env:XCONNECT_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine'

ENV DOTNET_SDK_EXE="dotnet-sdk.exe"

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

RUN Invoke-WebRequest $Env:DOTNET_HOSTING_URL -OutFile hosting.exe; `
    & ./dotnetsdk.exe /quiet /install; 

# Expand installation files
RUN Expand-Archive -Path './Sitecore.Commerce.SDK.2.0.1328.zip' -DestinationPath './Sitecore.Commerce.SDK.2.0.1328'; 

RUN $pathToProj = './Sitecore.Commerce.SDK.2.0.1328/src/Sitecore.Commerce.Engine/Sitecore.Commerce.Engine.csproj'; `
    [xml] $xml = Get-Content $pathToProj; `
    $node = $xml.SelectSingleNode('//Project/PropertyGroup/TargetFramework'); `
    $node.InnerText = 'net47'; `
    $xml.Save($pathToProj);

RUN dotnet restore './Sitecore.Commerce.SDK.2.0.1328/Customer.Sample.Solution.sln'; `
    dotnet publish './Sitecore.Commerce.SDK.2.0.1328/Customer.Sample.Solution.sln' -o '/Publish/Customer.Sample.Solution'; `
    New-Item C:\Deploy\Customer.Sample.Solution -type directory; `
    Compress-Archive -Path '/Publish/Customer.Sample.Solution/*' -DestinationPath C:\Deploy\Customer.Sample.Solution\Customer.Sample.Solution.zip

RUN Expand-Archive -Path './Sitecore.IdentityServer.SDK.1.0.48.zip' -DestinationPath './Sitecore.IdentityServer.SDK.1.0.48'; 

RUN dotnet restore './Sitecore.IdentityServer.SDK.1.0.48/Sitecore.IdentityServer.sln'; `
    dotnet publish './Sitecore.IdentityServer.SDK.1.0.48/Sitecore.IdentityServer.sln' -o '/Publish/Sitecore.IdentityServer'; `
    New-Item C:\Deploy\Sitecore.IdentityServer -type directory; `
    Compress-Archive -Path '/Publish/Sitecore.IdentityServer/*' -DestinationPath C:\Deploy\Sitecore.IdentityServer\Sitecore.IdentityServer.zip

ADD scripts /Scripts

# Install SIF
RUN /Scripts/Install-SIF.ps1

RUN net user /add commerceuser 'Pa$$w0rd'

RUN Expand-Archive -Path './SIF.Sitecore.Commerce.1.0.1626.zip' -DestinationPath './SIF.Sitecore.Commerce.1.0.1626'; 

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce.1.0.1626/Modules'); `
    $solrUrl = 'https://solr:{0}/solr' -f $Env:SOLR_PORT; `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce.1.0.1626/Configuration/Commerce/CommerceEngine/CommerceEngine.Deploy.json' `
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

RUN Expand-Archive -Path './Sitecore.BizFX.1.0.443.zip' -DestinationPath './Sitecore.BizFX'; 

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce.1.0.1626/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce.1.0.1626/Configuration/Commerce/SitecoreBizFx/SitecoreBizFx.json' `
    -SitecoreBizFxServicesContentPath './Sitecore.BizFX' `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/SIF.Sitecore.Commerce.1.0.1626/Modules'); `
    Install-SitecoreConfiguration -Path '/Files/SIF.Sitecore.Commerce.1.0.1626/Configuration/Commerce/SitecoreIdentityServer/SitecoreIdentityServer.json' `
    -SitecoreIdentityServerContentPath /Deploy/Sitecore.IdentityServer `
    -SitecoreDbServer $Env:SQL_SERVER `
    -SitecoreCoreDbName "${$Env:SQL_DB_PREFIX}_Core" `
    -UserAccount @{ Domain = $Env:COMPUTERNAME; UserName = 'commerceuser'; Password = 'Pa$$w0rd' }    

ADD commerce/UpdateConnectionString.ps1 /Scripts

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server 'mssql'

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

RUN /Scripts/UpdateConnectionString.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -userName 'sa' `
    -password $Env:SQL_SA_PASSWORD `
    -server $Env:SQL_SERVER

RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
RUN choco install -y --params="Quiet" dotnetcore-windowshosting

RUN $pathToAppSettings  = $(Join-Path -Path c:\inetpub\wwwroot\SitecoreIdentityServer -ChildPath "appsettings.json"); `
    $json = Get-Content $pathToAppSettings -raw | ConvertFrom-Json; `
    $connectionString = 'Data Source={0};Initial Catalog=Sitecore_Core;Integrated Security=False;User Id={1};Password={2};' -f $Env:SQL_SERVER, 'sa', $Env:SQL_SA_PASSWORD; `
    $json.AppSettings.SitecoreMembershipOptions.ConnectionString = $connectionString; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $pathToAppSettings -Value $json -Encoding UTF8;

RUN $hostFileName = 'c:\\windows\\system32\\drivers\\etc\\hosts'; '\"`r`n127.0.0.1`t$Env:HOST_NAME\"' | Add-Content $hostFileName

ADD commerce/UpdateIdentityServerUrl.ps1 /Scripts

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName $Env:HOST_NAME

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName $Env:HOST_NAME

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName $Env:HOST_NAME

RUN /Scripts/UpdateIdentityServerUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName $Env:HOST_NAME

ADD commerce/UpdateSitecoreUrl.ps1 /Scripts

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceAuthoring_Sc9 `
    -hostName 'sitecore'

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceMinions_Sc9 `
    -hostName 'sitecore'

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceOps_Sc9 `
    -hostName 'sitecore'

RUN /Scripts/UpdateSitecoreUrl.ps1 -folder c:\inetpub\wwwroot\CommerceShops_Sc9 `
    -hostName 'sitecore'