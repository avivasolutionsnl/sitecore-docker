[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$FromPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$ToPath
)

#Extract
Add-Type -Assembly "System.IO.Compression.FileSystem"

$tempPath = Join-Path $ToPath "temp"
Expand-Archive -Path (Join-Path $FromPath "*SIF.Sitecore.Commerce*.zip") -DestinationPath $tempPath -Force

# Copy utilities
Move-Item (Join-Path $tempPath "SiteUtilityPages") -Destination $ToPath -Force

$tempModulePath = Join-Path $tempPath "Modules"
$from = Join-Path $tempModulePath "SitecoreUtilityTasks"
$to = Join-Path $ToPath "Modules"

mkdir -Path $to 2>$null

Move-Item $from -Destination $to -Force

# Cleanup
Remove-Item -Recurse $tempPath -Force
