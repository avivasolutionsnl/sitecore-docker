[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$InstallPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$DataPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()] 
    [string]$DatabasePrefix
)

$DbNameManager='{0}_Xdb.Collection.ShardMapManager' -f $DatabasePrefix;
$ShardNamePrefix='{0}_Xdb.Collection.Shard' -f $DatabasePrefix;
$DbShard0='{0}0' -f $ShardNamePrefix;
$DbShard1='{0}1' -f $ShardNamePrefix;

$DacPac = Join-Path $InstallPath "Sitecore.Xdb.Collection.Database.Sql.dacpac"; `
$Tool = Join-Path $InstallPath "Sitecore.Xdb.Collection.Database.SqlShardingDeploymentTool.exe"

& $Tool /operation create /connectionstring 'Server=.;Trusted_Connection=True;' /dbedition Basic /shardMapManagerDatabaseName "$DbNameManager" /shardMapNames 'ContactIdShardMap,DeviceProfileIdShardMap,ContactIdentifiersIndexShardMap' /shardnumber 2 /shardnameprefix "$ShardNamePrefix" /shardnamesuffix '""' /dacpac "$DacPac";

# Detach
Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$DbNameManager', @keepfulltextindexfile = N'false'"
Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'Sitecore_Xdb.Collection.Shard0', @keepfulltextindexfile = N'false'"
Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'Sitecore_Xdb.Collection.Shard1', @keepfulltextindexfile = N'false'"

# Get db path
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$dbFilePath = $server.Properties["DefaultFile"].Value

Push-Location -Path $dbFilePath

# Remove _log postfix
Move-Item ${DbNameManager}_log.ldf -Destination "${DbNameManager}.ldf"
Move-Item ${DbShard0}_log.ldf -Destination "${DbShard0}.ldf"
Move-Item ${DbShard1}_log.ldf -Destination "${DbShard1}.ldf"

# Move to installation dir
Move-Item "${DbNameManager}.*" -Destination $InstallPath
Move-Item "${DbShard0}.*" -Destination $InstallPath
Move-Item "${DbShard1}.*" -Destination $InstallPath

Pop-Location
