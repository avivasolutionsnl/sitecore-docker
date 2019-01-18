# escape=`

# Stage 0: prepare files
ARG BASE_IMAGE
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

ARG COMMERCE_SDK_PACKAGE
ARG COMMERCE_SIF_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ADD files/ /Files/

RUN Expand-Archive -Force -Path /Files/$Env:COMMERCE_SDK_PACKAGE -DestinationPath /Files/Commerce; `
    Expand-Archive -Force -Path /Files/$Env:COMMERCE_SIF_PACKAGE -DestinationPath /Files/CommerceSIF


# Stage 1: create actual image
FROM ${BASE_IMAGE}

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ARG DB_PREFIX

ENV SQL_PACKAGE_EXE='C:\Program Files (x86)\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe'

# Add files
COPY --from=prepare /Files/Commerce /Files/Commerce/
COPY --from=prepare /Files/CommerceSIF /Files/CommerceSIF/

# Install commerce engine databases
RUN & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Commerce/Sitecore.Commerce.Engine.DB.dacpac' /tdn:SitecoreCommerce9_SharedEnvironments /tsn:$Env:COMPUTERNAME
RUN & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Commerce/Sitecore.Commerce.Engine.DB.dacpac' /tdn:SitecoreCommerce9_Global /tsn:$Env:COMPUTERNAME

RUN sqlcmd -Q \"EXEC sp_MSforeachdb 'IF charindex(''Sitecore'', ''?'' ) = 1 BEGIN EXEC [?]..sp_changedbowner ''sa'' END'\" 