#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [String]$commerceHostname,
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname,
    [Parameter(Mandatory=$true)]
    [String]$identityHostname
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Function UpdateBindingCertificate() {
    param(
        [Parameter(Mandatory = $true)]
        [X509Certificate]$certificate, 
        [Parameter(Mandatory = $true)]
        [string]$bindingName, 
        [Parameter(Mandatory = $true)]
        [uint32]$port
    )
    Write-Host "Deleting old $bindingName with port $port"
    Get-WebBinding -Name $bindingName -Protocol 'https' -Port $port | Remove-WebBinding

    Write-Host "Creating new binding $bindingName with port $port"
    New-WebBinding -Name $bindingName -HostHeader '*' -IPAddress * -Protocol 'https' -Port $port
    $binding = Get-WebBinding -Name $bindingName -Protocol 'https' -Port $port
    Write-Host "Succesfully created a new https binding with name $bindingName!" -ForegroundColor Green

    Write-Host "Updating the certificate for binding $bindingName with port $port"
    $binding.AddSslCertificate($certificate.GetCertHashString(), 'My')
    Write-Host "Succesfully updated the binding certificate!" -ForegroundColor Green
}

Function UpdateBizFxConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string]$bizFxUrl,
        [Parameter(Mandatory = $true)]
        [string]$identityServerUrl,
        [Parameter(Mandatory = $true)]
        [string]$engineServerUrl
    )

    Write-Host "Patching $configPath"
    $json = Get-Content $configPath -raw | ConvertFrom-Json; 
    Write-Host "Patching BizFxUri with $commerceUrl"
    $json.BizFxUri = $bizFxUrl
    Write-Host "Patching IdentityServerUri with $identityServerUrl"
    $json.IdentityServerUri = $identityServerUrl
    Write-Host "Patching EngineUri with $engineServerUrl"
    $json.EngineUri = $engineServerUrl
    $json | ConvertTo-Json | set-content $configPath

    $json = ConvertTo-Json $json -Depth 100
    Set-Content $configPath -Value $json -Encoding UTF8
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

Function UpdatePlumberConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string]$plumberUrl,
        [Parameter(Mandatory = $true)]
        [string]$identityServerUrl,
        [Parameter(Mandatory = $true)]
        [string]$engineServerUrl
    )

    Write-Host "Patching $configPath"
    $json = Get-Content $configPath -raw | ConvertFrom-Json; 
    Write-Host "Patching PlumberUri with $plumberUrl"
    $json.PlumberUri = $plumberUrl
    Write-Host "Patching IdentityServerUri with $identityServerUrl"
    $json.IdentityServerUri = $identityServerUrl
    Write-Host "Patching EngineUri with $engineServerUrl"
    $json.EngineUri = $engineServerUrl
    $json | ConvertTo-Json | set-content $configPath

    $json = ConvertTo-Json $json -Depth 100
    Set-Content $configPath -Value $json -Encoding UTF8
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

Function UpdateCommerceConfig() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$configPath, 
        [Parameter(Mandatory = $true)]
        [string[]]$allowedOrigins,
        [Parameter(Mandatory = $true)]
        [string]$identityServerUrl
    )

    Write-Host "Patching $configPath"
    $json = Get-Content $configPath -raw | ConvertFrom-Json;
    Write-Host "Patching AppSettings.AllowedOrigin with $allowedOrigins"
    $json.AppSettings.AllowedOrigins = $allowedOrigins
    Write-Host "Patching AppSettings.SitecoreIdentityServerUrl with $identityServerUrl"
    $json.AppSettings.SitecoreIdentityServerUrl = $identityServerUrl
    $json = ConvertTo-Json $json -Depth 100
    Set-Content $configPath -Value $json -Encoding UTF8
    Write-Host "Done patching $configPath!" -ForegroundColor Green
}

#Update the hostfile with the new hostnames
Write-Host "Updating hostfile with hostname $commerceHostname"
$hostFileName = 'c:\\windows\\system32\\drivers\\etc\\hosts'; '\"`r`n127.0.0.1`t$commerceHostname\"' | Add-Content $hostFileName
Write-Host "Succesfully updated hostfile!" -ForegroundColor Green

#Modify the certificate with the new hostnames
[X509Certificate[]]$certificates = Get-ChildItem -Path 'cert:\localmachine\root' -DnsName 'sitecore-docker-devonly';
[X509Certificate]$rootCert = $certificates[0];
Write-Host "Creating a new certificate with hostnames $commerceHostname"
[X509Certificate]$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $commerceHostname -Signer $rootcert -KeyUsage CertSign,CRLSign,DataEncipherment,DigitalSignature,KeyAgreement,KeyEncipherment -Provider "Microsoft Strong Cryptographic Provider" `
-HashAlgorithm "SHA256"
Write-Host "Succesfully created the certificate!. Updating bindings..." -ForegroundColor Green

UpdateBindingCertificate -certificate $certificate -bindingName 'CommerceOps_Sc9' -port 5015
UpdateBindingCertificate -certificate $certificate -bindingName 'CommerceShops_Sc9' -port 5005
UpdateBindingCertificate -certificate $certificate -bindingName 'CommerceAuthoring_Sc9' -port 5000 
UpdateBindingCertificate -certificate $certificate -bindingName 'CommerceMinions_Sc9'-port 5010
UpdateBindingCertificate -certificate $certificate -bindingName 'SitecoreBizFx' -port 4200

#Prepare some variables to be passed as arguments 
[string]$baseUrl = "https://$commerceHostname"
[string]$identityServerUrl = "https://${identityHostname}"
[string]$engineServerUrl = $baseUrl + ":5000"
[string]$bizFxUrl = $baseUrl + ":4200"
[string]$plumberUrl = "http://${commerceHostname}:4000"
$redirectUrls = [string[]]@(
    ($bizFxUrl),
    ($bizFxUrl + "/?")
)
$allowedOrigins = [string[]]@(
    "http://$sitecoreHostname",
    ($bizFxUrl),
    ($bizFxUrl + "/?"),
    $plumberUrl
)

$plumberAllowedOrigins = [string[]]@(
    ($plumberUrl),
    ($plumberUrl + "/?")
)

#Modify the commerce config with the new hostnames
UpdateBizFxConfig -configPath "C:\inetpub\wwwroot\SitecoreBizFx\assets\config.json" -bizFxUrl $bizFxUrl -identityServerUrl $identityServerUrl -engineServerUrl $engineServerUrl
UpdatePlumberConfig -configPath "C:\inetpub\plumber\config.json" -plumberUrl $plumberUrl -identityServerUrl $identityServerUrl -engineServerUrl $engineServerUrl

UpdateCommerceConfig -configPath "C:\inetpub\wwwroot\CommerceAuthoring_Sc9\wwwroot\config.json" -allowedOrigins $allowedOrigins -identityServerUrl $identityServerUrl
UpdateCommerceConfig -configPath "C:\inetpub\wwwroot\CommerceOps_Sc9\wwwroot\config.json" -allowedOrigins $allowedOrigins -identityServerUrl $identityServerUrl
UpdateCommerceConfig -configPath "C:\inetpub\wwwroot\CommerceMinions_Sc9\wwwroot\config.json" -allowedOrigins $allowedOrigins -identityServerUrl $identityServerUrl
UpdateCommerceConfig -configPath "C:\inetpub\wwwroot\CommerceShops_Sc9\wwwroot\config.json" -allowedOrigins $allowedOrigins -identityServerUrl $identityServerUrl