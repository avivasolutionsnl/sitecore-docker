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

(Get-ChildItem -Path $InstallPath -Filter "*.dacpac" | Where-Object { !($_.Name -like "*Xdb*") }) | ForEach-Object {
    $databaseName = $_.BaseName.Replace("Sitecore.", "$DatabasePrefix`_").Replace(".Database.Sql", ".ShardMapManager")
    $dacpacPath = ".\{0}" -f $_.Name

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q

    # Detach
    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false'"
}

Pop-Location

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $DataPath
$server.Properties["DefaultLog"].Value = $DataPath
$server.Alter()
