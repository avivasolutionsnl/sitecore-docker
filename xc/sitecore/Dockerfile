# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as builder

ARG COMMERCE_SIF_PACKAGE
ARG COMMERCE_CONNECT_ENGINE_PACKAGE
ARG COMMERCE_CONNECT_PACKAGE
ARG COMMERCE_MA_PACKAGE
ARG COMMERCE_XPROFILES_PACKAGE
ARG COMMERCE_XANALYTICS_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY files/ /Files/

RUN Expand-Archive -Path "/Files/$Env:COMMERCE_SIF_PACKAGE" -DestinationPath /Files/CommerceSIF -Force

COPY scripts/Clear-Package.ps1 /Scripts/

# Prepare WebDeploy (WDP) package: Remove DacFx and SQL dependencies
RUN & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:COMMERCE_CONNECT_ENGINE_PACKAGE"; `
    & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:COMMERCE_CONNECT_PACKAGE"; `
    & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:COMMERCE_MA_PACKAGE";  `
    & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:COMMERCE_XPROFILES_PACKAGE";  `
    & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:COMMERCE_XANALYTICS_PACKAGE";

# Stage 1: perform actual build
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG COMMERCE_CERT_PATH
ARG COMMERCE_CONNECT_ENGINE_PACKAGE
ARG COMMERCE_CONNECT_PACKAGE
ARG COMMERCE_MA_PACKAGE
ARG COMMERCE_XPROFILES_PACKAGE
ARG COMMERCE_XANALYTICS_PACKAGE
ARG SITE_NAME="sitecore"
ARG WEB_TRANSFORM_TOOL

COPY --from=builder /Files/CommerceSIF /Files/CommerceSIF/
COPY --from=builder /Files/${WEB_TRANSFORM_TOOL} /Files/Microsoft.Web.XmlTransform.dll
COPY --from=builder /Files/${COMMERCE_CONNECT_ENGINE_PACKAGE} /Files/
COPY --from=builder /Files/${COMMERCE_CONNECT_PACKAGE} /Files/
COPY --from=builder /Files/${COMMERCE_MA_PACKAGE} /Files/
COPY --from=builder /Files/${COMMERCE_XPROFILES_PACKAGE} /Files/
COPY --from=builder /Files/${COMMERCE_XANALYTICS_PACKAGE} /Files/
COPY files/$COMMERCE_CERT_PATH /Files/
COPY scripts/Import-Certificate.ps1 /Scripts/

# Import commerce certificate
RUN /Scripts/Import-Certificate.ps1 -certificateFile /Files/$Env:COMMERCE_CERT_PATH -secret 'secret' -storeName 'My' -storeLocation 'LocalMachine';

# Install Commerce Modules
COPY scripts/install-package.json /Scripts/
RUN Install-SitecoreConfiguration -Path "/Scripts/install-package.json" ` -Package "/Files/$Env:COMMERCE_CONNECT_ENGINE_PACKAGE" ` -SiteName $env:SITE_NAME; `
    Install-SitecoreConfiguration -Path "/Scripts/install-package.json" ` -Package "/Files/$Env:COMMERCE_CONNECT_PACKAGE" ` -SiteName $env:SITE_NAME; `
    Install-SitecoreConfiguration -Path "/Scripts/install-package.json" ` -Package "/Files/$Env:COMMERCE_MA_PACKAGE" ` -SiteName $env:SITE_NAME; `
    Install-SitecoreConfiguration -Path "/Scripts/install-package.json" ` -Package "/Files/$Env:COMMERCE_XPROFILES_PACKAGE" ` -SiteName $env:SITE_NAME; `
    Install-SitecoreConfiguration -Path "/Scripts/install-package.json" ` -Package "/Files/$Env:COMMERCE_XANALYTICS_PACKAGE" ` -SiteName $env:SITE_NAME;

# CEConnect: Post, EnableDataProvider, EnableIndexing
RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules'); `
    $env:SITE_PATH = 'c:/inetpub/wwwroot/{0}' -f $env:SITE_NAME; `
    Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/CEConnect/CEConnect.Post.json' `
    -MergeTool (Join-Path /files/ $env:WEB_TRANSFORM_TOOL) `
    -InputFile (Join-Path $env:SITE_PATH '\\MergeFiles\\Sitecore.Commerce.Engine.Connectors.Merge.Config') `
    -WebConfig (Join-Path $env:SITE_PATH '\\Web.Config'); `
    Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/CEConnect/CEConnect.EnableDataProvider.json' `
    -ConfigDir (Join-Path $env:SITE_PATH '\\App_Config\\Include\\Y.Commerce.Engine'); `
    Install-SitecoreConfiguration -Path '/Files/CommerceSIF/Configuration/Commerce/CEConnect/CEConnect.EnableIndexing.json' `
    -ConfigDir (Join-Path $env:SITE_PATH '\\App_Config\\Include\\Y.Commerce.Engine'); 

# Modify the commerce engine connection
COPY xc/sitecore/InstallCommercePackages.ps1 /Scripts/
RUN /Scripts/InstallCommercePackages.ps1;


COPY xc/sitecore/UpdateHostnames.ps1 /Scripts
COPY xc/sitecore/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-commerceHostname commerce.local -identityHostname identity" ]