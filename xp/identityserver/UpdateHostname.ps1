
param(
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'


Function UpdateIdentityServerConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string]$defaultClientOrigin
    )

    Write-Host "Patching $configPath"

    $xml = [xml](Get-Content $configPath)
    $xml.Settings.Sitecore.IdentityServer.Clients.DefaultClient.AllowedCorsOrigins.AllowedCorsOriginsGroup1 = $defaultClientOrigin
    $xml.Save($configPath);
    
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

UpdateIdentityServerConfig -configPath "C:\inetpub\wwwroot\identity\Config\production\Sitecore.IdentityServer.Host.xml" -defaultClientOrigin "http://$sitecoreHostname"
