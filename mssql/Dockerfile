# escape=`

# Stage 0: prepare files
FROM microsoft/aspnet:4.7.1-windowsservercore-1709 AS prepare

ARG SITECORE_PACKAGE
ARG XCONNECT_PACKAGE
ARG COMMERCE_SDK_PACKAGE
ARG COMMERCE_SIF_PACKAGE

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ADD files/ /Files/

RUN Expand-Archive -Path /Files/$Env:COMMERCE_SDK_PACKAGE -DestinationPath /Files/Commerce
RUN Expand-Archive -Path /Files/$Env:COMMERCE_SIF_PACKAGE -DestinationPath /Files/CommerceSIF
RUN Expand-Archive -Path /Files/$Env:SITECORE_PACKAGE -DestinationPath /Files/Sitecore 
RUN Expand-Archive -Path /Files/$Env:XCONNECT_PACKAGE -DestinationPath /Files/Xconnect 


# Stage 1: create actual image
FROM microsoft/mssql-server-windows-express:2016-sp1-windowsservercore-10.0.14393.1715

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ARG DB_PREFIX
ARG HOST_NAME

ENV ACCEPT_EULA "Y"
ENV SQL_PACKAGE_EXE='C:\Program Files (x86)\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe'

# Add files
COPY --from=prepare /Files/Commerce /Files/Commerce/
COPY --from=prepare /Files/CommerceSIF /Files/CommerceSIF/
COPY --from=prepare /Files/Sitecore /Files/Sitecore/
COPY --from=prepare /Files/Xconnect /Files/Xconnect/

# Install databases
RUN $name = '{0}_MarketingAutomation' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Marketingautomation.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Processing.Pools' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Processing.pools.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_ReferenceData' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Referencedata.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Core' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Core.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Master' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Master.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Web' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Web.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Reporting' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Reporting.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `
    $name = '{0}_Processing.Tasks' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.Processing.tasks.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; `       
    $name = '{0}_ExperienceForms' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Sitecore/Sitecore.ExperienceForms.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME 

RUN $DB_NAME='{0}_Xdb.Collection.ShardMapManager' -f $Env:DB_PREFIX; `
    $SHARD_NAME_PREFIX='{0}_Xdb.Collection.Shard' -f $Env:DB_PREFIX; `
    /Files/Xconnect/Content/Website/App_data/collectiondeployment/Sitecore.Xdb.Collection.Database.SqlShardingDeploymentTool.exe `
    /operation create `
    /connectionstring 'Server=.;Trusted_Connection=True;' `
    /dbedition Basic `
    /shardMapManagerDatabaseName "$DB_NAME" `
    /shardMapNames 'ContactIdShardMap,DeviceProfileIdShardMap,ContactIdentifiersIndexShardMap' `
    /shardnumber 2 `
    /shardnameprefix "$SHARD_NAME_PREFIX" ` 
    /shardnamesuffix '\"\"' `
    /dacpac '/Files/Xconnect/Content/Website/App_data/collectiondeployment/Sitecore.Xdb.Collection.Database.Sql.dacpac'

RUN $sqlcmd = 'UPDATE [{0}_Xdb.Collection.ShardMapManager].[__ShardManagement].[ShardsGlobal] SET ServerName = ''{1}''' -f $Env:DB_PREFIX, $Env:HOST_NAME; `
    sqlcmd -Q $sqlcmd 

# Install commerce engine databases
RUN & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Commerce/Sitecore.Commerce.Engine.DB.dacpac' /tdn:SitecoreCommerce9_SharedEnvironments /tsn:$Env:COMPUTERNAME
RUN & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Commerce/Sitecore.Commerce.Engine.DB.dacpac' /tdn:SitecoreCommerce9_Global /tsn:$Env:COMPUTERNAME

RUN sqlcmd -Q \"EXEC sp_MSforeachdb 'IF charindex(''Sitecore'', ''?'' ) = 1 BEGIN EXEC [?]..sp_changedbowner ''sa'' END'\" 

RUN Add-WindowsFeature Web-Server

ADD scripts /Scripts
RUN /Scripts/Install-SIF.ps1

RUN [Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath + ';/Files/CommerceSIF/Modules'); `
    $connStr = 'Data Source=.;Initial Catalog={0}_Core;Integrated Security=True;' -f $Env:DB_PREFIX; `
    Install-SitecoreConfiguration -Path "C:\\Files\\CommerceSIF\\Configuration\\Commerce\\CommerceEngine\\CommerceEngine.UserRoles.json" `
    -ConnectionString $connStr
