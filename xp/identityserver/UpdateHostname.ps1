
param(
    [Parameter(Mandatory=$true)]
    [String]$identityHostname,
    [Parameter(Mandatory=$true)]
    [String]$sitecoreHostname
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

#Modify the certificate with the new hostnames
[X509Certificate[]]$certificates = Get-ChildItem -Path 'cert:\localmachine\root' -DnsName 'sitecore-docker-devonly';
[X509Certificate]$rootCert = $certificates[0];

Write-Host "Creating a new certificate with hostnames $identityHostname"
[X509Certificate]$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $identityHostname -Signer $rootcert -KeyUsage CertSign,CRLSign,DataEncipherment,DigitalSignature,KeyAgreement,KeyEncipherment -Provider "Microsoft Strong Cryptographic Provider" `
-HashAlgorithm "SHA256"
Write-Host "Succesfully created the certificate!. Updating bindings..." -ForegroundColor Green

UpdateBindingCertificate -certificate $certificate -bindingName 'identity' -port 443

UpdateIdentityServerConfig -configPath "C:\inetpub\wwwroot\identity\Config\production\Sitecore.IdentityServer.Host.xml" -defaultClientOrigin "http://$sitecoreHostname"
