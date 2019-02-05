[CmdletBinding()]
param(
    [string]$InstallPath = $env:INSTALL_PATH,
    [string]$DataPath = $env:DATA_PATH
)

Get-ChildItem -Path $DataPath -Filter "*.mdf" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("_Primary", "").Replace("_primary", "")
    $mdfPath = $_.FullName
    $ldfPath = $mdfPath.Replace(".mdf", ".ldf")

    # https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-detach-db-transact-sql?view=sql-server-2017
    Write-Host "### Detaching '$databaseName'..."
    $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '$databaseName') BEGIN EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false', @skipchecks = N'true' END;"
    Invoke-Sqlcmd -Query $sqlcmd

    Write-Host "### Moving '$mdfPath' and '$ldfPath' to '$InstallPath'"
    Move-Item $mdfPath -Destination $InstallPath -Force
    Move-Item $ldfPath -Destination $InstallPath -Force
}
