# escape=`
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SQL_DB_PREFIX
ARG COMMERCE_DB_PREFIX
ARG COMMERCE_ENGINE_PACKAGE
ARG COMMERCE_CONNECT_ENGINE_PACKAGE
ARG COMMERCE_CONNECT_PACKAGE
ARG COMMERCE_MA_PACKAGE
ARG COMMERCE_XPROFILES_PACKAGE
ARG COMMERCE_XANALYTICS_PACKAGE
ARG COMMERCE_SIF_PACKAGE

ENV COMMERCE_DB_PREFIX=${COMMERCE_DB_PREFIX}

COPY files/$COMMERCE_ENGINE_PACKAGE ${INSTALL_PATH}/
COPY files/$COMMERCE_CONNECT_PACKAGE ${INSTALL_PATH}/
COPY files/$COMMERCE_CONNECT_ENGINE_PACKAGE ${INSTALL_PATH}/
COPY files/$COMMERCE_MA_PACKAGE ${INSTALL_PATH}/
COPY files/$COMMERCE_XPROFILES_PACKAGE ${INSTALL_PATH}/
COPY files/$COMMERCE_XANALYTICS_PACKAGE ${INSTALL_PATH}/
COPY xc/mssql/*.ps1 ${INSTALL_PATH}
COPY xc/mssql/RebuildDescendants.sql ${INSTALL_PATH}
COPY files/$COMMERCE_SIF_PACKAGE ${INSTALL_PATH}
COPY scripts/Install-SIF.ps1 ${INSTALL_PATH}

# Install SIF
RUN & (Join-Path $Env:INSTALL_PATH "Install-SIF.ps1");

RUN & (Join-Path $env:INSTALL_PATH "Attach-Databases.ps1"); ` 
    # Install databases from WDP packages
    & (Join-Path $env:INSTALL_PATH "Extract-Databases.ps1") -Path $env:INSTALL_PATH; `
    & (Join-Path $env:INSTALL_PATH "Install-Databases.ps1") -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $Env:SQL_DB_PREFIX -CommerceDatabasePrefix $Env:COMMERCE_DB_PREFIX; `
    # Extract Commerce SIF
    Expand-Archive (Join-Path $Env:INSTALL_PATH $Env:COMMERCE_SIF_PACKAGE) -DestinationPath (Join-Path $Env:INSTALL_PATH "SIF.Sitecore.Commerce"); `    
    [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + (';{0}/SIF.Sitecore.Commerce/Modules' -f (Get-Item $Env:INSTALL_PATH).BaseName)); `
    # Customize Commerce Users and Roles SIF config:
    # Add extra ConnectionString parameter to be able to use Integrated Security connection string.
    # 'sa' login is disabled during docker build and the SIF installation won't be able to connect using the connection string with login.
    $usersAndRolesConfig = (Join-Path $Env:INSTALL_PATH "SIF.Sitecore.Commerce/Configuration/Commerce/CEConnect/CEConnect.UsersAndRoles.json"); `
    $json = (Get-Content $usersAndRolesConfig) -replace '^\s*//.*' | Out-String | ConvertFrom-Json; `
    $json.Variables.ConnectionString = '[parameter(''ConnectionString'')]'; `
    $json.Parameters | Add-Member -Name 'ConnectionString' -Value @{'Type' = 'string'; 'Description' = 'Connectionstring of the database'; 'DefaultValue' = ''} -MemberType NoteProperty; `
    $json = ConvertTo-Json $json -Depth 100; `
    Set-Content $usersAndRolesConfig -Value $json -Encoding UTF8; `
    # Add Commerce Users and Roles
    Install-SitecoreConfiguration -Path $usersAndRolesConfig `
    -ConnectionString ("'Data Source=.;Initial Catalog={0}_Core;Integrated Security=true;'" -f $Env:SQL_DB_PREFIX); `
    # Rebuild Descendants task
    $env:MasterDatase = '{0}_Master' -f $Env:SQL_DB_PREFIX; `
    Invoke-Sqlcmd -Database $Env:MasterDatase -InputFile (Join-Path $env:INSTALL_PATH "RebuildDescendants.sql"); `
    & (Join-Path $env:INSTALL_PATH "Detach-Databases.ps1"); `    
    Get-ChildItem -Path $env:INSTALL_PATH -Exclude "*.mdf", "*.ldf" | Remove-Item -Force -Recurse;