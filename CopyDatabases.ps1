[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Container = 'sitecore-xp_mssql_1',
    [Parameter(Mandatory=$false)]
    [string]$FromDatabaseFilePath = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLEXPRESS\MSSQL\DATA',
    [Parameter(Mandatory=$false)]
    [string]$ToDatabaseFilePath = 'databases/'
)

mkdir -Force -Path ${ToDatabaseFilePath}

docker cp ${Container}:${FromDatabaseFilePath} ${ToDatabaseFilePath}

mv -Force ${ToDatabaseFilePath}/DATA/* ${ToDatabaseFilePath}
rm -Recurse ${ToDatabaseFilePath}/DATA
