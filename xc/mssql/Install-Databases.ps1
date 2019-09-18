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
    [string]$DatabasePrefix,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()] 
    [string]$CommerceDatabasePrefix
)

# Make sure SQL server is running
Start-Service MSSQLSERVER;
(Get-Service MSSQLSERVER).WaitForStatus('Running');

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $InstallPath
$server.Properties["DefaultLog"].Value = $InstallPath
$server.Alter()

$sqlPackageExePath = Get-Item "C:\tools\*\lib\net46\SqlPackage.exe" | Select-Object -Last 1 -Property FullName -ExpandProperty FullName

Write-Host "Using: $sqlPackageExePath"

Push-Location -Path $InstallPath

# attach
Get-ChildItem -Path $InstallPath -Filter "*.mdf" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("_Primary", "")
    $mdfPath = $_.FullName
    $ldfPath = $mdfPath.Replace(".mdf", ".ldf")
    $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '$databaseName') BEGIN EXEC sp_detach_db [$databaseName] END;CREATE DATABASE [$databaseName] ON (FILENAME = N'$mdfPath'), (FILENAME = N'$ldfPath') FOR ATTACH;"

    Write-Host "### Attaching '$databaseName'..."

    Invoke-Sqlcmd -Query $sqlcmd
}

# do Sitecore Commerce Global DB
Get-ChildItem -Path $InstallPath -Include "Sitecore.Commerce.Engine.Global.DB.dacpac" -Recurse | ForEach-Object {
    $dacpacPath = $_.FullName
    $databaseName = "$CommerceDatabasePrefix`_Global"

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q
}

# do Sitecore Commerce SharedEnvironments DB
Get-ChildItem -Path $InstallPath -Include "Sitecore.Commerce.Engine.Shared.DB.dacpac" -Recurse | ForEach-Object {
    $dacpacPath = $_.FullName
    $databaseName = "$CommerceDatabasePrefix`_SharedEnvironments"

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q
}

# do modules
$TextInfo = (Get-Culture).TextInfo
Get-ChildItem -Path $InstallPath -Include "core.dacpac", "master.dacpac" -Recurse | ForEach-Object {
    $dacpacPath = $_.FullName
    $databaseName = "$DatabasePrefix`_" + $TextInfo.ToTitleCase($_.BaseName)

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q
}

# detach DB
Get-ChildItem -Path $InstallPath -Filter "*.mdf" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("_Primary", "")

    Write-Host "### Detaching '$databaseName'..."

    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false'"
}

Pop-Location

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $DataPath
$server.Properties["DefaultLog"].Value = $DataPath
$server.Alter()