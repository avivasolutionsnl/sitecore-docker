Param(
    [Parameter(Mandatory = $true)]
    [String]$commerceHostname
)

Function UpdateCommerceConfig() {
    param(
        [Parameter(Mandatory = $true)]
        [String]$commerceHostname
    )

    # Modify the commerce engine connection
    $engineConnectIncludeDir = 'c:\\inetpub\\wwwroot\\sitecore\\App_Config\\Include\\Y.Commerce.Engine'
    $configPath = $(Join-Path -Path $engineConnectIncludeDir -ChildPath "\Sitecore.Commerce.Engine.Connect.config")

    Write-Host "Patching $configPath with $commerceHostname"
    $xml = [xml](Get-Content $configPath)
    $node = $xml.configuration.sitecore.commerceEngineConfiguration
    $node.shopsServiceUrl = "https://$commerceHostname" + ":5000/api/"
    $node.commerceOpsServiceUrl = "https://$commerceHostname" + ":5000/commerceops/"
    $xml.Save($configPath);
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

UpdateCommerceConfig -commerceHostname $commerceHostname