# escape=`
FROM microsoft/mssql-server-windows-express:2016-sp1-windowsservercore-10.0.14393.1715

SHELL ["powershell", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop';"]

ENV ACCEPT_EULA "Y"
ENV SQL_PACKAGE_EXE='C:\Program Files (x86)\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe'
ARG DB_PREFIX
ARG HOST_NAME
# Add files
ADD files/install /Files

# Install databases
RUN $name = '{0}_MarketingAutomation' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Marketingautomation.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Processing.Pools' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Processing.pools.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_ReferenceData' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Referencedata.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Core' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Core.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Master' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Master.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Web' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Web.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Reporting' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Reporting.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `
    $name = '{0}_Processing.Tasks' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.Processing.tasks.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa'''; `       
    $name = '{0}_ExperienceForms' -f $Env:DB_PREFIX; & $Env:SQL_PACKAGE_EXE /a:Publish /sf:'c:/Files/Data/Sitecore.ExperienceForms.dacpac' /tdn:$name /tsn:$Env:COMPUTERNAME; sqlcmd -d $name -Q 'EXEC sp_changedbowner ''sa''' 

RUN $DB_NAME='{0}_Xdb.Collection.ShardMapManager' -f $Env:DB_PREFIX; `
    $SHARD_NAME_PREFIX='{0}_Xdb.Collection.Shard' -f $Env:DB_PREFIX; `
    c:/Files/Data/collectiondeployment/Sitecore.Xdb.Collection.Database.SqlShardingDeploymentTool.exe `
    /operation create `
    /connectionstring 'Server=.;Trusted_Connection=True;' `
    /dbedition Basic `
    /shardMapManagerDatabaseName "$DB_NAME" `
    /shardMapNames 'ContactIdShardMap,DeviceProfileIdShardMap,ContactIdentifiersIndexShardMap' `
    /shardnumber 2 `
    /shardnameprefix "$SHARD_NAME_PREFIX" `
    /shardnamesuffix '\"\"' `
    /dacpac 'c:/Files/Data/collectiondeployment/Sitecore.Xdb.Collection.Database.Sql.dacpac'

RUN $sqlcmd = 'UPDATE [{0}_Xdb.Collection.ShardMapManager].[__ShardManagement].[ShardsGlobal] SET ServerName = ''{1}''' -f $Env:DB_PREFIX, $Env:HOST_NAME; `
    sqlcmd -Q $sqlcmd 
