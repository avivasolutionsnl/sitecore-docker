# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG COMMERCE_SDK_PACKAGE
ARG COMMERCE_DB_PREFIX

ENV COMMERCE_DB_PREFIX=${COMMERCE_DB_PREFIX}

COPY files/$COMMERCE_SDK_PACKAGE ${INSTALL_PATH}/
COPY xc/mssql/*.ps1 ${INSTALL_PATH}

RUN & (Join-Path $env:INSTALL_PATH "Extract-Databases.ps1") -Path $env:INSTALL_PATH; `
    & (Join-Path $env:INSTALL_PATH "Install-Databases.ps1") -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $Env:COMMERCE_DB_PREFIX; `
    Get-ChildItem -Path $env:INSTALL_PATH -Exclude "*.mdf", "*.ldf" | Remove-Item -Force;
