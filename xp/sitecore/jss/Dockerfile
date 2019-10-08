# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as builder

ARG JSS_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

COPY files/ /Files/

COPY scripts/Clear-Package.ps1 /Scripts/

# Prepare WebDeploy (WDP) package: Remove DacFx and SQL dependencies
RUN & "/Scripts/Clear-Package.ps1" -Path "/Files/$Env:JSS_PACKAGE";

# Stage 1: perform actual build
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG JSS_PACKAGE
ARG SITE_NAME="sitecore"

COPY --from=builder /Files/${JSS_PACKAGE} /Files/

COPY scripts/install-package.json /Scripts/

# Install NodeJS
RUN choco install -y --params="Quiet" --version 11.10.0 nodejs; 

# Install JSS Module
RUN Install-SitecoreConfiguration -Path "/Scripts/install-package.json" `
    -Package "/Files/$Env:JSS_PACKAGE" `
    -SiteName $env:SITE_NAME;

ENTRYPOINT ["powershell", "C:/Boot.ps1"]