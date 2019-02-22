[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$InstallPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$DataPath
)

$noDatabases = (Get-ChildItem -Path $DataPath -Filter "*.mdf") -eq $null

if ($noDatabases)
{
    Write-Host "### Sitecore databases not found in '$DataPath', seeding clean databases..."

    Get-ChildItem -Path $InstallPath | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $DataPath
    }
}
else
{
    Write-Host "### Existing Sitecore databases found in '$DataPath'..."
}

Get-ChildItem -Path $DataPath -Filter "*.mdf" | ForEach-Object {
    # Replace case-insensitive,
    # Move-Item removes casing: https://stackoverflow.com/questions/54437210/move-item-and-preserve-filename-casing?noredirect=1#comment95683944_54437210
    $databaseName = $_.BaseName.Replace("_Primary", "").Replace("_primary", "")
    $mdfPath = $_.FullName
    $ldfPath = $mdfPath.Replace(".mdf", ".ldf")

    $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '$databaseName') BEGIN EXEC sp_detach_db [$databaseName] END;CREATE DATABASE [$databaseName] ON (FILENAME = N'$mdfPath'), (FILENAME = N'$ldfPath') FOR ATTACH;"

    Write-Host "### Attaching '$databaseName'..."

    try {
        Invoke-Sqlcmd -Query $sqlcmd
    } catch {
        Write-Host "### Repairing '$databaseName'..."

        $repairCmd = "ALTER DATABASE $databaseName SET EMERGENCY; GO DBCC CHECKDB ($databaseName, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS; GO";
        Invoke-Sqlcmd -Query $repairCmd
    }
}

# See http://jonnekats.nl/2017/sql-connection-issue-xconnect/
$DbNameManager='{0}_Xdb.Collection.ShardMapManager' -f $env:DB_PREFIX;
$sqlcmd = 'UPDATE [{0}].[__ShardManagement].[ShardsGlobal] SET ServerName = ''{1}''' -f $DbNameManager, $env:HOST_NAME;
Invoke-Sqlcmd -Query $sqlcmd

$sqlcmd = "EXEC sp_MSforeachdb 'IF charindex(''{0}'', ''?'' ) = 1 BEGIN EXEC [?]..sp_changedbowner ''sa'' END'" -f $env:DB_PREFIX;
Invoke-Sqlcmd -Query $sqlcmd

# Dbs are now ready
Write-Host "### Sitecore databases ready!"

# Call Start.ps1 from the base image https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-developer/dockerfile
& C:\Start.ps1 -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -Verbose
