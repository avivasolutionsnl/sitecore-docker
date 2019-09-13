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
COPY xc/sitecore/Install.Commerce.Modules.json /Files/CommerceSIF

COPY scripts/WebDeploy-Utilities.ps1 /Scripts/
# Remove DacFx and SQL dependencies from the WebDeploy (WDP) package which is not needed in a non-mssql container
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:COMMERCE_CONNECT_ENGINE_PACKAGE"
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:COMMERCE_CONNECT_PACKAGE"
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:COMMERCE_MA_PACKAGE"
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:COMMERCE_XPROFILES_PACKAGE"
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:COMMERCE_XANALYTICS_PACKAGE"

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
RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules'); `
    $sifConfigFile = Join-Path /files/ 'CommerceSIF/Install.Commerce.Modules.json'; `
    cd '/Files/CommerceSIF'; `
    Install-SitecoreConfiguration -Path $sifConfigFile `
    -InstallDir 'c:\\inetpub\\wwwroot\\sitecore' `
    -SiteName $Env:SITE_NAME `
    -MergeToolFullPath '/Files/Microsoft.Web.XmlTransform.dll' `
    -CEConnectWdpFullPath "/Files/$Env:COMMERCE_CONNECT_ENGINE_PACKAGE"  `
    -CommerceConnectWdpFullPath "/Files/$Env:COMMERCE_CONNECT_PACKAGE" `
    -CommerceMAWdpFullPath "/Files/$Env:COMMERCE_MA_PACKAGE"  `
    -CommercexProfilesWdpFullPath "/Files/$Env:COMMERCE_XPROFILES_PACKAGE" `
    -CommercexAnalyticsWdpFullPath "/Files/$Env:COMMERCE_XANALYTICS_PACKAGE"

# Modify the commerce engine connection
COPY xc/sitecore/InstallCommercePackages.ps1 /Scripts/
RUN /Scripts/InstallCommercePackages.ps1;


COPY xc/sitecore/UpdateHostnames.ps1 /Scripts
COPY xc/sitecore/Boot.ps1 C:/

ENTRYPOINT ["powershell", "C:/Boot.ps1"]
CMD [ "-commerceHostname commerce.local -identityHostname identity" ]