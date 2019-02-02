[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$Path
)

#Extract
Add-Type -Assembly "System.IO.Compression.FileSystem"

$tempPath = Join-Path $Path "temp"
Expand-Archive -Path (Join-Path $Path "*SIF.Sitecore.Commerce*.zip") -DestinationPath $tempPath

# Copy utilities
Move-Item (Join-Path $tempPath "SiteUtilityPages") -Destination $Path

$tempModulePath = Join-Path $tempPath "Modules"
Move-Item (Join-Path $tempModulePath "SitecoreUtilityTasks") -Destination (Join-Path $Path "SitecoreUtilityTasks/Modules")

# Cleanup
Remove-Item -Recurse $tempPath
