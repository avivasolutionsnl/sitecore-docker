# escape=`
# Based on https://github.com/sitecoreops/sitecore-images/blob/master/images/9.0.2%20rev.%20180604/windowsservercore-ltsc2019/sitecore-sqldev/Dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2019

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Download Links:
ENV exe "https://go.microsoft.com/fwlink/?linkid=840945"
ENV box "https://go.microsoft.com/fwlink/?linkid=840944"

ENV sa_password="_" `
    attach_dbs="[]" `
    ACCEPT_EULA="_" `
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

# make install files accessible
COPY xp/mssql/start.ps1 /
WORKDIR /

RUN Invoke-WebRequest -Uri $env:box -OutFile SQL.box; `
    Invoke-WebRequest -Uri $env:exe -OutFile SQL.exe; `
    Start-Process -Wait -FilePath .\SQL.exe -ArgumentList /qs, /x:setup; `
    .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS; `
    Remove-Item -Recurse -Force SQL.exe, SQL.box, setup;

RUN Stop-Service MSSQLSERVER; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name tcpdynamicports -Value ''; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name tcpport -Value 1433; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver' -Name LoginMode -Value 2;

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

# ABOVE HERE SHOULD BE REMOVE WHEN A 1803 VERSION IS RELEASED
ARG DB_PREFIX
ARG SITECORE_PACKAGE
ARG XCONNECT_PACKAGE
ARG HOST_NAME

ENV ACCEPT_EULA=Y
ENV sa_password=my_Sup3rSecret!!
ENV INSTALL_PATH='c:/install/'
ENV DATA_PATH='c:/data/'
ENV HOST_NAME=${HOST_NAME}
ENV DB_PREFIX=${DB_PREFIX}

COPY files/$SITECORE_PACKAGE ${INSTALL_PATH}/ 
COPY files/$XCONNECT_PACKAGE ${INSTALL_PATH}/ 

COPY xp/mssql/*.ps1 ${INSTALL_PATH}

ADD https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe C:\\Windows\\nuget.exe
RUN New-Item -Path 'C:/tools' -ItemType Directory | Out-Null; `
    & nuget install Microsoft.Data.Tools.Msbuild -Version 10.0.61710.120 -OutputDirectory c:/tools
    
RUN mkdir -p $env:DATA_PATH; `
     echo $env:DATA_PATH; `
     echo "A"; `
     & (Join-Path $env:INSTALL_PATH "Extract-Databases.ps1") -Path $env:INSTALL_PATH; `
     echo $env:INSTALL_PATH; `
     echo "B"; `
     & (Join-Path $env:INSTALL_PATH "Extract-ShardTool.ps1") -Path $env:INSTALL_PATH; `
     echo "C"; `
     echo $env:DATA_PATH; `
     echo $env:DB_PREFIX; `
     & (Join-Path $env:INSTALL_PATH "Install-Databases.ps1") -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $Env:DB_PREFIX; ` 
     echo "D"; `
     & (Join-Path $env:INSTALL_PATH "Install-Shards.ps1") -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $Env:DB_PREFIX; `
     echo "E"; `
     Get-ChildItem -Path $env:INSTALL_PATH -Exclude "*.mdf", "*.ldf" | Remove-Item -Force;

COPY xp/mssql/Boot.ps1 .
COPY xp/mssql/Persist-Databases.ps1 .

CMD C:/Boot.ps1 -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH
