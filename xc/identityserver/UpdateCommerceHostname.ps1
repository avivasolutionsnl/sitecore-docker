
param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostName
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'


Function UpdateIdentityServerCommerceConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string]$commerceHostName
    )

    Write-Host "Patching $configPath"

    $allowedCors = "http://${commerceHostName}:4200|https://${commerceHostName}:4200|http://${commerceHostName}:5000|https://${commerceHostName}:5000"

    $xml = [xml](Get-Content $configPath)
    $xml.Settings.Sitecore.IdentityServer.Clients.CommerceClient.AllowedCorsOrigins.AllowedCorsOriginsGroup1 = $allowedCors
    $xml.Save($configPath);
    
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

Function UpdateIdentityServerPlumberConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string]$commerceHostName
    )

    Write-Host "Patching $configPath"

    $allowedCors = "http://${commerceHostName}:4000"

    $xml = [xml](Get-Content $configPath)
    $xml.Settings.Sitecore.IdentityServer.Clients.PlumberClient.AllowedCorsOrigins.AllowedCorsOrigins1 = $allowedCors
    $xml.Save($configPath);
    
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

UpdateIdentityServerCommerceConfig -configPath "C:\inetpub\wwwroot\identity\Config\production\Sitecore.Commerce.IdentityServer.Host.xml" -commerceHostName $commerceHostName
UpdateIdentityServerPlumberConfig -configPath "C:\inetpub\wwwroot\identity\Config\production\Sitecore.Plumber.IdentityServer.Host.xml" -commerceHostName $commerceHostName
