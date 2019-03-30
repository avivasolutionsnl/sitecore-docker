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
echo "1"
echo $InstallPath
echo $env:COMPUTERNAME
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $InstallPath
$server.Properties["DefaultLog"].Value = $InstallPath
$server.Alter()
echo "2"
$sqlPackageExePath = Get-Item "C:\tools\*\lib\net46\SqlPackage.exe" | Select-Object -Last 1 -Property FullName -ExpandProperty FullName
echo "3"
Write-Host "Using: $sqlPackageExePath"

Push-Location -Path $InstallPath

(Get-ChildItem -Path $InstallPath -Filter "*.dacpac" | Where-Object { !($_.Name -like "*Xdb*") }) | ForEach-Object {
    $databaseName = $_.BaseName.Replace("Sitecore.", "$DatabasePrefix`_").Replace(".Database.Sql", ".ShardMapManager")
    echo $databaseName
    $dacpacPath = ".\{0}" -f $_.Name
    echo $dacpacPath
    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q
    echo "Installed"
    # Detach
    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false'"
    echo "Detached"
}

Pop-Location
echo "4"
echo $DataPath
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $DataPath
$server.Properties["DefaultLog"].Value = $DataPath
$server.Alter()
