#Requires -RunAsAdministrator

param(
    [String]$hostname = "commerce.localhost"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

#Modify the certificate for the binding
$certificates = Get-ChildItem -Path 'cert:\localmachine\my' -DnsName 'DO_NOT_TRUST_SitecoreRootCert';
$hostnames = [string[]]@(
    ("$hostname")
)

$rootCert = $certificates[0];
Write-Host "Creating a new certificate with hostnames $hostnames"
$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $hostnames -Signer $rootcert -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider';
Write-Host "Succesfully created the certificate!. Updating bindings..." -ForegroundColor Green

$updateBindingCertifcate = "$PSScriptRoot/UpdateBindingCertificate.ps1"

& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceOps_Sc9' -port 5015
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceShops_Sc9' -port 5005
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceAuthoring_Sc9' -port 5000 
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceMinions_Sc9'-port 5010
& $updateBindingCertifcate -certificate $certificate -bindingName 'SitecoreBizFx' -port 4200
& $updateBindingCertifcate -certificate $certificate -bindingName 'SitecoreIdentityServer' -port 5050

$baseUrl = "https://$hostname"
$identityServerUrl = $baseUrl + ":5050"
$engineServerUrl = $baseUrl + ":5000"
$bizFxUrl = $baseUrl + ":4200"
$urls = @(
    ($bizFxUrl),
    ($bizFxUrl + "/?")
)
$allowedOrigins = @(
    "http://sitecore",
    ($bizFxUrl),
    ($bizFxUrl + "/?")
)
#Patch the bizfx config
$pathToBizfxConfig = "C:\inetpub\wwwroot\SitecoreBizFx\assets\config.json"
Write-Host "Patching $pathToBizfxConfig with $commerceUrl"

$json = Get-Content $pathToBizfxConfig -raw | ConvertFrom-Json; 
$json.BizFxUri = $bizFxUrl
$json.IdentityServerUri = $identityServerUrl
$json.EngineUri = $engineServerUrl
$json | ConvertTo-Json | set-content $pathToBizfxConfig

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToBizfxConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToBizfxConfig!" -ForegroundColor Green

#Patch the sitecore identity server config
$pathToIdentityServerConfig = "C:\inetpub\wwwroot\SitecoreIdentityServer\wwwroot\appsettings.json"

Write-Host "Patching $pathToIdentityServerConfig with $urls"

$json = Get-Content $pathToIdentityServerConfig -raw | ConvertFrom-Json; 
foreach ($p in $json.AppSettings.Clients) {
    if($p.ClientId -eq "CommerceBusinessTools"){
        $p.RedirectUris = $urls
        $p.PostLogoutRedirectUris = $urls
        $p.AllowedCorsOrigins = $urls
    }
}

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToIdentityServerConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToIdentityServerConfig!" -ForegroundColor Green

#Patch the commerce engine config
$pathToCommerceEngineConfig = "C:\inetpub\wwwroot\CommerceAuthoring_Sc9\wwwroot\config.json"
Write-Host "Patching $pathToCommerceEngineConfig with $urls"
$json = Get-Content $pathToCommerceEngineConfig -raw | ConvertFrom-Json;
$json.AppSettings.AllowedOrigins = $urls
$json.AppSettings.SitecoreIdentityServerUrl = $identityServerUrl
$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToCommerceEngineConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToCommerceEngineConfig!" -ForegroundColor Green

#Patch the commerce ops config
$pathToCommerceOpsConfig = "C:\inetpub\wwwroot\CommerceOps_Sc9\wwwroot\config.json"
Write-Host "Patching $pathToCommerceOpsConfig with $urls"
$json = Get-Content $pathToCommerceOpsConfig -raw | ConvertFrom-Json;
$json.AppSettings.AllowedOrigins = $urls
$json.AppSettings.SitecoreIdentityServerUrl = $identityServerUrl
$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToCommerceOpsConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToCommerceOpsConfig!" -ForegroundColor Green