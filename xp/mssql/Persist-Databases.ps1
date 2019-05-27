[CmdletBinding()]
param(
    [string]$InstallPath = $env:INSTALL_PATH,
    [string]$DataPath = $env:DATA_PATH
)

Get-ChildItem -Path $DataPath -Filter "*.mdf" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("_Primary", "").Replace("_primary", "")
    $mdfPath = $_.FullName
    $ldfPath = $mdfPath.Replace(".mdf", ".ldf")

    Write-Host "### Setting single user for [$databaseName]..."
    Invoke-Sqlcmd -Query "ALTER DATABASE [$databaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE"

    Write-Host "### Detaching '$databaseName'..."
    $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '$databaseName') BEGIN EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false', @skipchecks = N'true' END;"
    Invoke-Sqlcmd -Query $sqlcmd
    if ( -Not $?) {
        $msg = $Error[0].Exception.Message
        throw "Encountered a error while executing a sql query: $msg"
    }

    Write-Host "### Moving '$mdfPath' and '$ldfPath' to '$InstallPath'"
    Move-Item $mdfPath -Destination $InstallPath -Force
    Move-Item $ldfPath -Destination $InstallPath -Force
}

if (!((Get-ChildItem $DataPath | Measure-Object).Count -eq 0)) {
    throw "Something went wrong during persisting the databases as $DataPath is not empty"
}
