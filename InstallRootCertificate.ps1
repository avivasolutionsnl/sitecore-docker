#Requires -RunAsAdministrator

Param(
    [String]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $commerceContainerName,
    [String]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $password
)

$securepassword = $password | ConvertTo-SecureString -AsPlainText -Force
$hostCertLocation = "$PSScriptRoot\root.pfx"

try{
    $containerCertLocation = "C:\files\root.pfx"
    docker cp ${commerceContainerName}:${containerCertLocation} $hostCertLocation
    if( -Not $?){
        throw "Unable to get the root certificate file from ${commerceContainerName}. Possible causes might be that the container is not running or the path $containerCertLocation does not exist in the container."
    }

    Import-PfxCertificate -FilePath $hostCertLocation -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $securepassword -Verbose

    Write-Host "Succesfully imported the root certificate!" -ForegroundColor Green
}finally{
    if (Test-Path $hostCertLocation) 
    {
        Write-Host "Cleaning up $hostCertLocation"
        Remove-Item $hostCertLocation;
        Write-Host "Clean up $hostCertLocation succes!" -ForegroundColor Green
    }
}