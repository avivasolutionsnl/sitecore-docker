Param(
    [Parameter(Mandatory = $true)]
    [String]$commerceHostname,
    [Parameter(Mandatory = $true)]
    [String]$identityHostname
)

Function UpdateIdentityConfig() {
    param(
        [Parameter(Mandatory = $true)]
        [String]$identityHostname
    )

    # Modify the commerce engine connection
    $identityServerDir = 'c:\\inetpub\\wwwroot\\sitecore\\App_Config\\Sitecore\\Owin.Authentication.IdentityServer'
    $configPath = $(Join-Path -Path $identityServerDir -ChildPath "\Sitecore.Owin.Authentication.IdentityServer.config")

    Write-Host "Patching $configPath with $commerceHostname"
    $xml = [xml](Get-Content $configPath)
    $node = $xml.SelectSingleNode('//sc.variable[@name="identityServerAuthority"]')
    $node.value =  "https://$identityHostname"
    $xml.Save($configPath);
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

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

UpdateIdentityConfig -identityHostname $identityHostname
UpdateCommerceConfig -commerceHostname $commerceHostname