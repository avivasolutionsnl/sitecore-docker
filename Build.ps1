[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [string]$archive = "Sitecore.zip",
    [Parameter(Mandatory=$True)]
    [string]$license = "license.xml"
)

Expand-Archive $archive -DestinationPath 'extract';
Move-Item 'extract\Sitecore*\Data' 'sitecore\Data' -Force;
Move-Item 'extract\Sitecore*\Databases' 'mssql\Databases' -Force;
Move-Item 'extract\Sitecore*\Website' 'sitecore\Website' -Force;
Remove-Item 'extract' -Recurse -Force;

Copy-Item $license 'sitecore\Data\' -Force;

# Build Sitecore Docker image
cd sitecore
docker build -t sitecore .
cd ..

# Build MS SQL Docker image with Sitecore databases
cd mssql
docker build -t mssql-sitecore .
cd ..
