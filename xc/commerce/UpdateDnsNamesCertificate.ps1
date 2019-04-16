#Requires -RunAsAdministrator

param(
    [String]$hostname = "commerce.localhost"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$certificates = Get-ChildItem -Path 'cert:\localmachine\my' -DnsName 'DO_NOT_TRUST_SitecoreRootCert';
$hostnames = [string[]]@(
    ("commerce"),
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

$bizFxUrl = "https://$hostname:5000"
$pathToBizfxConfig = "C:\inetpub\wwwroot\SitecoreBizFx\assets\config.json"
Write-Host "Patching $pathToBizfxConfig with $bizFxUrl"

$json = Get-Content $pathToBizfxConfig -raw | ConvertFrom-Json; 
$json.BizFxUri = $bizFxUrl
$json | ConvertTo-Json | set-content $pathToBizfxConfig

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToBizfxConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToBizfxConfig!" -ForegroundColor Green


$pathToIdentityServerConfig = "C:\inetpub\wwwroot\SitecoreIdentityServer\wwwroot\appsettings.json"
$urls = @(
    ("https://commerce" + ":4200"),
    ("https://$hostname" + ":4200")
)
Write-Host "Patching $pathToIdentityServerConfig with $urls"

$json = Get-Content $pathToIdentityServerConfig -raw | ConvertFrom-Json; 
foreach ($p in $json.AppSettings.Clients) {
    $p.RedirectUris = $urls
    $p.PostLogoutRedirectUris = $urls
    $p.AllowedCorsOrigins = $urls
}

$json = ConvertTo-Json $json -Depth 100
Set-Content $pathToIdentityServerConfig -Value $json -Encoding UTF8
Write-Host "Done patching $pathToIdentityServerConfig!" -ForegroundColor Green