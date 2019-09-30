# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as builder

ARG PSE_PACKAGE
ARG SXA_PACKAGE
ARG SCXA_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY files/ /Files/

COPY xc/sitecore/sxa/install-sxa.json /Files

COPY scripts/WebDeploy-Utilities.ps1 /Scripts/
# Remove DacFx and SQL dependencies from the WebDeploy (WDP) package which is not needed in a non-mssql container
RUN . /Scripts/WebDeploy-Utilities.ps1; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:PSE_PACKAGE"; `
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:SXA_PACKAGE";`
    RemoveDbDacFxDependencies -WdpFullpath "/Files/$Env:SCXA_PACKAGE";

# Stage 1: perform actual build
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG PSE_PACKAGE
ARG SXA_PACKAGE
ARG SCXA_PACKAGE
ARG SITE_NAME="sitecore"

COPY --from=builder /Files/install-sxa.json /Files/install-sxa.json
COPY --from=builder /Files/${PSE_PACKAGE} /Files/
COPY --from=builder /Files/${SXA_PACKAGE} /Files/
COPY --from=builder /Files/${SCXA_PACKAGE} /Files/

# Install SXA Modules
RUN $sifConfigFile = Join-Path /files/ 'install-sxa.json'; `
    Install-SitecoreConfiguration -Path $sifConfigFile `
    -SiteName $Env:SITE_NAME `
    -PowershellExtensionsWdpFullPath "/Files/$Env:PSE_PACKAGE"  `
    -SXAFrameworkWdpFullPath "/Files/$Env:SXA_PACKAGE" `
    -SXACommerceWdpFullPath "/Files/$Env:SCXA_PACKAGE"

ENTRYPOINT ["powershell", "C:/Boot.ps1"]