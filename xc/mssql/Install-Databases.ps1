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

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $InstallPath
$server.Properties["DefaultLog"].Value = $InstallPath
$server.Alter()

$sqlPackageExePath = Get-Item "C:\tools\*\lib\net46\SqlPackage.exe" | Select-Object -Last 1 -Property FullName -ExpandProperty FullName

Write-Host "Using: $sqlPackageExePath"

Push-Location -Path $InstallPath

(Get-ChildItem -Path $InstallPath -Filter "*.dacpac" | Where-Object { ($_.Name -like "*Sitecore.Commerce.Engine*") }) | ForEach-Object {
    $dacpacPath = ".\{0}" -f $_.Name
    
    $sharedDatabaseName = "$DatabasePrefix`_SharedEnvironments"
    $globalDatabaseName = "$DatabasePrefix`_Global"

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$sharedDatabaseName /tsn:$env:COMPUTERNAME /q
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$globalDatabaseName /tsn:$env:COMPUTERNAME /q

    # Detach
    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$sharedDatabaseName', @keepfulltextindexfile = N'false'"
    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$globalDatabaseName', @keepfulltextindexfile = N'false'"
}

Pop-Location

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $DataPath
$server.Properties["DefaultLog"].Value = $DataPath
$server.Alter()