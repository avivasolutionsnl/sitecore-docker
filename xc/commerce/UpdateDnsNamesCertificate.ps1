#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)]
    [String[]]$dnsNames
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$certificates = Get-ChildItem -Path 'cert:\localmachine\my' -DnsName 'DO_NOT_TRUST_SitecoreRootCert';

$rootCert = $certificates[0];
Write-Host "Creating a new certificate with dnsnames $dnsNames"
$certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $dnsNames -Signer $rootcert -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider';
Write-Host "Succesfully created the certificate!. Updating bindings..." -ForegroundColor Green

$updateBindingCertifcate = "$PSScriptRoot/UpdateBindingCertificate.ps1"

& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceOps_Sc9' -port 5015
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceShops_Sc9' -port 5005
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceAuthoring_Sc9' -port 5000 
& $updateBindingCertifcate -certificate $certificate -bindingName 'CommerceMinions_Sc9'-port 5010
& $updateBindingCertifcate -certificate $certificate -bindingName 'SitecoreBizFx' -port 4200
& $updateBindingCertifcate -certificate $certificate -bindingName 'SitecoreIdentityServer' -port 5050