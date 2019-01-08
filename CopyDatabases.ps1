[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Container = 'sitecore-docker_mssql_1',
    [Parameter(Mandatory=$false)]
    [string]$FromDatabaseFilePath = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA',
    [Parameter(Mandatory=$false)]
    [string]$ToDatabaseFilePath = 'databases/'
)

mkdir -Force -Path ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Core_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Core_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_ExperienceForms_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_ExperienceForms_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_MarketingAutomation_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_MarketingAutomation_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Master_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Master_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Processing.Pools_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Processing.Pools_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Processing.Tasks_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Processing.Tasks_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_ReferenceData_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_ReferenceData_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Master_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Master_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Reporting_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Reporting_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Web_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Web_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.Shard0.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.Shard0_log.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.Shard1_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.Shard1_Primary.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.ShardMapManager.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Xdb.Collection.ShardMapManager_log.ldf ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Messaging_Primary.mdf ${ToDatabaseFilePath}
docker cp ${Container}:${FromDatabaseFilePath}\Sitecore_Messaging_Primary.ldf ${ToDatabaseFilePath}
