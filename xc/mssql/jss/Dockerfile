# escape=`
ARG BASE_IMAGE
FROM $BASE_IMAGE

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG JSS_PACKAGE

COPY files/$JSS_PACKAGE ${INSTALL_PATH}/
COPY scripts/database/Extract-Databases.ps1 ${INSTALL_PATH}/
COPY scripts/database/Install-Databases.ps1 ${INSTALL_PATH}/

RUN & (Join-Path $env:INSTALL_PATH "\\Extract-Databases.ps1") -Path $env:INSTALL_PATH; `
    & (Join-Path $env:INSTALL_PATH "\\Install-Databases.ps1") -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $env:DB_PREFIX; ` 
    Get-ChildItem -Path $env:INSTALL_PATH -Exclude '*.mdf', '*.ldf' -Recurse -Force | Remove-Item -Recurse -Force;
